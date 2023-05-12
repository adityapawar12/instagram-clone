import 'dart:io';
import '../main.dart';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePost extends StatefulWidget with WidgetsBindingObserver {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  // CAMERA
  CameraController? controller;
  bool _isCameraInitialized = false;

  // RESOLUTION
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.medium;

  // ZOOM
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;

  // EXPOSURE
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  // FLASH
  FlashMode? _currentFlashMode;

  // FLIP
  bool _isRearCameraSelected = true;

  // SETTINGS
  bool _showSettings = false;

  // POST IMAGE
  bool _imageSelected = false;
  late File _image = File('');
  late int _userId = 0;
  late String _location = '';
  late String _postType = 'image';
  late String _caption = '';

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // ON CAMERA SELECTED
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      _currentFlashMode = controller!.value.flashMode;
      cameraController
          .getMaxZoomLevel()
          .then((value) => _maxAvailableZoom = value);

      cameraController
          .getMinZoomLevel()
          .then((value) => _minAvailableZoom = value);

      cameraController
          .getMinExposureOffset()
          .then((value) => _minAvailableExposureOffset = value);

      cameraController
          .getMaxExposureOffset()
          .then((value) => _maxAvailableExposureOffset = value);
    } on CameraException catch (e) {
      log('Error initializing camera: $e');
    }

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
    });
  }

  //  TAKE PICTURE
  Future<void> _takePhoto() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      return;
    }
    final XFile image = await cameraController.takePicture();
    setState(() {
      _image = File(image.path);
      _imageSelected = true;
    });
  }

  // CLEAR PHOTO
  void _clearPhoto() {
    setState(() {
      _image = File('');
      _imageSelected = false;
      _location = '';
      _caption = '';
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

  // MAKE POST
  Future<void> _saveImage() async {
    bool isFileReady = await _checkFile(_image);
    if (isFileReady == true) {
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
      var post =
          await Supabase.instance.client.from('posts').insert(obj).select();

      log(post.toString());

      if (post![0]!['caption']!.length > 0) {
        log('CAPTIONNNNNNNNNNNNNNNNNNNNNNNNNNNN');
        String captionText = post![0]!['caption']!;
        List<String> captionWords = captionText.split(" ");

        for (String captionWord in captionWords) {
          if (captionWord.startsWith("#")) {
            log("Found word starting with #: $captionWord");

            var hashtagExists = await Supabase.instance.client
                .from('hashtags')
                .select("id")
                .eq('hashtag', captionWord);

            if (hashtagExists != null && hashtagExists.length > 0) {
              final hashtagPostObj = {
                'hashtag_id': hashtagExists![0]!['id'],
                'post_id': post![0]!['id'],
              };
              await Supabase.instance.client
                  .from('hashtag_posts')
                  .insert(hashtagPostObj)
                  .select();
            } else {
              final hashtagObj = {
                'post_id': post![0]!['id'],
                'user_id': post![0]!['user_id'],
                'hashtag': captionWord,
              };
              var hashtag = await Supabase.instance.client
                  .from('hashtags')
                  .insert(hashtagObj)
                  .select();

              final hashtagPostObj = {
                'hashtag_id': hashtag![0]!['id'],
                'post_id': post![0]!['id'],
              };
              await Supabase.instance.client
                  .from('hashtag_posts')
                  .insert(hashtagPostObj)
                  .select();
            }
          }
        }
      }

      _clearPhoto();
    }
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _loadPreferences();
    onNewCameraSelected(cameras[0]);
    // SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
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
          ? SafeArea(
              child: Column(
                children: [
                  _imageSelected == false
                      ? Expanded(
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // TOP SETTINGS
                                  _showSettings
                                      ? Container(
                                          height: 30,
                                          color: Colors.black,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // FLASH OFF
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    _currentFlashMode =
                                                        FlashMode.off;
                                                  });
                                                  await controller!
                                                      .setFlashMode(
                                                    FlashMode.off,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.flash_off,
                                                  color: _currentFlashMode ==
                                                          FlashMode.off
                                                      ? Colors.amber
                                                      : Colors.white,
                                                  size: 20,
                                                ),
                                              ),

                                              // AUTO FLASH
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    _currentFlashMode =
                                                        FlashMode.auto;
                                                  });
                                                  await controller!
                                                      .setFlashMode(
                                                    FlashMode.auto,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.flash_auto,
                                                  color: _currentFlashMode ==
                                                          FlashMode.auto
                                                      ? Colors.amber
                                                      : Colors.white,
                                                  size: 20,
                                                ),
                                              ),

                                              // TORCH
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    _currentFlashMode =
                                                        FlashMode.torch;
                                                  });
                                                  await controller!
                                                      .setFlashMode(
                                                    FlashMode.torch,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.highlight,
                                                  color: _currentFlashMode ==
                                                          FlashMode.torch
                                                      ? Colors.amber
                                                      : Colors.white,
                                                  size: 20,
                                                ),
                                              ),

                                              // RESOLUTION
                                              SizedBox(
                                                height: 20,
                                                child: DropdownButton<
                                                    ResolutionPreset>(
                                                  dropdownColor: Colors.black,
                                                  underline: Container(),
                                                  value:
                                                      currentResolutionPreset,
                                                  items: [
                                                    for (ResolutionPreset preset
                                                        in resolutionPresets)
                                                      DropdownMenuItem(
                                                        value: preset,
                                                        child: Text(
                                                          preset
                                                              .toString()
                                                              .split('.')[1]
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      )
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      currentResolutionPreset =
                                                          value!;
                                                      _isCameraInitialized =
                                                          false;
                                                    });
                                                    onNewCameraSelected(
                                                        controller!
                                                            .description);
                                                  },
                                                  hint:
                                                      const Text("Select item"),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox(),

                                  // CAMERA
                                  AspectRatio(
                                    aspectRatio:
                                        1 / controller!.value.aspectRatio,
                                    child: controller!.buildPreview(),
                                  ),

                                  // FLASH
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      color: Colors.black,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // SHOW SETTINGS
                                          IconButton(
                                            onPressed: () async {
                                              setState(() {
                                                _showSettings = !_showSettings;
                                              });
                                            },
                                            icon: Icon(
                                              _showSettings
                                                  ? Icons.settings_sharp
                                                  : Icons.settings_rounded,
                                              color: Colors.white,
                                              size: !_showSettings ? 50 : 30,
                                            ),
                                          ),

                                          // CLICK PIC
                                          IconButton(
                                            onPressed: _takePhoto,
                                            icon: Icon(
                                              Icons.circle,
                                              color: Colors.white,
                                              size: !_showSettings ? 70 : 30,
                                            ),
                                          ),

                                          // FLIP
                                          IconButton(
                                            onPressed: () async {
                                              setState(() {
                                                _isCameraInitialized = false;
                                              });
                                              onNewCameraSelected(
                                                cameras[_isRearCameraSelected
                                                    ? 1
                                                    : 0],
                                              );
                                              setState(() {
                                                _isRearCameraSelected =
                                                    !_isRearCameraSelected;
                                              });
                                            },
                                            icon: Icon(
                                              _isRearCameraSelected
                                                  ? Icons.camera_front
                                                  : Icons.camera_rear,
                                              color: Colors.white,
                                              size: !_showSettings ? 50 : 30,
                                            ),
                                          ),

                                          // SELECT FILE
                                          IconButton(
                                            onPressed: _selectImage,
                                            icon: Icon(
                                              Icons.image,
                                              color: Colors.white,
                                              size: !_showSettings ? 50 : 30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ZOOM
                              Positioned(
                                top: 30,
                                right: 2,
                                child: SizedBox(
                                  width: 50,
                                  height: 230,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Slider(
                                            value: _currentExposureOffset,
                                            min: _minAvailableExposureOffset,
                                            max: _maxAvailableExposureOffset,
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white,
                                            onChanged: (value) async {
                                              setState(() {
                                                _currentExposureOffset = value;
                                              });
                                              await controller!
                                                  .setExposureOffset(value);
                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '${_currentExposureOffset.toStringAsFixed(1)}x',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // EXPOSURE
                              Positioned(
                                top: 270,
                                right: 2,
                                child: SizedBox(
                                  width: 50,
                                  height: 230,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Slider(
                                            value: _currentZoomLevel,
                                            min: _minAvailableZoom,
                                            max: _maxAvailableZoom,
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white,
                                            onChanged: (value) async {
                                              setState(
                                                () {
                                                  _currentZoomLevel = value;
                                                },
                                              );
                                              await controller!
                                                  .setZoomLevel(value);
                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '${_currentZoomLevel.toStringAsFixed(1)}x',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  _imageSelected == true
                      ? Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      margin: const EdgeInsets.fromLTRB(
                                        25.0,
                                        16.0,
                                        16.0,
                                        16.0,
                                      ),
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(
                                            10.0,
                                          ),
                                        ),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Image.file(
                                        _image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Center(
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                165.0,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        50.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color.fromARGB(
                                                  255, 240, 240, 240),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              50.0,
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
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    50.0,
                                                color: Colors.blue,
                                                child: IconButton(
                                                  onPressed: _saveImage,
                                                  color: Colors.white,
                                                  icon:
                                                      const Icon(Icons.upload),
                                                ),
                                              )
                                            : Container(),
                                        const SizedBox(height: 16.0),
                                        _imageSelected
                                            ? Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    50.0,
                                                color: Colors.blue,
                                                child: IconButton(
                                                  onPressed: _clearPhoto,
                                                  color: Colors.white,
                                                  icon:
                                                      const Icon(Icons.cancel),
                                                ),
                                              )
                                            : const SizedBox(),
                                        const SizedBox(height: 16.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container()
                ],
              ),
            )
          : Container(),
    );
  }
}
