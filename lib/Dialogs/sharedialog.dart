import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/Helper/ui_model.dart';

import 'package:splizz/models/item.model.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogModel(
      content: const Text('Do you want to sign in to share your items and sync them across devices?', style: TextStyle(fontSize: 20),),
      onConfirmed: () => Navigator.pushReplacementNamed(context, '/auth'),
      pop: false
    );
  }
}

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
    String message = 'You are invited to a Splizz. Accept by opening this link.\n\n';
    return message + 'splizz://de.tmc.splizz?itemId=${widget.item.id}&userEmail=${tfController.text}&fullAccess=$fullAccess';
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
                        title: 'Email',
                        icon: IconButton(icon: const Icon(Icons.copy), color: Colors.black45, onPressed: () => {Share.share(generateLink())},),
                      ),
                      onSubmitted: (value) => {},
                    ),
                    SizedBox(height: 10,),
                    ListTile(
                      title: const Text('Full Access', style: TextStyle(fontSize: 20),),
                      contentPadding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      trailing: Switch(
                        value: fullAccess, 
                        onChanged: ((value) => setState(() {
                          fullAccess = value;
                        })
                        )
                      ),
                    ),
                  ]
                ),
              ),
            ),
            onConfirmed:  () => Share.share(generateLink())
            );
  }
}