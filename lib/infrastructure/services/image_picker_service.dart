import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Prend une photo avec la caméra
  Future<String?> pickImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Optimisation
    );

    if (photo == null) return null;

    return await _saveImagePermanently(photo.path);
  }

  /// Sélectionne une image depuis la galerie
  Future<String?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return null;

    return await _saveImagePermanently(image.path);
  }

  /// Déplace l'image du cache vers le dossier Documents de l'app
  Future<String> _saveImagePermanently(String temporaryPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(temporaryPath)}';
    final permanentPath = p.join(directory.path, 'maintenance_photos', fileName);

    // Créer le dossier s'il n'existe pas
    final parentDir = Directory(p.dirname(permanentPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Copier le fichier
    final File tempFile = File(temporaryPath);
    await tempFile.copy(permanentPath);

    // Optionnel : supprimer l'original du cache si on veut faire le ménage
    // await tempFile.delete();

    return permanentPath;
  }
}
