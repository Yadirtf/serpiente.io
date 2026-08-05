# Arquitectura Base del Proyecto Snake.io

## Objetivo

Construir un motor de juego modular, escalable y mantenible que permita
evolucionar desde un modo **offline** hasta **LAN**, **online**,
temporadas, skins, eventos y nuevos modos de juego sin reescribir el
núcleo.

------------------------------------------------------------------------

# Principios

-   Responsabilidad única por módulo.
-   Bajo acoplamiento.
-   Alta cohesión.
-   Reutilización.
-   Separación entre lógica, renderizado y datos.
-   Comunicación mediante eventos.
-   El motor no depende de Flutter UI.

------------------------------------------------------------------------

# Arquitectura General

``` text
Game Engine
├── Snake System
├── Orb System
├── Collision System
├── Physics System
├── Spawn System
├── Camera System
├── Background System
├── Audio System
├── FX System
├── UI System
├── Theme System
├── Bot System
├── Network System
└── Match System
```

Cada sistema tiene una única responsabilidad.

# Snake

``` text
Snake
├── SnakeModel
├── SnakeLogic
├── SnakeRenderer
├── Movement
├── Growth
├── Boost
├── Collision
├── Animation
├── NameTag
├── Crown
└── NetworkSync
```

## Model

Guarda únicamente estado: - id - posición - dirección - velocidad -
segmentos - nombre - skin - estado

## Logic

-   movimiento
-   crecimiento
-   muerte
-   boost
-   límites

## Renderer

-   dibuja cabeza
-   cuerpo
-   cola
-   accesorios
-   efectos visuales

------------------------------------------------------------------------

# Orbes

``` text
Orb
├── Spawn
├── Respawn
├── Collection
├── Animation
├── Glow
└── Renderer
```

La lógica jamás depende del aspecto visual.

------------------------------------------------------------------------

# Fondo

``` text
Background
├── Sky
├── Bush Layer Back
├── Bush Layer Middle
├── Bush Layer Front
├── Floating Leaves
├── Particles
├── Lighting
└── Parallax
```

Beneficios: - temporadas - cambio de mapas - rendimiento - animaciones
independientes

------------------------------------------------------------------------

# Pantallas

``` text
Splash
Loading
Home
Lobby
Game
Pause
GameOver
Ranking
Shop
Inventory
Settings
```

Cada pantalla aislada.

------------------------------------------------------------------------

# Comunicación

Usar Event Bus.

Ejemplos:

SnakeDead → sonido → partículas → estadísticas → UI

OrbCollected → crecimiento → puntuación → sonido → partículas

Esto evita dependencias directas.

------------------------------------------------------------------------

# Entrada

Definir una interfaz única:

``` dart
abstract class InputSource{
  Direction getDirection();
  bool isBoosting();
}
```

Implementaciones:

-   HumanInput
-   BotInput
-   LanInput
-   OnlineInput
-   ReplayInput

El motor nunca conoce quién controla la serpiente.

------------------------------------------------------------------------

# Modos

``` text
Offline
LAN
Online
```

Los tres usan el mismo motor.

Solo cambia el proveedor de datos.

------------------------------------------------------------------------

# Temas

Crear ThemeManager.

Debe poder cambiar:

-   fondos
-   arbustos
-   música
-   partículas
-   orbes
-   iluminación
-   interfaz

Permite temporadas sin tocar la lógica.

------------------------------------------------------------------------

# Organización sugerida

``` text
lib/
 core/
   engine/
   events/
   physics/
   interfaces/
 gameplay/
   snake/
   orb/
   map/
   bots/
 network/
 ui/
 assets/
```

------------------------------------------------------------------------
## Fase 4

-   Optimización.
-   Replay.
-   Estadísticas.

## Fase 5

-   LAN.

## Fase 6

-   Online con servidor autoritativo.

------------------------------------------------------------------------

# Reglas de oro

1.  Una clase = una responsabilidad.
2.  Nunca mezclar lógica con renderizado.
3.  Evitar dependencias entre módulos.
4.  Comunicar mediante eventos.
5.  Pensar en reutilización.
6.  Todo configurable.
7.  Preparar el proyecto para temporadas.
8.  Diseñar pensando en 100 jugadores aunque hoy existan 2.
9.  No duplicar lógica entre Offline, LAN y Online.
10. Antes de añadir funciones, mejorar la arquitectura.

------------------------------------------------------------------------

# Visión

El objetivo no es construir un juego pequeño, sino una plataforma capaz
de crecer durante años sin perder rendimiento ni mantenibilidad.

Una buena arquitectura hará que agregar skins, eventos, modos, mapas,
clanes, misiones, logros o temporadas sea una extensión del sistema
existente y no una reescritura del proyecto.
