import 'package:flutter/material.dart';
import '../bloc/auth_bloc.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  field_helpers.dart                                                      ║
// ║  Helpers visuales compartidos entre LoginScreen y RegisterScreen         ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// Ícono de estado a la derecha del campo (check verde / error rojo)
Widget? fieldStatusIcon(FieldStatus status) {
  if (status == FieldStatus.valid) {
    return const Icon(Icons.check_circle_outline, color: Color(0xFF198754));
  }
  if (status == FieldStatus.invalid) {
    return const Icon(Icons.error_outline, color: Color(0xFFDC3545));
  }
  return null;
}

/// Borde coloreado según el estado del campo
OutlineInputBorder fieldBorderFor(FieldStatus status, {bool focused = false}) {
  Color color;
  if (status == FieldStatus.valid) {
    color = const Color(0xFF198754);
  } else if (status == FieldStatus.invalid) {
    color = const Color(0xFFDC3545);
  } else {
    color = focused ? const Color(0xFF0D6EFD) : Colors.grey.shade300;
  }
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: focused ? 2 : 1.2),
  );
}

/// Texto de error rojo debajo del campo
Widget fieldErrorText(String msg) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 12, color: Color(0xFFDC3545)),
      ),
    );

/// Texto de éxito verde debajo del campo
Widget fieldSuccessText(String msg) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 12, color: Color(0xFF198754)),
      ),
    );
