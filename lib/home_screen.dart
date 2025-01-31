import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'image_viewer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartItems(); // Загрузка корзины при инициализации
  }

  // Загружаем все товары с сервера
  Future<void> _loadProducts() async {
    try {
      final response =
          await Supabase.instance.client.from('products').select().execute();
      if (response.error == null && response.data != null) {
        setState(() {
          products = List<Map<String, dynamic>>.from(response.data);
          isLoading = false;
        });

        // Загрузка списка избранного после загрузки продуктов
        final wishListProvider =
            provider.Provider.of<WishlistProvider>(context, listen: false);
        await wishListProvider.loadWishlist();
      } else {
        throw Exception(
            'Ошибка загрузки продуктов: ${response.error?.message}');
      }
    } catch (e) {
      print('Ошибка загрузки продуктов: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Загрузка корзины для текущего пользователя
  Future<void> _loadCartItems() async {
    final cartProvider =
        provider.Provider.of<CartProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      await cartProvider.loadCartItems(userId); // Загружаем товары в корзине
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishListProvider =
        provider.Provider.of<WishlistProvider>(context, listen: true);
    final cartProvider =
        provider.Provider.of<CartProvider>(context, listen: false);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black54,
          title: const Text(
            'NyxNest',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text(
            'Пожалуйста, войдите в систему',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NyxNest',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/wishlist_screen');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart_screen');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile_screen');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isFavorite =
                    wishListProvider.isProductInWishlist(product['id']);
                return Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ImageViewer(imagePath: product['image']),
                              ),
                            );
                          },
                          child: Hero(
                            tag: product['image'],
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: AssetImage(product['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Цена: \$${product['price']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.favorite),
                                  color: isFavorite
                                      ? Colors.redAccent
                                      : Colors.white70,
                                  onPressed: () {
                                    if (isFavorite) {
                                      wishListProvider
                                          .removeFromWishlist(product['id']);
                                    } else {
                                      wishListProvider.addToWishlist(product);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final itemToAdd = {
                                        'id': product['id'],
                                        'name': product['name'],
                                        'price': product['price'],
                                        'image': product['image'],
                                        'quantity': 1,
                                      };
                                      await cartProvider.addItemToCart(
                                          itemToAdd, user.id);

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product['name']} добавлен в корзину'),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: const Text(
                                      'В корзину',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
