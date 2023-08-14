// example app deps, not necessarily needed for tor usage
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_libtor/flutter_libtor.dart';
// imports needed for tor usage:
import 'package:flutter_libtor/models/tor_config.dart';
import 'package:flutter_libtor_example/socks_socket.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socks5_proxy/socks_client.dart'; // just for example; can use any socks5 proxy package, pick your favorite.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final tor = Tor();
  late TorConfig _torConfig;
  late String? _password;
  // final portController = TextEditingController();
  // final passwordController = TextEditingController();
  final hostController = TextEditingController(text: 'https://icanhazip.com/');

  @override
  void initState() {
    unawaited(init());
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    // portController.dispose();
    // passwordController.dispose();
    hostController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    // int newControlPort = await tor.getRandomUnusedPort(
    //     excluded: [/*int.parse(portController.text)*/]);
    // TorConfig torConfig = new TorConfig(
    //     dataDirectory: appDocDir.path + '/tor',
    //     logFile: appDocDir.path + '/tor/tor.log',
    //     socksPort: int.parse(portController.text),
    //     controlPort: newControlPort,
    //     password: passwordController.text);

    // Start the Tor daemon
    _torConfig = await tor.start(torDir: Directory('${appDocDir.path}/tor'));
    _password = _torConfig.password;
    print('done awaiting; tor should be running');
  }

  @override
  Widget build(BuildContext context) {
    // const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tor example'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                //     // TODO add password input and start button to start Tor daemon with password input
                //     const Text(
                //       'Enter the port and password of your Tor daemon/SOCKS5 proxy and press connect'
                //       'See the console logs for your port or ~/Documents/tor/tor.log',
                //       style: textStyle,
                //       textAlign: TextAlign.center,
                //     ),
                //     spacerSmall,
                //     Row(children: [
                //       TextButton(
                //           onPressed: () async {
                //             getPort();
                //           },
                //           child: Text("generate unused port")),
                //       spacerSmall,
                //       Expanded(
                //         child: TextField(
                //             controller: portController,
                //             decoration: const InputDecoration(
                //               border: OutlineInputBorder(),
                //               hintText: 'SOCKS5 proxy port',
                //             )),
                //       ),
                //     ]),
                //     Row(children: [
                //       TextButton(
                //           onPressed: () async {
                //             getPassword();
                //           },
                //           child: Text("generate password")),
                //       spacerSmall,
                //       Expanded(
                //         child: TextField(
                //             controller: passwordController,
                //             decoration: const InputDecoration(
                //               border: OutlineInputBorder(),
                //               hintText: 'password',
                //             )),
                //       ),
                //     ]),
                //     spacerSmall,
                // TextButton(
                //     onPressed: () async {
                //       final Directory appDocDir =
                //           await getApplicationDocumentsDirectory();
                //       int newControlPort = await this.tor.getRandomUnusedPort(
                //           excluded: [int.parse(portController.text)]);
                //
                //       TorConfig torConfig = new TorConfig(
                //           dataDirectory: appDocDir.path + '/tor',
                //           logFile: appDocDir.path + '/tor/tor.log',
                //           socksPort: int.parse(portController.text),
                //           controlPort: newControlPort,
                //           password: passwordController.text);
                //
                //       // Start the Tor daemon
                //       await this
                //           .tor
                //           .start(torDir: Directory(appDocDir.path + '/tor'));
                //       print('done awaiting');
                //     },
                //     child: Text("start tor")),
                // spacerSmall,
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: hostController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'host to request',
                        )),
                  ),
                  spacerSmall,
                  TextButton(
                      onPressed: () async {
                        // socks5_proxy package example; use socks5 connection of your choice
                        // Create HttpClient object
                        final client = HttpClient();

                        // Assign connection factory
                        SocksTCPClient.assignToHttpClient(client, [
                          ProxySettings(InternetAddress.loopbackIPv4, tor.port,
                              password:
                                  _password), // need to get from tor config file
                        ]);

                        // GET request
                        final request =
                            await client.getUrl(Uri.parse(hostController.text));
                        final response = await request.close();
                        // Print response
                        var responseString = await utf8.decodeStream(response);
                        print(
                            responseString); // if host input left to default icanhazip.com, a Tor exit node IP should be printed to the console

                        // Close client
                        client.close();
                      },
                      child: const Text("make proxied request")),
                ]),
                spacerSmall,
                TextButton(
                    onPressed: () async {
                      // TODO check that tor is running'
                      SOCKSSocket socksSocket = SOCKSSocket(
                          host: InternetAddress.loopbackIPv4.address,
                          port: tor.port);
                      try {
                        await socksSocket.connect();
                      } catch (e) {
                        print(e);
                      }
                      try {
                        await socksSocket.connectTo(
                            'bitcoincash.stackwallet.com', 50001);
                      } catch (e) {
                        print(e);
                      }
                      // TODO request server features
                    },
                    child: const Text(
                        "connect to bitcoincash.stackwallet.com:50002")),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // getPort() async {
  //   portController.text = "${await this.tor.getRandomUnusedPort()}";
  // }
  //
  // getPassword() async {
  //   passwordController.text = "${await this.tor.generatePassword()}";
  // }
}
