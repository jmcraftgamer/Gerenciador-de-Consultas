import 'package:flutter/material.dart';

class Consulta {
  final String id;
  final String paciente;
  final DateTime data;
  final TimeOfDay horarioInicio;
  final TimeOfDay horarioFim;
  final String modalidade;
  final String telefone;
  final List<String> queixas;
  bool confirmada;

  Consulta({
    required this.id,
    required this.paciente,
    required this.data,
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    this.telefone = '',
    this.queixas = const [],
    this.confirmada = false,
  });

  String get horarioFormatado {
    final h1 = horarioInicio.hour.toString().padLeft(2, '0');
    final m1 = horarioInicio.minute.toString().padLeft(2, '0');
    final h2 = horarioFim.hour.toString().padLeft(2, '0');
    final m2 = horarioFim.minute.toString().padLeft(2, '0');
    return '$h1:$m1 – $h2:$m2';
  }

  String get dataFormatada {
    final d = data.day.toString().padLeft(2, '0');
    final m = data.month.toString().padLeft(2, '0');
    return '$d/$m/${data.year}';
  }

  String get dateKey {
    return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente': paciente,
      'data': '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
      'horarioInicioHour': horarioInicio.hour,
      'horarioInicioMinute': horarioInicio.minute,
      'horarioFimHour': horarioFim.hour,
      'horarioFimMinute': horarioFim.minute,
      'modalidade': modalidade,
      'telefone': telefone,
      'queixas': queixas,
      'confirmada': confirmada,
    };
  }

  factory Consulta.fromJson(Map<String, dynamic> json) {
    try {
      final dataParts = (json['data'] as String).split('-');
      return Consulta(
        id: json['id'] as String,
        paciente: json['paciente'] as String,
        data: DateTime(
          int.parse(dataParts[0]),
          int.parse(dataParts[1]),
          int.parse(dataParts[2]),
        ),
        horarioInicio: TimeOfDay(
          hour: json['horarioInicioHour'] as int,
          minute: json['horarioInicioMinute'] as int,
        ),
        horarioFim: TimeOfDay(
          hour: json['horarioFimHour'] as int,
          minute: json['horarioFimMinute'] as int,
        ),
        modalidade: json['modalidade'] as String,
        telefone: (json['telefone'] as String?) ?? '',
        queixas: (json['queixas'] as List<dynamic>?)?.cast<String>() ?? [],
        confirmada: (json['confirmada'] as bool?) ?? false,
      );
    } catch (_) {
      return Consulta(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        paciente: json['paciente']?.toString() ?? 'Desconhecido',
        data: DateTime.now(),
        horarioInicio: const TimeOfDay(hour: 9, minute: 0),
        horarioFim: const TimeOfDay(hour: 10, minute: 0),
        modalidade: 'Presencial',
      );
    }
  }
}
