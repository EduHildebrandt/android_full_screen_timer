import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'sound_controller.dart';

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
        _soundController.playVoice('voice_10.mp3');
      } else if (_currentSeconds <= 5 && _currentSeconds >= 1) {
        _soundController.playVoice('voice_$_currentSeconds.mp3');
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
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Modo Voz Activo:\nTe avisaremos a los 10 segundos, últimos 5 segundos, y al finalizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/poker_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54, // Oscurecer un poco para legibilidad
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
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
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), // Oro
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 4)),
                  ],
                ),
              ),
              const Text(
                "TEMPORIZADOR",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          backgroundColor: Colors.black45,
          onPressed: _resetTimer,
          child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 32),
        ),
        FloatingActionButton(
          heroTag: 'play_pause',
          backgroundColor: _isRunning ? Colors.white24 : const Color(0xFFD40000), // Rojo Casino
          onPressed: _isRunning ? _pauseTimer : _startTimer,
          child: Icon(
            _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: _isRunning ? Colors.white : Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }
}
