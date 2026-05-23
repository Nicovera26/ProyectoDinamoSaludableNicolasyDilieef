part of 'auth_bloc.dart';

abstract class AuthEvent {}

// ── Login Events ────────────────────────────────────────────────────────────

class LoginEmailChanged extends AuthEvent {
  final String email;
  LoginEmailChanged(this.email);
}

class LoginPasswordChanged extends AuthEvent {
  final String password;
  LoginPasswordChanged(this.password);
}

class LoginRememberMeChanged extends AuthEvent {
  final bool value;
  LoginRememberMeChanged(this.value);
}

class LoginSubmitted extends AuthEvent {}

// ── Register Events ─────────────────────────────────────────────────────────

class RegisterNombreChanged extends AuthEvent {
  final String nombre;
  RegisterNombreChanged(this.nombre);
}

class RegisterEdadChanged extends AuthEvent {
  final String edad;
  RegisterEdadChanged(this.edad);
}

class RegisterPesoChanged extends AuthEvent {
  final String peso;
  RegisterPesoChanged(this.peso);
}

class RegisterEmpresaChanged extends AuthEvent {
  final String empresa;
  RegisterEmpresaChanged(this.empresa);
}

class RegisterEmailChanged extends AuthEvent {
  final String email;
  RegisterEmailChanged(this.email);
}

class RegisterPasswordChanged extends AuthEvent {
  final String password;
  RegisterPasswordChanged(this.password);
}

class RegisterConfirmPasswordChanged extends AuthEvent {
  final String confirmPassword;
  RegisterConfirmPasswordChanged(this.confirmPassword);
}

class RegisterFechaNacimientoChanged extends AuthEvent {
  final DateTime fecha;
  RegisterFechaNacimientoChanged(this.fecha);
}

class RegisterSubmitted extends AuthEvent {}
