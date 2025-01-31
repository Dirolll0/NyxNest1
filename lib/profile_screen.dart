import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'delivery_addresses_screen.dart'; // Экран работы с адресами
import 'payment_methods_screen.dart'; // Экран работы с оплатой

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _availableAvatars = [];
  bool isLoading = true;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  bool _isUpdating = false;
  List<Map<String, dynamic>> _orders = []; // Заменяем _orderItems на _orders
  // ignore: unused_field
  String _currentProfilePhoto =
      'assets/avatar1.png'; // Добавляем переменную для текущего фото

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrderHistory();
    _loadAvatars();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single()
          .execute();

      if (response.error == null) {
        setState(() {
          _firstName = response.data['first_name'] ?? 'Неизвестно';
          _lastName = response.data['last_name'] ?? 'Неизвестно';
          _email = response.data['email'] ?? 'Неизвестно';
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _currentProfilePhoto =
              response.data['profile_image'] ?? 'assets/avatar1.png';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка загрузки данных пользователя: ${response.error?.message}')),
        );
      }
    }
  }

  Future<void> _loadOrderHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .execute();

      if (response.error == null) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка загрузки истории заказов: ${response.error?.message}')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final newPassword = _passwordController.text.trim();
      final newEmail = _emailController.text.trim();
      final newFirstName = _firstNameController.text.trim();
      final newLastName = _lastNameController.text.trim();

      final response = await Supabase.instance.client
          .from('users')
          .update({
            'first_name': newFirstName,
            'last_name': newLastName,
            'email': newEmail,
          })
          .eq('id', Supabase.instance.client.auth.currentUser?.id)
          .execute();

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка обновления профиля: ${response.error?.message}')),
        );
      }

      if (newPassword.isNotEmpty) {
        await Supabase.instance.client.auth
            .update(UserAttributes(password: newPassword));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успешно обновлен')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления данных: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // Добавляем функцию обновления фото
  Future<void> _updateProfilePhoto(String newPhoto) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .update({'profile_image': newPhoto})
          .eq('id', Supabase.instance.client.auth.currentUser?.id)
          .execute();

      if (response.error == null) {
        setState(() {
          _currentProfilePhoto = newPhoto;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото профиля обновлено')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка обновления фото: ${response.error?.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Выберите фото', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: _availableAvatars.length,
            itemBuilder: (context, index) {
              final avatar = _availableAvatars[index];
              return GestureDetector(
                onTap: () {
                  _updateProfilePhoto(avatar['image_path']);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border.all(
                      color: _currentProfilePhoto == avatar['image_path']
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      avatar['image_path'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                _currentProfilePhoto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _showAvatarPicker,
            child: const Text('Изменить фото',
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAvatars() async {
    try {
      final response =
          await Supabase.instance.client.from('avatars').select().execute();

      if (response.error == null) {
        setState(() {
          _availableAvatars = List<Map<String, dynamic>>.from(response.data);
          isLoading = false;
        });
      } else {
        throw Exception('Ошибка загрузки аватаров: ${response.error?.message}');
      }
    } catch (e) {
      print('Ошибка загрузки аватаров: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          },
          child: const Text(
            'NyxNest',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
          physics: const BouncingScrollPhysics(),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePhoto(),
                const SizedBox(height: 20),
                const Text('Приветствуем,',
                    style: TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 10),
                Text('$_firstName $_lastName',
                    style: const TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 30),
                const Text('Изменить профиль:',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                      hintText: 'Имя',
                      hintStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                      hintText: 'Фамилия',
                      hintStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      hintText: 'Пароль',
                      hintStyle: TextStyle(color: Colors.white70)),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                _isUpdating
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Обновить профиль'),
                        ),
                      ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DeliveryAddressesScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Управление адресами доставки'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PaymentMethodsScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Управление способами оплаты'),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('История заказов:',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    // Парсим order_items из JSONB
                    List<Map<String, dynamic>> orderItems = [];
                    try {
                      if (order['order_items'] != null) {
                        orderItems = List<Map<String, dynamic>>.from(
                            (order['order_items'] as List).map(
                                (item) => Map<String, dynamic>.from(item)));
                      }
                    } catch (e) {
                      print('Ошибка парсинга order_items: $e');
                    }

                    return Card(
                      color: Colors.black54,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ExpansionTile(
                        title: Text(
                          'Заказ',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Статус: Собираем • ${DateTime.parse(order['created_at']).toString().split('.')[0]}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        children: [
                          Container(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: orderItems.length,
                              itemBuilder: (context, itemIndex) {
                                final orderItem = orderItems[itemIndex];
                                return FutureBuilder(
                                  future: Supabase.instance.client
                                      .from('products')
                                      .select()
                                      .eq('id', orderItem['product_id'])
                                      .single()
                                      .execute(),
                                  builder: (context,
                                      AsyncSnapshot<PostgrestResponse>
                                          snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data?.data != null) {
                                      final product = snapshot.data!.data;
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      product['image']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'x${orderItem['quantity']}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Комментарий: ${order['comment'] ?? 'Нет комментария'}',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
