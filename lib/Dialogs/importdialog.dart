import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Helper/drive.dart';

class ImportDialog extends StatefulWidget {
  final Function setParentState;

  const ImportDialog({
    Key? key,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ImportDialogState();
  }
}

class _ImportDialogState extends State<ImportDialog>{
  final List<Map> _filenameList = [];
  int _selection = -1; //true means items is in shared list, false means in saved list

  @override
  void initState(){
    super.initState();
  }

  Future<List<Map>> _fetchData() async {
    List<Map>? sharedList = await GoogleDrive.instance.getFilenames();
    var savedList = await GoogleDrive.instance.getFilenames(owner: true);

    if(sharedList != null && savedList != null)
    {
      if(sharedList.isNotEmpty){
        _filenameList.add({'name' : "Shared with me"});
        _filenameList.addAll(sharedList);
      }
      if(savedList.isNotEmpty){
        _filenameList.add({'name' : "Saved by me"});
        _filenameList.addAll(savedList);
      }
    }
    return _filenameList;
  }



  @override
  Widget build(BuildContext context) {
      return DialogModel(
          title: 'Import Splizz',
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder(
              future: _fetchData(),
              builder: (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
                if (!snapshot.hasData){
                  return const Center(
                      child: CircularProgressIndicator(),
                  );
                }
                else {
                  return snapshot.data!.isEmpty ?
                  Container(
                    margin: const EdgeInsets.all(5),
                    child: const Text('No items available. Make sure that there are items shared with you.', style: TextStyle(fontSize: 20)),
                  ) :
                  SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children:
                        //_sharedList.isNotEmpty ? const Text('Shared with me', style: TextStyle(color: Colors.white, fontSize: 20),) : const Text(''),
                        List.generate(
                            _filenameList.length,
                                (i) {
                              Color color = _selection==i ? Theme.of(context).colorScheme.surfaceTint : Theme.of(context).colorScheme.surface;
                              Color textColor = color.computeLuminance() > 0.3 ? Colors.black : Colors.white;

                              if(!_filenameList[i].containsKey('path')){
                                return Container(
                                  margin: const EdgeInsets.all(5),
                                  child: Text(_filenameList[i]['name'] ,style: const TextStyle(fontSize: 20),),
                                );
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                  ),
                                  title: Text(_filenameList[i]['name'], style: TextStyle(fontSize: 20, color: textColor),),
                                  tileColor: Theme.of(context).colorScheme.surface,
                                  selected: _selection==i,//_isSelected[i],
                                  selectedTileColor: Theme.of(context).colorScheme.surfaceTint,
                                  onTap: (){
                                    setState(() {
                                      _selection = i;
                                    });
                                  },
                                ),
                              );
                            }
                        ),
                      ),
                    );
                }
              },
            ),
          ),
          onConfirmed: () async {
            if (_selection != -1){
              var f = _filenameList[_selection];
              try{
                var file = await GoogleDrive.instance.downloadFile(f['id'], f['path']);
                var imageFile = await GoogleDrive.instance.downloadFile(f['imageId'], '${f['path']}_image');
                await DatabaseHelper.instance.import(file.path, f['id'], imageFile.path, f['imageId']);

                //GoogleDrive.instance.addParents(file, item.sharedId);
                FileHandler.instance.deleteFile(file.path);
                FileHandler.instance.deleteFile(imageFile.path);
              } catch(_){
                showDialog(context: context, builder: (BuildContext){
                  return ErrorDialog('Import Error');
                });
              }
              widget.setParentState(() {});
            }
          }
        );
    }
}