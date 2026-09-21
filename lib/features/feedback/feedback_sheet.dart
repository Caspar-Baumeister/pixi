import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/links.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';

/// Where feedback mails go.
const String kFeedbackEmail = Links.supportEmail;

enum FeedbackKind { firstMap, firstCheckin }

/// Small, friendly feedback prompt shown once after the first map and once
/// after the first check-in.
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key, required this.kind});
  final FeedbackKind kind;

  static Future<void> show(BuildContext context, {required FeedbackKind kind}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FeedbackSheet(kind: kind),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int? _rating; // 0 bad, 1 meh, 2 good
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = S.of(context);
    final subject = Uri.encodeComponent('Pixi Feedback (${widget.kind.name})');
    final body = Uri.encodeComponent('${['👎', '😐', '👍'][_rating ?? 1]}\n\n${_text.text}');
    final uri = Uri.parse('mailto:$kFeedbackEmail?subject=$subject&body=$body');
    try {
      await launchUrl(uri);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s.t('fb_thanks'))));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final first = widget.kind == FeedbackKind.firstMap;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(first ? s.t('fb_map_title') : s.t('fb_checkin_title'), style: PixiText.title(size: 22)),
                    const SizedBox(height: 4),
                    Text(first ? s.t('fb_map_sub') : s.t('fb_checkin_sub'), style: PixiText.body1(color: PixiColors.muted)),
                  ],
                ),
              ),
              const PixiCat(size: 84),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final (i, label) in [s.t('fb_bad'), s.t('fb_meh'), s.t('fb_good')].indexed) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _rating = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _rating == i ? PixiColors.ink : PixiColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _rating == i ? PixiColors.ink : PixiColors.line),
                      ),
                      child: Center(
                        child: Text(label,
                            style: PixiText.label(size: 14, color: _rating == i ? Colors.white : PixiColors.ink)),
                      ),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 8),
              ],
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _rating == null || _rating == 2
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: TextField(
                      controller: _text,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: s.t('fb_tell')),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _rating == 2 ? s.t('fb_thanks') : s.t('fb_send'),
            onPressed: _rating == null
                ? null
                : () {
                    if (_rating == 2) {
                      Navigator.of(context).pop();
                    } else {
                      _send();
                    }
                  },
          ),
          SecondaryButton(label: s.t('later'), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
