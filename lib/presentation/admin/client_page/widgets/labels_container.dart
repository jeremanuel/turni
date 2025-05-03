
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/label_chip.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../domain/entities/label.dart';
import '../../../../domain/repositories/label_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import '../../states/global_data/global_data_cubit.dart';
import '../client_page.dart';

class LabelsContainer extends StatelessWidget {
  const LabelsContainer({
    super.key,
  });


  onDelete(Label label){

  }


  @override
  Widget build(BuildContext context) {

 
    final textTheme = Theme.of(context).textTheme;

    final client = ClientInherited.of(context)!.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 4,
          children: [
            Text("Etiquetas", style: textTheme.headlineSmall),
            const Tooltip(
              message: "Las etiquetas son una forma de clasificar a los clientes",
              child: Icon(Icons.info_outlined, size: 18),
            )
          ],
        ),
        const SizedBox(height: 24,),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if(client.labels != null && client.labels!.isNotEmpty) ...client.labels!.map((e) => Labelchip(e, onDelete: () => onDelete(e)))
            else const Text("No hay etiquetas cargadas"),
            const SizedBox(
              width: 200,
              child: AddLabelButton()
            )
          ],
        )
      ],
    );
    
  }
}



class AddLabelButton extends StatefulWidget {
  const AddLabelButton({super.key});

  @override
  State<AddLabelButton> createState() => _AddLabelButtonState();
}

class _AddLabelButtonState extends State<AddLabelButton> {

  final DropdownController _dropdownController = DropdownController();
  final LabelRepository _labelRepository = sl<LabelRepository>();

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      menuWidget: AddLabelContainer(
        onSelectLabel: (label) async {
          
          final client = ClientInherited.of(context)!.client;

          final labelResponse = await _labelRepository.addLabelToClient(client.intClientId, label.toJson());
          
          labelResponse.when(
            left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message), 
            right: (createdLabel) {

               ClientInherited.of(context)!.updateClient(client.copyWith(labels: [...client.labels!, createdLabel]));

               if(label.labelId == -1) sl<GlobalDataCubit>().addLabel(createdLabel);
               
            },
          );

          _dropdownController.hide!();
          
        },
      ), 
      dropdownController: _dropdownController,
      child: TextButton(onPressed: () => _dropdownController.show!(), child: const Row(spacing: 4, children: [Icon(Icons.add), Text("Agregar etiqueta")]))
    );
  }
}

class AddLabelContainer extends StatefulWidget {
  const AddLabelContainer({
    super.key, required this.onSelectLabel,
  });

  final Function(Label) onSelectLabel;


  @override
  State<AddLabelContainer> createState() => _AddLabelContainerState();
}

class _AddLabelContainerState extends State<AddLabelContainer> {

  String? search;
  String labelName = "";
  AnimationController? _animationController;
  final ScrollController _scrollController = ScrollController();

  bool isCreatingNew = false;
  Color? pickedColor;
  final GlobalKey<FormBuilderFieldState> _textfieldKey = GlobalKey<FormBuilderFieldState>();

  @override
  void initState() {
    pickedColor = labelColors[3];
    super.initState();
  }

var options = sl<GlobalDataCubit>().state.labels.data ?? [];

List<Color> labelColors = [
  Colors.redAccent,
  Colors.pinkAccent,
  Colors.orangeAccent,
  Colors.amberAccent,
  Colors.yellowAccent,
  Colors.limeAccent,
  Colors.lightGreenAccent,
  Colors.greenAccent,
  Colors.tealAccent,
  Colors.cyanAccent,
  Colors.lightBlueAccent,
  Colors.blueAccent,
  Colors.indigoAccent,
  Colors.deepPurpleAccent,
  Colors.purpleAccent,
  const Color(0xFFFFA07A), // Light Salmon
  const Color(0xFFFFD700), // Gold
  const Color(0xFFFFE4B5), // Moccasin
  const Color(0xFF98FB98), // Pale Green
  const Color(0xFF00FA9A), // Medium Spring Green
  const Color(0xFF87CEFA), // Light Sky Blue
  const Color(0xFF4682B4), // Steel Blue
  const Color(0xFF7B68EE), // Medium Slate Blue
  const Color(0xFFDDA0DD), // Plum
  const Color(0xFFFF69B4), // Hot Pink
  const Color(0xFFFFB6C1), // Light Pink
  const Color(0xFFDB7093), // Pale Violet Red
  const Color(0xFFFFDAB9), // Peach Puff
  const Color(0xFFF5DEB3), // Wheat
  const Color(0xFFFFA500), // Orange
];

  



  Widget buildNewLabelForm(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: (){
                  search = "";
                  isCreatingNew = false;
                  setState(() {});
                  _animationController?.reverse();
                }, 
                icon: const Icon(Icons.arrow_back)
              ),
              Text("Nueva Etiqueta", style: Theme.of(context).textTheme.titleLarge,),
            ],
          ),
        ),
        const Divider(
          height: 1
        ),
        FormBuilderTextField(
          initialValue: labelName,
          key: _textfieldKey,
          name: "name",
          autovalidateMode: AutovalidateMode.always,
          validator: (value){
            if(value?.isEmpty ?? true) return "Nombre requerido";

            if(value!.length < 3) return "Minimo 3 Caracteres";

            if(value.length > 30) return "Maximo 30 caracteres";

            return null;
          },
          //controller: _textEditingController,
          onChanged: (value) => setState(() => labelName = value ?? ''),
          decoration: const InputDecoration(
            filled: true,
            labelText: "Nombre",
            helperText: ""
          ),  
        ),
        const SizedBox(height: 4),
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 70,
            child: ListView.separated(
              controller: _scrollController,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: labelColors.length,
              scrollDirection: Axis.horizontal,
          
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: pickedColor == labelColors[index]? Border(top:  BorderSide(color: Theme.of(context).colorScheme.primary))  : null
                  ),
                  width: 40,
                  child: Center(
                    child: ColorItem(
                      isSelected: pickedColor == labelColors[index],
                      color: labelColors[index], 
                      onTap: (){
                        pickedColor = labelColors[index];
                        setState(() {});
                      }
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height:4),
        const Divider(height: 1),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vista previa", style: Theme.of(context).textTheme.titleMedium,),
              Labelchip(Label(-1, labelName, pickedColor, sl<AuthCubit>().getClubId()))
            ],
          )),
          const SizedBox(height: 8),
          const Divider(height: 1,),
          SizedBox(
            height: 60,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: (){
                      search = "";
                      isCreatingNew = false;
                      setState(() {});
                      _animationController?.reverse();
                    },
                    child: const Text("Cancelar")
                  ),
                  FilledButton(onPressed:(_textfieldKey.currentState?.isValid ?? false) ? (){
                    widget.onSelectLabel(
                      Label(-1, labelName, pickedColor, sl<AuthCubit>().getClubId())
                    );
                  } : null, child: const Text("Crear")),
                  const SizedBox(width: 8,)
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget buildList(){

    final listToUse = search?.isEmpty ?? true ? options : options.where((element) => element.value.toLowerCase().contains(search!.toLowerCase())).toList();

    return Column(
        children: [
          Container(
            color:Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SearchBar(
              autoFocus: true,
              hintText: "Buscar Etiqueta",
              onChanged: (value) => setState(() {
                search = value;
              }),
            ),
          ),
          Divider(
              height: 1,
              color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: listToUse.isEmpty ? buildNoLabels() : ListView.separated(
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 1,
                );
              },
              itemCount: listToUse.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    widget.onSelectLabel(listToUse[index]);
                  },
                  title: Container(
                    alignment: Alignment.centerLeft,
                    child: Labelchip(listToUse[index])),
                );
              },
            ),
          ),
          const Divider(height: 1,),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,

            ),
            height: 60, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: (){

                    setState(() {
                      isCreatingNew = true;
                    });
                    _animationController?.forward();

                    
                }, child: const Text("Crear Etiqueta")),
              ],
            ),
          )
        ],
      );
  }

  Widget buildNoLabels() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("No hay etiquetas ${(search?.isNotEmpty ?? false) ? "para la busqueda $search" : ""}"),
      if(search?.isNotEmpty ?? false) 
      TextButton(
        onPressed: (){
          isCreatingNew = true;
          setState(() {});
          labelName = search!;
          _animationController?.forward();
        }, 
        child: Text("Crear etiqueta $search"))
    ],
  );




  @override
  Widget build(BuildContext context) {
    
    return SizedBox(
      child: !isCreatingNew ? buildList() : buildNewLabelForm().animate().moveX(),
    )
    .animate(onInit: (controller) => _animationController = controller, autoPlay: false)
    .custom(
      curve: Curves.ease,
      begin: 500,
      end: 350,
      builder: (context, value, child) {
        
        return SizedBox(
          width: 300,
          height: value,
          child: child,
        );

    });
  }
}

class ColorItem extends StatelessWidget {
    const ColorItem({
    super.key, 
    required this.color,
    required this.onTap, required this.isSelected
  });


  final Color color;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        
        decoration: BoxDecoration(
          border: isSelected ? Border.all(
            width: 2,
            color: Colors.white
          ) : null,
          color: color
        ),
        height: isSelected ? 40 : 40,
        width: isSelected ? 40 : 40,
                   
      ),
    );
  }
}
