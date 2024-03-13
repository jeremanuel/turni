import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: FractionallySizedBox(
          widthFactor: 0.8,
          child: Column(children: [
            const Row(
              children: [
                CircleAvatar(backgroundColor: Colors.blue),
                SizedBox(width: 10.0),
                Text("Nunito Bold")
              ],
            ),
            const SizedBox(height: 20.0),
            const Row(
              children: [
                Text("Turnos de Marzo",
                    style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20.0),
            Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                        constraints: const BoxConstraints(minWidth: 35.0),
                        child: const Text("13",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0, color: Colors.white))),
                    const SizedBox(width: 20.0),
                    const Text("Tenis",
                        style: TextStyle(fontSize: 20.0, color: Colors.white)),
                    const Spacer(),
                    const Icon(
                      Icons.sports_tennis_rounded,
                      color: Colors.white,
                    )
                  ],
                )),
            const SizedBox(height: 20.0),
            Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                        constraints: const BoxConstraints(minWidth: 35.0),
                        child: const Text("7",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0, color: Colors.white))),
                    const SizedBox(width: 20.0),
                    const Text("Futbol",
                        style: TextStyle(fontSize: 20.0, color: Colors.white)),
                    const Spacer(),
                    const Icon(
                      Icons.sports_football_rounded,
                      color: Colors.white,
                    )
                  ],
                )),
            const SizedBox(height: 20.0),
            Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                        constraints: const BoxConstraints(minWidth: 35.0),
                        child: const Text("100",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0, color: Colors.white))),
                    const SizedBox(width: 20.0),
                    const Text("Baseball",
                        style: TextStyle(fontSize: 20.0, color: Colors.white)),
                    const Spacer(),
                    const Icon(
                      Icons.sports_baseball_rounded,
                      color: Colors.white,
                    )
                  ],
                )),
            const SizedBox(height: 10.0),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Ver más",
                    style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue)),
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
            )
          ]),
        ));
  }
}
