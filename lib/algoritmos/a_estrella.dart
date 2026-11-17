import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../modelo/grafo.dart';
import 'resultado.dart';

class _Entrada {
  final String nodo;
  final double prioridad; // g + h
  _Entrada(this.nodo, this.prioridad);
}

/// A* con heurística de distancia en línea recta (admisible).
class AEstrella implements AlgoritmoRuta {
  @override
  String get nombre => 'A*';

  @override
  ResultadoRuta calcular(Grafo g, String origen, String destino) {
    final reloj = Stopwatch()..start();
    const geo = Distance();
    final meta = g.nodos[destino]!;
    double h(String n) => geo.as(LengthUnit.Meter, g.nodos[n]!, meta);

    final dist = <String, double>{
      for (final n in g.nodos.keys) n: double.infinity
    };
    final previo = <String, String>{};
    final cerrados = <String>{};
    final cola =
        PriorityQueue<_Entrada>((a, b) => a.prioridad.compareTo(b.prioridad));

    dist[origen] = 0;
    cola.add(_Entrada(origen, h(origen)));
    var explorados = 0;

    while (cola.isNotEmpty) {
      final actual = cola.removeFirst().nodo;
      if (!cerrados.add(actual)) continue;
      explorados++;
      if (actual == destino) break;

      for (final ar in g.vecinos[actual]!) {
        final nueva = dist[actual]! + ar.metros;
        if (nueva < dist[ar.destino]!) {
          dist[ar.destino] = nueva;
          previo[ar.destino] = actual;
          cola.add(_Entrada(ar.destino, nueva + h(ar.destino)));
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