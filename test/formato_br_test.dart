import 'package:bikesafe_app/util/formato_br.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('data', () {
    expect(FormatoBr.data('2024-06-01T00:00:00'), '01/06/2024');
    expect(FormatoBr.data('2024-06-01'), '01/06/2024');
    expect(FormatoBr.data('01/06/2024'), '01/06/2024');
    expect(FormatoBr.data(''), isNull);
    expect(FormatoBr.data(null), isNull);
  });
  test('hora', () {
    expect(FormatoBr.hora('04:06:00'), '04:06');
    expect(FormatoBr.hora('4:06'), '04:06');
    expect(FormatoBr.hora(null), isNull);
  });
  test('quando', () {
    expect(FormatoBr.quando('2024-06-01T00:00:00', '04:06:00'), '01/06/2024 às 04:06');
    expect(FormatoBr.quando('2024-06-01', null), '01/06/2024');
  });
}
