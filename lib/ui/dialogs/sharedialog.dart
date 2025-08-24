import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    return CustomDialog(
      content: Text(
        wannaSignIn,
        style: TextStyle(fontSize: 20),
      ),
      onConfirmed: () => Navigator.pushReplacementNamed(context, '/auth'),
      onDismissed: () => cubit.closeShareDialog(),
      pop: false);
  }
}

class ShareDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  TextEditingController tfController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocConsumer<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      listenWhen: (_, current) => current is DetailViewShowSnackBar,
      listener: (context, state) {
        switch (state.runtimeType) {
          case DetailViewShareDialogShowSnackBar:
            showOverlayMessage(
              context: context, 
              message: (state as DetailViewShareDialogShowSnackBar).message,
              backgroundColor: Theme.of(context).colorScheme.primary,
            );
            break;
          case DetailViewShareDialogShowLink:
            Share.share((state as DetailViewShareDialogShowLink).message);
            break;
        }
      },
      buildWhen: (_, current) => current is DetailViewShareDialog,
      builder: (context, state) {
        return CustomDialog(
          pop: false,
          title: shareSplizzDialogTitle,
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
                    title: email,
                    //icon: IconButton(
                    //  icon: const Icon(Icons.copy),
                    //  color: Colors.black45,
                    //  onPressed: () async => cubit.showLink(tfController.text),
                    //),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                ListTile(
                  title: Text(
                    fullAccess,
                    style: TextStyle(fontSize: 20),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  trailing: Switch(
                    value: (state as DetailViewShareDialog).fullAccess,
                    onChanged: (_) => cubit.toggleAccess()
                  ),
                ),
              ]),
            ),
          ),
          onConfirmed: () => cubit.showLink(tfController.text),
          onDismissed: () => cubit.closeShareDialog(),
        );
      },
    );
  }
}
