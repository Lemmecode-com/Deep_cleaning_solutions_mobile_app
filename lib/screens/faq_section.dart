import 'package:flutter/material.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/widgets/section_title.dart';
import 'package:dcs_app/utils/app_colors.dart';

class FAQSection extends StatefulWidget {
  final List<dynamic> faqs;

  const FAQSection({
    super.key,
    this.faqs = const [],
  });

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  int _selectedIndex = -1;

  // ── Static fallback (API data नसेल तर) ───────────────────────────
  static const List<Map<String, String>> _staticFaqs = [
    {
      'q': 'What cleaning services does Deep Cleaning Solutions offer?',
      'a': 'Deep Cleaning Solutions offers a comprehensive range of cleaning services including residential cleaning, commercial cleaning, deep cleaning, move-in/move-out cleaning, post-construction cleaning, and specialized services such as carpet cleaning, upholstery cleaning, and window cleaning. Whether you need regular maintenance or a one-time deep clean, our professional team can customize services to meet your specific requirements.',
    },
    {
      'q': 'How do I schedule a cleaning service?',
      'a': 'Scheduling a cleaning service with Deep Cleaning Solutions is simple and convenient. You can book through our website using our online booking form, call us directly at +91 8485854972, or send an email to contact@deepcleaningsolutions.in. Our customer service team is available to help you select the appropriate service package, answer any questions, and schedule a time that works best for you. We recommend booking at least 3-4 days in advance to ensure availability, especially for first-time services.',
    },
    {
      'q': 'What cleaning products and equipment do you use?',
      'a': 'At Deep Cleaning Solutions, we use professional-grade cleaning equipment and high-quality cleaning products that effectively remove dirt, grime, bacteria, and allergens. We prioritize eco-friendly and non-toxic cleaning solutions whenever possible to ensure the safety of your family, pets, employees, and the environment.',
    },
    {
      'q': 'How much does your cleaning service cost?',
      'a': 'Our cleaning service pricing varies based on several factors including the size of the space, type of cleaning required, frequency of service, and specific cleaning tasks needed. For residential cleaning, prices typically start from ₹1,500 for basic cleaning of a 1BHK apartment. Contact us for a free quote.',
    },
    {
      'q': 'Are your cleaning staff trained and insured?',
      'a': 'Yes, all our cleaning professionals at Deep Cleaning Solutions undergo thorough training in proper cleaning techniques, safety protocols, and customer service. We conduct background checks on all staff members. Our company is fully insured with liability coverage.',
    },
    {
      'q': "What if I'm not satisfied with the cleaning service?",
      'a': 'Customer satisfaction is our top priority. We offer a 5-star satisfaction guarantee. If you\'re not completely satisfied, please notify us within 24 hours of service completion, and we\'ll arrange for a follow-up cleaning at no additional cost.',
    },
  ];

  List<Map<String, String>> get _faqs {
    if (widget.faqs.isNotEmpty) {
      return widget.faqs.map((f) => {
        'q': (f['question'] ?? f['q'] ?? '').toString(),
        'a': (f['answer']   ?? f['a'] ?? '').toString(),
      }).toList();
    }
    return _staticFaqs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          const SectionTitle('Frequently Asked Questions'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _FAQItem(
              data: _faqs[i],
              isOpen: _selectedIndex == i,
              onTap: () => setState(() {
                _selectedIndex = _selectedIndex == i ? -1 : i;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final Map<String, String> data;
  final bool isOpen;
  final VoidCallback onTap;

  const _FAQItem({
    required this.data,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOpen ? AppColors.secondary : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data['q']!,
                      style: TextStyle(
                        fontSize: R.sp(context, 13),
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppColors.secondary : AppColors.black,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.remove : Icons.add,
                    color: isOpen ? AppColors.secondary : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                data['a']!,
                style: TextStyle(
                  fontSize: R.sp(context, 12),
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}