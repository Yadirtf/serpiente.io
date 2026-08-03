# Plan de Implementación Profesional para Snake.io en Flutter

## Objetivo
Crear un juego estilo `snake.io` en Flutter con:
- jugabilidad fluida y responsiva
- sistema de skins y personalización
- lógica de negocio escalable
- estructura limpia y modular
- base de datos local ordenada
- pruebas unitarias y de integración
- preparación para monetización futura

---

## 1. Arquitectura General

### 1.1 Modelo de Capas

La arquitectura será una mezcla de Clean Architecture y componentes de juego de Flame:

- `presentation/` - UI, pantallas, widgets, controladores de entrada.
- `game/` - motor de juego, bucle, físicas básicas, componentes de entidad.
- `domain/` - entidades, reglas de negocio, casos de uso, interfaces.
- `data/` - repositorios, servicios locales, persistencia, mapeadores.
- `core/` - constantes, tipos compartidos, utilidades, errores.

### 1.2 Principios clave

- **Separación de responsabilidades**: la lógica del juego no debe mezclarse con la UI.
- **Reutilización**: componentes reutilizables para entrada, renderizado y datos.
- **Escalabilidad**: diseño preparado para agregar bots, multijugador simulado y monetización.
- **Testabilidad**: cada capa probada con pruebas unitarias e integración.

---

## 2. Estructura de Carpetas

```
lib/
  src/
    core/
      constants/
      helpers/
      enums/
      errors/
      extensions/
    data/
      models/
      repositories/
      sources/
      persistence/
    domain/
      entities/
      repositories/
      usecases/
    game/
      components/
      controllers/
      models/
      systems/
      skins/
      views/
    presentation/
      screens/
      widgets/
      providers/
      state/
    app.dart
    main.dart
```

---

## 3. Tecnologías y Dependencias

### 3.1 Dependencias principales

- `flutter` (SDK)
- `flame` - motor de juego ligero
- `flame_audio` - sonido y música
- `google_mobile_ads` - anuncios y monetización
- `hive` + `hive_flutter` - persistencia local rápida y tipada
- `provider` o `riverpod` - gestión de estado de UI y configuración

### 3.2 Dependencias de desarrollo

- `flutter_test` - pruebas unitarias
- `mocktail` - mocks para pruebas
- `flame_test` - pruebas de componentes de juego
- `build_runner` + `hive_generator` - generación de adaptadores Hive

---

## 4. Modelo de Datos y Persistencia

### 4.1 Entidades clave

- `SnakeEntity`: posicionamiento, tamaño, velocidad, skin, estado.
- `OrbEntity`: punto de masa en el mapa.
- `GameSessionEntity`: puntos, tiempo, record, muerte, reinicios.
- `SkinEntity`: id, nombre, tipo, color, sprite.
- `PlayerProfileEntity`: progreso, monedas, compras, skins desbloqueados.

### 4.2 Persistencia local

- `Hive` como base de datos local para:
  - settings
  - progreso del jugador
  - skins desbloqueadas
  - datos de partidas cortas

- Repositorios:
  - `PlayerProfileRepository`
  - `SkinRepository`
  - `GameSessionRepository`

---

## 5. Diseño del Juego y Lógica

### 5.1 Bucle de juego

1. Inicializar `SnakeGame` y partida.
2. Registrar posición inicial aleatoria.
3. Generar orbes en el mapa con un despunte de densidad.
4. Procesar entrada del joystick / direcciones.
5. Actualizar movimiento de la cabeza y aplicar inercia.
6. Actualizar segmentos de cuerpo siguiendo la pista.
7. Detectar colisiones con orbes, límites y rivales.
8. Aplicar boost, crecimiento y caída de masa.
9. Rendear estado en pantalla cada frame.
10. Finalizar partida y almacenar resultados.

### 5.2 Componentes de juego

- `SnakeComponent` - cuerpo y cabeza, actualizado por posición.
- `OrbComponent` - item que se consume.
- `TrailComponent` - orbes dejados al boost/muerte.
- `EnemySnakeComponent` - bots o rivales.
- `HudComponent` - puntaje, boost, estado.

### 5.3 Sistema de colisiones

- Uso de grillas espaciales o partición cuadrática simple para eficiencia.
- Colisión de cabeza vs cuerpo rival.
- Sin colisión destructiva con propio cuerpo.
- Colisión con límites del mapa.

### 5.4 Input y control

- Joystick virtual 360º.
- Botón de boost.
- Gestos alternativos: deslizamiento o toque para dirección.

---

## 6. Skins y Personalización

### 6.1 Concepto de Skins

- Skins para la serpiente y partículas.
- Skins por color, textura, tema, brillo.
- Skins desbloqueables o comprables.

### 6.2 Implementación

- `SkinEntity` con datos de renderizado.
- `SkinRepository` para cargar skins disponibles y estado.
- Vista de selección de skins en pantalla de menú.
- Aplicación dinámica de skin en `SnakeComponent`.
- Soporte para `skins` locales y nuevos assets.

---

## 7. Monetización y Futuras Funciones

### 7.1 Base inicial para monetización

- Preparar hooks para anuncios recompensados.
- Pantalla de `Game Over` con botón para revivir.
- Variables de configuración para `Remove Ads` y `rewarded`.
- Separar lógica de anuncios en `services/ads_service.dart`.

### 7.2 Evolución futura

- tienda de skins
- pase de batalla
- modo competitivo con bots inteligentes
- eventos temporales y desafíos diarios

---

## 8. Estrategia de Pruebas

### 8.1 Pruebas unitarias

- `domain/`:
  - `SnakeMovementTest`
  - `CollisionDetectionTest`
  - `BoostLogicTest`
  - `OrbConsumptionTest`
  - `SkinRepositoryTest`

- `data/`:
  - pruebas de persistencia Hive

- `presentation/`:
  - pruebas de widgets de menú y HUD

### 8.2 Pruebas de juego

- `flame_test` para:
  - movimiento de snake
  - eventos de colisión
  - generación de orbes

### 8.3 Pruebas de integración

- flujo de `Game Over`
- selección de skin
- reinicio de partida

---

## 9. Fases y Hitos

### Fase 1: Base técnica y prototipo

- inicializar proyecto Flutter
- definir estructura de carpetas
- instalar `flame` y dependencias
- crear `SnakeGame` simple con movimiento y orbes
- crear pantalla de inicio y HUD

### Fase 2: Lógica de juego

- implementar crecimiento
- boost y pérdida de masa
- colisiones contra límites y orbes
- sistema de puntaje

### Fase 3: Skins y datos persistentes

- persistencia de perfil local
- pantalla de selección de skins
- sistemas de skins + assets

### Fase 4: Monetización inicial

- preparar servicio de anuncios
- pantalla `Game Over` con premio/revive
- registro de monedas y compras

### Fase 5: Testing y limpieza

- escribir pruebas unitarias y de juego
- revisar código y refactorizar
- optimizar rendimiento y estructura

---

## 10. Recomendación inmediata

1. Actualizar `pubspec.yaml` con `flame`, `hive` y `google_mobile_ads`.
2. Crear la estructura de carpetas propuesta.
3. Implementar la primera versión de `SnakeGame` en `lib/src/game/`.
4. Escribir pruebas unitarias de `domain/` antes de avanzar.

---

## 11. Notas de profesionalización

- Mantener cada archivo con responsabilidad única.
- Evitar lógica de juego dentro de widgets de Flutter.
- Documentar entidades y servicios.
- Registrar errores y estados de carga.
- Usar `const` donde sea posible para rendimiento.
- Mantener nombres claros y sin abreviaciones ambiguas.

---

## 12. Próximo entregable

Crear los siguientes elementos iniciales:
- `lib/main.dart`
- `lib/app.dart`
- `lib/src/game/snake_game.dart`
- `lib/src/game/components/snake_component.dart`
- `lib/src/game/components/orb_component.dart`
- `lib/src/domain/entities/snake_entity.dart`
- `lib/src/data/repositories/skin_repository.dart`
- pruebas unitarias iniciales en `test/`

Con esto tendrás una base sólida para escalar a un juego completo y preparar la personalización y monetización.
