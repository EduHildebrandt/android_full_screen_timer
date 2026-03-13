# Master Roadmap: Temporizador Android a Pantalla Completa

## 1. Visión y Requisitos del Producto
- **Objetivo**: Temporizador de cuenta regresiva en pantalla completa para Android.
- **Entrada de Tiempo**: Configurable en segundos.
- **Controles**: Botones de Inicio, Pausa y Reseteo fácil.
- **Alertas Sonoras**:
  - Señal a los 10 segundos restantes.
  - Señal en cada uno de los últimos 5 segundos (5, 4, 3, 2, 1).
  - Toggle (interruptor) para habilitar/deshabilitar sonidos.
- **UX/UI**: Interfaz clara, números grandes legibles desde lejos, minimalista pero elegante.

## 2. Decisiones de Arquitectura
- **Stack Tecnológico**: Flutter (elegido por el usuario).
- **Manejo de Estado**: `setState` nativo para simplificar y evitar dependencias innecesarias dadas las reglas de "Simplicidad Primero", o `provider` de ser requerido a futuro.
- **Wake Lock**: Necesario para evitar apagado de pantalla (usaremos paquete `wakelock_plus`).

## 3. Fases de Desarrollo
1. **Fase 1: Configuración**: Inicialización del proyecto, setup del stack y reglas recurrentes.
2. **Fase 2: Core Timer Engine**: Lógica de cuenta regresiva, pausas y reseteo.
3. **Fase 3: UI & Vista**: Diseño a pantalla completa, controles de usuario e inputs.
4. **Fase 4: Alertas Sonoras & Config**: Lógica de disparos de audio sincronizados en 10s y últimos 5s. Toggle de configuración.
5. **Fase 5: Verificación y Pulido**: Auditoría UX, manejo de estado vacío/inicial, Wake Lock.
6. **Fase 6: Estabilización y Refactorización (Actual)**: Corrección de bugs de sonido, refactorización y GitHub sync.

## 4. Actualizaciones v1.1 (Solicitadas)
- **Tiempo por defecto**: Ajustado a 30s.
- **Auto-reinicio**: Al resetear el contador, este inicia automáticamente.
- **Optimización de Pausa**: Confirmar que el flujo de pausa es fluido.

## 5. Actualizaciones v0.3 (Solicitadas)
- **Corrección de Bugs**: Solucionar problemas al cambiar sonidos y fugas de memoria.
- **Refactorización**: Modularizar lógica de audio y mejorar comentarios.
- **GitHub Sync**: Push al repositorio oficial.

## Revisión y Resolución (Auto-Healed)
- [v1.1] Implementado auto-reinicio y cambio de default. UX mejorada para sesiones repetitivas.
- [v0.3] Implementada corrección de cambio de sonidos y refactorización completa.
