// Testes do Pluviômetro Digital.
//
// Cobrem a regra de negócio de classificação de chuva (núcleo do app) e a
// renderização de um card de estatística. São testes offline — não dependem
// de banco de dados, rede ou timers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pluviometro_app/features/dashboard/widgets/rain_classification.dart';
import 'package:pluviometro_app/features/dashboard/widgets/stat_card.dart';

void main() {
  group('RainClassification.fromMillimeters', () {
    test('0 mm é classificado como "Sem Chuva"', () {
      expect(RainClassification.fromMillimeters(0).label, 'Sem Chuva');
    });

    test('até 50 mm é "Chuva Leve"', () {
      expect(RainClassification.fromMillimeters(1).label, 'Chuva Leve');
      expect(RainClassification.fromMillimeters(50).label, 'Chuva Leve');
    });

    test('51–100 mm é "Chuva Moderada"', () {
      expect(RainClassification.fromMillimeters(51).label, 'Chuva Moderada');
      expect(RainClassification.fromMillimeters(100).label, 'Chuva Moderada');
    });

    test('101–200 mm é "Chuva Boa"', () {
      expect(RainClassification.fromMillimeters(101).label, 'Chuva Boa');
      expect(RainClassification.fromMillimeters(200).label, 'Chuva Boa');
    });

    test('acima de 200 mm é "Chuva Intensa"', () {
      expect(RainClassification.fromMillimeters(200.1).label, 'Chuva Intensa');
      expect(RainClassification.fromMillimeters(500).label, 'Chuva Intensa');
    });
  });

  testWidgets('StatCard exibe título e valor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Este mês',
            subtitle: 'JUNHO',
            value: '123.4 mm',
          ),
        ),
      ),
    );

    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('JUNHO'), findsOneWidget);
    expect(find.text('123.4 mm'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsOneWidget);
  });
}
