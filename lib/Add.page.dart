// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase/supabase.dart';

// class AddPage extends StatefulWidget {
//   const AddPage({super.key});

//   @override
//   State<AddPage> createState() => _AddPageState();
// }

// class _AddPageState extends State<AddPage> {
//   final _picker = ImagePicker();
//   late File _image = File('');
//   bool _isUploading = false;

//   Future<void> _selectImage() async {
//     final dynamic pickedFile =
//         await _picker.getImage(source: ImageSource.gallery);
//     setState(() {
//       _image = File(pickedFile.path);
//     });
//   }

//   Future<void> _uploadImage() async {
//     setState(() {
//       _isUploading = true;
//     });
//     final client = SupabaseClient('<your_supabase_url>', '<your_supabase_key>');
//     final storage = client.storage.from('bucket_name');
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final fileData = await _image.readAsBytes();
//     final dynamic response = await storage.uploadBinary(fileName, fileData);
//     if (response.error == null) {
//       // Image uploaded successfully
//       // ignore: avoid_print
//       print('Image uploaded successfully');
//     } else {
//       // Error uploading image
//       // ignore: avoid_print
//       print('Error uploading image: ${response.error.message}');
//     }
//     setState(() {
//       _isUploading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Post Page'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _image != null
//                 ? Image.file(_image)
//                 : const Placeholder(
//                     fallbackHeight: 500,
//                   ),
//             const SizedBox(
//               height: 16,
//             ),
//             ElevatedButton(
//               onPressed: _selectImage,
//               child: const Text('Select Image'),
//             ),
//             const SizedBox(
//               height: 16,
//             ),
//             _isUploading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: _image != null ? _uploadImage : null,
//                     child: const Text('Post'),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase/supabase.dart';
// import 'package:camera/camera.dart';

// class AddPage extends StatefulWidget {
//   const AddPage({super.key});

//   @override
//   _AddPageState createState() => _AddPageState();
// }

// class _AddPageState extends State<AddPage> {
//   final _picker = ImagePicker();
//   late List<CameraDescription> _cameras;
//   late CameraController _controller;
//   late File _image = File('');
//   bool _isUploading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     if (_cameras.isNotEmpty) {
//       _controller = CameraController(_cameras[0], ResolutionPreset.high);
//       await _controller.initialize();
//       setState(() {});
//     }
//   }

//   Future<void> _selectImage() async {
//     final pickedFile = await _picker.getImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _takePhoto() async {
//     final path = await _controller.takePicture();
//     setState(() {
//       _image = File(path.path);
//     });
//   }

//   Future<void> _uploadImage() async {
//     setState(() {
//       _isUploading = true;
//     });
//     final client = SupabaseClient('<your_supabase_url>', '<your_supabase_key>');
//     final storage = client.storage.from('bucket_name');
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final fileData = await _image.readAsBytes();
//     final dynamic response = await storage.uploadBinary(fileName, fileData);
//     if (response.error == null) {
//       // Image uploaded successfully
//       print('Image uploaded successfully');
//     } else {
//       // Error uploading image
//       print('Error uploading image: ${response.error.message}');
//     }
//     setState(() {
//       _isUploading = false;
//     });
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Post Page'),
//       ),
//       body: _controller != null && _controller.value.isInitialized
//           ? Stack(
//               children: [
//                 Positioned.fill(
//                   child: AspectRatio(
//                     aspectRatio: _controller.value.aspectRatio,
//                     child: CameraPreview(_controller),
//                   ),
//                 ),
//                 _image != null
//                     ? Positioned.fill(
//                         child: Image.file(
//                           _image,
//                           fit: BoxFit.cover,
//                         ),
//                       )
//                     : Container(),
//                 Positioned(
//                   bottom: 16,
//                   left: 16,
//                   child: FloatingActionButton(
//                     onPressed: _takePhoto,
//                     child: Icon(Icons.camera_alt),
//                   ),
//                 ),
//               ],
//             )
//           : Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _image != null
//                       ? Image.file(_image)
//                       : Placeholder(
//                           fallbackHeight: 200,
//                         ),
//                   SizedBox(
//                     height: 16,
//                   ),
//                   ElevatedButton(
//                     onPressed: _selectImage,
//                     child: Text('Select Image'),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase/supabase.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
  // _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _picker = ImagePicker();
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  late File _image = File('');
  bool _isUploading = false;
  bool _imageSelected = false;
  late int _userId;
  late String _userName = '';
  late String _userPhone = '';
  late String _userEmail = '';
  late String _userProfileUrl = '';

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
      _userName = prefs.getString('userName') ?? "";
      _userPhone = prefs.getString('userPhone') ?? "";
      _userEmail = prefs.getString('userEmail') ?? "";
      _userProfileUrl = prefs.getString('profileImage') ?? "";
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(_cameras[0], ResolutionPreset.high);
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

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });
    final client = SupabaseClient('https://wjzgvpftlznhngujjmze.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqemd2cGZ0bHpuaG5ndWpqbXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODEyMDQ5MTgsImV4cCI6MTk5Njc4MDkxOH0.M8QuSuQWQFcP13_1nallkST1hIlP7WJrgWPwwXs9BPc');
    final storage = client.storage.from('post');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileData = await _image.readAsBytes();
    final dynamic response = await storage.uploadBinary(fileName, fileData);
    if (response.error == null) {
      // Image uploaded successfully
      print('Image uploaded successfully');
    } else {
      // Error uploading image
      print('Error uploading image: ${response.error.message}');
    }
    setState(() {
      _isUploading = false;
    });
  }

  Future<void> _saveImage() async {
    final client = SupabaseClient('https://wjzgvpftlznhngujjmze.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqemd2cGZ0bHpuaG5ndWpqbXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODEyMDQ5MTgsImV4cCI6MTk5Njc4MDkxOH0.M8QuSuQWQFcP13_1nallkST1hIlP7WJrgWPwwXs9BPc');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dynamic response =
        client.storage.from('post').upload('$_userId/$fileName', _image);

    final error = response.error;
    if (response.hasError) {
      print(error!.message);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Post Page'),
        ),
        body:
            // _controller != null && _controller.value.isInitialized
            //     ?
            Stack(
          children: [
            Positioned.fill(
              bottom: 250,
              top: 0,
              right: 0,
              left: 0,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CameraPreview(_controller),
              ),
            ),
            _image.path.isNotEmpty
                ? Positioned.fill(
                    bottom: 250,
                    top: 0,
                    right: 0,
                    left: 0,
                    child: Image.file(
                      _image,
                      fit: BoxFit.cover,
                    ),
                  )
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
                : SizedBox(),
          ],
        )
        // : Center(
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         _image.path.isNotEmpty
        //             ? Image.file(_image)
        //             : const Placeholder(
        //                 fallbackHeight: 200,
        //               ),
        //         const SizedBox(
        //           height: 16,
        //         ),
        //         ElevatedButton(
        //           onPressed: _selectImage,
        //           child: Text('Select Image'),
        //         ),
        //       ],
        //     ),
        //   ),
        );
  }
}
