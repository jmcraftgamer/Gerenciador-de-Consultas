import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Keys
  static const _kNome = 'settings_nome';
  static const _kEmail = 'settings_email';
  static const _kNotificacoes = 'settings_notificacoes';
  static const _kSons = 'settings_sons';
  static const _kVibracao = 'settings_vibracao';
  static const _kAnimacoes = 'settings_animacoes';
  static const _kTamanhoFonte = 'settings_tamanho_fonte';
  static const _kLembreteMinutos = 'settings_lembrete_minutos';
  static const _kIdioma = 'settings_idioma';
  static const _kNumeroPsicologa = 'settings_numero_psicologa';
  static const _kMensagemFormulario = 'settings_mensagem_formulario';
  static const _kLinkFormulario = 'settings_link_formulario';

  // Defaults
  String _nome = 'Dra. Psicanalista';
  String _email = 'psicanalista@email.com';
  bool _notificacoes = true;
  bool _sons = true;
  bool _vibracao = true;
  bool _animacoes = true;
  double _tamanhoFonte = 1.0;
  int _lembreteMinutos = 30;
  String _idioma = 'pt_BR';
  String _numeroPsicologa = '';
  String _mensagemFormulario = 'Olá {nome}! Por favor, preencha o formulário de avaliação antes da nossa consulta:\n\n{link}\n\nAguardo seu retorno!';
  String _linkFormulario = '';

  bool _carregado = false;

  // Getters
  String get nome => _nome;
  String get email => _email;
  bool get notificacoes => _notificacoes;
  bool get sons => _sons;
  bool get vibracao => _vibracao;
  bool get animacoes => _animacoes;
  double get tamanhoFonte => _tamanhoFonte;
  int get lembreteMinutos => _lembreteMinutos;
  String get idioma => _idioma;
  String get numeroPsicologa => _numeroPsicologa;
  String get mensagemFormulario => _mensagemFormulario;
  String get linkFormulario => _linkFormulario;

  String get tamanhoFonteLabel {
    if (_tamanhoFonte <= 0.85) return 'Pequeno';
    if (_tamanhoFonte >= 1.15) return 'Grande';
    return 'Médio';
  }

  String get lembreteLabel {
    if (_lembreteMinutos == 0) return 'Desativado';
    if (_lembreteMinutos < 60) return '${_lembreteMinutos} minutos antes';
    return '1 hora antes';
  }

  Future<void> carregar() async {
    if (_carregado) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _nome = prefs.getString(_kNome) ?? _nome;
      _email = prefs.getString(_kEmail) ?? _email;
      _notificacoes = prefs.getBool(_kNotificacoes) ?? _notificacoes;
      _sons = prefs.getBool(_kSons) ?? _sons;
      _vibracao = prefs.getBool(_kVibracao) ?? _vibracao;
      _animacoes = prefs.getBool(_kAnimacoes) ?? _animacoes;
      _tamanhoFonte = prefs.getDouble(_kTamanhoFonte) ?? _tamanhoFonte;
      _lembreteMinutos = prefs.getInt(_kLembreteMinutos) ?? _lembreteMinutos;
      _idioma = prefs.getString(_kIdioma) ?? _idioma;
      _numeroPsicologa = prefs.getString(_kNumeroPsicologa) ?? _numeroPsicologa;
      _mensagemFormulario = prefs.getString(_kMensagemFormulario) ?? _mensagemFormulario;
      _linkFormulario = prefs.getString(_kLinkFormulario) ?? _linkFormulario;
    } catch (_) {}
    _carregado = true;
    notifyListeners();
  }

  Future<void> _salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNome, _nome);
      await prefs.setString(_kEmail, _email);
      await prefs.setBool(_kNotificacoes, _notificacoes);
      await prefs.setBool(_kSons, _sons);
      await prefs.setBool(_kVibracao, _vibracao);
      await prefs.setBool(_kAnimacoes, _animacoes);
      await prefs.setDouble(_kTamanhoFonte, _tamanhoFonte);
      await prefs.setInt(_kLembreteMinutos, _lembreteMinutos);
      await prefs.setString(_kIdioma, _idioma);
      await prefs.setString(_kNumeroPsicologa, _numeroPsicologa);
      await prefs.setString(_kMensagemFormulario, _mensagemFormulario);
      await prefs.setString(_kLinkFormulario, _linkFormulario);
    } catch (_) {}
  }

  Future<void> atualizarPerfil({required String nome, required String email}) async {
    _nome = nome;
    _email = email;
    await _salvar();
    notifyListeners();
  }

  Future<void> toggleNotificacoes() async {
    _notificacoes = !_notificacoes;
    await _salvar();
    notifyListeners();
  }

  Future<void> toggleSons() async {
    _sons = !_sons;
    await _salvar();
    notifyListeners();
  }

  Future<void> toggleVibracao() async {
    _vibracao = !_vibracao;
    await _salvar();
    notifyListeners();
  }

  Future<void> toggleAnimacoes() async {
    _animacoes = !_animacoes;
    await _salvar();
    notifyListeners();
  }

  Future<void> setTamanhoFonte(double valor) async {
    _tamanhoFonte = valor;
    await _salvar();
    notifyListeners();
  }

  Future<void> setLembreteMinutos(int minutos) async {
    _lembreteMinutos = minutos;
    await _salvar();
    notifyListeners();
  }

  Future<void> setNumeroPsicologa(String valor) async {
    _numeroPsicologa = valor;
    await _salvar();
    notifyListeners();
  }

  Future<void> setMensagemFormulario(String valor) async {
    _mensagemFormulario = valor;
    await _salvar();
    notifyListeners();
  }

  Future<void> setLinkFormulario(String valor) async {
    _linkFormulario = valor;
    await _salvar();
    notifyListeners();
  }
}
