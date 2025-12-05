import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/habit.dart' as domain;
import '../../domain/repositories/habits_repository.dart';
import '../../data/models/habit_model.dart' as data;
import 'habits_state.dart';

class HabitsCubit extends Cubit<HabitsState> {
  final HabitsRepository _repository;

  HabitsCubit({required HabitsRepository repository})
    : _repository = repository,
      super(const HabitsLoading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      emit(const HabitsLoading());

      // Reset completion status if date has changed (must be done before loading habits)
      await _resetCompletionStatusIfNeeded();

      final habits = await _repository.getAllHabits();

      // Clean up any weekly habits that have isSkippedToday = true
      await _repository.cleanupWeeklySkippedHabits();

      // Reset skipped habits if date has changed
      await _resetSkippedHabitsIfNeeded(habits);

      // Sync completion status with completion records (after reset)
      await _repository.syncCompletionStatus();

      // Reload habits after reset to get updated completion status
      final updatedHabits = await _repository.getAllHabits();

      // Convert HabitModel to Habit entity
      final habitEntities = updatedHabits
          .map(
            (model) => domain.Habit(
              id: model.id,
              name: model.name,
              emoji: model.emoji,
              colorHex: model.colorHex,
              timeOfDay: _convertTimeOfDay(model.timeOfDay),
              status: _convertStatusToDomain(model.status),
              isCompleted: model.isCompleted,
              repeatType: _convertRepeatType(model.repeatType),
              selectedDays: model.selectedDays,
              isSkippedToday: model.isSkippedToday,
            ),
          )
          .toList();

      emit(HabitsLoaded(habits: habitEntities));
    } catch (e) {
      emit(HabitsError(message: e.toString()));
    }
  }

  void changeView(HabitsView view) {
    if (state is HabitsLoaded) {
      emit((state as HabitsLoaded).copyWith(currentView: view));
    }
  }

  void changeTimeFilter(TimeFilter filter) {
    if (state is HabitsLoaded) {
      emit((state as HabitsLoaded).copyWith(timeFilter: filter));
    }
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    if (state is HabitsLoaded) {
      try {
        final currentState = state as HabitsLoaded;
        final habit = currentState.habits.firstWhere((h) => h.id == habitId);
        final newCompletionStatus = !habit.isCompleted;

        // Update in database
        await _repository.toggleHabitCompletion(habitId, newCompletionStatus);

        // Handle completion records
        if (newCompletionStatus) {
          // Marking as completed: record completion (only if not already recorded today)
          await _repository.recordHabitCompletion(habitId);
        } else {
          // Marking as un-completed: remove today's completion record
          await _repository.removeTodayCompletion(habitId);
        }

        // Update local state
        final updatedHabits = currentState.habits.map((h) {
          if (h.id == habitId) {
            return h.copyWith(isCompleted: newCompletionStatus);
          }
          return h;
        }).toList();

        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> addHabit(domain.Habit habit) async {
    if (state is HabitsLoaded) {
      try {
        // Convert Habit entity to HabitModel with provided ID
        final habitModel = data.HabitModel(
          id: habit.id, // Use the provided ID from the habit entity
          name: habit.name,
          emoji: habit.emoji,
          colorHex: habit.colorHex,
          timeOfDay: _convertTimeOfDayToData(habit.timeOfDay),
          status: _convertStatusToData(habit.status),
          isCompleted: habit.isCompleted,
          repeatType: _convertRepeatTypeToData(habit.repeatType),
          selectedDays: habit.selectedDays,
          isSkippedToday: habit.isSkippedToday,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to database
        await _repository.insertHabit(habitModel);

        // Update local state
        final currentState = state as HabitsLoaded;
        final updatedHabits = [...currentState.habits, habit];
        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> updateHabit(domain.Habit habit) async {
    if (state is HabitsLoaded) {
      try {
        // Get existing habit to preserve all fields not in domain entity
        final existingHabitModel = await _repository.getHabitById(habit.id);
        if (existingHabitModel == null) {
          emit(HabitsError(message: 'Habit not found'));
          return;
        }

        // Convert Habit entity to HabitModel, preserving reminder and end habit fields
        final updatedModel = existingHabitModel.copyWith(
          name: habit.name,
          emoji: habit.emoji,
          colorHex: habit.colorHex,
          timeOfDay: _convertTimeOfDayToData(habit.timeOfDay),
          status: _convertStatusToData(habit.status),
          isCompleted: habit.isCompleted,
          repeatType: _convertRepeatTypeToData(habit.repeatType),
          selectedDays: habit.selectedDays,
          isSkippedToday: habit.isSkippedToday,
          updatedAt: DateTime.now(),
        );

        await _repository.updateHabit(updatedModel);

        // Update local state
        final currentState = state as HabitsLoaded;
        final updatedHabits = currentState.habits.map((h) {
          if (h.id == habit.id) {
            return habit;
          }
          return h;
        }).toList();
        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> deleteHabit(String habitId) async {
    if (state is HabitsLoaded) {
      try {
        // Delete from database
        await _repository.deleteHabit(habitId);

        // Update local state
        final currentState = state as HabitsLoaded;
        final updatedHabits = currentState.habits
            .where((habit) => habit.id != habitId)
            .toList();
        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> archiveHabit(String habitId) async {
    if (state is HabitsLoaded) {
      try {
        // Archive habit (keep data but mark as archived)
        await _repository.archiveHabit(habitId);

        // Update local state - remove from active list
        final currentState = state as HabitsLoaded;
        final updatedHabits = currentState.habits
            .where((habit) => habit.id != habitId)
            .toList();
        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> restoreHabit(String habitId) async {
    try {
      // Restore habit (unarchive)
      await _repository.restoreHabit(habitId);

      // Reload habits to include the restored habit
      await _loadHabits();
    } catch (e) {
      emit(HabitsError(message: e.toString()));
    }
  }

  Future<void> resetDatabase() async {
    try {
      emit(const HabitsLoading());
      await _repository.clearAllData();
      emit(const HabitsLoaded(habits: []));
    } catch (e) {
      emit(HabitsError(message: e.toString()));
    }
  }

  Future<void> markAllHabitsComplete() async {
    if (state is HabitsLoaded) {
      try {
        final currentState = state as HabitsLoaded;
        final activeHabits = currentState.habits
            .where((h) => !h.isCompleted)
            .toList();

        // Update all active habits to completed
        for (final habit in activeHabits) {
          await _repository.toggleHabitCompletion(habit.id, true);
          await _repository.recordHabitCompletion(habit.id);
        }

        // Update local state
        final updatedHabits = currentState.habits
            .map((h) => h.copyWith(isCompleted: true))
            .toList();
        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> clearCompletedHabits() async {
    if (state is HabitsLoaded) {
      try {
        final currentState = state as HabitsLoaded;
        final completedHabits = currentState.habits
            .where((h) => h.isCompleted)
            .toList();

        // Delete all completed habits from database
        for (final habit in completedHabits) {
          await _repository.deleteHabit(habit.id);
        }

        // Update local state to only keep active habits
        final activeHabits = currentState.habits
            .where((h) => !h.isCompleted)
            .toList();
        emit(currentState.copyWith(habits: activeHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<void> skipHabitForToday(String habitId) async {
    if (state is HabitsLoaded) {
      try {
        final currentState = state as HabitsLoaded;

        // Update in database
        await _repository.toggleHabitSkip(habitId, true);

        // Update local state
        final updatedHabits = currentState.habits.map((h) {
          if (h.id == habitId) {
            return h.copyWith(isSkippedToday: true);
          }
          return h;
        }).toList();

        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  Future<bool> isHabitNameDuplicate(String name) async {
    try {
      return await _repository.habitNameExists(name);
    } catch (e) {
      return false; // Return false on error to allow creation
    }
  }

  Future<void> undoSkipHabit(String habitId) async {
    if (state is HabitsLoaded) {
      try {
        final currentState = state as HabitsLoaded;

        // Update in database
        await _repository.toggleHabitSkip(habitId, false);

        // Update local state
        final updatedHabits = currentState.habits.map((h) {
          if (h.id == habitId) {
            return h.copyWith(isSkippedToday: false);
          }
          return h;
        }).toList();

        emit(currentState.copyWith(habits: updatedHabits));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    }
  }

  // Helper methods to convert between data and domain enums
  domain.HabitTimeOfDay _convertTimeOfDay(data.HabitTimeOfDay dataTimeOfDay) {
    switch (dataTimeOfDay) {
      case data.HabitTimeOfDay.morning:
        return domain.HabitTimeOfDay.morning;
      case data.HabitTimeOfDay.afternoon:
        return domain.HabitTimeOfDay.afternoon;
      case data.HabitTimeOfDay.evening:
        return domain.HabitTimeOfDay.evening;
      case data.HabitTimeOfDay.anytime:
        return domain.HabitTimeOfDay.anytime;
    }
  }

  // Helper methods to convert from domain to data enums
  data.HabitTimeOfDay _convertTimeOfDayToData(
    domain.HabitTimeOfDay domainTimeOfDay,
  ) {
    switch (domainTimeOfDay) {
      case domain.HabitTimeOfDay.morning:
        return data.HabitTimeOfDay.morning;
      case domain.HabitTimeOfDay.afternoon:
        return data.HabitTimeOfDay.afternoon;
      case domain.HabitTimeOfDay.evening:
        return data.HabitTimeOfDay.evening;
      case domain.HabitTimeOfDay.anytime:
        return data.HabitTimeOfDay.anytime;
    }
  }

  data.HabitStatus _convertStatusToData(domain.HabitStatus domainStatus) {
    switch (domainStatus) {
      case domain.HabitStatus.active:
        return data.HabitStatus.active;
      case domain.HabitStatus.completed:
        return data.HabitStatus.completed;
    }
  }

  domain.HabitStatus _convertStatusToDomain(data.HabitStatus dataStatus) {
    switch (dataStatus) {
      case data.HabitStatus.active:
        return domain.HabitStatus.active;
      case data.HabitStatus.completed:
        return domain.HabitStatus.completed;
    }
  }

  domain.RepeatType _convertRepeatType(data.RepeatType dataRepeatType) {
    switch (dataRepeatType) {
      case data.RepeatType.daily:
        return domain.RepeatType.daily;
      case data.RepeatType.weekly:
        return domain.RepeatType.weekly;
      case data.RepeatType.monthly:
        return domain.RepeatType.monthly;
    }
  }

  data.RepeatType _convertRepeatTypeToData(domain.RepeatType domainRepeatType) {
    switch (domainRepeatType) {
      case domain.RepeatType.daily:
        return data.RepeatType.daily;
      case domain.RepeatType.weekly:
        return data.RepeatType.weekly;
      case domain.RepeatType.monthly:
        return data.RepeatType.monthly;
    }
  }

  Future<void> _resetSkippedHabitsIfNeeded(List<data.HabitModel> habits) async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if we have a stored date for when habits were last reset
    final lastResetDate = await _getLastResetDate();

    // If no stored date or date has changed, reset all skipped habits
    if (lastResetDate != todayString) {
      final skippedHabits = habits
          .where((habit) => habit.isSkippedToday)
          .toList();

      for (final habit in skippedHabits) {
        await _repository.toggleHabitSkip(habit.id, false);
      }

      // Store today's date as the last reset date
      await _setLastResetDate(todayString);
    }
  }

  Future<void> _resetCompletionStatusIfNeeded() async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if we have a stored date for when completion status was last reset
    final lastResetDate = await _getLastCompletionResetDate();

    // If no stored date or date has changed, reset all completion flags
    if (lastResetDate != todayString) {
      await _repository.resetAllCompletionFlags();

      // Store today's date as the last reset date
      await _setLastCompletionResetDate(todayString);
    }
  }

  Future<String?> _getLastResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_reset_date');
    } catch (e) {
      return null;
    }
  }

  Future<void> _setLastResetDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_reset_date', date);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<String?> _getLastCompletionResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_completion_reset_date');
    } catch (e) {
      return null;
    }
  }

  Future<void> _setLastCompletionResetDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_completion_reset_date', date);
    } catch (e) {
      // Ignore errors
    }
  }
}
