import 'package:flutter/material.dart';
import 'package:instagram_clone/signup.page.dart';
import 'package:instagram_clone/Container.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // FORM
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // LOGIN
  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final emailOrPhone = _emailOrPhoneController.text;
      final password = _passwordController.text;

      final checkEmailOrPhoneExists = await Supabase.instance.client
              .from('users')
              .select<List<Map<String, dynamic>>>('id')
              .eq('email', emailOrPhone)
          // .eq('phone', emailOrPhone)
          ;

      if (checkEmailOrPhoneExists.isEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Email/Phone does not exist.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final checkPasswordViability = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('password', password)
          .eq('email', emailOrPhone);

      if (checkEmailOrPhoneExists.isNotEmpty &&
          checkPasswordViability.isEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Wrong Password!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final future = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>(
              '''id, name, user_tag_id, bio, email, phone, profile_image_url''')
          .eq('email', emailOrPhone)
          .eq('password', password);

      if (future.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setInt('userId', future[0]['id']);
        await prefs.setString('userName', future[0]['name']);
        await prefs.setString('userTagId', future[0]['user_tag_id']);
        if (future[0]['bio'] != null && future[0]['bio'].length > 0) {
          await prefs.setString('bio', future[0]['bio']);
        }
        await prefs.setString('userEmail', future[0]['email']);
        await prefs.setString('userPhone', future[0]['phone']);
        if (future[0]['profile_image_url'] != null &&
            future[0]['profile_image_url'].length > 0) {
          await prefs.setString(
              'profileImageUrl', future[0]['profile_image_url']);
        }
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ContainerPage(
                    selectedPageIndex: 0,
                  )),
        );
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Something Went Wrong!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // CHECK USER LOGIN
  void _checkLogin(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int? userId = prefs.getInt('userId');

    if (userId != null) {
      final future = await Supabase.instance.client.from('users').select<
              List<Map<String, dynamic>>>(
          '''id, name, user_tag_id, bio, email, phone, profile_image_url''').eq('id', userId);

      if (future.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setInt('userId', future[0]['id']);
        await prefs.setString('userName', future[0]['name']);
        await prefs.setString('userTagId', future[0]['user_tag_id']);
        if (future[0]['bio'] != null && future[0]['bio'].length > 0) {
          await prefs.setString('bio', future[0]['bio']);
        }
        await prefs.setString('userEmail', future[0]['email']);
        await prefs.setString('userPhone', future[0]['phone']);
        if (future[0]['profile_image_url'] != null &&
            future[0]['profile_image_url'].length > 0) {
          await prefs.setString(
              'profileImageUrl', future[0]['profile_image_url']);
        }
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ContainerPage(
                    selectedPageIndex: 0,
                  )),
        );
      }
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const ContainerPage(
                  selectedPageIndex: 0,
                )),
      );
    }
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin(context);
    });
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              TextFormField(
                controller: _emailOrPhoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email/phone';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Email/Phone',
                  hintText: 'Email/Phone',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 5.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 5.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.black,
                    ),
                  ),
                  onPressed: () {
                    _login(context);
                  },
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(
                height: 5.0,
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
