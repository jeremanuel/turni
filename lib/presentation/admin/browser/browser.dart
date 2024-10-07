import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/date_functions.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/generic_search_item.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/IA_repository.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../session_manager_screen/widgets/session_manager_card.dart';

class Browser extends StatefulWidget {
  const Browser({super.key});

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {

  bool isLoadingData = false;
 
  Timer? searchTimer;
  List<GenericSearchItem> result = [];

  String? prompt;

  final SearchController _searchAnchorController = SearchController();

  final IARepository iaRepository = sl<IARepository>();
  final AdminRepository adminRepository= sl<AdminRepository>();


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildTextfield();
  }

  Widget buildTextfield(){
    return SearchAnchor(
      viewBackgroundColor: Theme.of(context).colorScheme.surfaceBright,
      searchController: _searchAnchorController,
      viewOnSubmitted: (value) {
        onTapSearch();
      },
      viewTrailing: [
        IconButton(onPressed: () => onTapSearch(), icon:const Icon(Icons.send))
      ],
      builder: (context, controller) {
        return SearchBar(
              leading: const Icon(Icons.search),
              hintText: "Clientes o turnos",
              onTap: () => controller.openView(),
            );
      },
      suggestionsBuilder: (context, controller) async {

        const loadingItems = [SizedBox(height: 8), LinearProgressIndicator(), SizedBox(height: 8)];

        return [if(isLoadingData) ...loadingItems, if(result.isNotEmpty) ...buildResult()];

      },
      viewBuilder: (suggestions) {

        return MenuView(
          prompt: prompt ?? '', 
          suggestions:suggestions
        );

      },
      );
  }

  List<Widget> buildResult(){

    DateTime? currentDate;
 
    return result.expand((genericItemSearch){

      final newDate = genericItemSearch.whenOrNull(session: (session) => session.startTime);
      
      bool buildDate = false;

      if(currentDate?.day != newDate?.day){
        buildDate = true;
        currentDate = newDate;
      }

      final widget = genericItemSearch.when(session: buildSession, client: buildClient);

      return [ 

        if(buildDate) 
          Row(
            children: [
              const Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                child: Text(DateFunctions.formatDateToDayMonth(currentDate!)),
              ),
              const Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
            ],
          ), 

        widget
        ];
    }).toList();

  }

  Widget buildClient(Client client) => ListTile(  
      leading: CircleAvatar(
          child: Text(client.person!.fullName.characters.first)
        ),
      subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(client.person!.email != null && client.person!.email!.isNotEmpty) Text(client.person!.email!, overflow: TextOverflow.ellipsis,),
                    if(client.person!.phone != null && client.person!.phone!.isNotEmpty) Text(client.person!.phone!, overflow: TextOverflow.ellipsis)
                  ],
                ),
      title: Text(client.person!.fullName),
    );

  Widget buildSession(Session session) => Container(height: 100, margin: const EdgeInsets.only(bottom: 8), child: SessionManagerCard(session: session, physicalPartition: session.physicalPartition!, onReserve: () => _searchAnchorController.closeView(null)));


  Future onTapSearch() async {
      setState(() {
        isLoadingData = true;
        prompt = _searchAnchorController.text;
      });

      _searchAnchorController.text += " ";

      final iaResult = await searchResultsWithIA(_searchAnchorController.text);

      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      if(iaResult.containsKey("error") && iaResult['error']){

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(iaResult['mensaje']),
        ));

        setState(() {
          result = [];
          isLoadingData = false;
        });

        _searchAnchorController.text = _searchAnchorController.text.substring(0, _searchAnchorController.text.length - 1);

        return;

      }

      final results = await adminRepository.genericSearch(iaResult['busqueda'], RangeDate(from:dateFormat.parse(iaResult['fechaInicio']), to:dateFormat.parse(iaResult['fechaFin'])));

      setState(() {
        result = results;
        isLoadingData = false;
      });

      _searchAnchorController.text = _searchAnchorController.text.substring(0, _searchAnchorController.text.length - 1);

  }

  searchResultsWithIA(String prompt) async {
          
    final result = await iaRepository.getResult(prompt);

    return result;
  }

  Widget buildButtonIcon(){
    return const Icon(Icons.search);
  }
}

class MenuView extends StatefulWidget {

  const MenuView({
    super.key,
    required this.prompt, 
    required this.suggestions,
  });

  final String prompt;
  final Iterable<Widget> suggestions; 

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {

  bool isLoadingData = false;

  void toggleIsLoading() => setState(() { isLoadingData = !isLoadingData; });
  
  @override
  Widget build(BuildContext context) {
    return ListView(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      children: [
     
        SegmentedButton(
          onSelectionChanged: (p0) {
            
          },
          segments: const [
    
            ButtonSegment(value: 1, label: Text("Busqueda inteligente")),
            ButtonSegment(value: 2, label: Text("Busqueda Manual"))
            
          ], 
          selected: const {1}
        ),
        
        
        if(widget.suggestions.length < 1 && widget.prompt.isEmpty) const SizedBox(height: 140, child: Center(child:Text("Realize una busqueda y precione el boton de envio"))),
    
    
        const SizedBox(height: 16,),
    
        ...widget.suggestions
    
      ],
    );
  }
}