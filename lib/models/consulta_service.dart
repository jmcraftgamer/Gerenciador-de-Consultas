import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/consulta.dart';

class ConsultaService extends ChangeNotifier {
  static final ConsultaService _instance = ConsultaService._internal();
  factory ConsultaService() => _instance;
  ConsultaService._internal();

  static const String _storageKey = 'consultas';
  final List<Consulta> _consultas = [];
  bool _carregado = false;
  bool _useSupabase = false;
  SupabaseClient? _client;

  List<Consulta> get consultas => List.unmodifiable(_consultas);

  bool get isOnline => _useSupabase;

  Future<void> carregar() async {
    if (_carregado) return;

    try {
      _client = Supabase.instance.client;
      await _client!.from('consultas').select('id').limit(1);
      _useSupabase = true;
    } catch (_) {
      _useSupabase = false;
    }

    if (_useSupabase) {
      await _carregarDoSupabase();
    } else {
      await _carregarLocal();
    }

    _carregado = true;
  }

  Future<void> _carregarDoSupabase() async {
    try {
      final data = await _client!.from('consultas').select().order('data').order('horario_inicio_hour');
      _consultas.clear();
      for (final row in data) {
        _consultas.add(Consulta(
          id: row['id'],
          paciente: row['paciente'],
          data: DateTime.parse(row['data']),
          horarioInicio: TimeOfDay(hour: row['horario_inicio_hour'], minute: row['horario_inicio_minute']),
          horarioFim: TimeOfDay(hour: row['horario_fim_hour'], minute: row['horario_fim_minute']),
          modalidade: row['modalidade'],
          telefone: row['telefone'] ?? '',
          queixas: (row['queixas'] as List<dynamic>?)?.cast<String>() ?? [],
          confirmada: row['confirmada'] ?? false,
        ));
      }
      notifyListeners();
    } catch (_) {
      await _carregarLocal();
    }
  }

  Future<void> _carregarLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _consultas.clear();
        _consultas.addAll(jsonList.map((j) => Consulta.fromJson(j)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _salvar() async {
    await _salvarLocal();
    if (_useSupabase) {
      await _sincronizarSupabase();
    }
  }

  Future<void> _sincronizarSupabase() async {
    try {
      await _client!.from('consultas').delete().neq('id', '__none__');
      if (_consultas.isNotEmpty) {
        final rows = _consultas.map((c) => {
          'id': c.id,
          'paciente': c.paciente,
          'data': '${c.data.year}-${c.data.month.toString().padLeft(2, '0')}-${c.data.day.toString().padLeft(2, '0')}',
          'horario_inicio_hour': c.horarioInicio.hour,
          'horario_inicio_minute': c.horarioInicio.minute,
          'horario_fim_hour': c.horarioFim.hour,
          'horario_fim_minute': c.horarioFim.minute,
          'modalidade': c.modalidade,
          'telefone': c.telefone,
          'queixas': c.queixas,
          'confirmada': c.confirmada,
        }).toList();
        await _client!.from('consultas').insert(rows);
      }
    } catch (_) {}
  }

  Future<void> _salvarLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _consultas.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  void adicionar(Consulta consulta) {
    _consultas.add(consulta);
    _salvar();
    notifyListeners();
  }

  void remover(String id) {
    _consultas.removeWhere((c) => c.id == id);
    _salvar();
    notifyListeners();
  }

  void limparTodas() {
    _consultas.clear();
    _salvar();
    notifyListeners();
  }

  void atualizar(String id, Consulta atualizada) {
    final index = _consultas.indexWhere((c) => c.id == id);
    if (index != -1) {
      _consultas[index] = atualizada;
      _salvar();
      notifyListeners();
    }
  }

  void toggleConfirmada(String id) {
    final index = _consultas.indexWhere((c) => c.id == id);
    if (index != -1) {
      _consultas[index].confirmada = !_consultas[index].confirmada;
      _salvar();
      notifyListeners();
    }
  }

  List<Consulta> consultasPorData(DateTime data) {
    return _consultas.where((c) {
      return c.data.year == data.year &&
          c.data.month == data.month &&
          c.data.day == data.day;
    }).toList()
      ..sort((a, b) {
        final cmp = a.horarioInicio.hour.compareTo(b.horarioInicio.hour);
        if (cmp != 0) return cmp;
        return a.horarioInicio.minute.compareTo(b.horarioInicio.minute);
      });
  }

  List<Consulta> consultasOrdenadas() {
    return List.of(_consultas)..sort((a, b) {
      final cmp = a.data.compareTo(b.data);
      if (cmp != 0) return cmp;
      final cmpH = a.horarioInicio.hour.compareTo(b.horarioInicio.hour);
      if (cmpH != 0) return cmpH;
      return a.horarioInicio.minute.compareTo(b.horarioInicio.minute);
    });
  }

  int countPorData(DateTime data) {
    return _consultas.where((c) {
      return c.data.year == data.year &&
          c.data.month == data.month &&
          c.data.day == data.day;
    }).length;
  }

  Set<int> horariosOcupados(DateTime data) {
    final hours = <int>{};
    for (final c in _consultas.where((c) =>
        c.data.year == data.year &&
        c.data.month == data.month &&
        c.data.day == data.day)) {
      for (var h = c.horarioInicio.hour; h < c.horarioFim.hour; h++) {
        hours.add(h);
      }
      hours.add(c.horarioInicio.hour);
    }
    return hours;
  }
}
