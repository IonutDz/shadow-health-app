import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/user.dart';
import '../../core/utils/storage.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({User? user, bool? isLoading, String? error, bool? isAuthenticated}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> checkAuth() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      state = state.copyWith(isAuthenticated: false);
      return;
    }

    try {
      final response = await _api.get(ApiEndpoints.me);
      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, isAuthenticated: true);
    } catch (_) {
      await StorageService.clearToken();
      state = state.copyWith(isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await StorageService.saveToken(data['token'] as String);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await StorageService.saveUserId(user.id);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await StorageService.saveToken(data['token'] as String);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await StorageService.saveUserId(user.id);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {}
    await StorageService.clearToken();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    try {
      final response = (e as dynamic).response;
      return response?.data?['error'] as String? ?? 'Error desconocido';
    } catch (_) {
      return e.toString();
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.init();
  return client;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
