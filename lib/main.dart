import 'package:flutter/material.dart';
import 'ui/pantalla_inicio.dart';

void main() {
  runApp(const UbicateUnicor());
}

class UbicateUnicor extends StatelessWidget {
  const UbicateUnicor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ubícate Unicor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      home: const PantallaInicio(),
    );
  }
}