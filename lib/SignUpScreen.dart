import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'signinscreen.dart'; // Импорт экрана входа

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Контроллер для повторного пароля
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Future<void> _signUp() async {
    // Проверка совпадения паролей
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пароли не совпадают. Попробуйте ещё раз.')),
      );
      return;
    }

    try {
      // Регистрация пользователя
      final response = await Supabase.instance.client.auth.signUp(
          _emailController.text, // email передается как позиционный аргумент
          _passwordController
              .text // password передается как позиционный аргумент
          );

      // Проверка успешной регистрации
      if (response.error == null && response.user != null) {
        // Если пользователь успешно зарегистрирован, добавим его в таблицу users
        await Supabase.instance.client.from('users').insert({
          'id': response.user!.id, // Добавляем user ID, полученный из Supabase
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'created_at': DateTime.now().toIso8601String(), // Текущая дата
        }).execute(); // Используем .execute() для выполнения операции

        // Перенаправление на главный экран
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ошибка регистрации. Попробуйте ещё раз.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: Colors.black54,
      ),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontFamily: 'BebasNeue',
                ),
              ),
              const SizedBox(height: 30),
              _buildInputBox('Имя', _firstNameController),
              _buildInputBox('Фамилия', _lastNameController),
              _buildInputBox('Email', _emailController),
              _buildInputBox('Пароль', _passwordController, obscureText: true),
              _buildInputBox('Повторите пароль', _confirmPasswordController,
                  obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text(
                  'Зарегистрироваться',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SignInScreen()), // Экран входа
                  );
                },
                child: const Text(
                  'Уже есть аккаунт?',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(String hint, TextEditingController controller,
      {bool obscureText = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}
