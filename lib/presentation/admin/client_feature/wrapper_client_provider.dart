import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../domain/repositories/client/client_session_repository.dart';
import '../../../infrastructure/api/repositories/admin_repository_impl.dart';
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
  void didUpdateWidget(covariant WrapperClientProvider oldWidget) {
    if(oldWidget.clientId != widget.clientId) _initialize();
    
    super.didUpdateWidget(oldWidget);
  }

  void _initialize(){

    client = widget.client;

    if(widget.client == null){
      loadingClient = true;
      sl<AdminRepository>().getClientById(widget.clientId).then((value) {
        value.when(left: (error) {
          // Handle error
          loadingClient = false;
        }, right: (value) => setState(() {
          client = value;
          loadingClient = false;
        })); 
      });
    }
  }

  @override
  void initState() {

    _initialize();

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