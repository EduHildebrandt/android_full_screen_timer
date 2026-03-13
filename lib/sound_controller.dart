import 'package:just_audio/just_audio.dart';
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Controlador centralizado para la gestión de sonidos del temporizador.
/// Maneja la persistencia, reproducción y vistas previas.
class SoundController {
  // Jugadores de audio individuales para evitar conflictos de recursos
  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();
  final JbhRingtone _jbhRingtone = JbhRingtone();

  // Estado de los sonidos
  String? _beepUri;
  String _beepName = 'Default Notification';
  String? _alarmUri;
  String _alarmName = 'Default Alarm';
  bool _soundEnabled = true;

  // Getters para el estado
  String get beepName => _beepName;
  String get alarmName => _alarmName;
  bool get soundEnabled => _soundEnabled;
  String? get beepUri => _beepUri;
  String? get alarmUri => _alarmUri;

  /// Inicializa los reproductores con sonidos por defecto (assets).
  Future<void> init() async {
    try {
      await _beepPlayer.setAsset('assets/beep.wav');
      await _alarmPlayer.setAsset('assets/alarm.wav');
      await loadSettings();
    } catch (e) {
      debugPrint('Error inicializando SoundController: $e');
    }
  }

  /// Carga la configuración guardada desde SharedPreferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _beepUri = prefs.getString('beepUri');
    _beepName = prefs.getString('beepName') ?? 'Default Notification';
    _alarmUri = prefs.getString('alarmUri');
    _alarmName = prefs.getString('alarmName') ?? 'Default Alarm';
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

  /// Guarda la configuración actual en SharedPreferences.
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_beepUri != null) {
      await prefs.setString('beepUri', _beepUri!);
    } else {
      await prefs.remove('beepUri');
    }
    await prefs.setString('beepName', _beepName);
    
    if (_alarmUri != null) {
      await prefs.setString('alarmUri', _alarmUri!);
    } else {
      await prefs.remove('alarmUri');
    }
    await prefs.setString('alarmName', _alarmName);
    
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  /// Cambia el estado del interruptor de sonido.
  void toggleSound(bool value) {
    _soundEnabled = value;
    saveSettings();
  }

  /// Reproduce el sonido de "beep" corto (intermedio).
  Future<void> playBeep() async {
    if (!_soundEnabled) return;
    try {
      if (_beepUri != null && _beepUri!.isNotEmpty) {
        await _beepPlayer.setAudioSource(AudioSource.uri(Uri.parse(_beepUri!)));
      } else {
        await _beepPlayer.setAsset('assets/beep.wav');
      }
      await _beepPlayer.seek(Duration.zero);
      await _beepPlayer.play();
    } catch (e) {
      debugPrint('Error reproduciendo beep: $e. Usando fallback asset.');
      await _beepPlayer.setAsset('assets/beep.wav');
      await _beepPlayer.seek(Duration.zero);
      await _beepPlayer.play();
    }
  }

  /// Reproduce la alarma final (3 toques secuenciales).
  Future<void> playFinalAlarm(bool Function() shouldContinue) async {
    if (!_soundEnabled) return;
    for (int i = 0; i < 3; i++) {
      // Verificar si el temporizador sigue en cero antes de cada toque
      if (!shouldContinue()) break;
      
      try {
        if (_alarmUri != null && _alarmUri!.isNotEmpty) {
          await _alarmPlayer.setAudioSource(AudioSource.uri(Uri.parse(_alarmUri!)));
        } else {
          await _alarmPlayer.setAsset('assets/alarm.wav');
        }
        await _alarmPlayer.seek(Duration.zero);
        await _alarmPlayer.play();
      } catch (e) {
        debugPrint('Error reproduciendo alarma: $e. Usando fallback asset.');
        await _alarmPlayer.setAsset('assets/alarm.wav');
        await _alarmPlayer.seek(Duration.zero);
        await _alarmPlayer.play();
      }
      
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 2500));
      }
    }
  }

  /// Detiene todos los sonidos activos.
  void stopAll() {
    _beepPlayer.stop();
    _alarmPlayer.stop();
    _previewPlayer.stop();
  }

  /// Obtiene los sonidos del sistema según el tipo (Notificación o Alarma).
  Future<List<JbhRingtoneModel>> getSystemSounds(String type) async {
    try {
      if (type == 'Notificaciones') {
        return await _jbhRingtone.getRingtonesByType(RingtoneType.notification);
      } else {
        return await _jbhRingtone.getRingtonesByType(RingtoneType.alarm);
      }
    } catch (e) {
      debugPrint('Error obteniendo sonidos del sistema: $e');
      return [];
    }
  }

  /// Reproduce una vista previa de un sonido.
  Future<void> playPreview(String uri) async {
    try {
      await _previewPlayer.stop(); // Detener previa anterior
      await _previewPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      await _previewPlayer.play();
    } catch (e) {
      debugPrint('Error en vista previa: $e');
    }
  }

  /// Detiene la vista previa.
  void stopPreview() {
    _previewPlayer.stop();
  }

  /// Actualiza el sonido seleccionado para un tipo específico.
  void setSelectedSound(String type, JbhRingtoneModel selected) {
    if (type == 'Notificaciones') {
      _beepUri = selected.uri;
      _beepName = selected.title;
    } else {
      _alarmUri = selected.uri;
      _alarmName = selected.title;
    }
    saveSettings();
  }

  /// Libera los recursos de los reproductores.
  void dispose() {
    _beepPlayer.dispose();
    _alarmPlayer.dispose();
    _previewPlayer.dispose();
  }
}
