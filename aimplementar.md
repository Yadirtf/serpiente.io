Objetivo General

La pantalla principal debe convertirse en el centro de navegación del juego.

El jugador debe poder realizar tres acciones principales antes de iniciar una partida:

Administrar su perfil.
Seleccionar el modo de juego.
Seleccionar la skin que utilizará su serpiente.

Toda la arquitectura debe diseñarse pensando en el crecimiento del proyecto, evitando implementar elementos estáticos o difíciles de extender.

Distribución General

La distribución deberá mantener aproximadamente la siguiente estructura:

┌────────────────────────────────────────────────────┐

[ Perfil ]

              [ Mejor Puntaje ]

         [ Carrusel de Modos ]



         [ Editar Serpiente ]

                         [ Jugar ]

└────────────────────────────────────────────────────┘

Cada componente deberá ser independiente y reutilizable.

1. Panel de Perfil del Jugador
Ubicación

Esquina superior izquierda.

Debe permanecer siempre en esta posición sin importar la resolución de la pantalla.

Debe respetar un margen de seguridad respecto a los bordes.

Objetivo

Mostrar la identidad del jugador y permitir el acceso rápido a la configuración y edición del perfil.

Estructura
┌────────────────────────────────────┐

[⚙] [Avatar] Nombre del jugador [✎]

        UID

└────────────────────────────────────┘
Componentes
Botón Configuración

Ubicado al extremo izquierdo.

Características:

Botón circular.
Abre la pantalla de configuración.
Debe tener animación al presionarlo.
Avatar

Ubicado después del botón de configuración.

Debe mostrar:

Avatar seleccionado.
Imagen por defecto si aún no existe uno.

Debe actualizarse automáticamente cuando el jugador cambie su avatar.

Nombre del jugador

Ubicado a la derecha del avatar.

Características:

Fuente grande.
Negrita.
Centrado verticalmente.

Si el nombre supera el espacio disponible deberá truncarse.

Ejemplo:

JugadorProfes...
UID

Ubicado debajo del nombre.

Características:

Texto pequeño.
Color gris claro.

Ejemplo:

UID: 12023A788F72

No debe ser editable.

Botón Editar

Ubicado al extremo derecho.

Icono de lápiz.

Permitirá editar posteriormente:

Nombre
Avatar
Foto de perfil
Otros elementos del perfil
Diseño

El panel debe verse como una tarjeta flotante.

Características:

Fondo azul.
Bordes redondeados.
Sombra suave.
Padding interno.
Ligero efecto brillante.
2. Carrusel Central de Modos de Juego

Este será el componente principal de la pantalla de inicio.

Debe ubicarse:

Debajo del panel de Mejor Puntaje.
Encima del botón Jugar.

Debe ocupar aproximadamente entre el 55% y el 65% del ancho disponible.

Objetivo

El carrusel será el selector principal del modo de juego.

Cada tarjeta representará un modo diferente.

El jugador podrá deslizar horizontalmente para seleccionar el modo que desea jugar.

El modo que permanezca centrado será considerado el modo activo.

Al presionar Jugar, se iniciará dicho modo.

Modos de juego previstos
1. Offline (Disponible)

Será el modo predeterminado.

Características:

Contra bots.
Sin conexión a Internet.
Disponible desde la primera versión.
2. Online (Futuro)

Inicialmente aparecerá como:

Próximamente

En futuras versiones permitirá:

Partidas contra jugadores reales.
Ranking mundial.
Sincronización con servidor.
Eventos online.
Temporadas.
Recompensas especiales.
3. Multijugador por Red Local (Futuro)

También aparecerá inicialmente como:

Próximamente

Permitirá:

Crear partidas mediante una red Wi-Fi local.
Un jugador actuará como Host.
Los demás podrán unirse a la partida.
No requerirá conexión a Internet.
Ideal para jugar entre amigos en una misma red.
Diseño de cada tarjeta

Cada modo deberá representarse mediante una tarjeta.

Cada tarjeta podrá contener:

Imagen ilustrativa.
Nombre del modo.
Breve descripción.
Estado (Disponible / Próximamente / Bloqueado).
Icono representativo.

El diseño debe ser visualmente atractivo y ocupar la mayor parte del carrusel.

Navegación

El carrusel deberá permitir:

Deslizar horizontalmente.
Cambio automático mediante animaciones suaves.
Indicadores inferiores.

Ejemplo:

● ○ ○

El punto activo deberá resaltarse claramente.

Comportamiento

Siempre existirá un modo seleccionado.

Cuando el usuario pulse Jugar, se iniciará el modo actualmente seleccionado.

Ejemplos:

Si el carrusel está en:

Offline

Se abrirá una partida offline.

Si en el futuro está seleccionado:

Online

Se abrirá el flujo de conexión al servidor.

Si está seleccionado:

Multijugador LAN

Se abrirá el menú para crear o unirse a una partida local.

El botón Jugar nunca deberá cambiar su comportamiento.

Siempre ejecutará el modo actualmente seleccionado.

Arquitectura

El carrusel no debe contener datos escritos directamente en la interfaz.

Debe consumir una colección de modos de juego.

Ejemplo conceptual:

GameMode

- Offline
- Online
- LAN

Agregar un nuevo modo de juego no deberá requerir modificar el carrusel.

Solo añadir un nuevo elemento a la colección.

Animaciones

Las transiciones deberán ser suaves.

Preferiblemente:

Slide horizontal.
Fade.
Escala ligera.

No deben existir movimientos bruscos.

3. Botón "Editar Serpiente"

Este componente será el acceso principal al sistema de selección de skins.

Debe ubicarse:

En la parte inferior central.

Entre el botón Misiones y el botón Jugar.

Debe mantenerse perfectamente centrado.

Objetivo

Abrir la pantalla de Skins, donde el jugador podrá administrar la apariencia de su serpiente.

En la primera versión el sistema estará orientado exclusivamente a la selección de skins.

Sin embargo, la arquitectura deberá quedar preparada para futuras ampliaciones.

Funcionalidad Inicial

La pantalla permitirá:

Ver todas las skins disponibles.
Visualizar skins bloqueadas.
Visualizar skins desbloqueadas.
Seleccionar una skin.
Equipar una skin.
Ver una vista previa antes de confirmar.

Cuando una skin sea equipada, deberá reflejarse inmediatamente tanto en la partida como en la vista previa del botón del menú principal.

Expansión Futura

El sistema debe permitir incorporar posteriormente:

Skins comunes.
Skins raras.
Skins épicas.
Skins legendarias.
Skins obtenidas mediante logros.
Skins de eventos.
Skins de temporada.
Skins compradas con monedas.
Skins premium.
Paquetes de skins.
Animaciones especiales.
Efectos visuales exclusivos.

Todo ello sin necesidad de rediseñar la arquitectura.

Vista previa

El botón deberá mostrar una representación de la skin actualmente equipada.

No deberá utilizar una imagen fija.

La vista previa deberá generarse utilizando la skin equipada por el jugador, mostrando exactamente su apariencia actual.

Cuando el jugador cambie de skin, la vista previa deberá actualizarse automáticamente.

Indicador de novedades

Si existen nuevas skins desbloqueadas que el jugador aún no ha revisado, el botón podrá mostrar un pequeño indicador rojo.

Ejemplo:

(3)

o simplemente:

•

Cuando el jugador ingrese a la pantalla de skins, el indicador desaparecerá.

Diseño Responsive

Todos los componentes deberán mantener su posición relativa en cualquier resolución.

No deberán superponerse.

Todo el contenido deberá escalar proporcionalmente para dispositivos móviles con diferentes tamaños de pantalla.

Requisitos Técnicos

Todos los componentes deberán implementarse como widgets independientes y reutilizables.

Se recomienda la siguiente estructura:

HomeScreen
│
├── ProfilePanel
├── HighScorePanel
├── GameModeCarousel
├── SnakeEditorButton
└── PlayButton

Cada widget deberá tener responsabilidades claramente definidas y no depender directamente de otros componentes de la interfaz.

Arquitectura Recomendada

El sistema debe diseñarse siguiendo una arquitectura modular.

ProfilePanel: consume únicamente la información del perfil del jugador.
GameModeCarousel: consume una colección de modos de juego (GameMode), permitiendo agregar nuevos modos sin modificar la interfaz.
SnakeEditorButton: obtiene la vista previa directamente del sistema de skins equipado, evitando imágenes estáticas.
PlayButton: consulta el modo actualmente seleccionado en el carrusel e inicia la partida correspondiente.

Esta separación permitirá que futuras funcionalidades (como juego online, temporadas, eventos, nuevos modos o cosméticos) se integren sin necesidad de rediseñar la pantalla principal.

Flujo de Usuario

El flujo esperado dentro del menú principal será el siguiente:

El jugador ingresa al menú principal.
Visualiza su perfil y puede acceder a la configuración o editar sus datos.
Selecciona el modo de juego desde el carrusel central (Offline, Online o Multijugador LAN).
Accede al menú Editar Serpiente para elegir la skin con la que desea jugar.
Presiona el botón Jugar.
El juego inicia utilizando el modo de juego y la skin actualmente seleccionados.

Este flujo proporciona una experiencia intuitiva, escalable y preparada para el crecimiento del proyecto, permitiendo incorporar nuevas funcionalidades sin alterar la estructura principal del menú.