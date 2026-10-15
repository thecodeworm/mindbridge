import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_events.dart';
import '../../widgets/crisis_fab.dart';
import '../mood/mood_log_screen.dart';
import 'history_list.dart';

/// "Journal" tab: every past check-in, newest first, grouped by month.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: const [HelpAction()],
      ),
      body: userId == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: () async => notifyMoodDataChanged(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  HistoryList(
                    userId: userId,
                    onEntryChanged: notifyMoodDataChanged,
                    onLogMood: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MoodLogScreen()),
                      );
                      notifyMoodDataChanged();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
