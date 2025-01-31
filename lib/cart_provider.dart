import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  double _totalPrice = 0.0;
  List<Map<String, dynamic>> _allProducts = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;
  double get totalPrice => _totalPrice;
  List<Map<String, dynamic>> get allProducts => _allProducts;

  // Загрузка товаров корзины для конкретного пользователя
  Future<void> loadCartItems(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_products')
          .select()
          .eq('user_id', userId)
          .execute();

      if (response.error == null && response.data != null) {
        final data = List<Map<String, dynamic>>.from(response.data);

        _cartItems = data;
        _calculateTotalPrice();
        notifyListeners();
      } else {
        throw Exception('Ошибка загрузки корзины: ${response.error?.message}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  // Загрузка всех доступных товаров для отображения в качестве рекомендаций
  Future<void> loadAllProducts() async {
    try {
      final response =
          await Supabase.instance.client.from('products').select().execute();

      if (response.error == null && response.data != null) {
        _allProducts = List<Map<String, dynamic>>.from(response.data);
        notifyListeners();
      } else {
        throw Exception('Ошибка загрузки товаров: ${response.error?.message}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

// Увеличение количества товара в корзине
  Future<void> addItemToCart(Map<String, dynamic> item, String userId) async {
    try {
      final existingItemIndex = _cartItems.indexWhere(
        (cartItem) =>
            cartItem['product_id'] == item['id'], // Проверка по id товара
      );

      if (existingItemIndex != -1) {
        // Если товар уже есть, обновляем количество
        _cartItems[existingItemIndex]['quantity'] += 1;
        await Supabase.instance.client
            .from('user_products')
            .update({'quantity': _cartItems[existingItemIndex]['quantity']})
            .eq('user_id', userId)
            .eq('product_id', item['id'])
            .execute();
      } else {
        // Если товара нет в корзине, добавляем новый
        _cartItems.add(item);
        await Supabase.instance.client.from('user_products').insert({
          'user_id': userId,
          'product_id': item['id'],
          'product_name': item['name'],
          'price': item['price'],
          'image': item['image'],
          'quantity': item['quantity'],
        }).execute();
      }

      _calculateTotalPrice();
      notifyListeners();
    } catch (e) {
      print('Ошибка добавления в корзину: $e');
    }
  }

  // Уменьшение количества товара
  Future<void> decrementItemQuantity(
      Map<String, dynamic> item, String userId) async {
    final existingItemIndex = _cartItems.indexWhere(
      (cartItem) => cartItem['image'] == item['image'],
    );

    if (existingItemIndex != -1) {
      if (_cartItems[existingItemIndex]['quantity'] > 1) {
        _cartItems[existingItemIndex]['quantity']--;

        await Supabase.instance.client
            .from('user_products')
            .update({'quantity': _cartItems[existingItemIndex]['quantity']})
            .eq('user_id', userId)
            .eq('image', item['image'])
            .execute();
      } else {
        await removeItem(item, userId);
      }

      _calculateTotalPrice();
      notifyListeners();
    }
  }

  // Удаление товара из корзины и базы данных
  Future<void> removeItem(Map<String, dynamic> item, String userId) async {
    final existingItemIndex = _cartItems.indexWhere(
      (cartItem) => cartItem['image'] == item['image'],
    );

    if (existingItemIndex != -1) {
      _totalPrice -= _cartItems[existingItemIndex]['price'] *
          _cartItems[existingItemIndex]['quantity'];

      _cartItems.removeAt(existingItemIndex);

      await Supabase.instance.client
          .from('user_products')
          .delete()
          .eq('user_id', userId)
          .eq('image', item['image'])
          .execute();

      _calculateTotalPrice();
      notifyListeners();
    }
  }

  // Пересчет общей стоимости корзины
  void _calculateTotalPrice() {
    _totalPrice = 0.0;
    for (var item in _cartItems) {
      _totalPrice += (item['price'] ?? 0.0) * (item['quantity'] ?? 0);
    }
  }

  // Функция оформления заказа с добавлением комментария
  Future<bool> proceedToCheckout(String userId, String deliveryOption,
      String paymentOption, String orderComment) async {
    try {
      // Создаем запись в таблице заказов
      final response = await Supabase.instance.client.from('orders').insert({
        'user_id': userId,
        'total_price': _totalPrice,
        'delivery_option': deliveryOption,
        'payment_option': paymentOption,
        'comment': orderComment,
        'items': _cartItems,
      }).execute();

      if (response.error == null) {
        // Очистка данных корзины в локальном состоянии
        _cartItems.clear();
        _totalPrice = 0.0;
        notifyListeners();

        // Удаляем товары пользователя из таблицы user_products
        final deleteResponse = await Supabase.instance.client
            .from('user_products')
            .delete()
            .eq('user_id', userId)
            .execute();

        if (deleteResponse.error != null) {
          print(
              'Ошибка при удалении товаров из корзины: ${deleteResponse.error?.message}');
          return false;
        }

        return true;
      } else {
        throw Exception('Ошибка оформления заказа: ${response.error?.message}');
      }
    } catch (e) {
      print('Ошибка: $e');
      return false;
    }
  }

  void clearCart() {
    _cartItems.clear();
    _totalPrice = 0;
    notifyListeners();
  }
}
