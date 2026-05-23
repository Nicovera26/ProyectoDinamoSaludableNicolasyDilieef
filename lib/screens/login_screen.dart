import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/field_helpers.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  static const Color _primary  = Color(0xFF0D6EFD);
  static const Color _darkText = Color(0xFF1A1A2E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showToast(String msg, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor:
          isError ? const Color(0xFFDC3545) : const Color(0xFF198754),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _navigateHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (ctx, state) {
          if (state.status == AuthStatus.success) {
            _showToast('¡Bienvenido!', isError: false);
            _navigateHome();
          } else if (state.status == AuthStatus.failure) {
            _showToast(state.errorMessage ?? 'Error al iniciar sesión');
          }
        },
        builder: (ctx, state) => _buildScaffold(ctx, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext ctx, AuthState state) {
    final bloc = ctx.read<AuthBloc>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),

                  // ── Email ─────────────────────────────────────────────
                  _fieldLabel('Correo electrónico'),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) => bloc.add(LoginEmailChanged(v)),
                        decoration: InputDecoration(
                          hintText: 'tu@correo.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixIcon: fieldStatusIcon(state.loginEmail.status),
                          enabledBorder: fieldBorderFor(state.loginEmail.status),
                          focusedBorder: fieldBorderFor(state.loginEmail.status, focused: true),
                        ),
                      ),
                      if (state.loginEmail.isInvalid && state.loginEmail.errorMessage != null)
                        fieldErrorText(state.loginEmail.errorMessage!),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Contraseña ────────────────────────────────────────
                  _fieldLabel('Contraseña'),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (v) => bloc.add(LoginPasswordChanged(v)),
                        onFieldSubmitted: (_) => bloc.add(LoginSubmitted()),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: fieldBorderFor(state.loginPassword.status),
                          focusedBorder: fieldBorderFor(state.loginPassword.status, focused: true),
                        ),
                      ),
                      if (state.loginPassword.isInvalid && state.loginPassword.errorMessage != null)
                        fieldErrorText(state.loginPassword.errorMessage!),
                      if (state.loginPassword.isValid)
                        fieldSuccessText('Contraseña segura ✓'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Recordarme + Olvidé ───────────────────────────────
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: state.rememberMe,
                          activeColor: _primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) =>
                              bloc.add(LoginRememberMeChanged(v ?? false)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Recordarme',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showForgotDialog(ctx),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: _primary,
                        ),
                        child: const Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Botón ─────────────────────────────────────────────
                  ElevatedButton(
                    onPressed: state.status == AuthStatus.loading
                        ? null
                        : () => bloc.add(LoginSubmitted()),
                    child: state.status == AuthStatus.loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 32),

                  // ── Ir a Registro ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿No tienes cuenta? ',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: _primary,
                        ),
                        child: const Text('Regístrate',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.self_improvement_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 22),
        const Text(
          'Pausas Activas',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _darkText,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor de Posturas Inteligente',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText),
      );

  void _showForgotDialog(BuildContext ctx) {
    final forgotController = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo y te enviaremos un enlace de recuperación.'),
            const SizedBox(height: 16),
            TextField(
              controller: forgotController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast('Correo de recuperación enviado ✓', isError: false);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
