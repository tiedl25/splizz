import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splizz/Helper/ui_model.dart';

import 'package:splizz/models/item.model.dart';

class ShareDialog extends StatefulWidget {
  final Item item;

  const ShareDialog({
    Key? key,
    required this.item
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ShareDialogState();
  }
}

class _ShareDialogState extends State<ShareDialog>{
  TextEditingController tfController = TextEditingController();
  bool fullAccess = false;

  String generateLink() {
    return 'splizz://de.tmc.splizz?itemId=${widget.item.id}&userEmail=${tfController.text}&fullAccess=$fullAccess';
  }

  @override
  Widget build(BuildContext context) {
    return DialogModel(
            title: 'Share Splizz',
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: tfController,
                      decoration: TfDecorationModel(
                        context: context,
                        title: 'Share by entering the users email address',
                        icon: IconButton(icon: const Icon(Icons.email), color: Colors.black45, onPressed: () => {},),
                      ),
                      onSubmitted: (value) => {},
                    ),
                    SizedBox(height: 10,),
                    TextField(
                      readOnly: false,
                      decoration: TfDecorationModel(
                        context: context,
                        title: 'Create link',
                        icon: IconButton(icon: const Icon(Icons.email), color: Colors.black45, onPressed: () => Clipboard.setData(ClipboardData(text: generateLink())),),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Checkbox(
                      value: fullAccess, 
                      onChanged: ((value) => setState(() {
                        fullAccess = value!;
                      })
                      )
                    )
                  ]
                ),
              ),
            ),
            onConfirmed:  (){

            }
            );
  }
}