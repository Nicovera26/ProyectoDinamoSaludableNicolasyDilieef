import 'package:flutter/material.dart';
import '../bloc/auth_bloc.dart';


Widget? fieldStatusIcon(FieldStatus status) {
  if (status == FieldStatus.valid) {
    return const Icon(Icons.check_circle_outline, color: Color(0xFF198754));
  }
  if (status == FieldStatus.invalid) {
    return const Icon(Icons.error_outline, color: Color(0xFFDC3545));
  }
  return null;
}

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

Widget fieldErrorText(String msg) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 12, color: Color(0xFFDC3545)),
      ),
    );

Widget fieldSuccessText(String msg) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 12, color: Color(0xFF198754)),
      ),
    );
