import '../repositories/habits_repository.dart';
import '../../data/models/habit_model.dart';

class GetAllHabitsUseCase {
  final HabitsRepository _repository;

  GetAllHabitsUseCase(this._repository);

  Future<List<HabitModel>> call() async {
    return await _repository.getAllHabits();
  }
}

class GetHabitByIdUseCase {
  final HabitsRepository _repository;

  GetHabitByIdUseCase(this._repository);

  Future<HabitModel?> call(String id) async {
    return await _repository.getHabitById(id);
  }
}

class InsertHabitUseCase {
  final HabitsRepository _repository;

  InsertHabitUseCase(this._repository);

  Future<void> call(HabitModel habit) async {
    await _repository.insertHabit(habit);
  }
}

class UpdateHabitUseCase {
  final HabitsRepository _repository;

  UpdateHabitUseCase(this._repository);

  Future<void> call(HabitModel habit) async {
    await _repository.updateHabit(habit);
  }
}

class DeleteHabitUseCase {
  final HabitsRepository _repository;

  DeleteHabitUseCase(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteHabit(id);
  }
}

class ToggleHabitCompletionUseCase {
  final HabitsRepository _repository;

  ToggleHabitCompletionUseCase(this._repository);

  Future<void> call(String id, bool isCompleted) async {
    await _repository.toggleHabitCompletion(id, isCompleted);
  }
}

class RecordHabitCompletionUseCase {
  final HabitsRepository _repository;

  RecordHabitCompletionUseCase(this._repository);

  Future<void> call(String habitId) async {
    await _repository.recordHabitCompletion(habitId);
  }
}
