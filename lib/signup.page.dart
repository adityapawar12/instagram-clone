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
  final _nameController = TextEditingController();
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
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      log('Error initializing camera: $e');
    }

    // Update the Boolean
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
    // Do something with the file...
  }

  // SIGN UP
  void _signUpUser(BuildContext context) async {
    bool isFileReady = await _checkFile(_image);

    if (_formKey.currentState!.validate()) {
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
        final phone = _phoneController.text;
        final email = _emailController.text;
        final password = _passwordController.text;
        final obj = {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'profile_image': profileImageUrl
        };

        final newUser = await Supabase.instance.client
            .from('users')
            .insert(obj)
            .select("*");

        _clearPhoto();
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();

        if (newUser.isNotEmpty) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          await prefs.setInt('userId', newUser[0]['id']);
          await prefs.setString('userName', newUser[0]['name']);
          await prefs.setString('userEmail', newUser[0]['email']);
          await prefs.setString('userPhone', newUser[0]['phone']);
          await prefs.setString('profileImage', newUser[0]['profile_image']);
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
      }
    }
  }

  // CHECK USER LOGIN
  void _checkLogin(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int? userId = prefs.getInt('userId');

    if (userId != null) {
      final future = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>(
              '''id, name, email, phone, profile_image''').eq('id', userId);

      if (future.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setInt('userId', future[0]['id']);
        await prefs.setString('userName', future[0]['name']);
        await prefs.setString('userEmail', future[0]['email']);
        await prefs.setString('userPhone', future[0]['phone']);
        await prefs.setString('profileImage', future[0]['profile_image']);

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

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
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
                              controller: _phoneController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                hintText: 'Phone',
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
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Email',
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
