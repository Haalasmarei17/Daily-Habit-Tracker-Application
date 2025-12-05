import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/habits_cubit.dart';
import '../bloc/habits_state.dart';
import '../widgets/swipeable_habit_card.dart';
import '../widgets/filter_chip_widget.dart';
import 'create_habit_page.dart';
import 'edit_habit_page.dart';
import 'archive_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
          'Home',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (String value) async {
              switch (value) {
                case 'mark_all_complete':
                  await _markAllHabitsComplete(context);
                  break;
                case 'clear_completed':
                  await _clearCompletedHabits(context);
                  break;
                case 'archive':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArchivePage(),
                    ),
                  );
                  break;
                case 'reset_database':
                  await _showResetDatabaseDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'mark_all_complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark All Complete'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear Completed'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Archive'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'reset_database',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset All Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<HabitsCubit, HabitsState>(
        builder: (context, state) {
          if (state is HabitsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitsError) {
            return Center(child: Text(state.message));
          }

          if (state is HabitsLoaded) {
            return Column(
              children: [
                // Tab navigation
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _buildTab(
                        context,
                        'Today',
                        state.currentView == HabitsView.today,
                        () => context.read<HabitsCubit>().changeView(
                          HabitsView.today,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTab(
                        context,
                        'Weekly',
                        state.currentView == HabitsView.weekly,
                        () => context.read<HabitsCubit>().changeView(
                          HabitsView.weekly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTab(
                        context,
                        'Overall',
                        state.currentView == HabitsView.overall,
                        () => context.read<HabitsCubit>().changeView(
                          HabitsView.overall,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChipWidget(
                          label: 'All',
                          isSelected: state.timeFilter == TimeFilter.all,
                          onTap: () => context
                              .read<HabitsCubit>()
                              .changeTimeFilter(TimeFilter.all),
                        ),
                        const SizedBox(width: 8),
                        FilterChipWidget(
                          label: 'Morning',
                          isSelected: state.timeFilter == TimeFilter.morning,
                          onTap: () => context
                              .read<HabitsCubit>()
                              .changeTimeFilter(TimeFilter.morning),
                        ),
                        const SizedBox(width: 8),
                        FilterChipWidget(
                          label: 'Afternoon',
                          isSelected: state.timeFilter == TimeFilter.afternoon,
                          onTap: () => context
                              .read<HabitsCubit>()
                              .changeTimeFilter(TimeFilter.afternoon),
                        ),
                        const SizedBox(width: 8),
                        FilterChipWidget(
                          label: 'Evening',
                          isSelected: state.timeFilter == TimeFilter.evening,
                          onTap: () => context
                              .read<HabitsCubit>()
                              .changeTimeFilter(TimeFilter.evening),
                        ),
                      ],
                    ),
                  ),
                ),

                // Habits list
                Expanded(
                  child: state.habits.isEmpty
                      ? _buildEmptyState(context)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Active habits
                              ...state.filteredActiveHabits.map(
                                (habit) => SwipeableHabitCard(
                                  habit: habit,
                                  onTap: () {
                                    // Tap on active habit to complete it
                                    context
                                        .read<HabitsCubit>()
                                        .toggleHabitCompletion(habit.id);
                                  },
                                  onComplete: () {
                                    context
                                        .read<HabitsCubit>()
                                        .toggleHabitCompletion(habit.id);
                                  },
                                  onSkip: () {
                                    context
                                        .read<HabitsCubit>()
                                        .skipHabitForToday(habit.id);
                                  },
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditHabitPage(habitId: habit.id),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteConfirmation(
                                      context,
                                      habit.id,
                                      habit.name,
                                    );
                                  },
                                ),
                              ),

                              // Completed section
                              if (state.completedHabits.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                ...state.completedHabits.map(
                                  (habit) => SwipeableHabitCard(
                                    habit: habit,
                                    onTap: () {
                                      // Tap on completed habit to undo completion
                                      context
                                          .read<HabitsCubit>()
                                          .toggleHabitCompletion(habit.id);
                                    },
                                    onComplete: () {
                                      context
                                          .read<HabitsCubit>()
                                          .toggleHabitCompletion(habit.id);
                                    },
                                    onSkip: () {
                                      context
                                          .read<HabitsCubit>()
                                          .skipHabitForToday(habit.id);
                                    },
                                    onEdit: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditHabitPage(habitId: habit.id),
                                        ),
                                      );
                                    },
                                    onDelete: () {
                                      _showDeleteConfirmation(
                                        context,
                                        habit.id,
                                        habit.name,
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Skipped section - only show in Today view
                              if (state.skippedHabits.isNotEmpty &&
                                  state.currentView == HabitsView.today) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    'Skipped Today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                ...state.skippedHabits.map(
                                  (habit) => SwipeableHabitCard(
                                    habit: habit,
                                    onTap: () {
                                      // Tap on skipped habit to undo skip
                                      context.read<HabitsCubit>().undoSkipHabit(
                                        habit.id,
                                      );
                                    },
                                    onComplete: () {
                                      context
                                          .read<HabitsCubit>()
                                          .toggleHabitCompletion(habit.id);
                                    },
                                    onSkip: () {
                                      context
                                          .read<HabitsCubit>()
                                          .skipHabitForToday(habit.id);
                                    },
                                    onEdit: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditHabitPage(habitId: habit.id),
                                        ),
                                      );
                                    },
                                    onDelete: () {
                                      _showDeleteConfirmation(
                                        context,
                                        habit.id,
                                        habit.name,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateHabitPage()),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first habit and begin building\na better version of yourself',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateHabitPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Your First Habit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Show some example habits or tips
                _showHabitTips(context);
              },
              icon: Icon(Icons.lightbulb_outline, color: Colors.grey.shade600),
              label: Text(
                'Need inspiration?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHabitTips(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Habit Ideas'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Morning Habits:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Drink a glass of water'),
                Text('• 10 minutes of meditation'),
                Text('• Make your bed'),
                SizedBox(height: 12),
                Text(
                  'Evening Habits:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Read for 20 minutes'),
                Text('• Write in a journal'),
                Text('• Prepare for tomorrow'),
                SizedBox(height: 12),
                Text(
                  'Health Habits:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Take a 10-minute walk'),
                Text('• Eat a healthy snack'),
                Text('• Stretch for 5 minutes'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAllHabitsComplete(BuildContext context) async {
    final cubit = context.read<HabitsCubit>();
    final state = cubit.state;

    if (state is HabitsLoaded) {
      final activeHabits = state.habits.where((h) => !h.isCompleted).toList();

      if (activeHabits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active habits to mark complete'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await cubit.markAllHabitsComplete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${activeHabits.length} habits marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearCompletedHabits(BuildContext context) async {
    final cubit = context.read<HabitsCubit>();
    final state = cubit.state;

    if (state is HabitsLoaded) {
      final completedHabits = state.habits.where((h) => h.isCompleted).toList();

      if (completedHabits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No completed habits to clear'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Clear Completed Habits'),
            content: Text(
              'Are you sure you want to delete ${completedHabits.length} completed habits? This action cannot be undone.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await cubit.clearCompletedHabits();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${completedHabits.length} completed habits cleared',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String habitId,
    String habitName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Habit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this habit?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Archive habit (keep data but remove from active list)
                await context.read<HabitsCubit>().archiveHabit(habitId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$habitName" has been archived'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete but keep data for archive',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Delete from database and update UI instantly
                await context.read<HabitsCubit>().deleteHabit(habitId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$habitName" has been deleted'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetDatabaseDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'Are you sure you want to reset the database? This will delete all habits and cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await context.read<HabitsCubit>().resetDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database has been reset successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
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
}
