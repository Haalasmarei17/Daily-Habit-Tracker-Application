import 'package:equatable/equatable.dart';

enum HabitTimeOfDay { morning, afternoon, evening, anytime }

enum HabitStatus { active, completed }

enum RepeatType { daily, weekly, monthly }

class HabitModel extends Equatable {
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
  final bool endHabitEnabled;
  final String? endHabitMode;
  final DateTime? endDate;
  final int? daysAfter;
  final bool reminderEnabled;
  final String? reminderTime;
  final bool isSkippedToday;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitModel({
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
    this.endHabitEnabled = false,
    this.endHabitMode,
    this.endDate,
    this.daysAfter,
    this.reminderEnabled = false,
    this.reminderTime,
    this.isSkippedToday = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitModel copyWith({
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
    bool? endHabitEnabled,
    String? endHabitMode,
    DateTime? endDate,
    int? daysAfter,
    bool? reminderEnabled,
    String? reminderTime,
    bool? isSkippedToday,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
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
      endHabitEnabled: endHabitEnabled ?? this.endHabitEnabled,
      endHabitMode: endHabitMode ?? this.endHabitMode,
      endDate: endDate ?? this.endDate,
      daysAfter: daysAfter ?? this.daysAfter,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isSkippedToday: isSkippedToday ?? this.isSkippedToday,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color_hex': colorHex,
      'time_of_day': timeOfDay.name,
      'status': status.name,
      'is_completed': isCompleted ? 1 : 0,
      'repeat_type': repeatType.name,
      'selected_days': selectedDays.join(','),
      'selected_month_dates': selectedMonthDates.join(','),
      'end_habit_enabled': endHabitEnabled ? 1 : 0,
      'end_habit_mode': endHabitMode,
      'end_date': endDate?.toIso8601String(),
      'days_after': daysAfter,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'is_skipped_today': isSkippedToday ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      colorHex: json['color_hex'],
      timeOfDay: HabitTimeOfDay.values.firstWhere(
        (e) => e.name == json['time_of_day'],
        orElse: () => HabitTimeOfDay.anytime,
      ),
      status: HabitStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HabitStatus.active,
      ),
      isCompleted: json['is_completed'] == 1,
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == json['repeat_type'],
        orElse: () => RepeatType.daily,
      ),
      selectedDays:
          json['selected_days'] != null && json['selected_days'].isNotEmpty
          ? json['selected_days']
                .split(',')
                .map((e) => int.parse(e))
                .toSet()
                .cast<int>()
          : const <int>{0, 1, 2, 3, 4, 5, 6},
      selectedMonthDates:
          json['selected_month_dates'] != null &&
              json['selected_month_dates'].isNotEmpty
          ? json['selected_month_dates']
                .split(',')
                .map((e) => int.parse(e))
                .toSet()
                .cast<int>()
          : const <int>{},
      endHabitEnabled: json['end_habit_enabled'] == 1,
      endHabitMode: json['end_habit_mode'],
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      daysAfter: json['days_after'],
      reminderEnabled: json['reminder_enabled'] == 1,
      reminderTime: json['reminder_time'],
      isSkippedToday: json['is_skipped_today'] == 1,
      isArchived: (json['is_archived'] ?? 0) == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    endHabitEnabled,
    endHabitMode,
    endDate,
    daysAfter,
    reminderEnabled,
    reminderTime,
    isSkippedToday,
    isArchived,
    createdAt,
    updatedAt,
  ];
}
