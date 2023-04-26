import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:url_launcher/url_launcher.dart';

class SecureStorage {
  final storage = FlutterSecureStorage();

  //Save Credentials
  Future saveCredentials(AccessToken token, String refreshToken) async {
    print(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  //Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved Credentials
  Future clear() {
    return storage.deleteAll();
  }
}

const _clientId = '802052442135-kfeelho298649sd84qh5uqrvd9eu31s9.apps.googleusercontent.com';
const _clientSecret = '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';
const _scopes = ['https://www.googleapis.com/auth/drive'];

class GoogleDrive {
  //Singleton Pattern
  GoogleDrive._privateConstructor();
  static final GoogleDrive instance = GoogleDrive._privateConstructor();
  
  final storage = SecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
          ClientId(_clientId, _clientSecret), _scopes, (url) {
        //Open Url in Browser
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      });
      //Save Credentials
      await storage.saveCredentials(authClient.credentials.accessToken,
          authClient.credentials.refreshToken!);

      return authClient;
    } else if (DateTime.tryParse(credentials["expiry"])!.isBefore(DateTime.now())){

      var accessToken = AccessToken(credentials["type"], credentials["data"],
          DateTime.tryParse(credentials["expiry"])!);

      var accessCredentials = AccessCredentials(accessToken, credentials["refreshToken"], _scopes);

      try {
        var rc = await refreshCredentials(ClientId(_clientId, _clientSecret), accessCredentials, http.Client());
        return authenticatedClient(http.Client(), rc);
      } catch (error){
        print(error);
        storage.clear();
        return getHttpClient();
      }

    } else {
      var accessToken = AccessToken(credentials["type"], credentials["data"],
          DateTime.tryParse(credentials["expiry"])!);

      var accessCredentials = AccessCredentials(accessToken, credentials["refreshToken"], _scopes);
      var authClient = http.Client();
      return authenticatedClient(authClient, accessCredentials);
    }
  }

// check if the directory forlder is already available in drive , if available return its id
// if not available create a folder in drive and return id
//   if not able to create id then it means user authetication has failed
  Future<String?> _getFolderId(gd.DriveApi driveApi, {String folderName='Splizz'}) async {
    const mimeType = "application/vnd.google-apps.folder";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );

      final files = found.files;

      if (files == null) {
        print("Sign-in first Error");
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
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String?> testFilenames(String filename) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);
    String? folderId = await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      var fileList = (await drive.files.list(q: "'$folderId' in parents and trashed=false")).files;
      for (var file in fileList!){
        print(file.name);
        if(file.name == filename){
          return file.id;
        }
      }
    }
    return 'false';
  }

  Future<List> getFilenames() async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);
    String? folderId = await _getFolderId(drive);
    var response = (await drive.files.list(q: 'sharedWithMe=true and trashed=false and not "$folderId" in parents', supportsAllDrives: true, includeItemsFromAllDrives: true)).files;
    var itemlist = [];
    for (var file in response!){
      if((file.name)!.startsWith('item') && await DatabaseHelper.instance.checkSharedId(file.id!)){
        final startIndex = file.name?.indexOf('{');
        final endIndex = file.name?.lastIndexOf('}');
        final substring = file.name?.substring(startIndex!+1, endIndex!);
        itemlist.add([file.name, file.id, substring]);
      }
    }
    return itemlist;
  }

  Future<List> getSharedPeople(String id) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    final about = await drive.about.get($fields: 'user(emailAddress)');
    final userEmail = about.user?.emailAddress;

    final permissions = await drive.permissions.list(id, $fields: "*",);

    List people = [];

    for (var permission in permissions.permissions!) {
      if(permission.emailAddress != userEmail) {
        people.add({'email' : permission.emailAddress, 'name' : permission.displayName});
      }
    }

    return people;
  }

  updateFile(File file, id) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      final updatedFile = gd.File(name: p.basename(file.absolute.path));
      var response = await drive.files.update(
        updatedFile,
        id,
        uploadMedia: gd.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
  }

  addParents(File file, id) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      print(id);
      var f = await drive.files.get(id);
      var updatedFile = gd.File()..name = p.basename(file.absolute.path);
      var a = gd.File(name: p.basename(file.absolute.path), parents: [folderId]);
      var response = await drive.files.update(
        a,
        id,
        addParents: folderId
      );
      print(response);
    }
  }

  Future<String?> uploadFile(File file) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
      return 'false';
    }else {
      gd.File fileToUpload = gd.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: gd.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
      return response.id;
    }
  }

  Future<bool> checkOwner(String fileId) async {
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
  }
  
  Future<File> downloadFile(String fileId, String filename) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    //download ByteStream from GoogleDrive
    gd.Media? response = (await drive.files.get(fileId, downloadOptions: gd.DownloadOptions.fullMedia)) as gd.Media?;
    return FileHandler.instance.writeBytestream(filename, response);
  }
}