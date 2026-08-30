import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:campha_moblie/features/tools/presentation/location_weather_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModernWeatherCard', () {
    testWidgets('renders temperature, wind metrics and location properly', (
      tester,
    ) async {
      final weather = WeatherSnapshot(
        observedAt: DateTime.parse('2026-08-30T13:30:00.000Z'),
        location: 'Cam Pha Port',
        temperatureC: 28.6,
        windSpeedMps: 4.2,
        windDirectionDegrees: 135,
        description: 'Mây cụm, gió mát',
      );

      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ModernWeatherCard(
                weather: weather,
                onRefresh: () => refreshed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('28.6'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
      expect(find.text('Cam Pha Port'), findsOneWidget);
      expect(find.text('Mây cụm, gió mát'), findsOneWidget);
      expect(find.text('4.2 m/s'), findsOneWidget);
      expect(find.text('135°'), findsOneWidget);
      expect(find.text('Đông Nam (SE)'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(refreshed, isTrue);
    });
  });
}
