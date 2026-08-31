import 'package:intl/intl.dart';

import '../../../core/models/mood.dart';
import '../../../core/models/task_enums.dart';
import 'report_providers.dart';

/// Plain-text report summary for sharing — same sections
/// `_ReportBody` renders, formatted as a message rather than widgets.
/// Styled after a classic numbered daily-tracker message (bold title,
/// numbered tasks with a description under each, a Done section and a
/// Carry Forward section) rather than a generic bullet list. See
/// docs/API.md for why this is a tap-to-send WhatsApp deep link rather
/// than the WhatsApp Business API — `*text*` below is WhatsApp's own
/// bold markup, not markdown.
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

  final title = DateFormat('MMMM d, yyyy').format(data.plan.date).toUpperCase();
  final buffer = StringBuffer()
    ..writeln('*DAILY TASK TRACKER — $title*')
    ..writeln()
    ..writeln(
      total == 0
          ? 'No tasks planned'
          : 'Productivity: $pct% (${completed.length}/$total tasks)',
    );

  // Numbered continuously across Done and Carry Forward, matching a
  // running daily checklist rather than two separately-numbered lists.
  var itemNumber = 0;

  if (completed.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('🟢 *DONE*');
    for (final t in completed) {
      itemNumber++;
      buffer.writeln('$itemNumber. ${t.title} ✅');
      if (t.description != null) buffer.writeln(t.description);
    }
  }

  if (notCompleted.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('🔴 *CARRY FORWARD TO THE NEXT DAY*');
    for (final t in notCompleted) {
      itemNumber++;
      buffer.writeln('$itemNumber. ${t.title}');
      if (t.description != null) buffer.writeln(t.description);
      if (t.explanationNote != null) buffer.writeln('Note: "${t.explanationNote}"');
    }
  }

  if (activities.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('✨ *New activities*');
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
