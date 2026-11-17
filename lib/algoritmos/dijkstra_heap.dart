import 'package:collection/collection.dart';
import '../modelo/grafo.dart';
import 'resultado.dart';

class _Entrada {
  final String nodo;
  final double prioridad;
  _Entrada(this.nodo, this.prioridad);
}

/// Dijkstra con cola de prioridad (heap binario). O(E log V).
class DijkstraHeap implements AlgoritmoRuta {
  @override
  String get nombre => 'Dijkstra con heap';

  @override
  ResultadoRuta calcular(Grafo g, String origen, String destino) {
    final reloj = Stopwatch()..start();
    final dist = <String, double>{
      for (final n in g.nodos.keys) n: double.infinity
    };
    final previo = <String, String>{};
    final cerrados = <String>{};
    final cola =
        PriorityQueue<_Entrada>((a, b) => a.prioridad.compareTo(b.prioridad));

    dist[origen] = 0;
    cola.add(_Entrada(origen, 0));
    var explorados = 0;

    while (cola.isNotEmpty) {
      final actual = cola.removeFirst().nodo;
      if (!cerrados.add(actual)) continue; // entrada vieja repetida
      explorados++;
      if (actual == destino) break;

      for (final ar in g.vecinos[actual]!) {
        final nueva = dist[actual]! + ar.metros;
        if (nueva < dist[ar.destino]!) {
          dist[ar.destino] = nueva;
          previo[ar.destino] = actual;
          cola.add(_Entrada(ar.destino, nueva));
        }
      }
    }

    var camino = <String>[];
    if (dist[destino]! < double.infinity) {
      String? paso = destino;
      while (paso != null) {
        camino.add(paso);
        paso = previo[paso];
      }
      camino = camino.reversed.toList();
    }
    reloj.stop();
    return ResultadoRuta(
      camino,
      camino.isEmpty ? double.infinity : dist[destino]!,
      explorados,
      reloj.elapsedMicroseconds,
    );
  }
}