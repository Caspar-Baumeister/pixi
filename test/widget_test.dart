import 'package:flutter_test/flutter_test.dart';
import 'package:pixi/core/dates.dart';

void main() {
  test('date keys round-trip', () {
    final d = DateTime(2026, 9, 21);
    expect(Dates.key(d), '2026-09-21');
    expect(Dates.parse('2026-09-21'), d);
  });
}
