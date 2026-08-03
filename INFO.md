# Especificación Técnica y Funcional: Juego Estilo Snake.io en Flutter & Dart

Este documento contiene la recopilación completa de mecánicas, arquitectura técnica y modelo de monetización para el desarrollo de un juego similar a **Snake.io** utilizando **Flutter** y **Dart**.

---

## 1. Concepto General y Core Loop

* **Género:** Arcade .io / Acción multijugador casual.
* **Objetivo Principal:** Controlar una serpiente, consumir masa (orbes) para crecer, eliminar a otras serpientes cortándoles el paso y convertirse en la serpiente más grande del mapa.
* **Bucle Principal (Core Loop):**
  1. **Nacer** en una posición aleatoria del mapa con un tamaño base.
  2. **Navegar y Comer** orbes pequeños dispersos o los restos de otras serpientes muertas.
  3. **Acelerar (Boost)** para encerrar a rivales o escapar de situaciones peligrosas.
  4. **Eliminar / Morir:** Si la cabeza de una serpiente choca contra el cuerpo de otra, muere instantáneamente y se convierte en una estela de orbes de alta densidad.
  5. **Monetización / Reintento:** Opciones de revivir mediante anuncios o reiniciar la partida.

---

## 2. Mecánicas de Juego Detalladas

### A. Movimiento y Control
* **Joystick Virtual:** Control direccional de 360 grados suave y responsivo.
* **Radio de Giro (Turning Radius):** La cabeza de la serpiente gira con cierta inercia; cuanto más larga es la serpiente, ligeramente menor es la agilidad de giro.
* **Mecánica del Cuerpo (Trail / Vertebrae System):** Cada segmento sigue la trayectoria registrada del segmento anterior manteniendo una distancia fija inter-segmento.

### B. Sistema de Aceleración (Boost)
* **Activación:** Botón dedicado para incrementar la velocidad (ej. $1.8\times$ o $2.0\times$).
* **Costo:** Mientras se mantiene presionado el acelerador, la serpiente pierde masa gradualmente, dejando un rastro de pequeños orbes detrás.
* **Condición Límite:** Si la serpiente alcanza el tamaño mínimo base, la función de aceleración se deshabilita temporalmente.

### C. Sistema de Colisiones
* **Cabeza vs Cuerpo Rival:** La colisión ocurre únicamente cuando el área del *hitbox* de la cabeza interactúa con el *hitbox* de algún segmento del cuerpo de otra serpiente.
* **Cabeza vs Propio Cuerpo:** No hay colisión destructiva (el jugador puede cruzarse sobre su propio cuerpo de forma segura).
* **Límites del Mapa:** La colisión de la cabeza contra el borde exterior de la arena destruye la serpiente.

### D. Bots e Inteligencia Artificial (Multijugador Simulado)
> **Dato Clave de Arquitectura:** La mayoría de los juegos estilo *Snake.io* móviles utilizan **bots simulados localmente** o en un servidor híbrido para garantizar 0% de *lag*, permitir juego offline y reducir los costos de infraestructura backend.

* **Comportamiento de Bots:**
  * Movimiento estocástico/aleatorio en áreas libres.
  * Atracción hacia concentraciones de orbes cercanas.
  * Algoritmo de evasión si detectan la cabeza de una serpiente rival en su área de influencia.
  * Aceleración táctica para intentar cortar el paso a serpientes cercanas.

---

## 3. Modelo de Monetización (Anuncios e IAP)

Diseñado para maximizar el eCPM sin comprometer la retención de usuarios.

### A. Anuncios (Ads - AdMob / Unity Ads)
1. **Anuncios Recompensados (Rewarded Ads):**
   * **Revivir:** Continuar la partida actual manteniendo un porcentaje del tamaño previo a la muerte (máximo 1 vez por partida).
   * **Multiplicador de Recompensa:** Duplicar la moneda o puntos obtenidos al finalizar la partida.
   * **Desbloqueo de Skins:** Ver un video para usar un aspecto exclusivo temporal o permanentemente.
2. **Anuncios Intersticiales (Interstitial Ads):**
   * Desplegados tras la pantalla de *Game Over* (con un enfriamiento o *cooldown* de 2 a 3 partidas para evitar la frustración).
3. **Anuncios Banner (Banner Ads):**
   * Visibles únicamente en el menú principal y pantalla de selección de skins (nunca durante el gameplay activo).

### B. Compras In-App (IAP)
* **Remove Ads:** Pago único para eliminar anuncios intersticiales y de banner.
* **Pases de Aspectos / Tienda de Skins:** Compra directa de monedas o paquetes de skins cosméticos exclusivos.

---

## 4. Arquitectura Técnica Recomendada en Flutter & Dart

Para mantener 60 FPS estables con múltiples elementos dinámicos en pantalla, se debe evitar el uso de widgets tradicionales de Flutter (`Stack`, `Positioned`) en el área del juego.

| Componente | Opción Recomendada | Razón Técnica |
| :--- | :--- | :--- |
| **Motor de Juego** | **Flame Engine** (`flame`) | Aporta `GameLoop`, árbol de componentes, sistema de cámara y soporte eficiente de colisiones. |
| **Renderizado** | `Flame Canvas` / `SpriteBatch` | Permite dibujar múltiples segmentos e imitación de fluido mediante canvas directo en la GPU. |
| **Optimizador de Colisiones** | QuadTree / Spatial Grid Partitioning | Filtra comparaciones de colisión $O(N^2)$ a solo entidades dentro del mismo sector geométrico. |
| **Monetización** | `google_mobile_ads` | Plugin oficial de AdMob para la integración de banners, intersticiales y videos recompensados. |
| **Gestión de Audio** | `flame_audio` | Manejo de efectos sonoros (comer, acelerar, morir) y música ambiental sin congelar el hilo principal. |

---


