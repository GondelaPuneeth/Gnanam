import 'package:flutter_math_fork/flutter_math.dart';

class MathUtils {
  /// Processes LaTeX math expressions and returns a Math widget
  /// Returns null if the expression is invalid
  static Widget? processMathExpression(String expression, {bool isInline = true}) {
    try {
      return Math.tex(
        expression,
        mathStyle: isInline ? MathStyle.text : MathStyle.display,
      );
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
  }

  /// Checks if a string contains math expressions
  static bool containsMath(String text) {
    return text.contains(RegExp(r'\$.*?\$')) ||
           text.contains(RegExp(r'\$\$.*?\$\$'));
  }

  /// Extracts math expressions from text
  static List<String> extractMathExpressions(String text) {
    final inlineMath = RegExp(r'\$(.*?)\$').allMatches(text);
    final blockMath = RegExp(r'\$\$(.*?)\$\$').allMatches(text);

    final expressions = <String>[];

    for (final match in inlineMath) {
      if (match.groupCount >= 1) {
        expressions.add(match.group(1)!);
      }
    }

    for (final match in blockMath) {
      if (match.groupCount >= 1) {
        expressions.add(match.group(1)!);
      }
    }

    return expressions;
  }
}