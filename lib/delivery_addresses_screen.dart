import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryAddressesScreen extends StatefulWidget {
  @override
  _DeliveryAddressesScreenState createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Загрузка адресов пользователя
  Future<List<Map<String, dynamic>>> _loadAddresses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('delivery_addresses')
          .select()
          .eq('user_id', user.id)
          .execute();

      if (response.error == null) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        return [];
      }
    }
    return [];
  }

  // Добавление нового адреса
  Future<void> _addAddress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response =
          await Supabase.instance.client.from('delivery_addresses').insert({
        'user_id': user.id,
        'address': _addressController.text,
        'city': _cityController.text,
        'postal_code': _postalCodeController.text,
      }).execute();

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Адрес добавлен')),
        );

        // Обновляем страницу
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryAddressesScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка добавления адреса: ${response.error?.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Адреса доставки',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black54,
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Добавьте новый адрес:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Адрес',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: 'Город',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                hintText: 'Почтовый индекс',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addAddress,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Добавить адрес'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ваши адреса:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadAddresses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Нет адресов доставки',
                      style: TextStyle(color: Colors.white70));
                } else {
                  final addresses = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return ListTile(
                        title: Text(address['address'],
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            '${address['city']}, ${address['postal_code']}',
                            style: const TextStyle(color: Colors.white70)),
                        tileColor: Colors.black45,
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
