import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

class CustomMarkdownWidget extends StatelessWidget {
  final String data;
  final Color? textColor;

  const CustomMarkdownWidget({
    super.key,
    required this.data,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final processedData = _processMath(data);
    final baseColor = textColor ?? Theme.of(context).colorScheme.onSurface;

    return MarkdownBody(
      data: processedData,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        // Headings
        h1: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          height: 1.3,
        ),
        h1Padding: const EdgeInsets.only(top: 24, bottom: 12),
        h2: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.3,
        ),
        h2Padding: const EdgeInsets.only(top: 20, bottom: 10),
        h3: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h4: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h4Padding: const EdgeInsets.only(top: 12, bottom: 6),
        // Body text
        p: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: baseColor,
        ),
        pPadding: const EdgeInsets.only(bottom: 12),
        // Lists
        listBullet: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: baseColor,
        ),
        listBulletPadding: const EdgeInsets.only(left: 16),
        // Blockquotes
        blockquote: TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: baseColor,
          height: 1.5,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquotePadding: const EdgeInsets.all(12),
        // Code
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      builders: {
        'math_inline': MathInlineBuilder(),
        'math_block': MathBlockBuilder(),
        'code': CodeElementBuilder(
          darkTheme: atomOneDarkTheme,
          lightTheme: atomOneLightTheme,
        ),
      },
      inlineSyntaxes: [
        MathBlockSyntax(),
        MathInlineSyntax(),
      ],
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
    );
  }

  String _processMath(String text) {
    // This is a simple processor - in a real app, you'd want a more robust solution
    return text;
  }
}

class MathInlineBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    try {
      return Math.tex(
        text,
        mathStyle: MathStyle.text,
        textStyle: preferredStyle?.copyWith(fontSize: (preferredStyle.fontSize ?? 15) * 1.05),
      );
    } catch (e) {
      // Fallback to monospace text with red border if LaTeX parsing fails
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '\$$text\$',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    }
  }
}

class MathBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    try {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            text,
            mathStyle: MathStyle.display,
            textStyle: preferredStyle?.copyWith(fontSize: (preferredStyle.fontSize ?? 15) * 1.05),
          ),
        ),
      );
    } catch (e) {
      // Fallback to monospace text with red border if LaTeX parsing fails
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '\$\$$text\$\$',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    }
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final Map<String, TextStyle> darkTheme;
  final Map<String, TextStyle> lightTheme;

  CodeElementBuilder({required this.darkTheme, required this.lightTheme});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String? language;
    final code = element.textContent;

    // Extract language if present
    if (element.attributes['class'] != null) {
      final classAttr = element.attributes['class'] as String;
      if (classAttr.startsWith('language-')) {
        language = classAttr.substring(9);
      }
    }

    return CodeHighlightWidget(
      code: code,
      language: language ?? 'plaintext',
      darkTheme: darkTheme,
      lightTheme: lightTheme,
    );
  }
}

class CodeHighlightWidget extends StatefulWidget {
  final String code;
  final String language;
  final Map<String, TextStyle> darkTheme;
  final Map<String, TextStyle> lightTheme;

  const CodeHighlightWidget({
    super.key,
    required this.code,
    required this.language,
    required this.darkTheme,
    required this.lightTheme,
  });

  @override
  State<CodeHighlightWidget> createState() => _CodeHighlightWidgetState();
}

class _CodeHighlightWidgetState extends State<CodeHighlightWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? widget.darkTheme : widget.lightTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF282C34)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: [
          // Language label
          if (widget.language != 'plaintext')
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.language,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          // Copy button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _copied ? Icons.check_outlined : Icons.content_copy_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () {
                // Copy to clipboard
                setState(() {
                  _copied = true;
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _copied = false;
                    });
                  }
                });
              },
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                widget.code,
                language: widget.language,
                theme: theme,
                padding: const EdgeInsets.all(0),
                textStyle: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MathBlockSyntax extends md.InlineSyntax {
  MathBlockSyntax() : super(r'\$\$(.*?)\$\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math_block', match[1]!));
    return true;
  }
}

class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(r'\$(.*?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math_inline', match[1]!));
    return true;
  }
}