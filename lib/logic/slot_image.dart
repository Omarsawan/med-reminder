import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/photo_store.dart';
import '../models/models.dart';

/// Draws one picture showing every medicine due at the same time, side by
/// side with its name and colour tag, for the notification's big image.
///
/// Returns null when none of the medicines has a photo. Images are cached by
/// content, so rescheduling doesn't redraw them.
Future<File?> buildSlotImage(
  List<Medicine> medicines,
  PhotoStore photos,
  Directory dir, {
  required bool rtl,
}) async {
  final meds = medicines.take(4).toList();
  if (!meds.any((m) => photos.file(m.photo) != null)) return null;

  final key = _fnv1a([
    for (final m in meds) '${m.id}:${m.photo}:${m.name}:${m.color}',
    '$rtl',
  ].join('|'));
  final out = File('${dir.path}/slot_$key.png');
  if (out.existsSync()) return out;

  const width = 1024.0;
  const height = 512.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFFF1F5F9));

  final tileWidth = width / meds.length;
  for (var i = 0; i < meds.length; i++) {
    final m = meds[i];
    final column = rtl ? meds.length - 1 - i : i;
    final tile = Rect.fromLTWH(column * tileWidth, 0, tileWidth, height).deflate(8);
    final tag = m.color == null ? null : Color(m.color!);
    final radius = const Radius.circular(28);

    var inner = tile;
    if (tag != null) {
      canvas.drawRRect(RRect.fromRectAndRadius(tile, radius), Paint()..color = tag);
      inner = tile.deflate(10);
    }
    final clip = RRect.fromRectAndRadius(inner, const Radius.circular(20));
    canvas.save();
    canvas.clipRRect(clip);

    final image = await _decode(photos.file(m.photo));
    if (image != null) {
      _drawCover(canvas, image, inner);
    } else {
      canvas.drawRect(inner, Paint()..color = (tag ?? const Color(0xFF64748B)).withValues(alpha: 0.35));
      final initial = m.name.isEmpty ? '?' : String.fromCharCode(m.name.runes.first).toUpperCase();
      _drawText(canvas, initial, inner, 180, const Color(0xFF1E293B), rtl);
    }

    // Name band along the bottom.
    final band = Rect.fromLTRB(inner.left, inner.bottom - 96, inner.right, inner.bottom);
    canvas.drawRect(band, Paint()..color = const Color(0xCC000000));
    _drawText(canvas, m.name, band, 44, const Color(0xFFFFFFFF), rtl);
    canvas.restore();
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(width.toInt(), height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return null;
  await out.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return out;
}

Future<ui.Image?> _decode(File? file) async {
  if (file == null) return null;
  try {
    final codec = await ui.instantiateImageCodec(await file.readAsBytes(), targetWidth: 640);
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

/// Draws [image] filling [dst], cropping the overflow like BoxFit.cover.
void _drawCover(Canvas canvas, ui.Image image, Rect dst) {
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final scale = (dst.width / iw) > (dst.height / ih) ? dst.width / iw : dst.height / ih;
  final sw = dst.width / scale;
  final sh = dst.height / scale;
  final src = Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
  canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
}

void _drawText(Canvas canvas, String text, Rect box, double size, Color color, bool rtl) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.center,
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
    fontSize: size,
    fontWeight: FontWeight.w700,
  ))
    ..pushStyle(ui.TextStyle(color: color))
    ..addText(text);
  final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: box.width - 24));
  canvas.drawParagraph(
    paragraph,
    Offset(box.left + 12, box.top + (box.height - paragraph.height) / 2),
  );
}

/// Small stable hash for cache file names (String.hashCode changes between runs).
String _fnv1a(String s) {
  var hash = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16);
}
