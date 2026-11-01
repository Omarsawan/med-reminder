import 'schedule.dart';

export 'schedule.dart';

/// Every record carries a string id and an update time so phones can be synced
/// later without changing the data model.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// ARGB colour used to tell people apart at a glance.
  final int color;
  final DateTime updatedAt;

  Person copyWith({String? name, int? color}) => Person(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as int,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

enum DoseUnit { tablet, capsule, ml, drop, puff, unit, sachet, application }

enum Instruction { none, beforeFood, withFood, afterFood, emptyStomach, bedtime }

class Medicine {
  const Medicine({
    required this.id,
    required this.personId,
    required this.name,
    required this.unit,
    required this.amount,
    required this.schedule,
    required this.updatedAt,
    DateTime? createdAt,
    this.photo,
    this.color,
    this.instruction = Instruction.none,
    this.notes = '',
    this.stock,
    this.refillAt = 5,
    this.active = true,
  }) : createdAt = createdAt ?? updatedAt;

  final String id;
  final String personId;
  final String name;
  final DoseUnit unit;

  /// How much per dose, e.g. 1 tablet, 0.5 tablet, 5 ml.
  final double amount;
  final Schedule schedule;

  /// File name of the photo inside the app's photo folder (not a full path,
  /// because iOS changes the app folder path between installs).
  final String? photo;

  /// Optional ARGB colour tag to help tell similar medicines apart.
  final int? color;
  final Instruction instruction;
  final String notes;

  /// Pills/ml left, or null when stock isn't tracked.
  final double? stock;

  /// Warn when [stock] drops to this amount or lower.
  final double refillAt;

  /// Paused medicines keep their data but get no reminders.
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Doses scheduled before the medicine was added aren't shown as missed; an
  /// hour of grace covers adding a medicine right after taking it.
  DateTime get firstDoseFrom => createdAt.subtract(const Duration(hours: 1));

  bool get isAsNeeded => schedule.type == ScheduleType.asNeeded;

  bool get isLowStock => stock != null && stock! <= refillAt;

  Medicine copyWith({
    String? personId,
    String? name,
    DoseUnit? unit,
    double? amount,
    Schedule? schedule,
    String? Function()? photo,
    int? Function()? color,
    Instruction? instruction,
    String? notes,
    double? Function()? stock,
    double? refillAt,
    bool? active,
  }) =>
      Medicine(
        id: id,
        personId: personId ?? this.personId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        amount: amount ?? this.amount,
        schedule: schedule ?? this.schedule,
        photo: photo != null ? photo() : this.photo,
        color: color != null ? color() : this.color,
        instruction: instruction ?? this.instruction,
        notes: notes ?? this.notes,
        stock: stock != null ? stock() : this.stock,
        refillAt: refillAt ?? this.refillAt,
        active: active ?? this.active,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'name': name,
        'unit': unit.name,
        'amount': amount,
        'schedule': schedule.toJson(),
        'photo': photo,
        'color': color,
        'instruction': instruction.name,
        'notes': notes,
        'stock': stock,
        'refillAt': refillAt,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] as String,
        personId: j['personId'] as String,
        name: j['name'] as String,
        unit: DoseUnit.values.byName(j['unit'] as String),
        amount: (j['amount'] as num).toDouble(),
        schedule: Schedule.fromJson((j['schedule'] as Map).cast<String, dynamic>()),
        photo: j['photo'] as String?,
        color: j['color'] as int?,
        instruction: Instruction.values.byName(j['instruction'] as String),
        notes: j['notes'] as String? ?? '',
        stock: (j['stock'] as num?)?.toDouble(),
        refillAt: (j['refillAt'] as num?)?.toDouble() ?? 5,
        active: j['active'] as bool? ?? true,
        createdAt: j['createdAt'] == null ? null : DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

enum LogStatus { taken, skipped }

/// What happened to one dose. A scheduled dose is identified by
/// (medicineId, scheduledAt); an as-needed dose uses the time it was taken.
class DoseLog {
  const DoseLog({
    required this.id,
    required this.medicineId,
    required this.scheduledAt,
    required this.status,
    required this.at,
    required this.amount,
  });

  final String id;
  final String medicineId;
  final DateTime scheduledAt;
  final LogStatus status;

  /// When it was marked.
  final DateTime at;

  /// How much was taken (used to give stock back on undo).
  final double amount;
}

enum DoseState { taken, skipped, upcoming, due, missed }

/// A scheduled dose for a specific time, joined with its log if any.
class Dose {
  const Dose({required this.medicine, required this.at, this.log});

  final Medicine medicine;
  final DateTime at;
  final DoseLog? log;

  /// How long after its time a dose still counts as "due" rather than missed.
  static const dueWindow = Duration(hours: 2);

  DoseState stateAt(DateTime now) {
    if (log != null) {
      return log!.status == LogStatus.taken ? DoseState.taken : DoseState.skipped;
    }
    if (now.isBefore(at)) return DoseState.upcoming;
    if (now.isBefore(at.add(dueWindow))) return DoseState.due;
    return DoseState.missed;
  }

  bool get isPending => log == null;
}
