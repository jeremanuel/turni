import 'package:flutter/material.dart';


class SnackbarsFunctions {
  static void showErrorsSnackbar(BuildContext context, String error){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          margin: EdgeInsets.only(left: 1600, bottom: 16),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer,),
              const SizedBox(width: 8,),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),)
            ],
          )
      )
    );
  }

    static void showSuccessSnackbar(BuildContext context, String error){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          width: 500,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimaryContainer,),
              const SizedBox(width: 8,),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),)
            ],
          )
      )
    );
  }




}