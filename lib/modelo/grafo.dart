import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Arista {
  final String destino;
  final double metros;
  final List<LatLng> forma; // curva real del sendero, de origen a destino
  Arista(this.destino, this.metros, [this.forma = const []]);
}

/// Modelo: G = (V, E, w). V = nodos, E = senderos, w = longitud en metros.
class Grafo {
  final Map<String, LatLng> nodos = {};
  final Map<String, List<Arista>> vecinos = {};

  int get totalNodos => nodos.length;
  int get totalAristas =>
      vecinos.values.fold(0, (s, l) => s + l.length) ~/ 2;

  /// Construye el grafo desde el texto de 
  static Grafo desdeJson(String texto) {
    final datos = jsonDecode(texto) as Map<String, dynamic>;
    final g = Grafo();

    (datos['nodos'] as Map<String, dynamic>).forEach((id, coord) {
      g.nodos[id] = LatLng(
        (coord[0] as num).toDouble(),
        (coord[1] as num).toDouble(),
      );
      g.vecinos[id] = [];
    });

    for (final a in datos['aristas'] as List<dynamic>) {
      final u = a[0] as String;
      final v = a[1] as String;
      final m = (a[2] as num).toDouble();
      final forma = (a.length > 3 ? a[3] as List<dynamic> : <dynamic>[])
          .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList();
      g.vecinos[u]!.add(Arista(v, m, forma));
      g.vecinos[v]!.add(Arista(u, m, forma.reversed.toList()));
    }
    return g;
  }

  String nodoMasCercano(LatLng punto) {
    const distancia = Distance();
    String? mejor;
    double mejorDist = double.infinity;
    nodos.forEach((id, pos) {
      final d = distancia.as(LengthUnit.Meter, punto, pos);
      if (d < mejorDist) {
        mejorDist = d;
        mejor = id;
      }
    });
    return mejor!;
  }

  // Si hay varias aristas entre los mismos nodos, toma la más corta
  Arista _arista(String a, String b) {
    return vecinos[a]!
        .where((x) => x.destino == b)
        .reduce((x, y) => x.metros <= y.metros ? x : y);
  }

  double longitudRuta(List<String> camino) {
    double total = 0;
    for (var i = 0; i < camino.length - 1; i++) {
      total += _arista(camino[i], camino[i + 1]).metros;
    }
    return total;
  }

  // Puntos de la ruta siguiendo las curvas reales de los senderos
  List<LatLng> puntosRuta(List<String> camino) {
    if (camino.isEmpty) return [];
    if (camino.length == 1) return [nodos[camino.first]!];

    final puntos = <LatLng>[];
    for (var i = 0; i < camino.length - 1; i++) {
      final ar = _arista(camino[i], camino[i + 1]);
      if (ar.forma.isNotEmpty) {
        puntos.addAll(ar.forma);
      } else {
        puntos.add(nodos[camino[i]]!);
        puntos.add(nodos[camino[i + 1]]!);
      }
    }
    return puntos;
  }
}