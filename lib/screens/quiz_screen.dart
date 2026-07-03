import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gnanam/features/quiz/quiz_generator.dart';
import 'package:gnanam/screens/quiz_results_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  int? _selectedIndex;
  bool _answered = false;
  final List<int?> _userAnswers = [];
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsed = '00:00';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userAnswers.addAll(List.filled(widget.quiz.questions.length, null));
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final mins = _stopwatch.elapsed.inMinutes.toString().padLeft(2, '0');
          final secs = (_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0');
          _elapsed = '$mins:$secs';
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopwatch.stop();
    _timer.cancel();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _userAnswers[_currentPage] = index;
    });
  }

  void _nextQuestion() {
    if (_currentPage < widget.quiz.questions.length - 1) {
      setState(() {
        _currentPage++;
        _selectedIndex = null;
        _answered = false;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _stopwatch.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen(
            quiz: widget.quiz,
            userAnswers: _userAnswers,
            timeSpentSeconds: _stopwatch.elapsed.inSeconds,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = (_currentPage + 1) / widget.quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.subject),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(_elapsed, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentPage + 1} of ${widget.quiz.questions.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.quiz.difficulty.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          // Question content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionPage(widget.quiz.questions[index], theme);
              },
            ),
          ),

          // Next / Finish button
          if (_answered)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _nextQuestion,
                  icon: Icon(
                    _currentPage < widget.quiz.questions.length - 1
                        ? Icons.arrow_forward
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    _currentPage < widget.quiz.questions.length - 1 ? 'Next Question' : 'See Results',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(QuizQuestion question, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildRichText(question.questionText, theme.textTheme.titleMedium!),
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(4, (i) {
            final labels = ['A', 'B', 'C', 'D'];
            final isSelected = _selectedIndex == i;
            final isCorrect = question.correctIndex == i;
            final showResult = _answered;

            Color? cardColor;
            Color? borderColor;
            if (showResult && isCorrect) {
              cardColor = Colors.green.withValues(alpha: 0.1);
              borderColor = Colors.green;
            } else if (showResult && isSelected && !isCorrect) {
              cardColor = Colors.red.withValues(alpha: 0.1);
              borderColor = Colors.red;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Material(
                  color: cardColor ?? theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _answered ? null : () => _selectAnswer(i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: borderColor != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: showResult && isCorrect
                                  ? Colors.green
                                  : showResult && isSelected
                                      ? Colors.red
                                      : theme.colorScheme.primaryContainer,
                            ),
                            child: Center(
                              child: showResult && isCorrect
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : showResult && isSelected && !isCorrect
                                      ? const Icon(Icons.close, color: Colors.white, size: 20)
                                      : Text(
                                          labels[i],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRichText(
                              question.options[i],
                              theme.textTheme.bodyLarge!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Explanation
          if (_answered && question.explanation.isNotEmpty)
            AnimatedOpacity(
              opacity: _answered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Card(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Explanation',
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            _buildRichText(question.explanation, theme.textTheme.bodyMedium!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Renders text with inline LaTeX support ($...$)
  Widget _buildRichText(String text, TextStyle baseStyle) {
    if (!text.contains('\$')) {
      return Text(text, style: baseStyle);
    }

    final parts = <InlineSpan>[];
    final regex = RegExp(r'\$(.+?)\$');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      // We'll use a WidgetSpan for math
      parts.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          match.group(1)!,
          textStyle: baseStyle,
          onErrorFallback: (e) => Text(
            '\$${match.group(1)}\$',
            style: baseStyle.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      parts.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return Text.rich(TextSpan(children: parts));
  }
}
