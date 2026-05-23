import 'package:flutter/material.dart';

class ReporteForm extends StatefulWidget {
  const ReporteForm({super.key});

  @override
  State<ReporteForm> createState() => _ReporteFormState();
}

class _ReporteFormState extends State<ReporteForm> {
  final _formKey = GlobalKey<FormState>();
  final _notasController = TextEditingController();

  static const Color _primary = Color(0xFF0D6EFD);

  String _nivelEnergia   = 'Bueno';
  String _dolor          = 'Ninguno';
  double _satisfaccion   = 4;
  bool   _completoRutina = true;
  bool   _enviando       = false;

  final List<String> _nivelesEnergia = ['Muy bajo', 'Bajo', 'Normal', 'Bueno', 'Excelente'];
  final List<String> _nivelesDolor   = ['Ninguno', 'Leve', 'Moderado', 'Fuerte'];

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _enviando = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Reporte guardado correctamente'),
        ]),
        backgroundColor: const Color(0xFF198754),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Reporte de Sesión',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header info ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: _primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Registra cómo te sentiste en tu sesión de hoy',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Completó la rutina ──
              _SectionCard(
                title: '¿Completaste la rutina completa?',
                child: Row(children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Sí, completa',
                      icon: Icons.check_circle_rounded,
                      selected: _completoRutina,
                      color: const Color(0xFF198754),
                      onTap: () => setState(() => _completoRutina = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Parcialmente',
                      icon: Icons.radio_button_checked_rounded,
                      selected: !_completoRutina,
                      color: const Color(0xFFFFC107),
                      onTap: () => setState(() => _completoRutina = false),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // ── Nivel de energía ──
              _SectionCard(
                title: 'Nivel de energía',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _nivelesEnergia.map((n) {
                    final sel = n == _nivelEnergia;
                    return GestureDetector(
                      onTap: () => setState(() => _nivelEnergia = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? _primary : Colors.grey.shade300),
                        ),
                        child: Text(n,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : Colors.grey.shade700,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ── Dolor o molestia ──
              _SectionCard(
                title: 'Dolor o molestia',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _nivelesDolor.map((d) {
                    final sel = d == _dolor;
                    final Color col = d == 'Ninguno'
                        ? const Color(0xFF198754)
                        : d == 'Leve'
                            ? const Color(0xFFFFC107)
                            : d == 'Moderado'
                                ? const Color(0xFFFF8C00)
                                : const Color(0xFFDC3545);
                    return GestureDetector(
                      onTap: () => setState(() => _dolor = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? col : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? col : Colors.grey.shade300),
                        ),
                        child: Text(d,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : Colors.grey.shade700,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // ── Satisfacción ──
              _SectionCard(
                title: 'Satisfacción general  ${_satisfaccion.round()}/5',
                child: Column(
                  children: [
                    Slider(
                      value: _satisfaccion,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: _primary,
                      inactiveColor: _primary.withValues(alpha: 0.2),
                      onChanged: (v) => setState(() => _satisfaccion = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (i) {
                        final active = i < _satisfaccion.round();
                        return Icon(
                          active ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: active ? const Color(0xFFFFC107) : Colors.grey.shade300,
                          size: 28,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Notas adicionales ──
              _SectionCard(
                title: 'Notas adicionales (opcional)',
                child: TextFormField(
                  controller: _notasController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escribe observaciones sobre tu sesión...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón enviar ──
              ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _enviando
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Guardar reporte'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ToggleOption({
    required this.label, required this.icon,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? color : Colors.grey.shade400, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey.shade600,
              )),
        ]),
      ),
    );
  }
}
