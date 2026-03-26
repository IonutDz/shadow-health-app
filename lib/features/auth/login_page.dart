import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

final _googleSignIn = GoogleSignIn(
  clientId: '177898872987-6rqc6e350tmfocuuhh37ralkfdb9tneg.apps.googleusercontent.com',
  serverClientId: '177898872987-6rqc6e350tmfocuuhh37ralkfdb9tneg.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _googleLoading = false;
  bool _isRegister = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    bool success;
    if (_isRegister) {
      success = await ref.read(authProvider.notifier).register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    } else {
      success = await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    }
    if (success && mounted) context.go('/dashboard');
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener token de Google.')),
        );
        return;
      }
      final success = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (success && mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 768;

    final form = _buildForm(state);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            Expanded(flex: 55, child: _BrandingPanel()),
            Expanded(
              flex: 45,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: form,
        ),
      ),
    );
  }

  Widget _buildForm(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _isRegister ? 'Crear cuenta' : 'Iniciar Sesión',
            style: const TextStyle(
              color: AppTheme.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRegister ? 'Completa los datos para registrarte' : 'Ingresa a tu cuenta para continuar',
            style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Error
          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.destructive.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.destructive, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(state.error!, style: const TextStyle(color: AppTheme.destructive, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Name (register only)
          if (_isRegister) ...[
            _label('Nombre'),
            const SizedBox(height: 6),
            _field(controller: _nameCtrl, hint: 'Tu nombre', icon: Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null),
            const SizedBox(height: 16),
          ],

          // Email
          _label('Email'),
          const SizedBox(height: 6),
          _field(
            controller: _emailCtrl,
            hint: 'tu@email.com',
            icon: Icons.mail_outline,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _label('Contraseña'),
          const SizedBox(height: 6),
          _field(
            controller: _passCtrl,
            hint: 'Min. 6 caracteres',
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.mutedForeground, size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(_isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(children: [
            const Expanded(child: Divider(color: AppTheme.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
            ),
            const Expanded(child: Divider(color: AppTheme.border)),
          ]),
          const SizedBox(height: 16),

          // Google button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _googleLoading ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.foreground,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppTheme.surface,
              ),
              child: _googleLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('G', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        SizedBox(width: 10),
                        Text('Continuar con Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Toggle register/login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRegister ? '¿Ya tienes cuenta? ' : '¿No tienes cuenta? ',
                style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _isRegister = !_isRegister;
                  ref.read(authProvider.notifier).clearError();
                }),
                child: Text(
                  _isRegister ? 'Inicia sesión' : 'Regístrate',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLines: 1,
      style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.destructive, width: 1.5),
        ),
      ),
      validator: validator,
      ),
    );
  }
}

// ── Branding Panel ─────────────────────────────────────────────────────────────
class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.show_chart, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 32),
          const Text('Shadow Health',
            style: TextStyle(color: AppTheme.foreground, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tu plataforma integral de salud y fitness.\nRegistra entrenamientos, nutrición y más.',
            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16, height: 1.6)),
          const SizedBox(height: 48),
          _feature(Icons.fitness_center, 'Entrenamientos', 'Planifica y registra tus sesiones'),
          const SizedBox(height: 20),
          _feature(Icons.restaurant, 'Nutrición', 'Controla comidas e hidratación'),
          const SizedBox(height: 20),
          _feature(Icons.monitor_heart, 'Salud', 'Sueño, cardio y frecuencia cardíaca'),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String title, String desc) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(desc, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
      ]),
    ]);
  }
}
