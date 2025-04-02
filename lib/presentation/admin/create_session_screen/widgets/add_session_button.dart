import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/session.dart';
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

  @override
  Widget build(BuildContext context) {

    return DropdownWidget(
      dropdownController: dropdownController,
      menuWidget: SessionFormDropdown(
        onCancel: () {
          dropdownController.hide!();
        },
        onSave: (startTime, duration) {
          dropdownController.hide!();
          sl<CreateSesssionsFormBloc>().add(AddSession(
              Session.fromDates(DateTime.now().applied(startTime), duration)));
        },
      ),
      child: IconButton(onPressed: () => dropdownController.show!(), icon: const Icon(Icons.add)),
    );
  }
}
