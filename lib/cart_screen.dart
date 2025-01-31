import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'home_screen.dart';
import 'OrderPage.dart';
import 'image_viewer.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    final cartProvider =
        provider.Provider.of<CartProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    cartProvider.loadCartItems(userId);
    cartProvider.loadAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = provider.Provider.of<CartProvider>(context);
    final wishListProvider = provider.Provider.of<WishlistProvider>(context);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          child: const Text(
            'NyxNest - Корзина',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.black54,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            provider.Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                if (cartProvider.cartItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Ваша корзина пуста',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    final String productName =
                        item['product_name'] ?? 'Неизвестный товар';
                    final double productPrice = item['price'] ?? 0.0;
                    final int productQuantity = item['quantity'] ?? 1;
                    final String productImage =
                        item['image'] ?? 'assets/default_image.png';

                    return Card(
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ImageViewer(imagePath: productImage),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'cart_image_${item['product_id']}',
                            child: Image.asset(
                              productImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          productName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Цена: \$${productPrice.toStringAsFixed(2)} × $productQuantity',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                cartProvider.decrementItemQuantity(
                                    item, userId);
                                setState(() {}); // Обновляем UI
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Количество товара уменьшено!'),
                                  ),
                                );
                              },
                            ),
                            Text(
                              productQuantity.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () async {
                                final itemToAdd = {
                                  'id': item['product_id'],
                                  'name': item['product_name'],
                                  'price': item['price'],
                                  'image': item['image'],
                                  'quantity': 1,
                                };
                                await cartProvider.addItemToCart(
                                    itemToAdd, userId);
                                setState(() {}); // Обновляем UI
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${item['product_name']} добавлен в корзину!'),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (cartProvider.allProducts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Text(
                  'Популярные товары',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cartProvider.allProducts.length,
                  itemBuilder: (context, index) {
                    final product = cartProvider.allProducts[index];

                    return SizedBox(
                      width: 200,
                      child: Card(
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageViewer(
                                          imagePath: product['image']),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'popular_image_${product['id']}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(product['image']),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Цена: \$${product['price']}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite),
                                  color: wishListProvider
                                          .isProductInWishlist(product['id'])
                                      ? Colors.red
                                      : Colors.white70,
                                  onPressed: () {
                                    if (wishListProvider
                                        .isProductInWishlist(product['id'])) {
                                      wishListProvider
                                          .removeFromWishlist(product['id']);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product['name']} удалён из желаемого!'),
                                        ),
                                      );
                                    } else {
                                      wishListProvider.addToWishlist(product);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product['name']} добавлен в желаемое!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final itemToAdd = {
                                      'id': product['id'],
                                      'name': product['name'],
                                      'price': product['price'] ?? 0.0,
                                      'image': product['image'] ??
                                          'assets/default_image.png',
                                      'quantity': 1,
                                    };
                                    await cartProvider.addItemToCart(
                                        itemToAdd, userId);
                                    // Принудительное обновление экрана
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CartScreen()),
                                    );
                                    setState(() {}); // Обновляем UI
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${product['name']} добавлен в корзину!'),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'В корзину',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Итого: \$${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cartProvider.cartItems.isEmpty
                          ? Colors.grey
                          : Colors.green,
                    ),
                    onPressed: cartProvider.cartItems.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderPage(),
                              ),
                            );
                          },
                    child: Text(
                      cartProvider.cartItems.isEmpty
                          ? 'Корзина пуста'
                          : 'Оформить заказ',
                      style: TextStyle(
                        color: cartProvider.cartItems.isEmpty
                            ? Colors.grey[400]
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
