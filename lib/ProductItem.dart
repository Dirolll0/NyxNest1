import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'cart_provider.dart';
import 'wishlist_provider.dart';

class ProductItem extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final wishListProvider = provider.Provider.of<WishlistProvider>(context);
    final cartProvider =
        provider.Provider.of<CartProvider>(context, listen: false);

    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Expanded(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite),
                      color: wishListProvider.wishlistItems
                              .any((item) => item['id'] == product['id'])
                          ? Colors.redAccent
                          : Colors.white70,
                      onPressed: () {
                        if (wishListProvider.wishlistItems
                            .any((item) => item['id'] == product['id'])) {
                          wishListProvider.removeFromWishlist(product['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product['name']} удалён из желаемого',
                              ),
                            ),
                          );
                        } else {
                          wishListProvider.addToWishlist(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product['name']} добавлен в желаемое',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          cartProvider.addItemToCart(
                            {
                              'id': product['id'],
                              'name': product['name'],
                              'price': product['price'],
                              'image': product['image'],
                              'quantity': 1,
                            },
                            product['id'], // Второй обязательный аргумент
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${product['name']} добавлен в корзину')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'В корзину',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
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
  }
}
