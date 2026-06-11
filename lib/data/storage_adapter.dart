import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/attachments/attachments.dart';
import 'package:powersync/attachments/io.dart';
import 'package:splizz/data/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

// For Flutter (native platforms)
Future<LocalStorage> getLocalStorage() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final attachmentsDir = Directory('${appDocDir.path}/attachments');
  return IOLocalStorage(attachmentsDir);
}

// Remote storage adapter (example with signed URLs)
class SupabaseStorageAdapter implements RemoteStorage {
  @override
  Future<void> uploadFile(
    Stream<Uint8List> fileData,
    Attachment attachment,
  ) async {
    if (!loggedIn) {
      throw Exception('User must be logged in to upload files');
    }

    final bytes = await fileData.expand((chunk) => chunk).toList();
    await Supabase.instance.client.storage
      .from('images') // Replace with your storage bucket name
      .uploadBinary(attachment.id + ".jpg", 
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true)
      );
  }
  
  @override
  Future<Stream<List<int>>> downloadFile(Attachment attachment) async {
    if (!loggedIn) {
      throw Exception('User must be logged in to download files');
    }

    Uint8List image = await Supabase.instance.client.storage
      .from('images') // Replace with your storage bucket name
      .download(attachment.id + ".jpg");
    return Stream.value(image);
  }
  
  @override
  Future<void> deleteFile(Attachment attachment) async {
    if (!loggedIn) {
      throw Exception('User must be logged in to delete files');
    }

    await Supabase.instance.client.storage
      .from('images') // Replace with your storage bucket name
      .remove([attachment.id + ".jpg"]);
  }
}

//TODO: Security Best Practice: Always use your backend to generate signed URLs and validate permissions. Never expose storage credentials directly to clients.