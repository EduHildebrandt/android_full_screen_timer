import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'timer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ocultar barra de estado y de navegación (Pantalla Completa Immersiva)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Forzar orientación horizontal o vertical según preferencia, aquí dejamos libre
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Evitar que la pantalla se apague (Wake Lock) al iniciar la app
  WakelockPlus.enable();

  runApp(const FullScreenTimerApp());
}

class FullScreenTimerApp extends StatelessWidget {
  const FullScreenTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temporizador Full Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Estilo inmersivo negro
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const TimerScreen(),
    );
  }
}
