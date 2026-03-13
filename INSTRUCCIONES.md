# 🚀 Instrucciones de Configuración y Despliegue

Como no tenías Flutter instalado en el momento de crear el código, he adelantado todo el trabajo creando la lógica de la aplicación y la interfaz directamente en esta carpeta.

Para poder ejecutar la aplicación en tu dispositivo o emulador Android, por favor sigue estos pasos una vez que instales Flutter.

### Paso 1: Instalar Flutter
Si aún no lo has hecho, descarga Flutter desde [flutter.dev](https://docs.flutter.dev/get-started/install) y asegúrate de añadir la ruta `flutter/bin` a tus variables de entorno PATH de Windows.

### Paso 2: Generar la estructura Nativa de Android
Abre una terminal en esta misma carpeta (`d:\Mi unidad\Temporizador`) y ejecuta el siguiente comando para generar los archivos de Android e iOS:

```cmd
flutter create --project-name android_full_screen_timer .
```
> **⚠️ IMPORTANTE:** Si el comando te pregunta si deseas sobreescribir `lib/main.dart` o `pubspec.yaml`, dile que **NO (n)**. El código que yo escribí en esos archivos contiene toda la lógica de tu Temporizador.

### Paso 3: Instalar Dependencias
Una vez generada la estructura, instala las librerías necesarias (`wakelock_plus` para mantener la pantalla encendida y `flutter_ringtone_player` para las alarmas sonoras):
```cmd
flutter pub get
```

### Paso 4: Ejecutar la Aplicación
Conecta tu celular Android con la Depuración USB habilitada (o abre un simulador de Android Studio) y ejecuta:
```cmd
flutter run
```

### Detalles de la Implementación
Todo el código sigue tus instrucciones de **«Simplicidad Primero»** y **«Elegancia»**:
- **Interfaz a Pantalla Completa**: Oculta la barra de estado superior nativa (Immersive mode).
- **Control de Sonidos Inteligente**: Sin necesidad de añadir archivos de audio pesados; se utilizan los sonidos del sistema nativo del teléfono a los 10 segundos y en la cuenta regresiva 5, 4, 3, 2, 1.
- **Wake Lock**: Evita que la pantalla entre en suspensión.
- **Seteo Práctico**: Solo necesitas tocar el ícono de temporizador arriba a la derecha para ingresar los segundos totales, y este guardará tu selección para un uso rápido.
