import 'dart:async';

/// Un bus de eventos simple basado en Streams para comunicación desacoplada.
/// Permite que diferentes sistemas se comuniquen sin conocerse entre sí.
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController _controller = StreamController.broadcast();

  /// Escucha eventos de tipo [T].
  Stream<T> on<T>() {
    if (T == dynamic) {
      return _controller.stream as Stream<T>;
    } else {
      return _controller.stream.where((event) => event is T).cast<T>();
    }
  }

  /// Dispara un evento.
  void fire(event) {
    _controller.add(event);
  }

  /// Cierra el bus de eventos.
  void destroy() {
    _controller.close();
  }
}
