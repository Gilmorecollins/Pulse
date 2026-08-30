import 'package:intl/intl.dart';

import '../../../core/models/mood.dart';
import '../../../core/models/task_enums.dart';
import 'report_providers.dart';

/// Plain-text report summary for sharing — same sections
/// `_ReportBody` renders, formatted as a message rather than widgets.
/// See docs/API.md for why this is a tap-to-send WhatsApp deep link
/// rather than the WhatsApp Business API.
String buildReportShareText(ReportViewData data) {
  final planned = data.tasks
      .where(
        (t) =>
            TaskSource.fromDb(t.source) == TaskSource.morningPlan ||
            TaskSource.fromDb(t.source) == TaskSource.userAdded,
      )
      .toList();
  final completed = planned
      .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
      .toList();
  final notCompleted = planned
      .where((t) => TaskStatus.fromDb(t.status) != TaskStatus.completed)
      .toList();
  final activities = data.tasks
      .where(
        (t) =>
            TaskSource.fromDb(t.source) == TaskSource.pulseCheckin ||
            TaskSource.fromDb(t.source) == TaskSource.aiSuggested,
      )
      .toList();
  final total = planned.length;
  final pct = total == 0 ? 0 : ((completed.length / total) * 100).round();

  final buffer = StringBuffer()
    ..writeln('📊 Pulse — ${DateFormat('EEEE, d MMMM').format(data.plan.date)}')
    ..writeln()
    ..writeln(
      total == 0
          ? 'No tasks planned'
          : 'Productivity: $pct% (${completed.length}/$total tasks)',
    );

  if (completed.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('✅ Completed');
    for (final t in completed) {
      buffer.writeln('• ${t.title}');
    }
  }

  if (notCompleted.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('◻️ Not completed');
    for (final t in notCompleted) {
      final note = t.explanationNote;
      buffer.writeln(note == null ? '• ${t.title}' : '• ${t.title} — "$note"');
    }
  }

  if (activities.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('✨ New activities');
    for (final t in activities) {
      buffer.writeln('• ${t.title}');
    }
  }

  final reflection = data.reflection;
  if (reflection != null) {
    buffer
      ..writeln()
      ..writeln('Mood: ${Mood.fromDb(reflection.mood).label}');
    if (reflection.biggestWin != null) {
      buffer.writeln('🏆 Biggest win: ${reflection.biggestWin}');
    }
    if (reflection.carryForward != null) {
      buffer.writeln('➡️ Carried forward: ${reflection.carryForward}');
    }
  }

  return buffer.toString().trim();
}
