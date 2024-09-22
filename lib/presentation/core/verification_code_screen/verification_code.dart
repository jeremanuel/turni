import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCode extends StatelessWidget {
  VerificationCode({super.key});

  final _controller = TextEditingController();

  get handleSend => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color.fromRGBO(189, 163, 246, 1),
            Color.fromRGBO(103, 43, 234, 1)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Código de verificación",
              style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            ),
            Form(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InputOneChar(),
                  InputOneChar(),
                  InputOneChar(),
                  InputOneChar(),
                ],
              ),
            ),
            SendButton()
          ],
        ),
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key});

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);

    return MaterialButton(
        elevation: 0,
        color: whiteColor,
        height: 50,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: whiteColor,
          ),
          borderRadius: BorderRadius.circular(40.0),
        ),
        onPressed: () {},
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Enviar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(159, 121, 242, 1),
              ),
            ),
          ],
        ));
  }
}

class InputOneChar extends StatelessWidget {
  const InputOneChar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      width: 64,
      child: TextFormField(
        onSaved: (value) {},
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
        decoration: const InputDecoration(hintText: "0"),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}
