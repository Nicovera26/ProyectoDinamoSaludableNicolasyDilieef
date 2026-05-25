import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _loginEmailSubject       = BehaviorSubject<String>.seeded('');
  final _loginPasswordSubject    = BehaviorSubject<String>.seeded('');
  final _registerPasswordSubject = BehaviorSubject<String>.seeded('');

  Stream<String> get loginEmailStream    => _loginEmailSubject.stream;
  Stream<String> get loginPasswordStream => _loginPasswordSubject.stream;

  final List<StreamSubscription> _subscriptions = [];

  AuthBloc() : super(const AuthState()) {
    on<LoginEmailChanged>(_onLoginEmailChanged,           transformer: debounceTransformer());
    on<LoginPasswordChanged>(_onLoginPasswordChanged,     transformer: debounceTransformer());
    on<LoginRememberMeChanged>(_onLoginRememberMeChanged);
    on<LoginSubmitted>(_onLoginSubmitted);

    on<RegisterNombreChanged>(_onRegisterNombreChanged,               transformer: debounceTransformer());
    on<RegisterEdadChanged>(_onRegisterEdadChanged,                   transformer: debounceTransformer());
    on<RegisterPesoChanged>(_onRegisterPesoChanged,                   transformer: debounceTransformer());
    on<RegisterEmpresaChanged>(_onRegisterEmpresaChanged,             transformer: debounceTransformer());
    on<RegisterEmailChanged>(_onRegisterEmailChanged,                 transformer: debounceTransformer());
    on<RegisterPasswordChanged>(_onRegisterPasswordChanged,           transformer: debounceTransformer());
    on<RegisterConfirmPasswordChanged>(_onRegisterConfirmPasswordChanged, transformer: debounceTransformer());
    on<RegisterFechaNacimientoChanged>(_onRegisterFechaNacimientoChanged);
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  EventTransformer<T> debounceTransformer<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 350))
        .switchMap(mapper);
  }

  void _onLoginEmailChanged(LoginEmailChanged event, Emitter<AuthState> emit) {
    _loginEmailSubject.add(event.email);
    emit(state.copyWith(loginEmail: _validateEmail(event.email)));
  }

  void _onLoginPasswordChanged(LoginPasswordChanged event, Emitter<AuthState> emit) {
    _loginPasswordSubject.add(event.password);
    emit(state.copyWith(loginPassword: _validatePassword(event.password)));
  }

  void _onLoginRememberMeChanged(LoginRememberMeChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(rememberMe: event.value));
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    final emailField = _validateEmail(state.loginEmail.value, force: true);
    final passField  = _validatePassword(state.loginPassword.value, force: true);

    emit(state.copyWith(
      loginEmail:    emailField,
      loginPassword: passField,
      status:        AuthStatus.loading,
    ));

    if (!emailField.isValid || !passField.isValid) {
      emit(state.copyWith(
        status:       AuthStatus.failure,
        errorMessage: 'Por favor corrige los errores antes de continuar.',
      ));
      return;
    }

    final res = await ApiService.login(
      email:    state.loginEmail.value.trim(),
      password: state.loginPassword.value,
    );

    if (res.success) {

      final tokens = res.data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await ApiService.saveTokens(
          tokens['access'].toString(),
          tokens['refresh'].toString(),
        );
      }

      final user = res.data['user'] as Map<String, dynamic>?;
      if (user != null) await ApiService.saveUser(user);

      if (state.rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
      }

      emit(state.copyWith(status: AuthStatus.success));
    } else {
      emit(state.copyWith(
        status:       AuthStatus.failure,
        errorMessage: res.errorMessage,
      ));
    }
  }

  void _onRegisterNombreChanged(RegisterNombreChanged event, Emitter<AuthState> emit) =>
      emit(state.copyWith(registerNombre: _validateNombre(event.nombre)));

  void _onRegisterEdadChanged(RegisterEdadChanged event, Emitter<AuthState> emit) =>
      emit(state.copyWith(registerEdad: _validateEdad(event.edad)));

  void _onRegisterPesoChanged(RegisterPesoChanged event, Emitter<AuthState> emit) =>
      emit(state.copyWith(registerPeso: _validatePeso(event.peso)));

  void _onRegisterEmpresaChanged(RegisterEmpresaChanged event, Emitter<AuthState> emit) =>
      emit(state.copyWith(registerEmpresa: _validateEmpresa(event.empresa)));

  void _onRegisterEmailChanged(RegisterEmailChanged event, Emitter<AuthState> emit) =>
      emit(state.copyWith(registerEmail: _validateEmail(event.email)));

  void _onRegisterPasswordChanged(RegisterPasswordChanged event, Emitter<AuthState> emit) {
    _registerPasswordSubject.add(event.password);
    final passField    = _validatePassword(event.password);
    final confirmField = state.registerConfirmPassword.value.isEmpty
        ? state.registerConfirmPassword
        : _validateConfirmPassword(
            state.registerConfirmPassword.value, event.password);
    emit(state.copyWith(
      registerPassword:        passField,
      registerConfirmPassword: confirmField,
    ));
  }

  void _onRegisterConfirmPasswordChanged(
      RegisterConfirmPasswordChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      registerConfirmPassword: _validateConfirmPassword(
          event.confirmPassword, state.registerPassword.value),
    ));
  }

  void _onRegisterFechaNacimientoChanged(
      RegisterFechaNacimientoChanged event, Emitter<AuthState> emit) {
    final now  = DateTime.now();
    int edad   = now.year - event.fecha.year;
    if (now.month < event.fecha.month ||
        (now.month == event.fecha.month && now.day < event.fecha.day)) {
      edad--;
    }
    emit(state.copyWith(
      fechaNacimiento: event.fecha,
      registerEdad: FieldState(value: edad.toString(), status: FieldStatus.valid),
    ));
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    final nombre  = _validateNombre(state.registerNombre.value,   force: true);
    final edad    = _validateEdad(state.registerEdad.value,       force: true);
    final peso    = _validatePeso(state.registerPeso.value,       force: true);
    final empresa = _validateEmpresa(state.registerEmpresa.value, force: true);
    final email   = _validateEmail(state.registerEmail.value,     force: true);
    final pass    = _validatePassword(state.registerPassword.value, force: true);
    final confirm = _validateConfirmPassword(
        state.registerConfirmPassword.value,
        state.registerPassword.value,
        force: true);

    emit(state.copyWith(
      registerNombre:          nombre,
      registerEdad:            edad,
      registerPeso:            peso,
      registerEmpresa:         empresa,
      registerEmail:           email,
      registerPassword:        pass,
      registerConfirmPassword: confirm,
      status:                  AuthStatus.loading,
    ));

    final allValid = nombre.isValid && edad.isValid && peso.isValid &&
        empresa.isValid && email.isValid && pass.isValid &&
        confirm.isValid && state.fechaNacimiento != null;

    if (!allValid) {
      emit(state.copyWith(
        status:       AuthStatus.failure,
        errorMessage: state.fechaNacimiento == null
            ? 'Selecciona tu fecha de nacimiento.'
            : 'Por favor corrige los errores antes de continuar.',
      ));
      return;
    }

    final res = await ApiService.register(
      nombre:           state.registerNombre.value.trim(),
      email:            state.registerEmail.value.trim(),
      password:         state.registerPassword.value,
      confirmPassword:  state.registerConfirmPassword.value,
      empresa:          state.registerEmpresa.value.trim(),
      peso:             double.parse(state.registerPeso.value.trim()),
      fechaNacimiento:  state.fechaNacimiento!,
    );

    if (res.success) {

      final tokens = res.data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await ApiService.saveTokens(
          tokens['access'].toString(),
          tokens['refresh'].toString(),
        );
      }

      final user = res.data['user'] as Map<String, dynamic>?;
      if (user != null) await ApiService.saveUser(user);

      emit(state.copyWith(status: AuthStatus.success));
    } else {
      emit(state.copyWith(
        status:       AuthStatus.failure,
        errorMessage: res.errorMessage,
      ));
    }
  }


  static FieldState _validateEmail(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.trim().isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa tu correo electrónico');
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa un correo válido');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validatePassword(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa una contraseña');
    if (value.length < 6) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Mínimo 6 caracteres');
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Debe incluir al menos una mayúscula');
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Debe incluir al menos un número');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validateConfirmPassword(String value, String password, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Confirma tu contraseña');
    if (value != password) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Las contraseñas no coinciden');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validateNombre(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.trim().isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa tu nombre completo');
    if (value.trim().length < 3) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Nombre muy corto');
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value.trim())) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Solo se permiten letras');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validateEdad(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.trim().isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Selecciona tu fecha de nacimiento');
    final edad = int.tryParse(value.trim());
    if (edad == null || edad < 5 || edad > 110) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Edad inválida (5–110)');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validatePeso(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.trim().isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa tu peso');
    final peso = double.tryParse(value.trim());
    if (peso == null || peso < 20 || peso > 300) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Peso inválido (20–300 kg)');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  static FieldState _validateEmpresa(String value, {bool force = false}) {
    if (value.isEmpty && !force) return FieldState(value: value);
    if (value.trim().isEmpty) return FieldState(value: value, status: FieldStatus.invalid, errorMessage: 'Ingresa tu empresa o institución');
    return FieldState(value: value, status: FieldStatus.valid);
  }

  @override
  Future<void> close() async {
    await _loginEmailSubject.close();
    await _loginPasswordSubject.close();
    await _registerPasswordSubject.close();
    for (final sub in _subscriptions) await sub.cancel();
    return super.close();
  }
}
