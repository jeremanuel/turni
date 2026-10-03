import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/use_case/session_template/validate_session_overlap_use_case.dart';
import '../bloc/create_sesssions_form_bloc.dart';
import 'session_form_dropdown.dart';

class AddSessionButton extends StatefulWidget {
  
  const AddSessionButton({
    super.key,
  });

  @override
  State<AddSessionButton> createState() => _AddSessionButtonState();
}

class _AddSessionButtonState extends State<AddSessionButton> {

  final dropdownController = DropdownController();
  final ValidateSessionOverlapUseCase _validateSessionOverlapUseCase =
      ValidateSessionOverlapUseCase();

  @override
  Widget build(BuildContext context) {

    return DropdownWidget(
      dropdownController: dropdownController,
      menuWidget: SessionFormDropdown(
        onCancel: () {
          dropdownController.hide!();
        },
        onSave: (startTime, duration) {
          final candidate = Session.fromDates(
            DateTime.now().applied(startTime),
            duration,
          );

          final existingSessions = sl<CreateSesssionsFormBloc>().state.sessions;
          final hasOverlap = _validateSessionOverlapUseCase.execute(
            candidate: candidate,
            existingSessions: existingSessions,
          );

          if (hasOverlap) {
            SnackbarsFunctions.showErrorsSnackbar(
              context,
              'El turno se superpone con otro horario cargado.',
            );
            return;
          }

          dropdownController.hide!();
          sl<CreateSesssionsFormBloc>().add(AddSession(candidate));
        },
      ),
      child: IconButton(onPressed: () => dropdownController.show!(), icon: const Icon(Icons.add)),
    );
  }
}
