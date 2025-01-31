import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  String _paymentType = 'card'; // По умолчанию выбран тип "карта"
  List<String> paymentTypes = ['card', 'cash']; // Доступные способы оплаты

  // Загрузка способов оплаты пользователя
  Future<List<Map<String, dynamic>>> _loadPaymentMethods() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('payment_methods')
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

  // Добавление способа оплаты
  Future<void> _addPaymentMethod() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response =
          await Supabase.instance.client.from('payment_methods').insert({
        'user_id': user.id,
        'payment_type': _paymentType,
        'card_number':
            _paymentType == 'card' ? _cardNumberController.text.trim() : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).execute();

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Способ оплаты добавлен')),
        );
        _cardNumberController.clear();

        // Обновляем страницу
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodsScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка добавления способа оплаты: ${response.error?.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Способы оплаты', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black54,
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Добавьте новый способ оплаты:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            // Dropdown для выбора типа оплаты
            DropdownButton<String>(
              value: _paymentType,
              onChanged: (String? newValue) {
                setState(() {
                  _paymentType = newValue!;
                });
              },
              items: paymentTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'card' ? 'Карта' : 'Наличные',
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              dropdownColor: Colors.black54,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            // Если выбрана карта, отображаем поле для номера карты
            if (_paymentType == 'card')
              TextField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  hintText: 'Номер карты',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black54,
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addPaymentMethod,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Добавить способ оплаты'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ваши способы оплаты:',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadPaymentMethods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Нет способов оплаты',
                      style: TextStyle(color: Colors.white70));
                } else {
                  final paymentMethods = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final paymentMethod = paymentMethods[index];
                      return ListTile(
                        title: Text(
                          '${paymentMethod['payment_type'] == 'card' ? 'Карта' : 'Наличные'} - ${paymentMethod['card_number'] ?? 'Без карты'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Создано: ${paymentMethod['created_at']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
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
