import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:modern_go/core/api/api_client.dart';
import 'package:modern_go/features/cart/data/services/socket_service.dart';
import 'package:modern_go/features/cart/domain/entities/cart_item.dart';
import 'package:modern_go/features/cart/domain/entities/cart_update.dart';
import 'package:modern_go/features/cart/domain/entities/cart_warning.dart';

// ─── Cart Status ─────────────────────────────────────────────────────

enum CartStatus { disconnected, connecting, connected }

// ─── Events ──────────────────────────────────────────────────────────

abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initiate socket connection with JWT token
class CartConnectRequested extends CartEvent {
  final String serverUrl;
  final String jwtToken;
  CartConnectRequested({required this.serverUrl, required this.jwtToken});
  @override
  List<Object?> get props => [serverUrl, jwtToken];
}

/// Disconnect the socket
class CartDisconnectRequested extends CartEvent {}

/// Request checkout process and clear cart
class CartCheckoutRequested extends CartEvent {}

/// Reset checkout completed state
class CartCheckoutReset extends CartEvent {}

/// Internal: full cart received on connect
class _CartCurrentReceived extends CartEvent {
  final List<CartItem> items;
  _CartCurrentReceived(this.items);
  @override
  List<Object?> get props => [items];
}

/// Internal: real-time cart update from AI
class _CartUpdateReceived extends CartEvent {
  final CartUpdate update;
  _CartUpdateReceived(this.update);
  @override
  List<Object?> get props => [update];
}

/// Internal: connection state changed
class _ConnectionStateChanged extends CartEvent {
  final bool isConnected;
  _ConnectionStateChanged(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

/// Internal: session replaced by another device
class _SessionReplaced extends CartEvent {
  final String message;
  _SessionReplaced(this.message);
  @override
  List<Object?> get props => [message];
}

/// Internal: checkout completed
class _CheckoutCompleted extends CartEvent {
  final String customerId;
  _CheckoutCompleted(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

/// Internal: socket error received
class _SocketErrorReceived extends CartEvent {
  final String message;
  _SocketErrorReceived(this.message);
  @override
  List<Object?> get props => [message];
}

/// Internal: health warnings received from AI
class _HealthWarningsReceived extends CartEvent {
  final List<CartWarning> warnings;
  _HealthWarningsReceived(this.warnings);
  @override
  List<Object?> get props => [warnings];
}

// ─── State ───────────────────────────────────────────────────────────

class CartState extends Equatable {
  final List<CartItem> items;
  final List<CartWarning> warnings;
  final CartStatus status;
  final String? lastAction; // "pick" or "release"
  final String? sessionReplacedMessage;
  final bool checkoutCompleted;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.warnings = const [],
    this.status = CartStatus.disconnected,
    this.lastAction,
    this.sessionReplacedMessage,
    this.checkoutCompleted = false,
    this.errorMessage,
  });

  /// Total number of individual items (sum of quantities)
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Whether there are any health warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Whether there are any critical warnings
  bool get hasCriticalWarnings => warnings.any((w) => w.isCritical);

  CartState copyWith({
    List<CartItem>? items,
    List<CartWarning>? warnings,
    CartStatus? status,
    String? lastAction,
    String? sessionReplacedMessage,
    bool? checkoutCompleted,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      warnings: warnings ?? this.warnings,
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      sessionReplacedMessage:
          sessionReplacedMessage ?? this.sessionReplacedMessage,
      checkoutCompleted: checkoutCompleted ?? this.checkoutCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [items, warnings, status, lastAction, sessionReplacedMessage, checkoutCompleted, errorMessage];
}

// ─── Bloc ────────────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  final SocketService _socketService;
  final ApiClient _apiClient;
  StreamSubscription<List<CartItem>>? _cartCurrentSub;
  StreamSubscription<CartUpdate>? _cartUpdateSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<String>? _sessionSub;
  StreamSubscription<String>? _checkoutSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<List<CartWarning>>? _warningSub;

  CartBloc({required SocketService socketService, required ApiClient apiClient})
      : _socketService = socketService,
        _apiClient = apiClient,
        super(const CartState()) {
    on<CartConnectRequested>(_onConnectRequested);
    on<CartDisconnectRequested>(_onDisconnectRequested);
    on<CartCheckoutRequested>(_onCheckoutRequestedEvent);
    on<CartCheckoutReset>(_onCheckoutReset);
    on<_CartCurrentReceived>(_onCartCurrentReceived);
    on<_CartUpdateReceived>(_onCartUpdateReceived);
    on<_ConnectionStateChanged>(_onConnectionStateChanged);
    on<_SessionReplaced>(_onSessionReplaced);
    on<_CheckoutCompleted>(_onCheckoutCompleted);
    on<_SocketErrorReceived>(_onSocketErrorReceived);
    on<_HealthWarningsReceived>(_onHealthWarningsReceived);
  }

  void _onConnectRequested(
    CartConnectRequested event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(
      status: CartStatus.connecting,
      sessionReplacedMessage: null,
      checkoutCompleted: false,
    ));

    // Subscribe to socket streams
    _cartCurrentSub = _socketService.cartCurrent.listen((items) {
      add(_CartCurrentReceived(items));
    });

    _cartUpdateSub = _socketService.cartUpdates.listen((update) {
      add(_CartUpdateReceived(update));
    });

    _connectionSub = _socketService.connectionState.listen((connected) {
      add(_ConnectionStateChanged(connected));
    });

    _sessionSub = _socketService.sessionReplaced.listen((message) {
      add(_SessionReplaced(message));
    });

    _checkoutSub = _socketService.checkoutCompleted.listen((customerId) {
      add(_CheckoutCompleted(customerId));
    });

    _errorSub = _socketService.socketError.listen((message) {
      add(_SocketErrorReceived(message));
    });

    _warningSub = _socketService.healthWarnings.listen((warnings) {
      add(_HealthWarningsReceived(warnings));
    });

    // Initiate connection
    _socketService.connect(
      serverUrl: event.serverUrl,
      jwtToken: event.jwtToken,
    );

    // Fetch existing cart items via REST API (also returns warnings)
    _loadExistingCart();
  }

  Future<void> _loadExistingCart() async {
    try {
      final response = await _apiClient.get('/cart/me');
      final data = response.data['data'] as Map<String, dynamic>?;

      if (data != null) {
        // New structured response: { cart: [...], warnings: [...] }
        final cartJson = data['cart'] as List? ?? [];
        final items = cartJson
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final warningsJson = data['warnings'] as List? ?? [];
        final warnings = warningsJson
            .map((e) => CartWarning.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        add(_CartCurrentReceived(items));
        add(_HealthWarningsReceived(warnings));
      } else {
        // Fallback: old flat list response
        final cartJson = response.data['data'] as List? ?? [];
        final items = cartJson
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        add(_CartCurrentReceived(items));
      }
    } catch (e) {
      add(_SocketErrorReceived("Failed to fetch initial cart: $e"));
    }
  }

  Future<void> _onCheckoutRequestedEvent(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(checkoutCompleted: false));
    try {
      await _apiClient.post('/cart/checkout');
      emit(state.copyWith(
        checkoutCompleted: true,
        items: [],
        warnings: [],
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: "Checkout failed: $e"));
    }
  }

  void _onCheckoutReset(
    CartCheckoutReset event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(checkoutCompleted: false));
  }

  void _onDisconnectRequested(
    CartDisconnectRequested event,
    Emitter<CartState> emit,
  ) {
    _cancelSubscriptions();
    _socketService.disconnect();
    emit(const CartState());
  }

  void _onCartCurrentReceived(
    _CartCurrentReceived event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(items: event.items, status: CartStatus.connected));
  }

  void _onCartUpdateReceived(
    _CartUpdateReceived event,
    Emitter<CartState> emit,
  ) {
    // Replace entire cart with the server's full cart (recommended approach)
    emit(state.copyWith(
      items: event.update.cart,
      lastAction: event.update.action,
    ));
  }

  void _onConnectionStateChanged(
    _ConnectionStateChanged event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(
      status: event.isConnected ? CartStatus.connected : CartStatus.connecting,
    ));
  }

  void _onSessionReplaced(
    _SessionReplaced event,
    Emitter<CartState> emit,
  ) {
    _cancelSubscriptions();
    emit(CartState(
      status: CartStatus.disconnected,
      sessionReplacedMessage: event.message,
    ));
  }

  void _onCheckoutCompleted(
    _CheckoutCompleted event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(checkoutCompleted: true, items: [], warnings: []));
  }

  void _onSocketErrorReceived(
    _SocketErrorReceived event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.message));
  }

  void _onHealthWarningsReceived(
    _HealthWarningsReceived event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(warnings: event.warnings));
  }

  void _cancelSubscriptions() {
    _cartCurrentSub?.cancel();
    _cartUpdateSub?.cancel();
    _connectionSub?.cancel();
    _sessionSub?.cancel();
    _checkoutSub?.cancel();
    _errorSub?.cancel();
    _warningSub?.cancel();
    _cartCurrentSub = null;
    _cartUpdateSub = null;
    _connectionSub = null;
    _sessionSub = null;
    _checkoutSub = null;
    _errorSub = null;
    _warningSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}


