import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:modern_go/features/cart/domain/entities/cart_item.dart';
import 'package:modern_go/features/cart/domain/entities/cart_update.dart';

/// Manages the Socket.IO connection to the Modern Go backend for real-time
/// cart updates from the AI vision system.
///
/// The Flutter app is a **receiver only** — the AI system emits cart actions,
/// and this service listens for updates and exposes them as Dart streams.
class SocketService {
  io.Socket? _socket;

  // ─── Stream Controllers ────────────────────────────────────────────

  final _cartCurrentController = StreamController<List<CartItem>>.broadcast();
  final _cartUpdateController = StreamController<CartUpdate>.broadcast();
  final _sessionReplacedController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // ─── Public Streams ────────────────────────────────────────────────

  /// Emits the full cart when first connected (initial state)
  Stream<List<CartItem>> get cartCurrent => _cartCurrentController.stream;

  /// Emits every real-time cart change from the AI vision system
  Stream<CartUpdate> get cartUpdates => _cartUpdateController.stream;

  /// Emits when this device's session has been replaced by another device
  Stream<String> get sessionReplaced => _sessionReplacedController.stream;

  /// Emits true when connected, false when disconnected
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Whether the socket is currently connected
  bool get isConnected => _socket?.connected ?? false;

  // ─── Connect ───────────────────────────────────────────────────────

  /// Connect to the Modern Go socket server.
  ///
  /// [serverUrl] — Base URL of the socket server (e.g., 'http://192.168.1.100:3001')
  /// [jwtToken]  — Customer JWT from login/register REST API
  void connect({required String serverUrl, required String jwtToken}) {
    // Clean up any existing connection
    disconnect();

    _socket = io.io(
      '$serverUrl/mobile',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': jwtToken})
          .build(),
    );

    _registerEventHandlers();
    _socket!.connect();
  }

  // ─── Event Registration ────────────────────────────────────────────

  void _registerEventHandlers() {
    final socket = _socket!;

    // ── Connection lifecycle ──────────────────────────────────────

    socket.onConnect((_) {
      _connectionStateController.add(true);
    });

    socket.onDisconnect((_) {
      _connectionStateController.add(false);
    });

    socket.onConnectError((error) {
      _connectionStateController.add(false);
    });

    socket.onReconnect((_) {
      _connectionStateController.add(true);
    });

    // ── Cart events ──────────────────────────────────────────────

    socket.on('cart:current', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final cartItems = (map['cart'] as List)
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _cartCurrentController.add(cartItems);
      } catch (e) {
        // Error parsing cart:current — logged silently
      }
    });

    socket.on('cart:updated', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final update = CartUpdate.fromJson(map);
        _cartUpdateController.add(update);
      } catch (e) {
        // Error parsing cart:updated — logged silently
      }
    });

    // ── Session management ───────────────────────────────────────

    socket.on('session:replaced', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final message = map['message'] as String? ?? 'Session replaced';
      _sessionReplacedController.add(message);

      // CRITICAL: Disable reconnection to prevent infinite loop
      socket.io.options?['reconnection'] = false;
      socket.dispose();
      _socket = null;
    });

    // ── Error event ──────────────────────────────────────────────

    socket.on('error', (data) {
      // Server-side errors — logged silently
    });
  }

  // ─── Disconnect ────────────────────────────────────────────────────

  /// Cleanly disconnect from the server.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  // ─── Dispose ───────────────────────────────────────────────────────

  /// Release all resources. Call this when the service is no longer needed.
  void dispose() {
    disconnect();
    _cartCurrentController.close();
    _cartUpdateController.close();
    _sessionReplacedController.close();
    _connectionStateController.close();
  }
}
