import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'sound_controller.dart';
import 'package:jbh_ringtone/jbh_ringtone.dart';

/// Pantalla principal del Temporizador.
/// Muestra un contador circular y controles de tiempo.
class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Lógica de tiempo
  int _totalSeconds = 30;
  int _currentSeconds = 30;
  bool _isRunning = false;
  Timer? _timer;

  // Controlador de sonido refactorizado
  final SoundController _soundController = SoundController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Inicialización asíncrona de la aplicación
  Future<void> _initializeApp() async {
    await _loadTimeSettings();
    await _soundController.init();
    WakelockPlus.enable(); // Mantener pantalla encendida
    if (mounted) setState(() {});
  }

  /// Carga la configuración de tiempo
  Future<void> _loadTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalSeconds = prefs.getInt('totalSeconds') ?? 30;
      _currentSeconds = _totalSeconds;
    });
  }

  /// Guarda la configuración de tiempo
  Future<void> _saveTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalSeconds', _totalSeconds);
  }

  // --- Lógica del Temporizador ---

  void _startTimer() {
    if (_currentSeconds > 0 && !_isRunning) {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _soundController.stopAll();
    _pauseTimer();
    setState(() => _currentSeconds = _totalSeconds);
    
    // v1.1: Auto-inicio al reiniciar
    _startTimer();
  }

  /// Función que se ejecuta cada segundo
  void _tick(Timer timer) {
    if (_currentSeconds > 0) {
      setState(() => _currentSeconds--);

      // Disparadores de sonido
      if (_currentSeconds == 10) {
        _soundController.playBeep();
      } else if (_currentSeconds <= 5 && _currentSeconds >= 1) {
        _soundController.playBeep();
      } else if (_currentSeconds == 0) {
        // Alarma final de 3 toques
        _soundController.playFinalAlarm(() => _currentSeconds == 0);
      }

      if (_currentSeconds == 0) _pauseTimer();
    } else {
      _pauseTimer();
    }
  }

  // --- UI: Diálogos y Selectores ---

  /// Muestra el modal de configuración principal
  Future<void> _showSettingsDialog() async {
    final TextEditingController timeController = 
        TextEditingController(text: _totalSeconds.toString());
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[950],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 32, right: 32, top: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Configuración', 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Entrada de Tiempo
                  _buildSettingTile(
                    title: 'Tiempo (Segundos)',
                    trailing: SizedBox(
                      width: 80,
                      child: TextField(
                        controller: timeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          final p = int.tryParse(val);
                          if (p != null) {
                            setState(() => _totalSeconds = p);
                            _saveTimeSettings();
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const Divider(color: Colors.white10),
                  
                  // Selección de Sonido Intermedio
                  _buildSettingTile(
                    title: 'Sonido Intermedio',
                    subtitle: _soundController.beepName,
                    onTap: () async {
                      final selected = await _showSoundPicker('Notificaciones');
                      if (selected != null) {
                        _soundController.setSelectedSound('Notificaciones', selected);
                        setModalState(() {});
                        setState(() {});
                      }
                    },
                  ),

                  const Divider(color: Colors.white10),
                  
                  // Selección de Alarma Final
                  _buildSettingTile(
                    title: 'Alarma Final',
                    subtitle: _soundController.alarmName,
                    onTap: () async {
                      final selected = await _showSoundPicker('Alarmas');
                      if (selected != null) {
                        _soundController.setSelectedSound('Alarmas', selected);
                        setModalState(() {});
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  
                  _buildActionButton('CERRAR', Colors.cyanAccent, () => Navigator.pop(context)),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Diálogo selector de sonidos del sistema
  Future<JbhRingtoneModel?> _showSoundPicker(String type) async {
    final sounds = await _soundController.getSystemSounds(type);
    if (!mounted) return null;

    return await showModalBottomSheet<JbhRingtoneModel>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text('Seleccionar $type', style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),
              if (sounds.isEmpty)
                const Expanded(child: Center(child: Text('No se encontraron sonidos', style: TextStyle(color: Colors.white38))))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: sounds.length,
                    itemBuilder: (context, index) {
                      final sound = sounds[index];
                      return ListTile(
                        title: Text(sound.title, style: const TextStyle(color: Colors.white)),
                        leading: const Icon(Icons.music_note, color: Colors.white38),
                        onTap: () => _soundController.playPreview(sound.uri),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.cyanAccent),
                          onPressed: () {
                            _soundController.stopPreview();
                            Navigator.pop(context, sound);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).whenComplete(() => _soundController.stopPreview()); // Garantiza detener preview al cerrar
  }

  // --- Helpers de UI ---

  Widget _buildSettingTile({required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _formatTime() {
    final int minutes = _currentSeconds ~/ 60;
    final int seconds = _currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalSeconds > 0 ? (_currentSeconds / _totalSeconds) : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            _buildTopBar(),
            
            // Reloj central
            Expanded(child: Center(child: _buildTimerDisplay(progress))),

            // Botones inferiores
            Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: _buildControlButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _soundController.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _soundController.soundEnabled ? Colors.white : Colors.white38,
              size: 32,
            ),
            onPressed: () => setState(() => _soundController.toggleSound(!_soundController.soundEnabled)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 32),
            onPressed: _isRunning ? null : _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(double progress) {
    return GestureDetector(
      onTap: _isRunning ? _pauseTimer : _startTimer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 320, height: 320,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: progress),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[900],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatTime(),
                style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: -2)),
              if (_currentSeconds >= 60)
                Text('$_currentSeconds SEG TOTALES',
                  style: const TextStyle(fontSize: 16, color: Colors.white38, letterSpacing: 2.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'reset',
          backgroundColor: Colors.grey[800],
          onPressed: _resetTimer,
          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 32),
        ),
        FloatingActionButton(
          heroTag: 'play_pause',
          backgroundColor: _isRunning ? Colors.amber : Colors.cyanAccent,
          onPressed: _isRunning ? _pauseTimer : _startTimer,
          child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 40),
        ),
      ],
    );
  }
}
