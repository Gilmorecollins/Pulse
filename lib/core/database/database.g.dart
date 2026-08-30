// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyPlansTable extends DailyPlans
    with TableInfo<$DailyPlansTable, DailyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyPlansTable createAlias(String alias) {
    return $DailyPlansTable(attachedDatabase, alias);
  }
}

class DailyPlan extends DataClass implements Insertable<DailyPlan> {
  final String id;
  final DateTime date;
  final DateTime createdAt;
  const DailyPlan({
    required this.id,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyPlansCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansCompanion(
      id: Value(id),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlan(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyPlan copyWith({String? id, DateTime? date, DateTime? createdAt}) =>
      DailyPlan(
        id: id ?? this.id,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );
  DailyPlan copyWithCompanion(DailyPlansCompanion data) {
    return DailyPlan(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlan(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlan &&
          other.id == this.id &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class DailyPlansCompanion extends UpdateCompanion<DailyPlan> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyPlansCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPlansCompanion.insert({
    required String id,
    required DateTime date,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<DailyPlan> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPlansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyPlansCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyPlanIdMeta = const VerificationMeta(
    'dailyPlanId',
  );
  @override
  late final GeneratedColumn<String> dailyPlanId = GeneratedColumn<String>(
    'daily_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('planned'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedForMeta = const VerificationMeta(
    'plannedFor',
  );
  @override
  late final GeneratedColumn<DateTime> plannedFor = GeneratedColumn<DateTime>(
    'planned_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedDurationMeta = const VerificationMeta(
    'estimatedDuration',
  );
  @override
  late final GeneratedColumn<int> estimatedDuration = GeneratedColumn<int>(
    'estimated_duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualDurationMeta = const VerificationMeta(
    'actualDuration',
  );
  @override
  late final GeneratedColumn<int> actualDuration = GeneratedColumn<int>(
    'actual_duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user_added'),
  );
  static const VerificationMeta _expectedCompletionTimeMeta =
      const VerificationMeta('expectedCompletionTime');
  @override
  late final GeneratedColumn<DateTime> expectedCompletionTime =
      GeneratedColumn<DateTime>(
        'expected_completion_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _explanationNoteMeta = const VerificationMeta(
    'explanationNote',
  );
  @override
  late final GeneratedColumn<String> explanationNote = GeneratedColumn<String>(
    'explanation_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyPlanId,
    title,
    description,
    status,
    priority,
    createdAt,
    completedAt,
    plannedFor,
    estimatedDuration,
    actualDuration,
    source,
    expectedCompletionTime,
    explanationNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('daily_plan_id')) {
      context.handle(
        _dailyPlanIdMeta,
        dailyPlanId.isAcceptableOrUnknown(
          data['daily_plan_id']!,
          _dailyPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyPlanIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('planned_for')) {
      context.handle(
        _plannedForMeta,
        plannedFor.isAcceptableOrUnknown(data['planned_for']!, _plannedForMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedForMeta);
    }
    if (data.containsKey('estimated_duration')) {
      context.handle(
        _estimatedDurationMeta,
        estimatedDuration.isAcceptableOrUnknown(
          data['estimated_duration']!,
          _estimatedDurationMeta,
        ),
      );
    }
    if (data.containsKey('actual_duration')) {
      context.handle(
        _actualDurationMeta,
        actualDuration.isAcceptableOrUnknown(
          data['actual_duration']!,
          _actualDurationMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('expected_completion_time')) {
      context.handle(
        _expectedCompletionTimeMeta,
        expectedCompletionTime.isAcceptableOrUnknown(
          data['expected_completion_time']!,
          _expectedCompletionTimeMeta,
        ),
      );
    }
    if (data.containsKey('explanation_note')) {
      context.handle(
        _explanationNoteMeta,
        explanationNote.isAcceptableOrUnknown(
          data['explanation_note']!,
          _explanationNoteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dailyPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_plan_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      plannedFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_for'],
      )!,
      estimatedDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_duration'],
      ),
      actualDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      expectedCompletionTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_completion_time'],
      ),
      explanationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_note'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String dailyPlanId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime plannedFor;
  final int? estimatedDuration;
  final int? actualDuration;
  final String source;
  final DateTime? expectedCompletionTime;
  final String? explanationNote;
  const Task({
    required this.id,
    required this.dailyPlanId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.completedAt,
    required this.plannedFor,
    this.estimatedDuration,
    this.actualDuration,
    required this.source,
    this.expectedCompletionTime,
    this.explanationNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['daily_plan_id'] = Variable<String>(dailyPlanId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['planned_for'] = Variable<DateTime>(plannedFor);
    if (!nullToAbsent || estimatedDuration != null) {
      map['estimated_duration'] = Variable<int>(estimatedDuration);
    }
    if (!nullToAbsent || actualDuration != null) {
      map['actual_duration'] = Variable<int>(actualDuration);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || expectedCompletionTime != null) {
      map['expected_completion_time'] = Variable<DateTime>(
        expectedCompletionTime,
      );
    }
    if (!nullToAbsent || explanationNote != null) {
      map['explanation_note'] = Variable<String>(explanationNote);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      dailyPlanId: Value(dailyPlanId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      priority: Value(priority),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      plannedFor: Value(plannedFor),
      estimatedDuration: estimatedDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDuration),
      actualDuration: actualDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDuration),
      source: Value(source),
      expectedCompletionTime: expectedCompletionTime == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCompletionTime),
      explanationNote: explanationNote == null && nullToAbsent
          ? const Value.absent()
          : Value(explanationNote),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      dailyPlanId: serializer.fromJson<String>(json['dailyPlanId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      plannedFor: serializer.fromJson<DateTime>(json['plannedFor']),
      estimatedDuration: serializer.fromJson<int?>(json['estimatedDuration']),
      actualDuration: serializer.fromJson<int?>(json['actualDuration']),
      source: serializer.fromJson<String>(json['source']),
      expectedCompletionTime: serializer.fromJson<DateTime?>(
        json['expectedCompletionTime'],
      ),
      explanationNote: serializer.fromJson<String?>(json['explanationNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dailyPlanId': serializer.toJson<String>(dailyPlanId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'plannedFor': serializer.toJson<DateTime>(plannedFor),
      'estimatedDuration': serializer.toJson<int?>(estimatedDuration),
      'actualDuration': serializer.toJson<int?>(actualDuration),
      'source': serializer.toJson<String>(source),
      'expectedCompletionTime': serializer.toJson<DateTime?>(
        expectedCompletionTime,
      ),
      'explanationNote': serializer.toJson<String?>(explanationNote),
    };
  }

  Task copyWith({
    String? id,
    String? dailyPlanId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? priority,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? plannedFor,
    Value<int?> estimatedDuration = const Value.absent(),
    Value<int?> actualDuration = const Value.absent(),
    String? source,
    Value<DateTime?> expectedCompletionTime = const Value.absent(),
    Value<String?> explanationNote = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    dailyPlanId: dailyPlanId ?? this.dailyPlanId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    plannedFor: plannedFor ?? this.plannedFor,
    estimatedDuration: estimatedDuration.present
        ? estimatedDuration.value
        : this.estimatedDuration,
    actualDuration: actualDuration.present
        ? actualDuration.value
        : this.actualDuration,
    source: source ?? this.source,
    expectedCompletionTime: expectedCompletionTime.present
        ? expectedCompletionTime.value
        : this.expectedCompletionTime,
    explanationNote: explanationNote.present
        ? explanationNote.value
        : this.explanationNote,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      dailyPlanId: data.dailyPlanId.present
          ? data.dailyPlanId.value
          : this.dailyPlanId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      plannedFor: data.plannedFor.present
          ? data.plannedFor.value
          : this.plannedFor,
      estimatedDuration: data.estimatedDuration.present
          ? data.estimatedDuration.value
          : this.estimatedDuration,
      actualDuration: data.actualDuration.present
          ? data.actualDuration.value
          : this.actualDuration,
      source: data.source.present ? data.source.value : this.source,
      expectedCompletionTime: data.expectedCompletionTime.present
          ? data.expectedCompletionTime.value
          : this.expectedCompletionTime,
      explanationNote: data.explanationNote.present
          ? data.explanationNote.value
          : this.explanationNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('plannedFor: $plannedFor, ')
          ..write('estimatedDuration: $estimatedDuration, ')
          ..write('actualDuration: $actualDuration, ')
          ..write('source: $source, ')
          ..write('expectedCompletionTime: $expectedCompletionTime, ')
          ..write('explanationNote: $explanationNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyPlanId,
    title,
    description,
    status,
    priority,
    createdAt,
    completedAt,
    plannedFor,
    estimatedDuration,
    actualDuration,
    source,
    expectedCompletionTime,
    explanationNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.dailyPlanId == this.dailyPlanId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.plannedFor == this.plannedFor &&
          other.estimatedDuration == this.estimatedDuration &&
          other.actualDuration == this.actualDuration &&
          other.source == this.source &&
          other.expectedCompletionTime == this.expectedCompletionTime &&
          other.explanationNote == this.explanationNote);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> dailyPlanId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime> plannedFor;
  final Value<int?> estimatedDuration;
  final Value<int?> actualDuration;
  final Value<String> source;
  final Value<DateTime?> expectedCompletionTime;
  final Value<String?> explanationNote;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.dailyPlanId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.plannedFor = const Value.absent(),
    this.estimatedDuration = const Value.absent(),
    this.actualDuration = const Value.absent(),
    this.source = const Value.absent(),
    this.expectedCompletionTime = const Value.absent(),
    this.explanationNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String dailyPlanId,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    required DateTime plannedFor,
    this.estimatedDuration = const Value.absent(),
    this.actualDuration = const Value.absent(),
    this.source = const Value.absent(),
    this.expectedCompletionTime = const Value.absent(),
    this.explanationNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dailyPlanId = Value(dailyPlanId),
       title = Value(title),
       createdAt = Value(createdAt),
       plannedFor = Value(plannedFor);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? dailyPlanId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? plannedFor,
    Expression<int>? estimatedDuration,
    Expression<int>? actualDuration,
    Expression<String>? source,
    Expression<DateTime>? expectedCompletionTime,
    Expression<String>? explanationNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyPlanId != null) 'daily_plan_id': dailyPlanId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (plannedFor != null) 'planned_for': plannedFor,
      if (estimatedDuration != null) 'estimated_duration': estimatedDuration,
      if (actualDuration != null) 'actual_duration': actualDuration,
      if (source != null) 'source': source,
      if (expectedCompletionTime != null)
        'expected_completion_time': expectedCompletionTime,
      if (explanationNote != null) 'explanation_note': explanationNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? dailyPlanId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<DateTime>? plannedFor,
    Value<int?>? estimatedDuration,
    Value<int?>? actualDuration,
    Value<String>? source,
    Value<DateTime?>? expectedCompletionTime,
    Value<String?>? explanationNote,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      dailyPlanId: dailyPlanId ?? this.dailyPlanId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      plannedFor: plannedFor ?? this.plannedFor,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      source: source ?? this.source,
      expectedCompletionTime:
          expectedCompletionTime ?? this.expectedCompletionTime,
      explanationNote: explanationNote ?? this.explanationNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dailyPlanId.present) {
      map['daily_plan_id'] = Variable<String>(dailyPlanId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (plannedFor.present) {
      map['planned_for'] = Variable<DateTime>(plannedFor.value);
    }
    if (estimatedDuration.present) {
      map['estimated_duration'] = Variable<int>(estimatedDuration.value);
    }
    if (actualDuration.present) {
      map['actual_duration'] = Variable<int>(actualDuration.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (expectedCompletionTime.present) {
      map['expected_completion_time'] = Variable<DateTime>(
        expectedCompletionTime.value,
      );
    }
    if (explanationNote.present) {
      map['explanation_note'] = Variable<String>(explanationNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('plannedFor: $plannedFor, ')
          ..write('estimatedDuration: $estimatedDuration, ')
          ..write('actualDuration: $actualDuration, ')
          ..write('source: $source, ')
          ..write('expectedCompletionTime: $expectedCompletionTime, ')
          ..write('explanationNote: $explanationNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyPlanIdMeta = const VerificationMeta(
    'dailyPlanId',
  );
  @override
  late final GeneratedColumn<String> dailyPlanId = GeneratedColumn<String>(
    'daily_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
    'scheduled_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyPlanId,
    taskId,
    scheduledFor,
    respondedAt,
    status,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('daily_plan_id')) {
      context.handle(
        _dailyPlanIdMeta,
        dailyPlanId.isAcceptableOrUnknown(
          data['daily_plan_id']!,
          _dailyPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyPlanIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledForMeta);
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dailyPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_plan_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_for'],
      )!,
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final String id;
  final String dailyPlanId;
  final String? taskId;
  final DateTime scheduledFor;
  final DateTime? respondedAt;
  final String status;
  final String? note;
  const CheckIn({
    required this.id,
    required this.dailyPlanId,
    this.taskId,
    required this.scheduledFor,
    this.respondedAt,
    required this.status,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['daily_plan_id'] = Variable<String>(dailyPlanId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      dailyPlanId: Value(dailyPlanId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      scheduledFor: Value(scheduledFor),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<String>(json['id']),
      dailyPlanId: serializer.fromJson<String>(json['dailyPlanId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      scheduledFor: serializer.fromJson<DateTime>(json['scheduledFor']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dailyPlanId': serializer.toJson<String>(dailyPlanId),
      'taskId': serializer.toJson<String?>(taskId),
      'scheduledFor': serializer.toJson<DateTime>(scheduledFor),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
    };
  }

  CheckIn copyWith({
    String? id,
    String? dailyPlanId,
    Value<String?> taskId = const Value.absent(),
    DateTime? scheduledFor,
    Value<DateTime?> respondedAt = const Value.absent(),
    String? status,
    Value<String?> note = const Value.absent(),
  }) => CheckIn(
    id: id ?? this.id,
    dailyPlanId: dailyPlanId ?? this.dailyPlanId,
    taskId: taskId.present ? taskId.value : this.taskId,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      dailyPlanId: data.dailyPlanId.present
          ? data.dailyPlanId.value
          : this.dailyPlanId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('status: $status, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyPlanId,
    taskId,
    scheduledFor,
    respondedAt,
    status,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.dailyPlanId == this.dailyPlanId &&
          other.taskId == this.taskId &&
          other.scheduledFor == this.scheduledFor &&
          other.respondedAt == this.respondedAt &&
          other.status == this.status &&
          other.note == this.note);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<String> id;
  final Value<String> dailyPlanId;
  final Value<String?> taskId;
  final Value<DateTime> scheduledFor;
  final Value<DateTime?> respondedAt;
  final Value<String> status;
  final Value<String?> note;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.dailyPlanId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required String id,
    required String dailyPlanId,
    this.taskId = const Value.absent(),
    required DateTime scheduledFor,
    this.respondedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dailyPlanId = Value(dailyPlanId),
       scheduledFor = Value(scheduledFor);
  static Insertable<CheckIn> custom({
    Expression<String>? id,
    Expression<String>? dailyPlanId,
    Expression<String>? taskId,
    Expression<DateTime>? scheduledFor,
    Expression<DateTime>? respondedAt,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyPlanId != null) 'daily_plan_id': dailyPlanId,
      if (taskId != null) 'task_id': taskId,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({
    Value<String>? id,
    Value<String>? dailyPlanId,
    Value<String?>? taskId,
    Value<DateTime>? scheduledFor,
    Value<DateTime?>? respondedAt,
    Value<String>? status,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      dailyPlanId: dailyPlanId ?? this.dailyPlanId,
      taskId: taskId ?? this.taskId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      respondedAt: respondedAt ?? this.respondedAt,
      status: status ?? this.status,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dailyPlanId.present) {
      map['daily_plan_id'] = Variable<String>(dailyPlanId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReflectionsTable extends DailyReflections
    with TableInfo<$DailyReflectionsTable, DailyReflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyPlanIdMeta = const VerificationMeta(
    'dailyPlanId',
  );
  @override
  late final GeneratedColumn<String> dailyPlanId = GeneratedColumn<String>(
    'daily_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _biggestWinMeta = const VerificationMeta(
    'biggestWin',
  );
  @override
  late final GeneratedColumn<String> biggestWin = GeneratedColumn<String>(
    'biggest_win',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carryForwardMeta = const VerificationMeta(
    'carryForward',
  );
  @override
  late final GeneratedColumn<String> carryForward = GeneratedColumn<String>(
    'carry_forward',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyPlanId,
    mood,
    biggestWin,
    carryForward,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('daily_plan_id')) {
      context.handle(
        _dailyPlanIdMeta,
        dailyPlanId.isAcceptableOrUnknown(
          data['daily_plan_id']!,
          _dailyPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyPlanIdMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('biggest_win')) {
      context.handle(
        _biggestWinMeta,
        biggestWin.isAcceptableOrUnknown(data['biggest_win']!, _biggestWinMeta),
      );
    }
    if (data.containsKey('carry_forward')) {
      context.handle(
        _carryForwardMeta,
        carryForward.isAcceptableOrUnknown(
          data['carry_forward']!,
          _carryForwardMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyReflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dailyPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_plan_id'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      biggestWin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biggest_win'],
      ),
      carryForward: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carry_forward'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyReflectionsTable createAlias(String alias) {
    return $DailyReflectionsTable(attachedDatabase, alias);
  }
}

class DailyReflection extends DataClass implements Insertable<DailyReflection> {
  final String id;
  final String dailyPlanId;
  final String mood;
  final String? biggestWin;
  final String? carryForward;
  final DateTime createdAt;
  const DailyReflection({
    required this.id,
    required this.dailyPlanId,
    required this.mood,
    this.biggestWin,
    this.carryForward,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['daily_plan_id'] = Variable<String>(dailyPlanId);
    map['mood'] = Variable<String>(mood);
    if (!nullToAbsent || biggestWin != null) {
      map['biggest_win'] = Variable<String>(biggestWin);
    }
    if (!nullToAbsent || carryForward != null) {
      map['carry_forward'] = Variable<String>(carryForward);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyReflectionsCompanion toCompanion(bool nullToAbsent) {
    return DailyReflectionsCompanion(
      id: Value(id),
      dailyPlanId: Value(dailyPlanId),
      mood: Value(mood),
      biggestWin: biggestWin == null && nullToAbsent
          ? const Value.absent()
          : Value(biggestWin),
      carryForward: carryForward == null && nullToAbsent
          ? const Value.absent()
          : Value(carryForward),
      createdAt: Value(createdAt),
    );
  }

  factory DailyReflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReflection(
      id: serializer.fromJson<String>(json['id']),
      dailyPlanId: serializer.fromJson<String>(json['dailyPlanId']),
      mood: serializer.fromJson<String>(json['mood']),
      biggestWin: serializer.fromJson<String?>(json['biggestWin']),
      carryForward: serializer.fromJson<String?>(json['carryForward']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dailyPlanId': serializer.toJson<String>(dailyPlanId),
      'mood': serializer.toJson<String>(mood),
      'biggestWin': serializer.toJson<String?>(biggestWin),
      'carryForward': serializer.toJson<String?>(carryForward),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyReflection copyWith({
    String? id,
    String? dailyPlanId,
    String? mood,
    Value<String?> biggestWin = const Value.absent(),
    Value<String?> carryForward = const Value.absent(),
    DateTime? createdAt,
  }) => DailyReflection(
    id: id ?? this.id,
    dailyPlanId: dailyPlanId ?? this.dailyPlanId,
    mood: mood ?? this.mood,
    biggestWin: biggestWin.present ? biggestWin.value : this.biggestWin,
    carryForward: carryForward.present ? carryForward.value : this.carryForward,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyReflection copyWithCompanion(DailyReflectionsCompanion data) {
    return DailyReflection(
      id: data.id.present ? data.id.value : this.id,
      dailyPlanId: data.dailyPlanId.present
          ? data.dailyPlanId.value
          : this.dailyPlanId,
      mood: data.mood.present ? data.mood.value : this.mood,
      biggestWin: data.biggestWin.present
          ? data.biggestWin.value
          : this.biggestWin,
      carryForward: data.carryForward.present
          ? data.carryForward.value
          : this.carryForward,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReflection(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('mood: $mood, ')
          ..write('biggestWin: $biggestWin, ')
          ..write('carryForward: $carryForward, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dailyPlanId, mood, biggestWin, carryForward, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReflection &&
          other.id == this.id &&
          other.dailyPlanId == this.dailyPlanId &&
          other.mood == this.mood &&
          other.biggestWin == this.biggestWin &&
          other.carryForward == this.carryForward &&
          other.createdAt == this.createdAt);
}

class DailyReflectionsCompanion extends UpdateCompanion<DailyReflection> {
  final Value<String> id;
  final Value<String> dailyPlanId;
  final Value<String> mood;
  final Value<String?> biggestWin;
  final Value<String?> carryForward;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyReflectionsCompanion({
    this.id = const Value.absent(),
    this.dailyPlanId = const Value.absent(),
    this.mood = const Value.absent(),
    this.biggestWin = const Value.absent(),
    this.carryForward = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReflectionsCompanion.insert({
    required String id,
    required String dailyPlanId,
    required String mood,
    this.biggestWin = const Value.absent(),
    this.carryForward = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dailyPlanId = Value(dailyPlanId),
       mood = Value(mood),
       createdAt = Value(createdAt);
  static Insertable<DailyReflection> custom({
    Expression<String>? id,
    Expression<String>? dailyPlanId,
    Expression<String>? mood,
    Expression<String>? biggestWin,
    Expression<String>? carryForward,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyPlanId != null) 'daily_plan_id': dailyPlanId,
      if (mood != null) 'mood': mood,
      if (biggestWin != null) 'biggest_win': biggestWin,
      if (carryForward != null) 'carry_forward': carryForward,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReflectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? dailyPlanId,
    Value<String>? mood,
    Value<String?>? biggestWin,
    Value<String?>? carryForward,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyReflectionsCompanion(
      id: id ?? this.id,
      dailyPlanId: dailyPlanId ?? this.dailyPlanId,
      mood: mood ?? this.mood,
      biggestWin: biggestWin ?? this.biggestWin,
      carryForward: carryForward ?? this.carryForward,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dailyPlanId.present) {
      map['daily_plan_id'] = Variable<String>(dailyPlanId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (biggestWin.present) {
      map['biggest_win'] = Variable<String>(biggestWin.value);
    }
    if (carryForward.present) {
      map['carry_forward'] = Variable<String>(carryForward.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('mood: $mood, ')
          ..write('biggestWin: $biggestWin, ')
          ..write('carryForward: $carryForward, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReportsTable extends DailyReports
    with TableInfo<$DailyReportsTable, DailyReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyPlanIdMeta = const VerificationMeta(
    'dailyPlanId',
  );
  @override
  late final GeneratedColumn<String> dailyPlanId = GeneratedColumn<String>(
    'daily_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _completionRateMeta = const VerificationMeta(
    'completionRate',
  );
  @override
  late final GeneratedColumn<double> completionRate = GeneratedColumn<double>(
    'completion_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyPlanId,
    completionRate,
    generatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('daily_plan_id')) {
      context.handle(
        _dailyPlanIdMeta,
        dailyPlanId.isAcceptableOrUnknown(
          data['daily_plan_id']!,
          _dailyPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyPlanIdMeta);
    }
    if (data.containsKey('completion_rate')) {
      context.handle(
        _completionRateMeta,
        completionRate.isAcceptableOrUnknown(
          data['completion_rate']!,
          _completionRateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionRateMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dailyPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_plan_id'],
      )!,
      completionRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_rate'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
    );
  }

  @override
  $DailyReportsTable createAlias(String alias) {
    return $DailyReportsTable(attachedDatabase, alias);
  }
}

class DailyReport extends DataClass implements Insertable<DailyReport> {
  final String id;
  final String dailyPlanId;
  final double completionRate;
  final DateTime generatedAt;
  const DailyReport({
    required this.id,
    required this.dailyPlanId,
    required this.completionRate,
    required this.generatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['daily_plan_id'] = Variable<String>(dailyPlanId);
    map['completion_rate'] = Variable<double>(completionRate);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  DailyReportsCompanion toCompanion(bool nullToAbsent) {
    return DailyReportsCompanion(
      id: Value(id),
      dailyPlanId: Value(dailyPlanId),
      completionRate: Value(completionRate),
      generatedAt: Value(generatedAt),
    );
  }

  factory DailyReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReport(
      id: serializer.fromJson<String>(json['id']),
      dailyPlanId: serializer.fromJson<String>(json['dailyPlanId']),
      completionRate: serializer.fromJson<double>(json['completionRate']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dailyPlanId': serializer.toJson<String>(dailyPlanId),
      'completionRate': serializer.toJson<double>(completionRate),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  DailyReport copyWith({
    String? id,
    String? dailyPlanId,
    double? completionRate,
    DateTime? generatedAt,
  }) => DailyReport(
    id: id ?? this.id,
    dailyPlanId: dailyPlanId ?? this.dailyPlanId,
    completionRate: completionRate ?? this.completionRate,
    generatedAt: generatedAt ?? this.generatedAt,
  );
  DailyReport copyWithCompanion(DailyReportsCompanion data) {
    return DailyReport(
      id: data.id.present ? data.id.value : this.id,
      dailyPlanId: data.dailyPlanId.present
          ? data.dailyPlanId.value
          : this.dailyPlanId,
      completionRate: data.completionRate.present
          ? data.completionRate.value
          : this.completionRate,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReport(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('completionRate: $completionRate, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dailyPlanId, completionRate, generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReport &&
          other.id == this.id &&
          other.dailyPlanId == this.dailyPlanId &&
          other.completionRate == this.completionRate &&
          other.generatedAt == this.generatedAt);
}

class DailyReportsCompanion extends UpdateCompanion<DailyReport> {
  final Value<String> id;
  final Value<String> dailyPlanId;
  final Value<double> completionRate;
  final Value<DateTime> generatedAt;
  final Value<int> rowid;
  const DailyReportsCompanion({
    this.id = const Value.absent(),
    this.dailyPlanId = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReportsCompanion.insert({
    required String id,
    required String dailyPlanId,
    required double completionRate,
    required DateTime generatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dailyPlanId = Value(dailyPlanId),
       completionRate = Value(completionRate),
       generatedAt = Value(generatedAt);
  static Insertable<DailyReport> custom({
    Expression<String>? id,
    Expression<String>? dailyPlanId,
    Expression<double>? completionRate,
    Expression<DateTime>? generatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyPlanId != null) 'daily_plan_id': dailyPlanId,
      if (completionRate != null) 'completion_rate': completionRate,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? dailyPlanId,
    Value<double>? completionRate,
    Value<DateTime>? generatedAt,
    Value<int>? rowid,
  }) {
    return DailyReportsCompanion(
      id: id ?? this.id,
      dailyPlanId: dailyPlanId ?? this.dailyPlanId,
      completionRate: completionRate ?? this.completionRate,
      generatedAt: generatedAt ?? this.generatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dailyPlanId.present) {
      map['daily_plan_id'] = Variable<String>(dailyPlanId.value);
    }
    if (completionRate.present) {
      map['completion_rate'] = Variable<double>(completionRate.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsCompanion(')
          ..write('id: $id, ')
          ..write('dailyPlanId: $dailyPlanId, ')
          ..write('completionRate: $completionRate, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PulseDatabase extends GeneratedDatabase {
  _$PulseDatabase(QueryExecutor e) : super(e);
  $PulseDatabaseManager get managers => $PulseDatabaseManager(this);
  late final $DailyPlansTable dailyPlans = $DailyPlansTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $DailyReflectionsTable dailyReflections = $DailyReflectionsTable(
    this,
  );
  late final $DailyReportsTable dailyReports = $DailyReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyPlans,
    tasks,
    checkIns,
    dailyReflections,
    dailyReports,
  ];
}

typedef $$DailyPlansTableCreateCompanionBuilder =
    DailyPlansCompanion Function({
      required String id,
      required DateTime date,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DailyPlansTableUpdateCompanionBuilder =
    DailyPlansCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DailyPlansTableFilterComposer
    extends Composer<_$PulseDatabase, $DailyPlansTable> {
  $$DailyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPlansTableOrderingComposer
    extends Composer<_$PulseDatabase, $DailyPlansTable> {
  $$DailyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPlansTableAnnotationComposer
    extends Composer<_$PulseDatabase, $DailyPlansTable> {
  $$DailyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyPlansTableTableManager
    extends
        RootTableManager<
          _$PulseDatabase,
          $DailyPlansTable,
          DailyPlan,
          $$DailyPlansTableFilterComposer,
          $$DailyPlansTableOrderingComposer,
          $$DailyPlansTableAnnotationComposer,
          $$DailyPlansTableCreateCompanionBuilder,
          $$DailyPlansTableUpdateCompanionBuilder,
          (
            DailyPlan,
            BaseReferences<_$PulseDatabase, $DailyPlansTable, DailyPlan>,
          ),
          DailyPlan,
          PrefetchHooks Function()
        > {
  $$DailyPlansTableTableManager(_$PulseDatabase db, $DailyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansCompanion(
                id: id,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansCompanion.insert(
                id: id,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$PulseDatabase,
      $DailyPlansTable,
      DailyPlan,
      $$DailyPlansTableFilterComposer,
      $$DailyPlansTableOrderingComposer,
      $$DailyPlansTableAnnotationComposer,
      $$DailyPlansTableCreateCompanionBuilder,
      $$DailyPlansTableUpdateCompanionBuilder,
      (DailyPlan, BaseReferences<_$PulseDatabase, $DailyPlansTable, DailyPlan>),
      DailyPlan,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String dailyPlanId,
      required String title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      required DateTime plannedFor,
      Value<int?> estimatedDuration,
      Value<int?> actualDuration,
      Value<String> source,
      Value<DateTime?> expectedCompletionTime,
      Value<String?> explanationNote,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> dailyPlanId,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime> plannedFor,
      Value<int?> estimatedDuration,
      Value<int?> actualDuration,
      Value<String> source,
      Value<DateTime?> expectedCompletionTime,
      Value<String?> explanationNote,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer
    extends Composer<_$PulseDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDuration => $composableBuilder(
    column: $table.estimatedDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDuration => $composableBuilder(
    column: $table.actualDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedCompletionTime => $composableBuilder(
    column: $table.expectedCompletionTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationNote => $composableBuilder(
    column: $table.explanationNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$PulseDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDuration => $composableBuilder(
    column: $table.estimatedDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDuration => $composableBuilder(
    column: $table.actualDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedCompletionTime => $composableBuilder(
    column: $table.expectedCompletionTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationNote => $composableBuilder(
    column: $table.explanationNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$PulseDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedDuration => $composableBuilder(
    column: $table.estimatedDuration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDuration => $composableBuilder(
    column: $table.actualDuration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedCompletionTime => $composableBuilder(
    column: $table.expectedCompletionTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationNote => $composableBuilder(
    column: $table.explanationNote,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$PulseDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$PulseDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$PulseDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dailyPlanId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> plannedFor = const Value.absent(),
                Value<int?> estimatedDuration = const Value.absent(),
                Value<int?> actualDuration = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> expectedCompletionTime = const Value.absent(),
                Value<String?> explanationNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                dailyPlanId: dailyPlanId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                createdAt: createdAt,
                completedAt: completedAt,
                plannedFor: plannedFor,
                estimatedDuration: estimatedDuration,
                actualDuration: actualDuration,
                source: source,
                expectedCompletionTime: expectedCompletionTime,
                explanationNote: explanationNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dailyPlanId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime plannedFor,
                Value<int?> estimatedDuration = const Value.absent(),
                Value<int?> actualDuration = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> expectedCompletionTime = const Value.absent(),
                Value<String?> explanationNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                dailyPlanId: dailyPlanId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                createdAt: createdAt,
                completedAt: completedAt,
                plannedFor: plannedFor,
                estimatedDuration: estimatedDuration,
                actualDuration: actualDuration,
                source: source,
                expectedCompletionTime: expectedCompletionTime,
                explanationNote: explanationNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$PulseDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$PulseDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$CheckInsTableCreateCompanionBuilder =
    CheckInsCompanion Function({
      required String id,
      required String dailyPlanId,
      Value<String?> taskId,
      required DateTime scheduledFor,
      Value<DateTime?> respondedAt,
      Value<String> status,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$CheckInsTableUpdateCompanionBuilder =
    CheckInsCompanion Function({
      Value<String> id,
      Value<String> dailyPlanId,
      Value<String?> taskId,
      Value<DateTime> scheduledFor,
      Value<DateTime?> respondedAt,
      Value<String> status,
      Value<String?> note,
      Value<int> rowid,
    });

class $$CheckInsTableFilterComposer
    extends Composer<_$PulseDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$PulseDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$PulseDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$PulseDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$PulseDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$PulseDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dailyPlanId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<DateTime> scheduledFor = const Value.absent(),
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                dailyPlanId: dailyPlanId,
                taskId: taskId,
                scheduledFor: scheduledFor,
                respondedAt: respondedAt,
                status: status,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dailyPlanId,
                Value<String?> taskId = const Value.absent(),
                required DateTime scheduledFor,
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion.insert(
                id: id,
                dailyPlanId: dailyPlanId,
                taskId: taskId,
                scheduledFor: scheduledFor,
                respondedAt: respondedAt,
                status: status,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$PulseDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$PulseDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$DailyReflectionsTableCreateCompanionBuilder =
    DailyReflectionsCompanion Function({
      required String id,
      required String dailyPlanId,
      required String mood,
      Value<String?> biggestWin,
      Value<String?> carryForward,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DailyReflectionsTableUpdateCompanionBuilder =
    DailyReflectionsCompanion Function({
      Value<String> id,
      Value<String> dailyPlanId,
      Value<String> mood,
      Value<String?> biggestWin,
      Value<String?> carryForward,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DailyReflectionsTableFilterComposer
    extends Composer<_$PulseDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biggestWin => $composableBuilder(
    column: $table.biggestWin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carryForward => $composableBuilder(
    column: $table.carryForward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReflectionsTableOrderingComposer
    extends Composer<_$PulseDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biggestWin => $composableBuilder(
    column: $table.biggestWin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carryForward => $composableBuilder(
    column: $table.carryForward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReflectionsTableAnnotationComposer
    extends Composer<_$PulseDatabase, $DailyReflectionsTable> {
  $$DailyReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get biggestWin => $composableBuilder(
    column: $table.biggestWin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carryForward => $composableBuilder(
    column: $table.carryForward,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyReflectionsTableTableManager
    extends
        RootTableManager<
          _$PulseDatabase,
          $DailyReflectionsTable,
          DailyReflection,
          $$DailyReflectionsTableFilterComposer,
          $$DailyReflectionsTableOrderingComposer,
          $$DailyReflectionsTableAnnotationComposer,
          $$DailyReflectionsTableCreateCompanionBuilder,
          $$DailyReflectionsTableUpdateCompanionBuilder,
          (
            DailyReflection,
            BaseReferences<
              _$PulseDatabase,
              $DailyReflectionsTable,
              DailyReflection
            >,
          ),
          DailyReflection,
          PrefetchHooks Function()
        > {
  $$DailyReflectionsTableTableManager(
    _$PulseDatabase db,
    $DailyReflectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dailyPlanId = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<String?> biggestWin = const Value.absent(),
                Value<String?> carryForward = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReflectionsCompanion(
                id: id,
                dailyPlanId: dailyPlanId,
                mood: mood,
                biggestWin: biggestWin,
                carryForward: carryForward,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dailyPlanId,
                required String mood,
                Value<String?> biggestWin = const Value.absent(),
                Value<String?> carryForward = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyReflectionsCompanion.insert(
                id: id,
                dailyPlanId: dailyPlanId,
                mood: mood,
                biggestWin: biggestWin,
                carryForward: carryForward,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PulseDatabase,
      $DailyReflectionsTable,
      DailyReflection,
      $$DailyReflectionsTableFilterComposer,
      $$DailyReflectionsTableOrderingComposer,
      $$DailyReflectionsTableAnnotationComposer,
      $$DailyReflectionsTableCreateCompanionBuilder,
      $$DailyReflectionsTableUpdateCompanionBuilder,
      (
        DailyReflection,
        BaseReferences<
          _$PulseDatabase,
          $DailyReflectionsTable,
          DailyReflection
        >,
      ),
      DailyReflection,
      PrefetchHooks Function()
    >;
typedef $$DailyReportsTableCreateCompanionBuilder =
    DailyReportsCompanion Function({
      required String id,
      required String dailyPlanId,
      required double completionRate,
      required DateTime generatedAt,
      Value<int> rowid,
    });
typedef $$DailyReportsTableUpdateCompanionBuilder =
    DailyReportsCompanion Function({
      Value<String> id,
      Value<String> dailyPlanId,
      Value<double> completionRate,
      Value<DateTime> generatedAt,
      Value<int> rowid,
    });

class $$DailyReportsTableFilterComposer
    extends Composer<_$PulseDatabase, $DailyReportsTable> {
  $$DailyReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReportsTableOrderingComposer
    extends Composer<_$PulseDatabase, $DailyReportsTable> {
  $$DailyReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReportsTableAnnotationComposer
    extends Composer<_$PulseDatabase, $DailyReportsTable> {
  $$DailyReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dailyPlanId => $composableBuilder(
    column: $table.dailyPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );
}

class $$DailyReportsTableTableManager
    extends
        RootTableManager<
          _$PulseDatabase,
          $DailyReportsTable,
          DailyReport,
          $$DailyReportsTableFilterComposer,
          $$DailyReportsTableOrderingComposer,
          $$DailyReportsTableAnnotationComposer,
          $$DailyReportsTableCreateCompanionBuilder,
          $$DailyReportsTableUpdateCompanionBuilder,
          (
            DailyReport,
            BaseReferences<_$PulseDatabase, $DailyReportsTable, DailyReport>,
          ),
          DailyReport,
          PrefetchHooks Function()
        > {
  $$DailyReportsTableTableManager(_$PulseDatabase db, $DailyReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dailyPlanId = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion(
                id: id,
                dailyPlanId: dailyPlanId,
                completionRate: completionRate,
                generatedAt: generatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dailyPlanId,
                required double completionRate,
                required DateTime generatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion.insert(
                id: id,
                dailyPlanId: dailyPlanId,
                completionRate: completionRate,
                generatedAt: generatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$PulseDatabase,
      $DailyReportsTable,
      DailyReport,
      $$DailyReportsTableFilterComposer,
      $$DailyReportsTableOrderingComposer,
      $$DailyReportsTableAnnotationComposer,
      $$DailyReportsTableCreateCompanionBuilder,
      $$DailyReportsTableUpdateCompanionBuilder,
      (
        DailyReport,
        BaseReferences<_$PulseDatabase, $DailyReportsTable, DailyReport>,
      ),
      DailyReport,
      PrefetchHooks Function()
    >;

class $PulseDatabaseManager {
  final _$PulseDatabase _db;
  $PulseDatabaseManager(this._db);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db, _db.dailyPlans);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$DailyReflectionsTableTableManager get dailyReflections =>
      $$DailyReflectionsTableTableManager(_db, _db.dailyReflections);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db, _db.dailyReports);
}
