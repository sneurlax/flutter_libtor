// Example app deps, not necessarily needed for tor usage.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socks5_proxy/socks_client.dart'; // Just for example; can use any socks5 proxy package, pick your favorite.
// Imports needed for tor usage:
import 'package:tor/tor.dart';
import 'package:tor_example/socks_socket.dart'; // For socket connections.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Instantiate a Tor object.
  final tor = Tor();

  // Flag to track if tor has started.
  bool torStarted = false;

  // Set the default text for the host input field.
  final hostController = TextEditingController(text: 'https://icanhazip.com/');
  // https://check.torproject.org is another good option.

  @override
  void initState() {
    super.initState();
    unawaited(init());
  }

  Future<void> init() async {
    // Get the app's documents directory.
    final Directory appDocDir = await getApplicationDocumentsDirectory();

    // Start the Tor daemon.
    await tor.start();

    // Toggle started flag.
    setState(() {
      torStarted = true; // Update flag
    });

    print('Done awaiting; tor should be running');
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    hostController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    // Start the Tor daemon
    _torConfig = await tor.start(torDir: Directory('${appDocDir.path}/tor'));
    _password = _torConfig.password;
    print('done awaiting; tor should be running');
  }

  @override
  Widget build(BuildContext context) {
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
                Row(children: [
                  // Host input field.
                  Expanded(
                    child: TextField(
                        controller: hostController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Host to request',
                        )),
                  ),
                  spacerSmall,
                  AbsorbPointer(
                    absorbing: !torStarted, // Disable if tor hasn't started
                    child: TextButton(
                      onPressed: () async {
                        // `socks5_proxy` package example, use another socks5
                        // connection of your choice.

                        // Create HttpClient object
                        final client = HttpClient();

                        // Assign connection factory.
                        SocksTCPClient.assignToHttpClient(client, [
                          ProxySettings(InternetAddress.loopbackIPv4, tor.port,
                              password:
                                  null), // TODO Need to get from tor config file.
                        ]);

                        // GET request.
                        final request =
                            await client.getUrl(Uri.parse(hostController.text));
                        final response = await request.close();

                        // Print response.
                        var responseString = await utf8.decodeStream(response);
                        print(responseString);
                        // If host input left to default icanhazip.com, a Tor
                        // exit node IP should be printed to the console.
                        //
                        // https://check.torproject.org is also good for
                        // doublechecking torability.

                        // Close client
                        client.close();
                      },
                      child: const Text("Make proxied request"),
                    ),
                  ),
                ]),
                spacerSmall,
                AbsorbPointer(
                  absorbing: !torStarted, // Disable if tor hasn't started
                  child: TextButton(
                      onPressed: () async {
                        // Instantiate a socks socket at localhost and on the port selected by the tor service.
                        var socksSocket = await SOCKSSocket.create(
                          proxyHost: InternetAddress.loopbackIPv4.address,
                          proxyPort: tor.port,
                        );

                        // Connect to the socks instantiated above.
                        await socksSocket.connect();

                        // Connect to bitcoincash.stackwallet.com on port 50001 via socks socket.
                        await socksSocket.connectTo(
                            'bitcoincash.stackwallet.com', 50001);

                        // Send a server features command to the connected socket, see method for more specific usage example..
                        await socksSocket.sendServerFeaturesCommand();
                        await socksSocket.close();
                      },
                      child: const Text(
                          "Connect to bitcoincash.stackwallet.com:50001")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
