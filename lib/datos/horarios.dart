class Franja {
  final List<int> dias; // 1 = lunes ... 7 = domingo
  final String desde; // 'HH:MM'
  final String hasta;
  const Franja(this.dias, this.desde, this.hasta);

  int get desdeMin => _minutos(desde);
  int get hastaMin => _minutos(hasta);
}

int _minutos(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

class InfoLugar {
  final String descripcion;
  final List<Franja> horarios; // vacío = sin horario registrado
  const InfoLugar(this.descripcion, [this.horarios = const []]);
}

const _sinInfo = InfoLugar('Aún no hay información registrada de este lugar.');

InfoLugar infoDe(String nombre) => infoLugares[nombre] ?? _sinInfo;

// ---------------------------------------------------------------
// EDITA AQUÍ con los datos reales (los de abajo son de ejemplo)
// ---------------------------------------------------------------
const lunVie = [1, 2, 3, 4, 5];

const Map<String, InfoLugar> infoLugares = {
  'Biblioteca': InfoLugar(
    'Préstamo de libros, salas de estudio y computadores.',
    [
      Franja(lunVie, '07:00', '20:00'),
      Franja([6], '08:00', '12:00'),
    ],
  ),
  'Cafetería Central': InfoLugar(
    'Desayunos, almuerzos y snacks.',
    [
      Franja(lunVie, '06:30', '18:00'),
      Franja([6], '07:00', '13:00'),
    ],
  ),
  'Edificio administrativo': InfoLugar(
    'Matrículas, certificados y trámites académicos.',
    [Franja(lunVie, '08:00', '12:00'), Franja(lunVie, '14:00', '17:00')],
  ),
  'Auditorio cultural': InfoLugar(
    'Eventos, conferencias y actividades culturales.',
    [Franja(lunVie, '08:00', '21:00')],
  ),
  'Bloque 21 (Laboratorio de ciencias básicas)': InfoLugar(
    'Laboratorios de física, química y biología.',
    [Franja(lunVie, '07:00', '18:00')],
  ),
  'Edificio de informática': InfoLugar(
    'Salas de cómputo y aulas de sistemas.',
    [Franja(lunVie, '07:00', '21:00'), Franja([6], '08:00', '13:00')],
  ),
  'Entrada norte (Calle 85)': InfoLugar(
    'Acceso peatonal por la Calle 85.',
    [Franja([1, 2, 3, 4, 5, 6, 7], '05:30', '21:00')],
  ),
};

// ---------------------------------------------------------------
// Estado: ¿abierto ahora?
// ---------------------------------------------------------------
const _nombreDia = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
];
const _abrevDia = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class Estado {
  final bool? abierto; // null = sin información
  final String texto;
  const Estado(this.abierto, this.texto);
}

Estado estadoAhora(InfoLugar info, DateTime ahora) {
  if (info.horarios.isEmpty) return const Estado(null, 'Sin horario registrado');

  final min = ahora.hour * 60 + ahora.minute;

  for (final f in info.horarios) {
    if (f.dias.contains(ahora.weekday) && min >= f.desdeMin && min < f.hastaMin) {
      return Estado(true, 'Cierra a las ${f.hasta}');
    }
  }

  // buscar la próxima apertura (hoy o en los próximos 7 días)
  for (var salto = 0; salto <= 7; salto++) {
    final dia = ((ahora.weekday - 1 + salto) % 7) + 1;
    final aperturas = info.horarios
        .where((f) => f.dias.contains(dia) && (salto > 0 || f.desdeMin > min))
        .map((f) => f.desde)
        .toList()
      ..sort();
    if (aperturas.isNotEmpty) {
      final cuando = salto == 0
          ? 'hoy'
          : salto == 1
              ? 'mañana'
              : 'el ${_nombreDia[dia - 1]}';
      return Estado(false, 'Abre $cuando a las ${aperturas.first}');
    }
  }
  return const Estado(false, 'Cerrado');
}

// "Lun–Vie", "Sáb", "Lun, Mié"
String diasTexto(List<int> dias) {
  final d = [...dias]..sort();
  if (d.length == 1) return _abrevDia[d.first - 1];
  var seguidos = true;
  for (var i = 1; i < d.length; i++) {
    if (d[i] != d[i - 1] + 1) seguidos = false;
  }
  if (seguidos) return '${_abrevDia[d.first - 1]}–${_abrevDia[d.last - 1]}';
  return d.map((x) => _abrevDia[x - 1]).join(', ');
}