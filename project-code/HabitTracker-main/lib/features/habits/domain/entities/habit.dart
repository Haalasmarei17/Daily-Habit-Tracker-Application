import 'package:equatable/equatable.dart';

enum HabitTimeOfDay { morning, afternoon, evening, anytime }

enum HabitStatus { active, completed }

enum RepeatType { daily, weekly, monthly }

class Habit extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String colorHex;
  final HabitTimeOfDay timeOfDay;
  final HabitStatus status;
  final bool isCompleted;
  final RepeatType repeatType;
  final Set<int> selectedDays;
  final Set<int> selectedMonthDates;
  final bool isSkippedToday;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.timeOfDay,
    this.status = HabitStatus.active,
    this.isCompleted = false,
    this.repeatType = RepeatType.daily,
    this.selectedDays = const <int>{0, 1, 2, 3, 4, 5, 6},
    this.selectedMonthDates = const <int>{},
    this.isSkippedToday = false,
  });

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    String? colorHex,
    HabitTimeOfDay? timeOfDay,
    HabitStatus? status,
    bool? isCompleted,
    RepeatType? repeatType,
    Set<int>? selectedDays,
    Set<int>? selectedMonthDates,
    bool? isSkippedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedMonthDates: selectedMonthDates ?? this.selectedMonthDates,
      isSkippedToday: isSkippedToday ?? this.isSkippedToday,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    emoji,
    colorHex,
    timeOfDay,
    status,
    isCompleted,
    repeatType,
    selectedDays,
    selectedMonthDates,
    isSkippedToday,
  ];
}
