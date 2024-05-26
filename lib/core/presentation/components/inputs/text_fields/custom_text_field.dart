import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../utils/responsive_builder.dart';
import '../inputs_decorations.dart';

class CustomTextField extends StatefulWidget {
  CustomTextField(
    BuildContext context,
    {
    super.key, 
    this.name, 
    // this.compact = false, 
    this.style = InputStyle.outlined, 
    required this.labelText, 
    this.enabled = true, 
    this.onChanged, 
    this.leadingIcon, 
    this.trailingIcon, 
    this.supportingText, 
    this.placeHolder, 
    this.validator, 
    this.variableWidth = true, 
    this.autovalidateMode = AutovalidateMode.onUserInteraction, 
    this.prefixText, 
    this.suffixText, 
    this.inputAlignRight = false, 
    this.initialValue, 
    this.inputFormatter,
  }){
    assert(name == null || initialValue == null, 'initialValue no es usado si se especifica name.');
    compact = ResponsiveBuilder.isDesktop(context) ? true : false;
  }

  final void Function(String?)? onChanged;
  final bool enabled;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  
  /// [name] es utilizado para identificar el textfield en el formbuilder.
  /// Si no se especifica, no se agrega el campo al formbuilder.
  final String? name;

  /// [initialValue] Valor inicial del textfield.
  /// Si se especifica [name] este campo no se utiliza.
  final String? initialValue;

  /// [compact] Si esta en true el textfield se muestra mas pequeño.
  late bool compact; //Esta seguramente se maneje internamente respecto al dispositivo. Por ahora asi como esta.

  /// [variableWidth] Si esta en true el ancho del textfield se adapta al contenido. Si es false toma un ancho fijo.
  final bool variableWidth;
  
  /// [style] Define el estilo del textfield. TODO: A definir.
  final InputStyle style;

  /// [leadingIcon] Icono que se muestra a la izquierda del textfield.
  final IconData? leadingIcon;  

  /// [trailingIcon] Icono que se muestra a la derecha del textfield.
  final IconData? trailingIcon; 

  /// [supportingText] Texto que se muestra debajo del textfield.
  final String? supportingText;

  /// [labelText] Texto que se muestra arriba del textfield.
  final String labelText;

  /// [placeHolder] Texto que se muestra dentro del textfield cuando el input es nulo.
  final String? placeHolder;

  /// [prefixText] Texto que se muestra a la izquierda del input.
  final String? prefixText;

  /// [suffixText] Texto que se muestra a la derecha del input.
  final String? suffixText;

  /// [inputAlignRight] Si esta en true el texto del input se alinea a la derecha.
  final bool inputAlignRight;


  final inputFormatter;
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {

  @override
  void initState() {
    super.initState();
    _initDecoration(context);
    initialValue = ( widget.name != null ) ? (FormBuilder.of(context)?.initialValue[widget.name]) : widget.initialValue;
  }
  @override
  void dispose() {
    super.dispose();
  }

  late String? initialValue;

  late InputDecoration Function() getInputDecoration;

  late TextStyle textInputStyle;

  late Color Function() cursorColor;

  late Set<MaterialState> states = (widget.enabled) ? <MaterialState>{} : <MaterialState>{MaterialState.disabled};

  late double? width;

  late double height;

  late bool expands;

  String? errorText;

  @override
  Widget build(BuildContext context) {
    if (widget.enabled && states.contains(MaterialState.disabled)) {
      states.remove(MaterialState.disabled);
    } else if( !widget.enabled && !states.contains(MaterialState.disabled) ){
      states.add(MaterialState.disabled);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: width, 
          child: textField(),
        ),
        supportingErrorContainer( context, states, errorText, widget.supportingText ),
      ],
    );
    // return textField();
  }

  Widget textField(){ 

    TextFormField textInput({
      FormFieldState? field,
    }) => TextFormField(
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      expands: expands,
      maxLines: null,
      // cursorColor: cursorColor(),
      inputFormatters: widget.inputFormatter,
      initialValue: initialValue,
      onChanged: (value){
        widget.onChanged?.call(value);
        field?.didChange(value);
      },
      decoration: getInputDecoration(),
      style: textInputStyle,
      enabled: widget.enabled,
      textAlign: (widget.inputAlignRight) ? TextAlign.right : TextAlign.left,
    );

    if( widget.name == null ) return textInput();
    
    return FormBuilderField(
      name: widget.name!,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (FormFieldState field) => 
        textInput(field: field), 
    );

  }


  _initDecoration(BuildContext context) {
    Map<String,dynamic> options = getInputOptions(
      context: context,
      style: widget.style,
      labelText: widget.labelText,
      supportingText: null,
      compact: widget.compact,
      variableWidth: widget.variableWidth,
      currentStates: states,
      leadingIcon: widget.leadingIcon,
      trailingIcon: widget.trailingIcon,
      placeHolder: widget.placeHolder,
      suffixText: widget.suffixText,
      prefixText: widget.prefixText,
      inputAlignRight: widget.inputAlignRight,
      errorText: errorText,
    );
    
    textInputStyle = options['textInputStyle'];
    getInputDecoration = options['inputDecoration'];
    // cursorColor = options['cursorColor'];
    width = options['width'];
    height = options['height'];
    expands = options['expands'];
  }
}