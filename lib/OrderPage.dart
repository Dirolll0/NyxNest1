import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_provider.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _commentController = TextEditingController();
  String? _selectedAddress;
  String? _selectedCard;
  String _selectedPaymentMethod = 'card';
  List<Map<String, dynamic>> _addresses = [];
  List<String> paymentMethods = ['card', 'cash'];
  List<Map<String, dynamic>> _userCards = [];
  List<Map<String, dynamic>> _userProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadUserProducts();
    _loadUserCards();
  }

  // Загрузка адресов пользователя
  Future<void> _loadAddresses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('delivery_addresses')
          .select()
          .eq('user_id', user.id)
          .execute();

      if (response.error == null) {
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка загрузки адресов: ${response.error?.message}')),
        );
      }
    }
  }

  // Загрузка товаров пользователя
  Future<void> _loadUserProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('user_products')
          .select()
          .eq('user_id', user.id)
          .execute();

      if (response.error == null) {
        setState(() {
          _userProducts = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка загрузки товаров: ${response.error?.message}')),
        );
      }
    }
  }

  // Загрузка карт пользователя
  Future<void> _loadUserCards() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('payment_methods')
          .select()
          .eq('user_id', user.id)
          .execute();

      if (response.error == null) {
        setState(() {
          _userCards = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка загрузки карт: ${response.error?.message}')),
        );
      }
    }
  }

  // Добавление нового заказа
  Future<void> _submitOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null &&
        _selectedAddress != null &&
        (_selectedPaymentMethod == 'cash' || _selectedCard != null)) {
      List<Map<String, dynamic>> orderItems = _userProducts.map((product) {
        return {
          'product_id': product['product_id'],
          'quantity': product['quantity'],
        };
      }).toList();

      final orderData = {
        'user_id': user.id,
        'address': _selectedAddress,
        'payment_method': _selectedPaymentMethod,
        'card_number': _selectedPaymentMethod == 'card' ? _selectedCard : null,
        'comment': _commentController.text,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'order_items': orderItems,
      };

      final response = await Supabase.instance.client
          .from('orders')
          .insert(orderData)
          .execute();

      if (response.error == null) {
        // Удаление всех товаров из корзины пользователя
        await Supabase.instance.client
            .from('user_products')
            .delete()
            .eq('user_id', user.id)
            .execute();

        // Очистка локальной корзины через провайдер
        final cartProvider = context.read<CartProvider>();
        cartProvider.clearCart();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ оформлен успешно')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка оформления заказа: ${response.error?.message}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пожалуйста, выберите адрес и способ оплаты')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Colors.black54,
      ),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Оформить заказ',
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.grey[850],
                  dropdownMenuTheme: DropdownMenuThemeData(
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: _selectedAddress,
                      hint: Text('Выберите адрес',
                          style: TextStyle(color: Colors.grey[300])),
                      style: TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[850],
                      underline: Container(
                        height: 1,
                        color: Colors.grey[400],
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAddress = newValue;
                        });
                      },
                      items: _addresses.map<DropdownMenuItem<String>>(
                          (Map<String, dynamic> address) {
                        return DropdownMenuItem<String>(
                          value: address['address'],
                          child: Text(address['address'],
                              style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Выберите способ оплаты:',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _selectedPaymentMethod,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPaymentMethod = newValue!;
                          _selectedCard =
                              null; // Сбрасываем выбранную карту при изменении метода оплаты
                        });
                      },
                      items: paymentMethods
                          .map<DropdownMenuItem<String>>((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method,
                              style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    if (_selectedPaymentMethod == 'card')
                      DropdownButton<String>(
                        value: _selectedCard,
                        hint: const Text('Выберите карту',
                            style: TextStyle(color: Colors.white)),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCard = newValue;
                          });
                        },
                        items: _userCards.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> card) {
                          return DropdownMenuItem<String>(
                            value: card['card_number'],
                            child: Text(card['card_number'],
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  labelStyle: TextStyle(color: Colors.grey[300]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 50),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Оформить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
