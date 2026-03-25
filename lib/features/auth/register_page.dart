import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _googleLoading = false;
  String? _localError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _localError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _localError = 'Las contraseñas no coinciden');
      return;
    }
    final success = await ref.read(authProvider.notifier).register(
          _nameCtrl.text.trim(),
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
        setState(() {
          _googleLoading = false;
          _localError = 'Ocurrió un error al iniciar sesión con Google.';
        });
        return;
      }
      final success =
          await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (success && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localError = 'Error al conectar con Google.';
        });
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
    final displayError = _localError ?? state.error;

    final form = _buildForm(context, state, displayError);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            Expanded(flex: 55, child: _BrandingPanel()),
            Expanded(
              flex: 45,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 64, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
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
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: form,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, AuthState state, String? displayError) {
    InputDecoration inputDeco({
      required String hint,
      required IconData icon,
      Widget? suffix,
    }) =>
        InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppTheme.mutedForeground, fontSize: 14),
          prefixIcon: Icon(icon,
              color: AppTheme.primary.withOpacity(0.7), size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: AppTheme.destructive),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.destructive, width: 1.5),
          ),
        );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mobile logo
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

          const Text(
            'Crear Cuenta',
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Empieza tu viaje fitness hoy',
            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
          ),
          const SizedBox(height: 32),

          if (displayError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.destructive.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.destructive, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayError,
                      style: const TextStyle(
                          color: AppTheme.destructive, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Name
          const _Label('Nombre'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            autofocus: false,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration: inputDeco(
                hint: 'Tu nombre completo', icon: Icons.person_outline),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            onFieldSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Email
          const _Label('Email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofocus: false,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration:
                inputDeco(hint: 'tu@email.com', icon: Icons.mail_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
            onFieldSubmitted: (_) => _passFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Passwords (2 columns on desktop, stacked on mobile)
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 400;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: _passField(inputDeco)),
                  const SizedBox(width: 12),
                  Expanded(child: _confirmField(inputDeco)),
                ],
              );
            }
            return Column(
              children: [
                _passField(inputDeco),
                const SizedBox(height: 16),
                _confirmField(inputDeco),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Register button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _register,
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
                        Icon(Icons.person_add_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Crear Cuenta',
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o continuar con',
                  style: TextStyle(
                      color: AppTheme.mutedForeground, fontSize: 12),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.border)),
            ],
          ),
          const SizedBox(height: 20),

          // Google button
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed:
                  (_googleLoading || state.isLoading) ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.foreground,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppTheme.surface,
              ),
              child: _googleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GoogleIcon(),
                        SizedBox(width: 10),
                        Text(
                          'Continuar con Google',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.foreground),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Login link
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppTheme.mutedForeground, fontSize: 14),
                children: [
                  const TextSpan(text: '¿Ya tienes cuenta? '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => GoRouter.of(context).go('/login'),
                      child: const Text(
                        'Inicia Sesión',
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
        ],
      ),
    );
  }

  Widget _passField(InputDecoration Function({required String hint, required IconData icon, Widget? suffix}) inputDeco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Contraseña'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          focusNode: _passFocus,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          autofocus: false,
          style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
          decoration: inputDeco(
            hint: 'Min. 6 caracteres',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.primary.withOpacity(0.7),
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa una contraseña';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _confirmField(InputDecoration Function({required String hint, required IconData icon, Widget? suffix}) inputDeco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Confirmar'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofocus: false,
          style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
          decoration: inputDeco(
            hint: 'Repite la contraseña',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.primary.withOpacity(0.7),
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirma la contraseña';
            return null;
          },
          onFieldSubmitted: (_) => _register(),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
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

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => Container(
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
      );
}

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
      child: const Padding(
        padding: EdgeInsets.all(64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF1A2A1A),
                  radius: 20,
                  child: Icon(Icons.show_chart,
                      color: AppTheme.primary, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Shadow Health',
                  style: TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              'Tu compañero de\nfitness modular',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Entrena, aliméntate y monitorea tu cuerpo con una plataforma inteligente.',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            Spacer(),
            Text(
              'Shadow Health v1.0.0',
              style:
                  TextStyle(color: AppTheme.mutedForeground, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
