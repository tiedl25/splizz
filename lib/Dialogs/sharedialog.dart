import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/bloc/detailview_bloc.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/user.model.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogModel(
      content: const Text(
        'Do you want to sign in to share your items and sync them across devices?',
        style: TextStyle(fontSize: 20),
      ),
      onConfirmed: () => Navigator.pushReplacementNamed(context, '/auth'),
      pop: false);
  }
}

class ShareDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit detailViewCubit;

  TextEditingController tfController = TextEditingController();
  bool fullAccess = false;

  Future<void> showLink(state) async {
    User permission = User(
      itemId: state.item.id,
      fullAccess: fullAccess,
      userEmail: tfController.text,
      expirationDate: DateTime.now().add(const Duration(days: 1)));
    final result = await DatabaseHelper.instance.addPermission(permission);

    if (!result.isSuccess)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    else {
      String message = 'You are invited to a Splizz. Accept by opening this link.\n\n';
      Share.share(message + 'https://tmc.tiedl.rocks/splizz?id=${permission.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.detailViewCubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: detailViewCubit,
      builder: (context, state) {
        return DialogModel(
          title: 'Share Splizz',
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: tfController,
                  decoration: TfDecorationModel(
                    context: context,
                    title: 'Email',
                    icon: IconButton(
                      icon: const Icon(Icons.copy),
                      color: Colors.black45,
                      onPressed: () async => showLink(state),
                    ),
                  ),
                  onSubmitted: (value) => {},
                ),
                SizedBox(
                  height: 10,
                ),
                ListTile(
                  title: const Text(
                    'Full Access',
                    style: TextStyle(fontSize: 20),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  trailing: Switch(
                    value: fullAccess,
                    onChanged: ((value) {
                      fullAccess = value;
                      detailViewCubit.toggleCurrency();
                    })
                  ),
                ),
              ]),
            ),
          ),
          onConfirmed: () async => showLink(state),
        );
      },
    );
  }
}
