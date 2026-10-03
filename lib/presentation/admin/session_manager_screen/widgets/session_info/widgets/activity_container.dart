
import 'package:flutter/material.dart';

class ActivityContainer extends StatelessWidget {
  const ActivityContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        spacing: 8,
        children: [
          Row(
            spacing: 4,
            children: [
              Text("Actividad", style: Theme.of(context).textTheme.titleMedium, ),
            ],
          ),
          SizedBox(
              width: 300,
              height: 100,
              child: SingleChildScrollView(
                child: Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                            TextSpan(text:" Agustin Massa ", style: Theme.of(context).textTheme.labelMedium?.copyWith( color:colorScheme.primary ), ),
                            TextSpan(text:"creo el turno", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant) ),

                        ]
                      )
                    )

                  ],
                ),
              ),
          )
        ],
      ),
    );
  }
}
