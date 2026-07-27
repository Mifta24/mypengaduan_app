import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypengaduan_app/screens/home/landing_screen.dart';

void main() {
  testWidgets('landing does not expose public complaints before login',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Lihat Pengaduan Publik'), findsNothing);
  });
}
