import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gnanam.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Chat Sessions table
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT 'New Chat',
        subject TEXT,
        grade INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        message_count INTEGER NOT NULL DEFAULT 0,
        is_bookmarked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Chat Messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        is_error INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL,
        attachment_path TEXT,
        attachment_type TEXT,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        grade INTEGER NOT NULL,
        difficulty TEXT NOT NULL DEFAULT 'medium',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE SET NULL
      )
    ''');

    // Quiz Questions table
    await db.execute('''
      CREATE TABLE quiz_questions (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT NOT NULL DEFAULT '',
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      )
    ''');

    // Quiz Attempts table
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        answers TEXT NOT NULL,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      )
    ''');

    // Learning Progress table
    await db.execute('''
      CREATE TABLE learning_progress (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        grade INTEGER NOT NULL,
        questions_attempted INTEGER NOT NULL DEFAULT 0,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        total_study_time_seconds INTEGER NOT NULL DEFAULT 0,
        last_studied_at TEXT NOT NULL,
        mastery_level REAL NOT NULL DEFAULT 0.0,
        UNIQUE(subject, topic, grade)
      )
    ''');

    // Study Sessions table (daily activity tracking)
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        messages_sent INTEGER NOT NULL DEFAULT 0,
        quizzes_completed INTEGER NOT NULL DEFAULT 0,
        UNIQUE(date)
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_messages_session ON chat_messages(session_id)');
    await db.execute('CREATE INDEX idx_questions_quiz ON quiz_questions(quiz_id)');
    await db.execute('CREATE INDEX idx_attempts_quiz ON quiz_attempts(quiz_id)');
    await db.execute('CREATE INDEX idx_progress_subject ON learning_progress(subject)');
    await db.execute('CREATE INDEX idx_study_date ON study_sessions(date)');
  }

  // ── CHAT SESSION OPERATIONS ──

  Future<String> createSession({required int grade, String? subject}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    await db.insert('chat_sessions', {
      'id': id,
      'title': 'New Chat',
      'subject': subject,
      'grade': grade,
      'created_at': now,
      'updated_at': now,
      'message_count': 0,
      'is_bookmarked': 0,
    });
    return id;
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'title': title, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete('chat_messages', where: 'session_id = ?', whereArgs: [sessionId]);
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> toggleBookmark(String sessionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE chat_sessions SET is_bookmarked = CASE WHEN is_bookmarked = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [sessionId],
    );
  }

  // ── CHAT MESSAGE OPERATIONS ──

  Future<void> insertMessage({
    required String sessionId,
    required String id,
    required String role,
    required String content,
    bool isError = false,
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final db = await database;
    await db.insert('chat_messages', {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'is_error': isError ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
      'attachment_path': attachmentPath,
      'attachment_type': attachmentType,
    });
    await db.rawUpdate(
      'UPDATE chat_sessions SET message_count = message_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), sessionId],
    );
  }

  Future<void> updateMessage(String messageId, String content) async {
    final db = await database;
    await db.update(
      'chat_messages',
      {'content': content},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
  }

  // ── QUIZ OPERATIONS ──

  Future<String> insertQuiz({
    required String subject,
    required String topic,
    required int grade,
    String difficulty = 'medium',
    String? sessionId,
  }) async {
    final db = await database;
    final id = 'quiz_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('quizzes', {
      'id': id,
      'session_id': sessionId,
      'subject': subject,
      'topic': topic,
      'grade': grade,
      'difficulty': difficulty,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> insertQuizQuestion({
    required String quizId,
    required String questionText,
    required List<String> options,
    required int correctIndex,
    String explanation = '',
    int orderIndex = 0,
  }) async {
    final db = await database;
    await db.insert('quiz_questions', {
      'id': 'qq_${DateTime.now().millisecondsSinceEpoch}_$orderIndex',
      'quiz_id': quizId,
      'question_text': questionText,
      'option_a': options[0],
      'option_b': options[1],
      'option_c': options[2],
      'option_d': options[3],
      'correct_index': correctIndex,
      'explanation': explanation,
      'order_index': orderIndex,
    });
  }

  Future<String> insertQuizAttempt({
    required String quizId,
    required int score,
    required int totalQuestions,
    required String answersJson,
    required int timeSpentSeconds,
  }) async {
    final db = await database;
    final id = 'attempt_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('quiz_attempts', {
      'id': id,
      'quiz_id': quizId,
      'score': score,
      'total_questions': totalQuestions,
      'answers': answersJson,
      'time_spent_seconds': timeSpentSeconds,
      'completed_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getQuizzes({int limit = 20}) async {
    final db = await database;
    return await db.query('quizzes', orderBy: 'created_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getQuizQuestions(String quizId) async {
    final db = await database;
    return await db.query(
      'quiz_questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'order_index ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getQuizAttempts(String quizId) async {
    final db = await database;
    return await db.query(
      'quiz_attempts',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'completed_at DESC',
    );
  }

  // ── PROGRESS & STATS OPERATIONS ──

  Future<void> updateProgress({
    required String subject,
    required String topic,
    required int grade,
    required int questionsAttempted,
    required int correctAnswers,
    int studyTimeSeconds = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO learning_progress (id, subject, topic, grade, questions_attempted, correct_answers, total_study_time_seconds, last_studied_at, mastery_level)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(subject, topic, grade) DO UPDATE SET
        questions_attempted = questions_attempted + excluded.questions_attempted,
        correct_answers = correct_answers + excluded.correct_answers,
        total_study_time_seconds = total_study_time_seconds + excluded.total_study_time_seconds,
        last_studied_at = excluded.last_studied_at,
        mastery_level = CAST((correct_answers + excluded.correct_answers) AS REAL) / CAST((questions_attempted + excluded.questions_attempted) AS REAL)
    ''', [
      'prog_${subject}_${topic}_$grade',
      subject, topic, grade,
      questionsAttempted, correctAnswers, studyTimeSeconds, now,
      questionsAttempted > 0 ? correctAnswers / questionsAttempted : 0.0,
    ]);
  }

  Future<List<Map<String, dynamic>>> getProgressBySubject() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT subject,
        SUM(questions_attempted) as total_attempted,
        SUM(correct_answers) as total_correct,
        SUM(total_study_time_seconds) as total_study_time,
        MAX(last_studied_at) as last_studied,
        AVG(mastery_level) as avg_mastery
      FROM learning_progress
      GROUP BY subject
      ORDER BY last_studied DESC
    ''');
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await database;
    final progressStats = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(questions_attempted), 0) as total_questions,
        COALESCE(SUM(correct_answers), 0) as total_correct,
        COALESCE(SUM(total_study_time_seconds), 0) as total_study_time
      FROM learning_progress
    ''');
    final sessionCount = await db.rawQuery('SELECT COUNT(*) as count FROM chat_sessions');
    final quizCount = await db.rawQuery('SELECT COUNT(*) as count FROM quiz_attempts');

    // Calculate streak
    final recentSessions = await db.rawQuery(
      'SELECT DISTINCT date FROM study_sessions ORDER BY date DESC LIMIT 30',
    );
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < recentSessions.length; i++) {
      final sessionDate = DateTime.parse(recentSessions[i]['date'] as String);
      final expectedDate = today.subtract(Duration(days: i));
      if (sessionDate.year == expectedDate.year &&
          sessionDate.month == expectedDate.month &&
          sessionDate.day == expectedDate.day) {
        streak++;
      } else {
        break;
      }
    }

    return {
      'total_questions': progressStats.first['total_questions'] ?? 0,
      'total_correct': progressStats.first['total_correct'] ?? 0,
      'total_study_time_seconds': progressStats.first['total_study_time'] ?? 0,
      'total_sessions': sessionCount.first['count'] ?? 0,
      'total_quizzes': quizCount.first['count'] ?? 0,
      'streak': streak,
    };
  }

  Future<void> recordStudyActivity({int messagesSent = 0, int quizzesCompleted = 0}) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.rawInsert('''
      INSERT INTO study_sessions (id, date, duration_seconds, messages_sent, quizzes_completed)
      VALUES (?, ?, 0, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        messages_sent = messages_sent + excluded.messages_sent,
        quizzes_completed = quizzes_completed + excluded.quizzes_completed
    ''', ['study_$today', today, messagesSent, quizzesCompleted]);
  }

  Future<List<Map<String, dynamic>>> getStudyHistory({int days = 30}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    return await db.query(
      'study_sessions',
      where: 'date >= ?',
      whereArgs: [since],
      orderBy: 'date ASC',
    );
  }
}
