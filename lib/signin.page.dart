import 'package:flutter/material.dart';
import 'package:instagram_clone/signup.page.dart';
import 'package:instagram_clone/Container.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // SECURE STORAGE TO SAVE CREDENTIALS
  final _storage = const FlutterSecureStorage();

  // FORM
  final _formKey = GlobalKey<FormState>();

  // FORM FIELDS
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // SIGN IN STATE
  bool _isSignningIn = false;

  // SIGN IN STATE
  bool _isUserSignedIn = false;

  // REMEMBER ME
  bool _isRememberMeChecked = false;

  // SIGN IN
  void _signIn(BuildContext context) async {
    setState(() {
      _isSignningIn = true;
    });
    if (_formKey.currentState!.validate()) {
      final emailOrPhone = _emailOrPhoneController.text;
      final password = _passwordController.text;

      final checkEmailOrPhoneExists = await Supabase.instance.client
              .from('users')
              .select<List<Map<String, dynamic>>>('id')
              .eq('email', emailOrPhone)
          // .eq('phone', emailOrPhone)
          ;

      // EMAIL OR PHONE EXISTS OR NOT
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
        setState(() {
          _isSignningIn = false;
        });
        return;
      }

      final checkPasswordViability = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('password', password)
          .eq('email', emailOrPhone);

      // PASSWORD IS WRONG OR NOT
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
        setState(() {
          _isSignningIn = false;
        });
        return;
      }

      final future = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>(
              '''id, name, user_tag_id, bio, email, phone, profile_image_url''')
          .eq('email', emailOrPhone)
          .eq('password', password);

      if (future.isNotEmpty) {
        // SAVE TO LOCAL STORAGE AND NAVIGATE
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

        if (_isRememberMeChecked) {
          await _storage.delete(key: 'userName');
          await _storage.delete(key: 'password');
          await _storage.write(key: 'userName', value: emailOrPhone);
          await _storage.write(key: 'password', value: password);
        }

        setState(() {
          _isSignningIn = false;
        });
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ContainerPage(
                    selectedPageIndex: 0,
                  )),
        );
      } else {
        // SOME ERROR
        setState(() {
          _isSignningIn = false;
        });
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
      setState(() {
        _isSignningIn = false;
      });
    }
    setState(() {
      _isSignningIn = false;
    });
  }

  // CHECK USER SIGNED IN OR NOT
  void _checkUserSignedIn(BuildContext context) async {
    setState(() {
      _isUserSignedIn = true;
    });
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
    } else {
      setState(() {
        _isUserSignedIn = false;
      });
    }
  }

  // GET STORED CREDENTAILS FROM SECURE STORAGE
  Future<void> _getRememberedCredentials() async {
    _emailOrPhoneController.text = await _storage.read(key: 'userName') ?? "";
    _passwordController.text = await _storage.read(key: 'password') ?? "";

    if (_emailOrPhoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      _isRememberMeChecked = true;
    }
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _getRememberedCredentials();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserSignedIn(context);
    });
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isUserSignedIn == false
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sign In',
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
                      decoration: InputDecoration(
                        hintText: 'Email/Phone',
                        filled: true,
                        fillColor:
                            Colors.grey[200], // Use the desired grey color
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(
                              45.0), // Adjust the border radius as needed
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(
                              45.0), // Adjust the border radius as needed
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              45.0), // Same border radius for both states
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              45.0), // Same border radius for both states
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                      cursorColor:
                          Colors.black, // Set the cursor color to black
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
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor:
                            Colors.grey[200], // Use the desired grey color
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(
                              45.0), // Adjust the border radius as needed
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(
                              45.0), // Adjust the border radius as needed
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              45.0), // Same border radius for both states
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              45.0), // Same border radius for both states
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                      cursorColor:
                          Colors.black, // Set the cursor color to black
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                            child: const Text('Remember Me')),
                        Expanded(
                          child: Container(),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10.0, 0),
                          height: 20,
                          child: Checkbox(
                            checkColor: Colors.white,
                            value: _isRememberMeChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isRememberMeChecked = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(45.0),
                            ),
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.black,
                          ),
                        ),
                        onPressed: !_isSignningIn
                            ? () {
                                _signIn(context);
                              }
                            : null,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    const Text("Don't Have an account?"),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpPage()),
                          );
                        },
                        style: ButtonStyle(
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.transparent),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.all_inclusive_sharp,
                size: 50.0,
              ),
            ),
    );
  }
}
