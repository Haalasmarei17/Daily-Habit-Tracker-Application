import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart' as domain;
import '../../data/models/habit_model.dart' as data;
import '../bloc/habits_cubit.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../../../core/di/injection_container.dart';

data.HabitTimeOfDay _convertTimeOfDayToData(domain.HabitTimeOfDay domainTimeOfDay) {
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

class EditHabitPage extends StatefulWidget {
  final String habitId;

  const EditHabitPage({super.key, required this.habitId});

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _daysAfterController;
  String _selectedEmoji = '🎯';
  String _selectedColor = 'FFB3BA';
  String _selectedRepeat = 'Daily';
  Set<int> _selectedDays = {0, 1, 2, 3, 4, 5, 6};
  final Set<int> _selectedMonthDates = {};
  domain.HabitTimeOfDay _selectedTimeOfDay = domain.HabitTimeOfDay.morning;
  bool _endHabitEnabled = false;
  bool _reminderEnabled = false;
  bool _allDaySelected = true;
  String _endHabitMode = 'Days';
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = true;
  data.HabitModel? _originalHabit;

  final List<String> _emojiList = [
    '🎯',
    '🏆',
    '🥇',
    '🏀',
    '⚽',
    '🏋️',
    '🧘',
    '📚',
    '💼',
    '🎨',
    '🎵',
    '🎮',
    '🍎',
    '💧',
    '😴',
    '🧠',
  ];

  final List<String> _colorList = [
    'FFFACD',
    'FFDFBA',
    'B8A196',
    'C19A9A',
    'FFB3BA',
    'FFC1CC',
    'FFB3D9',
    'E0BBE4',
    'C5B3FF',
    'D4C5F9',
    'BAE1FF',
    'B4D4D3',
    'BAFFC9',
    'BAF5C3',
    'RAINBOW',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _daysAfterController = TextEditingController(text: '365');
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    try {
      final repository = getIt<HabitsRepository>();
      final habitModel = await repository.getHabitById(widget.habitId);
      
      if (habitModel != null && mounted) {
        setState(() {
          _originalHabit = habitModel;
          _nameController.text = habitModel.name;
          _selectedEmoji = habitModel.emoji;
          _selectedColor = habitModel.colorHex;
          _selectedRepeat = _convertRepeatTypeToString(habitModel.repeatType);
          _selectedDays = Set<int>.from(habitModel.selectedDays);
          _selectedMonthDates.clear();
          _selectedMonthDates.addAll(habitModel.selectedMonthDates);
          _selectedTimeOfDay = _convertTimeOfDayToDomain(habitModel.timeOfDay);
          _endHabitEnabled = habitModel.endHabitEnabled;
          _endHabitMode = habitModel.endHabitMode ?? 'Days';
          _endDate = habitModel.endDate ?? DateTime.now().add(const Duration(days: 365));
          _daysAfterController.text = (habitModel.daysAfter ?? 365).toString();
          _reminderEnabled = habitModel.reminderEnabled;
          if (habitModel.reminderTime != null) {
            final parts = habitModel.reminderTime!.split(':');
            _reminderTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          _allDaySelected = _selectedDays.length == 7;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habit: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysAfterController.dispose();
    super.dispose();
  }

  String _convertRepeatTypeToString(data.RepeatType repeatType) {
    switch (repeatType) {
      case data.RepeatType.daily:
        return 'Daily';
      case data.RepeatType.weekly:
        return 'Weekly';
      case data.RepeatType.monthly:
        return 'Monthly';
    }
  }

  domain.HabitTimeOfDay _convertTimeOfDayToDomain(data.HabitTimeOfDay dataTimeOfDay) {
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

  domain.HabitStatus _convertStatusToDomain(data.HabitStatus dataStatus) {
    switch (dataStatus) {
      case data.HabitStatus.active:
        return domain.HabitStatus.active;
      case data.HabitStatus.completed:
        return domain.HabitStatus.completed;
    }
  }

  domain.RepeatType _convertRepeatTypeToDomain(data.RepeatType dataRepeatType) {
    switch (dataRepeatType) {
      case data.RepeatType.daily:
        return domain.RepeatType.daily;
      case data.RepeatType.weekly:
        return domain.RepeatType.weekly;
      case data.RepeatType.monthly:
        return domain.RepeatType.monthly;
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  int get _selectedWeekDaysCount => _selectedDays.length;

  Future<void> _saveHabit() async {
    // Validate habit name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    if (_nameController.text.trim().length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit name must be 100 characters or less'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_originalHabit == null) return;

    // Validate weekly habit has selected days
    if (_selectedRepeat == 'Weekly' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for weekly habits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate monthly habit has selected dates
    if (_selectedRepeat == 'Monthly' && _selectedMonthDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one date for monthly habits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate end date is in the future
    if (_endHabitEnabled && _endHabitMode == 'Date' && _endDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be in the future'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate days after is positive
    if (_endHabitEnabled && _endHabitMode == 'Days') {
      final daysAfter = int.tryParse(_daysAfterController.text) ?? 0;
      if (daysAfter <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Days after must be greater than 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Check for duplicate name (excluding current habit)
    final isDuplicate = await context.read<HabitsCubit>().isHabitNameDuplicate(
      _nameController.text.trim(),
    );
    if (isDuplicate && _nameController.text.trim() != _originalHabit!.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A habit with the name "${_nameController.text.trim()}" already exists',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert repeat type string to enum
    data.RepeatType repeatType;
    switch (_selectedRepeat) {
      case 'Daily':
        repeatType = data.RepeatType.daily;
        break;
      case 'Weekly':
        repeatType = data.RepeatType.weekly;
        break;
      case 'Monthly':
        repeatType = data.RepeatType.monthly;
        break;
      default:
        repeatType = data.RepeatType.daily;
    }

    // Create Habit entity
    final habit = domain.Habit(
      id: _originalHabit!.id,
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      colorHex: _selectedColor == 'RAINBOW' ? 'FFB3BA' : _selectedColor,
      timeOfDay: _selectedTimeOfDay,
      status: _convertStatusToDomain(_originalHabit!.status),
      isCompleted: _originalHabit!.isCompleted,
      repeatType: _convertRepeatTypeToDomain(repeatType),
      selectedDays: _selectedDays,
      selectedMonthDates: _selectedMonthDates,
      isSkippedToday: _originalHabit!.isSkippedToday,
    );

    // Update the full HabitModel with reminder and end habit settings
    final updatedModel = _originalHabit!.copyWith(
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      colorHex: _selectedColor == 'RAINBOW' ? 'FFB3BA' : _selectedColor,
      timeOfDay: _convertTimeOfDayToData(_selectedTimeOfDay),
      repeatType: repeatType,
      selectedDays: _selectedDays,
      selectedMonthDates: _selectedMonthDates,
      endHabitEnabled: _endHabitEnabled,
      endHabitMode: _endHabitEnabled ? _endHabitMode : null,
      endDate: _endHabitEnabled && _endHabitMode == 'Date' ? _endDate : null,
      daysAfter: _endHabitEnabled && _endHabitMode == 'Days'
          ? int.tryParse(_daysAfterController.text) ?? 365
          : null,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled
          ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
          : null,
      updatedAt: DateTime.now(),
    );

    try {
      if (mounted) {
        // Update via repository to save all fields including reminder and end habit
        final repository = getIt<HabitsRepository>();
        await repository.updateHabit(updatedModel);
        
        // Also update via cubit to update UI state
        await context.read<HabitsCubit>().updateHabit(habit);
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Habit',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Name
            const Text(
              'Habit Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Habit Name',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Icon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  final emoji = _emojiList[index];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF6366F1),
                                width: 2,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorList.map((colorHex) {
                final isSelected = colorHex == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = colorHex);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorHex == 'RAINBOW'
                          ? null
                          : Color(int.parse('FF$colorHex', radix: 16)),
                      gradient: colorHex == 'RAINBOW'
                          ? const LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                              ],
                            )
                          : null,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Repeat
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRepeatButton('Daily'),
                const SizedBox(width: 8),
                _buildRepeatButton('Weekly'),
                const SizedBox(width: 8),
                _buildRepeatButton('Monthly'),
              ],
            ),
            const SizedBox(height: 24),

            // Days of Week / Monthly Calendar / Weekly Info
            if (_selectedRepeat == 'Daily') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'On these day:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'All day',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 24,
                        child: Checkbox(
                          value: _allDaySelected,
                          onChanged: (value) {
                            setState(() {
                              _allDaySelected = value ?? false;
                              if (_allDaySelected) {
                                _selectedDays = {0, 1, 2, 3, 4, 5, 6};
                              }
                            });
                          },
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final isSelected = _selectedDays.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected && !_allDaySelected) {
                          _selectedDays.remove(index);
                        } else {
                          _allDaySelected = false;
                          _selectedDays.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ] else if (_selectedRepeat == 'Weekly') ...[
              Text(
                '$_selectedWeekDaysCount days per week',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final days = ['1', '2', '3', '4', '5', '6', '7'];
                  final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final isSelected = _selectedDays.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(index);
                        } else {
                          _selectedDays.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ] else if (_selectedRepeat == 'Monthly') ...[
              const SizedBox(height: 12),
              _buildMonthlyCalendar(),
              const SizedBox(height: 24),
            ],

            // Time of Day
            const Text(
              'Do it at:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeButton('Morning', domain.HabitTimeOfDay.morning),
                const SizedBox(width: 8),
                _buildTimeButton('Afternoon', domain.HabitTimeOfDay.afternoon),
                const SizedBox(width: 8),
                _buildTimeButton('Evening', domain.HabitTimeOfDay.evening),
              ],
            ),
            const SizedBox(height: 24),

            // End Habit Toggle
            _buildToggleRow('End Habit on', _endHabitEnabled, (value) {
              setState(() => _endHabitEnabled = value);
            }),

            // End Habit Options
            if (_endHabitEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildEndHabitTab('Date'),
                  const SizedBox(width: 8),
                  _buildEndHabitTab('Days'),
                ],
              ),
              const SizedBox(height: 16),
              if (_endHabitMode == 'Date')
                GestureDetector(
                  onTap: () => _selectEndDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 18, color: Colors.black38),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'After',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _daysAfterController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const Text(
                        'days',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 18, color: Colors.black38),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),

            // Reminder Toggle
            _buildToggleRow('Set Reminder', _reminderEnabled, (value) {
              setState(() => _reminderEnabled = value);
            }),

            // Reminder Time Picker
            if (_reminderEnabled) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectReminderTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _reminderTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 18, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveHabit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatButton(String label) {
    final isSelected = _selectedRepeat == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRepeat = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(String label, domain.HabitTimeOfDay timeOfDay) {
    final isSelected = _selectedTimeOfDay == timeOfDay;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTimeOfDay = timeOfDay);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildEndHabitTab(String label) {
    final isSelected = _endHabitMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _endHabitMode = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'December 2024',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days of week header
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (day) {
                final dayNumber = week * 7 + day - 1;
                final isSelected = _selectedMonthDates.contains(dayNumber);
                final isValidDay = dayNumber >= 0 && dayNumber < 31;

                return Expanded(
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.all(2),
                    child: isValidDay
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMonthDates.remove(dayNumber);
                                } else {
                                  _selectedMonthDates.add(dayNumber);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${dayNumber + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

