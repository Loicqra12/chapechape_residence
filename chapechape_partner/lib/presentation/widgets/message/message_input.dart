import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/models/message/message.dart';

class MessageInput extends StatefulWidget {
  final Function(String content, List<MessageAttachment>? attachments) onSendMessage;
  final Function(String filePath, String? name) onAttachmentSelected;
  final Function(String content)? onSendWhatsApp;
  final Function(String content)? onSendSMS;
  final bool enabled;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.onAttachmentSelected,
    this.onSendWhatsApp,
    this.onSendSMS,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isComposing = false;
  String _selectedPlatform = 'chat'; // 'chat', 'whatsapp', 'sms'

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

    // Envoyer selon la plateforme sélectionnée
    switch (_selectedPlatform) {
      case 'whatsapp':
        if (widget.onSendWhatsApp != null) {
          widget.onSendWhatsApp!(text);
        }
        break;
      case 'sms':
        if (widget.onSendSMS != null) {
          widget.onSendSMS!(text);
        }
        break;
      case 'chat':
      default:
        widget.onSendMessage(text, null);
        break;
    }
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Joindre un fichier'),
              onTap: _pickFile,
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Prendre une photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Sélectionner une photo'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        );
      },
    );
  }

  void _showPlatformSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir la plateforme d\'envoi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                title: Text('Chat interne'),
                subtitle: Text('Message privé dans l\'application'),
                trailing: _selectedPlatform == 'chat' ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedPlatform = 'chat';
                  });
                  Navigator.pop(context);
                },
              ),
              if (widget.onSendWhatsApp != null)
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text('WhatsApp Business'),
                  subtitle: Text('Envoi via WhatsApp Business'),
                  trailing: _selectedPlatform == 'whatsapp' ? Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _selectedPlatform = 'whatsapp';
                    });
                    Navigator.pop(context);
                  },
                ),
              if (widget.onSendSMS != null)
                ListTile(
                  leading: Icon(Icons.sms, color: Colors.orange),
                  title: Text('SMS'),
                  subtitle: Text('Envoi par message SMS'),
                  trailing: _selectedPlatform == 'sms' ? Icon(Icons.check, color: Colors.orange) : null,
                  onTap: () {
                    setState(() {
                      _selectedPlatform = 'sms';
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _getPlatformIcon() {
    switch (_selectedPlatform) {
      case 'whatsapp':
        return Icon(Icons.phone, color: Colors.green);
      case 'sms':
        return Icon(Icons.sms, color: Colors.orange);
      case 'chat':
      default:
        return Icon(Icons.chat, color: Theme.of(context).colorScheme.primary);
    }
  }

  Color _getPlatformColor() {
    switch (_selectedPlatform) {
      case 'whatsapp':
        return Colors.green;
      case 'sms':
        return Colors.orange;
      case 'chat':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getPlatformTooltip() {
    switch (_selectedPlatform) {
      case 'whatsapp':
        return 'Envoyer via WhatsApp Business';
      case 'sms':
        return 'Envoyer par SMS';
      case 'chat':
      default:
        return 'Envoyer via chat interne';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildDisabledInput();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
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
                onPressed: () {
                  _showAttachmentOptions();
                },
              ),
              // Bouton sélecteur de plateforme
              IconButton(
                icon: _getPlatformIcon(),
                onPressed: _showPlatformSelector,
                tooltip: _getPlatformTooltip(),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _isComposing ? _getPlatformColor() : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_controller.text)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDisabledInput() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Text(
              'La messagerie n\'est pas encore activée pour cette réservation',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.lock_outline, color: Colors.grey[500]),
          onPressed: null,
        ),
      ],
    );
  }
}
