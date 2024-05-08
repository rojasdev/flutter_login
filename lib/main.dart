import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    // Your API endpoint
    const String apiUrl = 'https://devlab.helioho.st/serve/validate.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        // Successful login
        final responseData = jsonDecode(response.body);
        final bool validation = responseData['validation'];

        // Store validation status in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('validation', validation);

        if (validation) {
          _navigateToHome();
        } else {
          setState(() {
            errorMessage = 'Cannot verify user.';
          });
        }
      } else {
        // Handle error
        setState(() {
          errorMessage = 'Invalid username or password';
        });
      }
    } catch (e) {
      // Handle network errors
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 10.0),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('validation');
    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? validation = prefs.getBool('validation');

  runApp(MaterialApp(
    title: 'Login App',
    initialRoute: validation == null || !validation ? '/' : '/home',
    routes: {
      '/': (context) => const LoginPage(),
      '/home': (context) => const HomePage(),
    },
  ));
}
