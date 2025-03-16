import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/models/message/message.dart';

class MessageInput extends StatefulWidget {
  final Function(String content, List<MessageAttachment>? attachments) onSendMessage;
  final Function(String filePath, String? name) onAttachmentSelected;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.onAttachmentSelected,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    widget.onSendMessage(text, null);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        if (kIsWeb) {
          // Pour le web, on convertit l'image en base64
          final bytes = await image.readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          widget.onAttachmentSelected(base64Image, image.name);
        } else {
          widget.onAttachmentSelected(image.path, image.name);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        if (kIsWeb) {
          final file = result.files.first;
          if (file.bytes != null) {
            // Pour le web, on convertit le fichier en base64
            final base64File = 'data:application/octet-stream;base64,${base64Encode(file.bytes!)}';
            widget.onAttachmentSelected(base64File, file.name);
          }
        } else {
          final path = result.files.single.path;
          if (path != null) {
            widget.onAttachmentSelected(path, result.files.single.name);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFile,
              ),
              IconButton(
                icon: const Icon(Icons.photo_camera),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (String text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: _isComposing ? _handleSubmitted : null,
                  decoration: const InputDecoration(
                    hintText: 'Votre message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isComposing
                    ? () => _handleSubmitted(_controller.text)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
