import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  static const _baseUrl = 'https://shadow-health-api.onrender.com';
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final resp = await _dio.get(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (resp.statusCode == 200) {
        state = state.copyWith(
          isAuthenticated: true,
          user: (resp.data['user'] ?? resp.data) as Map<String, dynamic>?,
        );
      } else {
        await prefs.remove('auth_token');
      }
    } catch (_) {
      await prefs.remove('auth_token');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = resp.data['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: resp.data['user'] as Map<String, dynamic>?,
        );
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Credenciales incorrectas');
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Error al iniciar sesión. Intenta de nuevo.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Error de conexión. Intenta de nuevo.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _dio.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final token = resp.data['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: resp.data['user'] as Map<String, dynamic>?,
        );
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Error al crear la cuenta');
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Error al registrar. Intenta de nuevo.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Error de conexión. Intenta de nuevo.');
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _dio.post('/api/auth/google', data: {
        'idToken': idToken,
      });
      final token = resp.data['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: resp.data['user'] as Map<String, dynamic>?,
        );
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Error al iniciar sesión con Google');
      return false;
    } catch (_) {
      state = state.copyWith(
          isLoading: false,
          error: 'Error al conectar con Google. Intenta de nuevo.');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
