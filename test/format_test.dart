import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_reminder/l10n/app_localizations.dart';
import 'package:med_reminder/logic/format.dart';
import 'package:med_reminder/models/models.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final en = Fmt(lookupAppLocalizations(const Locale('en')));
  final ar = Fmt(lookupAppLocalizations(const Locale('ar')));

  test('fractions are shown as ½ and ¼', () {
    expect(en.number(0.5), '½');
    expect(en.number(1.5), '1½');
    expect(en.number(2), '2');
    expect(en.number(0.25), '¼');
  });

  test('English dose amounts use the right plural', () {
    expect(en.amount(DoseUnit.tablet, 1), '1 tablet');
    expect(en.amount(DoseUnit.tablet, 2), '2 tablets');
    expect(en.amount(DoseUnit.tablet, 0.5), '½ tablet');
    expect(en.amount(DoseUnit.tablet, 1.5), '1½ tablets');
    expect(en.amount(DoseUnit.ml, 5), '5 ml');
  });

  test('Arabic dose amounts use the right plural', () {
    expect(ar.amount(DoseUnit.tablet, 1), 'قرص واحد');
    expect(ar.amount(DoseUnit.tablet, 2), 'قرصان');
    expect(ar.amount(DoseUnit.tablet, 3), '3 أقراص');
    expect(ar.amount(DoseUnit.tablet, 0.5), '½ قرص');
  });
}
