import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_spanla_fe/core/widgets/app_button.dart';

void main() {
  testWidgets('1. AppButton renders its label and icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            text: 'Masuk',
            icon: Icons.login_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
  });

  testWidgets('2. AppButton responds to tap', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            text: 'Simpan',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('3. AppButton handles long text safely', (tester) async {
    const longLabel = 'Simpan Jurnal KBM Hari Ini Untuk Semua Siswa';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: AppButton.primary(
              text: longLabel,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(longLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
