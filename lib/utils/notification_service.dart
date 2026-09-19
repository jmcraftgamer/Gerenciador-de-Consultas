import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/consulta.dart';
import '../models/consulta_service.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _kUltimaConsultaKey = 'ultima_data_consulta';
  static const String _kDiaLivreMostradoKey = 'dia_livre_mostrado_data';
  static const String _kInatividadeMostradaKey = 'inatividade_mostrada_data';

  static const _androidDetails = AndroidNotificationDetails(
    'consultas_bemestar',
    'Lembretes de Consulta',
    channelDescription: 'Notificações de lembrete antes das consultas',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFB8A88A),
    playSound: true,
    enableVibration: true,
  );

  static const _darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
  );

  static const _inatividadeAndroidDetails = AndroidNotificationDetails(
    'inatividade_bemestar',
    'Lembrete de Inatividade',
    channelDescription: 'Notificações quando não há consultas há muito tempo',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFB8A88A),
  );

  static const _inatividadeDetails = NotificationDetails(
    android: _inatividadeAndroidDetails,
    iOS: _darwinDetails,
  );

  static const _diaLivreAndroidDetails = AndroidNotificationDetails(
    'dia_livre_bemestar',
    'Mensagem do Dia',
    channelDescription: 'Mensagem de bom dia quando não há consultas',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFB8A88A),
  );

  static const _diaLivreDetails = NotificationDetails(
    android: _diaLivreAndroidDetails,
    iOS: _darwinDetails,
  );

  Future<void> inicializar() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    ConsultaService().addListener(_onConsultasChanged);
    _onConsultasChanged();
  }

  void _onConsultasChanged() {
    agendarTodasNotificacoes();
    _verificarInatividade();
    _verificarDiaLivre();
  }

  Future<void> agendarTodasNotificacoes() async {
    final settings = SettingsService();
    if (!settings.notificacoes) return;

    final lembreteMinutos = settings.lembreteMinutos;
    if (lembreteMinutos <= 0) return;

    final service = ConsultaService();
    final consultas = service.consultasOrdenadas();
    final now = DateTime.now();

    await _plugin.cancelAll();

    for (final c in consultas) {
      final consultaDateTime = DateTime(
        c.data.year,
        c.data.month,
        c.data.day,
        c.horarioInicio.hour,
        c.horarioInicio.minute,
      );

      final notifTime = consultaDateTime.subtract(Duration(minutes: lembreteMinutos));

      if (notifTime.isAfter(now)) {
        final id = c.id.hashCode & 0x7FFFFFFF;
        await _agendarNotificacaoConsulta(
          id: id,
          title: 'Faltam $lembreteMinutos minutos!',
          body: 'Consulta com ${c.paciente} às ${c.horarioInicio.hour.toString().padLeft(2, '0')}:${c.horarioInicio.minute.toString().padLeft(2, '0')}',
          scheduledTime: notifTime,
        );
      }
    }
  }

  Future<void> _agendarNotificacaoConsulta({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _verificarInatividade() async {
    final service = ConsultaService();
    final consultas = service.consultasOrdenadas();
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateTime.now();
    final hojeKey = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final ultimaMostrada = prefs.getString(_kInatividadeMostradaKey);
    if (ultimaMostrada == hojeKey) return;

    DateTime? dataUltimaPassada;
    for (final c in consultas) {
      final fim = DateTime(c.data.year, c.data.month, c.data.day, c.horarioFim.hour, c.horarioFim.minute);
      if (fim.isBefore(hoje)) {
        dataUltimaPassada = c.data;
      }
    }

    if (dataUltimaPassada == null) {
      final ultimaConsulta = prefs.getString(_kUltimaConsultaKey);
      if (ultimaConsulta != null) {
        final data = DateTime.parse(ultimaConsulta);
        final diasSemConsulta = hoje.difference(data).inDays;
        if (diasSemConsulta >= 7) {
          await _mostrarNotificacaoInatividade(diasSemConsulta);
          await prefs.setString(_kInatividadeMostradaKey, hojeKey);
        }
      }
      return;
    }

    final dataUltima = '${dataUltimaPassada.year}-${dataUltimaPassada.month.toString().padLeft(2, '0')}-${dataUltimaPassada.day.toString().padLeft(2, '0')}';
    await prefs.setString(_kUltimaConsultaKey, dataUltima);

    final diasSemConsulta = hoje.difference(dataUltimaPassada).inDays;
    if (diasSemConsulta >= 7) {
      await _mostrarNotificacaoInatividade(diasSemConsulta);
      await prefs.setString(_kInatividadeMostradaKey, hojeKey);
    }
  }

  Future<void> _mostrarNotificacaoInatividade(int dias) async {
    await _plugin.show(
      9999,
      'Sentimos sua falta!',
      'Faz $dias dias sem consultas agendadas. Que tal agendar uma nova consulta?',
      _inatividadeDetails,
    );
  }

  Future<void> _verificarDiaLivre() async {
    final service = ConsultaService();
    final consultasHoje = service.consultasPorData(DateTime.now());

    if (consultasHoje.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final hoje = DateTime.now();
    final hojeKey = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final ultimaMostrada = prefs.getString(_kDiaLivreMostradoKey);
    if (ultimaMostrada == hojeKey) return;

    await _plugin.show(
      8888,
      'Dia tranquilo!',
      'Hoje não há consultas marcadas. Aproveite seu dia de descanso!',
      _diaLivreDetails,
    );
    await prefs.setString(_kDiaLivreMostradoKey, hojeKey);
  }

  Future<void> notificarConsultaCriada(Consulta c) async {
    final id = (c.id.hashCode & 0x7FFFFFFF) + 1;
    await _plugin.show(
      id,
      'Consulta agendada!',
      '${c.paciente} - ${c.dataFormatada} às ${c.horarioInicio.hour.toString().padLeft(2, '0')}:${c.horarioInicio.minute.toString().padLeft(2, '0')}',
      _notificationDetails,
    );
  }

  Future<void> cancelarNotificacoesConsultas() async {
    await _plugin.cancelAll();
  }
}
