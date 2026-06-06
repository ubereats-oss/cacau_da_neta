import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';

class CartState {
  const CartState({this.items = const []});
  final List<CartItemModel> items;
  int get totalItems => items.fold(0, (acc, item) => acc + item.quantity);
  double get totalPrice => items.fold(0.0, (acc, item) => acc + item.subtotal);
  bool containsProduct(String productId) =>
      items.any((item) => item.product.id == productId);
  int quantityOf(String productId) {
    final index = items.indexWhere((i) => i.product.id == productId);
    return index >= 0 ? items[index].quantity : 0;
  }

  CartState copyWith({List<CartItemModel>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());
  void add(ProductModel product) {
    final index = state.items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final updated = List<CartItemModel>.from(state.items);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItemModel(product: product, quantity: 1),
        ],
      );
    }
  }

  void remove(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void increment(String productId) {
    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void decrement(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    if (state.items[index].quantity <= 1) {
      remove(productId);
      return;
    }
    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: item.quantity - 1);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
