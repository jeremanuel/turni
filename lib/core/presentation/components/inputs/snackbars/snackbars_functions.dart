import 'package:flutter/material.dart';


class SnackbarsFunctions {
  static void showErrorsSnackbar(BuildContext context, String error){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          
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