import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  // Simple in-memory FAQ data based on the JSON you shared
  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'How do I place an order?',
      answer:
          'Browse our products, add items to your cart, and proceed to checkout. You can pay using various payment methods including cash on delivery.',
    ),
    _FaqItem(
      question: 'What payment methods do you accept?',
      answer:
          'We accept cash on delivery, credit/debit cards, UPI, and other digital payment methods.',
    ),
    _FaqItem(
      question: 'How long does shipping take?',
      answer:
          'Standard shipping takes 3-5 business days. Express shipping is available for faster delivery.',
    ),
    _FaqItem(
      question: 'Can I cancel my order?',
      answer:
          'Orders can be cancelled within 2 hours of placement. Contact our customer support for assistance.',
    ),
    _FaqItem(
      question: 'What is your return policy?',
      answer:
          'We offer a 7-day return policy for unused items in original packaging. Return shipping is free.',
    ),
    _FaqItem(
      question: 'How do I track my order?',
      answer:
          'You can track your order in real-time through our app or website using your order number.',
    ),
    _FaqItem(
      question: 'Do you ship internationally?',
      answer:
          'Currently, we only ship within India. International shipping will be available soon.',
    ),
    _FaqItem(
      question: 'How can I contact customer support?',
      answer:
          'You can reach us through live chat, email, or phone. Our support team is available 24/7.',
    ),
  ];

  int _expandedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? const Color(0xFFF7F7F5),
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          'Support / FAQ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final faq = _faqs[index];
            final isExpanded = _expandedIndex == index;

            return Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? -1 : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpanded
                          ? colorScheme.primary.withOpacity(0.35)
                          : colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              faq.question,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 8),
                        Text(
                          faq.answer,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.75),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}

