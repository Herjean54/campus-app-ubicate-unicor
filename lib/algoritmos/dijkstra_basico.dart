import '../modelo/grafo.dart';
import 'resultado.dart';

/// Línea base: busca el mínimo recorriendo todos los pendientes. O(V²).
class DijkstraBasico implements AlgoritmoRuta {
  @override
  String get nombre => 'Dijkstra básico';

  @override
  ResultadoRuta calcular(Grafo g, String origen, String destino) {
    final reloj = Stopwatch()..start();
    final dist = <String, double>{
      for (final n in g.nodos.keys) n: double.infinity
    };
    final previo = <String, String>{};
    final pendientes = <String>{...g.nodos.keys};
    dist[origen] = 0;
    var explorados = 0;

    while (pendientes.isNotEmpty) {
      String? actual;
      double menor = double.infinity;
      for (final n in pendientes) {
        if (dist[n]! < menor) {
          menor = dist[n]!;
          actual = n;
        }
      }
      if (actual == null) break; // el resto es inalcanzable
      pendientes.remove(actual);
      explorados++;
      if (actual == destino) break;

      for (final ar in g.vecinos[actual]!) {
        final nueva = dist[actual]! + ar.metros;
        if (nueva < dist[ar.destino]!) {
          dist[ar.destino] = nueva;
          previo[ar.destino] = actual;
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