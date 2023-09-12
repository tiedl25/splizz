import 'dart:async';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:splizz/Helper/secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleDrive {
  //Singleton Pattern
  GoogleDrive._privateConstructor();
  static final GoogleDrive instance = GoogleDrive._privateConstructor();

  final _storage = SecureStorage();

  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await _storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
        ClientId(dotenv.env['clientId']!, dotenv.env['clientSecret']), [dotenv.env['scope']!], (url) {
          //Open Url in Browser
          launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        }
      );
      //Save Credentials
      await _storage.saveCredentials(authClient.credentials.accessToken, authClient.credentials.refreshToken!);

      return authClient;
    } else if (DateTime.tryParse(credentials["expiry"])!.isBefore(DateTime.now())) {
      var accessToken = AccessToken(credentials["type"], credentials["data"], DateTime.tryParse(credentials["expiry"])!);
      var accessCredentials = AccessCredentials(accessToken, credentials["refreshToken"], [dotenv.env['scope']!]);

      try {
        var rc = await refreshCredentials(ClientId(dotenv.env['clientId']!, dotenv.env['clientSecret']), accessCredentials, http.Client());
        return authenticatedClient(http.Client(), rc);
      } catch (error){
        _storage.clear();
        return getHttpClient();
      }

    } else {
      var accessToken = AccessToken(credentials["type"], credentials["data"], DateTime.tryParse(credentials["expiry"])!);
      var accessCredentials = AccessCredentials(accessToken, credentials["refreshToken"], [dotenv.env['scope']!]);
      
      var authClient = http.Client();
      return authenticatedClient(authClient, accessCredentials);
    }
  }

// check if the directory folder is already available in drive, if available return its id
// if not available create a folder in drive and return id
//   if not able to create id then it means user authentication has failed
  Future<String?> _getFolderId(gd.DriveApi drive, {String folderName='Splizz'}) async {
    const mimeType = "application/vnd.google-apps.folder";

    try {
      final found = await drive.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );

      final files = found.files;

      if (files == null) {
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      gd.File folder = gd.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await drive.files.create(folder);

      return folderCreation.id;
    } catch (e) {
      return null;
    }
  }

  // return all filenames that are related to splizz items
  Future<dynamic> getFilenames({owner=false}) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);
      String? folderId = await _getFolderId(drive);
      if(folderId == null) throw Error();

      List<gd.File>? response;
      if (owner) {
        response = (await drive.files.list(
            q: 'trashed=false and "$folderId" in parents',
            supportsAllDrives: true,
            includeItemsFromAllDrives: true,
            $fields: "*")).files;
      } else {
        response = (await drive.files.list(
            q: 'sharedWithMe=true and trashed=false and not "$folderId" in parents',
            supportsAllDrives: true,
            includeItemsFromAllDrives: true,
            $fields: "*")).files;
      }

      List<Map> itemlist = [];
      for (var file in response!){
        if((file.name)!.startsWith('splizz_item') && await DatabaseHelper.instance.checkSharedId(file.id!)){
          itemlist.add({'path' : file.name, 'id' : file.id, 'name' : file.properties?['itemName'], 'imageId' : file.properties?['imageId']});
        }
      }
      return itemlist;
    } catch(error) {
      return 1;
    }

  }

  Future<dynamic> getSharedPeople(String id) async {
    try {
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      final about = await drive.about.get($fields: 'user(emailAddress)');
      final userEmail = about.user?.emailAddress;

      final permissions = await drive.permissions.list(id, $fields: "*",);

      List people = [];

      for (var permission in permissions.permissions!) {
        if(permission.emailAddress != userEmail) {
          people.add({'email' : permission.emailAddress, 'name' : permission.displayName, 'id' : permission.id});
        }
      }

      return people;
    } catch(error){
      return 1;
    }
  }

  Future<dynamic> addPeople(String fileId, String email) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      var permission = gd.Permission(
          emailAddress: email,
          role: 'writer',
          type: 'user'
      );

      permission = await drive.permissions.create(
          permission,
          fileId,
          sendNotificationEmail: false,
          $fields: '*'
      );
      if (permission.emailAddress == null) throw Error();

      return {'email' : permission.emailAddress, 'name' : permission.displayName, 'id' : permission.id};
    } catch(error){
      return 1;
    }
  }

  Future<int> removePeople(String fileId, String permissionId) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      await drive.permissions.delete(fileId, permissionId);
      return 0;
    } catch(error){
      return 1;
    }

  }

  Future<int> updateFile(File file, id) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);
      String? folderId = await _getFolderId(drive);
      if(folderId == null) throw Error();

      final updatedFile = gd.File(name: path.basename(file.absolute.path));
      await drive.files.update(
        updatedFile,
        id,
        uploadMedia: gd.Media(file.openRead(), file.lengthSync()),
      );
      return 0;
    } catch(error) {
      return 1;
    }
  }

  Future<dynamic> uploadFile(File file, [String? itemName, String? imageId]) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      String? folderId =  await _getFolderId(drive);
      if(folderId == null) throw Error();

      gd.File fileToUpload = gd.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = path.basename(file.absolute.path);
      fileToUpload.properties = {};
      if(itemName != null) fileToUpload.properties?.addAll({'itemName' : itemName});
      if(imageId != null) fileToUpload.properties?.addAll({'imageId' : imageId});
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: gd.Media(file.openRead(), file.lengthSync()),
      );
      return response.id;
    } catch (error) {
      return 1;
    }
  }

  Future<int> deleteFile(String fileId) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);
      drive.files.delete(fileId);
      return 0;
    } catch(error) {
      return 1;
    }
  }

  Future<int> repeat(Function function) async {
    int i=0;
    int retValue=0;

    do {
      retValue = function();
    } while(retValue == 1 && i<3);

    return i;
  }

  Future<bool> lastModifiedByMe(String fileId) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    gd.File file = (await drive.files.get(fileId, $fields: "lastModifyingUser")) as gd.File;
    return file.lastModifyingUser?.me ?? false;
  }

  Future<bool> checkOwner(String fileId) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      final about = await drive.about.get($fields: '*');
      final id = about.user?.permissionId;

      final permissions = await drive.permissions.list(fileId, $fields: "*",);

      for (var permission in permissions.permissions!) {
        if(permission.id == id) {
          return permission.role == 'owner';
        }
      }
      return false;
    } catch(error){
      return false;
    }
  }
  
  Future<dynamic> downloadFile(String fileId, String filename) async {
    try{
      var client = await getHttpClient();
      var drive = gd.DriveApi(client);

      //download ByteStream from GoogleDrive
      gd.Media? response = (await drive.files.get(fileId, downloadOptions: gd.DownloadOptions.fullMedia)) as gd.Media?;
      return FileHandler.instance.writeBytestream(filename, response);
    } catch(error){
      return 1;
    }
  }
}