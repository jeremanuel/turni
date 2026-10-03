import 'package:flutter/material.dart';

enum CloseSessionAction {
  cancelReservation,
  deleteSession,
}

Future<CloseSessionAction?> showCloseSessionDialog(
  BuildContext context, {
  required bool isReserved,
}) {
  return showDialog<CloseSessionAction>(
    context: context,
    builder: (dialogContext) {
      return _CloseSessionDialog(isReserved: isReserved);
    },
  );
}

class _CloseSessionDialog extends StatefulWidget {
  const _CloseSessionDialog({required this.isReserved});

  final bool isReserved;

  @override
  State<_CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<_CloseSessionDialog> {
  CloseSessionAction? selectedAction;

  @override
  void initState() {
    super.initState();
    selectedAction = widget.isReserved
        ? null
        : CloseSessionAction.deleteSession;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: SizedBox(
        height: 350,
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text("Cerrar Turno", style: textTheme.headlineSmall),
              Text(
                "Seleccione la accion a realizar",
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              RadioListTile<CloseSessionAction>(
                value: CloseSessionAction.cancelReservation,
                groupValue: selectedAction,
                onChanged: widget.isReserved
                    ? (value) {
                        setState(() {
                          selectedAction = value;
                        });
                      }
                    : null,
                title: const Text("Cancelar Reserva"),
                subtitle: const Text(
                  "El turno quedara disponible para otros clientes",
                ),
              ),
              const Divider(height: 1),
              RadioListTile<CloseSessionAction>(
                value: CloseSessionAction.deleteSession,
                groupValue: selectedAction,
                onChanged: (value) {
                  setState(() {
                    selectedAction = value;
                  });
                },
                title: const Text("Eliminar Turno"),
                subtitle: const Text(
                  "El turno sera eliminado de la agenda y no podra ser reservado",
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: selectedAction == null
                        ? null
                        : () {
                            Navigator.of(context).pop(selectedAction);
                          },
                    child: const Text("Aceptar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
