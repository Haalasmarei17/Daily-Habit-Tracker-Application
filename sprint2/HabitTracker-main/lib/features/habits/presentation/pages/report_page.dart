import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../data/models/habit_model.dart';

enum DateRangeOption {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last6Months,
  thisYear,
  lastYear,
  allTime,
  customRange,
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateRangeOption _selectedDateRange = DateRangeOption.thisWeek;
  bool _isLoading = false;
  int _totalDays = 0;
  int _habitsCompleted = 0;
  int _totalPerfectDays = 0;
  double _completionRate = 0.0;
  int _currentStreak = 0;
  List<Map<String, dynamic>>? _weeklyStats;
  List<Map<String, dynamic>>? _monthlyCompletionRate;
  List<Map<String, dynamic>>? _habitStreaks;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final repository = getIt<HabitsRepository>();
      final today = DateTime.now();

      DateTime startDate;
      DateTime endDate = today;

      // Calculate date range based on selection
      switch (_selectedDateRange) {
        case DateRangeOption.today:
          startDate = DateTime(today.year, today.month, today.day);
          break;
        case DateRangeOption.thisWeek:
          startDate = today.subtract(Duration(days: today.weekday - 1));
          break;
        case DateRangeOption.thisMonth:
          startDate = DateTime(today.year, today.month, 1);
          break;
        case DateRangeOption.lastMonth:
          startDate = DateTime(today.year, today.month - 1, 1);
          endDate = DateTime(
            today.year,
            today.month,
            1,
          ).subtract(const Duration(days: 1));
          break;
        case DateRangeOption.last6Months:
          startDate = DateTime(today.year, today.month - 6, today.day);
          break;
        case DateRangeOption.thisYear:
          startDate = DateTime(today.year, 1, 1);
          break;
        case DateRangeOption.lastYear:
          startDate = DateTime(today.year - 1, 1, 1);
          endDate = DateTime(today.year - 1, 12, 31);
          break;
        case DateRangeOption.allTime:
          // Get earliest habit creation date
          final habits = await repository.getAllHabits();
          if (habits.isEmpty) {
            startDate = today;
          } else {
            startDate = habits
                .map((h) => h.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
          }
          break;
        default:
          startDate = today.subtract(Duration(days: today.weekday - 1));
      }

      // Calculate statistics for the date range
      _totalDays = endDate.difference(startDate).inDays + 1;
      _habitsCompleted = 0;
      _totalPerfectDays = 0;
      int totalPossibleHabits = 0;

      // Get weekly stats for chart - start from first habit creation day
      final habits = await repository.getAllHabits();
      DateTime startOfWeek;
      if (habits.isEmpty) {
        // No habits, use Monday as default
        startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      } else {
        // Find the earliest habit creation date
        final earliestHabit = habits.reduce(
          (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
        );
        final firstHabitDay = earliestHabit.createdAt;
        final firstHabitWeekday =
            firstHabitDay.weekday; // 1 = Monday, 7 = Sunday

        // Find the most recent occurrence of that weekday (going back from today)
        final todayWeekday = today.weekday;
        int daysToSubtract;
        if (todayWeekday >= firstHabitWeekday) {
          // The weekday has already occurred this week
          daysToSubtract = todayWeekday - firstHabitWeekday;
        } else {
          // The weekday hasn't occurred yet this week, go back to last week
          daysToSubtract = 7 - (firstHabitWeekday - todayWeekday);
        }

        startOfWeek = today.subtract(Duration(days: daysToSubtract));
        // Normalize to start of day
        startOfWeek = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
      }
      _weeklyStats = await repository.getWeeklyStatistics(startOfWeek);

      // Calculate completion stats for the date range
      final dailyStats = <Map<String, dynamic>>[];
      for (int i = 0; i < _totalDays; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final dayStats = await repository.getDailyStatistics(currentDate);
        final completed = dayStats['completed'] as int;
        final total = dayStats['total'] as int;

        _habitsCompleted += completed;
        totalPossibleHabits += total;

        if (total > 0 && completed == total) {
          _totalPerfectDays++;
        }

        dailyStats.add({
          'date': currentDate,
          'completed': completed,
          'total': total,
          'rate': total > 0 ? (completed / total * 100) : 0,
        });
      }

      _completionRate = totalPossibleHabits > 0
          ? (_habitsCompleted / totalPossibleHabits * 100)
          : 0.0;

      // Calculate completion rate chart data based on selected date range
      _monthlyCompletionRate = await _calculateCompletionRateChartData(
        startDate,
        endDate,
        _selectedDateRange,
        repository,
      );

      // Calculate individual habit streaks
      await _calculateHabitStreaks(repository);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading statistics: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _calculateHabitStreaks(HabitsRepository repository) async {
    _habitStreaks = [];
    _currentStreak = 0; // Reset streak
    final habits = await repository.getAllHabits();

    // If no habits, streak is 0
    if (habits.isEmpty) {
      return;
    }

    for (final habit in habits) {
      // Calculate current streak
      int currentStreak = 0;

      // Get all completions
      final completions = await repository.getHabitCompletions(habit.id);

      if (completions.isNotEmpty) {
        // Group completions by day
        final completionsByDay = <DateTime>{};
        for (final completion in completions) {
          final completedAt = DateTime.parse(
            completion['completed_at'] as String,
          );
          final day = DateTime(
            completedAt.year,
            completedAt.month,
            completedAt.day,
          );
          completionsByDay.add(day);
        }

        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        // Check if today is scheduled for this habit
        bool isTodayScheduled = _isDateScheduled(habit, todayDate);

        // Check if today is completed
        bool isTodayCompleted =
            habit.isCompleted && completionsByDay.contains(todayDate);

        if (isTodayScheduled && isTodayCompleted) {
          // Today is scheduled and completed, so start counting from today
          currentStreak = 1;
          currentStreak += _countConsecutiveScheduledCompletions(
            habit,
            todayDate.subtract(const Duration(days: 1)),
            completionsByDay,
          );
        } else {
          // Today doesn't count (either not scheduled, not completed, or was un-completed)
          // Check backwards from yesterday
          var checkDate = todayDate.subtract(const Duration(days: 1));
          int maxLookback = 365; // Look back up to 1 year
          int lookbackCount = 0;

          // Find the most recent scheduled and completed day
          while (lookbackCount < maxLookback) {
            if (_isDateScheduled(habit, checkDate) &&
                completionsByDay.contains(checkDate)) {
              // Found a scheduled and completed day
              currentStreak = 1;
              currentStreak += _countConsecutiveScheduledCompletions(
                habit,
                checkDate.subtract(const Duration(days: 1)),
                completionsByDay,
              );
              break;
            }
            checkDate = checkDate.subtract(const Duration(days: 1));
            lookbackCount++;
          }
        }
      }

      // Calculate completion rate for the habit
      final allCompletions = await repository.getHabitCompletions(habit.id);
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentCompletions = allCompletions.where((c) {
        final completedAt = DateTime.parse(c['completed_at'] as String);
        return completedAt.isAfter(thirtyDaysAgo);
      }).length;

      _habitStreaks!.add({
        'habit_id': habit.id,
        'habit_name': habit.name,
        'emoji': habit.emoji,
        'color_hex': habit.colorHex,
        'current_streak': currentStreak,
        'total_completions': allCompletions.length,
        'completion_rate': (recentCompletions / 30.0 * 100.0).clamp(0.0, 100.0),
      });
    }

    // Sort by current streak (highest first)
    _habitStreaks!.sort(
      (a, b) =>
          (b['current_streak'] as int).compareTo(a['current_streak'] as int),
    );

    // Calculate the maximum current streak across all habits
    if (_habitStreaks!.isNotEmpty) {
      _currentStreak = _habitStreaks!
          .map((s) => s['current_streak'] as int)
          .reduce((a, b) => a > b ? a : b);
    } else {
      _currentStreak = 0;
    }
  }

  /// Check if a date is scheduled for a habit based on its repeat type
  bool _isDateScheduled(HabitModel habit, DateTime date) {
    switch (habit.repeatType) {
      case RepeatType.daily:
        return true;
      case RepeatType.weekly:
        // Check if the weekday is in selectedDays
        // DateTime.weekday: 1 = Monday, 7 = Sunday
        // Our selectedDays: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
        final weekday = date.weekday; // 1-7
        final adjustedWeekday = weekday == 7 ? 0 : weekday;
        return habit.selectedDays.contains(adjustedWeekday);
      case RepeatType.monthly:
        // Check if the day of month is in selectedMonthDates
        return habit.selectedMonthDates.contains(date.day);
    }
  }

  /// Count consecutive scheduled completions going backwards from a start date
  int _countConsecutiveScheduledCompletions(
    HabitModel habit,
    DateTime startDate,
    Set<DateTime> completionsByDay,
  ) {
    int count = 0;
    var checkDate = startDate;
    int maxIterations = 10000; // Safety limit
    int iterations = 0;

    while (iterations < maxIterations) {
      // Check if this date is scheduled for the habit
      if (!_isDateScheduled(habit, checkDate)) {
        // This date is not scheduled
        // For daily habits, any gap breaks the streak
        // For weekly/monthly, skip non-scheduled dates and continue
        if (habit.repeatType == RepeatType.daily) {
          break;
        } else {
          checkDate = checkDate.subtract(const Duration(days: 1));
          iterations++;
          continue;
        }
      }

      // This date is scheduled, check if it was completed
      if (completionsByDay.contains(checkDate)) {
        count++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        iterations++;
      } else {
        // This scheduled date was not completed, streak is broken
        break;
      }
    }

    return count;
  }

  Future<List<Map<String, dynamic>>> _calculateCompletionRateChartData(
    DateTime startDate,
    DateTime endDate,
    DateRangeOption dateRange,
    HabitsRepository repository,
  ) async {
    final chartData = <Map<String, dynamic>>[];
    final today = DateTime.now();

    switch (dateRange) {
      case DateRangeOption.today:
        // For today, show hourly data or just one point
        final dayStats = await repository.getDailyStatistics(startDate);
        final completed = dayStats['completed'] as int;
        final total = dayStats['total'] as int;
        final rate = total > 0 ? (completed / total * 100.0) : 0.0;
        chartData.add({'month': startDate, 'rate': rate});
        break;

      case DateRangeOption.thisWeek:
        // For this week, show daily data
        for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dayStats = await repository.getDailyStatistics(currentDate);
          final completed = dayStats['completed'] as int;
          final total = dayStats['total'] as int;
          final rate = total > 0 ? (completed / total * 100.0) : 0.0;
          chartData.add({'month': currentDate, 'rate': rate});
        }
        break;

      case DateRangeOption.thisMonth:
      case DateRangeOption.lastMonth:
        // For this/last month, show daily data
        var currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          final dayStats = await repository.getDailyStatistics(currentDate);
          final completed = dayStats['completed'] as int;
          final total = dayStats['total'] as int;
          final rate = total > 0 ? (completed / total * 100.0) : 0.0;
          chartData.add({'month': currentDate, 'rate': rate});
          currentDate = currentDate.add(const Duration(days: 1));
        }
        break;

      case DateRangeOption.last6Months:
      case DateRangeOption.thisYear:
      case DateRangeOption.lastYear:
      case DateRangeOption.allTime:
        // For longer ranges, show monthly data
        var currentMonth = DateTime(startDate.year, startDate.month, 1);
        final endMonth = DateTime(endDate.year, endDate.month, 1);

        while (currentMonth.isBefore(endMonth) ||
            currentMonth.isAtSameMomentAs(endMonth)) {
          final nextMonth = DateTime(
            currentMonth.year,
            currentMonth.month + 1,
            1,
          );
          final monthEnd = nextMonth.isBefore(today)
              ? nextMonth
              : DateTime.now();

          int monthCompleted = 0;
          int monthTotal = 0;
          var currentDate = currentMonth;

          while (currentDate.isBefore(monthEnd) &&
              !currentDate.isAfter(endDate)) {
            final dayStats = await repository.getDailyStatistics(currentDate);
            monthCompleted += dayStats['completed'] as int;
            monthTotal += dayStats['total'] as int;
            currentDate = currentDate.add(const Duration(days: 1));
          }

          final rate = monthTotal > 0
              ? (monthCompleted / monthTotal * 100.0)
              : 0.0;
          chartData.add({'month': currentMonth, 'rate': rate});

          currentMonth = nextMonth;
        }
        break;

      default:
        // Default to weekly data
        var currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          final dayStats = await repository.getDailyStatistics(currentDate);
          final completed = dayStats['completed'] as int;
          final total = dayStats['total'] as int;
          final rate = total > 0 ? (completed / total * 100.0) : 0.0;
          chartData.add({'month': currentDate, 'rate': rate});
          currentDate = currentDate.add(const Duration(days: 1));
        }
    }

    return chartData;
  }

  String _getDateRangeLabel() {
    switch (_selectedDateRange) {
      case DateRangeOption.today:
        return 'Today';
      case DateRangeOption.thisWeek:
        return 'This Week';
      case DateRangeOption.thisMonth:
        return 'This Month';
      case DateRangeOption.lastMonth:
        return 'Last Month';
      case DateRangeOption.last6Months:
        return 'Last 6 Months';
      case DateRangeOption.thisYear:
        return 'This Year';
      case DateRangeOption.lastYear:
        return 'Last Year';
      case DateRangeOption.allTime:
        return 'All Time';
      default:
        return 'Custom Range';
    }
  }

  void _showDateRangeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateRangeOption('Today', DateRangeOption.today),
            _buildDateRangeOption('This Week', DateRangeOption.thisWeek),
            _buildDateRangeOption('This Month', DateRangeOption.thisMonth),
            _buildDateRangeOption('Last Month', DateRangeOption.lastMonth),
            _buildDateRangeOption('Last 6 Months', DateRangeOption.last6Months),
            _buildDateRangeOption('This Year', DateRangeOption.thisYear),
            _buildDateRangeOption('Last Year', DateRangeOption.lastYear),
            _buildDateRangeOption('All Time', DateRangeOption.allTime),
            // _buildDateRangeOption('Custom Range', DateRangeOption.customRange),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeOption(String label, DateRangeOption option) {
    final isSelected = _selectedDateRange == option;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF6366F1))
          : null,
      onTap: () {
        setState(() => _selectedDateRange = option);
        Navigator.pop(context);
        _loadStatistics();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Report',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              _showDateRangeOptions(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _currentStreak > 0
                                ? '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}'
                                : '0 days',
                            'Current streak',
                            const Color(0xFFE8E5FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '${_completionRate.toStringAsFixed(0)}%',
                            'Completion rate',
                            const Color(0xFFE8E5FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '$_habitsCompleted',
                            'Habits completed',
                            const Color(0xFFE8E5FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '$_totalPerfectDays',
                            'Total perfect days',
                            const Color(0xFFE8E5FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Habits Completed Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Habits Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showDateRangeOptions(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _getDateRangeLabel(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weekly Chart
                    if (_weeklyStats != null && _weeklyStats!.isNotEmpty) ...[
                      _buildWeeklyChart(),
                      const SizedBox(height: 24),
                    ],

                    // Habit Completion Rate
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Habit Completion Rate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showDateRangeOptions(context),
                          child: Text(
                            _getDateRangeLabel(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Completion Rate Chart
                    if (_monthlyCompletionRate != null &&
                        _monthlyCompletionRate!.isNotEmpty)
                      _buildCompletionRateChart(),
                    const SizedBox(height: 24),

                    // Habit Streaks Section
                    if (_habitStreaks != null && _habitStreaks!.isNotEmpty) ...[
                      const Text(
                        'Habit Streaks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHabitStreaksSection(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats == null || _weeklyStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the max value from actual data for better scaling
    final maxActualValue = _weeklyStats!.fold<int>(
      0,
      (max, stat) =>
          (stat['completed'] as int) > max ? (stat['completed'] as int) : max,
    );
    final maxValue = maxActualValue > 7 ? maxActualValue : 7;

    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Chart with Y-axis
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(maxValue + 1, (index) {
                      final value = maxValue - index;
                      return Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                // Bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _weeklyStats!.asMap().entries.map((entry) {
                      final stat = entry.value;
                      final completed = stat['completed'] as int;
                      final date = stat['date'] as DateTime;
                      final isToday =
                          DateTime.now().day == date.day &&
                          DateTime.now().month == date.month;
                      final heightFactor = maxValue > 0
                          ? (completed / maxValue).clamp(0.0, 1.0)
                          : 0.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Bar
                              FractionallySizedBox(
                                heightFactor: heightFactor > 0
                                    ? heightFactor
                                    : 0.03,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? const Color(0xFF8B7CFF)
                                        : const Color(0xFFD4C5FF),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              // Pin indicator for today
                              if (isToday && completed > 0)
                                Positioned(
                                  bottom: heightFactor * 200 - 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          completed.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'habits',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date labels
          Row(
            children: [
              const SizedBox(width: 36), // Offset for Y-axis
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _weeklyStats!.map((stat) {
                    final date = stat['date'] as DateTime;
                    final isToday =
                        DateTime.now().day == date.day &&
                        DateTime.now().month == date.month;
                    return Expanded(
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isToday
                                ? const Color(0xFF6366F1)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateChart() {
    if (_monthlyCompletionRate == null || _monthlyCompletionRate!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fixed 0–100% scale for consistent axis like the design
    const maxRate = 100.0;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chart with Y-axis
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels 0%..100%
                SizedBox(
                  width: 35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final value = 100 - (index * 20);
                      return Text(
                        '$value%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // Chart area
                Expanded(
                  child: CustomPaint(
                    painter: LineChartPainter(
                      data: _monthlyCompletionRate!,
                      maxRate: maxRate,
                      highlightIndex: _monthlyCompletionRate!.isNotEmpty
                          ? _monthlyCompletionRate!.length - 1
                          : null,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitStreaksSection() {
    if (_habitStreaks == null || _habitStreaks!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _habitStreaks!.map((streak) {
        final habitName = streak['habit_name'] as String;
        final emoji = streak['emoji'] as String;
        final colorHex = streak['color_hex'] as String;
        final currentStreak = streak['current_streak'] as int;
        final totalCompletions = streak['total_completions'] as int;
        final completionRate = (streak['completion_rate'] is int)
            ? (streak['completion_rate'] as int).toDouble()
            : (streak['completion_rate'] as double);

        Color habitColor;
        try {
          habitColor = Color(int.parse('FF$colorHex', radix: 16));
        } catch (e) {
          habitColor = const Color(0xFFD4C5FF);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              // Emoji with colored background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habitName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: currentStreak > 0
                              ? Colors.orange
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentStreak > 0
                              ? '$currentStreak-Day Streak'
                              : 'No active streak',
                          style: TextStyle(
                            fontSize: 13,
                            color: currentStreak > 0
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalCompletions total',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Streak indicator
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${completionRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: habitColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '30 days',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxRate;
  final int? highlightIndex;

  LineChartPainter({
    required this.data,
    required this.maxRate,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Reserve space for date labels at bottom
    final chartHeight = size.height - 25;

    // Calculate points
    final points = <Offset>[];
    final widthStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final rate = (data[i]['rate'] is int)
          ? (data[i]['rate'] as int).toDouble()
          : (data[i]['rate'] as double);
      final x = data.length > 1 ? i * widthStep : size.width / 2;
      final y =
          chartHeight - ((rate.clamp(0, maxRate)) / maxRate * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw fill area with gradient
    final fillPath = Path();
    fillPath.moveTo(points[0].dx, chartHeight);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B7CFF).withValues(alpha: 0.25),
          const Color(0xFF8B7CFF).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF8B7CFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw dots and labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final rate = (data[i]['rate'] is int)
          ? (data[i]['rate'] as int).toDouble()
          : (data[i]['rate'] as double);

      // Draw outer dot (white background)
      final outerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, outerDotPaint);

      // Draw inner dot
      final dotPaint = Paint()
        ..color = const Color(0xFF8B7CFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, dotPaint);

      // Highlight latest point with bubble
      if (highlightIndex != null && i == highlightIndex) {
        // Draw bubble
        final bubbleRadius = 20.0;
        final bubbleCenter = Offset(point.dx, point.dy - 35);

        // Bubble shadow
        final shadowPaint = Paint()
          ..color = const Color(0xFF8B7CFF).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(bubbleCenter, bubbleRadius + 2, shadowPaint);

        // Bubble fill
        final bubbleFill = Paint()
          ..color = const Color(0xFF8B7CFF)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(bubbleCenter, bubbleRadius, bubbleFill);

        // Percentage text in bubble
        final percentText = TextPainter(
          text: TextSpan(
            text: '${rate.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        percentText.layout();
        percentText.paint(
          canvas,
          Offset(
            bubbleCenter.dx - percentText.width / 2,
            bubbleCenter.dy - percentText.height / 2,
          ),
        );
      }

      // Draw date labels
      final date = data[i]['month'] as DateTime;
      String labelText;
      if (data.length <= 31) {
        // Daily data - show day number
        labelText = date.day.toString();
      } else {
        // Monthly data - show month abbreviation
        labelText = _getMonthAbbreviation(date.month);
      }

      final dateText = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dateText.layout();
      dateText.paint(
        canvas,
        Offset(point.dx - dateText.width / 2, chartHeight + 8),
      );
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
