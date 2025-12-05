import '../../../../core/database/database_helper.dart';
import '../../domain/repositories/habits_repository.dart';
import '../models/habit_model.dart';

class HabitsRepositoryImpl implements HabitsRepository {
  final DatabaseHelper _databaseHelper;

  HabitsRepositoryImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  @override
  Future<List<HabitModel>> getAllHabits() async {
    final habitsJson = await _databaseHelper.getAllHabits();
    return habitsJson.map((json) => HabitModel.fromJson(json)).toList();
  }

  @override
  Future<HabitModel?> getHabitById(String id) async {
    final habitJson = await _databaseHelper.getHabitById(id);
    return habitJson != null ? HabitModel.fromJson(habitJson) : null;
  }

  @override
  Future<void> insertHabit(HabitModel habit) async {
    await _databaseHelper.insertHabit(habit.toJson());
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await _databaseHelper.updateHabit(habit.id, habit.toJson());
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _databaseHelper.deleteHabit(id);
  }

  @override
  Future<void> toggleHabitCompletion(String id, bool isCompleted) async {
    await _databaseHelper.toggleHabitCompletion(id, isCompleted);
  }

  @override
  Future<void> toggleHabitSkip(String id, bool isSkipped) async {
    await _databaseHelper.toggleHabitSkip(id, isSkipped);
  }

  @override
  Future<void> recordHabitCompletion(String habitId) async {
    await _databaseHelper.recordHabitCompletion(habitId);
  }

  @override
  Future<void> removeTodayCompletion(String habitId) async {
    await _databaseHelper.removeTodayCompletion(habitId);
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitCompletions(String habitId) async {
    return await _databaseHelper.getHabitCompletions(habitId);
  }

  @override
  Future<List<Map<String, dynamic>>> getCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _databaseHelper.getCompletionsByDateRange(
      habitId,
      startDate,
      endDate,
    );
  }

  @override
  Future<int> getTotalHabitsCount() async {
    return await _databaseHelper.getTotalHabitsCount();
  }

  @override
  Future<int> getCompletedHabitsCount() async {
    return await _databaseHelper.getCompletedHabitsCount();
  }

  @override
  Future<int> getActiveHabitsCount() async {
    return await _databaseHelper.getActiveHabitsCount();
  }

  @override
  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
  }

  @override
  Future<bool> hasData() async {
    return await _databaseHelper.hasData();
  }

  @override
  Future<bool> habitExists(String id) async {
    return await _databaseHelper.habitExists(id);
  }

  @override
  Future<bool> habitNameExists(String name) async {
    return await _databaseHelper.habitNameExists(name);
  }

  @override
  Future<String> getNextAvailableId() async {
    return await _databaseHelper.getNextAvailableId();
  }

  @override
  Future<void> cleanupWeeklySkippedHabits() async {
    await _databaseHelper.cleanupWeeklySkippedHabits();
  }

  @override
  Future<void> resetAllCompletionFlags() async {
    await _databaseHelper.resetAllCompletionFlags();
  }

  @override
  Future<void> syncCompletionStatus() async {
    await _databaseHelper.syncCompletionStatus();
  }

  @override
  Future<void> archiveHabit(String id) async {
    await _databaseHelper.archiveHabit(id);
  }

  @override
  Future<List<HabitModel>> getArchivedHabits() async {
    final habitsJson = await _databaseHelper.getArchivedHabits();
    return habitsJson.map((json) => HabitModel.fromJson(json)).toList();
  }

  @override
  Future<void> restoreHabit(String id) async {
    await _databaseHelper.restoreHabit(id);
  }

  @override
  Future<Map<String, dynamic>> getDailyStatistics(DateTime date) async {
    return await _databaseHelper.getDailyStatistics(date);
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyStatistics(
    DateTime startDate,
  ) async {
    return await _databaseHelper.getWeeklyStatistics(startDate);
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyStatistics(
    DateTime month,
  ) async {
    return await _databaseHelper.getMonthlyStatistics(month);
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitConsistencyStats() async {
    return await _databaseHelper.getHabitConsistencyStats();
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitsByStatus(String status) async {
    return await _databaseHelper.getHabitsByStatus(status);
  }

  @override
  List<Object?> get props => [_databaseHelper];

  @override
  bool get stringify => true;
}
