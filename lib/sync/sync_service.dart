import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/photo_store.dart';
import '../data/repository.dart';
import '../firebase_options.dart';

enum SyncStatus { unavailable, off, connecting, synced, offline, error }

enum SyncError { badCode, network }

class SyncException implements Exception {
  const SyncException(this.kind);

  final SyncError kind;
}

/// Shares people, medicines, photos and dose logs between the phones of one
/// family through Firestore (free Spark plan).
///
/// The local database stays the source the app reads from. Local changes are
/// marked dirty and pushed; changes from other phones arrive through listeners
/// that only run while the app is open, so sync never runs in the background.
/// Conflicts resolve to the most recent change.
class SyncService extends ChangeNotifier {
  SyncService(this.repo, this.photos);

  final Repository repo;
  final PhotoStore photos;

  /// Called after changes from another phone were stored locally.
  VoidCallback? onRemoteChange;

  SyncStatus status = SyncStatus.unavailable;
  String? householdId;
  String? joinCode;

  bool get available => _db != null;
  bool get joined => householdId != null;

  FirebaseFirestore? _db;
  final _subs = <StreamSubscription<Object?>>[];
  Future<void> _queue = Future.value();
  Timer? _debounce;

  static const _tables = ['people', 'medicines', 'logs'];
  static const _timeout = Duration(seconds: 15);

  /// Logs older than this aren't listened to, to keep reads within the free
  /// quota as history grows.
  static const _logWindow = Duration(days: 14);

  /// Firestore documents hold at most 1 MiB; photos above this are skipped.
  static const _maxPhotoBytes = 900 * 1024;

  Future<void> init() async {
    final info = await repo.getJson('sync');
    householdId = info?['householdId'] as String?;
    joinCode = info?['joinCode'] as String?;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _db = FirebaseFirestore.instance;
      status = joined ? SyncStatus.connecting : SyncStatus.off;
    } catch (e) {
      debugPrint('Family sharing unavailable: $e');
      status = SyncStatus.unavailable;
    }
    notifyListeners();
  }

  /// Starts listening for other phones' changes and sends this phone's.
  /// Called when the app opens; [stop] runs when it goes to the background.
  Future<void> start() async {
    if (!available || !joined || _subs.isNotEmpty) return;
    try {
      await _uid();
      _setStatus(SyncStatus.connecting);
      for (final table in ['people', 'medicines']) {
        _listen(table, _home.collection(table));
      }
      final since = DateTime.now().subtract(_logWindow).millisecondsSinceEpoch;
      _listen('logs', _home.collection('logs').where('scheduled_at', isGreaterThanOrEqualTo: since));
      await push();
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Sends everything changed on this phone. Writes are queued by Firestore
  /// while offline and sent when the connection returns.
  Future<void> push() async {
    if (!available || !joined) return;
    for (final table in _tables) {
      for (final row in await repo.dirtyRows(table)) {
        _home.collection(table).doc(row.id).set(_toDoc(row)).catchError((Object e) => _onError(e));
        await repo.markClean(table, row.id, row.updatedAt);
        if (table == 'medicines' && !row.deleted) await _uploadPhoto(row);
      }
    }
  }

  /// Creates a family for this phone and returns the code others join with.
  Future<String> createFamily() async {
    final db = _db!;
    try {
      final uid = await _uid();
      final home = db.collection('households').doc();
      await home.set({'createdBy': uid, 'createdAt': FieldValue.serverTimestamp()}).timeout(_timeout);
      await home.collection('members').doc(uid).set(_member(null)).timeout(_timeout);
      final code = _newCode();
      await db.collection('joinCodes').doc(code).set({'householdId': home.id, 'createdBy': uid}).timeout(_timeout);
      await _joined(home.id, code);
      return code;
    } on TimeoutException {
      throw const SyncException(SyncError.network);
    } on FirebaseException catch (e) {
      throw SyncException(e.code == 'unavailable' ? SyncError.network : SyncError.badCode);
    }
  }

  /// Joins the family with [code]. Anything already on this phone is added to
  /// the family's data.
  Future<void> joinFamily(String code) async {
    final db = _db!;
    final normalized = normalizeCode(code);
    try {
      final uid = await _uid();
      final snap = await db
          .collection('joinCodes')
          .doc(normalized)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      final hid = snap.data()?['householdId'] as String?;
      if (hid == null) throw const SyncException(SyncError.badCode);
      await db
          .collection('households')
          .doc(hid)
          .collection('members')
          .doc(uid)
          .set(_member(normalized))
          .timeout(_timeout);
      await _joined(hid, normalized);
    } on TimeoutException {
      throw const SyncException(SyncError.network);
    } on FirebaseException catch (e) {
      throw SyncException(e.code == 'unavailable' ? SyncError.network : SyncError.badCode);
    }
  }

  /// Stops sharing on this phone. Local data stays.
  Future<void> leaveFamily() async {
    await stop();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await _home.collection('members').doc(uid).delete().timeout(_timeout);
    } catch (e) {
      debugPrint('Could not remove membership: $e');
    }
    householdId = null;
    joinCode = null;
    await repo.setJson('sync', {});
    _setStatus(SyncStatus.off);
  }

  /// "k7m2 qx9p" -> "K7M2QX9P".
  static String normalizeCode(String code) => code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// "K7M2QX9P" -> "K7M2-QX9P".
  static String displayCode(String code) =>
      code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;

  // Internals -------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> get _home => _db!.collection('households').doc(householdId);

  Future<String> _uid() async {
    final auth = FirebaseAuth.instance;
    return (auth.currentUser ?? (await auth.signInAnonymously()).user!).uid;
  }

  Map<String, Object?> _member(String? code) => {
        'code': code,
        'platform': Platform.operatingSystem,
        'joinedAt': FieldValue.serverTimestamp(),
      };

  Future<void> _joined(String hid, String code) async {
    householdId = hid;
    joinCode = code;
    await repo.setJson('sync', {'householdId': hid, 'joinCode': code});
    await repo.markAllDirty();
    await start();
  }

  void _listen(String table, Query<Map<String, dynamic>> query) {
    _subs.add(query.snapshots(includeMetadataChanges: true).listen(
          // Process snapshots one at a time so writes to the local database
          // don't interleave.
          (snap) => _queue = _queue.then((_) => _apply(table, snap)),
          onError: _onError,
        ));
  }

  Future<void> _apply(String table, QuerySnapshot<Map<String, dynamic>> snap) async {
    var changed = false;
    for (final change in snap.docChanges) {
      final doc = change.doc;
      // This phone's own write that the server hasn't confirmed yet.
      if (doc.metadata.hasPendingWrites) continue;
      final data = doc.data();
      if (data == null) continue;
      final row = _fromDoc(table, doc.id, data);
      if (row == null || !await repo.applyRemote(row)) continue;
      changed = true;
      if (table == 'medicines' && !row.deleted) await _downloadPhoto(row);
    }
    _setStatus(snap.metadata.isFromCache ? SyncStatus.offline : SyncStatus.synced);
    if (changed) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () => onRemoteChange?.call());
    }
  }

  Map<String, Object?> _toDoc(SyncRow row) {
    final base = {'updatedAt': row.updatedAt, 'deleted': row.deleted};
    if (row.table == 'logs') return {...row.fields, ...base};
    return {'data': jsonDecode(row.fields['data'] as String), ...base};
  }

  SyncRow? _fromDoc(String table, String id, Map<String, dynamic> d) {
    final updatedAt = d['updatedAt'];
    if (updatedAt is! int) return null;
    final fields = table == 'logs'
        ? {for (final f in ['medicine_id', 'scheduled_at', 'status', 'at', 'amount']) f: d[f]}
        : {'data': jsonEncode(d['data'])};
    return SyncRow(
      table: table,
      id: id,
      updatedAt: updatedAt,
      deleted: d['deleted'] == true,
      fields: fields,
    );
  }

  String? _photoName(SyncRow medicineRow) =>
      (jsonDecode(medicineRow.fields['data'] as String) as Map)['photo'] as String?;

  Future<void> _uploadPhoto(SyncRow row) async {
    final name = _photoName(row);
    final file = photos.file(name);
    if (name == null || file == null) return;
    final uploaded = await _uploadedPhotos();
    if (uploaded.contains(name)) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxPhotoBytes) {
      debugPrint('Photo $name too large to share (${bytes.length} bytes)');
      return;
    }
    _home
        .collection('photos')
        .doc(name)
        .set({'bytes': Blob(bytes), 'updatedAt': DateTime.now().millisecondsSinceEpoch})
        .catchError((Object e) => _onError(e));
    await repo.setJson('uploadedPhotos', {'names': [...uploaded, name]});
  }

  Future<void> _downloadPhoto(SyncRow row) async {
    final name = _photoName(row);
    if (name == null || photos.file(name) != null) return;
    try {
      final snap = await _home.collection('photos').doc(name).get().timeout(_timeout);
      final blob = snap.data()?['bytes'];
      if (blob is! Blob) return;
      await File(photos.path(name)).writeAsBytes(blob.bytes, flush: true);
      final uploaded = await _uploadedPhotos();
      await repo.setJson('uploadedPhotos', {'names': [...uploaded, name]});
    } catch (e) {
      debugPrint('Could not download photo $name: $e');
    }
  }

  Future<Set<String>> _uploadedPhotos() async =>
      ((await repo.getJson('uploadedPhotos'))?['names'] as List? ?? const []).cast<String>().toSet();

  void _onError(Object e) {
    debugPrint('Sync error: $e');
    _setStatus(SyncStatus.error);
  }

  void _setStatus(SyncStatus s) {
    if (status == s) return;
    status = s;
    notifyListeners();
  }

  /// 8 characters without look-alikes (0/O, 1/I/L): about 10^12 combinations.
  static String _newCode() {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }
}
