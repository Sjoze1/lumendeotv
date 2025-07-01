import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/upload_progress_widget.dart';
import 'package:dio/dio.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _thumbnail;
  File? _trailer;
  File? _fullVideo;

  bool _isUploading = false;
  double _progress = 0.0;

  CancelToken? _cancelToken;

  Future<void> _pickFile(Function(File) onFilePicked, List<String> allowedExtensions) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: allowedExtensions);
    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!));
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnail == null || _trailer == null || _fullVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick all files')));
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _cancelToken = CancelToken();
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'thumbnail': await MultipartFile.fromFile(_thumbnail!.path, filename: 'thumbnail.jpg'),
        'trailer': await MultipartFile.fromFile(_trailer!.path, filename: 'trailer.mp4'),
        'full_video': await MultipartFile.fromFile(_fullVideo!.path, filename: 'full_video.mp4'),
      });

      final response = await dio.post(
        'https://lumendeotv-project-backend.onrender.com/api/upload',
        data: formData,
        cancelToken: _cancelToken,
        onSendProgress: (int sent, int total) {
          setState(() {
            _progress = sent / total;
          });
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video uploaded successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${response.statusMessage}')));
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload cancelled')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      setState(() {
        _isUploading = false;
        _progress = 0.0;
        _cancelToken = null;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Background image fills the page
        Positioned.fill(
          child: Image.asset(
            'lib/assets/plainlumendeobackground.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Icon at top-left
        Positioned(
          top: 45,
          left: 25,
          child: Image.asset(
            'lib/assets/lumendeotv-icon.jpg',
            width: 110,
            height: 110,
          ),
        ),
        // Centered content with padding and semi-transparent background
        Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black.withOpacity(0.5),
            constraints: const BoxConstraints(maxWidth: 400), // optional max width
            child: _isUploading
                ? UploadProgressWidget(
                    progress: _progress,
                    onCancel: () {
                      _cancelToken?.cancel('User cancelled upload');
                      setState(() {
                        _isUploading = false;
                        _progress = 0.0;
                        _cancelToken = null;
                      });
                    },
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: 'Title'),
                            validator: (value) => value!.isEmpty ? 'Title required' : null,
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description'),
                            validator: (value) => value!.isEmpty ? 'Description required' : null,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.image),
                              label: Text(_thumbnail != null ? 'Thumbnail Selected' : 'Pick Thumbnail'),
                              onPressed: () => _pickFile((file) => setState(() => _thumbnail = file), ['jpg', 'png']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.video_library),
                              label: Text(_trailer != null ? 'Trailer Selected' : 'Pick Trailer'),
                              onPressed: () => _pickFile((file) => setState(() => _trailer = file), ['mp4']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.video_call),
                              label: Text(_fullVideo != null ? 'Full Video Selected' : 'Pick Full Video'),
                              onPressed: () => _pickFile((file) => setState(() => _fullVideo = file), ['mp4']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _uploadVideo,
                              child: const Text('Upload'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 255, 213, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}
}
