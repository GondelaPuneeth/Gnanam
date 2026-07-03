import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/core/database/app_database.dart';
import 'package:gnanam/orchestrator/agent_manager.dart';


/// Data class for a quiz question
class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });
}

/// Data class for a complete quiz
class Quiz {
  final String id;
  final String subject;
  final String topic;
  final int grade;
  final String difficulty;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.subject,
    required this.topic,
    required this.grade,
    this.difficulty = 'medium',
    required this.questions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Generates quizzes using the on-device AI model
class QuizGenerator {
  final AgentManager _agentManager;
  bool _isGenerating = false;

  QuizGenerator(this._agentManager);

  bool get isGenerating => _isGenerating;

  /// Generate a quiz on the given subject/topic for the given grade
  Future<Quiz> generateQuiz({
    required String subject,
    required String topic,
    required int grade,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    if (_isGenerating) {
      throw Exception('A quiz is already being generated. Please wait.');
    }
    _isGenerating = true;

    try {
      final prompt = _buildPrompt(
        subject: subject,
        topic: topic,
        grade: grade,
        questionCount: questionCount,
        difficulty: difficulty,
      );

      // Collect the full response from the model
      final response = await _agentManager.submitTask(
        AgentTaskType.quiz,
        [{'role': 'user', 'content': prompt}],
      );

      final questions = _parseQuestions(response);

      if (questions.isEmpty) {
        throw Exception('Failed to parse quiz questions from AI response.');
      }

      final quiz = Quiz(
        id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        topic: topic,
        grade: grade,
        difficulty: difficulty,
        questions: questions,
      );

      // Save to database
      await _saveQuizToDb(quiz);

      return quiz;
    } finally {
      _isGenerating = false;
    }
  }

  String _buildPrompt({
    required String subject,
    required String topic,
    required int grade,
    required int questionCount,
    required String difficulty,
  }) {
    return '''Generate exactly $questionCount multiple choice questions about "$topic" for Grade $grade $subject.
Difficulty: $difficulty.

Format EACH question EXACTLY like this:
Q: [question text]
A) [option A]
B) [option B]
C) [option C]
D) [option D]
Correct: [A or B or C or D]
Explanation: [brief explanation]
---

Generate all $questionCount questions now:''';
  }

  List<QuizQuestion> _parseQuestions(String response) {
    final questions = <QuizQuestion>[];
    // Split by --- or by Q: markers
    final blocks = response.split(RegExp(r'---+|\n(?=Q:)'));

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i].trim();
      if (block.isEmpty) continue;

      try {
        final question = _parseSingleQuestion(block, i);
        if (question != null) {
          questions.add(question);
        }
      } catch (_) {
        // Skip unparseable questions
      }
    }
    return questions;
  }

  QuizQuestion? _parseSingleQuestion(String block, int index) {
    // Extract question text
    final qMatch = RegExp(r'Q:\s*(.+?)(?=\nA\))', dotAll: true).firstMatch(block);
    if (qMatch == null) return null;
    final questionText = qMatch.group(1)!.trim();

    // Extract options
    final optionA = RegExp(r'A\)\s*(.+?)(?=\nB\))', dotAll: true).firstMatch(block)?.group(1)?.trim();
    final optionB = RegExp(r'B\)\s*(.+?)(?=\nC\))', dotAll: true).firstMatch(block)?.group(1)?.trim();
    final optionC = RegExp(r'C\)\s*(.+?)(?=\nD\))', dotAll: true).firstMatch(block)?.group(1)?.trim();
    final optionD = RegExp(r'D\)\s*(.+?)(?=\n(?:Correct|Explanation|$))', dotAll: true).firstMatch(block)?.group(1)?.trim();

    if (optionA == null || optionB == null || optionC == null || optionD == null) return null;

    // Extract correct answer
    final correctMatch = RegExp(r'Correct:\s*([A-Da-d])').firstMatch(block);
    if (correctMatch == null) return null;
    final correctLetter = correctMatch.group(1)!.toUpperCase();
    final correctIndex = 'ABCD'.indexOf(correctLetter);
    if (correctIndex < 0) return null;

    // Extract explanation (optional)
    final explMatch = RegExp(r'Explanation:\s*(.+)', dotAll: true).firstMatch(block);
    final explanation = explMatch?.group(1)?.trim() ?? '';

    return QuizQuestion(
      id: 'qq_${DateTime.now().millisecondsSinceEpoch}_$index',
      questionText: questionText,
      options: [optionA, optionB, optionC, optionD],
      correctIndex: correctIndex,
      explanation: explanation,
    );
  }

  Future<void> _saveQuizToDb(Quiz quiz) async {
    final db = AppDatabase();
    await db.insertQuiz(
      subject: quiz.subject,
      topic: quiz.topic,
      grade: quiz.grade,
      difficulty: quiz.difficulty,
    );
    for (int i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      await db.insertQuizQuestion(
        quizId: quiz.id,
        questionText: q.questionText,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
        orderIndex: i,
      );
    }
  }
}

final quizGeneratorProvider = Provider<QuizGenerator>((ref) {
  final agentManager = ref.watch(agentManagerProvider);
  return QuizGenerator(agentManager);
});
