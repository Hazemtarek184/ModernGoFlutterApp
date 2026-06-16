import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:modern_go/features/cart/domain/entities/cart_item.dart';
import 'package:modern_go/features/cart/domain/entities/cart_update.dart';
import 'package:modern_go/features/cart/domain/entities/cart_warning.dart';

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
  final _checkoutCompletedController = StreamController<String>.broadcast();
  final _socketErrorController = StreamController<String>.broadcast();
  final _warningsController = StreamController<List<CartWarning>>.broadcast();

  // ─── Public Streams ────────────────────────────────────────────────

  /// Emits the full cart when first connected (initial state)
  Stream<List<CartItem>> get cartCurrent => _cartCurrentController.stream;

  /// Emits every real-time cart change from the AI vision system
  Stream<CartUpdate> get cartUpdates => _cartUpdateController.stream;

  /// Emits when this device's session has been replaced by another device
  Stream<String> get sessionReplaced => _sessionReplacedController.stream;

  /// Emits true when connected, false when disconnected
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Emits customerId when checkout is completed
  Stream<String> get checkoutCompleted => _checkoutCompletedController.stream;

  /// Emits error messages
  Stream<String> get socketError => _socketErrorController.stream;

  /// Emits health warnings from AI analysis of the cart
  Stream<List<CartWarning>> get healthWarnings => _warningsController.stream;

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

        // Parse and emit warnings if present
        if (map['warnings'] != null) {
          final warningsList = (map['warnings'] as List)
              .map((e) => CartWarning.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _warningsController.add(warningsList);
        }
      } catch (e) {
        // Error parsing cart:current — logged silently
      }
    });

    socket.on('cart:updated', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final update = CartUpdate.fromJson(map);
        _cartUpdateController.add(update);

        // Emit warnings carried in the update
        _warningsController.add(update.warnings);
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

    // ── Checkout event ───────────────────────────────────────────

    socket.on('checkout:completed', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final customerId = map['customerId'] as String? ?? '';
      _checkoutCompletedController.add(customerId);
    });

    // ── Error event ──────────────────────────────────────────────

    socket.on('error', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final message = map['message'] as String? ?? 'Socket Error';
      _socketErrorController.add(message);
    });
    
    socket.on('socket:error', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final message = map['message'] as String? ?? 'Socket Error';
      _socketErrorController.add(message);
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
    _checkoutCompletedController.close();
    _socketErrorController.close();
    _warningsController.close();
  }
}
