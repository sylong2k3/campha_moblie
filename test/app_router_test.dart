import 'package:campha_moblie/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows only known local return routes', () {
    expect(sanitizeReturnTo('/map'), '/map');
    expect(sanitizeReturnTo('/map/search'), '/map/search');
    expect(
      sanitizeReturnTo('/map/feature/1/CAMTRUNG_99'),
      '/map/feature/1/CAMTRUNG_99',
    );
    expect(sanitizeReturnTo('/news?q=campha'), '/news?q=campha');
    expect(sanitizeReturnTo('/news/8?compose=1'), '/news/8?compose=1');
    expect(sanitizeReturnTo('/documents/2'), '/documents/2');
    expect(sanitizeReturnTo('/documents/pdf/5'), '/documents/pdf/5');
    expect(
      sanitizeReturnTo('/map/feature/1/abc_2/edit'),
      '/map/feature/1/abc_2/edit',
    );
    expect(
      sanitizeReturnTo('/map/feature/1/abc_2/history'),
      '/map/feature/1/abc_2/history',
    );
    expect(sanitizeReturnTo('/map/offline-changes'), '/map/offline-changes');
    expect(sanitizeReturnTo('/reports/new'), '/reports/new');
    expect(sanitizeReturnTo('/reports/mine'), '/reports/mine');
    expect(
      sanitizeReturnTo('/reports/9007199254740997'),
      '/reports/9007199254740997',
    );
    expect(
      sanitizeReturnTo('/profile/change-password'),
      '/profile/change-password',
    );
  });

  test('maps guest continuation to a public destination', () {
    expect(guestReturnTo(null), '/map');
    expect(guestReturnTo('/news/8?compose=1'), '/news/8?compose=1');
    expect(guestReturnTo('/reports/new'), '/reports');
    expect(guestReturnTo('/reports/mine'), '/reports');
    expect(guestReturnTo('/reports/42'), '/reports');
    expect(guestReturnTo('/map/feature/1/abc_2/edit'), '/map/feature/1/abc_2');
    expect(guestReturnTo('/map/offline-changes'), '/map');
    expect(guestReturnTo('/profile/change-password'), '/profile');
    expect(guestReturnTo('https://evil.example/map'), '/map');
  });

  test('rejects external, traversal, auth loop and unknown return routes', () {
    expect(sanitizeReturnTo('https://evil.example/map'), isNull);
    expect(sanitizeReturnTo('//evil.example/map'), isNull);
    expect(sanitizeReturnTo('/map/../auth/login'), isNull);
    expect(sanitizeReturnTo('/auth/login'), isNull);
    expect(sanitizeReturnTo('/map/feature/no/1'), isNull);
    expect(sanitizeReturnTo('/map/feature/1/bad%2Fid'), isNull);
    expect(sanitizeReturnTo('/news/not-a-number'), isNull);
    expect(sanitizeReturnTo('/documents/pdf/5/extra'), isNull);
    expect(sanitizeReturnTo('/reports/not-a-number'), isNull);
    expect(sanitizeReturnTo('/map/drafts'), isNull);
    expect(sanitizeReturnTo('/map/feature/1/abc_2/edit/extra'), isNull);
    expect(sanitizeReturnTo('/reports/7/extra'), isNull);
    expect(sanitizeReturnTo('/unknown'), isNull);
    expect(sanitizeReturnTo(null), isNull);
  });
}
