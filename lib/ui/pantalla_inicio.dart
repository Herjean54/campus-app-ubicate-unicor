import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pantalla_mapa.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio>
    with TickerProviderStateMixin {
  // Movimiento del loro (mirar a los lados)
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  // Íconos que flotan en el fondo
  late final AnimationController _fondo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  // Ondas tipo "radar de ubicación"
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // Latido del botón
  late final AnimationController _boton = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  // Frases que "piensa" el loro
  static const _frases = [
    '¿Dónde queda el bloque 21?',
    '¿Cómo llego a la biblioteca?',
    '¿Por dónde está la cafetería?',
    '¡Estoy perdido!',
    '¿Y mi salón?',
  ];
  int _frase = 0;
  Timer? _timer;

  // Íconos decorativos: (icono, posición x, desfase, tamaño)
  static const _deco = [
    (Icons.location_on, 0.10, 0.00, 34.0),
    (Icons.explore, 0.85, 0.20, 40.0),
    (Icons.school, 0.25, 0.45, 36.0),
    (Icons.directions_walk, 0.70, 0.60, 32.0),
    (Icons.map, 0.50, 0.80, 38.0),
    (Icons.flag, 0.92, 0.90, 30.0),
    (Icons.place, 0.05, 0.70, 30.0),
    (Icons.local_library, 0.38, 0.12, 30.0),
  ];

  // -1 = mira a la izquierda, 1 = mira a la derecha, con pausas
  final Animatable<double> _mirada = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(-1.0), weight: 1.4),
    TweenSequenceItem(
      tween: Tween<double>(begin: -1.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1.0,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 1.4),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: -1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1.0,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted) setState(() => _frase = (_frase + 1) % _frases.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    _fondo.dispose();
    _ping.dispose();
    _boton.dispose();
    super.dispose();
  }

  void _comenzar() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const PantallaMapa(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ---------- Fondo con íconos flotando ----------
  Widget _fondoAnimado() {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          return AnimatedBuilder(
            animation: _fondo,
            builder: (_, __) {
              return Stack(
                children: [
                  for (final d in _deco)
                    Builder(builder: (_) {
                      final t = (_fondo.value + d.$3) % 1;
                      final y = c.maxHeight * (1.1 - 1.2 * t);
                      final x = c.maxWidth * d.$2 +
                          math.sin((t + d.$3) * 2 * math.pi * 2) * 18;
                      final op = math.sin(t * math.pi) * 0.30;
                      return Positioned(
                        left: x,
                        top: y,
                        child: Opacity(
                          opacity: op.clamp(0.0, 1.0),
                          child: Icon(d.$1, size: d.$4, color: Colors.white),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------- Mascota ----------
  Widget _mascota() {
    return AnimatedBuilder(
      animation: Listenable.merge([_anim, _ping]),
      builder: (_, __) {
        final p = _anim.value;
        final mira = _mirada.transform(p);
        final giro = (-mira * 3).clamp(-1.0, 1.0);
        final saltito = -6 * math.sin(p * 2 * math.pi * 4).abs();
        final ladeo = mira * 0.12 + math.sin(p * 2 * math.pi * 8) * 0.05;
        final pulso = 0.5 + 0.5 * math.sin(p * 2 * math.pi * 2);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Globo de pensamiento
            Transform.translate(
              offset: Offset(mira * 24, 0),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: Text(
                        _frases[_frase],
                        key: ValueKey(_frase),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: const Icon(Icons.arrow_drop_down,
                        color: Colors.white, size: 38),
                  ),
                ],
              ),
            ),

            // Ondas + círculo + loro
            SizedBox(
              width: 270,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 3; i++)
                    Builder(builder: (_) {
                      final t = (_ping.value + i / 3) % 1;
                      return Container(
                        width: 190 + 80 * t,
                        height: 190 + 80 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: (1 - t) * 0.45),
                            width: 3,
                          ),
                        ),
                      );
                    }),
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0.12),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F)
                              .withValues(alpha: 0.25 + 0.25 * pulso),
                          blurRadius: 30 + 20 * pulso,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(mira * 24, saltito),
                    child: Transform.rotate(
                      angle: ladeo,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(giro, 1, 1),
                        child: const Text('🦜',
                            style: TextStyle(fontSize: 110)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sombra que sigue al loro
            Transform.translate(
              offset: Offset(mira * 24, 0),
              child: Container(
                width: 100 + saltito * 2,
                height: 11 + saltito * 0.3,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Etiquetas de funciones ----------
  Widget _chip(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(texto,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------- Botón que late ----------
  Widget _botonComenzar() {
    return AnimatedBuilder(
      animation: _boton,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_boton.value);
        return Transform.scale(
          scale: 1 + 0.06 * t,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F)
                      .withValues(alpha: 0.35 + 0.3 * t),
                  blurRadius: 14 + 14 * t,
                  spreadRadius: 1 + 3 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FilledButton.icon(
        onPressed: _comenzar,
        icon: const Icon(Icons.explore, size: 26),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Text(
            '¡Comenzar!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: const Color(0xFF1B5E20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF43A047), Color(0xFF9CCC65)],
          ),
        ),
        child: Stack(
          children: [
            _fondoAnimado(),
            SafeArea(
              child: Center(
                // FittedBox: si el contenido no cabe, se reduce hasta caber
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1000),
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _mascota(),
                          const SizedBox(height: 12),
                          const Text(
                            'Ubícate',
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [Color(0xFFFFF176), Color(0xFFFFA000)],
                            ).createShader(rect),
                            child: const Text(
                              'UNICOR',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Encuentra tu camino por el campus\nde la Universidad de Córdoba',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(Icons.search, 'Busca lugares'),
                              _chip(Icons.alt_route, 'Rutas a pie'),
                              _chip(Icons.timer_outlined, 'Tiempo estimado'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _botonComenzar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}