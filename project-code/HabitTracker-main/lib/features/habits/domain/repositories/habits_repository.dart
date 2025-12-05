import 'package:equatable/equatable.dart';
import '../../data/models/habit_model.dart';

abstract class HabitsRepository extends Equatable {
  Future<List<HabitModel>> getAllHabits();
  Future<HabitModel?> getHabitById(String id);
  Future<void> insertHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
  Future<void> toggleHabitCompletion(String id, bool isCompleted);
  Future<void> toggleHabitSkip(String id, bool isSkipped);
  Future<void> recordHabitCompletion(String habitId);
  Future<void> removeTodayCompletion(String habitId);
  Future<List<Map<String, dynamic>>> getHabitCompletions(String habitId);
  Future<List<Map<String, dynamic>>> getCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<int> getTotalHabitsCount();
  Future<int> getCompletedHabitsCount();
  Future<int> getActiveHabitsCount();

  // Development helpers
  Future<void> clearAllData();
  Future<bool> hasData();
  Future<bool> habitExists(String id);
  Future<bool> habitNameExists(String name);
  Future<String> getNextAvailableId();
  Future<void> cleanupWeeklySkippedHabits();
  Future<void> resetAllCompletionFlags();
  Future<void> syncCompletionStatus();
  Future<void> archiveHabit(String id);
  Future<List<HabitModel>> getArchivedHabits();
  Future<void> restoreHabit(String id);

  // Statistics
  Future<Map<String, dynamic>> getDailyStatistics(DateTime date);
  Future<List<Map<String, dynamic>>> getWeeklyStatistics(DateTime startDate);
  Future<List<Map<String, dynamic>>> getMonthlyStatistics(DateTime month);
  Future<List<Map<String, dynamic>>> getHabitConsistencyStats();
  Future<List<Map<String, dynamic>>> getHabitsByStatus(String status);
}
