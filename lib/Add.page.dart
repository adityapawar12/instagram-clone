import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isUploading = false;
  bool _imageSelected = false;
  late int _userId = 0;
  late String _location = '';
  late String _postType = 'image';
  late String _caption = '';

  @override
  void initState() {
    _initializeCamera();
    _loadPreferences();
    super.initState();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.max,
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
      _location = '';
      _caption = '';
      _imageSelected = false;
    });
  }

  Future<void> _saveImage() async {
    setState(() {
      _isUploading = true;
    });
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage
        .from('post')
        .upload('post-media/$fileName', _image);

    final dynamic res = Supabase.instance.client.storage
        .from('post')
        .getPublicUrl('post-media/$fileName');

    final obj = {
      'user_id': _userId,
      'location': _location,
      'post_type': _postType,
      'post_url': res,
      'caption': _caption,
    };

    await Supabase.instance.client.from('posts').insert(obj);

    _clearPhoto();

    setState(() {
      _isUploading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_isUploading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post Page'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              !_imageSelected
                  ? SizedBox(
                      width: screenWidth,
                      height: screenWidth,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CameraPreview(_controller),
                      ),
                    )
                  : Container(),
              _imageSelected
                  ? SizedBox(
                      width: screenWidth,
                      height: screenWidth,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.file(
                          _image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(),
              !_imageSelected ? const SizedBox(height: 16.0) : Container(),
              !_imageSelected
                  ? Container(
                      width: MediaQuery.of(context).size.width - 50.0,
                      color: Colors.cyan,
                      child: IconButton(
                        onPressed: _takePhoto,
                        color: Colors.white,
                        icon: const Icon(Icons.camera_alt),
                      ),
                    )
                  : Container(),
              !_imageSelected ? const SizedBox(height: 16.0) : Container(),
              !_imageSelected
                  ? Container(
                      width: MediaQuery.of(context).size.width - 50.0,
                      color: Colors.cyan,
                      child: IconButton(
                        onPressed: _selectImage,
                        color: Colors.white,
                        icon: const Icon(Icons.add),
                      ),
                    )
                  : Container(),
              const SizedBox(height: 16.0),
              if (_imageSelected)
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 50.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Location',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 5.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            _location = value;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Caption',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 5.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            _caption = value;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          width: MediaQuery.of(context).size.width - 50.0,
                          child: DropdownButton<String>(
                            value: _postType,
                            onChanged: (value) {
                              setState(() {
                                _postType = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'image',
                                child: Text('Image'),
                              ),
                              DropdownMenuItem(
                                value: 'video',
                                child: Text('Video'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _imageSelected
                            ? Container(
                                width: MediaQuery.of(context).size.width - 50.0,
                                color: Colors.cyan,
                                child: IconButton(
                                  onPressed: _saveImage,
                                  color: Colors.white,
                                  icon: const Icon(Icons.upload),
                                ),
                              )
                            : Container(),
                        const SizedBox(height: 16.0),
                        _imageSelected
                            ? Container(
                                width: MediaQuery.of(context).size.width - 50.0,
                                color: Colors.cyan,
                                child: IconButton(
                                  onPressed: _clearPhoto,
                                  color: Colors.white,
                                  icon: const Icon(Icons.cancel),
                                ),
                              )
                            : const SizedBox(),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(),
            ],
          ),
        ),
      );
    }
  }
}
