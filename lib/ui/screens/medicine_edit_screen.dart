import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'people_screen.dart';

/// One scrolling form for adding or editing a medicine. Everything has a
/// sensible default so the minimum is: name, who, tap Save.
class MedicineEditScreen extends StatefulWidget {
  const MedicineEditScreen({super.key, this.medicine, this.initialPersonId});

  final Medicine? medicine;
  final String? initialPersonId;

  @override
  State<MedicineEditScreen> createState() => _MedicineEditScreenState();
}

class _MedicineEditScreenState extends State<MedicineEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;

  String? _personId;
  String? _photo;
  int? _color;
  DoseUnit _unit = DoseUnit.tablet;
  double _amount = 1;
  Instruction _instruction = Instruction.none;
  late Schedule _schedule;
  bool _trackStock = false;
  double _stock = 30;
  double _refillAt = 5;
  bool _active = true;
  String? _error;

  /// Photos picked in this session, deleted if the user backs out.
  final _newPhotos = <String>[];
  bool _saved = false;

  bool get _isNew => widget.medicine == null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    final state = context.read<AppState>();
    _name = TextEditingController(text: m?.name ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    if (m != null) {
      _personId = m.personId;
      _photo = m.photo;
      _color = m.color;
      _unit = m.unit;
      _amount = m.amount;
      _instruction = m.instruction;
      _schedule = m.schedule;
      _trackStock = m.stock != null;
      _stock = m.stock ?? 30;
      _refillAt = m.refillAt;
      _active = m.active;
    } else {
      _personId = widget.initialPersonId ?? (state.people.length == 1 ? state.people.first.id : null);
      _schedule = Schedule(
        type: ScheduleType.daily,
        times: const [DoseTime(8, 0)],
        weekdays: const {1, 2, 3, 4, 5, 6, 7},
        startDate: dateOnly(DateTime.now()),
      );
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      final photos = context.read<AppState>().env.photos;
      for (final p in _newPhotos) {
        photos.remove(p);
      }
    }
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = context.l;
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l.removePhoto),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photo = null);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (picked == null || !mounted) return;
    final name = await context.read<AppState>().env.photos.add(picked.path);
    setState(() {
      _photo = name;
      _newPhotos.add(name);
    });
  }

  Future<void> _addPerson() async {
    final person = await showPersonDialog(context);
    if (person != null) setState(() => _personId = person.id);
  }

  Future<void> _save() async {
    final l = context.l;
    final valid = _form.currentState!.validate();
    String? error;
    if (_personId == null) {
      error = l.pickPerson;
    } else if ((_schedule.type == ScheduleType.daily || _schedule.type == ScheduleType.weekdays) &&
        _schedule.times.isEmpty) {
      error = l.pickTimes;
    } else if (_schedule.type == ScheduleType.weekdays && _schedule.weekdays.isEmpty) {
      error = l.pickDays;
    }
    setState(() => _error = error);
    if (!valid || error != null) return;

    final state = context.read<AppState>();
    final base = widget.medicine ??
        Medicine(
          id: newId(),
          personId: _personId!,
          name: '',
          unit: _unit,
          amount: _amount,
          schedule: _schedule,
          updatedAt: DateTime.now(),
        );
    final med = base.copyWith(
      personId: _personId,
      name: _name.text.trim(),
      unit: _unit,
      amount: _amount,
      schedule: _schedule,
      photo: () => _photo,
      color: () => _color,
      instruction: _instruction,
      notes: _notes.text.trim(),
      stock: () => _trackStock ? _stock : null,
      refillAt: _refillAt,
      active: _active,
    );
    _saved = true;
    final navigator = Navigator.of(context);
    // Drop photos picked and then replaced during this edit.
    for (final p in _newPhotos.where((p) => p != _photo)) {
      await state.env.photos.remove(p);
    }
    await state.saveMedicine(med);
    navigator.pop();
  }

  Future<void> _delete() async {
    final m = widget.medicine!;
    final l = context.l;
    if (!await confirm(context, title: l.deleteTitle(m.name), body: l.deleteMedicineBody, action: l.delete)) {
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await context.read<AppState>().deleteMedicine(m);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final photoFile = state.env.photos.file(_photo);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.newMedicine : l.editMedicine),
        actions: [
          if (!_isNew) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: l.delete),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(l.save),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Photo
            Center(
              child: InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                    border: _color != null ? Border.all(color: Color(_color!), width: 8) : null,
                    image: photoFile != null
                        ? DecorationImage(image: FileImage(photoFile), fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(l.addPhoto, style: theme.textTheme.labelLarge),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.photoHelp, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: _isNew,
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(labelText: l.medicineName, border: const OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? l.nameRequired : null,
            ),

            // Who
            SectionTitle(l.whoTakesIt),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in state.people)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 7),
                    label: Text(p.name),
                    selected: _personId == p.id,
                    onSelected: (_) => setState(() => _personId = p.id),
                  ),
                ActionChip(avatar: const Icon(Icons.add, size: 18), label: Text(l.addPerson), onPressed: _addPerson),
              ],
            ),

            // Type and dose
            SectionTitle(l.typeAndDose),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in DoseUnit.values)
                  ChoiceChip(
                    avatar: Icon(unitIcon(u), size: 18),
                    label: Text(fmt.unitName(u)),
                    selected: _unit == u,
                    onSelected: (_) => setState(() {
                      _unit = u;
                      _amount = switch (u) {
                        DoseUnit.ml => 5,
                        DoseUnit.drop => 2,
                        DoseUnit.unit => 10,
                        _ => 1,
                      };
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: NumberStepper(
                value: _amount,
                step: switch (_unit) {
                  DoseUnit.tablet => 0.5,
                  DoseUnit.ml => 0.5,
                  _ => 1,
                },
                min: 0.5,
                label: fmt.amount(_unit, _amount),
                onChanged: (v) => setState(() => _amount = v),
              ),
            ),

            // When
            SectionTitle(l.whenToTake),
            _ScheduleEditor(
              schedule: _schedule,
              onChanged: (s) => setState(() => _schedule = s),
            ),

            // Instructions
            SectionTitle(l.instructions),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in Instruction.values)
                  ChoiceChip(
                    label: Text(fmt.instruction(i)),
                    selected: _instruction == i,
                    onSelected: (_) => setState(() => _instruction = i),
                  ),
              ],
            ),

            // Colour tag
            SectionTitle(l.colorTag),
            ColorPicker(value: _color, allowNone: true, onChanged: (c) => setState(() => _color = c)),

            // Stock
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.trackStock),
              value: _trackStock,
              onChanged: (v) => setState(() => _trackStock = v),
            ),
            if (_trackStock) ...[
              _LabeledRow(
                label: l.stockLeft,
                child: NumberStepper(
                  value: _stock,
                  step: 1,
                  max: 9999,
                  label: fmt.number(_stock),
                  onChanged: (v) => setState(() => _stock = v),
                ),
              ),
              _LabeledRow(
                label: l.warnAt,
                child: NumberStepper(
                  value: _refillAt,
                  step: 1,
                  max: 999,
                  onChanged: (v) => setState(() => _refillAt = v),
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l.notes, border: const OutlineInputBorder()),
            ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.pauseReminders),
                value: !_active,
                onChanged: (v) => setState(() => _active = !v),
              ),
          ],
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(label)), child]),
      );
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({required this.schedule, required this.onChanged});

  final Schedule schedule;
  final ValueChanged<Schedule> onChanged;

  static const _presets = {
    1: [DoseTime(8, 0)],
    2: [DoseTime(8, 0), DoseTime(20, 0)],
    3: [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
    4: [DoseTime(8, 0), DoseTime(12, 0), DoseTime(16, 0), DoseTime(20, 0)],
  };

  Future<DoseTime?> _pickTime(BuildContext context, DoseTime initial) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute));
    return t == null ? null : DoseTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final s = schedule;
    final type = s.type;

    final typeChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (t, label) in [
          (ScheduleType.daily, l.scheduleDaily),
          (ScheduleType.interval, l.scheduleInterval),
          (ScheduleType.weekdays, l.scheduleWeekdays),
          (ScheduleType.everyNDays, l.scheduleEveryNDays),
          (ScheduleType.asNeeded, l.scheduleAsNeeded),
        ])
          ChoiceChip(label: Text(label), selected: type == t, onSelected: (_) => onChanged(s.copyWith(type: t))),
      ],
    );

    Widget timesEditor() {
      final times = [...s.times]..sort();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _presets.entries)
                FilterChip(
                  label: Text(l.presetTimes(e.key)),
                  selected: _sameTimes(times, e.value),
                  onSelected: (_) => onChanged(s.copyWith(times: e.value)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in times)
                InputChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(fmt.doseTime(t), style: Theme.of(context).textTheme.titleMedium),
                  onPressed: () async {
                    final picked = await _pickTime(context, t);
                    if (picked == null) return;
                    onChanged(s.copyWith(times: [...times.where((x) => x != t), picked]..sort()));
                  },
                  onDeleted: () => onChanged(s.copyWith(times: times.where((x) => x != t).toList())),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: Text(l.addTime),
                onPressed: () async {
                  final last = times.isEmpty ? const DoseTime(8, 0) : times.last;
                  final picked = await _pickTime(context, DoseTime((last.hour + 4) % 24, last.minute));
                  if (picked == null || times.contains(picked)) return;
                  onChanged(s.copyWith(times: [...times, picked]..sort()));
                },
              ),
            ],
          ),
        ],
      );
    }

    Widget startDateRow(String label) => _LabeledRow(
          label: label,
          child: IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: s.startDate,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) onChanged(s.copyWith(startDate: dateOnly(picked)));
            },
          ),
        );

    final body = switch (type) {
      ScheduleType.daily => timesEditor(),
      ScheduleType.everyNDays => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabeledRow(
              label: l.everyDays(s.intervalDays),
              child: NumberStepper(
                value: s.intervalDays.toDouble(),
                min: 2,
                max: 90,
                label: '${s.intervalDays}',
                onChanged: (v) => onChanged(s.copyWith(intervalDays: v.round())),
              ),
            ),
            startDateRow(l.firstDoseOn(fmt.date(s.startDate))),
            const SizedBox(height: 8),
            timesEditor(),
          ],
        ),
      ScheduleType.weekdays => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(fmt.weekdayShort(d)),
                    selected: s.weekdays.contains(d),
                    showCheckmark: false,
                    onSelected: (on) => onChanged(s.copyWith(
                      weekdays: on ? {...s.weekdays, d} : ({...s.weekdays}..remove(d)),
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            timesEditor(),
          ],
        ),
      ScheduleType.interval => Column(
          children: [
            _LabeledRow(
              label: l.everyHours(s.intervalHours),
              child: NumberStepper(
                value: s.intervalHours.toDouble(),
                min: 1,
                max: 48,
                label: '${s.intervalHours}',
                onChanged: (v) => onChanged(s.copyWith(intervalHours: v.round())),
              ),
            ),
            _LabeledRow(
              label: l.firstDoseAt,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(fmt.doseTime(s.intervalStart)),
                onPressed: () async {
                  final picked = await _pickTime(context, s.intervalStart);
                  if (picked != null) onChanged(s.copyWith(intervalStart: picked));
                },
              ),
            ),
          ],
        ),
      ScheduleType.asNeeded => Column(
          children: [
            _LabeledRow(
              label: l.minGapLabel,
              child: NumberStepper(
                value: s.minGapHours,
                step: 0.5,
                min: 0.5,
                max: 72,
                onChanged: (v) => onChanged(s.copyWith(minGapHours: v)),
              ),
            ),
            _LabeledRow(
              label: l.maxPerDayLabel,
              child: NumberStepper(
                value: (s.maxPerDay ?? 0).toDouble(),
                min: 0,
                max: 24,
                label: s.maxPerDay == null ? l.noLimit : '${s.maxPerDay}',
                onChanged: (v) => onChanged(s.copyWith(maxPerDay: () => v < 1 ? null : v.round())),
              ),
            ),
          ],
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        typeChips,
        const SizedBox(height: 16),
        body,
        if (type != ScheduleType.asNeeded) ...[
          SectionTitle(l.durationLabel),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.ongoing),
                selected: s.durationDays == null,
                onSelected: (_) => onChanged(s.copyWith(durationDays: () => null)),
              ),
              ChoiceChip(
                label: Text(l.forSetDays),
                selected: s.durationDays != null,
                onSelected: (_) => onChanged(s.copyWith(durationDays: () => s.durationDays ?? 7)),
              ),
            ],
          ),
          if (s.durationDays != null) ...[
            const SizedBox(height: 8),
            _LabeledRow(
              label: l.daysCount(s.durationDays!),
              child: NumberStepper(
                value: s.durationDays!.toDouble(),
                min: 1,
                max: 365,
                label: '${s.durationDays}',
                onChanged: (v) => onChanged(s.copyWith(durationDays: () => v.round())),
              ),
            ),
            if (type != ScheduleType.everyNDays) startDateRow(l.startsOn(fmt.date(s.startDate))),
          ],
        ],
      ],
    );
  }

  static bool _sameTimes(List<DoseTime> a, List<DoseTime> b) =>
      a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
}
