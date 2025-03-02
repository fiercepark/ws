import 'dart:async';

import 'package:shelf/shelf.dart' show Handler, Middleware, Request;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws
    show webSocketHandler;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

Middleware webSocket({required String path}) =>
    (Handler innerHandler) => (Request request) =>
        request.method == 'GET' && request.requestedUri.path == path
            ? _webSocketHandler(request)
            : innerHandler(request);

final _webSocketHandler = ws.webSocketHandler((WebSocketChannel webSocket) {
  void push(Object message) {
    try {
      print('ws < $message');
      webSocket.sink.add(message);
    } catch (e) {
      print('e $e');
    }
  }

  late final StreamSubscription<Object?> subscription;
  subscription = webSocket.stream.listen(
    (Object? message) {
      print('ws > $message');
      switch (message) {
        // Ping-Pong message.
        case "ping":
          push("pong");

        // Close connection.
        case "close":
          webSocket.sink.close(1000, 'NORMAL_CLOSURE');
          subscription.cancel();

        // Echo text.
        case String text:
          push(text);

        // Echo bytes.
        case List<int> bytes:
          push(bytes);
      }
    },
    onError: (Object error) => print('ws > [error] $error'),
    onDone: () => print('ws > [done]'),
    cancelOnError: true,
  );
});
