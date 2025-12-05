import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Database
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());

  // Repository
  getIt.registerSingleton<HabitsRepository>(
    HabitsRepositoryImpl(databaseHelper: getIt<DatabaseHelper>()),
  );
}
