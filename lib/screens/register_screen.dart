import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/field_helpers.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController   = TextEditingController();
  final _edadController     = TextEditingController();
  final _pesoController     = TextEditingController();
  final _empresaController  = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  static const Color _primary  = Color(0xFF0D6EFD);
  static const Color _darkText = Color(0xFF1A1A2E);

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _empresaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showToast(String msg, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? const Color(0xFFDC3545) : const Color(0xFF198754),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickFecha(BuildContext ctx) async {
    final now  = DateTime.now();
    final bloc = ctx.read<AuthBloc>();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: bloc.state.fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      bloc.add(RegisterFechaNacimientoChanged(picked));
      final now2 = DateTime.now();
      int edad = now2.year - picked.year;
      if (now2.month < picked.month ||
          (now2.month == picked.month && now2.day < picked.day)) edad--;
      _edadController.text = edad.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (ctx, state) {
          if (state.status == AuthStatus.success) {
            _showToast('¡Cuenta creada exitosamente! 🎉', isError: false);
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state.status == AuthStatus.failure) {
            _showToast(state.errorMessage ?? 'Revisa los datos ingresados.');
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkText,
        elevation: 0,
        title: const Text('Crear cuenta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(                                      // ← centrado
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Center(
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.3),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Completa tu perfil',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _darkText)),
                  ),
                  Center(
                    child: Text('Tus datos se guardan solo en este dispositivo',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ),

                  const SizedBox(height: 28),
                  _sectionLabel('Información personal'),
                  const SizedBox(height: 12),

                  _fieldLabel('Nombre completo'),
                  const SizedBox(height: 6),
                  _buildSimpleField(
                    controller: _nombreController,
                    fieldState: state.registerNombre,
                    hint: 'Ej. Ana García López',
                    prefixIcon: Icons.person_outline_rounded,
                    capitalization: TextCapitalization.words,
                    onChanged: (v) => bloc.add(RegisterNombreChanged(v)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _fieldLabel('Fecha de nacimiento'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _pickFecha(ctx),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: state.fechaNacimiento != null
                                      ? _formatFecha(state.fechaNacimiento!)
                                      : 'DD/MM/AAAA',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                                  enabledBorder: state.registerEdad.isInvalid
                                      ? OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFDC3545), width: 1.2),
                                        )
                                      : fieldBorderFor(FieldStatus.pure),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _fieldLabel('Edad'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _edadController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: '–',
                              suffixText: 'años',
                              suffixIcon: fieldStatusIcon(state.registerEdad.status),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  if (state.registerEdad.isInvalid && state.registerEdad.errorMessage != null)
                    fieldErrorText(state.registerEdad.errorMessage!),

                  const SizedBox(height: 16),

                  _fieldLabel('Peso'),
                  const SizedBox(height: 6),
                  _buildSimpleField(
                    controller: _pesoController,
                    fieldState: state.registerPeso,
                    hint: 'Ej. 70.5',
                    prefixIcon: Icons.monitor_weight_outlined,
                    suffixText: 'kg',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    onChanged: (v) => bloc.add(RegisterPesoChanged(v)),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Institución'),
                  const SizedBox(height: 6),
                  _buildSimpleField(
                    controller: _empresaController,
                    fieldState: state.registerEmpresa,
                    hint: 'Ej. Universidad de los Andes.',
                    prefixIcon: Icons.business_outlined,
                    capitalization: TextCapitalization.words,
                    onChanged: (v) => bloc.add(RegisterEmpresaChanged(v)),
                  ),

                  const SizedBox(height: 28),
                  _sectionLabel('Datos de acceso'),
                  const SizedBox(height: 12),

                  _fieldLabel('Correo electrónico'),
                  const SizedBox(height: 6),
                  _buildSimpleField(
                    controller: _emailController,
                    fieldState: state.registerEmail,
                    hint: 'nombre@correo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => bloc.add(RegisterEmailChanged(v)),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Contraseña'),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: _passwordController,
                    fieldState: state.registerPassword,
                    hint: 'Mín. 6 car., 1 mayúscula y 1 número',
                    obscure: _obscurePassword,
                    onChanged: (v) => bloc.add(RegisterPasswordChanged(v)),
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  if (!state.registerPassword.isPure)
                    _PasswordStrengthHints(password: state.registerPassword.value),
                  const SizedBox(height: 16),

                  _fieldLabel('Confirmar contraseña'),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: _confirmController,
                    fieldState: state.registerConfirmPassword,
                    hint: 'Repite tu contraseña',
                    obscure: _obscureConfirm,
                    onChanged: (v) => bloc.add(RegisterConfirmPasswordChanged(v)),
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    onSubmitted: (_) => bloc.add(RegisterSubmitted()),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: state.status == AuthStatus.loading
                        ? null
                        : () => bloc.add(RegisterSubmitted()),
                    child: state.status == AuthStatus.loading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Crear cuenta'),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿Ya tienes cuenta? ',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: _primary,
                        ),
                        child: const Text('Inicia sesión',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleField({
    required TextEditingController controller,
    required FieldState fieldState,
    required String hint,
    required IconData prefixIcon,
    required ValueChanged<String> onChanged,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textCapitalization: capitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            suffixText: suffixText,
            suffixIcon: fieldStatusIcon(fieldState.status),
            enabledBorder: fieldBorderFor(fieldState.status),
            focusedBorder: fieldBorderFor(fieldState.status, focused: true),
          ),
        ),
        if (fieldState.isInvalid && fieldState.errorMessage != null)
          fieldErrorText(fieldState.errorMessage!),
        if (fieldState.isValid && suffixText == null)
          fieldSuccessText('Campo válido ✓'),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FieldState fieldState,
    required String hint,
    required bool obscure,
    required ValueChanged<String> onChanged,
    required VoidCallback onToggle,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction:
              onSubmitted != null ? TextInputAction.done : TextInputAction.next,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggle,
            ),
            enabledBorder: fieldBorderFor(fieldState.status),
            focusedBorder: fieldBorderFor(fieldState.status, focused: true),
          ),
        ),
        if (fieldState.isInvalid && fieldState.errorMessage != null)
          fieldErrorText(fieldState.errorMessage!),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkText)),
        ]),
      );

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText),
      );
}

class _PasswordStrengthHints extends StatelessWidget {
  final String password;
  const _PasswordStrengthHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = {
      'Mínimo 6 caracteres':    password.length >= 6,
      'Al menos una mayúscula': RegExp(r'[A-Z]').hasMatch(password),
      'Al menos un número':     RegExp(r'\d').hasMatch(password),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: checks.entries.map((e) {
          final ok = e.value;
          return Row(children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 14,
              color: ok ? const Color(0xFF198754) : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(e.key,
                style: TextStyle(
                  fontSize: 12,
                  color: ok ? const Color(0xFF198754) : Colors.grey.shade500,
                )),
          ]);
        }).toList(),
      ),
    );
  }
}
