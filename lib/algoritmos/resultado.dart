import '../modelo/grafo.dart';

class ResultadoRuta {
  final List<String> camino; // vacío = no hay ruta
  final double metros;
  final int explorados; // nodos que el algoritmo procesó
  final int microsegundos; // tiempo de ejecución

  const ResultadoRuta(
      this.camino, this.metros, this.explorados, this.microsegundos);

  bool get existe => camino.isNotEmpty;
}

abstract class AlgoritmoRuta {
  String get nombre;
  ResultadoRuta calcular(Grafo g, String origen, String destino);
}