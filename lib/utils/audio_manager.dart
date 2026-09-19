import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();

  bool get enabled => SettingsService().sons;

  Future<void> _playSound(String asset) async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  void _haptic(LightImpactType type) {
    if (!SettingsService().vibracao) return;
    switch (type) {
      case LightImpactType.light:
        HapticFeedback.lightImpact();
        break;
      case LightImpactType.medium:
        HapticFeedback.mediumImpact();
        break;
      case LightImpactType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case LightImpactType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  Future<void> playTap() async {
    _haptic(LightImpactType.light);
    await _playSound('sounds/tap.mp3');
  }

  Future<void> playNavigate() async {
    _haptic(LightImpactType.medium);
    await _playSound('sounds/navigate.mp3');
  }

  Future<void> playSuccess() async {
    _haptic(LightImpactType.heavy);
    await _playSound('sounds/success.mp3');
  }

  Future<void> playSelect() async {
    _haptic(LightImpactType.selection);
    await _playSound('sounds/select.mp3');
  }

  Future<void> playBack() async {
    _haptic(LightImpactType.light);
    await _playSound('sounds/back.mp3');
  }

  Future<void> playDelete() async {
    _haptic(LightImpactType.medium);
    await _playSound('sounds/delete.mp3');
  }

  void dispose() {
    _player.dispose();
  }
}

enum LightImpactType { light, medium, heavy, selection }
