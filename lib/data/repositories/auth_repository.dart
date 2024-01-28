import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:turni/domain/models/user.dart';

class AuthRepository {
  static Future signInGoogle() async {
    //Default definition
    GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
    );


  
  //If current device IOS or MacOS, We have to declare clientID
  //Please, look STEP 2 for how to get Client ID for IOS

    final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
    
    //If you want further information about Google accounts, such as authentication, use this.
    final GoogleSignInAuthentication googleAuthentication =
        await googleAccount!.authentication;
  }

  Future _createUserDocument(User user) async {
/*     FirebaseFirestore firestore = FirebaseFirestore.instance;

    final userDocRef = firestore
        .collection('users').doc(user.uid);

     await userDocRef.set({
      "name":user.displayName,
      "picture":user.photoURL,
      "email":user.email,
      "phoneNumber":user.phoneNumber
     }); */
  }

  Future checkAuthStatus() async {
/*     String? token = await LocalStorage.read(LocalStorage.TOKEN_KEY);
    
    if(token == null) return null;

    String? userCreds =  await LocalStorage.read(LocalStorage.USER_CRED_KEY);
 */
  }
}
