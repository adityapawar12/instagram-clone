import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _picker = ImagePicker();
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  late File _image = File('');
  // bool _isUploading = false;
  bool _imageSelected = false;
  // late int _userId;
  // late String _userName = '';
  // late String _userPhone = '';
  // late String _userEmail = '';
  // late String _userProfileUrl = '';

  @override
  void initState() {
    _initializeCamera();
    _loadPreferences();
    super.initState();
  }

  Future<void> _loadPreferences() async {
    // final prefs = await SharedPreferences.getInstance();
    setState(() {
      // _userId = prefs.getInt('userId') ?? 0;
      // _userName = prefs.getString('userName') ?? "";
      // _userPhone = prefs.getString('userPhone') ?? "";
      // _userEmail = prefs.getString('userEmail') ?? "";
      // _userProfileUrl = prefs.getString('profileImage') ?? "";
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      await _controller.initialize();
      setState(() {});
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageSelected = true;
      });
    }
  }

  Future<void> _takePhoto() async {
    final path = await _controller.takePicture();
    setState(() {
      _image = File(path.path);
      _imageSelected = true;
    });
  }

  void _clearPhoto() {
    setState(() {
      _image = File('');
      _imageSelected = false;
    });
  }

  Future<void> _saveImage() async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    // final dynamic response =
    await Supabase.instance.client.storage
        .from('post')
        .upload('post-media/$fileName', _image);

    // final error = response.error;
    // if (response.hasError) {
    //   print(error!.message);
    // }

    // final dynamic res = Supabase.instance.client.storage
    //     .from('post')
    //     .getPublicUrl('post-media/$fileName');

    // final publicURL = res.data;
    _clearPhoto();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return _controller.value.isInitialized
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Post Page'),
            ),
            body: Stack(
              children: [
                _image.path.isEmpty
                    ? Positioned.fill(
                        bottom: 250,
                        top: 0,
                        right: 0,
                        left: 0,
                        child: SizedBox(
                          width: screenWidth,
                          height: screenWidth,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CameraPreview(_controller),
                          ),
                        ))
                    : Container(),
                _image.path.isNotEmpty
                    ? Positioned.fill(
                        bottom: 250,
                        top: 0,
                        right: 0,
                        left: 0,
                        child: SizedBox(
                          width: screenWidth,
                          height: screenWidth,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.file(
                              _image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ))
                    : Container(),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: FloatingActionButton(
                    onPressed: _takePhoto,
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _selectImage,
                    child: const Icon(Icons.add),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 100,
                  child: FloatingActionButton(
                    onPressed: _saveImage,
                    child: const Icon(Icons.upload),
                  ),
                ),
                _imageSelected
                    ? Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _clearPhoto,
                          child: const Icon(Icons.cancel),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}
