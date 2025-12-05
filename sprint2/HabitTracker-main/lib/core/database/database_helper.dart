import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'habits.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        status TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        repeat_type TEXT NOT NULL DEFAULT 'Daily',
        selected_days TEXT,
        selected_month_dates TEXT,
        end_habit_enabled INTEGER NOT NULL DEFAULT 0,
        end_habit_mode TEXT,
        end_date TEXT,
        days_after INTEGER,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        reminder_time TEXT,
        is_skipped_today INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add is_skipped_today column to existing habits table
      await db.execute('''
        ALTER TABLE habits ADD COLUMN is_skipped_today INTEGER NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 3) {
      // Add is_archived column to existing habits table
      await db.execute('''
        ALTER TABLE habits ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  // Habit CRUD operations
  Future<int> insertHabit(Map<String, dynamic> habit) async {
    final db = await database;
    try {
      return await db.insert('habits', habit);
    } catch (e) {
      // If constraint error, try with a new ID
      if (e.toString().contains('UNIQUE constraint failed')) {
        final newHabit = Map<String, dynamic>.from(habit);
        newHabit['id'] =
            '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
        return await db.insert('habits', newHabit);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllHabits() async {
    final db = await database;
    // Exclude archived habits from active list
    return await db.query(
      'habits',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getHabitById(String id) async {
    final db = await database;
    final result = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateHabit(String id, Map<String, dynamic> habit) async {
    final db = await database;
    return await db.update('habits', habit, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteHabit(String id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleHabitCompletion(String id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'habits',
      {
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleHabitSkip(String id, bool isSkipped) async {
    final db = await database;
    return await db.update(
      'habits',
      {
        'is_skipped_today': isSkipped ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Habit completion tracking
  Future<int> recordHabitCompletion(String habitId) async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Check if there's already a completion for today
    final existingCompletions = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        habitId,
        todayStart.toIso8601String(),
        todayEnd.toIso8601String(),
      ],
    );

    // If no completion exists for today, add one
    if (existingCompletions.isEmpty) {
      try {
        return await db.insert('habit_completions', {
          'habit_id': habitId,
          'completed_at': now.toIso8601String(),
        });
      } catch (e) {
        // If insert fails (e.g., constraint violation), check again
        // This handles race conditions
        final recheck = await db.query(
          'habit_completions',
          where: 'habit_id = ? AND completed_at >= ? AND completed_at < ?',
          whereArgs: [
            habitId,
            todayStart.toIso8601String(),
            todayEnd.toIso8601String(),
          ],
        );
        return recheck.isEmpty ? 0 : 1;
      }
    }

    // Already has a completion for today, return 0 (no new record added)
    return 0;
  }

  // Remove completion for today when un-completing
  Future<int> removeTodayCompletion(String habitId) async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return await db.delete(
      'habit_completions',
      where: 'habit_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        habitId,
        todayStart.toIso8601String(),
        todayEnd.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getHabitCompletions(String habitId) async {
    final db = await database;
    return await db.query(
      'habit_completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completed_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return await db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_at BETWEEN ? AND ?',
      whereArgs: [
        habitId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'completed_at DESC',
    );
  }

  // Statistics
  Future<int> getTotalHabitsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM habits');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedHabitsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habits WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveHabitsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habits WHERE is_completed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Clean up
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Development helper - clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('habit_completions');
    await db.delete('habits');
  }

  // Development helper - check if database has data
  Future<bool> hasData() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM habits');
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  // Check if habit ID exists
  Future<bool> habitExists(String id) async {
    final db = await database;
    final result = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // Check if habit name exists
  Future<bool> habitNameExists(String name) async {
    final db = await database;
    final result = await db.query(
      'habits',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }

  // Get next available ID
  Future<String> getNextAvailableId() async {
    String id;
    do {
      id =
          '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
    } while (await habitExists(id));
    return id;
  }

  // Clean up weekly habits that have isSkippedToday = true
  Future<void> cleanupWeeklySkippedHabits() async {
    final db = await database;
    await db.update(
      'habits',
      {'is_skipped_today': 0},
      where: 'repeat_type = ? AND is_skipped_today = ?',
      whereArgs: ['weekly', 1],
    );
  }

  // Archive habit (keep data but mark as archived)
  Future<int> archiveHabit(String id) async {
    final db = await database;
    return await db.update(
      'habits',
      {
        'is_archived': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all archived habits
  Future<List<Map<String, dynamic>>> getArchivedHabits() async {
    final db = await database;
    return await db.query(
      'habits',
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
  }

  // Restore archived habit (unarchive)
  Future<int> restoreHabit(String id) async {
    final db = await database;
    return await db.update(
      'habits',
      {
        'is_archived': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Reset all completion flags (called when date changes)
  Future<void> resetAllCompletionFlags() async {
    final db = await database;
    final now = DateTime.now();
    await db.update(
      'habits',
      {
        'is_completed': 0,
        'updated_at': now.toIso8601String(),
      },
    );
  }

  // Sync is_completed flag with completion records
  Future<void> syncCompletionStatus() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get all habits
    final habits = await db.query('habits');

    for (final habit in habits) {
      final habitId = habit['id'] as String;
      final isCompleted = habit['is_completed'] == 1;

      // Check if completion record exists for today
      final completions = await db.query(
        'habit_completions',
        where: 'habit_id = ? AND completed_at >= ? AND completed_at < ?',
        whereArgs: [
          habitId,
          todayStart.toIso8601String(),
          todayEnd.toIso8601String(),
        ],
      );

      final hasCompletionRecord = completions.isNotEmpty;

      // Sync: if has completion record but is_completed is false, set to true
      // If no completion record but is_completed is true, set to false
      if (hasCompletionRecord && !isCompleted) {
        await db.update(
          'habits',
          {'is_completed': 1, 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [habitId],
        );
      } else if (!hasCompletionRecord && isCompleted) {
        await db.update(
          'habits',
          {'is_completed': 0, 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [habitId],
        );
      }
    }
  }

  // Statistics methods
  Future<Map<String, dynamic>> getDailyStatistics(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all active habits for the given date (excluding archived)
    final allHabits = await db.query(
      'habits',
      where: 'is_archived = ?',
      whereArgs: [0],
    );
    final todayHabits = allHabits.where((habit) {
      final repeatType = habit['repeat_type'] as String;
      if (repeatType == 'daily') return true;
      if (repeatType == 'weekly') {
        final selectedDays =
            (habit['selected_days'] as String?)
                ?.split(',')
                .map((e) => int.parse(e))
                .toSet() ??
            {};
        final weekday = date.weekday; // 1 = Monday, 7 = Sunday
        final adjustedWeekday = weekday == 7 ? 0 : weekday;
        return selectedDays.contains(adjustedWeekday);
      }
      if (repeatType == 'monthly') {
        final selectedMonthDates =
            (habit['selected_month_dates'] as String?)
                ?.split(',')
                .map((e) => int.parse(e))
                .toSet() ??
            {};
        return selectedMonthDates.contains(date.day);
      }
      return false;
    }).toList();

    // Get completions for today
    final completions = await db.query(
      'habit_completions',
      where: 'completed_at >= ? AND completed_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    final completedHabitIds = completions
        .map((c) => c['habit_id'] as String)
        .toSet();

    final completedCount = todayHabits
        .where((h) => completedHabitIds.contains(h['id'] as String))
        .length;
    final totalCount = todayHabits.length;

    return {
      'total': totalCount,
      'completed': completedCount,
      'uncompleted': totalCount - completedCount,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyStatistics(
    DateTime startDate,
  ) async {
    final statistics = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final stats = await getDailyStatistics(currentDate);
      statistics.add({
        'date': currentDate,
        'total': stats['total'] as int,
        'completed': stats['completed'] as int,
        'uncompleted': stats['uncompleted'] as int,
      });
    }

    return statistics;
  }

  Future<List<Map<String, dynamic>>> getMonthlyStatistics(
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final statistics = <Map<String, dynamic>>[];

    var currentDate = startOfMonth;
    while (currentDate.isBefore(endOfMonth)) {
      final stats = await getDailyStatistics(currentDate);
      statistics.add({
        'date': currentDate,
        'total': stats['total'] as int,
        'completed': stats['completed'] as int,
        'uncompleted': stats['uncompleted'] as int,
      });
      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return statistics;
  }

  Future<List<Map<String, dynamic>>> getHabitConsistencyStats() async {
    final db = await database;
    final habits = await db.query('habits');
    final stats = <Map<String, dynamic>>[];

    for (final habit in habits) {
      final habitId = habit['id'] as String;
      final completions = await db.query(
        'habit_completions',
        where: 'habit_id = ?',
        whereArgs: [habitId],
      );

      // Calculate consistency (completions in last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentCompletions = completions.where((c) {
        final completedAt = DateTime.parse(c['completed_at'] as String);
        return completedAt.isAfter(thirtyDaysAgo);
      }).length;

      stats.add({
        'habit_id': habitId,
        'habit_name': habit['name'] as String,
        'emoji': habit['emoji'] as String,
        'total_completions': completions.length,
        'recent_completions': recentCompletions,
        'consistency_rate': recentCompletions / 30.0,
      });
    }

    // Sort by consistency rate
    stats.sort(
      (a, b) => (b['consistency_rate'] as double).compareTo(
        a['consistency_rate'] as double,
      ),
    );

    return stats;
  }

  Future<List<Map<String, dynamic>>> getHabitsByStatus(String status) async {
    final db = await database;
    return await db.query('habits', where: 'status = ?', whereArgs: [status]);
  }
}
