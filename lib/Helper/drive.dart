import 'dart:async';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:splizz/Helper/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

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
          launch(
            url,
            customTabsOption: CustomTabsOption(
              enableUrlBarHiding: false,
              enableInstantApps: true,
              closeButtonPosition: CustomTabsCloseButtonPosition.end,
              showPageTitle: true,
            )
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
  Future<String> _getFolderId(gd.DriveApi drive, {String folderName='Splizz'}) async {
    const mimeType = "application/vnd.google-apps.folder";

    final files = (await drive.files.list(q: "mimeType = '$mimeType' and name = '$folderName'", $fields: "files(id, name)")).files;

    // The folder already exists
    if (files!.isNotEmpty) {
      return files.first.id!;
    }

    // Create a folder
    gd.File folder = gd.File();
    folder.name = folderName;
    folder.mimeType = mimeType;
    final folderId = (await drive.files.create(folder)).id;
    return folderId!;
  }

  // return all filenames that are related to splizz items
  Future<List<Map>> getFilenames({owner=false}) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);
    String folderId = await _getFolderId(drive);
    List<gd.File>? response = owner ? (await drive.files.list(q: 'trashed=false and "$folderId" in parents', supportsAllDrives: true, includeItemsFromAllDrives: true, $fields: "*")).files :
    (await drive.files.list(q: 'sharedWithMe=true and trashed=false and not "$folderId" in parents', supportsAllDrives: true, includeItemsFromAllDrives: true, $fields: "*")).files;

    List<Map> itemlist = [];
    for (var file in response!){
      if((file.name)!.startsWith('splizz_item') && await DatabaseHelper.instance.checkSharedId(file.id!)){
        itemlist.add({'path' : file.name, 'id' : file.id, 'name' : file.properties?['itemName'], 'imageId' : file.properties?['imageId']});
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
        people.add({'email' : permission.emailAddress, 'name' : permission.displayName, 'id' : permission.id});
      }
    }
    return people;
  }

  Future<Map> addPeople(String fileId, String email) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    var permission = gd.Permission(emailAddress: email, role: 'writer', type: 'user');

    permission = await drive.permissions.create(permission, fileId, sendNotificationEmail: false, $fields: '*');
    return {'email' : permission.emailAddress, 'name' : permission.displayName, 'id' : permission.id};
  }

  Future removePeople(String fileId, String permissionId) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    await drive.permissions.delete(fileId, permissionId);
  }

  Future updateFile(File file, id) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    final updatedFile = gd.File(name: path.basename(file.absolute.path));
    try{
      await drive.files.update(updatedFile, id, uploadMedia: gd.Media(file.openRead(), file.lengthSync()));
    }catch(e){
      return 0;
    }
    return 1;
  }


  Future<String?> uploadFile(File file, [String? itemName, String? imageId]) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    String folderId =  await _getFolderId(drive);

    gd.File fileToUpload = gd.File(parents: [folderId], name: path.basename(file.absolute.path), properties: {});

    if(itemName != null) fileToUpload.properties?.addAll({'itemName' : itemName});
    if(imageId != null) fileToUpload.properties?.addAll({'imageId' : imageId});

    return (await drive.files.create(fileToUpload, uploadMedia: gd.Media(file.openRead(), file.lengthSync()))).id;
  }

  Future deleteFile(String fileId) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    drive.files.delete(fileId);
  }

  Future<bool> lastModifiedByMe(String fileId) async {
    var client = await getHttpClient();
    var drive = gd.DriveApi(client);

    gd.File file = (await drive.files.get(fileId, $fields: "lastModifyingUser")) as gd.File;
    return file.lastModifyingUser?.me ?? false;
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