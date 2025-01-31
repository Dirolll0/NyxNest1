import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'wishlist_provider.dart';
import 'cart_provider.dart'; // Добавлено подключение cart_provider
import 'package:supabase_flutter/supabase_flutter.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({Key? key}) : super(key: key);

  @override
  _WishListScreenState createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  @override
  void initState() {
    super.initState();
    final wishlistProvider =
        provider.Provider.of<WishlistProvider>(context, listen: false);
    wishlistProvider.loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = provider.Provider.of<WishlistProvider>(context);
    final cartProvider = provider.Provider.of<CartProvider>(context,
        listen: false); // Подключение cartProvider

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text(
          'NyxNest - Список желаемого',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: wishlistProvider.wishlistItems.isEmpty
          ? const Center(
              child: Text(
                'Ваш список желаемого пуст',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: wishlistProvider.wishlistItems.length,
              itemBuilder: (context, index) {
                final product = wishlistProvider.wishlistItems[index];

                return Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    children: [
                                      InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.asset(
                                          product['image'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
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
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    await wishlistProvider
                                        .removeFromWishlist(product['id']);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${product['name']} удалён из желаемого'),
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final userId = Supabase
                                          .instance.client.auth.currentUser?.id;

                                      if (userId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Ошибка: Пользователь не авторизован'),
                                          ),
                                        );
                                        return;
                                      }

                                      final itemToAdd = {
                                        'id': product['id'],
                                        'name': product['name'],
                                        'price': product['price'],
                                        'image': product['image'],
                                        'quantity': 1,
                                      };

                                      await cartProvider.addItemToCart(
                                          itemToAdd, userId);

                                      wishlistProvider
                                          .removeFromWishlist(product['id']);
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
