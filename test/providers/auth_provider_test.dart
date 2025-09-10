import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:radio_odan_app/providers/auth_provider.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';

class MockAuthService extends Mock implements AuthService {}

class MockStorage extends Mock implements FlutterSecureStorage {}

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    late MockAuthService authService;
    late MockStorage storage;
    late MockApiClient apiClient;
    late AuthProvider provider;

    final user = UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      phone: null,
      address: null,
      avatar: null,
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      authService = MockAuthService();
      storage = MockStorage();
      apiClient = MockApiClient();
      provider = AuthProvider(
        authService: authService,
        storage: storage,
        apiClient: apiClient,
      );
    });

    test('successful login stores user and token', () async {
      when(() => authService.login('mail', 'pw')).thenAnswer(
        (_) async => AuthResult(
          status: true,
          message: 'ok',
          token: 'abc',
          user: user,
        ),
      );
      when(() => apiClient.setBearer('abc')).thenReturn(null);

      final res = await provider.login('mail', 'pw');

      expect(res, isNull);
      expect(provider.user, equals(user));
      expect(provider.token, 'abc');
      verify(() => apiClient.setBearer('abc')).called(1);
    });

    test('failed login returns message', () async {
      when(() => authService.login('mail', 'pw')).thenAnswer(
        (_) async => const AuthResult(status: false, message: 'err'),
      );

      final res = await provider.login('mail', 'pw');

      expect(res, 'err');
      expect(provider.user, isNull);
      expect(provider.token, isNull);
    });
  });
}

