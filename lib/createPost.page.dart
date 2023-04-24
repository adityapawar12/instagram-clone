import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../main.dart';

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
      // ignore: avoid_print
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  //  TAKE PICTURE
  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      // ignore: avoid_print
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    onNewCameraSelected(cameras[0]);
    // SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
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
          ? SafeArea(
              child: Column(
                children: [
                  Expanded(
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
                                              _currentFlashMode = FlashMode.off;
                                            });
                                            await controller!.setFlashMode(
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
                                            await controller!.setFlashMode(
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
                                            await controller!.setFlashMode(
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
                                          child:
                                              DropdownButton<ResolutionPreset>(
                                            dropdownColor: Colors.black87,
                                            underline: Container(),
                                            value: currentResolutionPreset,
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
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                currentResolutionPreset =
                                                    value!;
                                                _isCameraInitialized = false;
                                              });
                                              onNewCameraSelected(
                                                  controller!.description);
                                            },
                                            hint: const Text("Select item"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),

                            // CAMERA
                            AspectRatio(
                              aspectRatio: 1 / controller!.value.aspectRatio,
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                      onPressed: () async {
                                        XFile? rawImage = await takePicture();
                                        File imageFile = File(rawImage!.path);

                                        int currentUnix = DateTime.now()
                                            .millisecondsSinceEpoch;
                                        Directory documentsDirectory =
                                            await getApplicationDocumentsDirectory();
                                        String fileFormat =
                                            rawImage.path.split('.').last;

                                        await imageFile.copy(
                                          '${documentsDirectory.path}/$currentUnix.$fileFormat',
                                        );
                                      },
                                      icon: Icon(
                                        Icons.circle,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
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
                                          cameras[
                                              _isRearCameraSelected ? 1 : 0],
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
                                      inactiveColor: Colors.white30,
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
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${_currentExposureOffset.toStringAsFixed(1)}x',
                                      style:
                                          const TextStyle(color: Colors.white),
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
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) async {
                                        setState(() {
                                          _currentZoomLevel = value;
                                        });
                                        await controller!.setZoomLevel(value);
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${_currentZoomLevel.toStringAsFixed(1)}x',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Container(),
    );
  }
}
