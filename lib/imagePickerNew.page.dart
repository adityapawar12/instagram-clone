import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:instagram_clone/createPost.page.dart';
import 'package:instagram_clone/utils/files.dart';
import 'package:flutter_storage_path/flutter_storage_path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImagePickerNewPage extends StatefulWidget {
  const ImagePickerNewPage({super.key});

  @override
  State<ImagePickerNewPage> createState() => _ImagePickerNewPageState();
}

class _ImagePickerNewPageState extends State<ImagePickerNewPage> {
  List<FileModel> files = [];
  FileModel? selectedModel;
  String image = '';

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

      if (post![0]!['caption']!.length > 0) {
        String captionText = post![0]!['caption']!;
        List<String> captionWords = captionText.split(" ");

        for (String captionWord in captionWords) {
          if (captionWord.startsWith("#")) {
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    getImagesPath();
  }

  getImagesPath() async {
    var imagePath = await StoragePath.imagesPath;
    var images = jsonDecode(imagePath!) as List;
    files = images.map<FileModel>((e) => FileModel.fromJson(e)).toList();

    log(files.toString());

    if (files.isNotEmpty) {
      setState(() {
        selectedModel = files[0];
        image = files[0].files[0];
      });
    }
  }

  List<DropdownMenuItem<FileModel>> getItems() {
    return files
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(
              e.folder,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: _imageSelected == false
              ? <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.clear),
                              iconSize: 25,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "New Post",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        color: Colors.blue,
                        iconSize: 25,
                        onPressed: () {
                          // log(image.toString());

                          setState(() {
                            _image = File(image);
                            _imageSelected = true;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: image.isNotEmpty
                        ? Image.file(
                            File(image),
                            height: MediaQuery.of(context).size.height * 0.45,
                            width: MediaQuery.of(context).size.width,
                          )
                        : Container(),
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(0),
                    height: 30,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<FileModel>(
                              items: getItems(),
                              onChanged: (FileModel? d) {
                                setState(() {
                                  selectedModel = d!;
                                  image = d.files[0];
                                });
                              },
                              value: selectedModel,
                            ),
                          ),
                        ),
                        Expanded(child: Container()),
                        IconButton(
                            padding: const EdgeInsets.all(0),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreatePost(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.camera_alt_rounded))
                      ],
                    ),
                  ),
                  const Divider(),
                  selectedModel != null && selectedModel!.files.isEmpty
                      ? Container()
                      : Expanded(
                          child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemBuilder: (_, i) {
                                if (selectedModel != null &&
                                    selectedModel!.files.isNotEmpty &&
                                    selectedModel!.files.length > i) {
                                  var file = selectedModel!.files[i];

                                  return GestureDetector(
                                    child: Image.file(
                                      File(file),
                                      fit: BoxFit.cover,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        image = file;
                                      });
                                    },
                                  );
                                }

                                return Container();
                              }),
                        )
                ]
              : <Widget>[
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
                          width: MediaQuery.of(context).size.width - 165.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
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
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 240, 240, 240),
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
                                  width:
                                      MediaQuery.of(context).size.width - 50.0,
                                  color: Colors.blue,
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
                                  width:
                                      MediaQuery.of(context).size.width - 50.0,
                                  color: Colors.blue,
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
                ],
        ),
      ),
    );
  }
}
