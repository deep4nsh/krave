import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/firestore_service.dart';

class ManageMenu extends StatefulWidget {
  final String canteenId;
  const ManageMenu({super.key, required this.canteenId});

  @override
  State<ManageMenu> createState() => _ManageMenuState();
}

class _ManageMenuState extends State<ManageMenu> {
  final FirestoreService fs = FirestoreService();
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null; // swallow in UI, we show failure after
    }
  }

  void _addMenuItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
              ),
              if (_image != null) Image.file(_image!, height: 100),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final imgUrl = _image != null ? await _uploadImage(_image!) : null;
              await fs.addMenuItem(widget.canteenId, {
                'name': nameCtrl.text.trim(),
                'price': int.parse(priceCtrl.text),
                'imageUrl': imgUrl,
                'available': true,
              });
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenuItemDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: fs.streamMenuItems(widget.canteenId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('No menu items.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: item.imageUrl != null
                    ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.fastfood),
                title: Text(item.name),
                subtitle: Text("₹${item.price}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => fs.deleteMenuItem(widget.canteenId, item.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}