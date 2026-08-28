/// String constants matching the `status` column in the Tasks table.
/// Kept as raw strings at the persistence boundary (see docs/DATABASE.md)
/// but exposed as an enum everywhere else so the UI/business logic never
/// deals with typos-prone string literals.
enum TaskStatus {
  planned,
  inProgress,
  completed,
  cancelled,
  carriedForward;

  static TaskStatus fromDb(String value) => switch (value) {
        'planned' => TaskStatus.planned,
        'in_progress' => TaskStatus.inProgress,
        'completed' => TaskStatus.completed,
        'cancelled' => TaskStatus.cancelled,
        'carried_forward' => TaskStatus.carriedForward,
        _ => throw ArgumentError('Unknown task status: $value'),
      };

  String toDb() => switch (this) {
        TaskStatus.planned => 'planned',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.completed => 'completed',
        TaskStatus.cancelled => 'cancelled',
        TaskStatus.carriedForward => 'carried_forward',
      };
}

enum TaskPriority {
  low,
  medium,
  high,
  critical;

  static TaskPriority fromDb(String value) => TaskPriority.values.firstWhere(
        (p) => p.name == value,
        orElse: () => TaskPriority.medium,
      );

  String toDb() => name;
}

enum TaskSource {
  morningPlan,
  userAdded,
  pulseCheckin,
  aiSuggested;

  static TaskSource fromDb(String value) => switch (value) {
        'morning_plan' => TaskSource.morningPlan,
        'user_added' => TaskSource.userAdded,
        'pulse_checkin' => TaskSource.pulseCheckin,
        'ai_suggested' => TaskSource.aiSuggested,
        _ => throw ArgumentError('Unknown task source: $value'),
      };

  String toDb() => switch (this) {
        TaskSource.morningPlan => 'morning_plan',
        TaskSource.userAdded => 'user_added',
        TaskSource.pulseCheckin => 'pulse_checkin',
        TaskSource.aiSuggested => 'ai_suggested',
      };
}
