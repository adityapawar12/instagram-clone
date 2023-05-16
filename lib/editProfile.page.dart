import 'dart:io';
import '../main.dart';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/container.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // FORM
  final _formKey = GlobalKey<FormState>();

  // FORM FIELDS
  final _nameController = TextEditingController();
  final _userTagIdController = TextEditingController();
  final _bioController = TextEditingController();

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
  String _imageUrl = '';

  // OTHER
  bool _isUploading = false;

  // EDIT STATE
  bool _isEditing = false;

  // USER
  late int _userId = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _getProfileInfo(_userId);
    });
  }

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

  // EDIT PROFILE INFO
  void _editProfile(BuildContext context) async {
    bool isFileReady = await _checkFile(_image);

    setState(() {
      _isEditing = true;
    });
    if (_formKey.currentState!.validate()) {
      final userTagNameExists = await Supabase.instance.client
          .from('users')
          .select<List<Map<String, dynamic>>>('id')
          .eq('user_tag_id', _userTagIdController.text)
          .neq('id', _userId);

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
        setState(() {
          _isEditing = false;
        });
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
        final obj = {
          'name': name,
          'user_tag_id': userTagId,
          'bio': bio,
          'profile_image_url': profileImageUrl
        };

        final newUser = await Supabase.instance.client
            .from('users')
            .update(obj)
            .eq('id', _userId)
            .select("*");

        _clearPhoto();
        _nameController.clear();
        _userTagIdController.clear();
        _bioController.clear();

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
          setState(() {
            _isEditing = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContainerPage(
                selectedPageIndex: 0,
              ),
            ),
          );
        } else {
          setState(() {
            _isEditing = false;
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
          _isUploading = false;
        });
      } else {
        final name = _nameController.text;
        final userTagId = _userTagIdController.text;
        final bio = _bioController.text;
        final obj = {
          'name': name,
          'user_tag_id': userTagId,
          'bio': bio,
        };

        final newUser = await Supabase.instance.client
            .from('users')
            .update(obj)
            .eq('id', _userId)
            .select("*");

        _clearPhoto();
        _nameController.clear();
        _userTagIdController.clear();
        _bioController.clear();

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
          setState(() {
            _isEditing = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContainerPage(
                selectedPageIndex: 0,
              ),
            ),
          );
        } else {
          setState(() {
            _isEditing = false;
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
          _isUploading = false;
        });
      }
    }
    setState(() {
      _isEditing = false;
    });
  }

  // EDIT PROFILE INFO
  _getProfileInfo(id) async {
    dynamic info = await Supabase.instance.client
        .from('users')
        .select("id, name, user_tag_id, bio, profile_image_url")
        .eq('id', id)
        .single();

    log(info.toString());

    setState(() {
      _nameController.text = info['name'];
      _userTagIdController.text = info['user_tag_id'];
      _bioController.text = info['bio'];
      _imageUrl = info['profile_image_url'] ?? '';
    });
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    onNewCameraSelected(cameras[1]);
    _loadPreferences();
    super.initState();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
      ),
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
                            const SizedBox(
                              height: 20.0,
                            ),
                            Stack(
                              children: [
                                _imageUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Container(
                                          height: 150,
                                          width: 150,
                                          color: const Color.fromARGB(
                                              255, 240, 240, 240),
                                          child: SizedBox(
                                              child: Image.network(
                                            _imageUrl,
                                            height: 150,
                                            width: 150,
                                          )),
                                        ),
                                      )
                                    : const SizedBox(width: 0, height: 0),
                                !_imageSelected &&
                                        !_imageCaptured &&
                                        _imageUrl.isEmpty
                                    ? ClipOval(
                                        child: Container(
                                          height: 150,
                                          width: 150,
                                          color: const Color.fromARGB(
                                              255, 240, 240, 240),
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
                                                  255, 240, 240, 240),
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
                                                  255, 240, 240, 240),
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
                              decoration: InputDecoration(
                                hintText: 'Name',
                                filled: true,
                                fillColor: Colors
                                    .grey[200], // Use the desired grey color
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
                              controller: _userTagIdController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your tag name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Tag Name',
                                filled: true,
                                fillColor: Colors
                                    .grey[200], // Use the desired grey color
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
                              controller: _bioController,
                              decoration: InputDecoration(
                                hintText: 'Bio',
                                filled: true,
                                fillColor: Colors
                                    .grey[200], // Use the desired grey color
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
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(45.0),
                                    ),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    Colors.black,
                                  ),
                                ),
                                onPressed: !_isEditing
                                    ? () {
                                        _editProfile(context);
                                      }
                                    : null,
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15.0,
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
