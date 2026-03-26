import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Google Sign-In instance.
/// TODO: Replace 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'
/// with your actual OAuth 2.0 Web Client ID from Google Cloud Console.
final _googleSignIn = GoogleSignIn(
  clientId: '177898872987-6rqc6e350tmfocuuhh37ralkfdb9tneg.apps.googleusercontent.com',
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
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() => _googleLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al obtener token de Google.')),
          );
        }
        return;
      }
      final success = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (success && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Google Sign-In: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            // Left branding panel
            Expanded(
              flex: 55,
              child: _BrandingPanel(),
            ),
            // Right form panel
            Expanded(
              flex: 45,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _LoginForm(
                          formKey: _formKey,
                          emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl,
                          emailFocus: _emailFocus,
                          passFocus: _passFocus,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onLogin: _login,
                          onGoogleLogin: _loginWithGoogle,
                          state: state,
                          googleLoading: _googleLoading,
                          showMobileLogo: false,
                        ),
                      ),
                    ),
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
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _LoginForm(
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                emailFocus: _emailFocus,
                passFocus: _passFocus,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onLogin: _login,
                onGoogleLogin: _loginWithGoogle,
                state: state,
                googleLoading: _googleLoading,
                showMobileLogo: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Left branding panel (desktop only) ───────────────────────────────────────
class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.05),
            AppTheme.background,
            AppTheme.primary.withOpacity(0.03),
          ],
        ),
        border: const Border(
          right: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.show_chart,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Shadow Health',
                  style: TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Hero text
            const Text(
              'Tu compañero de\nfitness modular',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Entrena, aliméntate y monitorea tu cuerpo con una plataforma inteligente que se adapta a ti.',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            // Features
            _FeatureRow(
              icon: Icons.fitness_center,
              color: AppTheme.primary,
              title: 'Plannings y rutinas personalizadas',
              subtitle:
                  'Organiza tu entrenamiento por día con máquinas y ejercicios',
            ),
            const SizedBox(height: 20),
            _FeatureRow(
              icon: Icons.restaurant_outlined,
              color: AppTheme.blue400,
              title: 'Nutrición y suplementos',
              subtitle:
                  'Registra comidas, macros, hidratación y suplementos',
            ),
            const SizedBox(height: 20),
            _FeatureRow(
              icon: Icons.monitor_heart_outlined,
              color: AppTheme.violet400,
              title: 'Salud y dispositivos',
              subtitle:
                  'Conecta wearables, monitorea FC, sueño y cardio',
            ),
            const Spacer(),
            const Text(
              'Shadow Health v1.0.0',
              style: TextStyle(
                  color: AppTheme.mutedForeground, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Login Form ────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final FocusNode emailFocus;
  final FocusNode passFocus;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final AuthState state;
  final bool googleLoading;
  final bool showMobileLogo;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.emailFocus,
    required this.passFocus,
    required this.obscure,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.state,
    required this.googleLoading,
    required this.showMobileLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mobile logo
          if (showMobileLogo) ...[
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.show_chart,
                    color: AppTheme.primary, size: 32),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Title
          const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresa a tu cuenta para continuar',
            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Error
          if (state.error != null) ...[
            _ErrorBanner(message: state.error!),
            const SizedBox(height: 16),
          ],

          // Email
          const _FieldLabel(text: 'Email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: emailCtrl,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofocus: false,
            maxLines: 1,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration: _inputDeco(hint: 'tu@email.com', icon: Icons.mail_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
            onFieldSubmitted: (_) => passFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel(text: 'Contraseña'),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: passCtrl,
            focusNode: passFocus,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            autofocus: false,
            maxLines: 1,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration: _inputDeco(
              hint: 'Min. 6 caracteres',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.primary.withOpacity(0.7),
                  size: 18,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
            onFieldSubmitted: (_) => onLogin(),
          ),
          const SizedBox(height: 24),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o continuar con',
                  style: const TextStyle(
                      color: AppTheme.mutedForeground, fontSize: 12),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.border)),
            ],
          ),
          const SizedBox(height: 20),

          // Google Sign In
          _GoogleButton(
            onPressed: (googleLoading || state.isLoading) ? null : onGoogleLogin,
            isLoading: googleLoading,
          ),
          const SizedBox(height: 24),

          // Register link
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppTheme.mutedForeground, fontSize: 14),
                children: [
                  const TextSpan(text: '¿No tienes cuenta? '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => GoRouter.of(context).push('/register'),
                      child: const Text(
                        'Crea una gratis',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppTheme.primary, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'SEGURO Y PRIVADO',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tus datos se almacenan de forma segura. Crea una cuenta para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
      prefixIcon: Icon(icon,
          color: AppTheme.primary.withOpacity(0.7), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppTheme.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        borderSide:
            const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppTheme.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppTheme.destructive, width: 1.5),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.foreground,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.destructive.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.destructive, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.destructive, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.foreground,
          side: const BorderSide(color: AppTheme.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.surface,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Google G icon (simplified)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.mutedForeground.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
