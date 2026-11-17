import 'package:flutter/services.dart' show rootBundle;
import 'grafo.dart';

Future<Grafo> cargarGrafo() async {
  final texto = await rootBundle.loadString('assets/campus.json');
  return Grafo.desdeJson(texto);
}