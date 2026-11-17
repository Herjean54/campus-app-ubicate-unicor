import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'ficha_lugar.dart';
import '../modelo/grafo.dart';
import '../modelo/lugares.dart';
import '../algoritmos/dijkstra_basico.dart';
import '../modelo/cargador.dart';

const miUbicacion = 'Mi ubicación';

// true = puedes simular tu posición con un clic sostenido en el mapa.
// Ponlo en false cuando pruebes con el GPS real en el celular.
const bool modoPrueba = true;

String _normalizar(String s) {
  const de = 'áéíóúüñ';
  const a = 'aeiouun';
  var r = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], a[i]);
  }
  return r;
}

// Campo de texto con menú desplegable de lugares
class CampoLugar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String etiqueta;
  final IconData icono;
  final Color color;
  final ValueChanged<String> alElegir;
  final List<String> extras; // opciones especiales, ej. "Mi ubicación"

  const CampoLugar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.alElegir,
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width - 100;

    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (valor) {
        final todos = [...extras, ...lugares.keys];
        final q = _normalizar(valor.text.trim());
        if (q.isEmpty) return todos;
        return todos.where((n) => _normalizar(n).contains(q));
      },
      onSelected: alElegir,
      fieldViewBuilder: (context, c, f, onSubmit) {
        return TextField(
          controller: c,
          focusNode: f,
          decoration: InputDecoration(
            labelText: etiqueta,
            prefixIcon: Icon(icono, color: color),
            suffixIcon: c.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => c.clear(),
                  ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, opciones) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260, maxWidth: ancho),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opciones.length,
                itemBuilder: (_, i) {
                  final nombre = opciones.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      nombre == miUbicacion
                          ? Icons.my_location
                          : Icons.place_outlined,
                      color: nombre == miUbicacion
                          ? const Color(0xFF1E88E5)
                          : null,
                    ),
                    title: Text(nombre),
                    onTap: () => onSelected(nombre),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  Grafo? grafo;
  String? origen;
  String? destino;
  List<LatLng> ruta = [];
  double metros = 0;
  bool _mostrarTodos = false;

  // GPS
  LatLng? _miPos;
  double _precision = 0; // metros de error del GPS
  StreamSubscription<Position>? _gps;
  bool _seguir = false; // el mapa sigue tu posición

  final _mapa = MapController();
  final _ctrlOrigen = TextEditingController();
  final _ctrlDestino = TextEditingController();
  final _focoOrigen = FocusNode();
  final _focoDestino = FocusNode();

  @override
  void initState() {
    super.initState();
    cargarGrafo().then((g) => setState(() => grafo = g));
  }

  @override
  void dispose() {
    _gps?.cancel();
    _ctrlOrigen.dispose();
    _ctrlDestino.dispose();
    _focoOrigen.dispose();
    _focoDestino.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------
  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // Coordenada de un lugar, o tu posición si es "Mi ubicación"
  LatLng? _punto(String? nombre) {
    if (nombre == null) return null;
    if (nombre == miUbicacion) return _miPos;
    return lugares[nombre];
  }

  // ---------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------
  Future<bool> _permisoGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _aviso('Activa la ubicación de tu dispositivo');
      return false;
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _aviso('Necesito el permiso de ubicación para guiarte');
      return false;
    }
    return true;
  }

  void _alCambiarPosicion(LatLng pos, double precision) {
    setState(() {
      _miPos = pos;
      _precision = precision;
    });
    // si tu origen (o destino) es "Mi ubicación", la ruta se recalcula
    if (origen == miUbicacion || destino == miUbicacion) {
      _calcularRuta(mover: false);
    }
    if (_seguir) _mapa.move(pos, _mapa.camera.zoom);
  }

  void _iniciarGps() {
    if (_gps != null || modoPrueba) return;
    _gps = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // actualiza cada 3 metros
      ),
    ).listen(
      (p) => _alCambiarPosicion(LatLng(p.latitude, p.longitude), p.accuracy),
      onError: (_) => _aviso('No pude leer tu ubicación'),
    );
  }

  Future<void> _estoyAqui() async {
    if (grafo == null) return;
    LatLng aqui;

    if (modoPrueba && _miPos != null) {
      // posición simulada con clic sostenido
      aqui = _miPos!;
    } else {
      if (!await _permisoGps()) return;
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        aqui = LatLng(p.latitude, p.longitude);
        _precision = p.accuracy;
      } catch (_) {
        _aviso('No pude obtener tu ubicación. Intenta de nuevo.');
        return;
      }
      if (!mounted) return;
    }

    setState(() => _miPos = aqui);
    _iniciarGps();

    // ¿estás dentro del campus?
    final nodo = grafo!.nodoMasCercano(aqui);
    final lejos =
        const Distance().as(LengthUnit.Meter, aqui, grafo!.nodos[nodo]!);
    if (lejos > 300) {
      _aviso('Parece que no estás en el campus (a ${lejos.toStringAsFixed(0)} m)');
      return;
    }

    _mapa.move(aqui, 18);
    _elegirOrigen(miUbicacion);
  }

  void _alternarSeguir() {
    if (_miPos == null) {
      _aviso('Toca "Estoy aquí" primero');
      return;
    }
    setState(() => _seguir = !_seguir);
    if (_seguir) _mapa.move(_miPos!, 18);
  }

  // ---------------------------------------------------------------
  // Origen, destino y ruta
  // ---------------------------------------------------------------
  void _elegirOrigen(String nombre) {
    FocusScope.of(context).unfocus();
    setState(() => origen = nombre);
    _ctrlOrigen.text = nombre;
    if (nombre == miUbicacion && _miPos == null) {
      _estoyAqui();
      return;
    }
    _calcularRuta();
  }

  void _elegirDestino(String nombre) {
    FocusScope.of(context).unfocus();
    setState(() => destino = nombre);
    _ctrlDestino.text = nombre;
    _calcularRuta();
  }

  void _intercambiar() {
    final o = origen, d = destino;
    final to = _ctrlOrigen.text, td = _ctrlDestino.text;
    setState(() {
      origen = d;
      destino = o;
    });
    _ctrlOrigen.text = td;
    _ctrlDestino.text = to;
    _calcularRuta();
  }

  void _calcularRuta({bool mover = true}) {
    final a = _punto(origen);
    final b = _punto(destino);
    if (grafo == null || a == null || b == null) return;

    final nodoA = grafo!.nodoMasCercano(a);
    final nodoB = grafo!.nodoMasCercano(b);
    final camino = DijkstraBasico().calcular(grafo!, nodoA, nodoB).camino;

    if (camino.isEmpty) {
      _aviso('No se encontró una ruta entre esos lugares');
      return;
    }

    final puntos = [a, ...grafo!.puntosRuta(camino), b];
    final m = grafo!.longitudRuta(camino);
    setState(() {
      ruta = puntos;
      metros = m;
    });

    // Zoom fijo, solo cuando eliges la ruta 
    if (mover) {
      final mitad = puntos[puntos.length ~/ 2];
      _mapa.move(m < 400 ? mitad : puntos.first, 18);
    }
  }

  void _limpiar() {
    _ctrlOrigen.clear();
    _ctrlDestino.clear();
    setState(() {
      origen = null;
      destino = null;
      ruta = [];
      metros = 0;
    });
  }

  void _mostrarLugar(String nombre) {
    mostrarFicha(
      context,
      nombre,
      alEstoyAqui: () => _elegirOrigen(nombre),
      alIrAqui: () => _elegirDestino(nombre),
    );
  }

  // ---------------------------------------------------------------
  // Pantalla
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (grafo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final marcadores = lugares.entries
        .where((e) =>
            e.key == origen ||
            e.key == destino ||
            (_mostrarTodos && ruta.isEmpty))
        .map((e) {
      Color color = Colors.red;
      if (e.key == origen) color = Colors.green;
      if (e.key == destino) color = Colors.orange;
      return Marker(
        point: e.value,
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _mostrarLugar(e.key),
          child: Icon(
            Icons.location_on,
            color: color,
            size: 40,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
          ),
        ),
      );
    }).toList();

    final minutos = metros / 80;
    const azul = Color(0xFF1E88E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubícate Unicor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Lugares y horarios',
            onPressed: () => mostrarListaLugares(context, _mostrarLugar),
          ),
          IconButton(
            icon: Icon(_mostrarTodos ? Icons.location_off : Icons.location_on),
            tooltip: _mostrarTodos ? 'Ocultar lugares' : 'Mostrar lugares',
            onPressed: () => setState(() => _mostrarTodos = !_mostrarTodos),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Limpiar',
            onPressed: _limpiar,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: const LatLng(8.7910, -75.8610),
              initialZoom: 17,
              // Solo pruebas: clic sostenido = "estoy aquí"
              onLongPress: modoPrueba
                  ? (tap, punto) => _alCambiarPosicion(punto, 8)
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ejemplo.campus_app',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
              if (ruta.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ruta,
                      color: azul,
                      strokeWidth: 6,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              MarkerLayer(markers: marcadores),

              // Círculo de precisión del GPS
              if (_miPos != null && _precision > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _miPos!,
                      radius: _precision.clamp(5, 120).toDouble(),
                      useRadiusInMeter: true,
                      color: azul.withValues(alpha: 0.15),
                      borderColor: azul.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),

              // Punto azul: tu posición
              if (_miPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _miPos!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: azul,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Buscador arriba
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(12),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CampoLugar(
                            controller: _ctrlOrigen,
                            focusNode: _focoOrigen,
                            etiqueta: '¿Dónde estás?',
                            icono: Icons.my_location,
                            color: Colors.green,
                            extras: const [miUbicacion],
                            alElegir: _elegirOrigen,
                          ),
                          const SizedBox(height: 10),
                          CampoLugar(
                            controller: _ctrlDestino,
                            focusNode: _focoDestino,
                            etiqueta: '¿A dónde quieres ir?',
                            icono: Icons.flag,
                            color: Colors.orange,
                            alElegir: _elegirDestino,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_vert),
                      tooltip: 'Intercambiar',
                      onPressed: _intercambiar,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botones de GPS y navegación (abajo a la derecha)
          Positioned(
            right: 12,
            bottom: ruta.isNotEmpty ? 100 : 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ruta.isNotEmpty) ...[
                  FloatingActionButton.small(
                    heroTag: 'verDestino',
                    tooltip: 'Ir al destino',
                    onPressed: () => _mapa.move(ruta.last, 18),
                    child: const Icon(Icons.flag),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.small(
                  heroTag: 'seguir',
                  tooltip: _seguir ? 'Dejar de seguirme' : 'Seguir mi posición',
                  backgroundColor: _seguir ? azul : null,
                  foregroundColor: _seguir ? Colors.white : null,
                  onPressed: _alternarSeguir,
                  child: Icon(_seguir ? Icons.navigation : Icons.near_me),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'estoyAqui',
                  onPressed: _estoyAqui,
                  backgroundColor: azul,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Estoy aquí'),
                ),
              ],
            ),
          ),

          // Resultado abajo
          if (ruta.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${metros.toStringAsFixed(0)} m · '
                          'unos ${minutos.toStringAsFixed(0)} min caminando',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (destino != null && destino != miUbicacion)
                        TextButton.icon(
                          icon: const Icon(Icons.schedule),
                          label: const Text('Horario'),
                          onPressed: () => mostrarFicha(context, destino!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}