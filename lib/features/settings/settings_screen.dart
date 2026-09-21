import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/links.dart';
import '../../core/screenshot_mode.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../services/notification_service.dart';
import '../../services/premium_service.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';
import '../feedback/feedback_sheet.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(settingsProvider).name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _applyReminder({bool? enabled, TimeOfDay? time}) async {
    final s = S.of(context);
    final notifier = ref.read(appProvider.notifier);
    var settings = ref.read(settingsProvider);
    var on = enabled ?? settings.remindersEnabled;
    if (on && enabled == true) {
      on = await NotificationService.instance.requestPermission();
    }
    notifier.updateSettings((st) => st.copyWith(
          remindersEnabled: on,
          reminderHour: time?.hour ?? st.reminderHour,
          reminderMinute: time?.minute ?? st.reminderMinute,
        ));
    settings = ref.read(settingsProvider);
    if (on) {
      await NotificationService.instance.scheduleDaily(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
        title: s.withName('notif_title', settings.name),
        body: s.t('notif_body'),
      );
    } else {
      await NotificationService.instance.cancelDaily();
    }
  }

  Future<void> _export() async {
    final data = ref.read(appProvider);
    final json = await ref.read(repositoryProvider).exportJson(data);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/pixi_export.json');
    await f.writeAsString(json);
    await Share.shareXFiles([XFile(f.path, mimeType: 'application/json')]);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final time = TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute);

    return Scaffold(
      backgroundColor: PixiColors.paper,
      appBar: AppBar(
        title: Text(s.t('settings'), style: PixiText.title(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          // ---- reminder
          _Section(
            title: s.t('reminder'),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('reminder_on'), style: PixiText.body1(color: PixiColors.ink)),
                value: settings.remindersEnabled,
                onChanged: (v) => _applyReminder(enabled: v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('reminder_time'), style: PixiText.body1(color: PixiColors.ink)),
                trailing: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: PixiText.title(size: 20),
                ),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: time);
                  if (t != null) _applyReminder(time: t);
                },
              ),
            ],
          ),

          // ---- name
          _Section(
            title: s.t('your_name'),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: s.t('ob_name_hint')),
                onChanged: (v) => ref.read(appProvider.notifier).updateSettings((st) => st.copyWith(name: v.trim())),
              ),
            ],
          ),

          // ---- premium
          _Section(
            title: s.t('premium'),
            children: [
              PaperCard(
                onTap: settings.premium
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                child: Row(
                  children: [
                    const PixiCat(size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settings.premium ? s.t('premium_active') : s.t('free_limit_sub'),
                        style: PixiText.body1(color: PixiColors.ink),
                      ),
                    ),
                    if (!settings.premium) const Icon(Icons.chevron_right_rounded, color: PixiColors.muted),
                  ],
                ),
              ),
              if (kScreenshotMode)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('English (Screenshots)', style: PixiText.label()),
                  value: s.locale.languageCode == 'en',
                  onChanged: (v) => ref.read(localeOverrideProvider.notifier).state = Locale(v ? 'en' : 'de'),
                ),
              if (kDebugMode)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.t('dev_toggle_premium'), style: PixiText.label()),
                  value: settings.premium,
                  onChanged: (v) => ref.read(appProvider.notifier).updateSettings((st) => st.copyWith(premium: v)),
                ),
            ],
          ),

          // ---- misc
          _Section(
            title: s.t('about'),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.ios_share_rounded, color: PixiColors.ink),
                title: Text(s.t('export'), style: PixiText.body1(color: PixiColors.ink)),
                onTap: _export,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: PixiColors.ink),
                title: Text(s.t('feedback'), style: PixiText.body1(color: PixiColors.ink)),
                onTap: () => launchUrl(Uri.parse('mailto:$kFeedbackEmail?subject=Pixi')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline_rounded, color: PixiColors.ink),
                title: Text(s.t('privacy'), style: PixiText.body1(color: PixiColors.ink)),
                onTap: () => launchUrl(Uri.parse(Links.privacy)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: PixiColors.ink),
                title: Text(s.t('terms'), style: PixiText.body1(color: PixiColors.ink)),
                onTap: () => launchUrl(Uri.parse(Links.terms)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded, color: PixiColors.ink),
                title: Text(s.t('restore'), style: PixiText.body1(color: PixiColors.ink)),
                onTap: () async {
                  final ok = await PremiumService.instance.restore();
                  if (!context.mounted) return;
                  if (ok) ref.read(appProvider.notifier).updateSettings((st) => st.copyWith(premium: true));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? s.t('premium_active') : s.t('restore_none'))),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded, color: PixiColors.ink),
                title: Text('${s.t('version')} 1.0.0', style: PixiText.body1(color: PixiColors.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PixiText.label()),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}
