import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Controlador centralizado para la gestión de sonidos del temporizador.
/// Reproduce las voces y la alarma final.
class SoundController {
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  /// Inicializa cargando las preferencias de sonido activado.
  Future<void> init() async {
    try {
      await loadSettings();
    } catch (e) {
      debugPrint('Error inicializando SoundController: $e');
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  void toggleSound(bool value) {
    _soundEnabled = value;
    saveSettings();
  }

  /// Reproduce una voz específica ("faltan 10 segundos", "5", "4", etc.)
  Future<void> playVoice(String assetName) async {
    if (!_soundEnabled) return;
    try {
      await _voicePlayer.stop(); // Detener cualquier voz previa
      await _voicePlayer.setAsset('assets/$assetName');
      await _voicePlayer.play();
    } catch (e) {
      debugPrint('Error reproduciendo voz $assetName: $e');
    }
  }

  /// Reproduce la alarma crillona seguida de "terminó el tiempo".
  Future<void> playFinalAlarm(bool Function() shouldContinue) async {
    if (!_soundEnabled) return;
    try {
      // 1. Reproducir alarma estridente
      await _alarmPlayer.setAsset('assets/alarm.wav');
      await _alarmPlayer.setLoopMode(LoopMode.one); // Hacer que la alarma chille en loop corto
      await _alarmPlayer.play();
      
      // Detener loops tras un corto periodo y reproducir voz
      await Future.delayed(const Duration(milliseconds: 1500));
      await _alarmPlayer.stop();
      await _alarmPlayer.setLoopMode(LoopMode.off);

      if (shouldContinue()) {
        await _voicePlayer.setAsset('assets/voice_termino.mp3');
        await _voicePlayer.play();
      }
    } catch (e) {
      debugPrint('Error reproduciendo alarma final: $e');
    }
  }

  void stopAll() {
    _voicePlayer.stop();
    _alarmPlayer.stop();
  }

  void dispose() {
    _voicePlayer.dispose();
    _alarmPlayer.dispose();
  }
}
