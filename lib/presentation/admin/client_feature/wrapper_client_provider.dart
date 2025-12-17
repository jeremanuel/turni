import 'package:flutter/material.dart';

import '../../../domain/entities/client.dart';
import '../client_page/client_page.dart';

class WrapperClientProvider extends StatefulWidget {

  final Client? client;
  final int clientId;
  Widget child;
  Function(Client) onUpdateClient;
    WrapperClientProvider({
    super.key, 
    required this.clientId,
    required this.child,
    this.client,
    required this.onUpdateClient
  });


  @override
  State<WrapperClientProvider> createState() => _WrapperClientProviderState();
}

class _WrapperClientProviderState extends State<WrapperClientProvider> {

  bool loadingClient = false;
  Client? client;
  @override
  void initState() {
    client = widget.client;

    if(widget.client == null){
      loadingClient = true;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    if(loadingClient && client == null){
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClientInherited((newClient) {
      setState(() {
        client = newClient;
        loadingClient = false;
      });
    }, 
    client: client!, child: widget.child);
  }
}