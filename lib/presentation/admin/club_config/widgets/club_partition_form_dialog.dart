import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/club_type.dart';
import '../../../../domain/entities/partition_vocabulary.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';

/// Diálogo de alta/edición de un servicio (`club_partition`): su tipo, su
/// nombre y, opcional, cómo se llaman sus espacios y las personas del cupo
/// (si no, los del tipo).
/// Devuelve el `ClubPartition` creado/actualizado por `Navigator.pop`, o `null` si se cancela.
class ClubPartitionFormDialog extends StatefulWidget {
  const ClubPartitionFormDialog({
    super.key,
    required this.clubTypes,
    this.existing,
  });

  final List<ClubType> clubTypes;
  final ClubPartition? existing;

  @override
  State<ClubPartitionFormDialog> createState() =>
      _ClubPartitionFormDialogState();
}

class _ClubPartitionFormDialogState extends State<ClubPartitionFormDialog> {
  final _repository = sl<ClubPartitionAdminRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _spaceController = TextEditingController();
  final _spacePluralController = TextEditingController();
  final _participantController = TextEditingController();
  final _participantPluralController = TextEditingController();
  int? _clubTypeId;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  List<TextEditingController> get _vocabularyControllers => [
        _spaceController,
        _spacePluralController,
        _participantController,
        _participantPluralController,
      ];

  ClubType? get _clubType {
    for (final type in widget.clubTypes) {
      if (type.clubTypeId == _clubTypeId) return type;
    }
    return null;
  }

  /// Vocabulario con lo que hay escrito hasta ahora, para la vista previa.
  PartitionVocabulary get _preview => PartitionVocabulary.resolve(
        ClubPartition(
          club_id: 0,
          club_type_id: _clubTypeId ?? 0,
          clubType: _clubType,
          physicalPartitionName: _spaceController.text,
          physicalPartitionPlural: _spacePluralController.text,
          participantSingular: _participantController.text,
          participantPlural: _participantPluralController.text,
        ),
      );

  /// Lo mismo sin overrides: lo que se usa si se dejan vacíos.
  PartitionVocabulary get _typeDefaults => PartitionVocabulary.resolve(
        ClubPartition(club_id: 0, club_type_id: _clubTypeId ?? 0, clubType: _clubType),
      );

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      _clubTypeId = existing.club_type_id;
      _nameController.text = existing.name ?? '';
      _phoneController.text = existing.phone ?? '';
      _spaceController.text = existing.physicalPartitionName ?? '';
      _spacePluralController.text = existing.physicalPartitionPlural ?? '';
      _participantController.text = existing.participantSingular ?? '';
      _participantPluralController.text = existing.participantPlural ?? '';
    } else if (widget.clubTypes.isNotEmpty) {
      _clubTypeId = widget.clubTypes.first.clubTypeId;
    }
    for (final controller in _vocabularyControllers) {
      controller.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (final controller in _vocabularyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_clubTypeId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Al editar, "" borra el valor (vuelve al del tipo); al crear, vacío no se manda.
    String? text(TextEditingController controller) {
      final value = controller.text.trim();
      return _isEditing || value.isNotEmpty ? value : null;
    }

    final result = _isEditing
        ? await _repository.updateClubPartition(
            widget.existing!.club_partition_id!,
            clubTypeId: _clubTypeId,
            phone: _phoneController.text.trim(),
            name: text(_nameController),
            physicalPartitionName: text(_spaceController),
            physicalPartitionPlural: text(_spacePluralController),
            participantSingular: text(_participantController),
            participantPlural: text(_participantPluralController),
          )
        : await _repository.createClubPartition(
            clubTypeId: _clubTypeId!,
            phone: text(_phoneController),
            name: text(_nameController),
            physicalPartitionName: text(_spaceController),
            physicalPartitionPlural: text(_spacePluralController),
            participantSingular: text(_participantController),
            participantPlural: text(_participantPluralController),
          );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (clubPartition) => Navigator.of(context).pop(clubPartition),
    );
  }

  String? _maxLength(String? value) =>
      (value?.trim().length ?? 0) > 40 ? 'Hasta 40 caracteres.' : null;

  Widget _textField(
    TextEditingController controller, {
    required String label,
    String? hint,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      validator: _maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        floatingLabelBehavior: hint == null ? null : FloatingLabelBehavior.always,
        // El valor del tipo se ve como sugerencia, distinto de lo escrito.
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.55)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaults = _typeDefaults;
    final preview = _preview;
    final hasOverrides = _vocabularyControllers.any((c) => c.text.trim().isNotEmpty);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar servicio' : 'Nuevo servicio'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _clubTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de actividad',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.clubTypes
                      .map((type) => DropdownMenuItem(
                            value: type.clubTypeId,
                            child: Text(type.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _clubTypeId = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná un tipo de actividad.' : null,
                ),
                const SizedBox(height: 16),
                _textField(
                  _nameController,
                  label: 'Nombre del servicio',
                  hint: _clubType?.name,
                  helper: 'Cómo se ve en la agenda y en Configuración. Vacío: el del tipo.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: hasOverrides,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: const Text('Cómo se llaman'),
                    subtitle: Text(
                      '${preview.space.plural}'
                      '${preview.features.capacity ? ' y ${preview.participant.lowerPlural}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _textField(
                              _spaceController,
                              label: 'Cada espacio',
                              hint: defaults.space.singular,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              _spacePluralController,
                              label: 'En plural',
                              hint: preview.space.plural,
                            ),
                          ),
                        ],
                      ),
                      if (defaults.features.capacity) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _textField(
                                _participantController,
                                label: 'Cada persona',
                                hint: defaults.participant.singular,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                _participantPluralController,
                                label: 'En plural',
                                hint: preview.participant.plural,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      _VocabularyPreview(vocabulary: preview),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

/// Cómo van a quedar los textos: "Agregar sala · Sala 1 · 4 alumnos".
class _VocabularyPreview extends StatelessWidget {
  const _VocabularyPreview({required this.vocabulary});

  final PartitionVocabulary vocabulary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examples = [
      'Agregar ${vocabulary.space.lower}',
      vocabulary.space.label(1),
      vocabulary.space.todos,
      if (vocabulary.features.capacity) vocabulary.participant.count(4),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Así se va a ver', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final example in examples)
                Chip(
                  label: Text(example),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
