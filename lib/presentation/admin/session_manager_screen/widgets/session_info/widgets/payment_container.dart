import 'package:collection/collection.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/config/service_locator.dart';
import '../../../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../../../core/utils/responsive_builder.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/session.dart';
import '../../../../states/global_data/global_data_cubit.dart';
import './add_payment_container.dart';
import './add_extra_container.dart';

class PaymentContainer extends StatefulWidget {
  const PaymentContainer({
    super.key,
    required this.session,
    required this.onPaymentAdded,
    required this.onExtraAdded,
    required this.onExtraDeleted,
    required this.onExtrasPayed,
  });

  final Session session;
  final Function(Payment payment) onPaymentAdded;
  final Function(Extra extra, bool payed) onExtraAdded;
  final Function(Extra extra) onExtraDeleted;
  final Function(List<Extra> extras) onExtrasPayed;

  @override
  State<PaymentContainer> createState() => _PaymentContainerState();
}

class _PaymentContainerState extends State<PaymentContainer> {
  final DropdownController dropdownController = DropdownController();
  final DropdownController extraDropdownController = DropdownController();
  final ExpansibleController controller = ExpansibleController();

  bool get _hasPendingBalance => widget.session.remainingTotalPrice > 0.01;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hasPendingBalance && !controller.isExpanded) {
        controller.expand();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PaymentContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hadPending = oldWidget.session.remainingTotalPrice > 0.01;
    if (!hadPending && _hasPendingBalance && !controller.isExpanded) {
      controller.expand();
    }
  }

  @override
  void dispose() {
    dropdownController.dispose();
    extraDropdownController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = ResponsiveBuilder.isMobile(context);
    final ticketRadius = isMobile ? 8.0 : 10.0;
    final footerRadius = ticketRadius - 1;
    final headerHeight = isMobile ? 44.0 : 52.0;
    final contentSpacing = isMobile ? 8.0 : 12.0;
    final ticketPadding = isMobile ? 10.0 : 14.0;
    final isAllPaid = widget.session.remainingTotalPrice <= 0.01;
    final sessionPayments = widget.session.payments
            ?.where((payment) => payment.isExtra != true)
            .toList() ??
        <Payment>[];
    final extras = widget.session.extras ?? <Extra>[];
    final hasExtras = extras.isNotEmpty;
    final availableProducts = sl<GlobalDataCubit>().state.products.data ?? [];

    return Expansible(
      
      controller: controller,
      headerBuilder: (context, animation) => InkWell(
        onTap: () =>
            controller.isExpanded ? controller.collapse() : controller.expand(),
        child: SizedBox(
          height: headerHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Consumos", style: textTheme.titleLarge),
                    Text(
                      "Ticket del turno y extras",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAllPaid)
                Chip(
                  visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  label: const Text("Todo pago"),
                  labelStyle: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                ),
              const SizedBox(width: 6),
              Icon(controller.isExpanded
                  ? Icons.expand_less
                  : Icons.expand_more),
            ],
          ),
        ),
      ),
      bodyBuilder: (context, animation) => Padding(
        padding:
            EdgeInsets.only(top: isMobile ? 4 : 8, bottom: isMobile ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: contentSpacing,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isAllPaid)
                  DropdownWidget(
                    dropdownController: dropdownController,
                    menuWidget: AddPaymentContainer(
                      remainingPrice: widget.session.remainingSessionPrice,
                      totalPrice: widget.session.price,
                      onPaymentAdded: (payment) {
                        widget.onPaymentAdded(payment);
                        dropdownController.hide!();
                      },
                      consumos: widget.session.extras
                              ?.where((extra) => !extra.payed)
                              .toList() ??
                          [],
                      onConsumosPagados: (consumosPagados) {
                        widget.onExtrasPayed(consumosPagados);
                        dropdownController.hide!();
                      },
                    ),
                    child: FilledButton.tonalIcon(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        dropdownController.toggle!();
                      },
                      icon: const Icon(Icons.attach_money),
                      label: const Text("Nuevo Pago"),
                    ),
                  )
                else
                  FilledButton.tonalIcon(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Todo Pago"),
                  ),
                DropdownWidget(
                  dropdownController: extraDropdownController,
                  menuWidget: AddExtraContainer(
                    products: availableProducts,
                    
                    onExtraAdded: (extra) {
                      widget.onExtraAdded(extra, extra.payed);
                      extraDropdownController.hide!();
                    },
                  ),
                  child: FilledButton.tonalIcon(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      extraDropdownController.toggle!();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo Consumo"),
                  ),
                ),
              ],
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.all(Radius.circular(ticketRadius)),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Column(
         
                children: [
                  Padding(
                    padding: EdgeInsets.all(ticketPadding),
                    child: Column(
                      spacing: isMobile ? 7 : 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                 _buildSectionHeader(
                      context,
                      title: "Turno",
                      total: widget.session.price,
                      info: "Precio base",
                    ),
                    if (sessionPayments.isNotEmpty)
                      ...sessionPayments.mapIndexed(
                        (index, payment) => _buildAmountRow(
                          context,
                          label: "Pago ${index + 1}",
                          amount: payment.amount,
                          amountPrefix: "- ",
                          amountColor: colorScheme.primary,
                        ),
                      ),
                    if (sessionPayments.isNotEmpty)
                      _buildAmountRow(
                        context,
                        label: "Restante turno",
                        amount: widget.session.remainingSessionPrice,
                        emphasized: true,
                      ),
                    if (hasExtras) buildDottedLine(),
                    if (hasExtras)
                      _buildSectionHeader(
                        context,
                        title: "Consumos extras",
                        total: widget.session.extrasTotalPrice,
                        info: "No incluidos en el turno",
                      ),
                    ...extras.map(
                      (extra) => _buildExtraRow(context, extra),
                    ),
                    if (hasExtras)
                      _buildAmountRow(
                        context,
                        label: "Restante extras",
                        amount: widget.session.remainingExtrasPrice,
                        emphasized: true,
                      ),
                    buildDottedLine(),
                    _buildAmountRow(
                      context,
                      label: "Total turno + extras",
                      amount: widget.session.totalPrice,
                      emphasized: true,
                    ),
                      ],
                    ),
                  ),
     
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ticketPadding,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(footerRadius)),
                      color: isAllPaid
                          ? colorScheme.primaryContainer
                          : colorScheme.tertiaryContainer,
                    ),
                    child: isAllPaid
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Todo pago",
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatAmount(0),
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          )
                        : _buildAmountRow(
                            context,
                            label: "A pagar",
                            amount: widget.session.remainingTotalPrice,
                            emphasized: true,
                            amountColor: colorScheme.onTertiaryContainer,
                            labelColor: colorScheme.onTertiaryContainer,
                          ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required double total,
    required String info,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          title,
          style: textTheme.titleMedium,
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: info,
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          _formatAmount(total),
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    BuildContext context, {
    required String label,
    required double amount,
    String amountPrefix = "",
    bool emphasized = false,
    Color? amountColor,
    Color? labelColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rowStyle = emphasized ? textTheme.titleMedium : textTheme.titleSmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: rowStyle?.copyWith(
            color: labelColor ?? colorScheme.onSurface,
          ),
        ),
        Text(
          "$amountPrefix${_formatAmount(amount)}",
          style: rowStyle?.copyWith(
            color: amountColor ?? colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraRow(BuildContext context, Extra extra) {
    if (ResponsiveBuilder.isDesktop(context)) {
      return _ExtraActionDropdownRow(
        extra: extra,
        onPay: () => widget.onExtrasPayed([extra]),
        onDelete: () => widget.onExtraDeleted(extra),
      );
    }

    return _ExtraActionBottomSheetRow(
      extra: extra,
      onPay: () => widget.onExtrasPayed([extra]),
      onDelete: () => widget.onExtraDeleted(extra),
    );
  }

  Container buildDottedLine() {
    return Container(
      height: 2,
      decoration: DottedDecoration(
        shape: Shape.line,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  String _formatAmount(num value) {
    final rounded = value.round().toString();
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}

class _ExtraActionBottomSheetRow extends StatelessWidget {
  const _ExtraActionBottomSheetRow({
    required this.extra,
    required this.onPay,
    required this.onDelete,
  });

  final Extra extra;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showActions(context, colorScheme),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                extra.payed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: extra.payed ? colorScheme.primary : colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  extra.name,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: extra.payed
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  extra.payed ? "pago" : "pendiente",
                  style: textTheme.labelSmall?.copyWith(
                    color: extra.payed
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(extra.amount),
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(
      BuildContext context, ColorScheme colorScheme) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    extra.payed ? Icons.check_circle : Icons.attach_money,
                    color: colorScheme.primary,
                  ),
                  title: Text(extra.name),
                  subtitle: Text("\$${_formatAmount(extra.amount)}"),
                ),
                if (!extra.payed)
                  ListTile(
                    leading: Icon(
                      Icons.payments_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text("Pagar consumo"),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onPay();
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    "Eliminar consumo",
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(num value) {
    final rounded = value.round().toString();
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}

class _ExtraActionDropdownRow extends StatefulWidget {
  const _ExtraActionDropdownRow({
    required this.extra,
    required this.onPay,
    required this.onDelete,
  });

  final Extra extra;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  @override
  State<_ExtraActionDropdownRow> createState() =>
      _ExtraActionDropdownRowState();
}

class _ExtraActionDropdownRowState extends State<_ExtraActionDropdownRow> {
  final DropdownController controller = DropdownController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DropdownWidget(
      dropdownController: controller,
      menuWidget: _ExtraActionsMenu(
        extra: widget.extra,
        onPay: () {
          controller.hide?.call();
          widget.onPay();
        },
        onDelete: () {
          controller.hide?.call();
          widget.onDelete();
        },
      ),
      obscureBackground: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.toggle?.call(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  widget.extra.payed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: widget.extra.payed
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.extra.name,
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.extra.payed
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.extra.payed ? "pago" : "pendiente",
                    style: textTheme.labelSmall?.copyWith(
                      color: widget.extra.payed
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatAmount(widget.extra.amount),
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(num value) {
    final rounded = value.round().toString();
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}

class _ExtraActionsMenu extends StatelessWidget {
  const _ExtraActionsMenu({
    required this.extra,
    required this.onPay,
    required this.onDelete,
  });

  final Extra extra;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        if (!extra.payed)
          ListTile(
            dense: true,
            title: const Text("Pagar consumo"),
            onTap: onPay,
          ),
        ListTile(
          dense: true,
          title: Text(
            "Eliminar consumo",
            style: TextStyle(color: colorScheme.error),
          ),
          onTap: onDelete,
        ),
      ],
    );
  }

  String _formatAmount(num value) {
    final rounded = value.round().toString();
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}
