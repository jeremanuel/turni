import 'package:flutter/foundation.dart';

import '../../../domain/entities/gym/gym.dart';

int _nextKey = 0;
int _key() => ++_nextKey;

/// Series que se proponen para un ejercicio nuevo sin historial.
const defaultSeries = [Serie(reps: 10, weightKg: 0), Serie(reps: 10, weightKg: 0), Serie(reps: 10, weightKg: 0)];

class DraftExercise {
  DraftExercise({
    this.id,
    required this.exerciseId,
    required this.name,
    required this.muscles,
    required this.series,
    this.notes = '',
  }) : key = _key();

  /// Clave local estable (para reordenar y para los campos de texto).
  final int key;

  /// `routine_exercise_id` si ya existía en la rutina que se edita.
  int? id;
  int exerciseId;
  String name;
  List<String> muscles;
  List<Serie> series;
  String notes;

  DraftExercise copy({bool keepId = false}) => DraftExercise(
        id: keepId ? id : null,
        exerciseId: exerciseId,
        name: name,
        muscles: [...muscles],
        series: [...series],
        notes: notes,
      );

  factory DraftExercise.fromRoutine(RoutineExercise exercise, {bool keepId = false}) => DraftExercise(
        id: keepId ? exercise.id : null,
        exerciseId: exercise.exerciseId ?? 0,
        name: exercise.name,
        muscles: [...exercise.muscles],
        series: exercise.series.isEmpty ? [...defaultSeries] : [...exercise.series],
        notes: exercise.notes ?? '',
      );

  factory DraftExercise.fromCatalog(CatalogExercise exercise) => DraftExercise(
        exerciseId: exercise.id,
        name: exercise.name,
        muscles: exercise.muscles.map((m) => m.name).toList(),
        series: [...(exercise.lastForClient ?? defaultSeries)],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'routine_exercise_id': id,
        'exercise_id': exerciseId,
        'series': series.map((s) => s.toJson()).toList(),
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      };
}

class DraftGroup {
  DraftGroup({this.id, required this.name, List<DraftExercise>? exercises})
      : key = _key(),
        exercises = exercises ?? [];

  final int key;
  int? id;
  String name;
  final List<DraftExercise> exercises;

  List<String> get muscles {
    final out = <String>[];
    for (final exercise in exercises) {
      for (final muscle in exercise.muscles) {
        if (!out.contains(muscle)) out.add(muscle);
      }
    }
    return out;
  }

  factory DraftGroup.fromRoutine(RoutineGroup group, {bool keepIds = false}) => DraftGroup(
        id: keepIds ? group.id : null,
        name: group.name,
        exercises: group.exercises.map((e) => DraftExercise.fromRoutine(e, keepId: keepIds)).toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'routine_group_id': id,
        'name': name.trim(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

/// La rutina que se está armando. Todo lo que hace el editor pasa por acá.
class RoutineDraft extends ChangeNotifier {
  RoutineDraft({this.routineId, required this.startDate, required List<DraftGroup> groups})
      : groups = groups,
        targetKey = groups.isEmpty ? null : groups.first.key;

  /// Con valor: se está editando esa rutina (PUT). Null: es nueva (POST).
  final String? routineId;
  DateTime startDate;
  final List<DraftGroup> groups;

  /// Grupo donde se agrega lo que se copia o se busca.
  int? targetKey;
  bool dirty = false;

  List<DraftGroup>? _undoGroups;

  /// Qué rutina se usó de base (para el aviso con "Deshacer").
  String? undoLabel;

  /// Rutina vacía con [count] grupos: "Grupo 1", "Grupo 2"…
  factory RoutineDraft.empty(int count) => RoutineDraft(
        startDate: DateTime.now(),
        groups: [for (var i = 1; i <= count; i++) DraftGroup(name: count == 1 ? 'Full body' : 'Grupo $i')],
      );

  /// Copia de [routine] para una rutina nueva.
  factory RoutineDraft.copyOf(Routine routine) =>
      RoutineDraft(startDate: DateTime.now(), groups: routine.groups.map(DraftGroup.fromRoutine).toList());

  /// Edición de [routine] conservando los ids (y su historial).
  factory RoutineDraft.edit(Routine routine) => RoutineDraft(
        routineId: routine.id,
        startDate: routine.startDate,
        groups: routine.groups.map((g) => DraftGroup.fromRoutine(g, keepIds: true)).toList(),
      );

  DraftGroup? get target {
    for (final group in groups) {
      if (group.key == targetKey) return group;
    }
    return groups.isEmpty ? null : groups.last;
  }

  int get exercisesCount => groups.fold(0, (n, g) => n + g.exercises.length);

  void _changed() {
    dirty = true;
    notifyListeners();
  }

  DraftGroup? groupOf(int key) {
    for (final group in groups) {
      if (group.key == key) return group;
    }
    return null;
  }

  String _freeName(String base) {
    final used = groups.map((g) => g.name.trim().toLowerCase()).toSet();
    if (!used.contains(base.toLowerCase())) return base;
    var n = 2;
    while (used.contains('$base $n'.toLowerCase())) {
      n++;
    }
    return '$base $n';
  }

  void setStartDate(DateTime date) {
    startDate = date;
    _changed();
  }

  void setTarget(int key) {
    targetKey = key;
    notifyListeners();
  }

  DraftGroup addGroup() {
    final group = DraftGroup(name: _freeName('Grupo ${groups.length + 1}'));
    groups.add(group);
    targetKey = group.key;
    _changed();
    return group;
  }

  void renameGroup(DraftGroup group, String name) {
    group.name = name;
    _changed();
  }

  void removeGroup(DraftGroup group) {
    groups.remove(group);
    if (targetKey == group.key) targetKey = groups.isEmpty ? null : groups.first.key;
    _changed();
  }

  void duplicateGroup(DraftGroup group) {
    final copy = DraftGroup(name: _freeName('${group.name} (copia)'), exercises: group.exercises.map((e) => e.copy()).toList());
    groups.insert(groups.indexOf(group) + 1, copy);
    _changed();
  }

  /// [newIndex] ya corregido (como lo da `onReorderItem`).
  void moveGroup(int oldIndex, int newIndex) {
    groups.insert(newIndex, groups.removeAt(oldIndex));
    _changed();
  }

  /// Agrega un grupo entero copiado de otra rutina.
  void copyGroup(RoutineGroup group) {
    groups.add(DraftGroup(name: _freeName(group.name), exercises: group.exercises.map(DraftExercise.fromRoutine).toList()));
    _changed();
  }

  /// Agrega un ejercicio al grupo destino (o a [into]). Si no hay grupos, crea uno.
  void addExercise(DraftExercise exercise, {DraftGroup? into}) {
    final group = into ?? target ?? addGroup();
    group.exercises.add(exercise);
    _changed();
  }

  void removeExercise(DraftGroup group, DraftExercise exercise) {
    group.exercises.remove(exercise);
    _changed();
  }

  void duplicateExercise(DraftGroup group, DraftExercise exercise) {
    group.exercises.insert(group.exercises.indexOf(exercise) + 1, exercise.copy());
    _changed();
  }

  void moveExercise(DraftGroup group, int oldIndex, int newIndex) {
    group.exercises.insert(newIndex, group.exercises.removeAt(oldIndex));
    _changed();
  }

  void setSeries(DraftExercise exercise, List<Serie> series) {
    exercise.series = series;
    _changed();
  }

  void setNotes(DraftExercise exercise, String notes) {
    exercise.notes = notes;
    dirty = true;
  }

  void replaceExercise(DraftExercise exercise, CatalogExercise catalog) {
    exercise
      ..exerciseId = catalog.id
      ..name = catalog.name
      ..muscles = catalog.muscles.map((m) => m.name).toList();
    _changed();
  }

  /// Reemplaza toda la rutina por una copia de [routine]. Se puede deshacer.
  void useAsBase(Routine routine, String label) {
    _undoGroups = [...groups];
    undoLabel = label;
    groups
      ..clear()
      ..addAll(routine.groups.map(DraftGroup.fromRoutine));
    targetKey = groups.isEmpty ? null : groups.first.key;
    _changed();
  }

  bool get canUndo => _undoGroups != null;

  void undo() {
    final previous = _undoGroups;
    if (previous == null) return;
    groups
      ..clear()
      ..addAll(previous);
    _undoGroups = null;
    undoLabel = null;
    targetKey = groups.isEmpty ? null : groups.first.key;
    _changed();
  }

  void dismissUndo() {
    _undoGroups = null;
    undoLabel = null;
    notifyListeners();
  }

  /// Lo que falta para poder guardar, o null si está lista.
  String? validate() {
    if (groups.isEmpty) return 'Agregá al menos un grupo.';
    final names = <String>{};
    for (final group in groups) {
      final name = group.name.trim();
      if (name.isEmpty) return 'Todos los grupos necesitan un nombre.';
      if (!names.add(name.toLowerCase())) return 'Hay dos grupos que se llaman "$name".';
      if (group.exercises.isEmpty) return 'El grupo "$name" no tiene ejercicios.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'start_date': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'groups': groups.map((g) => g.toJson()).toList(),
      };
}
