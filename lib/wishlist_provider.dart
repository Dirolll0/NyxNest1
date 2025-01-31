import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> _wishlistItems = [];

  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;

  // Проверка, есть ли продукт в списке желаемого
  bool isProductInWishlist(String productId) {
    return _wishlistItems.any((item) => item['id'] == productId);
  }

  // Загрузка данных из таблицы wishlist
  Future<void> loadWishlist() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('wishlist')
        .select('product_id, products(name, price, image)')
        .eq('user_id', userId)
        .execute();

    if (response.error == null && response.data != null) {
      _wishlistItems =
          List<Map<String, dynamic>>.from(response.data.map((item) {
        return {
          'id': item['product_id'],
          'name': item['products']['name'],
          'price': item['products']['price'],
          'image': item['products']['image'],
        };
      }));
      notifyListeners();
    } else {
      print('Ошибка загрузки списка желаемого: ${response.error?.message}');
    }
  }

  // Добавление продукта в список желаемого
  Future<void> addToWishlist(Map<String, dynamic> product) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client.from('wishlist').insert({
      'user_id': userId,
      'product_id': product['id'],
    }).execute();

    if (response.error == null) {
      _wishlistItems.add(product);
      notifyListeners();
    } else {
      print('Ошибка добавления в список желаемого: ${response.error?.message}');
    }
  }

  // Удаление продукта из списка желаемого
  Future<void> removeFromWishlist(String productId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .execute();

    if (response.error == null) {
      _wishlistItems.removeWhere((item) => item['id'] == productId);
      notifyListeners();
    } else {
      print('Ошибка удаления из списка желаемого: ${response.error?.message}');
    }
  }
}
