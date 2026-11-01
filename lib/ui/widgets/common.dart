import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/format.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Colours for people and medicine tags: distinct and readable in both themes.
const palette = <int>[
  0xFFE53935, // red
  0xFFFB8C00, // orange
  0xFFFDD835, // yellow
  0xFF43A047, // green
  0xFF00ACC1, // cyan
  0xFF1E88E5, // blue
  0xFF8E24AA, // purple
  0xFFD81B60, // pink
  0xFF6D4C41, // brown
  0xFF546E7A, // grey
];

extension ContextX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  Fmt get fmt => Fmt(AppLocalizations.of(this));
}

IconData unitIcon(DoseUnit unit) => switch (unit) {
      DoseUnit.tablet => Icons.medication_rounded,
      DoseUnit.capsule => Icons.medication_outlined,
      DoseUnit.ml => Icons.local_drink_rounded,
      DoseUnit.drop => Icons.water_drop_rounded,
      DoseUnit.puff => Icons.air_rounded,
      DoseUnit.unit => Icons.vaccines_rounded,
      DoseUnit.sachet => Icons.inventory_2_rounded,
      DoseUnit.application => Icons.back_hand_rounded,
    };

/// The medicine's photo with its colour tag as a ring, or an icon if there's
/// no photo. This is what people recognise, so it's shown large everywhere.
class MedPhoto extends StatelessWidget {
  const MedPhoto(this.medicine, {super.key, this.size = 64});

  final Medicine medicine;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = context.read<AppState>().env.photos.file(medicine.photo);
    final scheme = Theme.of(context).colorScheme;
    final tag = medicine.color != null ? Color(medicine.color!) : null;
    final radius = BorderRadius.circular(size * 0.22);
    final ring = tag != null ? size * 0.07 : 0.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(color: tag, borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22 - ring),
        child: file != null
            ? Image.file(file, fit: BoxFit.cover, cacheWidth: (size * 3).round())
            : ColoredBox(
                color: tag?.withValues(alpha: 0.25) ?? scheme.secondaryContainer,
                child: Icon(unitIcon(medicine.unit), size: size * 0.5, color: scheme.onSecondaryContainer),
              ),
      ),
    );
  }
}

class PersonChip extends StatelessWidget {
  const PersonChip(this.person, {super.key});

  final Person? person;

  @override
  Widget build(BuildContext context) {
    final p = person;
    if (p == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: Color(p.color), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            p.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

/// "Everyone" plus one chip per person. Hidden when there's only one person.
class PersonFilter extends StatelessWidget {
  const PersonFilter({super.key, required this.selected, required this.onChanged});

  /// Selected person id, or null for everyone.
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final people = context.watch<AppState>().people;
    if (people.length < 2) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(context.l.everyone),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final p in people)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(
                avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 6),
                label: Text(p.name),
                selected: selected == p.id,
                onSelected: (_) => onChanged(p.id),
              ),
            ),
        ],
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.value, required this.onChanged, this.allowNone = false});

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(int? c) {
      final selected = c == value;
      return Semantics(
        selected: selected,
        button: true,
        label: c == null ? context.l.noColor : null,
        child: InkResponse(
          onTap: () => onChanged(c),
          radius: 24,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c != null ? Color(c) : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.onSurface : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
            child: c == null
                ? Icon(Icons.block, color: scheme.outline, size: 20)
                : selected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [if (allowNone) swatch(null), for (final c in palette) swatch(c)],
    );
  }
}

/// − value + control for small numbers.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: value - step >= min - 0.0001 ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: Text(
            label ?? context.fmt.number(value),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          onPressed: value + step <= max + 0.0001 ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}

Future<bool> confirm(BuildContext context, {required String title, String? body, required String action}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body != null ? Text(body) : null,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}
