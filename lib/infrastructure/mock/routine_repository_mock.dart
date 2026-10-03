import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/routine/exercise.dart';
import '../../domain/entities/routine/routine.dart';
import '../../domain/entities/routine/routine_exercise.dart';
import '../../domain/entities/routine/routine_group.dart';
import '../../domain/repositories/routine_repository.dart';

class RoutineRepositoryMock implements RoutineRepository {
  
  // Datos mock de ejercicios
  static final List<Exercise> _mockExercises = [
    // Pecho (Grupo 1)
    Exercise(id: 1, name: 'Press de Banca', muscularGroup: 1),
    Exercise(id: 8, name: 'Flexiones', muscularGroup: 1),
    Exercise(id: 15, name: 'Press Inclinado', muscularGroup: 1),
    Exercise(id: 16, name: 'Aperturas con Mancuernas', muscularGroup: 1),
    Exercise(id: 17, name: 'Fondos en Paralelas', muscularGroup: 1),
    Exercise(id: 18, name: 'Pull-over', muscularGroup: 1),
    
    // Piernas (Grupo 2)
    Exercise(id: 2, name: 'Sentadillas', muscularGroup: 2),
    Exercise(id: 9, name: 'Prensa de Piernas', muscularGroup: 2),
    Exercise(id: 19, name: 'Zancadas', muscularGroup: 2),
    Exercise(id: 20, name: 'Extensión de Cuádriceps', muscularGroup: 2),
    Exercise(id: 21, name: 'Curl de Femorales', muscularGroup: 2),
    Exercise(id: 22, name: 'Elevación de Talones', muscularGroup: 2),
    Exercise(id: 23, name: 'Sentadilla Búlgara', muscularGroup: 2),
    
    // Espalda (Grupo 3)
    Exercise(id: 3, name: 'Peso Muerto', muscularGroup: 3),
    Exercise(id: 7, name: 'Dominadas', muscularGroup: 3),
    Exercise(id: 24, name: 'Remo con Barra', muscularGroup: 3),
    Exercise(id: 25, name: 'Remo en Polea', muscularGroup: 3),
    Exercise(id: 26, name: 'Jalón al Pecho', muscularGroup: 3),
    Exercise(id: 27, name: 'Hiperextensiones', muscularGroup: 3),
    
    // Hombros (Grupo 4)
    Exercise(id: 4, name: 'Press Militar', muscularGroup: 4),
    Exercise(id: 10, name: 'Elevaciones Laterales', muscularGroup: 4),
    Exercise(id: 28, name: 'Elevaciones Frontales', muscularGroup: 4),
    Exercise(id: 29, name: 'Elevaciones Posteriores', muscularGroup: 4),
    Exercise(id: 30, name: 'Press Arnold', muscularGroup: 4),
    Exercise(id: 31, name: 'Encogimientos', muscularGroup: 4),
    
    // Bíceps (Grupo 5)
    Exercise(id: 5, name: 'Curl de Bíceps', muscularGroup: 5),
    Exercise(id: 32, name: 'Curl Martillo', muscularGroup: 5),
    Exercise(id: 33, name: 'Curl en Predicador', muscularGroup: 5),
    Exercise(id: 34, name: 'Curl con Barra Z', muscularGroup: 5),
    Exercise(id: 35, name: 'Curl 21s', muscularGroup: 5),
    
    // Tríceps (Grupo 6)
    Exercise(id: 6, name: 'Press Francés', muscularGroup: 6),
    Exercise(id: 36, name: 'Extensión de Tríceps', muscularGroup: 6),
    Exercise(id: 37, name: 'Patadas de Tríceps', muscularGroup: 6),
    Exercise(id: 38, name: 'Press Cerrado', muscularGroup: 6),
    Exercise(id: 39, name: 'Fondos en Banco', muscularGroup: 6),
    
    // Abdominales (Grupo 7)
    Exercise(id: 40, name: 'Crunches', muscularGroup: 7),
    Exercise(id: 41, name: 'Plancha', muscularGroup: 7),
    Exercise(id: 42, name: 'Elevación de Piernas', muscularGroup: 7),
    Exercise(id: 43, name: 'Russian Twists', muscularGroup: 7),
    Exercise(id: 44, name: 'Mountain Climbers', muscularGroup: 7),
    Exercise(id: 45, name: 'Bicycle Crunches', muscularGroup: 7),
  ];

  // Datos mock de rutinas
  static final List<Routine> _mockRoutines = [
    // Rutina 1: Entrenamiento Completo A
    Routine(
      routineId: 'routine_1',
      createdAt: DateTime(2024, 1, 15),
      exercises: [
        RoutineGroup(
          id: 1,
          groupName: 'Piernas',
          exercises: [
            RoutineExercise(
              id: 1,
              exercise: _mockExercises[7], // Sentadillas
              sets: '4',
              repetitions: '10-12',
              weight: '80kg',
              observations: 'Descanso 2 minutos entre series',
            ),
            RoutineExercise(
              id: 2,
              exercise: _mockExercises[8], // Prensa de Piernas
              sets: '3',
              repetitions: '12-15',
              weight: '150kg',
            ),
            RoutineExercise(
              id: 3,
              exercise: _mockExercises[9], // Zancadas
              sets: '3',
              repetitions: '12 c/pierna',
              weight: '25kg',
            ),
            RoutineExercise(
              id: 4,
              exercise: _mockExercises[11], // Curl de Femorales
              sets: '3',
              repetitions: '12-15',
              weight: '45kg',
            ),
            RoutineExercise(
              id: 5,
              exercise: _mockExercises[12], // Elevación de Talones
              sets: '4',
              repetitions: '15-20',
              weight: '60kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 2,
          groupName: 'Pecho',
          exercises: [
            RoutineExercise(
              id: 6,
              exercise: _mockExercises[0], // Press de Banca
              sets: '4',
              repetitions: '8-10',
              weight: '75kg',
            ),
            RoutineExercise(
              id: 7,
              exercise: _mockExercises[2], // Press Inclinado
              sets: '3',
              repetitions: '10-12',
              weight: '65kg',
            ),
            RoutineExercise(
              id: 8,
              exercise: _mockExercises[3], // Aperturas con Mancuernas
              sets: '3',
              repetitions: '12-15',
              weight: '22kg',
            ),
            RoutineExercise(
              id: 9,
              exercise: _mockExercises[1], // Flexiones
              sets: '3',
              repetitions: '15-20',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 10,
              exercise: _mockExercises[4], // Fondos en Paralelas
              sets: '3',
              repetitions: '10-12',
              weight: 'Peso corporal',
            ),
          ],
        ),
        RoutineGroup(
          id: 3,
          groupName: 'Espalda',
          exercises: [
            RoutineExercise(
              id: 11,
              exercise: _mockExercises[13], // Peso Muerto
              sets: '4',
              repetitions: '6-8',
              weight: '100kg',
              observations: 'Mantener espalda recta',
            ),
            RoutineExercise(
              id: 12,
              exercise: _mockExercises[14], // Dominadas
              sets: '3',
              repetitions: '8-12',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 13,
              exercise: _mockExercises[15], // Remo con Barra
              sets: '3',
              repetitions: '10-12',
              weight: '70kg',
            ),
            RoutineExercise(
              id: 14,
              exercise: _mockExercises[16], // Remo en Polea
              sets: '3',
              repetitions: '12-15',
              weight: '60kg',
            ),
            RoutineExercise(
              id: 15,
              exercise: _mockExercises[17], // Jalón al Pecho
              sets: '3',
              repetitions: '12-15',
              weight: '55kg',
            ),
          ],
        ),
      ],
    ),
    
    // Rutina 2: Entrenamiento Completo B
    Routine(
      routineId: 'routine_2',
      createdAt: DateTime(2024, 1, 20),
      exercises: [
        RoutineGroup(
          id: 4,
          groupName: 'Hombros',
          exercises: [
            RoutineExercise(
              id: 16,
              exercise: _mockExercises[19], // Press Militar
              sets: '4',
              repetitions: '8-10',
              weight: '50kg',
            ),
            RoutineExercise(
              id: 17,
              exercise: _mockExercises[21], // Elevaciones Laterales
              sets: '4',
              repetitions: '12-15',
              weight: '15kg',
            ),
            RoutineExercise(
              id: 18,
              exercise: _mockExercises[22], // Elevaciones Frontales
              sets: '3',
              repetitions: '12-15',
              weight: '12kg',
            ),
            RoutineExercise(
              id: 19,
              exercise: _mockExercises[23], // Elevaciones Posteriores
              sets: '4',
              repetitions: '15-20',
              weight: '10kg',
            ),
            RoutineExercise(
              id: 20,
              exercise: _mockExercises[25], // Encogimientos
              sets: '3',
              repetitions: '12-15',
              weight: '35kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 5,
          groupName: 'Brazos',
          exercises: [
            RoutineExercise(
              id: 21,
              exercise: _mockExercises[26], // Curl de Bíceps
              sets: '4',
              repetitions: '10-12',
              weight: '22kg',
            ),
            RoutineExercise(
              id: 22,
              exercise: _mockExercises[30], // Press Francés
              sets: '4',
              repetitions: '10-12',
              weight: '35kg',
            ),
            RoutineExercise(
              id: 23,
              exercise: _mockExercises[27], // Curl Martillo
              sets: '3',
              repetitions: '12-15',
              weight: '20kg',
            ),
            RoutineExercise(
              id: 24,
              exercise: _mockExercises[31], // Extensión de Tríceps
              sets: '3',
              repetitions: '12-15',
              weight: '30kg',
            ),
            RoutineExercise(
              id: 25,
              exercise: _mockExercises[28], // Curl en Predicador
              sets: '3',
              repetitions: '12-15',
              weight: '18kg',
            ),
            RoutineExercise(
              id: 26,
              exercise: _mockExercises[32], // Patadas de Tríceps
              sets: '3',
              repetitions: '12-15',
              weight: '15kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 6,
          groupName: 'Core y Abdominales',
          exercises: [
            RoutineExercise(
              id: 27,
              exercise: _mockExercises[35], // Crunches
              sets: '4',
              repetitions: '20-25',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 28,
              exercise: _mockExercises[36], // Plancha
              sets: '3',
              repetitions: '45-60 seg',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 29,
              exercise: _mockExercises[37], // Elevación de Piernas
              sets: '3',
              repetitions: '15-20',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 30,
              exercise: _mockExercises[38], // Russian Twists
              sets: '3',
              repetitions: '25-30',
              weight: '10kg',
            ),
          ],
        ),
      ],
    ),

    // Rutina 3: Entrenamiento de Fuerza Completo
    Routine(
      routineId: 'routine_3',
      createdAt: DateTime(2024, 2, 1),
      exercises: [
        RoutineGroup(
          id: 7,
          groupName: 'Piernas y Glúteos',
          exercises: [
            RoutineExercise(
              id: 31,
              exercise: _mockExercises[7], // Sentadillas
              sets: '5',
              repetitions: '5-6',
              weight: '90kg',
              observations: 'Fuerza máxima - descanso 3 minutos',
            ),
            RoutineExercise(
              id: 32,
              exercise: _mockExercises[13], // Peso Muerto
              sets: '4',
              repetitions: '5-6',
              weight: '110kg',
            ),
            RoutineExercise(
              id: 33,
              exercise: _mockExercises[8], // Prensa de Piernas
              sets: '4',
              repetitions: '8-10',
              weight: '180kg',
            ),
            RoutineExercise(
              id: 34,
              exercise: _mockExercises[12], // Sentadilla Búlgara
              sets: '3',
              repetitions: '10 c/pierna',
              weight: '25kg',
            ),
            RoutineExercise(
              id: 35,
              exercise: _mockExercises[11], // Curl de Femorales
              sets: '3',
              repetitions: '12-15',
              weight: '50kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 8,
          groupName: 'Pecho y Tríceps',
          exercises: [
            RoutineExercise(
              id: 36,
              exercise: _mockExercises[0], // Press de Banca
              sets: '5',
              repetitions: '5-6',
              weight: '85kg',
            ),
            RoutineExercise(
              id: 37,
              exercise: _mockExercises[2], // Press Inclinado
              sets: '4',
              repetitions: '8-10',
              weight: '70kg',
            ),
            RoutineExercise(
              id: 38,
              exercise: _mockExercises[4], // Fondos en Paralelas
              sets: '3',
              repetitions: '10-12',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 39,
              exercise: _mockExercises[30], // Press Francés
              sets: '4',
              repetitions: '10-12',
              weight: '40kg',
            ),
            RoutineExercise(
              id: 40,
              exercise: _mockExercises[33], // Press Cerrado
              sets: '3',
              repetitions: '10-12',
              weight: '60kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 9,
          groupName: 'Espalda y Bíceps',
          exercises: [
            RoutineExercise(
              id: 41,
              exercise: _mockExercises[14], // Dominadas
              sets: '4',
              repetitions: '6-10',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 42,
              exercise: _mockExercises[15], // Remo con Barra
              sets: '4',
              repetitions: '8-10',
              weight: '75kg',
            ),
            RoutineExercise(
              id: 43,
              exercise: _mockExercises[16], // Remo en Polea
              sets: '3',
              repetitions: '10-12',
              weight: '65kg',
            ),
            RoutineExercise(
              id: 44,
              exercise: _mockExercises[26], // Curl de Bíceps
              sets: '4',
              repetitions: '10-12',
              weight: '25kg',
            ),
            RoutineExercise(
              id: 45,
              exercise: _mockExercises[27], // Curl Martillo
              sets: '3',
              repetitions: '12-15',
              weight: '22kg',
            ),
          ],
        ),
      ],
    ),

    // Rutina 4: Entrenamiento de Volumen Completo
    Routine(
      routineId: 'routine_4',
      createdAt: DateTime(2024, 2, 10),
      exercises: [
        RoutineGroup(
          id: 10,
          groupName: 'Tren Inferior',
          exercises: [
            RoutineExercise(
              id: 46,
              exercise: _mockExercises[7], // Sentadillas
              sets: '4',
              repetitions: '12-15',
              weight: '70kg',
            ),
            RoutineExercise(
              id: 47,
              exercise: _mockExercises[9], // Zancadas
              sets: '3',
              repetitions: '15 c/pierna',
              weight: '20kg',
            ),
            RoutineExercise(
              id: 48,
              exercise: _mockExercises[10], // Extensión de Cuádriceps
              sets: '3',
              repetitions: '15-20',
              weight: '55kg',
            ),
            RoutineExercise(
              id: 49,
              exercise: _mockExercises[11], // Curl de Femorales
              sets: '3',
              repetitions: '15-20',
              weight: '40kg',
            ),
            RoutineExercise(
              id: 50,
              exercise: _mockExercises[12], // Elevación de Talones
              sets: '4',
              repetitions: '20-25',
              weight: '50kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 11,
          groupName: 'Tren Superior',
          exercises: [
            RoutineExercise(
              id: 51,
              exercise: _mockExercises[0], // Press de Banca
              sets: '4',
              repetitions: '12-15',
              weight: '65kg',
            ),
            RoutineExercise(
              id: 52,
              exercise: _mockExercises[15], // Remo con Barra
              sets: '4',
              repetitions: '12-15',
              weight: '60kg',
            ),
            RoutineExercise(
              id: 53,
              exercise: _mockExercises[19], // Press Militar
              sets: '3',
              repetitions: '12-15',
              weight: '40kg',
            ),
            RoutineExercise(
              id: 54,
              exercise: _mockExercises[26], // Curl de Bíceps
              sets: '3',
              repetitions: '15-20',
              weight: '18kg',
            ),
            RoutineExercise(
              id: 55,
              exercise: _mockExercises[30], // Press Francés
              sets: '3',
              repetitions: '15-20',
              weight: '30kg',
            ),
            RoutineExercise(
              id: 56,
              exercise: _mockExercises[21], // Elevaciones Laterales
              sets: '3',
              repetitions: '15-20',
              weight: '12kg',
            ),
          ],
        ),
      ],
    ),

    // Rutina 5: Entrenamiento Funcional Completo
    Routine(
      routineId: 'routine_5',
      createdAt: DateTime(2024, 2, 15),
      exercises: [
        RoutineGroup(
          id: 12,
          groupName: 'Movimientos Principales',
          exercises: [
            RoutineExercise(
              id: 57,
              exercise: _mockExercises[7], // Sentadillas
              sets: '4',
              repetitions: '10-12',
              weight: '75kg',
            ),
            RoutineExercise(
              id: 58,
              exercise: _mockExercises[13], // Peso Muerto
              sets: '4',
              repetitions: '8-10',
              weight: '95kg',
            ),
            RoutineExercise(
              id: 59,
              exercise: _mockExercises[0], // Press de Banca
              sets: '4',
              repetitions: '10-12',
              weight: '70kg',
            ),
            RoutineExercise(
              id: 60,
              exercise: _mockExercises[19], // Press Militar
              sets: '3',
              repetitions: '10-12',
              weight: '45kg',
            ),
            RoutineExercise(
              id: 61,
              exercise: _mockExercises[14], // Dominadas
              sets: '3',
              repetitions: '8-12',
              weight: 'Peso corporal',
            ),
          ],
        ),
        RoutineGroup(
          id: 13,
          groupName: 'Movimientos Accesorios',
          exercises: [
            RoutineExercise(
              id: 62,
              exercise: _mockExercises[9], // Zancadas
              sets: '3',
              repetitions: '12 c/pierna',
              weight: '25kg',
            ),
            RoutineExercise(
              id: 63,
              exercise: _mockExercises[3], // Aperturas con Mancuernas
              sets: '3',
              repetitions: '12-15',
              weight: '20kg',
            ),
            RoutineExercise(
              id: 64,
              exercise: _mockExercises[16], // Remo en Polea
              sets: '3',
              repetitions: '12-15',
              weight: '55kg',
            ),
            RoutineExercise(
              id: 65,
              exercise: _mockExercises[26], // Curl de Bíceps
              sets: '3',
              repetitions: '12-15',
              weight: '20kg',
            ),
            RoutineExercise(
              id: 66,
              exercise: _mockExercises[30], // Press Francés
              sets: '3',
              repetitions: '12-15',
              weight: '32kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 14,
          groupName: 'Core y Estabilidad',
          exercises: [
            RoutineExercise(
              id: 67,
              exercise: _mockExercises[36], // Plancha
              sets: '3',
              repetitions: '60 seg',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 68,
              exercise: _mockExercises[38], // Russian Twists
              sets: '3',
              repetitions: '30',
              weight: '15kg',
            ),
            RoutineExercise(
              id: 69,
              exercise: _mockExercises[39], // Mountain Climbers
              sets: '3',
              repetitions: '30 seg',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 70,
              exercise: _mockExercises[40], // Bicycle Crunches
              sets: '3',
              repetitions: '25',
              weight: 'Peso corporal',
            ),
          ],
        ),
      ],
    ),

    // Rutina 6: Entrenamiento de Principiante Completo
    Routine(
      routineId: 'routine_6',
      createdAt: DateTime(2024, 3, 1),
      exercises: [
        RoutineGroup(
          id: 15,
          groupName: 'Básicos de Piernas',
          exercises: [
            RoutineExercise(
              id: 71,
              exercise: _mockExercises[7], // Sentadillas
              sets: '3',
              repetitions: '12-15',
              weight: '50kg',
              observations: 'Enfoque en técnica correcta',
            ),
            RoutineExercise(
              id: 72,
              exercise: _mockExercises[8], // Prensa de Piernas
              sets: '3',
              repetitions: '15-20',
              weight: '100kg',
            ),
            RoutineExercise(
              id: 73,
              exercise: _mockExercises[9], // Zancadas
              sets: '2',
              repetitions: '10 c/pierna',
              weight: '15kg',
            ),
            RoutineExercise(
              id: 74,
              exercise: _mockExercises[11], // Curl de Femorales
              sets: '3',
              repetitions: '15',
              weight: '30kg',
            ),
            RoutineExercise(
              id: 75,
              exercise: _mockExercises[12], // Elevación de Talones
              sets: '3',
              repetitions: '20',
              weight: '30kg',
            ),
          ],
        ),
        RoutineGroup(
          id: 16,
          groupName: 'Básicos de Tren Superior',
          exercises: [
            RoutineExercise(
              id: 76,
              exercise: _mockExercises[1], // Flexiones
              sets: '3',
              repetitions: '10-15',
              weight: 'Peso corporal',
            ),
            RoutineExercise(
              id: 77,
              exercise: _mockExercises[17], // Jalón al Pecho
              sets: '3',
              repetitions: '12-15',
              weight: '40kg',
            ),
            RoutineExercise(
              id: 78,
              exercise: _mockExercises[19], // Press Militar
              sets: '3',
              repetitions: '10-12',
              weight: '30kg',
            ),
            RoutineExercise(
              id: 79,
              exercise: _mockExercises[26], // Curl de Bíceps
              sets: '3',
              repetitions: '12-15',
              weight: '15kg',
            ),
            RoutineExercise(
              id: 80,
              exercise: _mockExercises[31], // Extensión de Tríceps
              sets: '3',
              repetitions: '12-15',
              weight: '25kg',
            ),
          ],
        ),
      ],
    ),
  ];

  // Mapeo de rutinas por usuario (simulando diferentes usuarios)
  static final Map<String, List<String>> _userRoutines = {
    'user_1': ['routine_1', 'routine_2', 'routine_3'], // Usuario enfocado en Push/Pull/Legs
    'user_2': ['routine_4', 'routine_5'], // Usuario que prefiere Upper Body y Full Body
    'user_3': ['routine_6'], // Usuario avanzado enfocado en fuerza
    'user_4': ['routine_1', 'routine_4', 'routine_5'], // Usuario intermedio variado
    '1': ['routine_1', 'routine_2', 'routine_3'], // Cliente ID 1
    '2': ['routine_4', 'routine_5'], // Cliente ID 2
    '3': ['routine_6'], // Cliente ID 3
    '4': ['routine_1', 'routine_4', 'routine_5'], // Cliente ID 4
  };

  @override
  Future<Either<DomainError, List<Routine>>> getClientRoutines(int clientId) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      // Obtener IDs de rutinas del usuario
      final userRoutineIds = _userRoutines[clientId.toString()] ?? [];
      
      // Filtrar rutinas que pertenecen al usuario
      final userRoutines = _mockRoutines
          .where((routine) => userRoutineIds.contains(routine.routineId))
          .toList();
      
      // Ordenar por fecha de creación (más recientes primero)
      userRoutines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Right(userRoutines);
      
    } catch (e) {
      return Left(DomainError(
        message: 'Error al obtener rutinas del usuario: ${e.toString()}',
        internalCode: 3001,
        date: DateTime.now(),
      ));
    }
  }

  @override
  Future<Either<DomainError, List<Routine>>> getLastRoutines({int quantity = 10}) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Obtener todas las rutinas y ordenar por fecha de creación (más recientes primero)
      final sortedRoutines = List<Routine>.from(_mockRoutines);
      sortedRoutines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Limitar la cantidad según el parámetro
      final limitedRoutines = sortedRoutines.take(quantity).toList();
      
      return Right(limitedRoutines);
      
    } catch (e) {
      return Left(DomainError(
        message: 'Error al obtener las últimas rutinas: ${e.toString()}',
        internalCode: 3002,
        date: DateTime.now(),
      ));
    }
  }

  // Métodos auxiliares para testing y gestión de datos mock
  void addMockRoutine(Routine routine) {
    _mockRoutines.add(routine);
  }

  void addUserRoutine(String userId, String routineId) {
    if (_userRoutines.containsKey(userId)) {
      _userRoutines[userId]!.add(routineId);
    } else {
      _userRoutines[userId] = [routineId];
    }
  }

  void clearMockRoutines() {
    _mockRoutines.clear();
    _userRoutines.clear();
  }

  List<Routine> getAllMockRoutines() {
    return List.unmodifiable(_mockRoutines);
  }

  Map<String, List<String>> getAllUserRoutines() {
    return Map.unmodifiable(_userRoutines);
  }

  List<Exercise> getAllMockExercises() {
    return List.unmodifiable(_mockExercises);
  }
}