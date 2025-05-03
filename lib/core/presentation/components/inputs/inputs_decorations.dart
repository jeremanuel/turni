
import 'package:flutter/material.dart';

Map<String, dynamic> getInputOptions({
  required BuildContext context,
  required InputStyle style,
  required String labelText,
  required String? supportingText,
  required bool compact,
  required bool variableWidth,
  FocusNode? focusNode,
  required IconData? trailingIcon,
  required IconData? leadingIcon,
  required String? placeHolder,
  required bool inputAlignRight,
  required String? prefixText,
  required String? suffixText,
  required String? errorText,
  Function()? onTrailIconTap,
  required Set<WidgetState> currentStates,
  MouseCursor cursor = SystemMouseCursors.text,
}) {
  InputDecoration getInputDecoration(
      {required InputBorder border, Color? fillColor}) {
    return InputDecoration(
      isDense: compact,
      fillColor: fillColor,
      filled: fillColor != null,

      // floatingLabelStyle: MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
      //   return BodyTextStyleSmall(
      //     color: (states.contains(MaterialState.disabled))
      //         ? AppTheme.colors(context).onSurface.withOpacity(0.38)
      //         : (currentStates.contains(MaterialState.error))
      //             ? AppTheme.colors(context).error
      //             : ( states.contains(MaterialState.focused) || currentStates.contains(MaterialState.focused) )
      //               ? AppTheme.colors(context).primary
      //               :AppTheme.colors(context).onSurfaceVariant,
      //     ).copyWith(height: 0.3);
      // }),
      
      labelText: labelText,
      // labelStyle: MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
      //   return BodyTextStyleSmall(
      //     color: (states.contains(MaterialState.disabled))
      //         ? AppTheme.colors(context).onSurface.withOpacity(0.38)
      //         : (currentStates.contains(MaterialState.error))
      //             ? AppTheme.colors(context).error
      //               :AppTheme.colors(context).onSurfaceVariant,
      //     ).copyWith(height: 0.3);
      // }),

        hintText: placeHolder,
        
        prefixText: prefixText,
        // prefixStyle: (( compact ) ? const BodyTextStyleMedium() : const BodyTextStyleLarge()).copyWith(
        //   color: (!currentStates.contains(MaterialState.disabled)) 
        //     ? AppTheme.colors(context).onSurfaceVariant
        //     : AppTheme.colors(context).onSurface.withOpacity(0.38)
        // ),
        
        suffixText: suffixText,
        // suffixStyle: (( compact ) ? const BodyTextStyleMedium() : const BodyTextStyleLarge()).copyWith(
        //   color: (!currentStates.contains(MaterialState.disabled)) 
        //     ? AppTheme.colors(context).onSurfaceVariant
        //     : AppTheme.colors(context).onSurface.withOpacity(0.38)
        // ),

        // suffixIcon: ( trailingIcon == null ) 
        //   ? null 
        //   : MouseRegion(
        //     cursor: cursor,
        //     child: ( currentStates.contains(MaterialState.error) && !currentStates.contains(MaterialState.disabled) ) 
        //       ? Icon( Icons.error, color: AppTheme.colors(context).error )
        //       : Icon( trailingIcon,
        //         color: (!currentStates.contains(MaterialState.disabled)) 
        //           ? AppTheme.colors(context).onSurfaceVariant
        //           : AppTheme.colors(context).onSurface.withOpacity(0.38)
        //     ),
        //   ),
        
        // prefixIcon: ( leadingIcon == null ) 
        //   ? null 
        //   : MouseRegion(
        //     cursor: cursor,
        //     child: Icon( leadingIcon, color: (!currentStates.contains(MaterialState.disabled)) 
        //         ? AppTheme.colors(context).onSurfaceVariant
        //         : AppTheme.colors(context).onSurface.withOpacity(0.38)),
        //   ),
      border: border,
    );
  }

  final Map<String, dynamic> inputStyle = {
    // 'textInputStyle': (compact)
    //     ? const BodyTextStyleMedium()
    //     : const BodyTextStyleLarge().copyWith(height: 1),
    'textInputStyle': TextStyle(
      fontSize: (compact) ? 14.0 : 16.0,
    ),
    'expands' : true, 
    'height': (compact) ? 48.0 : 56.0,
    'width': (variableWidth) ? null : 210.0,
  };

  // inputStyle['cursorColor'] = () => MaterialStateColor.resolveWith(
  //   (Set<MaterialState> states) {
  //     if (currentStates.contains(MaterialState.error)) {
  //       return AppTheme.colors(context).error;
  //     } 
  //     return AppTheme.colors(context).primary;
  //   }
  // );

  inputStyle['inputDecoration'] = () {
    switch (style) {
      case (InputStyle.filled):
        return getInputDecoration(
          border: WidgetStateInputBorder.resolveWith(
              (Set<WidgetState> states) {
            double width = 1.0;
            // Color color = AppTheme.colors(context).onSurfaceVariant;
          
            // if (currentStates.contains(MaterialState.error)) {
            //   color = AppTheme.colors(context).error;
            //   width = 2;
            // } else if (states.contains(MaterialState.disabled)) {
            //   color = AppTheme.colors(context).onSurface.withOpacity(0.38);
            // } else if (states.contains(MaterialState.focused) || currentStates.contains(MaterialState.focused)) {
            //   color = AppTheme.colors(context).primary;
            //   width = 2;
            // }
            return UnderlineInputBorder(
              borderSide: BorderSide(
                width: width,
              ),
            );
          }),
          // fillColor:
          //     MaterialStateColor.resolveWith((Set<MaterialState> states) {
          //   if (states.contains(MaterialState.disabled)) {
          //     return AppTheme.colors(context)
          //         .disabledFieldBackground!
          //         .withOpacity(0.12);
          //   }
          //   return AppTheme.colors(context).surfaceVariant;
          // }),
        );

      case (InputStyle.outlined):
        return getInputDecoration(
          border: WidgetStateInputBorder.resolveWith(
              (Set<WidgetState> states) {
            double width = 1.0;
            // Color color = AppTheme.colors(context).onSurfaceVariant;

            // if (currentStates.contains(MaterialState.error)) {
            //   color = AppTheme.colors(context).error;
            //   width = 2;
            // } else if (states.contains(MaterialState.disabled)) {
            //   color = AppTheme.colors(context).onSurface.withOpacity(0.12);
            // } else if (states.contains(MaterialState.focused) || currentStates.contains(MaterialState.focused)) {
            //   color = AppTheme.colors(context).primary;
            //   width = 2;
            // }
            return OutlineInputBorder(
              borderSide: BorderSide(
                width: width,
              ),
            );
          }),
        );
    }
  };

  return inputStyle;
}

/// [setError] Funcion que checkea si el valor es valido y retorna el error
/// Tiene que ser invocado en el onChanged del input dentro de un setState(). 
/// Se lo debe asignar al texto de error del input.
String? setError( 
  String? value,
  Set<WidgetState> states,  
  String? Function(String?)? validator,
){
  String? error;
  if( validator != null && validator(value) != null ){
    states.add(WidgetState.error);
    error = validator(value);
  }
  else{
    states.remove(WidgetState.error);
  }
  return error;
}

/// [supportingErrorContainer] Genera el contenedor de error o soporte para los inputs
Widget supportingErrorContainer( 
  BuildContext context,
  Set<WidgetState> states,
  String? errorText,
  String? supportingText,
){
  return ( supportingText == null && states.contains(WidgetState.disabled) )
    ? const SizedBox()
    :(supportingText != null || states.contains(WidgetState.error))
      ? Container(
        padding: const EdgeInsets.only(left: 16,),
        child: Text(
          ( states.contains(WidgetState.disabled) ) 
            ? supportingText! : ( states.contains(WidgetState.error) ) ? errorText! : supportingText!,
            // style: BodyTextStyleSmall(
            style: TextStyle(
            color: (states.contains(WidgetState.disabled))
                // ? AppTheme.colors(context).onSurface.withOpacity(0.38)
                ? Colors.black.withValues(alpha:0.38)
                : (states.contains(WidgetState.error))
                    // ? AppTheme.colors(context).error
                    // : AppTheme.colors(context).onSurfaceVariant,
                    ? Colors.red
                    : Colors.black,
            ).copyWith(height: 1.5),
        ),
      )
      : const SizedBox();
}

enum InputStyle { filled, outlined }
