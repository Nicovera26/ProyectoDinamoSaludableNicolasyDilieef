part of 'auth_bloc.dart';

// ── Estados de validación individual de campo ────────────────────────────────

enum FieldStatus { pure, valid, invalid }

class FieldState {
  final String value;
  final FieldStatus status;
  final String? errorMessage;

  const FieldState({
    this.value = '',
    this.status = FieldStatus.pure,
    this.errorMessage,
  });

  bool get isValid => status == FieldStatus.valid;
  bool get isInvalid => status == FieldStatus.invalid;
  bool get isPure => status == FieldStatus.pure;

  FieldState copyWith({
    String? value,
    FieldStatus? status,
    String? errorMessage,
  }) {
    return FieldState(
      value: value ?? this.value,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ── Estado global del AuthBloc ───────────────────────────────────────────────

enum AuthStatus { idle, loading, success, failure }

class AuthState {
  // Login
  final FieldState loginEmail;
  final FieldState loginPassword;
  final bool rememberMe;

  // Register
  final FieldState registerNombre;
  final FieldState registerEdad;
  final FieldState registerPeso;
  final FieldState registerEmpresa;
  final FieldState registerEmail;
  final FieldState registerPassword;
  final FieldState registerConfirmPassword;
  final DateTime? fechaNacimiento;

  // Common
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.loginEmail = const FieldState(),
    this.loginPassword = const FieldState(),
    this.rememberMe = false,
    this.registerNombre = const FieldState(),
    this.registerEdad = const FieldState(),
    this.registerPeso = const FieldState(),
    this.registerEmpresa = const FieldState(),
    this.registerEmail = const FieldState(),
    this.registerPassword = const FieldState(),
    this.registerConfirmPassword = const FieldState(),
    this.fechaNacimiento,
    this.status = AuthStatus.idle,
    this.errorMessage,
  });

  bool get isLoginValid => loginEmail.isValid && loginPassword.isValid;

  bool get isRegisterValid =>
      registerNombre.isValid &&
      registerEdad.isValid &&
      registerPeso.isValid &&
      registerEmpresa.isValid &&
      registerEmail.isValid &&
      registerPassword.isValid &&
      registerConfirmPassword.isValid &&
      fechaNacimiento != null;

  AuthState copyWith({
    FieldState? loginEmail,
    FieldState? loginPassword,
    bool? rememberMe,
    FieldState? registerNombre,
    FieldState? registerEdad,
    FieldState? registerPeso,
    FieldState? registerEmpresa,
    FieldState? registerEmail,
    FieldState? registerPassword,
    FieldState? registerConfirmPassword,
    DateTime? fechaNacimiento,
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      loginEmail: loginEmail ?? this.loginEmail,
      loginPassword: loginPassword ?? this.loginPassword,
      rememberMe: rememberMe ?? this.rememberMe,
      registerNombre: registerNombre ?? this.registerNombre,
      registerEdad: registerEdad ?? this.registerEdad,
      registerPeso: registerPeso ?? this.registerPeso,
      registerEmpresa: registerEmpresa ?? this.registerEmpresa,
      registerEmail: registerEmail ?? this.registerEmail,
      registerPassword: registerPassword ?? this.registerPassword,
      registerConfirmPassword:
          registerConfirmPassword ?? this.registerConfirmPassword,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
