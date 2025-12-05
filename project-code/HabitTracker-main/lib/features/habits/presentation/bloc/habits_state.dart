import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';

enum HabitsView { today, weekly, overall }

enum TimeFilter { all, morning, afternoon, evening }

abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

class HabitsLoaded extends HabitsState {
  final List<Habit> habits;
  final HabitsView currentView;
  final TimeFilter timeFilter;

  const HabitsLoaded({
    required this.habits,
    this.currentView = HabitsView.today,
    this.timeFilter = TimeFilter.all,
  });

  List<Habit> get activeHabits => habits.where((h) => !h.isCompleted).toList();

  List<Habit> get completedHabits =>
      habits.where((h) => h.isCompleted).toList();

  List<Habit> get skippedHabits => habits
      .where(
        (h) =>
            !h.isCompleted &&
            h.isSkippedToday,
      )
      .toList();

  List<Habit> get filteredActiveHabits {
    List<Habit> filteredHabits = activeHabits;

    // Filter by view (today, weekly, overall)
    switch (currentView) {
      case HabitsView.today:
        // Show only daily habits, weekly habits scheduled for today, and monthly habits scheduled for today
        filteredHabits = filteredHabits.where((habit) {
          // Don't show skipped habits in today view
          if (habit.isSkippedToday) return false;

          if (habit.repeatType == RepeatType.daily) {
            return true; // Daily habits always show in today view
          } else if (habit.repeatType == RepeatType.weekly) {
            // Check if today is one of the selected days for this weekly habit
            final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
            final adjustedToday = today == 7
                ? 0
                : today; // Convert Sunday from 7 to 0
            return habit.selectedDays.contains(adjustedToday);
          } else if (habit.repeatType == RepeatType.monthly) {
            // Check if today's date is in selectedMonthDates
            final today = DateTime.now();
            return habit.selectedMonthDates.contains(today.day);
          }
          return false;
        }).toList();
        break;
      case HabitsView.weekly:
        // Show only weekly habits
        filteredHabits = filteredHabits.where((habit) {
          return habit.repeatType == RepeatType.weekly;
        }).toList();
        break;
      case HabitsView.overall:
        // Show all habits
        break;
    }

    // Apply time filter
    if (timeFilter == TimeFilter.all) return filteredHabits;

    return filteredHabits.where((habit) {
      switch (timeFilter) {
        case TimeFilter.morning:
          return habit.timeOfDay == HabitTimeOfDay.morning ||
              habit.timeOfDay == HabitTimeOfDay.anytime;
        case TimeFilter.afternoon:
          return habit.timeOfDay == HabitTimeOfDay.afternoon ||
              habit.timeOfDay == HabitTimeOfDay.anytime;
        case TimeFilter.evening:
          return habit.timeOfDay == HabitTimeOfDay.evening ||
              habit.timeOfDay == HabitTimeOfDay.anytime;
        default:
          return true;
      }
    }).toList();
  }

  HabitsLoaded copyWith({
    List<Habit>? habits,
    HabitsView? currentView,
    TimeFilter? timeFilter,
  }) {
    return HabitsLoaded(
      habits: habits ?? this.habits,
      currentView: currentView ?? this.currentView,
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }

  @override
  List<Object?> get props => [habits, currentView, timeFilter];
}

class HabitsError extends HabitsState {
  final String message;

  const HabitsError({required this.message});

  @override
  List<Object?> get props => [message];
}
