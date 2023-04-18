import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/item.dart';


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

      var rc = await refreshCredentials(ClientId(_clientId, _clientSecret), accessCredentials, http.Client());

      return authenticatedClient(http.Client(), rc);

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
  Future<String?> _getFolderId(ga.DriveApi driveApi, {String folderName='Splizz'}) async {
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
      ga.File folder = ga.File();
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
    var drive = ga.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
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
    var drive = ga.DriveApi(client);
    var response = (await drive.files.list(q: 'sharedWithMe=true and trashed=false', supportsAllDrives: true, includeItemsFromAllDrives: true)).files;
    var itemlist = [];
    for (var file in response!){
      if((file.name)!.startsWith('item_') && (file.name)!.endsWith('.json')){
        final startIndex = file.name?.indexOf('{');
        final endIndex = file.name?.lastIndexOf('}');
        final substring = file.name?.substring(startIndex!+1, endIndex!);
        itemlist.add([file.name, file.id, substring]);
      }
    }
    return itemlist;
  }

  updateFile(File file, id) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      ga.File fileToUpload = ga.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      final updatedFile = ga.File()..name = p.basename(file.absolute.path);
      var response = await drive.files.update(
        updatedFile,
        id,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
  }

  uploadFile(File file) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      ga.File fileToUpload = ga.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
  }
  
  downloadFile(String fileId, String filename) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);

    //download ByteStream from GoogleDrive
    ga.Media? response = (await drive.files.get(fileId, downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media?;

    //check if sharedWithMe directory exists
    var directory = await getApplicationSupportDirectory();
    directory = Directory('${directory.path}/sharedWithMe');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final saveFile = File('${directory.path}/$filename');

    //save response ByteStream to file
    List<int> dataStore = [];
    response?.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      saveFile.writeAsBytes(dataStore);
      print("File saved at ${saveFile.path}");
    }, onError: (error) {
      print("Some Error");
    });
  }
}