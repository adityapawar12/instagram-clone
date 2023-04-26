import 'dart:io';
import '../main.dart';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_supa/login.page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_supa/container.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // FORM
  final _formKey = GlobalKey<FormState>();

  // FORM CONTROLS
  final _nameController = TextEditingController();
  final _userTagIdController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // CAMERA
  CameraController? controller;
  bool _isCameraInitialized = false;

  // RESOLUTION
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.low;

  // PROFILE IMAGE
  bool _imageSelected = false;
  bool _imageCaptured = false;
  bool _imageCaptureButtonClicked = false;
  late File _image = File('');

  // OTHER
  bool _isUploading = false;

  // ON CAMERA SELECTED
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // INSTANTIATING THE CAMERA CONTROLLER
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // DISPOSE THE PREVIOUS CONTROLLER
    await previousCameraController?.dispose();

    // REPLACE WITH THE NEW CONTROLLER
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // UPDATE UI IF CONTROLLER UPDATED
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // INITIALIZE CONTROLLER
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      log('Error initializing camera: $e');
    }

    // UPDATE THE BOOLEAN
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  // IMAGE PICKER
  Future<void> _selectImage() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    setState(() {
      _image = File(image.path);
      _imageSelected = true;
      _imageCaptured = false;
      _imageCaptureButtonClicked = false;
    });
  }

  //  TAKE PICTURE
  Future<void> _takePhoto() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      return;
    }
    try {
      final XFile image = await cameraController.takePicture();
      setState(() {
        _image = File(image.path);
        _imageSelected = false;
        _imageCaptured = true;
        _imageCaptureButtonClicked = false;
      });
    } on CameraException {
      return;
    }
  }

  // OPEN CAMERA
  _openCamera() {
    setState(() {
      _imageCaptureButtonClicked = true;
    });
  }

  // CLEAR PHOTO
  void _clearPhoto() {
    setState(() {
      _image = File('');
      _imageSelected = false;
      _imageCaptured = false;
      _imageCaptureButtonClicked = false;
    });
  }

  // CHECK FILE
  Future<bool> _checkFile(File file) async {
    final bool exists = await file.exists();
    if (!exists) {
      return false;
    }
    final int size = await file.length();
    if (size == 0) {
      return false;
    }
    return true;
  }

  // SIGN UP
  void _signUpUser(BuildContext context) async {
    bool isFileReady = await _checkFile(_image);

    if (_formKey.currentState!.validate()) {
      final userTagNameExists = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('user_tag_id', _userTagIdController.text);

      if (userTagNameExists.isNotEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Tag Name Already Exists!'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        return;
      }

      final emailExists = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('email', _emailController.text);

      if (emailExists.isNotEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Email Address Already Used By Someone Else!'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        return;
      }

      final phoneExists = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('phone', _phoneController.text);

      if (phoneExists.isNotEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Phone Number Already Used By Someone Else!'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        return;
      }

      if (isFileReady) {
        setState(() {
          _isUploading = true;
        });
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('user')
            .upload('profile-image/$fileName', _image);

        final dynamic profileImageUrl = Supabase.instance.client.storage
            .from('user')
            .getPublicUrl('profile-image/$fileName');

        final name = _nameController.text;
        final userTagId = _userTagIdController.text;
        final bio = _bioController.text;
        final phone = _phoneController.text;
        final email = _emailController.text;
        final password = _passwordController.text;
        final obj = {
          'name': name,
          'user_tag_id': userTagId,
          'bio': bio,
          'email': email,
          'phone': phone,
          'password': password,
          'profile_image_url': profileImageUrl
        };

        final newUser = await Supabase.instance.client
            .from('users')
            .insert(obj)
            .select("*");

        _clearPhoto();
        _nameController.clear();
        _userTagIdController.clear();
        _bioController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();

        if (newUser.isNotEmpty) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          await prefs.setInt('userId', newUser[0]['id']);
          await prefs.setString('userName', newUser[0]['name']);
          await prefs.setString('userTagId', newUser[0]['user_tag_id']);
          if (newUser[0]['bio'] != null && newUser[0]['bio'].length > 0) {
            await prefs.setString('bio', newUser[0]['bio']);
          }
          await prefs.setString('userEmail', newUser[0]['email']);
          await prefs.setString('userPhone', newUser[0]['phone']);
          if (newUser[0]['profile_image_url'] != null &&
              newUser[0]['profile_image_url'].length > 0) {
            await prefs.setString(
                'profileImageUrl', newUser[0]['profile_image_url']);
          }
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContainerPage()),
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

        setState(() {
          _isUploading = false;
        });
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Select Profile Image!'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final name = _nameController.text;
                  final userTagId = _userTagIdController.text;
                  final bio = _bioController.text;
                  final phone = _phoneController.text;
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  final obj = {
                    'name': name,
                    'user_tag_id': userTagId,
                    'bio': bio,
                    'email': email,
                    'phone': phone,
                    'password': password,
                  };

                  final newUser = await Supabase.instance.client
                      .from('users')
                      .insert(obj)
                      .select("*");

                  _clearPhoto();
                  _nameController.clear();
                  _userTagIdController.clear();
                  _bioController.clear();
                  _phoneController.clear();
                  _emailController.clear();
                  _passwordController.clear();

                  if (newUser.isNotEmpty) {
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                    await prefs.setInt('userId', newUser[0]['id']);
                    await prefs.setString('userName', newUser[0]['name']);
                    await prefs.setString(
                        'userTagId', newUser[0]['user_tag_id']);
                    if (newUser[0]['bio'] != null &&
                        newUser[0]['bio'].length > 0) {
                      await prefs.setString('bio', newUser[0]['bio']);
                    }
                    await prefs.setString('userEmail', newUser[0]['email']);
                    await prefs.setString('userPhone', newUser[0]['phone']);
                    if (newUser[0]['profile_image_url'] != null &&
                        newUser[0]['profile_image_url'].length > 0) {
                      await prefs.setString(
                          'profileImageUrl', newUser[0]['profile_image_url']);
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContainerPage()),
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

                  setState(() {
                    _isUploading = false;
                  });
                },
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Select Profile Image'),
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
          MaterialPageRoute(builder: (_) => const ContainerPage()),
        );
      }
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ContainerPage()),
      );
    }
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    onNewCameraSelected(cameras[1]);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin(context);
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // APP STATE CHANGED BEFORE WE GOT THE CHANCE TO INITIALIZE.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // FREE UP MEMORY WHEN CAMERA NOT ACTIVE
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // REINITIALIZE THE CAMERA WITH THE SAME PROPERTIES
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? !_isUploading
              ? SingleChildScrollView(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 16.0,
                            ),
                            Stack(
                              children: [
                                !_imageSelected && !_imageCaptured
                                    ? ClipOval(
                                        child: Container(
                                          height: 150,
                                          width: 150,
                                          color: const Color.fromARGB(
                                              255, 204, 204, 204),
                                          child: const SizedBox(
                                            child: Icon(
                                              Icons.person,
                                              size: 140,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: 0, height: 0),
                                _imageCaptureButtonClicked
                                    ? ClipOval(
                                        child: SizedBox(
                                          width: 150,
                                          height: 150,
                                          child: AspectRatio(
                                            aspectRatio:
                                                controller!.value.aspectRatio,
                                            child: controller!.buildPreview(),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: 0, height: 0),
                                _imageSelected || _imageCaptured
                                    ? ClipOval(
                                        child: SizedBox(
                                          width: 150,
                                          height: 150,
                                          child: AspectRatio(
                                            aspectRatio:
                                                controller!.value.aspectRatio,
                                            child: Image.file(
                                              _image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: 0, height: 0),
                                !(_imageSelected || _imageCaptured)
                                    ? Positioned(
                                        bottom: 4,
                                        right: 0,
                                        child: ClipOval(
                                          child: Container(
                                            color: Colors.black,
                                            height: 40,
                                            width: 40,
                                            child: IconButton(
                                              icon:
                                                  const Icon(Icons.add_a_photo),
                                              onPressed: _selectImage,
                                              color: const Color.fromARGB(
                                                  255, 204, 204, 204),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(
                                        height: 0,
                                        width: 0,
                                      ),
                                _imageSelected || _imageCaptured
                                    ? Positioned(
                                        bottom: 4,
                                        right: 0,
                                        child: ClipOval(
                                          child: Container(
                                            color: Colors.black,
                                            height: 40,
                                            width: 40,
                                            child: IconButton(
                                              icon: const Icon(Icons.cancel),
                                              onPressed: _clearPhoto,
                                              color: const Color.fromARGB(
                                                  255, 204, 204, 204),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(
                                        height: 0,
                                        width: 0,
                                      ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.black,
                                  height: 40,
                                  width: 40,
                                  child: SizedBox(
                                    child: IconButton(
                                      onPressed:
                                          _imageCaptureButtonClicked == false
                                              ? _openCamera
                                              : _takePhoto,
                                      icon: Icon(
                                        _imageCaptureButtonClicked == false
                                            ? Icons.camera_alt
                                            : Icons.camera,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 16.0,
                            ),
                            TextFormField(
                              controller: _nameController,
                              onChanged: (value) {
                                var userTagName = value
                                    .toLowerCase()
                                    .replaceAll(' ', '')
                                    .replaceAll('@', '');

                                _userTagIdController.text = userTagName;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                hintText: 'Name',
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
                              controller: _userTagIdController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your tag name';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Tag Name',
                                hintText: 'Tag Name',
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
                              controller: _bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                hintText: 'Bio',
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
                              controller: _phoneController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                final phoneRegex = RegExp(r'^\+?[0-9]{10,12}$');
                                if (!phoneRegex.hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Phone Number',
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
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Email Address',
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
                                  return 'Please enter a password';
                                }
                                final passwordRegex = RegExp(
                                    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');

                                // Evaluate password strength
                                int strengthScore = 0;
                                if (passwordRegex.hasMatch(value)) {
                                  strengthScore++;
                                }
                                if (value.length >= 10) {
                                  strengthScore++;
                                }
                                if (RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                    .hasMatch(value)) {
                                  strengthScore++;
                                }

                                // if (!passwordRegex.hasMatch(value)) {
                                //   return 'Password must be at least 8 characters long, and contain at least one uppercase letter, one lowercase letter, and one digit.';
                                // }

                                String strength;
                                switch (strengthScore) {
                                  case 1:
                                    strength = 'Weak';
                                    return '''Weak Password!
Password must be at least 8 characters long, and contain at least one uppercase letter, 
one lowercase letter, and one digit.''';
                                  case 2:
                                    strength = 'Moderate';
                                    return '''Moderate Password!
Password must be at least 8 characters long, and contain at least one uppercase letter,
one lowercase letter, and one digit.''';
                                  case 3:
                                    strength = 'Strong';
                                    return null;
                                  default:
                                    strength = 'Very Weak';
                                    return '''Very Weak Password!
Password must be at least 8 characters long, and contain at least one uppercase letter,
one lowercase letter, and one digit.''';
                                }

                                // print('Password Strength: $strength');

                                // return null;
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
                              child: ElevatedButton(
                                onPressed: () {
                                  _signUpUser(context);
                                },
                                child: const Text('SIGN UP'),
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
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                )
          : Container(),
    );
  }
}
