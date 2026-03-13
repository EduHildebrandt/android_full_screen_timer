# Lessons Learned / Reglas de Automejora

*(Este archivo se actualizará permanentemente conforme avance el proyecto para registrar patrones, fallos comunes y reglas estrictas del entorno local).*

## Lecciones Actuales:
- Mantener simplicidad primero. Menos código = menos errores.
- Antes de dar por terminada una tarea (Definition of Done), verificar exhaustivamente el caso de uso y garantizar que pasa el Quality Assurance visual ("pixel perfect").

## Lección: Migración Windows → Linux (2026-03-11)
- Flutter en Linux puede estar instalado pero fuera del PATH. Verificar en `~/development/flutter/bin/flutter` antes de asumir que no está instalado.
- Agregar permanentemente al PATH con `echo 'export PATH="$PATH:/home/edu/development/flutter/bin"' >> ~/.bashrc`.
- `TweenAnimationBuilder` con `begin == end` no anima. Usar `begin: valorAnterior, end: nuevoValor` o simplemente `begin: 1.0, end: progress` para animar desde el inicio.
- **Audio: URIs del Sistema**: `flutter_ringtone_player` es limitado para sonidos personalizados. `audioplayers` permite reproducir `content://` URIs obtenidos del sistema (vía `flutter_system_ringtones`) usando `UrlSource`.
- **Persistencia**: Siempre usar `shared_preferences` para guardar configuraciones de usuario como URIs de sonidos para evitar que se pierdan al cerrar la app.
- **AudioContext**: Es vital configurar el `AudioContext` en Android para usar `usageType: AndroidUsageType.alarm` si queremos que el sonido respete el volumen de alarma del sistema.
- **Permisos de Manifiesto**: No olvidar declarar `WAKE_LOCK`, `MODIFY_AUDIO_SETTINGS` y `READ_MEDIA_AUDIO` en el `AndroidManifest.xml`, de lo contrario, el sistema puede denegar el acceso a los componentes de audio.
- **Librería de Audio (just_audio)**: En Android 13+, `audioplayers` puede fallar con `MEDIA_ERROR_UNKNOWN` al intentar leer `content://` URIs o assets comprimidos. `just_audio` es más robusto al usar ExoPlayer internamente.
- **Robustez de Audio (Fallback)**: Los `content://` URIs del sistema pueden fallar por permisos temporales o persistentes. Siempre incluir sonidos de respaldo en `assets/` y usar un `try-catch` para reproducirlos si el sonido del sistema falla.
- **Gestión de Recursos de Audio**: Al usar reproductores de audio en modales (como vistas previas), es crítico usar `whenComplete()` en el modal para asegurar que el reproductor se detenga (`stop()`) y no queden sonidos colgados.
- **Modularización (Controllers)**: Extraer la lógica de persistencia y audio a un `SoundController` separado del `Widget` principal mejora la legibilidad, facilita la depuración y evita fugas de memoria al centralizar los cicols de vida de los `AudioPlayer`.
