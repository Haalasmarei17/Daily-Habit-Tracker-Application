import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/habits_repository.dart';

enum DateRangeOption {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last6Months,
  thisYear,
  lastYear,
  allTime,
  customRange
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
  List<Map<String, dynamic>>? _weeklyStats;
  List<Map<String, dynamic>>? _monthlyCompletionRate;

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
          endDate = DateTime(today.year, today.month, 1)
              .subtract(const Duration(days: 1));
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

      // Get weekly stats for chart
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
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

      // Get monthly completion rate for chart (last 6 months)
      _monthlyCompletionRate = [];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(today.year, today.month - i, 1);
        final nextMonth = DateTime(today.year, today.month - i + 1, 1);
        final monthEnd =
            nextMonth.isBefore(today) ? nextMonth : DateTime.now();

        int monthCompleted = 0;
        int monthTotal = 0;
        var currentDate = month;

        while (currentDate.isBefore(monthEnd)) {
          final dayStats = await repository.getDailyStatistics(currentDate);
          monthCompleted += dayStats['completed'] as int;
          monthTotal += dayStats['total'] as int;
          currentDate = currentDate.add(const Duration(days: 1));
        }

        final rate = monthTotal > 0 ? (monthCompleted / monthTotal * 100) : 0;
        _monthlyCompletionRate!.add({
          'month': month,
          'rate': rate,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                            '$_totalDays days',
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
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                ),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats == null || _weeklyStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = _weeklyStats!.fold<int>(
      0,
      (max, stat) =>
          (stat['total'] as int) > max ? (stat['total'] as int) : max,
    );

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _weeklyStats!.asMap().entries.map((entry) {
          final stat = entry.value;
          final completed = stat['completed'] as int;
          final total = stat['total'] as int;
          final date = stat['date'] as DateTime;
          final dayName = _getShortDayName(date.weekday);
          final isToday = DateTime.now().day == date.day &&
              DateTime.now().month == date.month;
          final height = maxValue > 0 ? (completed / maxValue) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isToday)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        heightFactor: height > 0 ? height : 0.05,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7CFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday ? const Color(0xFF6366F1) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionRateChart() {
    if (_monthlyCompletionRate == null || _monthlyCompletionRate!.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRate = _monthlyCompletionRate!.fold<double>(
      0,
      (max, stat) =>
          (stat['rate'] as double) > max ? (stat['rate'] as double) : max,
    );

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: LineChartPainter(
          data: _monthlyCompletionRate!,
          maxRate: maxRate > 0 ? maxRate : 100,
        ),
        child: Container(),
      ),
    );
  }

  String _getShortDayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return weekday == 7 ? days[6] : days[weekday - 1];
  }

  String _getMonthName(int month) {
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
      'Dec'
    ];
    return months[month - 1];
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxRate;

  LineChartPainter({required this.data, required this.maxRate});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B7CFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF8B7CFF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF8B7CFF)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    if (data.isEmpty) return;

    final widthStep = size.width / (data.length - 1);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw line and fill
    for (int i = 0; i < data.length; i++) {
      final rate = data[i]['rate'] as double;
      final x = i * widthStep;
      final y = size.height - (rate / maxRate * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dots
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Draw percentage text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rate.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, y - 20));

      // Draw month labels
      final month = (data[i]['month'] as DateTime).month;
      final monthText = TextPainter(
        text: TextSpan(
          text: _getMonthAbbreviation(month),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      monthText.layout();
      monthText.paint(canvas, Offset(x - 10, size.height + 5));
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
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
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}







