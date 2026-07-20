// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vueniverse_database.dart';

// ignore_for_file: type=lint
class $StoreMetadataTable extends StoreMetadata
    with TableInfo<$StoreMetadataTable, StoreMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StoreMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreMetadataRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoreMetadataTable createAlias(String alias) {
    return $StoreMetadataTable(attachedDatabase, alias);
  }
}

class StoreMetadataRow extends DataClass
    implements Insertable<StoreMetadataRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const StoreMetadataRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoreMetadataCompanion toCompanion(bool nullToAbsent) {
    return StoreMetadataCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoreMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreMetadataRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoreMetadataRow copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => StoreMetadataRow(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoreMetadataRow copyWithCompanion(StoreMetadataCompanion data) {
    return StoreMetadataRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreMetadataRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreMetadataRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class StoreMetadataCompanion extends UpdateCompanion<StoreMetadataRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoreMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreMetadataCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<StoreMetadataRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoreMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceConnectionsTable extends SourceConnections
    with TableInfo<$SourceConnectionsTable, SourceConnectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configurationJsonMeta = const VerificationMeta(
    'configurationJson',
  );
  @override
  late final GeneratedColumn<String> configurationJson =
      GeneratedColumn<String>(
        'configuration_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    status,
    configurationJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceConnectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('configuration_json')) {
      context.handle(
        _configurationJsonMeta,
        configurationJson.isAcceptableOrUnknown(
          data['configuration_json']!,
          _configurationJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceConnectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceConnectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      configurationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SourceConnectionsTable createAlias(String alias) {
    return $SourceConnectionsTable(attachedDatabase, alias);
  }
}

class SourceConnectionRow extends DataClass
    implements Insertable<SourceConnectionRow> {
  final String id;
  final String sourceType;
  final String status;
  final String configurationJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SourceConnectionRow({
    required this.id,
    required this.sourceType,
    required this.status,
    required this.configurationJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['status'] = Variable<String>(status);
    map['configuration_json'] = Variable<String>(configurationJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SourceConnectionsCompanion toCompanion(bool nullToAbsent) {
    return SourceConnectionsCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      status: Value(status),
      configurationJson: Value(configurationJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourceConnectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceConnectionRow(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      status: serializer.fromJson<String>(json['status']),
      configurationJson: serializer.fromJson<String>(json['configurationJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'status': serializer.toJson<String>(status),
      'configurationJson': serializer.toJson<String>(configurationJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SourceConnectionRow copyWith({
    String? id,
    String? sourceType,
    String? status,
    String? configurationJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SourceConnectionRow(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    status: status ?? this.status,
    configurationJson: configurationJson ?? this.configurationJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SourceConnectionRow copyWithCompanion(SourceConnectionsCompanion data) {
    return SourceConnectionRow(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      status: data.status.present ? data.status.value : this.status,
      configurationJson: data.configurationJson.present
          ? data.configurationJson.value
          : this.configurationJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceConnectionRow(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    status,
    configurationJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceConnectionRow &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.status == this.status &&
          other.configurationJson == this.configurationJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SourceConnectionsCompanion extends UpdateCompanion<SourceConnectionRow> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> status;
  final Value<String> configurationJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SourceConnectionsCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.status = const Value.absent(),
    this.configurationJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceConnectionsCompanion.insert({
    required String id,
    required String sourceType,
    required String status,
    this.configurationJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       status = Value(status);
  static Insertable<SourceConnectionRow> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? status,
    Expression<String>? configurationJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (status != null) 'status': status,
      if (configurationJson != null) 'configuration_json': configurationJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceConnectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? status,
    Value<String>? configurationJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SourceConnectionsCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      configurationJson: configurationJson ?? this.configurationJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (configurationJson.present) {
      map['configuration_json'] = Variable<String>(configurationJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcePermissionsTable extends SourcePermissions
    with TableInfo<$SourcePermissionsTable, SourcePermissionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcePermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceConnectionIdMeta =
      const VerificationMeta('sourceConnectionId');
  @override
  late final GeneratedColumn<String> sourceConnectionId =
      GeneratedColumn<String>(
        'source_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES source_connections (id)',
        ),
      );
  static const VerificationMeta _recordTypeMeta = const VerificationMeta(
    'recordType',
  );
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
    'record_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceConnectionId,
    recordType,
    status,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourcePermissionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_connection_id')) {
      context.handle(
        _sourceConnectionIdMeta,
        sourceConnectionId.isAcceptableOrUnknown(
          data['source_connection_id']!,
          _sourceConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceConnectionIdMeta);
    }
    if (data.containsKey('record_type')) {
      context.handle(
        _recordTypeMeta,
        recordType.isAcceptableOrUnknown(data['record_type']!, _recordTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourcePermissionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourcePermissionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_connection_id'],
      )!,
      recordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SourcePermissionsTable createAlias(String alias) {
    return $SourcePermissionsTable(attachedDatabase, alias);
  }
}

class SourcePermissionRow extends DataClass
    implements Insertable<SourcePermissionRow> {
  final String id;
  final String sourceConnectionId;
  final String recordType;
  final String status;
  final DateTime updatedAt;
  const SourcePermissionRow({
    required this.id,
    required this.sourceConnectionId,
    required this.recordType,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_connection_id'] = Variable<String>(sourceConnectionId);
    map['record_type'] = Variable<String>(recordType);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SourcePermissionsCompanion toCompanion(bool nullToAbsent) {
    return SourcePermissionsCompanion(
      id: Value(id),
      sourceConnectionId: Value(sourceConnectionId),
      recordType: Value(recordType),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourcePermissionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourcePermissionRow(
      id: serializer.fromJson<String>(json['id']),
      sourceConnectionId: serializer.fromJson<String>(
        json['sourceConnectionId'],
      ),
      recordType: serializer.fromJson<String>(json['recordType']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceConnectionId': serializer.toJson<String>(sourceConnectionId),
      'recordType': serializer.toJson<String>(recordType),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SourcePermissionRow copyWith({
    String? id,
    String? sourceConnectionId,
    String? recordType,
    String? status,
    DateTime? updatedAt,
  }) => SourcePermissionRow(
    id: id ?? this.id,
    sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
    recordType: recordType ?? this.recordType,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SourcePermissionRow copyWithCompanion(SourcePermissionsCompanion data) {
    return SourcePermissionRow(
      id: data.id.present ? data.id.value : this.id,
      sourceConnectionId: data.sourceConnectionId.present
          ? data.sourceConnectionId.value
          : this.sourceConnectionId,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourcePermissionRow(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('recordType: $recordType, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceConnectionId, recordType, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourcePermissionRow &&
          other.id == this.id &&
          other.sourceConnectionId == this.sourceConnectionId &&
          other.recordType == this.recordType &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class SourcePermissionsCompanion extends UpdateCompanion<SourcePermissionRow> {
  final Value<String> id;
  final Value<String> sourceConnectionId;
  final Value<String> recordType;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SourcePermissionsCompanion({
    this.id = const Value.absent(),
    this.sourceConnectionId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcePermissionsCompanion.insert({
    required String id,
    required String sourceConnectionId,
    required String recordType,
    required String status,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceConnectionId = Value(sourceConnectionId),
       recordType = Value(recordType),
       status = Value(status);
  static Insertable<SourcePermissionRow> custom({
    Expression<String>? id,
    Expression<String>? sourceConnectionId,
    Expression<String>? recordType,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceConnectionId != null)
        'source_connection_id': sourceConnectionId,
      if (recordType != null) 'record_type': recordType,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcePermissionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceConnectionId,
    Value<String>? recordType,
    Value<String>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SourcePermissionsCompanion(
      id: id ?? this.id,
      sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
      recordType: recordType ?? this.recordType,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceConnectionId.present) {
      map['source_connection_id'] = Variable<String>(sourceConnectionId.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcePermissionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('recordType: $recordType, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRunsTable extends SyncRuns
    with TableInfo<$SyncRunsTable, SyncRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceConnectionIdMeta =
      const VerificationMeta('sourceConnectionId');
  @override
  late final GeneratedColumn<String> sourceConnectionId =
      GeneratedColumn<String>(
        'source_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES source_connections (id)',
        ),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordsSeenMeta = const VerificationMeta(
    'recordsSeen',
  );
  @override
  late final GeneratedColumn<int> recordsSeen = GeneratedColumn<int>(
    'records_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recordsAcceptedMeta = const VerificationMeta(
    'recordsAccepted',
  );
  @override
  late final GeneratedColumn<int> recordsAccepted = GeneratedColumn<int>(
    'records_accepted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recordsRejectedMeta = const VerificationMeta(
    'recordsRejected',
  );
  @override
  late final GeneratedColumn<int> recordsRejected = GeneratedColumn<int>(
    'records_rejected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorDetailsMeta = const VerificationMeta(
    'errorDetails',
  );
  @override
  late final GeneratedColumn<String> errorDetails = GeneratedColumn<String>(
    'error_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceConnectionId,
    status,
    startedAt,
    finishedAt,
    recordsSeen,
    recordsAccepted,
    recordsRejected,
    errorCode,
    errorDetails,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_connection_id')) {
      context.handle(
        _sourceConnectionIdMeta,
        sourceConnectionId.isAcceptableOrUnknown(
          data['source_connection_id']!,
          _sourceConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceConnectionIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('records_seen')) {
      context.handle(
        _recordsSeenMeta,
        recordsSeen.isAcceptableOrUnknown(
          data['records_seen']!,
          _recordsSeenMeta,
        ),
      );
    }
    if (data.containsKey('records_accepted')) {
      context.handle(
        _recordsAcceptedMeta,
        recordsAccepted.isAcceptableOrUnknown(
          data['records_accepted']!,
          _recordsAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('records_rejected')) {
      context.handle(
        _recordsRejectedMeta,
        recordsRejected.isAcceptableOrUnknown(
          data['records_rejected']!,
          _recordsRejectedMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_details')) {
      context.handle(
        _errorDetailsMeta,
        errorDetails.isAcceptableOrUnknown(
          data['error_details']!,
          _errorDetailsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_connection_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      recordsSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_seen'],
      )!,
      recordsAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_accepted'],
      )!,
      recordsRejected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_rejected'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_details'],
      ),
    );
  }

  @override
  $SyncRunsTable createAlias(String alias) {
    return $SyncRunsTable(attachedDatabase, alias);
  }
}

class SyncRunRow extends DataClass implements Insertable<SyncRunRow> {
  final String id;
  final String sourceConnectionId;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int recordsSeen;
  final int recordsAccepted;
  final int recordsRejected;
  final String? errorCode;
  final String? errorDetails;
  const SyncRunRow({
    required this.id,
    required this.sourceConnectionId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    required this.recordsSeen,
    required this.recordsAccepted,
    required this.recordsRejected,
    this.errorCode,
    this.errorDetails,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_connection_id'] = Variable<String>(sourceConnectionId);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['records_seen'] = Variable<int>(recordsSeen);
    map['records_accepted'] = Variable<int>(recordsAccepted);
    map['records_rejected'] = Variable<int>(recordsRejected);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorDetails != null) {
      map['error_details'] = Variable<String>(errorDetails);
    }
    return map;
  }

  SyncRunsCompanion toCompanion(bool nullToAbsent) {
    return SyncRunsCompanion(
      id: Value(id),
      sourceConnectionId: Value(sourceConnectionId),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      recordsSeen: Value(recordsSeen),
      recordsAccepted: Value(recordsAccepted),
      recordsRejected: Value(recordsRejected),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorDetails: errorDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(errorDetails),
    );
  }

  factory SyncRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRunRow(
      id: serializer.fromJson<String>(json['id']),
      sourceConnectionId: serializer.fromJson<String>(
        json['sourceConnectionId'],
      ),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      recordsSeen: serializer.fromJson<int>(json['recordsSeen']),
      recordsAccepted: serializer.fromJson<int>(json['recordsAccepted']),
      recordsRejected: serializer.fromJson<int>(json['recordsRejected']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorDetails: serializer.fromJson<String?>(json['errorDetails']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceConnectionId': serializer.toJson<String>(sourceConnectionId),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'recordsSeen': serializer.toJson<int>(recordsSeen),
      'recordsAccepted': serializer.toJson<int>(recordsAccepted),
      'recordsRejected': serializer.toJson<int>(recordsRejected),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorDetails': serializer.toJson<String?>(errorDetails),
    };
  }

  SyncRunRow copyWith({
    String? id,
    String? sourceConnectionId,
    String? status,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    int? recordsSeen,
    int? recordsAccepted,
    int? recordsRejected,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorDetails = const Value.absent(),
  }) => SyncRunRow(
    id: id ?? this.id,
    sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    recordsSeen: recordsSeen ?? this.recordsSeen,
    recordsAccepted: recordsAccepted ?? this.recordsAccepted,
    recordsRejected: recordsRejected ?? this.recordsRejected,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorDetails: errorDetails.present ? errorDetails.value : this.errorDetails,
  );
  SyncRunRow copyWithCompanion(SyncRunsCompanion data) {
    return SyncRunRow(
      id: data.id.present ? data.id.value : this.id,
      sourceConnectionId: data.sourceConnectionId.present
          ? data.sourceConnectionId.value
          : this.sourceConnectionId,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      recordsSeen: data.recordsSeen.present
          ? data.recordsSeen.value
          : this.recordsSeen,
      recordsAccepted: data.recordsAccepted.present
          ? data.recordsAccepted.value
          : this.recordsAccepted,
      recordsRejected: data.recordsRejected.present
          ? data.recordsRejected.value
          : this.recordsRejected,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorDetails: data.errorDetails.present
          ? data.errorDetails.value
          : this.errorDetails,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunRow(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('recordsSeen: $recordsSeen, ')
          ..write('recordsAccepted: $recordsAccepted, ')
          ..write('recordsRejected: $recordsRejected, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetails: $errorDetails')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceConnectionId,
    status,
    startedAt,
    finishedAt,
    recordsSeen,
    recordsAccepted,
    recordsRejected,
    errorCode,
    errorDetails,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRunRow &&
          other.id == this.id &&
          other.sourceConnectionId == this.sourceConnectionId &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.recordsSeen == this.recordsSeen &&
          other.recordsAccepted == this.recordsAccepted &&
          other.recordsRejected == this.recordsRejected &&
          other.errorCode == this.errorCode &&
          other.errorDetails == this.errorDetails);
}

class SyncRunsCompanion extends UpdateCompanion<SyncRunRow> {
  final Value<String> id;
  final Value<String> sourceConnectionId;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> recordsSeen;
  final Value<int> recordsAccepted;
  final Value<int> recordsRejected;
  final Value<String?> errorCode;
  final Value<String?> errorDetails;
  final Value<int> rowid;
  const SyncRunsCompanion({
    this.id = const Value.absent(),
    this.sourceConnectionId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.recordsSeen = const Value.absent(),
    this.recordsAccepted = const Value.absent(),
    this.recordsRejected = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetails = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRunsCompanion.insert({
    required String id,
    required String sourceConnectionId,
    required String status,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.recordsSeen = const Value.absent(),
    this.recordsAccepted = const Value.absent(),
    this.recordsRejected = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorDetails = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceConnectionId = Value(sourceConnectionId),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<SyncRunRow> custom({
    Expression<String>? id,
    Expression<String>? sourceConnectionId,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? recordsSeen,
    Expression<int>? recordsAccepted,
    Expression<int>? recordsRejected,
    Expression<String>? errorCode,
    Expression<String>? errorDetails,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceConnectionId != null)
        'source_connection_id': sourceConnectionId,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (recordsSeen != null) 'records_seen': recordsSeen,
      if (recordsAccepted != null) 'records_accepted': recordsAccepted,
      if (recordsRejected != null) 'records_rejected': recordsRejected,
      if (errorCode != null) 'error_code': errorCode,
      if (errorDetails != null) 'error_details': errorDetails,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceConnectionId,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? recordsSeen,
    Value<int>? recordsAccepted,
    Value<int>? recordsRejected,
    Value<String?>? errorCode,
    Value<String?>? errorDetails,
    Value<int>? rowid,
  }) {
    return SyncRunsCompanion(
      id: id ?? this.id,
      sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      recordsSeen: recordsSeen ?? this.recordsSeen,
      recordsAccepted: recordsAccepted ?? this.recordsAccepted,
      recordsRejected: recordsRejected ?? this.recordsRejected,
      errorCode: errorCode ?? this.errorCode,
      errorDetails: errorDetails ?? this.errorDetails,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceConnectionId.present) {
      map['source_connection_id'] = Variable<String>(sourceConnectionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (recordsSeen.present) {
      map['records_seen'] = Variable<int>(recordsSeen.value);
    }
    if (recordsAccepted.present) {
      map['records_accepted'] = Variable<int>(recordsAccepted.value);
    }
    if (recordsRejected.present) {
      map['records_rejected'] = Variable<int>(recordsRejected.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorDetails.present) {
      map['error_details'] = Variable<String>(errorDetails.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunsCompanion(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('recordsSeen: $recordsSeen, ')
          ..write('recordsAccepted: $recordsAccepted, ')
          ..write('recordsRejected: $recordsRejected, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorDetails: $errorDetails, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceConnectionIdMeta =
      const VerificationMeta('sourceConnectionId');
  @override
  late final GeneratedColumn<String> sourceConnectionId =
      GeneratedColumn<String>(
        'source_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES source_connections (id)',
        ),
      );
  static const VerificationMeta _recordTypeMeta = const VerificationMeta(
    'recordType',
  );
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
    'record_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceConnectionId,
    recordType,
    cursor,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_connection_id')) {
      context.handle(
        _sourceConnectionIdMeta,
        sourceConnectionId.isAcceptableOrUnknown(
          data['source_connection_id']!,
          _sourceConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceConnectionIdMeta);
    }
    if (data.containsKey('record_type')) {
      context.handle(
        _recordTypeMeta,
        recordType.isAcceptableOrUnknown(data['record_type']!, _recordTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_connection_id'],
      )!,
      recordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_type'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String id;
  final String sourceConnectionId;
  final String recordType;
  final String cursor;
  final DateTime updatedAt;
  const SyncCursorRow({
    required this.id,
    required this.sourceConnectionId,
    required this.recordType,
    required this.cursor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_connection_id'] = Variable<String>(sourceConnectionId);
    map['record_type'] = Variable<String>(recordType);
    map['cursor'] = Variable<String>(cursor);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      id: Value(id),
      sourceConnectionId: Value(sourceConnectionId),
      recordType: Value(recordType),
      cursor: Value(cursor),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      id: serializer.fromJson<String>(json['id']),
      sourceConnectionId: serializer.fromJson<String>(
        json['sourceConnectionId'],
      ),
      recordType: serializer.fromJson<String>(json['recordType']),
      cursor: serializer.fromJson<String>(json['cursor']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceConnectionId': serializer.toJson<String>(sourceConnectionId),
      'recordType': serializer.toJson<String>(recordType),
      'cursor': serializer.toJson<String>(cursor),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncCursorRow copyWith({
    String? id,
    String? sourceConnectionId,
    String? recordType,
    String? cursor,
    DateTime? updatedAt,
  }) => SyncCursorRow(
    id: id ?? this.id,
    sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
    recordType: recordType ?? this.recordType,
    cursor: cursor ?? this.cursor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      id: data.id.present ? data.id.value : this.id,
      sourceConnectionId: data.sourceConnectionId.present
          ? data.sourceConnectionId.value
          : this.sourceConnectionId,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('recordType: $recordType, ')
          ..write('cursor: $cursor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceConnectionId, recordType, cursor, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.id == this.id &&
          other.sourceConnectionId == this.sourceConnectionId &&
          other.recordType == this.recordType &&
          other.cursor == this.cursor &&
          other.updatedAt == this.updatedAt);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> id;
  final Value<String> sourceConnectionId;
  final Value<String> recordType;
  final Value<String> cursor;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.id = const Value.absent(),
    this.sourceConnectionId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.cursor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String id,
    required String sourceConnectionId,
    required String recordType,
    required String cursor,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceConnectionId = Value(sourceConnectionId),
       recordType = Value(recordType),
       cursor = Value(cursor);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? id,
    Expression<String>? sourceConnectionId,
    Expression<String>? recordType,
    Expression<String>? cursor,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceConnectionId != null)
        'source_connection_id': sourceConnectionId,
      if (recordType != null) 'record_type': recordType,
      if (cursor != null) 'cursor': cursor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceConnectionId,
    Value<String>? recordType,
    Value<String>? cursor,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      id: id ?? this.id,
      sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
      recordType: recordType ?? this.recordType,
      cursor: cursor ?? this.cursor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceConnectionId.present) {
      map['source_connection_id'] = Variable<String>(sourceConnectionId.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('recordType: $recordType, ')
          ..write('cursor: $cursor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncSeenRecordsTable extends SyncSeenRecords
    with TableInfo<$SyncSeenRecordsTable, SyncSeenRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSeenRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncRunIdMeta = const VerificationMeta(
    'syncRunId',
  );
  @override
  late final GeneratedColumn<String> syncRunId = GeneratedColumn<String>(
    'sync_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sync_runs (id)',
    ),
  );
  static const VerificationMeta _sourceRecordHmacMeta = const VerificationMeta(
    'sourceRecordHmac',
  );
  @override
  late final GeneratedColumn<String> sourceRecordHmac = GeneratedColumn<String>(
    'source_record_hmac',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncRunId,
    sourceRecordHmac,
    seenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_seen_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSeenRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_run_id')) {
      context.handle(
        _syncRunIdMeta,
        syncRunId.isAcceptableOrUnknown(data['sync_run_id']!, _syncRunIdMeta),
      );
    } else if (isInserting) {
      context.missing(_syncRunIdMeta);
    }
    if (data.containsKey('source_record_hmac')) {
      context.handle(
        _sourceRecordHmacMeta,
        sourceRecordHmac.isAcceptableOrUnknown(
          data['source_record_hmac']!,
          _sourceRecordHmacMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRecordHmacMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncSeenRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSeenRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_run_id'],
      )!,
      sourceRecordHmac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_record_hmac'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_at'],
      )!,
    );
  }

  @override
  $SyncSeenRecordsTable createAlias(String alias) {
    return $SyncSeenRecordsTable(attachedDatabase, alias);
  }
}

class SyncSeenRecordRow extends DataClass
    implements Insertable<SyncSeenRecordRow> {
  final String id;
  final String syncRunId;
  final String sourceRecordHmac;
  final DateTime seenAt;
  const SyncSeenRecordRow({
    required this.id,
    required this.syncRunId,
    required this.sourceRecordHmac,
    required this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_run_id'] = Variable<String>(syncRunId);
    map['source_record_hmac'] = Variable<String>(sourceRecordHmac);
    map['seen_at'] = Variable<DateTime>(seenAt);
    return map;
  }

  SyncSeenRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncSeenRecordsCompanion(
      id: Value(id),
      syncRunId: Value(syncRunId),
      sourceRecordHmac: Value(sourceRecordHmac),
      seenAt: Value(seenAt),
    );
  }

  factory SyncSeenRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSeenRecordRow(
      id: serializer.fromJson<String>(json['id']),
      syncRunId: serializer.fromJson<String>(json['syncRunId']),
      sourceRecordHmac: serializer.fromJson<String>(json['sourceRecordHmac']),
      seenAt: serializer.fromJson<DateTime>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncRunId': serializer.toJson<String>(syncRunId),
      'sourceRecordHmac': serializer.toJson<String>(sourceRecordHmac),
      'seenAt': serializer.toJson<DateTime>(seenAt),
    };
  }

  SyncSeenRecordRow copyWith({
    String? id,
    String? syncRunId,
    String? sourceRecordHmac,
    DateTime? seenAt,
  }) => SyncSeenRecordRow(
    id: id ?? this.id,
    syncRunId: syncRunId ?? this.syncRunId,
    sourceRecordHmac: sourceRecordHmac ?? this.sourceRecordHmac,
    seenAt: seenAt ?? this.seenAt,
  );
  SyncSeenRecordRow copyWithCompanion(SyncSeenRecordsCompanion data) {
    return SyncSeenRecordRow(
      id: data.id.present ? data.id.value : this.id,
      syncRunId: data.syncRunId.present ? data.syncRunId.value : this.syncRunId,
      sourceRecordHmac: data.sourceRecordHmac.present
          ? data.sourceRecordHmac.value
          : this.sourceRecordHmac,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSeenRecordRow(')
          ..write('id: $id, ')
          ..write('syncRunId: $syncRunId, ')
          ..write('sourceRecordHmac: $sourceRecordHmac, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, syncRunId, sourceRecordHmac, seenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSeenRecordRow &&
          other.id == this.id &&
          other.syncRunId == this.syncRunId &&
          other.sourceRecordHmac == this.sourceRecordHmac &&
          other.seenAt == this.seenAt);
}

class SyncSeenRecordsCompanion extends UpdateCompanion<SyncSeenRecordRow> {
  final Value<String> id;
  final Value<String> syncRunId;
  final Value<String> sourceRecordHmac;
  final Value<DateTime> seenAt;
  final Value<int> rowid;
  const SyncSeenRecordsCompanion({
    this.id = const Value.absent(),
    this.syncRunId = const Value.absent(),
    this.sourceRecordHmac = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncSeenRecordsCompanion.insert({
    required String id,
    required String syncRunId,
    required String sourceRecordHmac,
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       syncRunId = Value(syncRunId),
       sourceRecordHmac = Value(sourceRecordHmac);
  static Insertable<SyncSeenRecordRow> custom({
    Expression<String>? id,
    Expression<String>? syncRunId,
    Expression<String>? sourceRecordHmac,
    Expression<DateTime>? seenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncRunId != null) 'sync_run_id': syncRunId,
      if (sourceRecordHmac != null) 'source_record_hmac': sourceRecordHmac,
      if (seenAt != null) 'seen_at': seenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncSeenRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? syncRunId,
    Value<String>? sourceRecordHmac,
    Value<DateTime>? seenAt,
    Value<int>? rowid,
  }) {
    return SyncSeenRecordsCompanion(
      id: id ?? this.id,
      syncRunId: syncRunId ?? this.syncRunId,
      sourceRecordHmac: sourceRecordHmac ?? this.sourceRecordHmac,
      seenAt: seenAt ?? this.seenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncRunId.present) {
      map['sync_run_id'] = Variable<String>(syncRunId.value);
    }
    if (sourceRecordHmac.present) {
      map['source_record_hmac'] = Variable<String>(sourceRecordHmac.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSeenRecordsCompanion(')
          ..write('id: $id, ')
          ..write('syncRunId: $syncRunId, ')
          ..write('sourceRecordHmac: $sourceRecordHmac, ')
          ..write('seenAt: $seenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RawRecordIndexTable extends RawRecordIndex
    with TableInfo<$RawRecordIndexTable, RawRecordIndexRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawRecordIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceConnectionIdMeta =
      const VerificationMeta('sourceConnectionId');
  @override
  late final GeneratedColumn<String> sourceConnectionId =
      GeneratedColumn<String>(
        'source_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES source_connections (id)',
        ),
      );
  static const VerificationMeta _sourceKindMeta = const VerificationMeta(
    'sourceKind',
  );
  @override
  late final GeneratedColumn<String> sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRecordHmacMeta = const VerificationMeta(
    'sourceRecordHmac',
  );
  @override
  late final GeneratedColumn<String> sourceRecordHmac = GeneratedColumn<String>(
    'source_record_hmac',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canonicalPayloadHashMeta =
      const VerificationMeta('canonicalPayloadHash');
  @override
  late final GeneratedColumn<String> canonicalPayloadHash =
      GeneratedColumn<String>(
        'canonical_payload_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _canonicalKindMeta = const VerificationMeta(
    'canonicalKind',
  );
  @override
  late final GeneratedColumn<String> canonicalKind = GeneratedColumn<String>(
    'canonical_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalIdMeta = const VerificationMeta(
    'canonicalId',
  );
  @override
  late final GeneratedColumn<String> canonicalId = GeneratedColumn<String>(
    'canonical_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceConnectionId,
    sourceKind,
    sourceRecordHmac,
    canonicalPayloadHash,
    canonicalKind,
    canonicalId,
    occurredAtUtc,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_record_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawRecordIndexRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_connection_id')) {
      context.handle(
        _sourceConnectionIdMeta,
        sourceConnectionId.isAcceptableOrUnknown(
          data['source_connection_id']!,
          _sourceConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceConnectionIdMeta);
    }
    if (data.containsKey('source_kind')) {
      context.handle(
        _sourceKindMeta,
        sourceKind.isAcceptableOrUnknown(data['source_kind']!, _sourceKindMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKindMeta);
    }
    if (data.containsKey('source_record_hmac')) {
      context.handle(
        _sourceRecordHmacMeta,
        sourceRecordHmac.isAcceptableOrUnknown(
          data['source_record_hmac']!,
          _sourceRecordHmacMeta,
        ),
      );
    }
    if (data.containsKey('canonical_payload_hash')) {
      context.handle(
        _canonicalPayloadHashMeta,
        canonicalPayloadHash.isAcceptableOrUnknown(
          data['canonical_payload_hash']!,
          _canonicalPayloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadHashMeta);
    }
    if (data.containsKey('canonical_kind')) {
      context.handle(
        _canonicalKindMeta,
        canonicalKind.isAcceptableOrUnknown(
          data['canonical_kind']!,
          _canonicalKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalKindMeta);
    }
    if (data.containsKey('canonical_id')) {
      context.handle(
        _canonicalIdMeta,
        canonicalId.isAcceptableOrUnknown(
          data['canonical_id']!,
          _canonicalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalIdMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawRecordIndexRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawRecordIndexRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_connection_id'],
      )!,
      sourceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_kind'],
      )!,
      sourceRecordHmac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_record_hmac'],
      ),
      canonicalPayloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_hash'],
      )!,
      canonicalKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_kind'],
      )!,
      canonicalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_id'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RawRecordIndexTable createAlias(String alias) {
    return $RawRecordIndexTable(attachedDatabase, alias);
  }
}

class RawRecordIndexRow extends DataClass
    implements Insertable<RawRecordIndexRow> {
  final String id;
  final String sourceConnectionId;
  final String sourceKind;
  final String? sourceRecordHmac;
  final String canonicalPayloadHash;
  final String canonicalKind;
  final String canonicalId;
  final DateTime occurredAtUtc;
  final DateTime updatedAt;
  const RawRecordIndexRow({
    required this.id,
    required this.sourceConnectionId,
    required this.sourceKind,
    this.sourceRecordHmac,
    required this.canonicalPayloadHash,
    required this.canonicalKind,
    required this.canonicalId,
    required this.occurredAtUtc,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_connection_id'] = Variable<String>(sourceConnectionId);
    map['source_kind'] = Variable<String>(sourceKind);
    if (!nullToAbsent || sourceRecordHmac != null) {
      map['source_record_hmac'] = Variable<String>(sourceRecordHmac);
    }
    map['canonical_payload_hash'] = Variable<String>(canonicalPayloadHash);
    map['canonical_kind'] = Variable<String>(canonicalKind);
    map['canonical_id'] = Variable<String>(canonicalId);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RawRecordIndexCompanion toCompanion(bool nullToAbsent) {
    return RawRecordIndexCompanion(
      id: Value(id),
      sourceConnectionId: Value(sourceConnectionId),
      sourceKind: Value(sourceKind),
      sourceRecordHmac: sourceRecordHmac == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRecordHmac),
      canonicalPayloadHash: Value(canonicalPayloadHash),
      canonicalKind: Value(canonicalKind),
      canonicalId: Value(canonicalId),
      occurredAtUtc: Value(occurredAtUtc),
      updatedAt: Value(updatedAt),
    );
  }

  factory RawRecordIndexRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawRecordIndexRow(
      id: serializer.fromJson<String>(json['id']),
      sourceConnectionId: serializer.fromJson<String>(
        json['sourceConnectionId'],
      ),
      sourceKind: serializer.fromJson<String>(json['sourceKind']),
      sourceRecordHmac: serializer.fromJson<String?>(json['sourceRecordHmac']),
      canonicalPayloadHash: serializer.fromJson<String>(
        json['canonicalPayloadHash'],
      ),
      canonicalKind: serializer.fromJson<String>(json['canonicalKind']),
      canonicalId: serializer.fromJson<String>(json['canonicalId']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceConnectionId': serializer.toJson<String>(sourceConnectionId),
      'sourceKind': serializer.toJson<String>(sourceKind),
      'sourceRecordHmac': serializer.toJson<String?>(sourceRecordHmac),
      'canonicalPayloadHash': serializer.toJson<String>(canonicalPayloadHash),
      'canonicalKind': serializer.toJson<String>(canonicalKind),
      'canonicalId': serializer.toJson<String>(canonicalId),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RawRecordIndexRow copyWith({
    String? id,
    String? sourceConnectionId,
    String? sourceKind,
    Value<String?> sourceRecordHmac = const Value.absent(),
    String? canonicalPayloadHash,
    String? canonicalKind,
    String? canonicalId,
    DateTime? occurredAtUtc,
    DateTime? updatedAt,
  }) => RawRecordIndexRow(
    id: id ?? this.id,
    sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
    sourceKind: sourceKind ?? this.sourceKind,
    sourceRecordHmac: sourceRecordHmac.present
        ? sourceRecordHmac.value
        : this.sourceRecordHmac,
    canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
    canonicalKind: canonicalKind ?? this.canonicalKind,
    canonicalId: canonicalId ?? this.canonicalId,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RawRecordIndexRow copyWithCompanion(RawRecordIndexCompanion data) {
    return RawRecordIndexRow(
      id: data.id.present ? data.id.value : this.id,
      sourceConnectionId: data.sourceConnectionId.present
          ? data.sourceConnectionId.value
          : this.sourceConnectionId,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      sourceRecordHmac: data.sourceRecordHmac.present
          ? data.sourceRecordHmac.value
          : this.sourceRecordHmac,
      canonicalPayloadHash: data.canonicalPayloadHash.present
          ? data.canonicalPayloadHash.value
          : this.canonicalPayloadHash,
      canonicalKind: data.canonicalKind.present
          ? data.canonicalKind.value
          : this.canonicalKind,
      canonicalId: data.canonicalId.present
          ? data.canonicalId.value
          : this.canonicalId,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawRecordIndexRow(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceRecordHmac: $sourceRecordHmac, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('canonicalKind: $canonicalKind, ')
          ..write('canonicalId: $canonicalId, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceConnectionId,
    sourceKind,
    sourceRecordHmac,
    canonicalPayloadHash,
    canonicalKind,
    canonicalId,
    occurredAtUtc,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawRecordIndexRow &&
          other.id == this.id &&
          other.sourceConnectionId == this.sourceConnectionId &&
          other.sourceKind == this.sourceKind &&
          other.sourceRecordHmac == this.sourceRecordHmac &&
          other.canonicalPayloadHash == this.canonicalPayloadHash &&
          other.canonicalKind == this.canonicalKind &&
          other.canonicalId == this.canonicalId &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.updatedAt == this.updatedAt);
}

class RawRecordIndexCompanion extends UpdateCompanion<RawRecordIndexRow> {
  final Value<String> id;
  final Value<String> sourceConnectionId;
  final Value<String> sourceKind;
  final Value<String?> sourceRecordHmac;
  final Value<String> canonicalPayloadHash;
  final Value<String> canonicalKind;
  final Value<String> canonicalId;
  final Value<DateTime> occurredAtUtc;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RawRecordIndexCompanion({
    this.id = const Value.absent(),
    this.sourceConnectionId = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.sourceRecordHmac = const Value.absent(),
    this.canonicalPayloadHash = const Value.absent(),
    this.canonicalKind = const Value.absent(),
    this.canonicalId = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawRecordIndexCompanion.insert({
    required String id,
    required String sourceConnectionId,
    required String sourceKind,
    this.sourceRecordHmac = const Value.absent(),
    required String canonicalPayloadHash,
    required String canonicalKind,
    required String canonicalId,
    required DateTime occurredAtUtc,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceConnectionId = Value(sourceConnectionId),
       sourceKind = Value(sourceKind),
       canonicalPayloadHash = Value(canonicalPayloadHash),
       canonicalKind = Value(canonicalKind),
       canonicalId = Value(canonicalId),
       occurredAtUtc = Value(occurredAtUtc);
  static Insertable<RawRecordIndexRow> custom({
    Expression<String>? id,
    Expression<String>? sourceConnectionId,
    Expression<String>? sourceKind,
    Expression<String>? sourceRecordHmac,
    Expression<String>? canonicalPayloadHash,
    Expression<String>? canonicalKind,
    Expression<String>? canonicalId,
    Expression<DateTime>? occurredAtUtc,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceConnectionId != null)
        'source_connection_id': sourceConnectionId,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (sourceRecordHmac != null) 'source_record_hmac': sourceRecordHmac,
      if (canonicalPayloadHash != null)
        'canonical_payload_hash': canonicalPayloadHash,
      if (canonicalKind != null) 'canonical_kind': canonicalKind,
      if (canonicalId != null) 'canonical_id': canonicalId,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawRecordIndexCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceConnectionId,
    Value<String>? sourceKind,
    Value<String?>? sourceRecordHmac,
    Value<String>? canonicalPayloadHash,
    Value<String>? canonicalKind,
    Value<String>? canonicalId,
    Value<DateTime>? occurredAtUtc,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RawRecordIndexCompanion(
      id: id ?? this.id,
      sourceConnectionId: sourceConnectionId ?? this.sourceConnectionId,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceRecordHmac: sourceRecordHmac ?? this.sourceRecordHmac,
      canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
      canonicalKind: canonicalKind ?? this.canonicalKind,
      canonicalId: canonicalId ?? this.canonicalId,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceConnectionId.present) {
      map['source_connection_id'] = Variable<String>(sourceConnectionId.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(sourceKind.value);
    }
    if (sourceRecordHmac.present) {
      map['source_record_hmac'] = Variable<String>(sourceRecordHmac.value);
    }
    if (canonicalPayloadHash.present) {
      map['canonical_payload_hash'] = Variable<String>(
        canonicalPayloadHash.value,
      );
    }
    if (canonicalKind.present) {
      map['canonical_kind'] = Variable<String>(canonicalKind.value);
    }
    if (canonicalId.present) {
      map['canonical_id'] = Variable<String>(canonicalId.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawRecordIndexCompanion(')
          ..write('id: $id, ')
          ..write('sourceConnectionId: $sourceConnectionId, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceRecordHmac: $sourceRecordHmac, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('canonicalKind: $canonicalKind, ')
          ..write('canonicalId: $canonicalId, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalSamplesTable extends SignalSamples
    with TableInfo<$SignalSamplesTable, SignalSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signalTypeMeta = const VerificationMeta(
    'signalType',
  );
  @override
  late final GeneratedColumn<String> signalType = GeneratedColumn<String>(
    'signal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalOffsetMinutesMeta =
      const VerificationMeta('originalOffsetMinutes');
  @override
  late final GeneratedColumn<int> originalOffsetMinutes = GeneratedColumn<int>(
    'original_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalLocalDateMeta = const VerificationMeta(
    'originalLocalDate',
  );
  @override
  late final GeneratedColumn<String> originalLocalDate =
      GeneratedColumn<String>(
        'original_local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _provenanceJsonMeta = const VerificationMeta(
    'provenanceJson',
  );
  @override
  late final GeneratedColumn<String> provenanceJson = GeneratedColumn<String>(
    'provenance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalPayloadHashMeta =
      const VerificationMeta('canonicalPayloadHash');
  @override
  late final GeneratedColumn<String> canonicalPayloadHash =
      GeneratedColumn<String>(
        'canonical_payload_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signalType,
    occurredAtUtc,
    value,
    unit,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('signal_type')) {
      context.handle(
        _signalTypeMeta,
        signalType.isAcceptableOrUnknown(data['signal_type']!, _signalTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_signalTypeMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('original_offset_minutes')) {
      context.handle(
        _originalOffsetMinutesMeta,
        originalOffsetMinutes.isAcceptableOrUnknown(
          data['original_offset_minutes']!,
          _originalOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOffsetMinutesMeta);
    }
    if (data.containsKey('original_local_date')) {
      context.handle(
        _originalLocalDateMeta,
        originalLocalDate.isAcceptableOrUnknown(
          data['original_local_date']!,
          _originalLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalDateMeta);
    }
    if (data.containsKey('provenance_json')) {
      context.handle(
        _provenanceJsonMeta,
        provenanceJson.isAcceptableOrUnknown(
          data['provenance_json']!,
          _provenanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provenanceJsonMeta);
    }
    if (data.containsKey('canonical_payload_hash')) {
      context.handle(
        _canonicalPayloadHashMeta,
        canonicalPayloadHash.isAcceptableOrUnknown(
          data['canonical_payload_hash']!,
          _canonicalPayloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignalSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      signalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signal_type'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      originalOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_offset_minutes'],
      )!,
      originalLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_date'],
      )!,
      provenanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance_json'],
      )!,
      canonicalPayloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_hash'],
      )!,
    );
  }

  @override
  $SignalSamplesTable createAlias(String alias) {
    return $SignalSamplesTable(attachedDatabase, alias);
  }
}

class SignalSampleRow extends DataClass implements Insertable<SignalSampleRow> {
  final String id;
  final String signalType;
  final DateTime occurredAtUtc;
  final double value;
  final String unit;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final String provenanceJson;
  final String canonicalPayloadHash;
  const SignalSampleRow({
    required this.id,
    required this.signalType,
    required this.occurredAtUtc,
    required this.value,
    required this.unit,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenanceJson,
    required this.canonicalPayloadHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['signal_type'] = Variable<String>(signalType);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['original_offset_minutes'] = Variable<int>(originalOffsetMinutes);
    map['original_local_date'] = Variable<String>(originalLocalDate);
    map['provenance_json'] = Variable<String>(provenanceJson);
    map['canonical_payload_hash'] = Variable<String>(canonicalPayloadHash);
    return map;
  }

  SignalSamplesCompanion toCompanion(bool nullToAbsent) {
    return SignalSamplesCompanion(
      id: Value(id),
      signalType: Value(signalType),
      occurredAtUtc: Value(occurredAtUtc),
      value: Value(value),
      unit: Value(unit),
      originalOffsetMinutes: Value(originalOffsetMinutes),
      originalLocalDate: Value(originalLocalDate),
      provenanceJson: Value(provenanceJson),
      canonicalPayloadHash: Value(canonicalPayloadHash),
    );
  }

  factory SignalSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSampleRow(
      id: serializer.fromJson<String>(json['id']),
      signalType: serializer.fromJson<String>(json['signalType']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      originalOffsetMinutes: serializer.fromJson<int>(
        json['originalOffsetMinutes'],
      ),
      originalLocalDate: serializer.fromJson<String>(json['originalLocalDate']),
      provenanceJson: serializer.fromJson<String>(json['provenanceJson']),
      canonicalPayloadHash: serializer.fromJson<String>(
        json['canonicalPayloadHash'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'signalType': serializer.toJson<String>(signalType),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'originalOffsetMinutes': serializer.toJson<int>(originalOffsetMinutes),
      'originalLocalDate': serializer.toJson<String>(originalLocalDate),
      'provenanceJson': serializer.toJson<String>(provenanceJson),
      'canonicalPayloadHash': serializer.toJson<String>(canonicalPayloadHash),
    };
  }

  SignalSampleRow copyWith({
    String? id,
    String? signalType,
    DateTime? occurredAtUtc,
    double? value,
    String? unit,
    int? originalOffsetMinutes,
    String? originalLocalDate,
    String? provenanceJson,
    String? canonicalPayloadHash,
  }) => SignalSampleRow(
    id: id ?? this.id,
    signalType: signalType ?? this.signalType,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    originalOffsetMinutes: originalOffsetMinutes ?? this.originalOffsetMinutes,
    originalLocalDate: originalLocalDate ?? this.originalLocalDate,
    provenanceJson: provenanceJson ?? this.provenanceJson,
    canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
  );
  SignalSampleRow copyWithCompanion(SignalSamplesCompanion data) {
    return SignalSampleRow(
      id: data.id.present ? data.id.value : this.id,
      signalType: data.signalType.present
          ? data.signalType.value
          : this.signalType,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      originalOffsetMinutes: data.originalOffsetMinutes.present
          ? data.originalOffsetMinutes.value
          : this.originalOffsetMinutes,
      originalLocalDate: data.originalLocalDate.present
          ? data.originalLocalDate.value
          : this.originalLocalDate,
      provenanceJson: data.provenanceJson.present
          ? data.provenanceJson.value
          : this.provenanceJson,
      canonicalPayloadHash: data.canonicalPayloadHash.present
          ? data.canonicalPayloadHash.value
          : this.canonicalPayloadHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSampleRow(')
          ..write('id: $id, ')
          ..write('signalType: $signalType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    signalType,
    occurredAtUtc,
    value,
    unit,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSampleRow &&
          other.id == this.id &&
          other.signalType == this.signalType &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.originalOffsetMinutes == this.originalOffsetMinutes &&
          other.originalLocalDate == this.originalLocalDate &&
          other.provenanceJson == this.provenanceJson &&
          other.canonicalPayloadHash == this.canonicalPayloadHash);
}

class SignalSamplesCompanion extends UpdateCompanion<SignalSampleRow> {
  final Value<String> id;
  final Value<String> signalType;
  final Value<DateTime> occurredAtUtc;
  final Value<double> value;
  final Value<String> unit;
  final Value<int> originalOffsetMinutes;
  final Value<String> originalLocalDate;
  final Value<String> provenanceJson;
  final Value<String> canonicalPayloadHash;
  final Value<int> rowid;
  const SignalSamplesCompanion({
    this.id = const Value.absent(),
    this.signalType = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.originalOffsetMinutes = const Value.absent(),
    this.originalLocalDate = const Value.absent(),
    this.provenanceJson = const Value.absent(),
    this.canonicalPayloadHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSamplesCompanion.insert({
    required String id,
    required String signalType,
    required DateTime occurredAtUtc,
    required double value,
    required String unit,
    required int originalOffsetMinutes,
    required String originalLocalDate,
    required String provenanceJson,
    required String canonicalPayloadHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       signalType = Value(signalType),
       occurredAtUtc = Value(occurredAtUtc),
       value = Value(value),
       unit = Value(unit),
       originalOffsetMinutes = Value(originalOffsetMinutes),
       originalLocalDate = Value(originalLocalDate),
       provenanceJson = Value(provenanceJson),
       canonicalPayloadHash = Value(canonicalPayloadHash);
  static Insertable<SignalSampleRow> custom({
    Expression<String>? id,
    Expression<String>? signalType,
    Expression<DateTime>? occurredAtUtc,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<int>? originalOffsetMinutes,
    Expression<String>? originalLocalDate,
    Expression<String>? provenanceJson,
    Expression<String>? canonicalPayloadHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signalType != null) 'signal_type': signalType,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (originalOffsetMinutes != null)
        'original_offset_minutes': originalOffsetMinutes,
      if (originalLocalDate != null) 'original_local_date': originalLocalDate,
      if (provenanceJson != null) 'provenance_json': provenanceJson,
      if (canonicalPayloadHash != null)
        'canonical_payload_hash': canonicalPayloadHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalSamplesCompanion copyWith({
    Value<String>? id,
    Value<String>? signalType,
    Value<DateTime>? occurredAtUtc,
    Value<double>? value,
    Value<String>? unit,
    Value<int>? originalOffsetMinutes,
    Value<String>? originalLocalDate,
    Value<String>? provenanceJson,
    Value<String>? canonicalPayloadHash,
    Value<int>? rowid,
  }) {
    return SignalSamplesCompanion(
      id: id ?? this.id,
      signalType: signalType ?? this.signalType,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      originalOffsetMinutes:
          originalOffsetMinutes ?? this.originalOffsetMinutes,
      originalLocalDate: originalLocalDate ?? this.originalLocalDate,
      provenanceJson: provenanceJson ?? this.provenanceJson,
      canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (signalType.present) {
      map['signal_type'] = Variable<String>(signalType.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (originalOffsetMinutes.present) {
      map['original_offset_minutes'] = Variable<int>(
        originalOffsetMinutes.value,
      );
    }
    if (originalLocalDate.present) {
      map['original_local_date'] = Variable<String>(originalLocalDate.value);
    }
    if (provenanceJson.present) {
      map['provenance_json'] = Variable<String>(provenanceJson.value);
    }
    if (canonicalPayloadHash.present) {
      map['canonical_payload_hash'] = Variable<String>(
        canonicalPayloadHash.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSamplesCompanion(')
          ..write('id: $id, ')
          ..write('signalType: $signalType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthIntervalsTable extends HealthIntervals
    with TableInfo<$HealthIntervalsTable, HealthIntervalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthIntervalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalTypeMeta = const VerificationMeta(
    'intervalType',
  );
  @override
  late final GeneratedColumn<String> intervalType = GeneratedColumn<String>(
    'interval_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalOffsetMinutesMeta =
      const VerificationMeta('originalOffsetMinutes');
  @override
  late final GeneratedColumn<int> originalOffsetMinutes = GeneratedColumn<int>(
    'original_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalLocalDateMeta = const VerificationMeta(
    'originalLocalDate',
  );
  @override
  late final GeneratedColumn<String> originalLocalDate =
      GeneratedColumn<String>(
        'original_local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _provenanceJsonMeta = const VerificationMeta(
    'provenanceJson',
  );
  @override
  late final GeneratedColumn<String> provenanceJson = GeneratedColumn<String>(
    'provenance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalPayloadHashMeta =
      const VerificationMeta('canonicalPayloadHash');
  @override
  late final GeneratedColumn<String> canonicalPayloadHash =
      GeneratedColumn<String>(
        'canonical_payload_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    intervalType,
    category,
    startAtUtc,
    endAtUtc,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_intervals';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthIntervalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('interval_type')) {
      context.handle(
        _intervalTypeMeta,
        intervalType.isAcceptableOrUnknown(
          data['interval_type']!,
          _intervalTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('original_offset_minutes')) {
      context.handle(
        _originalOffsetMinutesMeta,
        originalOffsetMinutes.isAcceptableOrUnknown(
          data['original_offset_minutes']!,
          _originalOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOffsetMinutesMeta);
    }
    if (data.containsKey('original_local_date')) {
      context.handle(
        _originalLocalDateMeta,
        originalLocalDate.isAcceptableOrUnknown(
          data['original_local_date']!,
          _originalLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalDateMeta);
    }
    if (data.containsKey('provenance_json')) {
      context.handle(
        _provenanceJsonMeta,
        provenanceJson.isAcceptableOrUnknown(
          data['provenance_json']!,
          _provenanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provenanceJsonMeta);
    }
    if (data.containsKey('canonical_payload_hash')) {
      context.handle(
        _canonicalPayloadHashMeta,
        canonicalPayloadHash.isAcceptableOrUnknown(
          data['canonical_payload_hash']!,
          _canonicalPayloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthIntervalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthIntervalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      intervalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interval_type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      originalOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_offset_minutes'],
      )!,
      originalLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_date'],
      )!,
      provenanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance_json'],
      )!,
      canonicalPayloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_hash'],
      )!,
    );
  }

  @override
  $HealthIntervalsTable createAlias(String alias) {
    return $HealthIntervalsTable(attachedDatabase, alias);
  }
}

class HealthIntervalRow extends DataClass
    implements Insertable<HealthIntervalRow> {
  final String id;
  final String intervalType;
  final String category;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final String provenanceJson;
  final String canonicalPayloadHash;
  const HealthIntervalRow({
    required this.id,
    required this.intervalType,
    required this.category,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenanceJson,
    required this.canonicalPayloadHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['interval_type'] = Variable<String>(intervalType);
    map['category'] = Variable<String>(category);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    map['original_offset_minutes'] = Variable<int>(originalOffsetMinutes);
    map['original_local_date'] = Variable<String>(originalLocalDate);
    map['provenance_json'] = Variable<String>(provenanceJson);
    map['canonical_payload_hash'] = Variable<String>(canonicalPayloadHash);
    return map;
  }

  HealthIntervalsCompanion toCompanion(bool nullToAbsent) {
    return HealthIntervalsCompanion(
      id: Value(id),
      intervalType: Value(intervalType),
      category: Value(category),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      originalOffsetMinutes: Value(originalOffsetMinutes),
      originalLocalDate: Value(originalLocalDate),
      provenanceJson: Value(provenanceJson),
      canonicalPayloadHash: Value(canonicalPayloadHash),
    );
  }

  factory HealthIntervalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthIntervalRow(
      id: serializer.fromJson<String>(json['id']),
      intervalType: serializer.fromJson<String>(json['intervalType']),
      category: serializer.fromJson<String>(json['category']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      originalOffsetMinutes: serializer.fromJson<int>(
        json['originalOffsetMinutes'],
      ),
      originalLocalDate: serializer.fromJson<String>(json['originalLocalDate']),
      provenanceJson: serializer.fromJson<String>(json['provenanceJson']),
      canonicalPayloadHash: serializer.fromJson<String>(
        json['canonicalPayloadHash'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'intervalType': serializer.toJson<String>(intervalType),
      'category': serializer.toJson<String>(category),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'originalOffsetMinutes': serializer.toJson<int>(originalOffsetMinutes),
      'originalLocalDate': serializer.toJson<String>(originalLocalDate),
      'provenanceJson': serializer.toJson<String>(provenanceJson),
      'canonicalPayloadHash': serializer.toJson<String>(canonicalPayloadHash),
    };
  }

  HealthIntervalRow copyWith({
    String? id,
    String? intervalType,
    String? category,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    int? originalOffsetMinutes,
    String? originalLocalDate,
    String? provenanceJson,
    String? canonicalPayloadHash,
  }) => HealthIntervalRow(
    id: id ?? this.id,
    intervalType: intervalType ?? this.intervalType,
    category: category ?? this.category,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    originalOffsetMinutes: originalOffsetMinutes ?? this.originalOffsetMinutes,
    originalLocalDate: originalLocalDate ?? this.originalLocalDate,
    provenanceJson: provenanceJson ?? this.provenanceJson,
    canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
  );
  HealthIntervalRow copyWithCompanion(HealthIntervalsCompanion data) {
    return HealthIntervalRow(
      id: data.id.present ? data.id.value : this.id,
      intervalType: data.intervalType.present
          ? data.intervalType.value
          : this.intervalType,
      category: data.category.present ? data.category.value : this.category,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      originalOffsetMinutes: data.originalOffsetMinutes.present
          ? data.originalOffsetMinutes.value
          : this.originalOffsetMinutes,
      originalLocalDate: data.originalLocalDate.present
          ? data.originalLocalDate.value
          : this.originalLocalDate,
      provenanceJson: data.provenanceJson.present
          ? data.provenanceJson.value
          : this.provenanceJson,
      canonicalPayloadHash: data.canonicalPayloadHash.present
          ? data.canonicalPayloadHash.value
          : this.canonicalPayloadHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthIntervalRow(')
          ..write('id: $id, ')
          ..write('intervalType: $intervalType, ')
          ..write('category: $category, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    intervalType,
    category,
    startAtUtc,
    endAtUtc,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthIntervalRow &&
          other.id == this.id &&
          other.intervalType == this.intervalType &&
          other.category == this.category &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.originalOffsetMinutes == this.originalOffsetMinutes &&
          other.originalLocalDate == this.originalLocalDate &&
          other.provenanceJson == this.provenanceJson &&
          other.canonicalPayloadHash == this.canonicalPayloadHash);
}

class HealthIntervalsCompanion extends UpdateCompanion<HealthIntervalRow> {
  final Value<String> id;
  final Value<String> intervalType;
  final Value<String> category;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<int> originalOffsetMinutes;
  final Value<String> originalLocalDate;
  final Value<String> provenanceJson;
  final Value<String> canonicalPayloadHash;
  final Value<int> rowid;
  const HealthIntervalsCompanion({
    this.id = const Value.absent(),
    this.intervalType = const Value.absent(),
    this.category = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.originalOffsetMinutes = const Value.absent(),
    this.originalLocalDate = const Value.absent(),
    this.provenanceJson = const Value.absent(),
    this.canonicalPayloadHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthIntervalsCompanion.insert({
    required String id,
    required String intervalType,
    required String category,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required int originalOffsetMinutes,
    required String originalLocalDate,
    required String provenanceJson,
    required String canonicalPayloadHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       intervalType = Value(intervalType),
       category = Value(category),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       originalOffsetMinutes = Value(originalOffsetMinutes),
       originalLocalDate = Value(originalLocalDate),
       provenanceJson = Value(provenanceJson),
       canonicalPayloadHash = Value(canonicalPayloadHash);
  static Insertable<HealthIntervalRow> custom({
    Expression<String>? id,
    Expression<String>? intervalType,
    Expression<String>? category,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<int>? originalOffsetMinutes,
    Expression<String>? originalLocalDate,
    Expression<String>? provenanceJson,
    Expression<String>? canonicalPayloadHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (intervalType != null) 'interval_type': intervalType,
      if (category != null) 'category': category,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (originalOffsetMinutes != null)
        'original_offset_minutes': originalOffsetMinutes,
      if (originalLocalDate != null) 'original_local_date': originalLocalDate,
      if (provenanceJson != null) 'provenance_json': provenanceJson,
      if (canonicalPayloadHash != null)
        'canonical_payload_hash': canonicalPayloadHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthIntervalsCompanion copyWith({
    Value<String>? id,
    Value<String>? intervalType,
    Value<String>? category,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<int>? originalOffsetMinutes,
    Value<String>? originalLocalDate,
    Value<String>? provenanceJson,
    Value<String>? canonicalPayloadHash,
    Value<int>? rowid,
  }) {
    return HealthIntervalsCompanion(
      id: id ?? this.id,
      intervalType: intervalType ?? this.intervalType,
      category: category ?? this.category,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      originalOffsetMinutes:
          originalOffsetMinutes ?? this.originalOffsetMinutes,
      originalLocalDate: originalLocalDate ?? this.originalLocalDate,
      provenanceJson: provenanceJson ?? this.provenanceJson,
      canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (intervalType.present) {
      map['interval_type'] = Variable<String>(intervalType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (originalOffsetMinutes.present) {
      map['original_offset_minutes'] = Variable<int>(
        originalOffsetMinutes.value,
      );
    }
    if (originalLocalDate.present) {
      map['original_local_date'] = Variable<String>(originalLocalDate.value);
    }
    if (provenanceJson.present) {
      map['provenance_json'] = Variable<String>(provenanceJson.value);
    }
    if (canonicalPayloadHash.present) {
      map['canonical_payload_hash'] = Variable<String>(
        canonicalPayloadHash.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthIntervalsCompanion(')
          ..write('id: $id, ')
          ..write('intervalType: $intervalType, ')
          ..write('category: $category, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextEventsTable extends ContextEvents
    with TableInfo<$ContextEventsTable, ContextEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceKeyHmacMeta = const VerificationMeta(
    'recurrenceKeyHmac',
  );
  @override
  late final GeneratedColumn<String> recurrenceKeyHmac =
      GeneratedColumn<String>(
        'recurrence_key_hmac',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalOffsetMinutesMeta =
      const VerificationMeta('originalOffsetMinutes');
  @override
  late final GeneratedColumn<int> originalOffsetMinutes = GeneratedColumn<int>(
    'original_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalLocalDateMeta = const VerificationMeta(
    'originalLocalDate',
  );
  @override
  late final GeneratedColumn<String> originalLocalDate =
      GeneratedColumn<String>(
        'original_local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _provenanceJsonMeta = const VerificationMeta(
    'provenanceJson',
  );
  @override
  late final GeneratedColumn<String> provenanceJson = GeneratedColumn<String>(
    'provenance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalPayloadHashMeta =
      const VerificationMeta('canonicalPayloadHash');
  @override
  late final GeneratedColumn<String> canonicalPayloadHash =
      GeneratedColumn<String>(
        'canonical_payload_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    startAtUtc,
    endAtUtc,
    recurrenceKeyHmac,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('recurrence_key_hmac')) {
      context.handle(
        _recurrenceKeyHmacMeta,
        recurrenceKeyHmac.isAcceptableOrUnknown(
          data['recurrence_key_hmac']!,
          _recurrenceKeyHmacMeta,
        ),
      );
    }
    if (data.containsKey('original_offset_minutes')) {
      context.handle(
        _originalOffsetMinutesMeta,
        originalOffsetMinutes.isAcceptableOrUnknown(
          data['original_offset_minutes']!,
          _originalOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOffsetMinutesMeta);
    }
    if (data.containsKey('original_local_date')) {
      context.handle(
        _originalLocalDateMeta,
        originalLocalDate.isAcceptableOrUnknown(
          data['original_local_date']!,
          _originalLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalDateMeta);
    }
    if (data.containsKey('provenance_json')) {
      context.handle(
        _provenanceJsonMeta,
        provenanceJson.isAcceptableOrUnknown(
          data['provenance_json']!,
          _provenanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provenanceJsonMeta);
    }
    if (data.containsKey('canonical_payload_hash')) {
      context.handle(
        _canonicalPayloadHashMeta,
        canonicalPayloadHash.isAcceptableOrUnknown(
          data['canonical_payload_hash']!,
          _canonicalPayloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      recurrenceKeyHmac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_key_hmac'],
      ),
      originalOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_offset_minutes'],
      )!,
      originalLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_date'],
      )!,
      provenanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance_json'],
      )!,
      canonicalPayloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_hash'],
      )!,
    );
  }

  @override
  $ContextEventsTable createAlias(String alias) {
    return $ContextEventsTable(attachedDatabase, alias);
  }
}

class ContextEventRow extends DataClass implements Insertable<ContextEventRow> {
  final String id;
  final String category;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String? recurrenceKeyHmac;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final String provenanceJson;
  final String canonicalPayloadHash;
  const ContextEventRow({
    required this.id,
    required this.category,
    required this.startAtUtc,
    required this.endAtUtc,
    this.recurrenceKeyHmac,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenanceJson,
    required this.canonicalPayloadHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    if (!nullToAbsent || recurrenceKeyHmac != null) {
      map['recurrence_key_hmac'] = Variable<String>(recurrenceKeyHmac);
    }
    map['original_offset_minutes'] = Variable<int>(originalOffsetMinutes);
    map['original_local_date'] = Variable<String>(originalLocalDate);
    map['provenance_json'] = Variable<String>(provenanceJson);
    map['canonical_payload_hash'] = Variable<String>(canonicalPayloadHash);
    return map;
  }

  ContextEventsCompanion toCompanion(bool nullToAbsent) {
    return ContextEventsCompanion(
      id: Value(id),
      category: Value(category),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      recurrenceKeyHmac: recurrenceKeyHmac == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceKeyHmac),
      originalOffsetMinutes: Value(originalOffsetMinutes),
      originalLocalDate: Value(originalLocalDate),
      provenanceJson: Value(provenanceJson),
      canonicalPayloadHash: Value(canonicalPayloadHash),
    );
  }

  factory ContextEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextEventRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      recurrenceKeyHmac: serializer.fromJson<String?>(
        json['recurrenceKeyHmac'],
      ),
      originalOffsetMinutes: serializer.fromJson<int>(
        json['originalOffsetMinutes'],
      ),
      originalLocalDate: serializer.fromJson<String>(json['originalLocalDate']),
      provenanceJson: serializer.fromJson<String>(json['provenanceJson']),
      canonicalPayloadHash: serializer.fromJson<String>(
        json['canonicalPayloadHash'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'recurrenceKeyHmac': serializer.toJson<String?>(recurrenceKeyHmac),
      'originalOffsetMinutes': serializer.toJson<int>(originalOffsetMinutes),
      'originalLocalDate': serializer.toJson<String>(originalLocalDate),
      'provenanceJson': serializer.toJson<String>(provenanceJson),
      'canonicalPayloadHash': serializer.toJson<String>(canonicalPayloadHash),
    };
  }

  ContextEventRow copyWith({
    String? id,
    String? category,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    Value<String?> recurrenceKeyHmac = const Value.absent(),
    int? originalOffsetMinutes,
    String? originalLocalDate,
    String? provenanceJson,
    String? canonicalPayloadHash,
  }) => ContextEventRow(
    id: id ?? this.id,
    category: category ?? this.category,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    recurrenceKeyHmac: recurrenceKeyHmac.present
        ? recurrenceKeyHmac.value
        : this.recurrenceKeyHmac,
    originalOffsetMinutes: originalOffsetMinutes ?? this.originalOffsetMinutes,
    originalLocalDate: originalLocalDate ?? this.originalLocalDate,
    provenanceJson: provenanceJson ?? this.provenanceJson,
    canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
  );
  ContextEventRow copyWithCompanion(ContextEventsCompanion data) {
    return ContextEventRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      recurrenceKeyHmac: data.recurrenceKeyHmac.present
          ? data.recurrenceKeyHmac.value
          : this.recurrenceKeyHmac,
      originalOffsetMinutes: data.originalOffsetMinutes.present
          ? data.originalOffsetMinutes.value
          : this.originalOffsetMinutes,
      originalLocalDate: data.originalLocalDate.present
          ? data.originalLocalDate.value
          : this.originalLocalDate,
      provenanceJson: data.provenanceJson.present
          ? data.provenanceJson.value
          : this.provenanceJson,
      canonicalPayloadHash: data.canonicalPayloadHash.present
          ? data.canonicalPayloadHash.value
          : this.canonicalPayloadHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextEventRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('recurrenceKeyHmac: $recurrenceKeyHmac, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    startAtUtc,
    endAtUtc,
    recurrenceKeyHmac,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextEventRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.recurrenceKeyHmac == this.recurrenceKeyHmac &&
          other.originalOffsetMinutes == this.originalOffsetMinutes &&
          other.originalLocalDate == this.originalLocalDate &&
          other.provenanceJson == this.provenanceJson &&
          other.canonicalPayloadHash == this.canonicalPayloadHash);
}

class ContextEventsCompanion extends UpdateCompanion<ContextEventRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<String?> recurrenceKeyHmac;
  final Value<int> originalOffsetMinutes;
  final Value<String> originalLocalDate;
  final Value<String> provenanceJson;
  final Value<String> canonicalPayloadHash;
  final Value<int> rowid;
  const ContextEventsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.recurrenceKeyHmac = const Value.absent(),
    this.originalOffsetMinutes = const Value.absent(),
    this.originalLocalDate = const Value.absent(),
    this.provenanceJson = const Value.absent(),
    this.canonicalPayloadHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextEventsCompanion.insert({
    required String id,
    required String category,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    this.recurrenceKeyHmac = const Value.absent(),
    required int originalOffsetMinutes,
    required String originalLocalDate,
    required String provenanceJson,
    required String canonicalPayloadHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       originalOffsetMinutes = Value(originalOffsetMinutes),
       originalLocalDate = Value(originalLocalDate),
       provenanceJson = Value(provenanceJson),
       canonicalPayloadHash = Value(canonicalPayloadHash);
  static Insertable<ContextEventRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<String>? recurrenceKeyHmac,
    Expression<int>? originalOffsetMinutes,
    Expression<String>? originalLocalDate,
    Expression<String>? provenanceJson,
    Expression<String>? canonicalPayloadHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (recurrenceKeyHmac != null) 'recurrence_key_hmac': recurrenceKeyHmac,
      if (originalOffsetMinutes != null)
        'original_offset_minutes': originalOffsetMinutes,
      if (originalLocalDate != null) 'original_local_date': originalLocalDate,
      if (provenanceJson != null) 'provenance_json': provenanceJson,
      if (canonicalPayloadHash != null)
        'canonical_payload_hash': canonicalPayloadHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<String?>? recurrenceKeyHmac,
    Value<int>? originalOffsetMinutes,
    Value<String>? originalLocalDate,
    Value<String>? provenanceJson,
    Value<String>? canonicalPayloadHash,
    Value<int>? rowid,
  }) {
    return ContextEventsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      recurrenceKeyHmac: recurrenceKeyHmac ?? this.recurrenceKeyHmac,
      originalOffsetMinutes:
          originalOffsetMinutes ?? this.originalOffsetMinutes,
      originalLocalDate: originalLocalDate ?? this.originalLocalDate,
      provenanceJson: provenanceJson ?? this.provenanceJson,
      canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (recurrenceKeyHmac.present) {
      map['recurrence_key_hmac'] = Variable<String>(recurrenceKeyHmac.value);
    }
    if (originalOffsetMinutes.present) {
      map['original_offset_minutes'] = Variable<int>(
        originalOffsetMinutes.value,
      );
    }
    if (originalLocalDate.present) {
      map['original_local_date'] = Variable<String>(originalLocalDate.value);
    }
    if (provenanceJson.present) {
      map['provenance_json'] = Variable<String>(provenanceJson.value);
    }
    if (canonicalPayloadHash.present) {
      map['canonical_payload_hash'] = Variable<String>(
        canonicalPayloadHash.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextEventsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('recurrenceKeyHmac: $recurrenceKeyHmac, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualCheckinsTable extends ManualCheckins
    with TableInfo<$ManualCheckinsTable, ManualCheckinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalOffsetMinutesMeta =
      const VerificationMeta('originalOffsetMinutes');
  @override
  late final GeneratedColumn<int> originalOffsetMinutes = GeneratedColumn<int>(
    'original_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalLocalDateMeta = const VerificationMeta(
    'originalLocalDate',
  );
  @override
  late final GeneratedColumn<String> originalLocalDate =
      GeneratedColumn<String>(
        'original_local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _provenanceJsonMeta = const VerificationMeta(
    'provenanceJson',
  );
  @override
  late final GeneratedColumn<String> provenanceJson = GeneratedColumn<String>(
    'provenance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalPayloadHashMeta =
      const VerificationMeta('canonicalPayloadHash');
  @override
  late final GeneratedColumn<String> canonicalPayloadHash =
      GeneratedColumn<String>(
        'canonical_payload_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    occurredAtUtc,
    valueJson,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualCheckinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('original_offset_minutes')) {
      context.handle(
        _originalOffsetMinutesMeta,
        originalOffsetMinutes.isAcceptableOrUnknown(
          data['original_offset_minutes']!,
          _originalOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOffsetMinutesMeta);
    }
    if (data.containsKey('original_local_date')) {
      context.handle(
        _originalLocalDateMeta,
        originalLocalDate.isAcceptableOrUnknown(
          data['original_local_date']!,
          _originalLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalDateMeta);
    }
    if (data.containsKey('provenance_json')) {
      context.handle(
        _provenanceJsonMeta,
        provenanceJson.isAcceptableOrUnknown(
          data['provenance_json']!,
          _provenanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provenanceJsonMeta);
    }
    if (data.containsKey('canonical_payload_hash')) {
      context.handle(
        _canonicalPayloadHashMeta,
        canonicalPayloadHash.isAcceptableOrUnknown(
          data['canonical_payload_hash']!,
          _canonicalPayloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadHashMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualCheckinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualCheckinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      originalOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_offset_minutes'],
      )!,
      originalLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_date'],
      )!,
      provenanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance_json'],
      )!,
      canonicalPayloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_hash'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ManualCheckinsTable createAlias(String alias) {
    return $ManualCheckinsTable(attachedDatabase, alias);
  }
}

class ManualCheckinRow extends DataClass
    implements Insertable<ManualCheckinRow> {
  final String id;
  final String category;
  final DateTime occurredAtUtc;
  final String valueJson;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final String provenanceJson;
  final String canonicalPayloadHash;
  final DateTime updatedAt;
  const ManualCheckinRow({
    required this.id,
    required this.category,
    required this.occurredAtUtc,
    required this.valueJson,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenanceJson,
    required this.canonicalPayloadHash,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['value_json'] = Variable<String>(valueJson);
    map['original_offset_minutes'] = Variable<int>(originalOffsetMinutes);
    map['original_local_date'] = Variable<String>(originalLocalDate);
    map['provenance_json'] = Variable<String>(provenanceJson);
    map['canonical_payload_hash'] = Variable<String>(canonicalPayloadHash);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ManualCheckinsCompanion toCompanion(bool nullToAbsent) {
    return ManualCheckinsCompanion(
      id: Value(id),
      category: Value(category),
      occurredAtUtc: Value(occurredAtUtc),
      valueJson: Value(valueJson),
      originalOffsetMinutes: Value(originalOffsetMinutes),
      originalLocalDate: Value(originalLocalDate),
      provenanceJson: Value(provenanceJson),
      canonicalPayloadHash: Value(canonicalPayloadHash),
      updatedAt: Value(updatedAt),
    );
  }

  factory ManualCheckinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualCheckinRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      originalOffsetMinutes: serializer.fromJson<int>(
        json['originalOffsetMinutes'],
      ),
      originalLocalDate: serializer.fromJson<String>(json['originalLocalDate']),
      provenanceJson: serializer.fromJson<String>(json['provenanceJson']),
      canonicalPayloadHash: serializer.fromJson<String>(
        json['canonicalPayloadHash'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'valueJson': serializer.toJson<String>(valueJson),
      'originalOffsetMinutes': serializer.toJson<int>(originalOffsetMinutes),
      'originalLocalDate': serializer.toJson<String>(originalLocalDate),
      'provenanceJson': serializer.toJson<String>(provenanceJson),
      'canonicalPayloadHash': serializer.toJson<String>(canonicalPayloadHash),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ManualCheckinRow copyWith({
    String? id,
    String? category,
    DateTime? occurredAtUtc,
    String? valueJson,
    int? originalOffsetMinutes,
    String? originalLocalDate,
    String? provenanceJson,
    String? canonicalPayloadHash,
    DateTime? updatedAt,
  }) => ManualCheckinRow(
    id: id ?? this.id,
    category: category ?? this.category,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    valueJson: valueJson ?? this.valueJson,
    originalOffsetMinutes: originalOffsetMinutes ?? this.originalOffsetMinutes,
    originalLocalDate: originalLocalDate ?? this.originalLocalDate,
    provenanceJson: provenanceJson ?? this.provenanceJson,
    canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ManualCheckinRow copyWithCompanion(ManualCheckinsCompanion data) {
    return ManualCheckinRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      originalOffsetMinutes: data.originalOffsetMinutes.present
          ? data.originalOffsetMinutes.value
          : this.originalOffsetMinutes,
      originalLocalDate: data.originalLocalDate.present
          ? data.originalLocalDate.value
          : this.originalLocalDate,
      provenanceJson: data.provenanceJson.present
          ? data.provenanceJson.value
          : this.provenanceJson,
      canonicalPayloadHash: data.canonicalPayloadHash.present
          ? data.canonicalPayloadHash.value
          : this.canonicalPayloadHash,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualCheckinRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('valueJson: $valueJson, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    occurredAtUtc,
    valueJson,
    originalOffsetMinutes,
    originalLocalDate,
    provenanceJson,
    canonicalPayloadHash,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualCheckinRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.valueJson == this.valueJson &&
          other.originalOffsetMinutes == this.originalOffsetMinutes &&
          other.originalLocalDate == this.originalLocalDate &&
          other.provenanceJson == this.provenanceJson &&
          other.canonicalPayloadHash == this.canonicalPayloadHash &&
          other.updatedAt == this.updatedAt);
}

class ManualCheckinsCompanion extends UpdateCompanion<ManualCheckinRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<DateTime> occurredAtUtc;
  final Value<String> valueJson;
  final Value<int> originalOffsetMinutes;
  final Value<String> originalLocalDate;
  final Value<String> provenanceJson;
  final Value<String> canonicalPayloadHash;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ManualCheckinsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.originalOffsetMinutes = const Value.absent(),
    this.originalLocalDate = const Value.absent(),
    this.provenanceJson = const Value.absent(),
    this.canonicalPayloadHash = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualCheckinsCompanion.insert({
    required String id,
    required String category,
    required DateTime occurredAtUtc,
    required String valueJson,
    required int originalOffsetMinutes,
    required String originalLocalDate,
    required String provenanceJson,
    required String canonicalPayloadHash,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       occurredAtUtc = Value(occurredAtUtc),
       valueJson = Value(valueJson),
       originalOffsetMinutes = Value(originalOffsetMinutes),
       originalLocalDate = Value(originalLocalDate),
       provenanceJson = Value(provenanceJson),
       canonicalPayloadHash = Value(canonicalPayloadHash);
  static Insertable<ManualCheckinRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<DateTime>? occurredAtUtc,
    Expression<String>? valueJson,
    Expression<int>? originalOffsetMinutes,
    Expression<String>? originalLocalDate,
    Expression<String>? provenanceJson,
    Expression<String>? canonicalPayloadHash,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (valueJson != null) 'value_json': valueJson,
      if (originalOffsetMinutes != null)
        'original_offset_minutes': originalOffsetMinutes,
      if (originalLocalDate != null) 'original_local_date': originalLocalDate,
      if (provenanceJson != null) 'provenance_json': provenanceJson,
      if (canonicalPayloadHash != null)
        'canonical_payload_hash': canonicalPayloadHash,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualCheckinsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<DateTime>? occurredAtUtc,
    Value<String>? valueJson,
    Value<int>? originalOffsetMinutes,
    Value<String>? originalLocalDate,
    Value<String>? provenanceJson,
    Value<String>? canonicalPayloadHash,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ManualCheckinsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      valueJson: valueJson ?? this.valueJson,
      originalOffsetMinutes:
          originalOffsetMinutes ?? this.originalOffsetMinutes,
      originalLocalDate: originalLocalDate ?? this.originalLocalDate,
      provenanceJson: provenanceJson ?? this.provenanceJson,
      canonicalPayloadHash: canonicalPayloadHash ?? this.canonicalPayloadHash,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (originalOffsetMinutes.present) {
      map['original_offset_minutes'] = Variable<int>(
        originalOffsetMinutes.value,
      );
    }
    if (originalLocalDate.present) {
      map['original_local_date'] = Variable<String>(originalLocalDate.value);
    }
    if (provenanceJson.present) {
      map['provenance_json'] = Variable<String>(provenanceJson.value);
    }
    if (canonicalPayloadHash.present) {
      map['canonical_payload_hash'] = Variable<String>(
        canonicalPayloadHash.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('valueJson: $valueJson, ')
          ..write('originalOffsetMinutes: $originalOffsetMinutes, ')
          ..write('originalLocalDate: $originalLocalDate, ')
          ..write('provenanceJson: $provenanceJson, ')
          ..write('canonicalPayloadHash: $canonicalPayloadHash, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecomputeJobsTable extends RecomputeJobs
    with TableInfo<$RecomputeJobsTable, RecomputeJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecomputeJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyStartUtcMeta = const VerificationMeta(
    'dirtyStartUtc',
  );
  @override
  late final GeneratedColumn<DateTime> dirtyStartUtc =
      GeneratedColumn<DateTime>(
        'dirty_start_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dirtyEndUtcMeta = const VerificationMeta(
    'dirtyEndUtc',
  );
  @override
  late final GeneratedColumn<DateTime> dirtyEndUtc = GeneratedColumn<DateTime>(
    'dirty_end_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCheckpointMeta = const VerificationMeta(
    'lastCheckpoint',
  );
  @override
  late final GeneratedColumn<String> lastCheckpoint = GeneratedColumn<String>(
    'last_checkpoint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _analysisVersionMeta = const VerificationMeta(
    'analysisVersion',
  );
  @override
  late final GeneratedColumn<int> analysisVersion = GeneratedColumn<int>(
    'analysis_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dirtyStartUtc,
    dirtyEndUtc,
    reason,
    sourceId,
    status,
    retryCount,
    lastCheckpoint,
    analysisVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recompute_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecomputeJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dirty_start_utc')) {
      context.handle(
        _dirtyStartUtcMeta,
        dirtyStartUtc.isAcceptableOrUnknown(
          data['dirty_start_utc']!,
          _dirtyStartUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dirtyStartUtcMeta);
    }
    if (data.containsKey('dirty_end_utc')) {
      context.handle(
        _dirtyEndUtcMeta,
        dirtyEndUtc.isAcceptableOrUnknown(
          data['dirty_end_utc']!,
          _dirtyEndUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dirtyEndUtcMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_checkpoint')) {
      context.handle(
        _lastCheckpointMeta,
        lastCheckpoint.isAcceptableOrUnknown(
          data['last_checkpoint']!,
          _lastCheckpointMeta,
        ),
      );
    }
    if (data.containsKey('analysis_version')) {
      context.handle(
        _analysisVersionMeta,
        analysisVersion.isAcceptableOrUnknown(
          data['analysis_version']!,
          _analysisVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecomputeJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecomputeJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dirtyStartUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dirty_start_utc'],
      )!,
      dirtyEndUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dirty_end_utc'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastCheckpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_checkpoint'],
      ),
      analysisVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analysis_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecomputeJobsTable createAlias(String alias) {
    return $RecomputeJobsTable(attachedDatabase, alias);
  }
}

class RecomputeJobRow extends DataClass implements Insertable<RecomputeJobRow> {
  final String id;
  final DateTime dirtyStartUtc;
  final DateTime dirtyEndUtc;
  final String reason;
  final String? sourceId;
  final String status;
  final int retryCount;
  final String? lastCheckpoint;
  final int analysisVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecomputeJobRow({
    required this.id,
    required this.dirtyStartUtc,
    required this.dirtyEndUtc,
    required this.reason,
    this.sourceId,
    required this.status,
    required this.retryCount,
    this.lastCheckpoint,
    required this.analysisVersion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dirty_start_utc'] = Variable<DateTime>(dirtyStartUtc);
    map['dirty_end_utc'] = Variable<DateTime>(dirtyEndUtc);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastCheckpoint != null) {
      map['last_checkpoint'] = Variable<String>(lastCheckpoint);
    }
    map['analysis_version'] = Variable<int>(analysisVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecomputeJobsCompanion toCompanion(bool nullToAbsent) {
    return RecomputeJobsCompanion(
      id: Value(id),
      dirtyStartUtc: Value(dirtyStartUtc),
      dirtyEndUtc: Value(dirtyEndUtc),
      reason: Value(reason),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      status: Value(status),
      retryCount: Value(retryCount),
      lastCheckpoint: lastCheckpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckpoint),
      analysisVersion: Value(analysisVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecomputeJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecomputeJobRow(
      id: serializer.fromJson<String>(json['id']),
      dirtyStartUtc: serializer.fromJson<DateTime>(json['dirtyStartUtc']),
      dirtyEndUtc: serializer.fromJson<DateTime>(json['dirtyEndUtc']),
      reason: serializer.fromJson<String>(json['reason']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastCheckpoint: serializer.fromJson<String?>(json['lastCheckpoint']),
      analysisVersion: serializer.fromJson<int>(json['analysisVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dirtyStartUtc': serializer.toJson<DateTime>(dirtyStartUtc),
      'dirtyEndUtc': serializer.toJson<DateTime>(dirtyEndUtc),
      'reason': serializer.toJson<String>(reason),
      'sourceId': serializer.toJson<String?>(sourceId),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastCheckpoint': serializer.toJson<String?>(lastCheckpoint),
      'analysisVersion': serializer.toJson<int>(analysisVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecomputeJobRow copyWith({
    String? id,
    DateTime? dirtyStartUtc,
    DateTime? dirtyEndUtc,
    String? reason,
    Value<String?> sourceId = const Value.absent(),
    String? status,
    int? retryCount,
    Value<String?> lastCheckpoint = const Value.absent(),
    int? analysisVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecomputeJobRow(
    id: id ?? this.id,
    dirtyStartUtc: dirtyStartUtc ?? this.dirtyStartUtc,
    dirtyEndUtc: dirtyEndUtc ?? this.dirtyEndUtc,
    reason: reason ?? this.reason,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastCheckpoint: lastCheckpoint.present
        ? lastCheckpoint.value
        : this.lastCheckpoint,
    analysisVersion: analysisVersion ?? this.analysisVersion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecomputeJobRow copyWithCompanion(RecomputeJobsCompanion data) {
    return RecomputeJobRow(
      id: data.id.present ? data.id.value : this.id,
      dirtyStartUtc: data.dirtyStartUtc.present
          ? data.dirtyStartUtc.value
          : this.dirtyStartUtc,
      dirtyEndUtc: data.dirtyEndUtc.present
          ? data.dirtyEndUtc.value
          : this.dirtyEndUtc,
      reason: data.reason.present ? data.reason.value : this.reason,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastCheckpoint: data.lastCheckpoint.present
          ? data.lastCheckpoint.value
          : this.lastCheckpoint,
      analysisVersion: data.analysisVersion.present
          ? data.analysisVersion.value
          : this.analysisVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecomputeJobRow(')
          ..write('id: $id, ')
          ..write('dirtyStartUtc: $dirtyStartUtc, ')
          ..write('dirtyEndUtc: $dirtyEndUtc, ')
          ..write('reason: $reason, ')
          ..write('sourceId: $sourceId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastCheckpoint: $lastCheckpoint, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dirtyStartUtc,
    dirtyEndUtc,
    reason,
    sourceId,
    status,
    retryCount,
    lastCheckpoint,
    analysisVersion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecomputeJobRow &&
          other.id == this.id &&
          other.dirtyStartUtc == this.dirtyStartUtc &&
          other.dirtyEndUtc == this.dirtyEndUtc &&
          other.reason == this.reason &&
          other.sourceId == this.sourceId &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastCheckpoint == this.lastCheckpoint &&
          other.analysisVersion == this.analysisVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecomputeJobsCompanion extends UpdateCompanion<RecomputeJobRow> {
  final Value<String> id;
  final Value<DateTime> dirtyStartUtc;
  final Value<DateTime> dirtyEndUtc;
  final Value<String> reason;
  final Value<String?> sourceId;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastCheckpoint;
  final Value<int> analysisVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecomputeJobsCompanion({
    this.id = const Value.absent(),
    this.dirtyStartUtc = const Value.absent(),
    this.dirtyEndUtc = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastCheckpoint = const Value.absent(),
    this.analysisVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecomputeJobsCompanion.insert({
    required String id,
    required DateTime dirtyStartUtc,
    required DateTime dirtyEndUtc,
    required String reason,
    this.sourceId = const Value.absent(),
    required String status,
    this.retryCount = const Value.absent(),
    this.lastCheckpoint = const Value.absent(),
    required int analysisVersion,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dirtyStartUtc = Value(dirtyStartUtc),
       dirtyEndUtc = Value(dirtyEndUtc),
       reason = Value(reason),
       status = Value(status),
       analysisVersion = Value(analysisVersion);
  static Insertable<RecomputeJobRow> custom({
    Expression<String>? id,
    Expression<DateTime>? dirtyStartUtc,
    Expression<DateTime>? dirtyEndUtc,
    Expression<String>? reason,
    Expression<String>? sourceId,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastCheckpoint,
    Expression<int>? analysisVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dirtyStartUtc != null) 'dirty_start_utc': dirtyStartUtc,
      if (dirtyEndUtc != null) 'dirty_end_utc': dirtyEndUtc,
      if (reason != null) 'reason': reason,
      if (sourceId != null) 'source_id': sourceId,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastCheckpoint != null) 'last_checkpoint': lastCheckpoint,
      if (analysisVersion != null) 'analysis_version': analysisVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecomputeJobsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? dirtyStartUtc,
    Value<DateTime>? dirtyEndUtc,
    Value<String>? reason,
    Value<String?>? sourceId,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastCheckpoint,
    Value<int>? analysisVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecomputeJobsCompanion(
      id: id ?? this.id,
      dirtyStartUtc: dirtyStartUtc ?? this.dirtyStartUtc,
      dirtyEndUtc: dirtyEndUtc ?? this.dirtyEndUtc,
      reason: reason ?? this.reason,
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastCheckpoint: lastCheckpoint ?? this.lastCheckpoint,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dirtyStartUtc.present) {
      map['dirty_start_utc'] = Variable<DateTime>(dirtyStartUtc.value);
    }
    if (dirtyEndUtc.present) {
      map['dirty_end_utc'] = Variable<DateTime>(dirtyEndUtc.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastCheckpoint.present) {
      map['last_checkpoint'] = Variable<String>(lastCheckpoint.value);
    }
    if (analysisVersion.present) {
      map['analysis_version'] = Variable<int>(analysisVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecomputeJobsCompanion(')
          ..write('id: $id, ')
          ..write('dirtyStartUtc: $dirtyStartUtc, ')
          ..write('dirtyEndUtc: $dirtyEndUtc, ')
          ..write('reason: $reason, ')
          ..write('sourceId: $sourceId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastCheckpoint: $lastCheckpoint, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysisRunsTable extends AnalysisRuns
    with TableInfo<$AnalysisRunsTable, AnalysisRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeStartUtcMeta = const VerificationMeta(
    'rangeStartUtc',
  );
  @override
  late final GeneratedColumn<DateTime> rangeStartUtc =
      GeneratedColumn<DateTime>(
        'range_start_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rangeEndUtcMeta = const VerificationMeta(
    'rangeEndUtc',
  );
  @override
  late final GeneratedColumn<DateTime> rangeEndUtc = GeneratedColumn<DateTime>(
    'range_end_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysisVersionMeta = const VerificationMeta(
    'analysisVersion',
  );
  @override
  late final GeneratedColumn<int> analysisVersion = GeneratedColumn<int>(
    'analysis_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputHashMeta = const VerificationMeta(
    'inputHash',
  );
  @override
  late final GeneratedColumn<String> inputHash = GeneratedColumn<String>(
    'input_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputHashMeta = const VerificationMeta(
    'outputHash',
  );
  @override
  late final GeneratedColumn<String> outputHash = GeneratedColumn<String>(
    'output_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    rangeStartUtc,
    rangeEndUtc,
    analysisVersion,
    startedAt,
    finishedAt,
    inputHash,
    outputHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalysisRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('range_start_utc')) {
      context.handle(
        _rangeStartUtcMeta,
        rangeStartUtc.isAcceptableOrUnknown(
          data['range_start_utc']!,
          _rangeStartUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rangeStartUtcMeta);
    }
    if (data.containsKey('range_end_utc')) {
      context.handle(
        _rangeEndUtcMeta,
        rangeEndUtc.isAcceptableOrUnknown(
          data['range_end_utc']!,
          _rangeEndUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rangeEndUtcMeta);
    }
    if (data.containsKey('analysis_version')) {
      context.handle(
        _analysisVersionMeta,
        analysisVersion.isAcceptableOrUnknown(
          data['analysis_version']!,
          _analysisVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisVersionMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('input_hash')) {
      context.handle(
        _inputHashMeta,
        inputHash.isAcceptableOrUnknown(data['input_hash']!, _inputHashMeta),
      );
    } else if (isInserting) {
      context.missing(_inputHashMeta);
    }
    if (data.containsKey('output_hash')) {
      context.handle(
        _outputHashMeta,
        outputHash.isAcceptableOrUnknown(data['output_hash']!, _outputHashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rangeStartUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}range_start_utc'],
      )!,
      rangeEndUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}range_end_utc'],
      )!,
      analysisVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analysis_version'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      inputHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_hash'],
      )!,
      outputHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_hash'],
      ),
    );
  }

  @override
  $AnalysisRunsTable createAlias(String alias) {
    return $AnalysisRunsTable(attachedDatabase, alias);
  }
}

class AnalysisRunRow extends DataClass implements Insertable<AnalysisRunRow> {
  final String id;
  final String status;
  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;
  final int analysisVersion;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String inputHash;
  final String? outputHash;
  const AnalysisRunRow({
    required this.id,
    required this.status,
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    required this.analysisVersion,
    required this.startedAt,
    this.finishedAt,
    required this.inputHash,
    this.outputHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['range_start_utc'] = Variable<DateTime>(rangeStartUtc);
    map['range_end_utc'] = Variable<DateTime>(rangeEndUtc);
    map['analysis_version'] = Variable<int>(analysisVersion);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['input_hash'] = Variable<String>(inputHash);
    if (!nullToAbsent || outputHash != null) {
      map['output_hash'] = Variable<String>(outputHash);
    }
    return map;
  }

  AnalysisRunsCompanion toCompanion(bool nullToAbsent) {
    return AnalysisRunsCompanion(
      id: Value(id),
      status: Value(status),
      rangeStartUtc: Value(rangeStartUtc),
      rangeEndUtc: Value(rangeEndUtc),
      analysisVersion: Value(analysisVersion),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      inputHash: Value(inputHash),
      outputHash: outputHash == null && nullToAbsent
          ? const Value.absent()
          : Value(outputHash),
    );
  }

  factory AnalysisRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisRunRow(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      rangeStartUtc: serializer.fromJson<DateTime>(json['rangeStartUtc']),
      rangeEndUtc: serializer.fromJson<DateTime>(json['rangeEndUtc']),
      analysisVersion: serializer.fromJson<int>(json['analysisVersion']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      inputHash: serializer.fromJson<String>(json['inputHash']),
      outputHash: serializer.fromJson<String?>(json['outputHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'rangeStartUtc': serializer.toJson<DateTime>(rangeStartUtc),
      'rangeEndUtc': serializer.toJson<DateTime>(rangeEndUtc),
      'analysisVersion': serializer.toJson<int>(analysisVersion),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'inputHash': serializer.toJson<String>(inputHash),
      'outputHash': serializer.toJson<String?>(outputHash),
    };
  }

  AnalysisRunRow copyWith({
    String? id,
    String? status,
    DateTime? rangeStartUtc,
    DateTime? rangeEndUtc,
    int? analysisVersion,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? inputHash,
    Value<String?> outputHash = const Value.absent(),
  }) => AnalysisRunRow(
    id: id ?? this.id,
    status: status ?? this.status,
    rangeStartUtc: rangeStartUtc ?? this.rangeStartUtc,
    rangeEndUtc: rangeEndUtc ?? this.rangeEndUtc,
    analysisVersion: analysisVersion ?? this.analysisVersion,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    inputHash: inputHash ?? this.inputHash,
    outputHash: outputHash.present ? outputHash.value : this.outputHash,
  );
  AnalysisRunRow copyWithCompanion(AnalysisRunsCompanion data) {
    return AnalysisRunRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      rangeStartUtc: data.rangeStartUtc.present
          ? data.rangeStartUtc.value
          : this.rangeStartUtc,
      rangeEndUtc: data.rangeEndUtc.present
          ? data.rangeEndUtc.value
          : this.rangeEndUtc,
      analysisVersion: data.analysisVersion.present
          ? data.analysisVersion.value
          : this.analysisVersion,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      inputHash: data.inputHash.present ? data.inputHash.value : this.inputHash,
      outputHash: data.outputHash.present
          ? data.outputHash.value
          : this.outputHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisRunRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('rangeStartUtc: $rangeStartUtc, ')
          ..write('rangeEndUtc: $rangeEndUtc, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('inputHash: $inputHash, ')
          ..write('outputHash: $outputHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    rangeStartUtc,
    rangeEndUtc,
    analysisVersion,
    startedAt,
    finishedAt,
    inputHash,
    outputHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisRunRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.rangeStartUtc == this.rangeStartUtc &&
          other.rangeEndUtc == this.rangeEndUtc &&
          other.analysisVersion == this.analysisVersion &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.inputHash == this.inputHash &&
          other.outputHash == this.outputHash);
}

class AnalysisRunsCompanion extends UpdateCompanion<AnalysisRunRow> {
  final Value<String> id;
  final Value<String> status;
  final Value<DateTime> rangeStartUtc;
  final Value<DateTime> rangeEndUtc;
  final Value<int> analysisVersion;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> inputHash;
  final Value<String?> outputHash;
  final Value<int> rowid;
  const AnalysisRunsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.rangeStartUtc = const Value.absent(),
    this.rangeEndUtc = const Value.absent(),
    this.analysisVersion = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.inputHash = const Value.absent(),
    this.outputHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisRunsCompanion.insert({
    required String id,
    required String status,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
    required int analysisVersion,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    required String inputHash,
    this.outputHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       rangeStartUtc = Value(rangeStartUtc),
       rangeEndUtc = Value(rangeEndUtc),
       analysisVersion = Value(analysisVersion),
       startedAt = Value(startedAt),
       inputHash = Value(inputHash);
  static Insertable<AnalysisRunRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<DateTime>? rangeStartUtc,
    Expression<DateTime>? rangeEndUtc,
    Expression<int>? analysisVersion,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? inputHash,
    Expression<String>? outputHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (rangeStartUtc != null) 'range_start_utc': rangeStartUtc,
      if (rangeEndUtc != null) 'range_end_utc': rangeEndUtc,
      if (analysisVersion != null) 'analysis_version': analysisVersion,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (inputHash != null) 'input_hash': inputHash,
      if (outputHash != null) 'output_hash': outputHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<DateTime>? rangeStartUtc,
    Value<DateTime>? rangeEndUtc,
    Value<int>? analysisVersion,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? inputHash,
    Value<String?>? outputHash,
    Value<int>? rowid,
  }) {
    return AnalysisRunsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      rangeStartUtc: rangeStartUtc ?? this.rangeStartUtc,
      rangeEndUtc: rangeEndUtc ?? this.rangeEndUtc,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      inputHash: inputHash ?? this.inputHash,
      outputHash: outputHash ?? this.outputHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rangeStartUtc.present) {
      map['range_start_utc'] = Variable<DateTime>(rangeStartUtc.value);
    }
    if (rangeEndUtc.present) {
      map['range_end_utc'] = Variable<DateTime>(rangeEndUtc.value);
    }
    if (analysisVersion.present) {
      map['analysis_version'] = Variable<int>(analysisVersion.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (inputHash.present) {
      map['input_hash'] = Variable<String>(inputHash.value);
    }
    if (outputHash.present) {
      map['output_hash'] = Variable<String>(outputHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisRunsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('rangeStartUtc: $rangeStartUtc, ')
          ..write('rangeEndUtc: $rangeEndUtc, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('inputHash: $inputHash, ')
          ..write('outputHash: $outputHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventWindowsTable extends EventWindows
    with TableInfo<$EventWindowsTable, EventWindowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventWindowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysisRunIdMeta = const VerificationMeta(
    'analysisRunId',
  );
  @override
  late final GeneratedColumn<String> analysisRunId = GeneratedColumn<String>(
    'analysis_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES analysis_runs (id)',
    ),
  );
  static const VerificationMeta _contextEventIdMeta = const VerificationMeta(
    'contextEventId',
  );
  @override
  late final GeneratedColumn<String> contextEventId = GeneratedColumn<String>(
    'context_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES context_events (id)',
    ),
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exclusionReasonMeta = const VerificationMeta(
    'exclusionReason',
  );
  @override
  late final GeneratedColumn<String> exclusionReason = GeneratedColumn<String>(
    'exclusion_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    analysisRunId,
    contextEventId,
    startAtUtc,
    endAtUtc,
    status,
    exclusionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_windows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventWindowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('analysis_run_id')) {
      context.handle(
        _analysisRunIdMeta,
        analysisRunId.isAcceptableOrUnknown(
          data['analysis_run_id']!,
          _analysisRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisRunIdMeta);
    }
    if (data.containsKey('context_event_id')) {
      context.handle(
        _contextEventIdMeta,
        contextEventId.isAcceptableOrUnknown(
          data['context_event_id']!,
          _contextEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextEventIdMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('exclusion_reason')) {
      context.handle(
        _exclusionReasonMeta,
        exclusionReason.isAcceptableOrUnknown(
          data['exclusion_reason']!,
          _exclusionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventWindowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventWindowRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      analysisRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysis_run_id'],
      )!,
      contextEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_event_id'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      exclusionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exclusion_reason'],
      ),
    );
  }

  @override
  $EventWindowsTable createAlias(String alias) {
    return $EventWindowsTable(attachedDatabase, alias);
  }
}

class EventWindowRow extends DataClass implements Insertable<EventWindowRow> {
  final String id;
  final String analysisRunId;
  final String contextEventId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String status;
  final String? exclusionReason;
  const EventWindowRow({
    required this.id,
    required this.analysisRunId,
    required this.contextEventId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.status,
    this.exclusionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['analysis_run_id'] = Variable<String>(analysisRunId);
    map['context_event_id'] = Variable<String>(contextEventId);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || exclusionReason != null) {
      map['exclusion_reason'] = Variable<String>(exclusionReason);
    }
    return map;
  }

  EventWindowsCompanion toCompanion(bool nullToAbsent) {
    return EventWindowsCompanion(
      id: Value(id),
      analysisRunId: Value(analysisRunId),
      contextEventId: Value(contextEventId),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      status: Value(status),
      exclusionReason: exclusionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(exclusionReason),
    );
  }

  factory EventWindowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventWindowRow(
      id: serializer.fromJson<String>(json['id']),
      analysisRunId: serializer.fromJson<String>(json['analysisRunId']),
      contextEventId: serializer.fromJson<String>(json['contextEventId']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      status: serializer.fromJson<String>(json['status']),
      exclusionReason: serializer.fromJson<String?>(json['exclusionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'analysisRunId': serializer.toJson<String>(analysisRunId),
      'contextEventId': serializer.toJson<String>(contextEventId),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'status': serializer.toJson<String>(status),
      'exclusionReason': serializer.toJson<String?>(exclusionReason),
    };
  }

  EventWindowRow copyWith({
    String? id,
    String? analysisRunId,
    String? contextEventId,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    String? status,
    Value<String?> exclusionReason = const Value.absent(),
  }) => EventWindowRow(
    id: id ?? this.id,
    analysisRunId: analysisRunId ?? this.analysisRunId,
    contextEventId: contextEventId ?? this.contextEventId,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    status: status ?? this.status,
    exclusionReason: exclusionReason.present
        ? exclusionReason.value
        : this.exclusionReason,
  );
  EventWindowRow copyWithCompanion(EventWindowsCompanion data) {
    return EventWindowRow(
      id: data.id.present ? data.id.value : this.id,
      analysisRunId: data.analysisRunId.present
          ? data.analysisRunId.value
          : this.analysisRunId,
      contextEventId: data.contextEventId.present
          ? data.contextEventId.value
          : this.contextEventId,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      status: data.status.present ? data.status.value : this.status,
      exclusionReason: data.exclusionReason.present
          ? data.exclusionReason.value
          : this.exclusionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventWindowRow(')
          ..write('id: $id, ')
          ..write('analysisRunId: $analysisRunId, ')
          ..write('contextEventId: $contextEventId, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('status: $status, ')
          ..write('exclusionReason: $exclusionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    analysisRunId,
    contextEventId,
    startAtUtc,
    endAtUtc,
    status,
    exclusionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventWindowRow &&
          other.id == this.id &&
          other.analysisRunId == this.analysisRunId &&
          other.contextEventId == this.contextEventId &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.status == this.status &&
          other.exclusionReason == this.exclusionReason);
}

class EventWindowsCompanion extends UpdateCompanion<EventWindowRow> {
  final Value<String> id;
  final Value<String> analysisRunId;
  final Value<String> contextEventId;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<String> status;
  final Value<String?> exclusionReason;
  final Value<int> rowid;
  const EventWindowsCompanion({
    this.id = const Value.absent(),
    this.analysisRunId = const Value.absent(),
    this.contextEventId = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.status = const Value.absent(),
    this.exclusionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventWindowsCompanion.insert({
    required String id,
    required String analysisRunId,
    required String contextEventId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required String status,
    this.exclusionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       analysisRunId = Value(analysisRunId),
       contextEventId = Value(contextEventId),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       status = Value(status);
  static Insertable<EventWindowRow> custom({
    Expression<String>? id,
    Expression<String>? analysisRunId,
    Expression<String>? contextEventId,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<String>? status,
    Expression<String>? exclusionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (analysisRunId != null) 'analysis_run_id': analysisRunId,
      if (contextEventId != null) 'context_event_id': contextEventId,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (status != null) 'status': status,
      if (exclusionReason != null) 'exclusion_reason': exclusionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventWindowsCompanion copyWith({
    Value<String>? id,
    Value<String>? analysisRunId,
    Value<String>? contextEventId,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<String>? status,
    Value<String?>? exclusionReason,
    Value<int>? rowid,
  }) {
    return EventWindowsCompanion(
      id: id ?? this.id,
      analysisRunId: analysisRunId ?? this.analysisRunId,
      contextEventId: contextEventId ?? this.contextEventId,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      status: status ?? this.status,
      exclusionReason: exclusionReason ?? this.exclusionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (analysisRunId.present) {
      map['analysis_run_id'] = Variable<String>(analysisRunId.value);
    }
    if (contextEventId.present) {
      map['context_event_id'] = Variable<String>(contextEventId.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (exclusionReason.present) {
      map['exclusion_reason'] = Variable<String>(exclusionReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventWindowsCompanion(')
          ..write('id: $id, ')
          ..write('analysisRunId: $analysisRunId, ')
          ..write('contextEventId: $contextEventId, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('status: $status, ')
          ..write('exclusionReason: $exclusionReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ControlMatchesTable extends ControlMatches
    with TableInfo<$ControlMatchesTable, ControlMatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ControlMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventWindowIdMeta = const VerificationMeta(
    'eventWindowId',
  );
  @override
  late final GeneratedColumn<String> eventWindowId = GeneratedColumn<String>(
    'event_window_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES event_windows (id)',
    ),
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endAtUtc = GeneratedColumn<DateTime>(
    'end_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factorsJsonMeta = const VerificationMeta(
    'factorsJson',
  );
  @override
  late final GeneratedColumn<String> factorsJson = GeneratedColumn<String>(
    'factors_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventWindowId,
    startAtUtc,
    endAtUtc,
    score,
    factorsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'control_matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ControlMatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_window_id')) {
      context.handle(
        _eventWindowIdMeta,
        eventWindowId.isAcceptableOrUnknown(
          data['event_window_id']!,
          _eventWindowIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventWindowIdMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtUtcMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('factors_json')) {
      context.handle(
        _factorsJsonMeta,
        factorsJson.isAcceptableOrUnknown(
          data['factors_json']!,
          _factorsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_factorsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ControlMatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ControlMatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventWindowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_window_id'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at_utc'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      factorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}factors_json'],
      )!,
    );
  }

  @override
  $ControlMatchesTable createAlias(String alias) {
    return $ControlMatchesTable(attachedDatabase, alias);
  }
}

class ControlMatchRow extends DataClass implements Insertable<ControlMatchRow> {
  final String id;
  final String eventWindowId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final double score;
  final String factorsJson;
  const ControlMatchRow({
    required this.id,
    required this.eventWindowId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.score,
    required this.factorsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_window_id'] = Variable<String>(eventWindowId);
    map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    map['end_at_utc'] = Variable<DateTime>(endAtUtc);
    map['score'] = Variable<double>(score);
    map['factors_json'] = Variable<String>(factorsJson);
    return map;
  }

  ControlMatchesCompanion toCompanion(bool nullToAbsent) {
    return ControlMatchesCompanion(
      id: Value(id),
      eventWindowId: Value(eventWindowId),
      startAtUtc: Value(startAtUtc),
      endAtUtc: Value(endAtUtc),
      score: Value(score),
      factorsJson: Value(factorsJson),
    );
  }

  factory ControlMatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ControlMatchRow(
      id: serializer.fromJson<String>(json['id']),
      eventWindowId: serializer.fromJson<String>(json['eventWindowId']),
      startAtUtc: serializer.fromJson<DateTime>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<DateTime>(json['endAtUtc']),
      score: serializer.fromJson<double>(json['score']),
      factorsJson: serializer.fromJson<String>(json['factorsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventWindowId': serializer.toJson<String>(eventWindowId),
      'startAtUtc': serializer.toJson<DateTime>(startAtUtc),
      'endAtUtc': serializer.toJson<DateTime>(endAtUtc),
      'score': serializer.toJson<double>(score),
      'factorsJson': serializer.toJson<String>(factorsJson),
    };
  }

  ControlMatchRow copyWith({
    String? id,
    String? eventWindowId,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    double? score,
    String? factorsJson,
  }) => ControlMatchRow(
    id: id ?? this.id,
    eventWindowId: eventWindowId ?? this.eventWindowId,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc ?? this.endAtUtc,
    score: score ?? this.score,
    factorsJson: factorsJson ?? this.factorsJson,
  );
  ControlMatchRow copyWithCompanion(ControlMatchesCompanion data) {
    return ControlMatchRow(
      id: data.id.present ? data.id.value : this.id,
      eventWindowId: data.eventWindowId.present
          ? data.eventWindowId.value
          : this.eventWindowId,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      score: data.score.present ? data.score.value : this.score,
      factorsJson: data.factorsJson.present
          ? data.factorsJson.value
          : this.factorsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ControlMatchRow(')
          ..write('id: $id, ')
          ..write('eventWindowId: $eventWindowId, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('score: $score, ')
          ..write('factorsJson: $factorsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventWindowId, startAtUtc, endAtUtc, score, factorsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ControlMatchRow &&
          other.id == this.id &&
          other.eventWindowId == this.eventWindowId &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.score == this.score &&
          other.factorsJson == this.factorsJson);
}

class ControlMatchesCompanion extends UpdateCompanion<ControlMatchRow> {
  final Value<String> id;
  final Value<String> eventWindowId;
  final Value<DateTime> startAtUtc;
  final Value<DateTime> endAtUtc;
  final Value<double> score;
  final Value<String> factorsJson;
  final Value<int> rowid;
  const ControlMatchesCompanion({
    this.id = const Value.absent(),
    this.eventWindowId = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.score = const Value.absent(),
    this.factorsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ControlMatchesCompanion.insert({
    required String id,
    required String eventWindowId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required double score,
    required String factorsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventWindowId = Value(eventWindowId),
       startAtUtc = Value(startAtUtc),
       endAtUtc = Value(endAtUtc),
       score = Value(score),
       factorsJson = Value(factorsJson);
  static Insertable<ControlMatchRow> custom({
    Expression<String>? id,
    Expression<String>? eventWindowId,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? endAtUtc,
    Expression<double>? score,
    Expression<String>? factorsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventWindowId != null) 'event_window_id': eventWindowId,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (score != null) 'score': score,
      if (factorsJson != null) 'factors_json': factorsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ControlMatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? eventWindowId,
    Value<DateTime>? startAtUtc,
    Value<DateTime>? endAtUtc,
    Value<double>? score,
    Value<String>? factorsJson,
    Value<int>? rowid,
  }) {
    return ControlMatchesCompanion(
      id: id ?? this.id,
      eventWindowId: eventWindowId ?? this.eventWindowId,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      score: score ?? this.score,
      factorsJson: factorsJson ?? this.factorsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventWindowId.present) {
      map['event_window_id'] = Variable<String>(eventWindowId.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<DateTime>(endAtUtc.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (factorsJson.present) {
      map['factors_json'] = Variable<String>(factorsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ControlMatchesCompanion(')
          ..write('id: $id, ')
          ..write('eventWindowId: $eventWindowId, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('score: $score, ')
          ..write('factorsJson: $factorsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WindowMetricsTable extends WindowMetrics
    with TableInfo<$WindowMetricsTable, WindowMetricRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WindowMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventWindowIdMeta = const VerificationMeta(
    'eventWindowId',
  );
  @override
  late final GeneratedColumn<String> eventWindowId = GeneratedColumn<String>(
    'event_window_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES event_windows (id)',
    ),
  );
  static const VerificationMeta _controlMatchIdMeta = const VerificationMeta(
    'controlMatchId',
  );
  @override
  late final GeneratedColumn<String> controlMatchId = GeneratedColumn<String>(
    'control_match_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES control_matches (id)',
    ),
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityStateMeta = const VerificationMeta(
    'qualityState',
  );
  @override
  late final GeneratedColumn<String> qualityState = GeneratedColumn<String>(
    'quality_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventWindowId,
    controlMatchId,
    metric,
    value,
    unit,
    qualityState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'window_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<WindowMetricRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_window_id')) {
      context.handle(
        _eventWindowIdMeta,
        eventWindowId.isAcceptableOrUnknown(
          data['event_window_id']!,
          _eventWindowIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventWindowIdMeta);
    }
    if (data.containsKey('control_match_id')) {
      context.handle(
        _controlMatchIdMeta,
        controlMatchId.isAcceptableOrUnknown(
          data['control_match_id']!,
          _controlMatchIdMeta,
        ),
      );
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('quality_state')) {
      context.handle(
        _qualityStateMeta,
        qualityState.isAcceptableOrUnknown(
          data['quality_state']!,
          _qualityStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityStateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WindowMetricRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WindowMetricRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventWindowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_window_id'],
      )!,
      controlMatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}control_match_id'],
      ),
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      qualityState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_state'],
      )!,
    );
  }

  @override
  $WindowMetricsTable createAlias(String alias) {
    return $WindowMetricsTable(attachedDatabase, alias);
  }
}

class WindowMetricRow extends DataClass implements Insertable<WindowMetricRow> {
  final String id;
  final String eventWindowId;
  final String? controlMatchId;
  final String metric;
  final double value;
  final String unit;
  final String qualityState;
  const WindowMetricRow({
    required this.id,
    required this.eventWindowId,
    this.controlMatchId,
    required this.metric,
    required this.value,
    required this.unit,
    required this.qualityState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_window_id'] = Variable<String>(eventWindowId);
    if (!nullToAbsent || controlMatchId != null) {
      map['control_match_id'] = Variable<String>(controlMatchId);
    }
    map['metric'] = Variable<String>(metric);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['quality_state'] = Variable<String>(qualityState);
    return map;
  }

  WindowMetricsCompanion toCompanion(bool nullToAbsent) {
    return WindowMetricsCompanion(
      id: Value(id),
      eventWindowId: Value(eventWindowId),
      controlMatchId: controlMatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(controlMatchId),
      metric: Value(metric),
      value: Value(value),
      unit: Value(unit),
      qualityState: Value(qualityState),
    );
  }

  factory WindowMetricRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WindowMetricRow(
      id: serializer.fromJson<String>(json['id']),
      eventWindowId: serializer.fromJson<String>(json['eventWindowId']),
      controlMatchId: serializer.fromJson<String?>(json['controlMatchId']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      qualityState: serializer.fromJson<String>(json['qualityState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventWindowId': serializer.toJson<String>(eventWindowId),
      'controlMatchId': serializer.toJson<String?>(controlMatchId),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'qualityState': serializer.toJson<String>(qualityState),
    };
  }

  WindowMetricRow copyWith({
    String? id,
    String? eventWindowId,
    Value<String?> controlMatchId = const Value.absent(),
    String? metric,
    double? value,
    String? unit,
    String? qualityState,
  }) => WindowMetricRow(
    id: id ?? this.id,
    eventWindowId: eventWindowId ?? this.eventWindowId,
    controlMatchId: controlMatchId.present
        ? controlMatchId.value
        : this.controlMatchId,
    metric: metric ?? this.metric,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    qualityState: qualityState ?? this.qualityState,
  );
  WindowMetricRow copyWithCompanion(WindowMetricsCompanion data) {
    return WindowMetricRow(
      id: data.id.present ? data.id.value : this.id,
      eventWindowId: data.eventWindowId.present
          ? data.eventWindowId.value
          : this.eventWindowId,
      controlMatchId: data.controlMatchId.present
          ? data.controlMatchId.value
          : this.controlMatchId,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      qualityState: data.qualityState.present
          ? data.qualityState.value
          : this.qualityState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WindowMetricRow(')
          ..write('id: $id, ')
          ..write('eventWindowId: $eventWindowId, ')
          ..write('controlMatchId: $controlMatchId, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('qualityState: $qualityState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventWindowId,
    controlMatchId,
    metric,
    value,
    unit,
    qualityState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WindowMetricRow &&
          other.id == this.id &&
          other.eventWindowId == this.eventWindowId &&
          other.controlMatchId == this.controlMatchId &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.qualityState == this.qualityState);
}

class WindowMetricsCompanion extends UpdateCompanion<WindowMetricRow> {
  final Value<String> id;
  final Value<String> eventWindowId;
  final Value<String?> controlMatchId;
  final Value<String> metric;
  final Value<double> value;
  final Value<String> unit;
  final Value<String> qualityState;
  final Value<int> rowid;
  const WindowMetricsCompanion({
    this.id = const Value.absent(),
    this.eventWindowId = const Value.absent(),
    this.controlMatchId = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.qualityState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WindowMetricsCompanion.insert({
    required String id,
    required String eventWindowId,
    this.controlMatchId = const Value.absent(),
    required String metric,
    required double value,
    required String unit,
    required String qualityState,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventWindowId = Value(eventWindowId),
       metric = Value(metric),
       value = Value(value),
       unit = Value(unit),
       qualityState = Value(qualityState);
  static Insertable<WindowMetricRow> custom({
    Expression<String>? id,
    Expression<String>? eventWindowId,
    Expression<String>? controlMatchId,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<String>? qualityState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventWindowId != null) 'event_window_id': eventWindowId,
      if (controlMatchId != null) 'control_match_id': controlMatchId,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (qualityState != null) 'quality_state': qualityState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WindowMetricsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventWindowId,
    Value<String?>? controlMatchId,
    Value<String>? metric,
    Value<double>? value,
    Value<String>? unit,
    Value<String>? qualityState,
    Value<int>? rowid,
  }) {
    return WindowMetricsCompanion(
      id: id ?? this.id,
      eventWindowId: eventWindowId ?? this.eventWindowId,
      controlMatchId: controlMatchId ?? this.controlMatchId,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      qualityState: qualityState ?? this.qualityState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventWindowId.present) {
      map['event_window_id'] = Variable<String>(eventWindowId.value);
    }
    if (controlMatchId.present) {
      map['control_match_id'] = Variable<String>(controlMatchId.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (qualityState.present) {
      map['quality_state'] = Variable<String>(qualityState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WindowMetricsCompanion(')
          ..write('id: $id, ')
          ..write('eventWindowId: $eventWindowId, ')
          ..write('controlMatchId: $controlMatchId, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('qualityState: $qualityState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenceBundlesTable extends EvidenceBundles
    with TableInfo<$EvidenceBundlesTable, EvidenceBundleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenceBundlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysisRunIdMeta = const VerificationMeta(
    'analysisRunId',
  );
  @override
  late final GeneratedColumn<String> analysisRunId = GeneratedColumn<String>(
    'analysis_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES analysis_runs (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
  static const VerificationMeta _claimTypeMeta = const VerificationMeta(
    'claimType',
  );
  @override
  late final GeneratedColumn<String> claimType = GeneratedColumn<String>(
    'claim_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceHashMeta = const VerificationMeta(
    'evidenceHash',
  );
  @override
  late final GeneratedColumn<String> evidenceHash = GeneratedColumn<String>(
    'evidence_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promotionPolicyVersionMeta =
      const VerificationMeta('promotionPolicyVersion');
  @override
  late final GeneratedColumn<int> promotionPolicyVersion = GeneratedColumn<int>(
    'promotion_policy_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _staleAtMeta = const VerificationMeta(
    'staleAt',
  );
  @override
  late final GeneratedColumn<DateTime> staleAt = GeneratedColumn<DateTime>(
    'stale_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _staleReasonMeta = const VerificationMeta(
    'staleReason',
  );
  @override
  late final GeneratedColumn<String> staleReason = GeneratedColumn<String>(
    'stale_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    analysisRunId,
    status,
    title,
    claimType,
    evidenceHash,
    promotionPolicyVersion,
    createdAt,
    staleAt,
    staleReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidence_bundles';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenceBundleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('analysis_run_id')) {
      context.handle(
        _analysisRunIdMeta,
        analysisRunId.isAcceptableOrUnknown(
          data['analysis_run_id']!,
          _analysisRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisRunIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('claim_type')) {
      context.handle(
        _claimTypeMeta,
        claimType.isAcceptableOrUnknown(data['claim_type']!, _claimTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_claimTypeMeta);
    }
    if (data.containsKey('evidence_hash')) {
      context.handle(
        _evidenceHashMeta,
        evidenceHash.isAcceptableOrUnknown(
          data['evidence_hash']!,
          _evidenceHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceHashMeta);
    }
    if (data.containsKey('promotion_policy_version')) {
      context.handle(
        _promotionPolicyVersionMeta,
        promotionPolicyVersion.isAcceptableOrUnknown(
          data['promotion_policy_version']!,
          _promotionPolicyVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promotionPolicyVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('stale_at')) {
      context.handle(
        _staleAtMeta,
        staleAt.isAcceptableOrUnknown(data['stale_at']!, _staleAtMeta),
      );
    }
    if (data.containsKey('stale_reason')) {
      context.handle(
        _staleReasonMeta,
        staleReason.isAcceptableOrUnknown(
          data['stale_reason']!,
          _staleReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenceBundleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenceBundleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      analysisRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysis_run_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      claimType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_type'],
      )!,
      evidenceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_hash'],
      )!,
      promotionPolicyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}promotion_policy_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      staleAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stale_at'],
      ),
      staleReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stale_reason'],
      ),
    );
  }

  @override
  $EvidenceBundlesTable createAlias(String alias) {
    return $EvidenceBundlesTable(attachedDatabase, alias);
  }
}

class EvidenceBundleRow extends DataClass
    implements Insertable<EvidenceBundleRow> {
  final String id;
  final String analysisRunId;
  final String status;
  final String title;
  final String claimType;
  final String evidenceHash;
  final int promotionPolicyVersion;
  final DateTime createdAt;
  final DateTime? staleAt;
  final String? staleReason;
  const EvidenceBundleRow({
    required this.id,
    required this.analysisRunId,
    required this.status,
    required this.title,
    required this.claimType,
    required this.evidenceHash,
    required this.promotionPolicyVersion,
    required this.createdAt,
    this.staleAt,
    this.staleReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['analysis_run_id'] = Variable<String>(analysisRunId);
    map['status'] = Variable<String>(status);
    map['title'] = Variable<String>(title);
    map['claim_type'] = Variable<String>(claimType);
    map['evidence_hash'] = Variable<String>(evidenceHash);
    map['promotion_policy_version'] = Variable<int>(promotionPolicyVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || staleAt != null) {
      map['stale_at'] = Variable<DateTime>(staleAt);
    }
    if (!nullToAbsent || staleReason != null) {
      map['stale_reason'] = Variable<String>(staleReason);
    }
    return map;
  }

  EvidenceBundlesCompanion toCompanion(bool nullToAbsent) {
    return EvidenceBundlesCompanion(
      id: Value(id),
      analysisRunId: Value(analysisRunId),
      status: Value(status),
      title: Value(title),
      claimType: Value(claimType),
      evidenceHash: Value(evidenceHash),
      promotionPolicyVersion: Value(promotionPolicyVersion),
      createdAt: Value(createdAt),
      staleAt: staleAt == null && nullToAbsent
          ? const Value.absent()
          : Value(staleAt),
      staleReason: staleReason == null && nullToAbsent
          ? const Value.absent()
          : Value(staleReason),
    );
  }

  factory EvidenceBundleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenceBundleRow(
      id: serializer.fromJson<String>(json['id']),
      analysisRunId: serializer.fromJson<String>(json['analysisRunId']),
      status: serializer.fromJson<String>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      claimType: serializer.fromJson<String>(json['claimType']),
      evidenceHash: serializer.fromJson<String>(json['evidenceHash']),
      promotionPolicyVersion: serializer.fromJson<int>(
        json['promotionPolicyVersion'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      staleAt: serializer.fromJson<DateTime?>(json['staleAt']),
      staleReason: serializer.fromJson<String?>(json['staleReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'analysisRunId': serializer.toJson<String>(analysisRunId),
      'status': serializer.toJson<String>(status),
      'title': serializer.toJson<String>(title),
      'claimType': serializer.toJson<String>(claimType),
      'evidenceHash': serializer.toJson<String>(evidenceHash),
      'promotionPolicyVersion': serializer.toJson<int>(promotionPolicyVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'staleAt': serializer.toJson<DateTime?>(staleAt),
      'staleReason': serializer.toJson<String?>(staleReason),
    };
  }

  EvidenceBundleRow copyWith({
    String? id,
    String? analysisRunId,
    String? status,
    String? title,
    String? claimType,
    String? evidenceHash,
    int? promotionPolicyVersion,
    DateTime? createdAt,
    Value<DateTime?> staleAt = const Value.absent(),
    Value<String?> staleReason = const Value.absent(),
  }) => EvidenceBundleRow(
    id: id ?? this.id,
    analysisRunId: analysisRunId ?? this.analysisRunId,
    status: status ?? this.status,
    title: title ?? this.title,
    claimType: claimType ?? this.claimType,
    evidenceHash: evidenceHash ?? this.evidenceHash,
    promotionPolicyVersion:
        promotionPolicyVersion ?? this.promotionPolicyVersion,
    createdAt: createdAt ?? this.createdAt,
    staleAt: staleAt.present ? staleAt.value : this.staleAt,
    staleReason: staleReason.present ? staleReason.value : this.staleReason,
  );
  EvidenceBundleRow copyWithCompanion(EvidenceBundlesCompanion data) {
    return EvidenceBundleRow(
      id: data.id.present ? data.id.value : this.id,
      analysisRunId: data.analysisRunId.present
          ? data.analysisRunId.value
          : this.analysisRunId,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      claimType: data.claimType.present ? data.claimType.value : this.claimType,
      evidenceHash: data.evidenceHash.present
          ? data.evidenceHash.value
          : this.evidenceHash,
      promotionPolicyVersion: data.promotionPolicyVersion.present
          ? data.promotionPolicyVersion.value
          : this.promotionPolicyVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      staleAt: data.staleAt.present ? data.staleAt.value : this.staleAt,
      staleReason: data.staleReason.present
          ? data.staleReason.value
          : this.staleReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceBundleRow(')
          ..write('id: $id, ')
          ..write('analysisRunId: $analysisRunId, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('claimType: $claimType, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('promotionPolicyVersion: $promotionPolicyVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('staleReason: $staleReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    analysisRunId,
    status,
    title,
    claimType,
    evidenceHash,
    promotionPolicyVersion,
    createdAt,
    staleAt,
    staleReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceBundleRow &&
          other.id == this.id &&
          other.analysisRunId == this.analysisRunId &&
          other.status == this.status &&
          other.title == this.title &&
          other.claimType == this.claimType &&
          other.evidenceHash == this.evidenceHash &&
          other.promotionPolicyVersion == this.promotionPolicyVersion &&
          other.createdAt == this.createdAt &&
          other.staleAt == this.staleAt &&
          other.staleReason == this.staleReason);
}

class EvidenceBundlesCompanion extends UpdateCompanion<EvidenceBundleRow> {
  final Value<String> id;
  final Value<String> analysisRunId;
  final Value<String> status;
  final Value<String> title;
  final Value<String> claimType;
  final Value<String> evidenceHash;
  final Value<int> promotionPolicyVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> staleAt;
  final Value<String?> staleReason;
  final Value<int> rowid;
  const EvidenceBundlesCompanion({
    this.id = const Value.absent(),
    this.analysisRunId = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.claimType = const Value.absent(),
    this.evidenceHash = const Value.absent(),
    this.promotionPolicyVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.staleReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenceBundlesCompanion.insert({
    required String id,
    required String analysisRunId,
    required String status,
    required String title,
    required String claimType,
    required String evidenceHash,
    required int promotionPolicyVersion,
    this.createdAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.staleReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       analysisRunId = Value(analysisRunId),
       status = Value(status),
       title = Value(title),
       claimType = Value(claimType),
       evidenceHash = Value(evidenceHash),
       promotionPolicyVersion = Value(promotionPolicyVersion);
  static Insertable<EvidenceBundleRow> custom({
    Expression<String>? id,
    Expression<String>? analysisRunId,
    Expression<String>? status,
    Expression<String>? title,
    Expression<String>? claimType,
    Expression<String>? evidenceHash,
    Expression<int>? promotionPolicyVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? staleAt,
    Expression<String>? staleReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (analysisRunId != null) 'analysis_run_id': analysisRunId,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (claimType != null) 'claim_type': claimType,
      if (evidenceHash != null) 'evidence_hash': evidenceHash,
      if (promotionPolicyVersion != null)
        'promotion_policy_version': promotionPolicyVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (staleAt != null) 'stale_at': staleAt,
      if (staleReason != null) 'stale_reason': staleReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenceBundlesCompanion copyWith({
    Value<String>? id,
    Value<String>? analysisRunId,
    Value<String>? status,
    Value<String>? title,
    Value<String>? claimType,
    Value<String>? evidenceHash,
    Value<int>? promotionPolicyVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? staleAt,
    Value<String?>? staleReason,
    Value<int>? rowid,
  }) {
    return EvidenceBundlesCompanion(
      id: id ?? this.id,
      analysisRunId: analysisRunId ?? this.analysisRunId,
      status: status ?? this.status,
      title: title ?? this.title,
      claimType: claimType ?? this.claimType,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      promotionPolicyVersion:
          promotionPolicyVersion ?? this.promotionPolicyVersion,
      createdAt: createdAt ?? this.createdAt,
      staleAt: staleAt ?? this.staleAt,
      staleReason: staleReason ?? this.staleReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (analysisRunId.present) {
      map['analysis_run_id'] = Variable<String>(analysisRunId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (claimType.present) {
      map['claim_type'] = Variable<String>(claimType.value);
    }
    if (evidenceHash.present) {
      map['evidence_hash'] = Variable<String>(evidenceHash.value);
    }
    if (promotionPolicyVersion.present) {
      map['promotion_policy_version'] = Variable<int>(
        promotionPolicyVersion.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (staleAt.present) {
      map['stale_at'] = Variable<DateTime>(staleAt.value);
    }
    if (staleReason.present) {
      map['stale_reason'] = Variable<String>(staleReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceBundlesCompanion(')
          ..write('id: $id, ')
          ..write('analysisRunId: $analysisRunId, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('claimType: $claimType, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('promotionPolicyVersion: $promotionPolicyVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('staleReason: $staleReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenceMetricsTable extends EvidenceMetrics
    with TableInfo<$EvidenceMetricsTable, EvidenceMetricRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenceMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowerBoundMeta = const VerificationMeta(
    'lowerBound',
  );
  @override
  late final GeneratedColumn<double> lowerBound = GeneratedColumn<double>(
    'lower_bound',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upperBoundMeta = const VerificationMeta(
    'upperBound',
  );
  @override
  late final GeneratedColumn<double> upperBound = GeneratedColumn<double>(
    'upper_bound',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evidenceBundleId,
    metric,
    value,
    lowerBound,
    upperBound,
    unit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidence_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenceMetricRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceBundleIdMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('lower_bound')) {
      context.handle(
        _lowerBoundMeta,
        lowerBound.isAcceptableOrUnknown(data['lower_bound']!, _lowerBoundMeta),
      );
    }
    if (data.containsKey('upper_bound')) {
      context.handle(
        _upperBoundMeta,
        upperBound.isAcceptableOrUnknown(data['upper_bound']!, _upperBoundMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenceMetricRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenceMetricRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      lowerBound: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lower_bound'],
      ),
      upperBound: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}upper_bound'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
    );
  }

  @override
  $EvidenceMetricsTable createAlias(String alias) {
    return $EvidenceMetricsTable(attachedDatabase, alias);
  }
}

class EvidenceMetricRow extends DataClass
    implements Insertable<EvidenceMetricRow> {
  final String id;
  final String evidenceBundleId;
  final String metric;
  final double value;
  final double? lowerBound;
  final double? upperBound;
  final String unit;
  const EvidenceMetricRow({
    required this.id,
    required this.evidenceBundleId,
    required this.metric,
    required this.value,
    this.lowerBound,
    this.upperBound,
    required this.unit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    map['metric'] = Variable<String>(metric);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || lowerBound != null) {
      map['lower_bound'] = Variable<double>(lowerBound);
    }
    if (!nullToAbsent || upperBound != null) {
      map['upper_bound'] = Variable<double>(upperBound);
    }
    map['unit'] = Variable<String>(unit);
    return map;
  }

  EvidenceMetricsCompanion toCompanion(bool nullToAbsent) {
    return EvidenceMetricsCompanion(
      id: Value(id),
      evidenceBundleId: Value(evidenceBundleId),
      metric: Value(metric),
      value: Value(value),
      lowerBound: lowerBound == null && nullToAbsent
          ? const Value.absent()
          : Value(lowerBound),
      upperBound: upperBound == null && nullToAbsent
          ? const Value.absent()
          : Value(upperBound),
      unit: Value(unit),
    );
  }

  factory EvidenceMetricRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenceMetricRow(
      id: serializer.fromJson<String>(json['id']),
      evidenceBundleId: serializer.fromJson<String>(json['evidenceBundleId']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
      lowerBound: serializer.fromJson<double?>(json['lowerBound']),
      upperBound: serializer.fromJson<double?>(json['upperBound']),
      unit: serializer.fromJson<String>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evidenceBundleId': serializer.toJson<String>(evidenceBundleId),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<double>(value),
      'lowerBound': serializer.toJson<double?>(lowerBound),
      'upperBound': serializer.toJson<double?>(upperBound),
      'unit': serializer.toJson<String>(unit),
    };
  }

  EvidenceMetricRow copyWith({
    String? id,
    String? evidenceBundleId,
    String? metric,
    double? value,
    Value<double?> lowerBound = const Value.absent(),
    Value<double?> upperBound = const Value.absent(),
    String? unit,
  }) => EvidenceMetricRow(
    id: id ?? this.id,
    evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
    metric: metric ?? this.metric,
    value: value ?? this.value,
    lowerBound: lowerBound.present ? lowerBound.value : this.lowerBound,
    upperBound: upperBound.present ? upperBound.value : this.upperBound,
    unit: unit ?? this.unit,
  );
  EvidenceMetricRow copyWithCompanion(EvidenceMetricsCompanion data) {
    return EvidenceMetricRow(
      id: data.id.present ? data.id.value : this.id,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      lowerBound: data.lowerBound.present
          ? data.lowerBound.value
          : this.lowerBound,
      upperBound: data.upperBound.present
          ? data.upperBound.value
          : this.upperBound,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceMetricRow(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('lowerBound: $lowerBound, ')
          ..write('upperBound: $upperBound, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    evidenceBundleId,
    metric,
    value,
    lowerBound,
    upperBound,
    unit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceMetricRow &&
          other.id == this.id &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.lowerBound == this.lowerBound &&
          other.upperBound == this.upperBound &&
          other.unit == this.unit);
}

class EvidenceMetricsCompanion extends UpdateCompanion<EvidenceMetricRow> {
  final Value<String> id;
  final Value<String> evidenceBundleId;
  final Value<String> metric;
  final Value<double> value;
  final Value<double?> lowerBound;
  final Value<double?> upperBound;
  final Value<String> unit;
  final Value<int> rowid;
  const EvidenceMetricsCompanion({
    this.id = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.lowerBound = const Value.absent(),
    this.upperBound = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenceMetricsCompanion.insert({
    required String id,
    required String evidenceBundleId,
    required String metric,
    required double value,
    this.lowerBound = const Value.absent(),
    this.upperBound = const Value.absent(),
    required String unit,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       evidenceBundleId = Value(evidenceBundleId),
       metric = Value(metric),
       value = Value(value),
       unit = Value(unit);
  static Insertable<EvidenceMetricRow> custom({
    Expression<String>? id,
    Expression<String>? evidenceBundleId,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<double>? lowerBound,
    Expression<double>? upperBound,
    Expression<String>? unit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (lowerBound != null) 'lower_bound': lowerBound,
      if (upperBound != null) 'upper_bound': upperBound,
      if (unit != null) 'unit': unit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenceMetricsCompanion copyWith({
    Value<String>? id,
    Value<String>? evidenceBundleId,
    Value<String>? metric,
    Value<double>? value,
    Value<double?>? lowerBound,
    Value<double?>? upperBound,
    Value<String>? unit,
    Value<int>? rowid,
  }) {
    return EvidenceMetricsCompanion(
      id: id ?? this.id,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      lowerBound: lowerBound ?? this.lowerBound,
      upperBound: upperBound ?? this.upperBound,
      unit: unit ?? this.unit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (lowerBound.present) {
      map['lower_bound'] = Variable<double>(lowerBound.value);
    }
    if (upperBound.present) {
      map['upper_bound'] = Variable<double>(upperBound.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceMetricsCompanion(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('lowerBound: $lowerBound, ')
          ..write('upperBound: $upperBound, ')
          ..write('unit: $unit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenceDependenciesTable extends EvidenceDependencies
    with TableInfo<$EvidenceDependenciesTable, EvidenceDependencyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenceDependenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
  );
  static const VerificationMeta _dependencyKindMeta = const VerificationMeta(
    'dependencyKind',
  );
  @override
  late final GeneratedColumn<String> dependencyKind = GeneratedColumn<String>(
    'dependency_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependencyIdMeta = const VerificationMeta(
    'dependencyId',
  );
  @override
  late final GeneratedColumn<String> dependencyId = GeneratedColumn<String>(
    'dependency_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependencyHashMeta = const VerificationMeta(
    'dependencyHash',
  );
  @override
  late final GeneratedColumn<String> dependencyHash = GeneratedColumn<String>(
    'dependency_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evidenceBundleId,
    dependencyKind,
    dependencyId,
    dependencyHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidence_dependencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenceDependencyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceBundleIdMeta);
    }
    if (data.containsKey('dependency_kind')) {
      context.handle(
        _dependencyKindMeta,
        dependencyKind.isAcceptableOrUnknown(
          data['dependency_kind']!,
          _dependencyKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyKindMeta);
    }
    if (data.containsKey('dependency_id')) {
      context.handle(
        _dependencyIdMeta,
        dependencyId.isAcceptableOrUnknown(
          data['dependency_id']!,
          _dependencyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyIdMeta);
    }
    if (data.containsKey('dependency_hash')) {
      context.handle(
        _dependencyHashMeta,
        dependencyHash.isAcceptableOrUnknown(
          data['dependency_hash']!,
          _dependencyHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenceDependencyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenceDependencyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      )!,
      dependencyKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_kind'],
      )!,
      dependencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_id'],
      )!,
      dependencyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_hash'],
      )!,
    );
  }

  @override
  $EvidenceDependenciesTable createAlias(String alias) {
    return $EvidenceDependenciesTable(attachedDatabase, alias);
  }
}

class EvidenceDependencyRow extends DataClass
    implements Insertable<EvidenceDependencyRow> {
  final String id;
  final String evidenceBundleId;
  final String dependencyKind;
  final String dependencyId;
  final String dependencyHash;
  const EvidenceDependencyRow({
    required this.id,
    required this.evidenceBundleId,
    required this.dependencyKind,
    required this.dependencyId,
    required this.dependencyHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    map['dependency_kind'] = Variable<String>(dependencyKind);
    map['dependency_id'] = Variable<String>(dependencyId);
    map['dependency_hash'] = Variable<String>(dependencyHash);
    return map;
  }

  EvidenceDependenciesCompanion toCompanion(bool nullToAbsent) {
    return EvidenceDependenciesCompanion(
      id: Value(id),
      evidenceBundleId: Value(evidenceBundleId),
      dependencyKind: Value(dependencyKind),
      dependencyId: Value(dependencyId),
      dependencyHash: Value(dependencyHash),
    );
  }

  factory EvidenceDependencyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenceDependencyRow(
      id: serializer.fromJson<String>(json['id']),
      evidenceBundleId: serializer.fromJson<String>(json['evidenceBundleId']),
      dependencyKind: serializer.fromJson<String>(json['dependencyKind']),
      dependencyId: serializer.fromJson<String>(json['dependencyId']),
      dependencyHash: serializer.fromJson<String>(json['dependencyHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evidenceBundleId': serializer.toJson<String>(evidenceBundleId),
      'dependencyKind': serializer.toJson<String>(dependencyKind),
      'dependencyId': serializer.toJson<String>(dependencyId),
      'dependencyHash': serializer.toJson<String>(dependencyHash),
    };
  }

  EvidenceDependencyRow copyWith({
    String? id,
    String? evidenceBundleId,
    String? dependencyKind,
    String? dependencyId,
    String? dependencyHash,
  }) => EvidenceDependencyRow(
    id: id ?? this.id,
    evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
    dependencyKind: dependencyKind ?? this.dependencyKind,
    dependencyId: dependencyId ?? this.dependencyId,
    dependencyHash: dependencyHash ?? this.dependencyHash,
  );
  EvidenceDependencyRow copyWithCompanion(EvidenceDependenciesCompanion data) {
    return EvidenceDependencyRow(
      id: data.id.present ? data.id.value : this.id,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      dependencyKind: data.dependencyKind.present
          ? data.dependencyKind.value
          : this.dependencyKind,
      dependencyId: data.dependencyId.present
          ? data.dependencyId.value
          : this.dependencyId,
      dependencyHash: data.dependencyHash.present
          ? data.dependencyHash.value
          : this.dependencyHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceDependencyRow(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('dependencyKind: $dependencyKind, ')
          ..write('dependencyId: $dependencyId, ')
          ..write('dependencyHash: $dependencyHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    evidenceBundleId,
    dependencyKind,
    dependencyId,
    dependencyHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceDependencyRow &&
          other.id == this.id &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.dependencyKind == this.dependencyKind &&
          other.dependencyId == this.dependencyId &&
          other.dependencyHash == this.dependencyHash);
}

class EvidenceDependenciesCompanion
    extends UpdateCompanion<EvidenceDependencyRow> {
  final Value<String> id;
  final Value<String> evidenceBundleId;
  final Value<String> dependencyKind;
  final Value<String> dependencyId;
  final Value<String> dependencyHash;
  final Value<int> rowid;
  const EvidenceDependenciesCompanion({
    this.id = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.dependencyKind = const Value.absent(),
    this.dependencyId = const Value.absent(),
    this.dependencyHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenceDependenciesCompanion.insert({
    required String id,
    required String evidenceBundleId,
    required String dependencyKind,
    required String dependencyId,
    required String dependencyHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       evidenceBundleId = Value(evidenceBundleId),
       dependencyKind = Value(dependencyKind),
       dependencyId = Value(dependencyId),
       dependencyHash = Value(dependencyHash);
  static Insertable<EvidenceDependencyRow> custom({
    Expression<String>? id,
    Expression<String>? evidenceBundleId,
    Expression<String>? dependencyKind,
    Expression<String>? dependencyId,
    Expression<String>? dependencyHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (dependencyKind != null) 'dependency_kind': dependencyKind,
      if (dependencyId != null) 'dependency_id': dependencyId,
      if (dependencyHash != null) 'dependency_hash': dependencyHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenceDependenciesCompanion copyWith({
    Value<String>? id,
    Value<String>? evidenceBundleId,
    Value<String>? dependencyKind,
    Value<String>? dependencyId,
    Value<String>? dependencyHash,
    Value<int>? rowid,
  }) {
    return EvidenceDependenciesCompanion(
      id: id ?? this.id,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      dependencyKind: dependencyKind ?? this.dependencyKind,
      dependencyId: dependencyId ?? this.dependencyId,
      dependencyHash: dependencyHash ?? this.dependencyHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (dependencyKind.present) {
      map['dependency_kind'] = Variable<String>(dependencyKind.value);
    }
    if (dependencyId.present) {
      map['dependency_id'] = Variable<String>(dependencyId.value);
    }
    if (dependencyHash.present) {
      map['dependency_hash'] = Variable<String>(dependencyHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceDependenciesCompanion(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('dependencyKind: $dependencyKind, ')
          ..write('dependencyId: $dependencyId, ')
          ..write('dependencyHash: $dependencyHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FindingVersionsTable extends FindingVersions
    with TableInfo<$FindingVersionsTable, FindingVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FindingVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _findingIdMeta = const VerificationMeta(
    'findingId',
  );
  @override
  late final GeneratedColumn<String> findingId = GeneratedColumn<String>(
    'finding_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
    'valid_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersedesIdMeta = const VerificationMeta(
    'supersedesId',
  );
  @override
  late final GeneratedColumn<String> supersedesId = GeneratedColumn<String>(
    'supersedes_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    findingId,
    evidenceBundleId,
    version,
    status,
    validFrom,
    validUntil,
    supersedesId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finding_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FindingVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('finding_id')) {
      context.handle(
        _findingIdMeta,
        findingId.isAcceptableOrUnknown(data['finding_id']!, _findingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_findingIdMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceBundleIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    }
    if (data.containsKey('supersedes_id')) {
      context.handle(
        _supersedesIdMeta,
        supersedesId.isAcceptableOrUnknown(
          data['supersedes_id']!,
          _supersedesIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FindingVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FindingVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      findingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finding_id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      )!,
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_until'],
      ),
      supersedesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supersedes_id'],
      ),
    );
  }

  @override
  $FindingVersionsTable createAlias(String alias) {
    return $FindingVersionsTable(attachedDatabase, alias);
  }
}

class FindingVersionRow extends DataClass
    implements Insertable<FindingVersionRow> {
  final String id;
  final String findingId;
  final String evidenceBundleId;
  final int version;
  final String status;
  final DateTime validFrom;
  final DateTime? validUntil;
  final String? supersedesId;
  const FindingVersionRow({
    required this.id,
    required this.findingId,
    required this.evidenceBundleId,
    required this.version,
    required this.status,
    required this.validFrom,
    this.validUntil,
    this.supersedesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['finding_id'] = Variable<String>(findingId);
    map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    map['version'] = Variable<int>(version);
    map['status'] = Variable<String>(status);
    map['valid_from'] = Variable<DateTime>(validFrom);
    if (!nullToAbsent || validUntil != null) {
      map['valid_until'] = Variable<DateTime>(validUntil);
    }
    if (!nullToAbsent || supersedesId != null) {
      map['supersedes_id'] = Variable<String>(supersedesId);
    }
    return map;
  }

  FindingVersionsCompanion toCompanion(bool nullToAbsent) {
    return FindingVersionsCompanion(
      id: Value(id),
      findingId: Value(findingId),
      evidenceBundleId: Value(evidenceBundleId),
      version: Value(version),
      status: Value(status),
      validFrom: Value(validFrom),
      validUntil: validUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(validUntil),
      supersedesId: supersedesId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesId),
    );
  }

  factory FindingVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FindingVersionRow(
      id: serializer.fromJson<String>(json['id']),
      findingId: serializer.fromJson<String>(json['findingId']),
      evidenceBundleId: serializer.fromJson<String>(json['evidenceBundleId']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      validFrom: serializer.fromJson<DateTime>(json['validFrom']),
      validUntil: serializer.fromJson<DateTime?>(json['validUntil']),
      supersedesId: serializer.fromJson<String?>(json['supersedesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'findingId': serializer.toJson<String>(findingId),
      'evidenceBundleId': serializer.toJson<String>(evidenceBundleId),
      'version': serializer.toJson<int>(version),
      'status': serializer.toJson<String>(status),
      'validFrom': serializer.toJson<DateTime>(validFrom),
      'validUntil': serializer.toJson<DateTime?>(validUntil),
      'supersedesId': serializer.toJson<String?>(supersedesId),
    };
  }

  FindingVersionRow copyWith({
    String? id,
    String? findingId,
    String? evidenceBundleId,
    int? version,
    String? status,
    DateTime? validFrom,
    Value<DateTime?> validUntil = const Value.absent(),
    Value<String?> supersedesId = const Value.absent(),
  }) => FindingVersionRow(
    id: id ?? this.id,
    findingId: findingId ?? this.findingId,
    evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
    version: version ?? this.version,
    status: status ?? this.status,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil.present ? validUntil.value : this.validUntil,
    supersedesId: supersedesId.present ? supersedesId.value : this.supersedesId,
  );
  FindingVersionRow copyWithCompanion(FindingVersionsCompanion data) {
    return FindingVersionRow(
      id: data.id.present ? data.id.value : this.id,
      findingId: data.findingId.present ? data.findingId.value : this.findingId,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      supersedesId: data.supersedesId.present
          ? data.supersedesId.value
          : this.supersedesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FindingVersionRow(')
          ..write('id: $id, ')
          ..write('findingId: $findingId, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('supersedesId: $supersedesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    findingId,
    evidenceBundleId,
    version,
    status,
    validFrom,
    validUntil,
    supersedesId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FindingVersionRow &&
          other.id == this.id &&
          other.findingId == this.findingId &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.version == this.version &&
          other.status == this.status &&
          other.validFrom == this.validFrom &&
          other.validUntil == this.validUntil &&
          other.supersedesId == this.supersedesId);
}

class FindingVersionsCompanion extends UpdateCompanion<FindingVersionRow> {
  final Value<String> id;
  final Value<String> findingId;
  final Value<String> evidenceBundleId;
  final Value<int> version;
  final Value<String> status;
  final Value<DateTime> validFrom;
  final Value<DateTime?> validUntil;
  final Value<String?> supersedesId;
  final Value<int> rowid;
  const FindingVersionsCompanion({
    this.id = const Value.absent(),
    this.findingId = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FindingVersionsCompanion.insert({
    required String id,
    required String findingId,
    required String evidenceBundleId,
    required int version,
    required String status,
    required DateTime validFrom,
    this.validUntil = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       findingId = Value(findingId),
       evidenceBundleId = Value(evidenceBundleId),
       version = Value(version),
       status = Value(status),
       validFrom = Value(validFrom);
  static Insertable<FindingVersionRow> custom({
    Expression<String>? id,
    Expression<String>? findingId,
    Expression<String>? evidenceBundleId,
    Expression<int>? version,
    Expression<String>? status,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? validUntil,
    Expression<String>? supersedesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (findingId != null) 'finding_id': findingId,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (validFrom != null) 'valid_from': validFrom,
      if (validUntil != null) 'valid_until': validUntil,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FindingVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? findingId,
    Value<String>? evidenceBundleId,
    Value<int>? version,
    Value<String>? status,
    Value<DateTime>? validFrom,
    Value<DateTime?>? validUntil,
    Value<String?>? supersedesId,
    Value<int>? rowid,
  }) {
    return FindingVersionsCompanion(
      id: id ?? this.id,
      findingId: findingId ?? this.findingId,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      version: version ?? this.version,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      supersedesId: supersedesId ?? this.supersedesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (findingId.present) {
      map['finding_id'] = Variable<String>(findingId.value);
    }
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (supersedesId.present) {
      map['supersedes_id'] = Variable<String>(supersedesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FindingVersionsCompanion(')
          ..write('id: $id, ')
          ..write('findingId: $findingId, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExplanationsTable extends Explanations
    with TableInfo<$ExplanationsTable, ExplanationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExplanationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
  );
  static const VerificationMeta _evidenceHashMeta = const VerificationMeta(
    'evidenceHash',
  );
  @override
  late final GeneratedColumn<String> evidenceHash = GeneratedColumn<String>(
    'evidence_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _intentMeta = const VerificationMeta('intent');
  @override
  late final GeneratedColumn<String> intent = GeneratedColumn<String>(
    'intent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('why_promoted'),
  );
  static const VerificationMeta _requestHashMeta = const VerificationMeta(
    'requestHash',
  );
  @override
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
    'request_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMeta = const VerificationMeta(
    'runtime',
  );
  @override
  late final GeneratedColumn<String> runtime = GeneratedColumn<String>(
    'runtime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _safetyStateMeta = const VerificationMeta(
    'safetyState',
  );
  @override
  late final GeneratedColumn<String> safetyState = GeneratedColumn<String>(
    'safety_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _safetyFailuresJsonMeta =
      const VerificationMeta('safetyFailuresJson');
  @override
  late final GeneratedColumn<String> safetyFailuresJson =
      GeneratedColumn<String>(
        'safety_failures_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<int> promptVersion = GeneratedColumn<int>(
    'prompt_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputGuardVersionMeta =
      const VerificationMeta('outputGuardVersion');
  @override
  late final GeneratedColumn<int> outputGuardVersion = GeneratedColumn<int>(
    'output_guard_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMillisMeta = const VerificationMeta(
    'latencyMillis',
  );
  @override
  late final GeneratedColumn<int> latencyMillis = GeneratedColumn<int>(
    'latency_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _schemaValidMeta = const VerificationMeta(
    'schemaValid',
  );
  @override
  late final GeneratedColumn<bool> schemaValid = GeneratedColumn<bool>(
    'schema_valid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("schema_valid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evidenceBundleId,
    evidenceHash,
    intent,
    requestHash,
    runtime,
    modelName,
    content,
    safetyState,
    safetyFailuresJson,
    failureCode,
    promptVersion,
    outputGuardVersion,
    latencyMillis,
    schemaValid,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'explanations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExplanationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceBundleIdMeta);
    }
    if (data.containsKey('evidence_hash')) {
      context.handle(
        _evidenceHashMeta,
        evidenceHash.isAcceptableOrUnknown(
          data['evidence_hash']!,
          _evidenceHashMeta,
        ),
      );
    }
    if (data.containsKey('intent')) {
      context.handle(
        _intentMeta,
        intent.isAcceptableOrUnknown(data['intent']!, _intentMeta),
      );
    }
    if (data.containsKey('request_hash')) {
      context.handle(
        _requestHashMeta,
        requestHash.isAcceptableOrUnknown(
          data['request_hash']!,
          _requestHashMeta,
        ),
      );
    }
    if (data.containsKey('runtime')) {
      context.handle(
        _runtimeMeta,
        runtime.isAcceptableOrUnknown(data['runtime']!, _runtimeMeta),
      );
    } else if (isInserting) {
      context.missing(_runtimeMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('safety_state')) {
      context.handle(
        _safetyStateMeta,
        safetyState.isAcceptableOrUnknown(
          data['safety_state']!,
          _safetyStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_safetyStateMeta);
    }
    if (data.containsKey('safety_failures_json')) {
      context.handle(
        _safetyFailuresJsonMeta,
        safetyFailuresJson.isAcceptableOrUnknown(
          data['safety_failures_json']!,
          _safetyFailuresJsonMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promptVersionMeta);
    }
    if (data.containsKey('output_guard_version')) {
      context.handle(
        _outputGuardVersionMeta,
        outputGuardVersion.isAcceptableOrUnknown(
          data['output_guard_version']!,
          _outputGuardVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outputGuardVersionMeta);
    }
    if (data.containsKey('latency_millis')) {
      context.handle(
        _latencyMillisMeta,
        latencyMillis.isAcceptableOrUnknown(
          data['latency_millis']!,
          _latencyMillisMeta,
        ),
      );
    }
    if (data.containsKey('schema_valid')) {
      context.handle(
        _schemaValidMeta,
        schemaValid.isAcceptableOrUnknown(
          data['schema_valid']!,
          _schemaValidMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExplanationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExplanationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      )!,
      evidenceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_hash'],
      )!,
      intent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intent'],
      )!,
      requestHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_hash'],
      ),
      runtime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}runtime'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      safetyState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safety_state'],
      )!,
      safetyFailuresJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safety_failures_json'],
      )!,
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_version'],
      )!,
      outputGuardVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_guard_version'],
      )!,
      latencyMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_millis'],
      )!,
      schemaValid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}schema_valid'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExplanationsTable createAlias(String alias) {
    return $ExplanationsTable(attachedDatabase, alias);
  }
}

class ExplanationRow extends DataClass implements Insertable<ExplanationRow> {
  final String id;
  final String evidenceBundleId;
  final String evidenceHash;
  final String intent;
  final String? requestHash;
  final String runtime;
  final String modelName;
  final String content;
  final String safetyState;
  final String safetyFailuresJson;
  final String? failureCode;
  final int promptVersion;
  final int outputGuardVersion;
  final int latencyMillis;
  final bool schemaValid;
  final DateTime createdAt;
  const ExplanationRow({
    required this.id,
    required this.evidenceBundleId,
    required this.evidenceHash,
    required this.intent,
    this.requestHash,
    required this.runtime,
    required this.modelName,
    required this.content,
    required this.safetyState,
    required this.safetyFailuresJson,
    this.failureCode,
    required this.promptVersion,
    required this.outputGuardVersion,
    required this.latencyMillis,
    required this.schemaValid,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    map['evidence_hash'] = Variable<String>(evidenceHash);
    map['intent'] = Variable<String>(intent);
    if (!nullToAbsent || requestHash != null) {
      map['request_hash'] = Variable<String>(requestHash);
    }
    map['runtime'] = Variable<String>(runtime);
    map['model_name'] = Variable<String>(modelName);
    map['content'] = Variable<String>(content);
    map['safety_state'] = Variable<String>(safetyState);
    map['safety_failures_json'] = Variable<String>(safetyFailuresJson);
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    map['prompt_version'] = Variable<int>(promptVersion);
    map['output_guard_version'] = Variable<int>(outputGuardVersion);
    map['latency_millis'] = Variable<int>(latencyMillis);
    map['schema_valid'] = Variable<bool>(schemaValid);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExplanationsCompanion toCompanion(bool nullToAbsent) {
    return ExplanationsCompanion(
      id: Value(id),
      evidenceBundleId: Value(evidenceBundleId),
      evidenceHash: Value(evidenceHash),
      intent: Value(intent),
      requestHash: requestHash == null && nullToAbsent
          ? const Value.absent()
          : Value(requestHash),
      runtime: Value(runtime),
      modelName: Value(modelName),
      content: Value(content),
      safetyState: Value(safetyState),
      safetyFailuresJson: Value(safetyFailuresJson),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      promptVersion: Value(promptVersion),
      outputGuardVersion: Value(outputGuardVersion),
      latencyMillis: Value(latencyMillis),
      schemaValid: Value(schemaValid),
      createdAt: Value(createdAt),
    );
  }

  factory ExplanationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExplanationRow(
      id: serializer.fromJson<String>(json['id']),
      evidenceBundleId: serializer.fromJson<String>(json['evidenceBundleId']),
      evidenceHash: serializer.fromJson<String>(json['evidenceHash']),
      intent: serializer.fromJson<String>(json['intent']),
      requestHash: serializer.fromJson<String?>(json['requestHash']),
      runtime: serializer.fromJson<String>(json['runtime']),
      modelName: serializer.fromJson<String>(json['modelName']),
      content: serializer.fromJson<String>(json['content']),
      safetyState: serializer.fromJson<String>(json['safetyState']),
      safetyFailuresJson: serializer.fromJson<String>(
        json['safetyFailuresJson'],
      ),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      promptVersion: serializer.fromJson<int>(json['promptVersion']),
      outputGuardVersion: serializer.fromJson<int>(json['outputGuardVersion']),
      latencyMillis: serializer.fromJson<int>(json['latencyMillis']),
      schemaValid: serializer.fromJson<bool>(json['schemaValid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evidenceBundleId': serializer.toJson<String>(evidenceBundleId),
      'evidenceHash': serializer.toJson<String>(evidenceHash),
      'intent': serializer.toJson<String>(intent),
      'requestHash': serializer.toJson<String?>(requestHash),
      'runtime': serializer.toJson<String>(runtime),
      'modelName': serializer.toJson<String>(modelName),
      'content': serializer.toJson<String>(content),
      'safetyState': serializer.toJson<String>(safetyState),
      'safetyFailuresJson': serializer.toJson<String>(safetyFailuresJson),
      'failureCode': serializer.toJson<String?>(failureCode),
      'promptVersion': serializer.toJson<int>(promptVersion),
      'outputGuardVersion': serializer.toJson<int>(outputGuardVersion),
      'latencyMillis': serializer.toJson<int>(latencyMillis),
      'schemaValid': serializer.toJson<bool>(schemaValid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExplanationRow copyWith({
    String? id,
    String? evidenceBundleId,
    String? evidenceHash,
    String? intent,
    Value<String?> requestHash = const Value.absent(),
    String? runtime,
    String? modelName,
    String? content,
    String? safetyState,
    String? safetyFailuresJson,
    Value<String?> failureCode = const Value.absent(),
    int? promptVersion,
    int? outputGuardVersion,
    int? latencyMillis,
    bool? schemaValid,
    DateTime? createdAt,
  }) => ExplanationRow(
    id: id ?? this.id,
    evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
    evidenceHash: evidenceHash ?? this.evidenceHash,
    intent: intent ?? this.intent,
    requestHash: requestHash.present ? requestHash.value : this.requestHash,
    runtime: runtime ?? this.runtime,
    modelName: modelName ?? this.modelName,
    content: content ?? this.content,
    safetyState: safetyState ?? this.safetyState,
    safetyFailuresJson: safetyFailuresJson ?? this.safetyFailuresJson,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    promptVersion: promptVersion ?? this.promptVersion,
    outputGuardVersion: outputGuardVersion ?? this.outputGuardVersion,
    latencyMillis: latencyMillis ?? this.latencyMillis,
    schemaValid: schemaValid ?? this.schemaValid,
    createdAt: createdAt ?? this.createdAt,
  );
  ExplanationRow copyWithCompanion(ExplanationsCompanion data) {
    return ExplanationRow(
      id: data.id.present ? data.id.value : this.id,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      evidenceHash: data.evidenceHash.present
          ? data.evidenceHash.value
          : this.evidenceHash,
      intent: data.intent.present ? data.intent.value : this.intent,
      requestHash: data.requestHash.present
          ? data.requestHash.value
          : this.requestHash,
      runtime: data.runtime.present ? data.runtime.value : this.runtime,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      content: data.content.present ? data.content.value : this.content,
      safetyState: data.safetyState.present
          ? data.safetyState.value
          : this.safetyState,
      safetyFailuresJson: data.safetyFailuresJson.present
          ? data.safetyFailuresJson.value
          : this.safetyFailuresJson,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      outputGuardVersion: data.outputGuardVersion.present
          ? data.outputGuardVersion.value
          : this.outputGuardVersion,
      latencyMillis: data.latencyMillis.present
          ? data.latencyMillis.value
          : this.latencyMillis,
      schemaValid: data.schemaValid.present
          ? data.schemaValid.value
          : this.schemaValid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExplanationRow(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('intent: $intent, ')
          ..write('requestHash: $requestHash, ')
          ..write('runtime: $runtime, ')
          ..write('modelName: $modelName, ')
          ..write('content: $content, ')
          ..write('safetyState: $safetyState, ')
          ..write('safetyFailuresJson: $safetyFailuresJson, ')
          ..write('failureCode: $failureCode, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('outputGuardVersion: $outputGuardVersion, ')
          ..write('latencyMillis: $latencyMillis, ')
          ..write('schemaValid: $schemaValid, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    evidenceBundleId,
    evidenceHash,
    intent,
    requestHash,
    runtime,
    modelName,
    content,
    safetyState,
    safetyFailuresJson,
    failureCode,
    promptVersion,
    outputGuardVersion,
    latencyMillis,
    schemaValid,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExplanationRow &&
          other.id == this.id &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.evidenceHash == this.evidenceHash &&
          other.intent == this.intent &&
          other.requestHash == this.requestHash &&
          other.runtime == this.runtime &&
          other.modelName == this.modelName &&
          other.content == this.content &&
          other.safetyState == this.safetyState &&
          other.safetyFailuresJson == this.safetyFailuresJson &&
          other.failureCode == this.failureCode &&
          other.promptVersion == this.promptVersion &&
          other.outputGuardVersion == this.outputGuardVersion &&
          other.latencyMillis == this.latencyMillis &&
          other.schemaValid == this.schemaValid &&
          other.createdAt == this.createdAt);
}

class ExplanationsCompanion extends UpdateCompanion<ExplanationRow> {
  final Value<String> id;
  final Value<String> evidenceBundleId;
  final Value<String> evidenceHash;
  final Value<String> intent;
  final Value<String?> requestHash;
  final Value<String> runtime;
  final Value<String> modelName;
  final Value<String> content;
  final Value<String> safetyState;
  final Value<String> safetyFailuresJson;
  final Value<String?> failureCode;
  final Value<int> promptVersion;
  final Value<int> outputGuardVersion;
  final Value<int> latencyMillis;
  final Value<bool> schemaValid;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExplanationsCompanion({
    this.id = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.evidenceHash = const Value.absent(),
    this.intent = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.runtime = const Value.absent(),
    this.modelName = const Value.absent(),
    this.content = const Value.absent(),
    this.safetyState = const Value.absent(),
    this.safetyFailuresJson = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.outputGuardVersion = const Value.absent(),
    this.latencyMillis = const Value.absent(),
    this.schemaValid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExplanationsCompanion.insert({
    required String id,
    required String evidenceBundleId,
    this.evidenceHash = const Value.absent(),
    this.intent = const Value.absent(),
    this.requestHash = const Value.absent(),
    required String runtime,
    this.modelName = const Value.absent(),
    required String content,
    required String safetyState,
    this.safetyFailuresJson = const Value.absent(),
    this.failureCode = const Value.absent(),
    required int promptVersion,
    required int outputGuardVersion,
    this.latencyMillis = const Value.absent(),
    this.schemaValid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       evidenceBundleId = Value(evidenceBundleId),
       runtime = Value(runtime),
       content = Value(content),
       safetyState = Value(safetyState),
       promptVersion = Value(promptVersion),
       outputGuardVersion = Value(outputGuardVersion);
  static Insertable<ExplanationRow> custom({
    Expression<String>? id,
    Expression<String>? evidenceBundleId,
    Expression<String>? evidenceHash,
    Expression<String>? intent,
    Expression<String>? requestHash,
    Expression<String>? runtime,
    Expression<String>? modelName,
    Expression<String>? content,
    Expression<String>? safetyState,
    Expression<String>? safetyFailuresJson,
    Expression<String>? failureCode,
    Expression<int>? promptVersion,
    Expression<int>? outputGuardVersion,
    Expression<int>? latencyMillis,
    Expression<bool>? schemaValid,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (evidenceHash != null) 'evidence_hash': evidenceHash,
      if (intent != null) 'intent': intent,
      if (requestHash != null) 'request_hash': requestHash,
      if (runtime != null) 'runtime': runtime,
      if (modelName != null) 'model_name': modelName,
      if (content != null) 'content': content,
      if (safetyState != null) 'safety_state': safetyState,
      if (safetyFailuresJson != null)
        'safety_failures_json': safetyFailuresJson,
      if (failureCode != null) 'failure_code': failureCode,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (outputGuardVersion != null)
        'output_guard_version': outputGuardVersion,
      if (latencyMillis != null) 'latency_millis': latencyMillis,
      if (schemaValid != null) 'schema_valid': schemaValid,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExplanationsCompanion copyWith({
    Value<String>? id,
    Value<String>? evidenceBundleId,
    Value<String>? evidenceHash,
    Value<String>? intent,
    Value<String?>? requestHash,
    Value<String>? runtime,
    Value<String>? modelName,
    Value<String>? content,
    Value<String>? safetyState,
    Value<String>? safetyFailuresJson,
    Value<String?>? failureCode,
    Value<int>? promptVersion,
    Value<int>? outputGuardVersion,
    Value<int>? latencyMillis,
    Value<bool>? schemaValid,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ExplanationsCompanion(
      id: id ?? this.id,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      intent: intent ?? this.intent,
      requestHash: requestHash ?? this.requestHash,
      runtime: runtime ?? this.runtime,
      modelName: modelName ?? this.modelName,
      content: content ?? this.content,
      safetyState: safetyState ?? this.safetyState,
      safetyFailuresJson: safetyFailuresJson ?? this.safetyFailuresJson,
      failureCode: failureCode ?? this.failureCode,
      promptVersion: promptVersion ?? this.promptVersion,
      outputGuardVersion: outputGuardVersion ?? this.outputGuardVersion,
      latencyMillis: latencyMillis ?? this.latencyMillis,
      schemaValid: schemaValid ?? this.schemaValid,
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
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (evidenceHash.present) {
      map['evidence_hash'] = Variable<String>(evidenceHash.value);
    }
    if (intent.present) {
      map['intent'] = Variable<String>(intent.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (runtime.present) {
      map['runtime'] = Variable<String>(runtime.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (safetyState.present) {
      map['safety_state'] = Variable<String>(safetyState.value);
    }
    if (safetyFailuresJson.present) {
      map['safety_failures_json'] = Variable<String>(safetyFailuresJson.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<int>(promptVersion.value);
    }
    if (outputGuardVersion.present) {
      map['output_guard_version'] = Variable<int>(outputGuardVersion.value);
    }
    if (latencyMillis.present) {
      map['latency_millis'] = Variable<int>(latencyMillis.value);
    }
    if (schemaValid.present) {
      map['schema_valid'] = Variable<bool>(schemaValid.value);
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
    return (StringBuffer('ExplanationsCompanion(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('intent: $intent, ')
          ..write('requestHash: $requestHash, ')
          ..write('runtime: $runtime, ')
          ..write('modelName: $modelName, ')
          ..write('content: $content, ')
          ..write('safetyState: $safetyState, ')
          ..write('safetyFailuresJson: $safetyFailuresJson, ')
          ..write('failureCode: $failureCode, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('outputGuardVersion: $outputGuardVersion, ')
          ..write('latencyMillis: $latencyMillis, ')
          ..write('schemaValid: $schemaValid, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evidenceBundleId,
    createdAt,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceBundleIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSessionRow extends DataClass implements Insertable<ChatSessionRow> {
  final String id;
  final String evidenceBundleId;
  final DateTime createdAt;
  final DateTime? closedAt;
  const ChatSessionRow({
    required this.id,
    required this.evidenceBundleId,
    required this.createdAt,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      evidenceBundleId: Value(evidenceBundleId),
      createdAt: Value(createdAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory ChatSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionRow(
      id: serializer.fromJson<String>(json['id']),
      evidenceBundleId: serializer.fromJson<String>(json['evidenceBundleId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evidenceBundleId': serializer.toJson<String>(evidenceBundleId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  ChatSessionRow copyWith({
    String? id,
    String? evidenceBundleId,
    DateTime? createdAt,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => ChatSessionRow(
    id: id ?? this.id,
    evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
    createdAt: createdAt ?? this.createdAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  ChatSessionRow copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionRow(
      id: data.id.present ? data.id.value : this.id,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionRow(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, evidenceBundleId, createdAt, closedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionRow &&
          other.id == this.id &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.createdAt == this.createdAt &&
          other.closedAt == this.closedAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionRow> {
  final Value<String> id;
  final Value<String> evidenceBundleId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> closedAt;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String evidenceBundleId,
    this.createdAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       evidenceBundleId = Value(evidenceBundleId);
  static Insertable<ChatSessionRow> custom({
    Expression<String>? id,
    Expression<String>? evidenceBundleId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (createdAt != null) 'created_at': createdAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? evidenceBundleId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? closedAt,
    Value<int>? rowid,
  }) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatSessionIdMeta = const VerificationMeta(
    'chatSessionId',
  );
  @override
  late final GeneratedColumn<String> chatSessionId = GeneratedColumn<String>(
    'chat_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chat_sessions (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _safetyStateMeta = const VerificationMeta(
    'safetyState',
  );
  @override
  late final GeneratedColumn<String> safetyState = GeneratedColumn<String>(
    'safety_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatSessionId,
    role,
    content,
    safetyState,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_session_id')) {
      context.handle(
        _chatSessionIdMeta,
        chatSessionId.isAcceptableOrUnknown(
          data['chat_session_id']!,
          _chatSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chatSessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('safety_state')) {
      context.handle(
        _safetyStateMeta,
        safetyState.isAcceptableOrUnknown(
          data['safety_state']!,
          _safetyStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_safetyStateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chatSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_session_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      safetyState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safety_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String chatSessionId;
  final String role;
  final String content;
  final String safetyState;
  final DateTime createdAt;
  const ChatMessageRow({
    required this.id,
    required this.chatSessionId,
    required this.role,
    required this.content,
    required this.safetyState,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_session_id'] = Variable<String>(chatSessionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['safety_state'] = Variable<String>(safetyState);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      chatSessionId: Value(chatSessionId),
      role: Value(role),
      content: Value(content),
      safetyState: Value(safetyState),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      chatSessionId: serializer.fromJson<String>(json['chatSessionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      safetyState: serializer.fromJson<String>(json['safetyState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatSessionId': serializer.toJson<String>(chatSessionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'safetyState': serializer.toJson<String>(safetyState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    String? chatSessionId,
    String? role,
    String? content,
    String? safetyState,
    DateTime? createdAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    chatSessionId: chatSessionId ?? this.chatSessionId,
    role: role ?? this.role,
    content: content ?? this.content,
    safetyState: safetyState ?? this.safetyState,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      chatSessionId: data.chatSessionId.present
          ? data.chatSessionId.value
          : this.chatSessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      safetyState: data.safetyState.present
          ? data.safetyState.value
          : this.safetyState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('chatSessionId: $chatSessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('safetyState: $safetyState, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, chatSessionId, role, content, safetyState, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.chatSessionId == this.chatSessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.safetyState == this.safetyState &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> chatSessionId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> safetyState;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.chatSessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.safetyState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String chatSessionId,
    required String role,
    required String content,
    required String safetyState,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chatSessionId = Value(chatSessionId),
       role = Value(role),
       content = Value(content),
       safetyState = Value(safetyState);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? chatSessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? safetyState,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatSessionId != null) 'chat_session_id': chatSessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (safetyState != null) 'safety_state': safetyState,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? chatSessionId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? safetyState,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      chatSessionId: chatSessionId ?? this.chatSessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      safetyState: safetyState ?? this.safetyState,
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
    if (chatSessionId.present) {
      map['chat_session_id'] = Variable<String>(chatSessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (safetyState.present) {
      map['safety_state'] = Variable<String>(safetyState.value);
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
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('chatSessionId: $chatSessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('safetyState: $safetyState, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExperimentProtocolsTable extends ExperimentProtocols
    with TableInfo<$ExperimentProtocolsTable, ExperimentProtocolRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentProtocolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceBundleIdMeta = const VerificationMeta(
    'evidenceBundleId',
  );
  @override
  late final GeneratedColumn<String> evidenceBundleId = GeneratedColumn<String>(
    'evidence_bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES evidence_bundles (id)',
    ),
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolJsonMeta = const VerificationMeta(
    'protocolJson',
  );
  @override
  late final GeneratedColumn<String> protocolJson = GeneratedColumn<String>(
    'protocol_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evidenceBundleId,
    title,
    status,
    protocolJson,
    version,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experiment_protocols';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentProtocolRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evidence_bundle_id')) {
      context.handle(
        _evidenceBundleIdMeta,
        evidenceBundleId.isAcceptableOrUnknown(
          data['evidence_bundle_id']!,
          _evidenceBundleIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('protocol_json')) {
      context.handle(
        _protocolJsonMeta,
        protocolJson.isAcceptableOrUnknown(
          data['protocol_json']!,
          _protocolJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolJsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExperimentProtocolRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentProtocolRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      evidenceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_bundle_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      protocolJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExperimentProtocolsTable createAlias(String alias) {
    return $ExperimentProtocolsTable(attachedDatabase, alias);
  }
}

class ExperimentProtocolRow extends DataClass
    implements Insertable<ExperimentProtocolRow> {
  final String id;
  final String? evidenceBundleId;
  final String title;
  final String status;
  final String protocolJson;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExperimentProtocolRow({
    required this.id,
    this.evidenceBundleId,
    required this.title,
    required this.status,
    required this.protocolJson,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || evidenceBundleId != null) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId);
    }
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['protocol_json'] = Variable<String>(protocolJson);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExperimentProtocolsCompanion toCompanion(bool nullToAbsent) {
    return ExperimentProtocolsCompanion(
      id: Value(id),
      evidenceBundleId: evidenceBundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceBundleId),
      title: Value(title),
      status: Value(status),
      protocolJson: Value(protocolJson),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExperimentProtocolRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentProtocolRow(
      id: serializer.fromJson<String>(json['id']),
      evidenceBundleId: serializer.fromJson<String?>(json['evidenceBundleId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      protocolJson: serializer.fromJson<String>(json['protocolJson']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evidenceBundleId': serializer.toJson<String?>(evidenceBundleId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'protocolJson': serializer.toJson<String>(protocolJson),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExperimentProtocolRow copyWith({
    String? id,
    Value<String?> evidenceBundleId = const Value.absent(),
    String? title,
    String? status,
    String? protocolJson,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExperimentProtocolRow(
    id: id ?? this.id,
    evidenceBundleId: evidenceBundleId.present
        ? evidenceBundleId.value
        : this.evidenceBundleId,
    title: title ?? this.title,
    status: status ?? this.status,
    protocolJson: protocolJson ?? this.protocolJson,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExperimentProtocolRow copyWithCompanion(ExperimentProtocolsCompanion data) {
    return ExperimentProtocolRow(
      id: data.id.present ? data.id.value : this.id,
      evidenceBundleId: data.evidenceBundleId.present
          ? data.evidenceBundleId.value
          : this.evidenceBundleId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      protocolJson: data.protocolJson.present
          ? data.protocolJson.value
          : this.protocolJson,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentProtocolRow(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('protocolJson: $protocolJson, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    evidenceBundleId,
    title,
    status,
    protocolJson,
    version,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentProtocolRow &&
          other.id == this.id &&
          other.evidenceBundleId == this.evidenceBundleId &&
          other.title == this.title &&
          other.status == this.status &&
          other.protocolJson == this.protocolJson &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExperimentProtocolsCompanion
    extends UpdateCompanion<ExperimentProtocolRow> {
  final Value<String> id;
  final Value<String?> evidenceBundleId;
  final Value<String> title;
  final Value<String> status;
  final Value<String> protocolJson;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExperimentProtocolsCompanion({
    this.id = const Value.absent(),
    this.evidenceBundleId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.protocolJson = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentProtocolsCompanion.insert({
    required String id,
    this.evidenceBundleId = const Value.absent(),
    required String title,
    required String status,
    required String protocolJson,
    required int version,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       status = Value(status),
       protocolJson = Value(protocolJson),
       version = Value(version);
  static Insertable<ExperimentProtocolRow> custom({
    Expression<String>? id,
    Expression<String>? evidenceBundleId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? protocolJson,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evidenceBundleId != null) 'evidence_bundle_id': evidenceBundleId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (protocolJson != null) 'protocol_json': protocolJson,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentProtocolsCompanion copyWith({
    Value<String>? id,
    Value<String?>? evidenceBundleId,
    Value<String>? title,
    Value<String>? status,
    Value<String>? protocolJson,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExperimentProtocolsCompanion(
      id: id ?? this.id,
      evidenceBundleId: evidenceBundleId ?? this.evidenceBundleId,
      title: title ?? this.title,
      status: status ?? this.status,
      protocolJson: protocolJson ?? this.protocolJson,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (evidenceBundleId.present) {
      map['evidence_bundle_id'] = Variable<String>(evidenceBundleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (protocolJson.present) {
      map['protocol_json'] = Variable<String>(protocolJson.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentProtocolsCompanion(')
          ..write('id: $id, ')
          ..write('evidenceBundleId: $evidenceBundleId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('protocolJson: $protocolJson, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExperimentOccurrencesTable extends ExperimentOccurrences
    with TableInfo<$ExperimentOccurrencesTable, ExperimentOccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _experimentProtocolIdMeta =
      const VerificationMeta('experimentProtocolId');
  @override
  late final GeneratedColumn<String> experimentProtocolId =
      GeneratedColumn<String>(
        'experiment_protocol_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES experiment_protocols (id)',
        ),
      );
  static const VerificationMeta _scheduledAtUtcMeta = const VerificationMeta(
    'scheduledAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAtUtc =
      GeneratedColumn<DateTime>(
        'scheduled_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> completedAtUtc =
      GeneratedColumn<DateTime>(
        'completed_at_utc',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    experimentProtocolId,
    scheduledAtUtc,
    completedAtUtc,
    status,
    contextJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experiment_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentOccurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('experiment_protocol_id')) {
      context.handle(
        _experimentProtocolIdMeta,
        experimentProtocolId.isAcceptableOrUnknown(
          data['experiment_protocol_id']!,
          _experimentProtocolIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experimentProtocolIdMeta);
    }
    if (data.containsKey('scheduled_at_utc')) {
      context.handle(
        _scheduledAtUtcMeta,
        scheduledAtUtc.isAcceptableOrUnknown(
          data['scheduled_at_utc']!,
          _scheduledAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtUtcMeta);
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExperimentOccurrenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentOccurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      experimentProtocolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experiment_protocol_id'],
      )!,
      scheduledAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at_utc'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at_utc'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      )!,
    );
  }

  @override
  $ExperimentOccurrencesTable createAlias(String alias) {
    return $ExperimentOccurrencesTable(attachedDatabase, alias);
  }
}

class ExperimentOccurrenceRow extends DataClass
    implements Insertable<ExperimentOccurrenceRow> {
  final String id;
  final String experimentProtocolId;
  final DateTime scheduledAtUtc;
  final DateTime? completedAtUtc;
  final String status;
  final String contextJson;
  const ExperimentOccurrenceRow({
    required this.id,
    required this.experimentProtocolId,
    required this.scheduledAtUtc,
    this.completedAtUtc,
    required this.status,
    required this.contextJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['experiment_protocol_id'] = Variable<String>(experimentProtocolId);
    map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc);
    if (!nullToAbsent || completedAtUtc != null) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc);
    }
    map['status'] = Variable<String>(status);
    map['context_json'] = Variable<String>(contextJson);
    return map;
  }

  ExperimentOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return ExperimentOccurrencesCompanion(
      id: Value(id),
      experimentProtocolId: Value(experimentProtocolId),
      scheduledAtUtc: Value(scheduledAtUtc),
      completedAtUtc: completedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtc),
      status: Value(status),
      contextJson: Value(contextJson),
    );
  }

  factory ExperimentOccurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentOccurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      experimentProtocolId: serializer.fromJson<String>(
        json['experimentProtocolId'],
      ),
      scheduledAtUtc: serializer.fromJson<DateTime>(json['scheduledAtUtc']),
      completedAtUtc: serializer.fromJson<DateTime?>(json['completedAtUtc']),
      status: serializer.fromJson<String>(json['status']),
      contextJson: serializer.fromJson<String>(json['contextJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'experimentProtocolId': serializer.toJson<String>(experimentProtocolId),
      'scheduledAtUtc': serializer.toJson<DateTime>(scheduledAtUtc),
      'completedAtUtc': serializer.toJson<DateTime?>(completedAtUtc),
      'status': serializer.toJson<String>(status),
      'contextJson': serializer.toJson<String>(contextJson),
    };
  }

  ExperimentOccurrenceRow copyWith({
    String? id,
    String? experimentProtocolId,
    DateTime? scheduledAtUtc,
    Value<DateTime?> completedAtUtc = const Value.absent(),
    String? status,
    String? contextJson,
  }) => ExperimentOccurrenceRow(
    id: id ?? this.id,
    experimentProtocolId: experimentProtocolId ?? this.experimentProtocolId,
    scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
    completedAtUtc: completedAtUtc.present
        ? completedAtUtc.value
        : this.completedAtUtc,
    status: status ?? this.status,
    contextJson: contextJson ?? this.contextJson,
  );
  ExperimentOccurrenceRow copyWithCompanion(
    ExperimentOccurrencesCompanion data,
  ) {
    return ExperimentOccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      experimentProtocolId: data.experimentProtocolId.present
          ? data.experimentProtocolId.value
          : this.experimentProtocolId,
      scheduledAtUtc: data.scheduledAtUtc.present
          ? data.scheduledAtUtc.value
          : this.scheduledAtUtc,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
      status: data.status.present ? data.status.value : this.status,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentOccurrenceRow(')
          ..write('id: $id, ')
          ..write('experimentProtocolId: $experimentProtocolId, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('status: $status, ')
          ..write('contextJson: $contextJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    experimentProtocolId,
    scheduledAtUtc,
    completedAtUtc,
    status,
    contextJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentOccurrenceRow &&
          other.id == this.id &&
          other.experimentProtocolId == this.experimentProtocolId &&
          other.scheduledAtUtc == this.scheduledAtUtc &&
          other.completedAtUtc == this.completedAtUtc &&
          other.status == this.status &&
          other.contextJson == this.contextJson);
}

class ExperimentOccurrencesCompanion
    extends UpdateCompanion<ExperimentOccurrenceRow> {
  final Value<String> id;
  final Value<String> experimentProtocolId;
  final Value<DateTime> scheduledAtUtc;
  final Value<DateTime?> completedAtUtc;
  final Value<String> status;
  final Value<String> contextJson;
  final Value<int> rowid;
  const ExperimentOccurrencesCompanion({
    this.id = const Value.absent(),
    this.experimentProtocolId = const Value.absent(),
    this.scheduledAtUtc = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.status = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentOccurrencesCompanion.insert({
    required String id,
    required String experimentProtocolId,
    required DateTime scheduledAtUtc,
    this.completedAtUtc = const Value.absent(),
    required String status,
    required String contextJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       experimentProtocolId = Value(experimentProtocolId),
       scheduledAtUtc = Value(scheduledAtUtc),
       status = Value(status),
       contextJson = Value(contextJson);
  static Insertable<ExperimentOccurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? experimentProtocolId,
    Expression<DateTime>? scheduledAtUtc,
    Expression<DateTime>? completedAtUtc,
    Expression<String>? status,
    Expression<String>? contextJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (experimentProtocolId != null)
        'experiment_protocol_id': experimentProtocolId,
      if (scheduledAtUtc != null) 'scheduled_at_utc': scheduledAtUtc,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (status != null) 'status': status,
      if (contextJson != null) 'context_json': contextJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? experimentProtocolId,
    Value<DateTime>? scheduledAtUtc,
    Value<DateTime?>? completedAtUtc,
    Value<String>? status,
    Value<String>? contextJson,
    Value<int>? rowid,
  }) {
    return ExperimentOccurrencesCompanion(
      id: id ?? this.id,
      experimentProtocolId: experimentProtocolId ?? this.experimentProtocolId,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      status: status ?? this.status,
      contextJson: contextJson ?? this.contextJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (experimentProtocolId.present) {
      map['experiment_protocol_id'] = Variable<String>(
        experimentProtocolId.value,
      );
    }
    if (scheduledAtUtc.present) {
      map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc.value);
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('experimentProtocolId: $experimentProtocolId, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('status: $status, ')
          ..write('contextJson: $contextJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdherenceCheckinsTable extends AdherenceCheckins
    with TableInfo<$AdherenceCheckinsTable, AdherenceCheckinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdherenceCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _experimentOccurrenceIdMeta =
      const VerificationMeta('experimentOccurrenceId');
  @override
  late final GeneratedColumn<String> experimentOccurrenceId =
      GeneratedColumn<String>(
        'experiment_occurrence_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES experiment_occurrences (id)',
        ),
      );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtUtcMeta = const VerificationMeta(
    'recordedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAtUtc =
      GeneratedColumn<DateTime>(
        'recorded_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    experimentOccurrenceId,
    responseJson,
    recordedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adherence_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdherenceCheckinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('experiment_occurrence_id')) {
      context.handle(
        _experimentOccurrenceIdMeta,
        experimentOccurrenceId.isAcceptableOrUnknown(
          data['experiment_occurrence_id']!,
          _experimentOccurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experimentOccurrenceIdMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('recorded_at_utc')) {
      context.handle(
        _recordedAtUtcMeta,
        recordedAtUtc.isAcceptableOrUnknown(
          data['recorded_at_utc']!,
          _recordedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdherenceCheckinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdherenceCheckinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      experimentOccurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experiment_occurrence_id'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      recordedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at_utc'],
      )!,
    );
  }

  @override
  $AdherenceCheckinsTable createAlias(String alias) {
    return $AdherenceCheckinsTable(attachedDatabase, alias);
  }
}

class AdherenceCheckinRow extends DataClass
    implements Insertable<AdherenceCheckinRow> {
  final String id;
  final String experimentOccurrenceId;
  final String responseJson;
  final DateTime recordedAtUtc;
  const AdherenceCheckinRow({
    required this.id,
    required this.experimentOccurrenceId,
    required this.responseJson,
    required this.recordedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['experiment_occurrence_id'] = Variable<String>(experimentOccurrenceId);
    map['response_json'] = Variable<String>(responseJson);
    map['recorded_at_utc'] = Variable<DateTime>(recordedAtUtc);
    return map;
  }

  AdherenceCheckinsCompanion toCompanion(bool nullToAbsent) {
    return AdherenceCheckinsCompanion(
      id: Value(id),
      experimentOccurrenceId: Value(experimentOccurrenceId),
      responseJson: Value(responseJson),
      recordedAtUtc: Value(recordedAtUtc),
    );
  }

  factory AdherenceCheckinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdherenceCheckinRow(
      id: serializer.fromJson<String>(json['id']),
      experimentOccurrenceId: serializer.fromJson<String>(
        json['experimentOccurrenceId'],
      ),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      recordedAtUtc: serializer.fromJson<DateTime>(json['recordedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'experimentOccurrenceId': serializer.toJson<String>(
        experimentOccurrenceId,
      ),
      'responseJson': serializer.toJson<String>(responseJson),
      'recordedAtUtc': serializer.toJson<DateTime>(recordedAtUtc),
    };
  }

  AdherenceCheckinRow copyWith({
    String? id,
    String? experimentOccurrenceId,
    String? responseJson,
    DateTime? recordedAtUtc,
  }) => AdherenceCheckinRow(
    id: id ?? this.id,
    experimentOccurrenceId:
        experimentOccurrenceId ?? this.experimentOccurrenceId,
    responseJson: responseJson ?? this.responseJson,
    recordedAtUtc: recordedAtUtc ?? this.recordedAtUtc,
  );
  AdherenceCheckinRow copyWithCompanion(AdherenceCheckinsCompanion data) {
    return AdherenceCheckinRow(
      id: data.id.present ? data.id.value : this.id,
      experimentOccurrenceId: data.experimentOccurrenceId.present
          ? data.experimentOccurrenceId.value
          : this.experimentOccurrenceId,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      recordedAtUtc: data.recordedAtUtc.present
          ? data.recordedAtUtc.value
          : this.recordedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdherenceCheckinRow(')
          ..write('id: $id, ')
          ..write('experimentOccurrenceId: $experimentOccurrenceId, ')
          ..write('responseJson: $responseJson, ')
          ..write('recordedAtUtc: $recordedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, experimentOccurrenceId, responseJson, recordedAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdherenceCheckinRow &&
          other.id == this.id &&
          other.experimentOccurrenceId == this.experimentOccurrenceId &&
          other.responseJson == this.responseJson &&
          other.recordedAtUtc == this.recordedAtUtc);
}

class AdherenceCheckinsCompanion extends UpdateCompanion<AdherenceCheckinRow> {
  final Value<String> id;
  final Value<String> experimentOccurrenceId;
  final Value<String> responseJson;
  final Value<DateTime> recordedAtUtc;
  final Value<int> rowid;
  const AdherenceCheckinsCompanion({
    this.id = const Value.absent(),
    this.experimentOccurrenceId = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.recordedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdherenceCheckinsCompanion.insert({
    required String id,
    required String experimentOccurrenceId,
    required String responseJson,
    required DateTime recordedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       experimentOccurrenceId = Value(experimentOccurrenceId),
       responseJson = Value(responseJson),
       recordedAtUtc = Value(recordedAtUtc);
  static Insertable<AdherenceCheckinRow> custom({
    Expression<String>? id,
    Expression<String>? experimentOccurrenceId,
    Expression<String>? responseJson,
    Expression<DateTime>? recordedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (experimentOccurrenceId != null)
        'experiment_occurrence_id': experimentOccurrenceId,
      if (responseJson != null) 'response_json': responseJson,
      if (recordedAtUtc != null) 'recorded_at_utc': recordedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdherenceCheckinsCompanion copyWith({
    Value<String>? id,
    Value<String>? experimentOccurrenceId,
    Value<String>? responseJson,
    Value<DateTime>? recordedAtUtc,
    Value<int>? rowid,
  }) {
    return AdherenceCheckinsCompanion(
      id: id ?? this.id,
      experimentOccurrenceId:
          experimentOccurrenceId ?? this.experimentOccurrenceId,
      responseJson: responseJson ?? this.responseJson,
      recordedAtUtc: recordedAtUtc ?? this.recordedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (experimentOccurrenceId.present) {
      map['experiment_occurrence_id'] = Variable<String>(
        experimentOccurrenceId.value,
      );
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (recordedAtUtc.present) {
      map['recorded_at_utc'] = Variable<DateTime>(recordedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdherenceCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('experimentOccurrenceId: $experimentOccurrenceId, ')
          ..write('responseJson: $responseJson, ')
          ..write('recordedAtUtc: $recordedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExperimentResultsTable extends ExperimentResults
    with TableInfo<$ExperimentResultsTable, ExperimentResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _experimentProtocolIdMeta =
      const VerificationMeta('experimentProtocolId');
  @override
  late final GeneratedColumn<String> experimentProtocolId =
      GeneratedColumn<String>(
        'experiment_protocol_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES experiment_protocols (id)',
        ),
      );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceHashMeta = const VerificationMeta(
    'evidenceHash',
  );
  @override
  late final GeneratedColumn<String> evidenceHash = GeneratedColumn<String>(
    'evidence_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysisVersionMeta = const VerificationMeta(
    'analysisVersion',
  );
  @override
  late final GeneratedColumn<int> analysisVersion = GeneratedColumn<int>(
    'analysis_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _invalidatedAtMeta = const VerificationMeta(
    'invalidatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> invalidatedAt =
      GeneratedColumn<DateTime>(
        'invalidated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    experimentProtocolId,
    outcome,
    resultJson,
    evidenceHash,
    analysisVersion,
    createdAt,
    invalidatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experiment_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('experiment_protocol_id')) {
      context.handle(
        _experimentProtocolIdMeta,
        experimentProtocolId.isAcceptableOrUnknown(
          data['experiment_protocol_id']!,
          _experimentProtocolIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experimentProtocolIdMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('evidence_hash')) {
      context.handle(
        _evidenceHashMeta,
        evidenceHash.isAcceptableOrUnknown(
          data['evidence_hash']!,
          _evidenceHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceHashMeta);
    }
    if (data.containsKey('analysis_version')) {
      context.handle(
        _analysisVersionMeta,
        analysisVersion.isAcceptableOrUnknown(
          data['analysis_version']!,
          _analysisVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('invalidated_at')) {
      context.handle(
        _invalidatedAtMeta,
        invalidatedAt.isAcceptableOrUnknown(
          data['invalidated_at']!,
          _invalidatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExperimentResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      experimentProtocolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experiment_protocol_id'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
      evidenceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_hash'],
      )!,
      analysisVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analysis_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      invalidatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invalidated_at'],
      ),
    );
  }

  @override
  $ExperimentResultsTable createAlias(String alias) {
    return $ExperimentResultsTable(attachedDatabase, alias);
  }
}

class ExperimentResultRow extends DataClass
    implements Insertable<ExperimentResultRow> {
  final String id;
  final String experimentProtocolId;
  final String outcome;
  final String resultJson;
  final String evidenceHash;
  final int analysisVersion;
  final DateTime createdAt;
  final DateTime? invalidatedAt;
  const ExperimentResultRow({
    required this.id,
    required this.experimentProtocolId,
    required this.outcome,
    required this.resultJson,
    required this.evidenceHash,
    required this.analysisVersion,
    required this.createdAt,
    this.invalidatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['experiment_protocol_id'] = Variable<String>(experimentProtocolId);
    map['outcome'] = Variable<String>(outcome);
    map['result_json'] = Variable<String>(resultJson);
    map['evidence_hash'] = Variable<String>(evidenceHash);
    map['analysis_version'] = Variable<int>(analysisVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || invalidatedAt != null) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt);
    }
    return map;
  }

  ExperimentResultsCompanion toCompanion(bool nullToAbsent) {
    return ExperimentResultsCompanion(
      id: Value(id),
      experimentProtocolId: Value(experimentProtocolId),
      outcome: Value(outcome),
      resultJson: Value(resultJson),
      evidenceHash: Value(evidenceHash),
      analysisVersion: Value(analysisVersion),
      createdAt: Value(createdAt),
      invalidatedAt: invalidatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(invalidatedAt),
    );
  }

  factory ExperimentResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentResultRow(
      id: serializer.fromJson<String>(json['id']),
      experimentProtocolId: serializer.fromJson<String>(
        json['experimentProtocolId'],
      ),
      outcome: serializer.fromJson<String>(json['outcome']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      evidenceHash: serializer.fromJson<String>(json['evidenceHash']),
      analysisVersion: serializer.fromJson<int>(json['analysisVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      invalidatedAt: serializer.fromJson<DateTime?>(json['invalidatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'experimentProtocolId': serializer.toJson<String>(experimentProtocolId),
      'outcome': serializer.toJson<String>(outcome),
      'resultJson': serializer.toJson<String>(resultJson),
      'evidenceHash': serializer.toJson<String>(evidenceHash),
      'analysisVersion': serializer.toJson<int>(analysisVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'invalidatedAt': serializer.toJson<DateTime?>(invalidatedAt),
    };
  }

  ExperimentResultRow copyWith({
    String? id,
    String? experimentProtocolId,
    String? outcome,
    String? resultJson,
    String? evidenceHash,
    int? analysisVersion,
    DateTime? createdAt,
    Value<DateTime?> invalidatedAt = const Value.absent(),
  }) => ExperimentResultRow(
    id: id ?? this.id,
    experimentProtocolId: experimentProtocolId ?? this.experimentProtocolId,
    outcome: outcome ?? this.outcome,
    resultJson: resultJson ?? this.resultJson,
    evidenceHash: evidenceHash ?? this.evidenceHash,
    analysisVersion: analysisVersion ?? this.analysisVersion,
    createdAt: createdAt ?? this.createdAt,
    invalidatedAt: invalidatedAt.present
        ? invalidatedAt.value
        : this.invalidatedAt,
  );
  ExperimentResultRow copyWithCompanion(ExperimentResultsCompanion data) {
    return ExperimentResultRow(
      id: data.id.present ? data.id.value : this.id,
      experimentProtocolId: data.experimentProtocolId.present
          ? data.experimentProtocolId.value
          : this.experimentProtocolId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      evidenceHash: data.evidenceHash.present
          ? data.evidenceHash.value
          : this.evidenceHash,
      analysisVersion: data.analysisVersion.present
          ? data.analysisVersion.value
          : this.analysisVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      invalidatedAt: data.invalidatedAt.present
          ? data.invalidatedAt.value
          : this.invalidatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentResultRow(')
          ..write('id: $id, ')
          ..write('experimentProtocolId: $experimentProtocolId, ')
          ..write('outcome: $outcome, ')
          ..write('resultJson: $resultJson, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('invalidatedAt: $invalidatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    experimentProtocolId,
    outcome,
    resultJson,
    evidenceHash,
    analysisVersion,
    createdAt,
    invalidatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentResultRow &&
          other.id == this.id &&
          other.experimentProtocolId == this.experimentProtocolId &&
          other.outcome == this.outcome &&
          other.resultJson == this.resultJson &&
          other.evidenceHash == this.evidenceHash &&
          other.analysisVersion == this.analysisVersion &&
          other.createdAt == this.createdAt &&
          other.invalidatedAt == this.invalidatedAt);
}

class ExperimentResultsCompanion extends UpdateCompanion<ExperimentResultRow> {
  final Value<String> id;
  final Value<String> experimentProtocolId;
  final Value<String> outcome;
  final Value<String> resultJson;
  final Value<String> evidenceHash;
  final Value<int> analysisVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> invalidatedAt;
  final Value<int> rowid;
  const ExperimentResultsCompanion({
    this.id = const Value.absent(),
    this.experimentProtocolId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.evidenceHash = const Value.absent(),
    this.analysisVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentResultsCompanion.insert({
    required String id,
    required String experimentProtocolId,
    required String outcome,
    required String resultJson,
    required String evidenceHash,
    required int analysisVersion,
    this.createdAt = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       experimentProtocolId = Value(experimentProtocolId),
       outcome = Value(outcome),
       resultJson = Value(resultJson),
       evidenceHash = Value(evidenceHash),
       analysisVersion = Value(analysisVersion);
  static Insertable<ExperimentResultRow> custom({
    Expression<String>? id,
    Expression<String>? experimentProtocolId,
    Expression<String>? outcome,
    Expression<String>? resultJson,
    Expression<String>? evidenceHash,
    Expression<int>? analysisVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? invalidatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (experimentProtocolId != null)
        'experiment_protocol_id': experimentProtocolId,
      if (outcome != null) 'outcome': outcome,
      if (resultJson != null) 'result_json': resultJson,
      if (evidenceHash != null) 'evidence_hash': evidenceHash,
      if (analysisVersion != null) 'analysis_version': analysisVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (invalidatedAt != null) 'invalidated_at': invalidatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? experimentProtocolId,
    Value<String>? outcome,
    Value<String>? resultJson,
    Value<String>? evidenceHash,
    Value<int>? analysisVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? invalidatedAt,
    Value<int>? rowid,
  }) {
    return ExperimentResultsCompanion(
      id: id ?? this.id,
      experimentProtocolId: experimentProtocolId ?? this.experimentProtocolId,
      outcome: outcome ?? this.outcome,
      resultJson: resultJson ?? this.resultJson,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      createdAt: createdAt ?? this.createdAt,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (experimentProtocolId.present) {
      map['experiment_protocol_id'] = Variable<String>(
        experimentProtocolId.value,
      );
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (evidenceHash.present) {
      map['evidence_hash'] = Variable<String>(evidenceHash.value);
    }
    if (analysisVersion.present) {
      map['analysis_version'] = Variable<int>(analysisVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (invalidatedAt.present) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentResultsCompanion(')
          ..write('id: $id, ')
          ..write('experimentProtocolId: $experimentProtocolId, ')
          ..write('outcome: $outcome, ')
          ..write('resultJson: $resultJson, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('analysisVersion: $analysisVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('invalidatedAt: $invalidatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExperimentDependenciesTable extends ExperimentDependencies
    with TableInfo<$ExperimentDependenciesTable, ExperimentDependencyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentDependenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _experimentResultIdMeta =
      const VerificationMeta('experimentResultId');
  @override
  late final GeneratedColumn<String> experimentResultId =
      GeneratedColumn<String>(
        'experiment_result_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES experiment_results (id)',
        ),
      );
  static const VerificationMeta _dependencyKindMeta = const VerificationMeta(
    'dependencyKind',
  );
  @override
  late final GeneratedColumn<String> dependencyKind = GeneratedColumn<String>(
    'dependency_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependencyIdMeta = const VerificationMeta(
    'dependencyId',
  );
  @override
  late final GeneratedColumn<String> dependencyId = GeneratedColumn<String>(
    'dependency_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependencyHashMeta = const VerificationMeta(
    'dependencyHash',
  );
  @override
  late final GeneratedColumn<String> dependencyHash = GeneratedColumn<String>(
    'dependency_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    experimentResultId,
    dependencyKind,
    dependencyId,
    dependencyHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experiment_dependencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentDependencyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('experiment_result_id')) {
      context.handle(
        _experimentResultIdMeta,
        experimentResultId.isAcceptableOrUnknown(
          data['experiment_result_id']!,
          _experimentResultIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experimentResultIdMeta);
    }
    if (data.containsKey('dependency_kind')) {
      context.handle(
        _dependencyKindMeta,
        dependencyKind.isAcceptableOrUnknown(
          data['dependency_kind']!,
          _dependencyKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyKindMeta);
    }
    if (data.containsKey('dependency_id')) {
      context.handle(
        _dependencyIdMeta,
        dependencyId.isAcceptableOrUnknown(
          data['dependency_id']!,
          _dependencyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyIdMeta);
    }
    if (data.containsKey('dependency_hash')) {
      context.handle(
        _dependencyHashMeta,
        dependencyHash.isAcceptableOrUnknown(
          data['dependency_hash']!,
          _dependencyHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependencyHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExperimentDependencyRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentDependencyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      experimentResultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experiment_result_id'],
      )!,
      dependencyKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_kind'],
      )!,
      dependencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_id'],
      )!,
      dependencyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_hash'],
      )!,
    );
  }

  @override
  $ExperimentDependenciesTable createAlias(String alias) {
    return $ExperimentDependenciesTable(attachedDatabase, alias);
  }
}

class ExperimentDependencyRow extends DataClass
    implements Insertable<ExperimentDependencyRow> {
  final String id;
  final String experimentResultId;
  final String dependencyKind;
  final String dependencyId;
  final String dependencyHash;
  const ExperimentDependencyRow({
    required this.id,
    required this.experimentResultId,
    required this.dependencyKind,
    required this.dependencyId,
    required this.dependencyHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['experiment_result_id'] = Variable<String>(experimentResultId);
    map['dependency_kind'] = Variable<String>(dependencyKind);
    map['dependency_id'] = Variable<String>(dependencyId);
    map['dependency_hash'] = Variable<String>(dependencyHash);
    return map;
  }

  ExperimentDependenciesCompanion toCompanion(bool nullToAbsent) {
    return ExperimentDependenciesCompanion(
      id: Value(id),
      experimentResultId: Value(experimentResultId),
      dependencyKind: Value(dependencyKind),
      dependencyId: Value(dependencyId),
      dependencyHash: Value(dependencyHash),
    );
  }

  factory ExperimentDependencyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentDependencyRow(
      id: serializer.fromJson<String>(json['id']),
      experimentResultId: serializer.fromJson<String>(
        json['experimentResultId'],
      ),
      dependencyKind: serializer.fromJson<String>(json['dependencyKind']),
      dependencyId: serializer.fromJson<String>(json['dependencyId']),
      dependencyHash: serializer.fromJson<String>(json['dependencyHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'experimentResultId': serializer.toJson<String>(experimentResultId),
      'dependencyKind': serializer.toJson<String>(dependencyKind),
      'dependencyId': serializer.toJson<String>(dependencyId),
      'dependencyHash': serializer.toJson<String>(dependencyHash),
    };
  }

  ExperimentDependencyRow copyWith({
    String? id,
    String? experimentResultId,
    String? dependencyKind,
    String? dependencyId,
    String? dependencyHash,
  }) => ExperimentDependencyRow(
    id: id ?? this.id,
    experimentResultId: experimentResultId ?? this.experimentResultId,
    dependencyKind: dependencyKind ?? this.dependencyKind,
    dependencyId: dependencyId ?? this.dependencyId,
    dependencyHash: dependencyHash ?? this.dependencyHash,
  );
  ExperimentDependencyRow copyWithCompanion(
    ExperimentDependenciesCompanion data,
  ) {
    return ExperimentDependencyRow(
      id: data.id.present ? data.id.value : this.id,
      experimentResultId: data.experimentResultId.present
          ? data.experimentResultId.value
          : this.experimentResultId,
      dependencyKind: data.dependencyKind.present
          ? data.dependencyKind.value
          : this.dependencyKind,
      dependencyId: data.dependencyId.present
          ? data.dependencyId.value
          : this.dependencyId,
      dependencyHash: data.dependencyHash.present
          ? data.dependencyHash.value
          : this.dependencyHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentDependencyRow(')
          ..write('id: $id, ')
          ..write('experimentResultId: $experimentResultId, ')
          ..write('dependencyKind: $dependencyKind, ')
          ..write('dependencyId: $dependencyId, ')
          ..write('dependencyHash: $dependencyHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    experimentResultId,
    dependencyKind,
    dependencyId,
    dependencyHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentDependencyRow &&
          other.id == this.id &&
          other.experimentResultId == this.experimentResultId &&
          other.dependencyKind == this.dependencyKind &&
          other.dependencyId == this.dependencyId &&
          other.dependencyHash == this.dependencyHash);
}

class ExperimentDependenciesCompanion
    extends UpdateCompanion<ExperimentDependencyRow> {
  final Value<String> id;
  final Value<String> experimentResultId;
  final Value<String> dependencyKind;
  final Value<String> dependencyId;
  final Value<String> dependencyHash;
  final Value<int> rowid;
  const ExperimentDependenciesCompanion({
    this.id = const Value.absent(),
    this.experimentResultId = const Value.absent(),
    this.dependencyKind = const Value.absent(),
    this.dependencyId = const Value.absent(),
    this.dependencyHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentDependenciesCompanion.insert({
    required String id,
    required String experimentResultId,
    required String dependencyKind,
    required String dependencyId,
    required String dependencyHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       experimentResultId = Value(experimentResultId),
       dependencyKind = Value(dependencyKind),
       dependencyId = Value(dependencyId),
       dependencyHash = Value(dependencyHash);
  static Insertable<ExperimentDependencyRow> custom({
    Expression<String>? id,
    Expression<String>? experimentResultId,
    Expression<String>? dependencyKind,
    Expression<String>? dependencyId,
    Expression<String>? dependencyHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (experimentResultId != null)
        'experiment_result_id': experimentResultId,
      if (dependencyKind != null) 'dependency_kind': dependencyKind,
      if (dependencyId != null) 'dependency_id': dependencyId,
      if (dependencyHash != null) 'dependency_hash': dependencyHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentDependenciesCompanion copyWith({
    Value<String>? id,
    Value<String>? experimentResultId,
    Value<String>? dependencyKind,
    Value<String>? dependencyId,
    Value<String>? dependencyHash,
    Value<int>? rowid,
  }) {
    return ExperimentDependenciesCompanion(
      id: id ?? this.id,
      experimentResultId: experimentResultId ?? this.experimentResultId,
      dependencyKind: dependencyKind ?? this.dependencyKind,
      dependencyId: dependencyId ?? this.dependencyId,
      dependencyHash: dependencyHash ?? this.dependencyHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (experimentResultId.present) {
      map['experiment_result_id'] = Variable<String>(experimentResultId.value);
    }
    if (dependencyKind.present) {
      map['dependency_kind'] = Variable<String>(dependencyKind.value);
    }
    if (dependencyId.present) {
      map['dependency_id'] = Variable<String>(dependencyId.value);
    }
    if (dependencyHash.present) {
      map['dependency_hash'] = Variable<String>(dependencyHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentDependenciesCompanion(')
          ..write('id: $id, ')
          ..write('experimentResultId: $experimentResultId, ')
          ..write('dependencyKind: $dependencyKind, ')
          ..write('dependencyId: $dependencyId, ')
          ..write('dependencyHash: $dependencyHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportRecordsTable extends ExportRecords
    with TableInfo<$ExportRecordsTable, ExportRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exportTypeMeta = const VerificationMeta(
    'exportType',
  );
  @override
  late final GeneratedColumn<String> exportType = GeneratedColumn<String>(
    'export_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exportSchemaVersionMeta =
      const VerificationMeta('exportSchemaVersion');
  @override
  late final GeneratedColumn<int> exportSchemaVersion = GeneratedColumn<int>(
    'export_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exportType,
    status,
    filePath,
    contentHash,
    exportSchemaVersion,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('export_type')) {
      context.handle(
        _exportTypeMeta,
        exportType.isAcceptableOrUnknown(data['export_type']!, _exportTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_exportTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('export_schema_version')) {
      context.handle(
        _exportSchemaVersionMeta,
        exportSchemaVersion.isAcceptableOrUnknown(
          data['export_schema_version']!,
          _exportSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exportSchemaVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exportType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}export_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      exportSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}export_schema_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ExportRecordsTable createAlias(String alias) {
    return $ExportRecordsTable(attachedDatabase, alias);
  }
}

class ExportRecordRow extends DataClass implements Insertable<ExportRecordRow> {
  final String id;
  final String exportType;
  final String status;
  final String filePath;
  final String? contentHash;
  final int exportSchemaVersion;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const ExportRecordRow({
    required this.id,
    required this.exportType,
    required this.status,
    required this.filePath,
    this.contentHash,
    required this.exportSchemaVersion,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['export_type'] = Variable<String>(exportType);
    map['status'] = Variable<String>(status);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    map['export_schema_version'] = Variable<int>(exportSchemaVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ExportRecordsCompanion toCompanion(bool nullToAbsent) {
    return ExportRecordsCompanion(
      id: Value(id),
      exportType: Value(exportType),
      status: Value(status),
      filePath: Value(filePath),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      exportSchemaVersion: Value(exportSchemaVersion),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ExportRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportRecordRow(
      id: serializer.fromJson<String>(json['id']),
      exportType: serializer.fromJson<String>(json['exportType']),
      status: serializer.fromJson<String>(json['status']),
      filePath: serializer.fromJson<String>(json['filePath']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      exportSchemaVersion: serializer.fromJson<int>(
        json['exportSchemaVersion'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exportType': serializer.toJson<String>(exportType),
      'status': serializer.toJson<String>(status),
      'filePath': serializer.toJson<String>(filePath),
      'contentHash': serializer.toJson<String?>(contentHash),
      'exportSchemaVersion': serializer.toJson<int>(exportSchemaVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ExportRecordRow copyWith({
    String? id,
    String? exportType,
    String? status,
    String? filePath,
    Value<String?> contentHash = const Value.absent(),
    int? exportSchemaVersion,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ExportRecordRow(
    id: id ?? this.id,
    exportType: exportType ?? this.exportType,
    status: status ?? this.status,
    filePath: filePath ?? this.filePath,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    exportSchemaVersion: exportSchemaVersion ?? this.exportSchemaVersion,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ExportRecordRow copyWithCompanion(ExportRecordsCompanion data) {
    return ExportRecordRow(
      id: data.id.present ? data.id.value : this.id,
      exportType: data.exportType.present
          ? data.exportType.value
          : this.exportType,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      exportSchemaVersion: data.exportSchemaVersion.present
          ? data.exportSchemaVersion.value
          : this.exportSchemaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordRow(')
          ..write('id: $id, ')
          ..write('exportType: $exportType, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('contentHash: $contentHash, ')
          ..write('exportSchemaVersion: $exportSchemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exportType,
    status,
    filePath,
    contentHash,
    exportSchemaVersion,
    createdAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportRecordRow &&
          other.id == this.id &&
          other.exportType == this.exportType &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.contentHash == this.contentHash &&
          other.exportSchemaVersion == this.exportSchemaVersion &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class ExportRecordsCompanion extends UpdateCompanion<ExportRecordRow> {
  final Value<String> id;
  final Value<String> exportType;
  final Value<String> status;
  final Value<String> filePath;
  final Value<String?> contentHash;
  final Value<int> exportSchemaVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ExportRecordsCompanion({
    this.id = const Value.absent(),
    this.exportType = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.exportSchemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportRecordsCompanion.insert({
    required String id,
    required String exportType,
    required String status,
    required String filePath,
    this.contentHash = const Value.absent(),
    required int exportSchemaVersion,
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exportType = Value(exportType),
       status = Value(status),
       filePath = Value(filePath),
       exportSchemaVersion = Value(exportSchemaVersion);
  static Insertable<ExportRecordRow> custom({
    Expression<String>? id,
    Expression<String>? exportType,
    Expression<String>? status,
    Expression<String>? filePath,
    Expression<String>? contentHash,
    Expression<int>? exportSchemaVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exportType != null) 'export_type': exportType,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (contentHash != null) 'content_hash': contentHash,
      if (exportSchemaVersion != null)
        'export_schema_version': exportSchemaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? exportType,
    Value<String>? status,
    Value<String>? filePath,
    Value<String?>? contentHash,
    Value<int>? exportSchemaVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ExportRecordsCompanion(
      id: id ?? this.id,
      exportType: exportType ?? this.exportType,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      contentHash: contentHash ?? this.contentHash,
      exportSchemaVersion: exportSchemaVersion ?? this.exportSchemaVersion,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exportType.present) {
      map['export_type'] = Variable<String>(exportType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (exportSchemaVersion.present) {
      map['export_schema_version'] = Variable<int>(exportSchemaVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('exportType: $exportType, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('contentHash: $contentHash, ')
          ..write('exportSchemaVersion: $exportSchemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletionAuditTable extends DeletionAudit
    with TableInfo<$DeletionAuditTable, DeletionAuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletionAuditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordsDeletedMeta = const VerificationMeta(
    'recordsDeleted',
  );
  @override
  late final GeneratedColumn<int> recordsDeleted = GeneratedColumn<int>(
    'records_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invalidatedJsonMeta = const VerificationMeta(
    'invalidatedJson',
  );
  @override
  late final GeneratedColumn<String> invalidatedJson = GeneratedColumn<String>(
    'invalidated_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scope,
    sourceId,
    recordsDeleted,
    invalidatedJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deletion_audit';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletionAuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('records_deleted')) {
      context.handle(
        _recordsDeletedMeta,
        recordsDeleted.isAcceptableOrUnknown(
          data['records_deleted']!,
          _recordsDeletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordsDeletedMeta);
    }
    if (data.containsKey('invalidated_json')) {
      context.handle(
        _invalidatedJsonMeta,
        invalidatedJson.isAcceptableOrUnknown(
          data['invalidated_json']!,
          _invalidatedJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invalidatedJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeletionAuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletionAuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      recordsDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_deleted'],
      )!,
      invalidatedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invalidated_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DeletionAuditTable createAlias(String alias) {
    return $DeletionAuditTable(attachedDatabase, alias);
  }
}

class DeletionAuditRow extends DataClass
    implements Insertable<DeletionAuditRow> {
  final String id;
  final String scope;
  final String? sourceId;
  final int recordsDeleted;
  final String invalidatedJson;
  final DateTime createdAt;
  const DeletionAuditRow({
    required this.id,
    required this.scope,
    this.sourceId,
    required this.recordsDeleted,
    required this.invalidatedJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['records_deleted'] = Variable<int>(recordsDeleted);
    map['invalidated_json'] = Variable<String>(invalidatedJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DeletionAuditCompanion toCompanion(bool nullToAbsent) {
    return DeletionAuditCompanion(
      id: Value(id),
      scope: Value(scope),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      recordsDeleted: Value(recordsDeleted),
      invalidatedJson: Value(invalidatedJson),
      createdAt: Value(createdAt),
    );
  }

  factory DeletionAuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletionAuditRow(
      id: serializer.fromJson<String>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      recordsDeleted: serializer.fromJson<int>(json['recordsDeleted']),
      invalidatedJson: serializer.fromJson<String>(json['invalidatedJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scope': serializer.toJson<String>(scope),
      'sourceId': serializer.toJson<String?>(sourceId),
      'recordsDeleted': serializer.toJson<int>(recordsDeleted),
      'invalidatedJson': serializer.toJson<String>(invalidatedJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DeletionAuditRow copyWith({
    String? id,
    String? scope,
    Value<String?> sourceId = const Value.absent(),
    int? recordsDeleted,
    String? invalidatedJson,
    DateTime? createdAt,
  }) => DeletionAuditRow(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    recordsDeleted: recordsDeleted ?? this.recordsDeleted,
    invalidatedJson: invalidatedJson ?? this.invalidatedJson,
    createdAt: createdAt ?? this.createdAt,
  );
  DeletionAuditRow copyWithCompanion(DeletionAuditCompanion data) {
    return DeletionAuditRow(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      recordsDeleted: data.recordsDeleted.present
          ? data.recordsDeleted.value
          : this.recordsDeleted,
      invalidatedJson: data.invalidatedJson.present
          ? data.invalidatedJson.value
          : this.invalidatedJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletionAuditRow(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('sourceId: $sourceId, ')
          ..write('recordsDeleted: $recordsDeleted, ')
          ..write('invalidatedJson: $invalidatedJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scope,
    sourceId,
    recordsDeleted,
    invalidatedJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletionAuditRow &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.sourceId == this.sourceId &&
          other.recordsDeleted == this.recordsDeleted &&
          other.invalidatedJson == this.invalidatedJson &&
          other.createdAt == this.createdAt);
}

class DeletionAuditCompanion extends UpdateCompanion<DeletionAuditRow> {
  final Value<String> id;
  final Value<String> scope;
  final Value<String?> sourceId;
  final Value<int> recordsDeleted;
  final Value<String> invalidatedJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DeletionAuditCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.recordsDeleted = const Value.absent(),
    this.invalidatedJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletionAuditCompanion.insert({
    required String id,
    required String scope,
    this.sourceId = const Value.absent(),
    required int recordsDeleted,
    required String invalidatedJson,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scope = Value(scope),
       recordsDeleted = Value(recordsDeleted),
       invalidatedJson = Value(invalidatedJson);
  static Insertable<DeletionAuditRow> custom({
    Expression<String>? id,
    Expression<String>? scope,
    Expression<String>? sourceId,
    Expression<int>? recordsDeleted,
    Expression<String>? invalidatedJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (sourceId != null) 'source_id': sourceId,
      if (recordsDeleted != null) 'records_deleted': recordsDeleted,
      if (invalidatedJson != null) 'invalidated_json': invalidatedJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletionAuditCompanion copyWith({
    Value<String>? id,
    Value<String>? scope,
    Value<String?>? sourceId,
    Value<int>? recordsDeleted,
    Value<String>? invalidatedJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DeletionAuditCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      sourceId: sourceId ?? this.sourceId,
      recordsDeleted: recordsDeleted ?? this.recordsDeleted,
      invalidatedJson: invalidatedJson ?? this.invalidatedJson,
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
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (recordsDeleted.present) {
      map['records_deleted'] = Variable<int>(recordsDeleted.value);
    }
    if (invalidatedJson.present) {
      map['invalidated_json'] = Variable<String>(invalidatedJson.value);
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
    return (StringBuffer('DeletionAuditCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('sourceId: $sourceId, ')
          ..write('recordsDeleted: $recordsDeleted, ')
          ..write('invalidatedJson: $invalidatedJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VueniverseDatabase extends GeneratedDatabase {
  _$VueniverseDatabase(QueryExecutor e) : super(e);
  $VueniverseDatabaseManager get managers => $VueniverseDatabaseManager(this);
  late final $StoreMetadataTable storeMetadata = $StoreMetadataTable(this);
  late final $SourceConnectionsTable sourceConnections =
      $SourceConnectionsTable(this);
  late final $SourcePermissionsTable sourcePermissions =
      $SourcePermissionsTable(this);
  late final $SyncRunsTable syncRuns = $SyncRunsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $SyncSeenRecordsTable syncSeenRecords = $SyncSeenRecordsTable(
    this,
  );
  late final $RawRecordIndexTable rawRecordIndex = $RawRecordIndexTable(this);
  late final $SignalSamplesTable signalSamples = $SignalSamplesTable(this);
  late final $HealthIntervalsTable healthIntervals = $HealthIntervalsTable(
    this,
  );
  late final $ContextEventsTable contextEvents = $ContextEventsTable(this);
  late final $ManualCheckinsTable manualCheckins = $ManualCheckinsTable(this);
  late final $RecomputeJobsTable recomputeJobs = $RecomputeJobsTable(this);
  late final $AnalysisRunsTable analysisRuns = $AnalysisRunsTable(this);
  late final $EventWindowsTable eventWindows = $EventWindowsTable(this);
  late final $ControlMatchesTable controlMatches = $ControlMatchesTable(this);
  late final $WindowMetricsTable windowMetrics = $WindowMetricsTable(this);
  late final $EvidenceBundlesTable evidenceBundles = $EvidenceBundlesTable(
    this,
  );
  late final $EvidenceMetricsTable evidenceMetrics = $EvidenceMetricsTable(
    this,
  );
  late final $EvidenceDependenciesTable evidenceDependencies =
      $EvidenceDependenciesTable(this);
  late final $FindingVersionsTable findingVersions = $FindingVersionsTable(
    this,
  );
  late final $ExplanationsTable explanations = $ExplanationsTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ExperimentProtocolsTable experimentProtocols =
      $ExperimentProtocolsTable(this);
  late final $ExperimentOccurrencesTable experimentOccurrences =
      $ExperimentOccurrencesTable(this);
  late final $AdherenceCheckinsTable adherenceCheckins =
      $AdherenceCheckinsTable(this);
  late final $ExperimentResultsTable experimentResults =
      $ExperimentResultsTable(this);
  late final $ExperimentDependenciesTable experimentDependencies =
      $ExperimentDependenciesTable(this);
  late final $ExportRecordsTable exportRecords = $ExportRecordsTable(this);
  late final $DeletionAuditTable deletionAudit = $DeletionAuditTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storeMetadata,
    sourceConnections,
    sourcePermissions,
    syncRuns,
    syncCursors,
    syncSeenRecords,
    rawRecordIndex,
    signalSamples,
    healthIntervals,
    contextEvents,
    manualCheckins,
    recomputeJobs,
    analysisRuns,
    eventWindows,
    controlMatches,
    windowMetrics,
    evidenceBundles,
    evidenceMetrics,
    evidenceDependencies,
    findingVersions,
    explanations,
    chatSessions,
    chatMessages,
    experimentProtocols,
    experimentOccurrences,
    adherenceCheckins,
    experimentResults,
    experimentDependencies,
    exportRecords,
    deletionAudit,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$StoreMetadataTableCreateCompanionBuilder =
    StoreMetadataCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$StoreMetadataTableUpdateCompanionBuilder =
    StoreMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StoreMetadataTableFilterComposer
    extends Composer<_$VueniverseDatabase, $StoreMetadataTable> {
  $$StoreMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreMetadataTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $StoreMetadataTable> {
  $$StoreMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreMetadataTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $StoreMetadataTable> {
  $$StoreMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoreMetadataTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $StoreMetadataTable,
          StoreMetadataRow,
          $$StoreMetadataTableFilterComposer,
          $$StoreMetadataTableOrderingComposer,
          $$StoreMetadataTableAnnotationComposer,
          $$StoreMetadataTableCreateCompanionBuilder,
          $$StoreMetadataTableUpdateCompanionBuilder,
          (
            StoreMetadataRow,
            BaseReferences<
              _$VueniverseDatabase,
              $StoreMetadataTable,
              StoreMetadataRow
            >,
          ),
          StoreMetadataRow,
          PrefetchHooks Function()
        > {
  $$StoreMetadataTableTableManager(
    _$VueniverseDatabase db,
    $StoreMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreMetadataCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreMetadataCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $StoreMetadataTable,
      StoreMetadataRow,
      $$StoreMetadataTableFilterComposer,
      $$StoreMetadataTableOrderingComposer,
      $$StoreMetadataTableAnnotationComposer,
      $$StoreMetadataTableCreateCompanionBuilder,
      $$StoreMetadataTableUpdateCompanionBuilder,
      (
        StoreMetadataRow,
        BaseReferences<
          _$VueniverseDatabase,
          $StoreMetadataTable,
          StoreMetadataRow
        >,
      ),
      StoreMetadataRow,
      PrefetchHooks Function()
    >;
typedef $$SourceConnectionsTableCreateCompanionBuilder =
    SourceConnectionsCompanion Function({
      required String id,
      required String sourceType,
      required String status,
      Value<String> configurationJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SourceConnectionsTableUpdateCompanionBuilder =
    SourceConnectionsCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> status,
      Value<String> configurationJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SourceConnectionsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $SourceConnectionsTable,
          SourceConnectionRow
        > {
  $$SourceConnectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SourcePermissionsTable, List<SourcePermissionRow>>
  _sourcePermissionsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sourcePermissions,
        aliasName:
            'source_connections__id__source_permissions__source_connection_id',
      );

  $$SourcePermissionsTableProcessedTableManager get sourcePermissionsRefs {
    final manager =
        $$SourcePermissionsTableTableManager(
          $_db,
          $_db.sourcePermissions,
        ).filter(
          (f) => f.sourceConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _sourcePermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncRunsTable, List<SyncRunRow>>
  _syncRunsRefsTable(_$VueniverseDatabase db) => MultiTypedResultKey.fromTable(
    db.syncRuns,
    aliasName: 'source_connections__id__sync_runs__source_connection_id',
  );

  $$SyncRunsTableProcessedTableManager get syncRunsRefs {
    final manager = $$SyncRunsTableTableManager($_db, $_db.syncRuns).filter(
      (f) => f.sourceConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_syncRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncCursorsTable, List<SyncCursorRow>>
  _syncCursorsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncCursors,
        aliasName: 'source_connections__id__sync_cursors__source_connection_id',
      );

  $$SyncCursorsTableProcessedTableManager get syncCursorsRefs {
    final manager = $$SyncCursorsTableTableManager($_db, $_db.syncCursors)
        .filter(
          (f) => f.sourceConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_syncCursorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RawRecordIndexTable, List<RawRecordIndexRow>>
  _rawRecordIndexRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rawRecordIndex,
        aliasName:
            'source_connections__id__raw_record_index__source_connection_id',
      );

  $$RawRecordIndexTableProcessedTableManager get rawRecordIndexRefs {
    final manager = $$RawRecordIndexTableTableManager($_db, $_db.rawRecordIndex)
        .filter(
          (f) => f.sourceConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_rawRecordIndexRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourceConnectionsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SourceConnectionsTable> {
  $$SourceConnectionsTableFilterComposer({
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

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourcePermissionsRefs(
    Expression<bool> Function($$SourcePermissionsTableFilterComposer f) f,
  ) {
    final $$SourcePermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourcePermissions,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcePermissionsTableFilterComposer(
            $db: $db,
            $table: $db.sourcePermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncRunsRefs(
    Expression<bool> Function($$SyncRunsTableFilterComposer f) f,
  ) {
    final $$SyncRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableFilterComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncCursorsRefs(
    Expression<bool> Function($$SyncCursorsTableFilterComposer f) f,
  ) {
    final $$SyncCursorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursors,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorsTableFilterComposer(
            $db: $db,
            $table: $db.syncCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rawRecordIndexRefs(
    Expression<bool> Function($$RawRecordIndexTableFilterComposer f) f,
  ) {
    final $$RawRecordIndexTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawRecordIndex,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawRecordIndexTableFilterComposer(
            $db: $db,
            $table: $db.rawRecordIndex,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceConnectionsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SourceConnectionsTable> {
  $$SourceConnectionsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceConnectionsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SourceConnectionsTable> {
  $$SourceConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sourcePermissionsRefs<T extends Object>(
    Expression<T> Function($$SourcePermissionsTableAnnotationComposer a) f,
  ) {
    final $$SourcePermissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sourcePermissions,
          getReferencedColumn: (t) => t.sourceConnectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourcePermissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sourcePermissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> syncRunsRefs<T extends Object>(
    Expression<T> Function($$SyncRunsTableAnnotationComposer a) f,
  ) {
    final $$SyncRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncCursorsRefs<T extends Object>(
    Expression<T> Function($$SyncCursorsTableAnnotationComposer a) f,
  ) {
    final $$SyncCursorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursors,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rawRecordIndexRefs<T extends Object>(
    Expression<T> Function($$RawRecordIndexTableAnnotationComposer a) f,
  ) {
    final $$RawRecordIndexTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawRecordIndex,
      getReferencedColumn: (t) => t.sourceConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawRecordIndexTableAnnotationComposer(
            $db: $db,
            $table: $db.rawRecordIndex,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceConnectionsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SourceConnectionsTable,
          SourceConnectionRow,
          $$SourceConnectionsTableFilterComposer,
          $$SourceConnectionsTableOrderingComposer,
          $$SourceConnectionsTableAnnotationComposer,
          $$SourceConnectionsTableCreateCompanionBuilder,
          $$SourceConnectionsTableUpdateCompanionBuilder,
          (SourceConnectionRow, $$SourceConnectionsTableReferences),
          SourceConnectionRow,
          PrefetchHooks Function({
            bool sourcePermissionsRefs,
            bool syncRunsRefs,
            bool syncCursorsRefs,
            bool rawRecordIndexRefs,
          })
        > {
  $$SourceConnectionsTableTableManager(
    _$VueniverseDatabase db,
    $SourceConnectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceConnectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> configurationJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceConnectionsCompanion(
                id: id,
                sourceType: sourceType,
                status: status,
                configurationJson: configurationJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                required String status,
                Value<String> configurationJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceConnectionsCompanion.insert(
                id: id,
                sourceType: sourceType,
                status: status,
                configurationJson: configurationJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourceConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourcePermissionsRefs = false,
                syncRunsRefs = false,
                syncCursorsRefs = false,
                rawRecordIndexRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourcePermissionsRefs) db.sourcePermissions,
                    if (syncRunsRefs) db.syncRuns,
                    if (syncCursorsRefs) db.syncCursors,
                    if (rawRecordIndexRefs) db.rawRecordIndex,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourcePermissionsRefs)
                        await $_getPrefetchedData<
                          SourceConnectionRow,
                          $SourceConnectionsTable,
                          SourcePermissionRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourceConnectionsTableReferences
                              ._sourcePermissionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourceConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sourcePermissionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncRunsRefs)
                        await $_getPrefetchedData<
                          SourceConnectionRow,
                          $SourceConnectionsTable,
                          SyncRunRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourceConnectionsTableReferences
                              ._syncRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourceConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncCursorsRefs)
                        await $_getPrefetchedData<
                          SourceConnectionRow,
                          $SourceConnectionsTable,
                          SyncCursorRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourceConnectionsTableReferences
                              ._syncCursorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourceConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncCursorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rawRecordIndexRefs)
                        await $_getPrefetchedData<
                          SourceConnectionRow,
                          $SourceConnectionsTable,
                          RawRecordIndexRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourceConnectionsTableReferences
                              ._rawRecordIndexRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourceConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).rawRecordIndexRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SourceConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SourceConnectionsTable,
      SourceConnectionRow,
      $$SourceConnectionsTableFilterComposer,
      $$SourceConnectionsTableOrderingComposer,
      $$SourceConnectionsTableAnnotationComposer,
      $$SourceConnectionsTableCreateCompanionBuilder,
      $$SourceConnectionsTableUpdateCompanionBuilder,
      (SourceConnectionRow, $$SourceConnectionsTableReferences),
      SourceConnectionRow,
      PrefetchHooks Function({
        bool sourcePermissionsRefs,
        bool syncRunsRefs,
        bool syncCursorsRefs,
        bool rawRecordIndexRefs,
      })
    >;
typedef $$SourcePermissionsTableCreateCompanionBuilder =
    SourcePermissionsCompanion Function({
      required String id,
      required String sourceConnectionId,
      required String recordType,
      required String status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SourcePermissionsTableUpdateCompanionBuilder =
    SourcePermissionsCompanion Function({
      Value<String> id,
      Value<String> sourceConnectionId,
      Value<String> recordType,
      Value<String> status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SourcePermissionsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $SourcePermissionsTable,
          SourcePermissionRow
        > {
  $$SourcePermissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourceConnectionsTable _sourceConnectionIdTable(
    _$VueniverseDatabase db,
  ) => db.sourceConnections.createAlias(
    'source_permissions__source_connection_id__source_connections__id',
  );

  $$SourceConnectionsTableProcessedTableManager get sourceConnectionId {
    final $_column = $_itemColumn<String>('source_connection_id')!;

    final manager = $$SourceConnectionsTableTableManager(
      $_db,
      $_db.sourceConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceConnectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourcePermissionsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SourcePermissionsTable> {
  $$SourcePermissionsTableFilterComposer({
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

  ColumnFilters<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourceConnectionsTableFilterComposer get sourceConnectionId {
    final $$SourceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePermissionsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SourcePermissionsTable> {
  $$SourcePermissionsTableOrderingComposer({
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

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceConnectionsTableOrderingComposer get sourceConnectionId {
    final $$SourceConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePermissionsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SourcePermissionsTable> {
  $$SourcePermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourceConnectionsTableAnnotationComposer get sourceConnectionId {
    final $$SourceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceConnectionId,
          referencedTable: $db.sourceConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sourceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SourcePermissionsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SourcePermissionsTable,
          SourcePermissionRow,
          $$SourcePermissionsTableFilterComposer,
          $$SourcePermissionsTableOrderingComposer,
          $$SourcePermissionsTableAnnotationComposer,
          $$SourcePermissionsTableCreateCompanionBuilder,
          $$SourcePermissionsTableUpdateCompanionBuilder,
          (SourcePermissionRow, $$SourcePermissionsTableReferences),
          SourcePermissionRow,
          PrefetchHooks Function({bool sourceConnectionId})
        > {
  $$SourcePermissionsTableTableManager(
    _$VueniverseDatabase db,
    $SourcePermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcePermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcePermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcePermissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceConnectionId = const Value.absent(),
                Value<String> recordType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePermissionsCompanion(
                id: id,
                sourceConnectionId: sourceConnectionId,
                recordType: recordType,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceConnectionId,
                required String recordType,
                required String status,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePermissionsCompanion.insert(
                id: id,
                sourceConnectionId: sourceConnectionId,
                recordType: recordType,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourcePermissionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceConnectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceConnectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceConnectionId,
                                referencedTable:
                                    $$SourcePermissionsTableReferences
                                        ._sourceConnectionIdTable(db),
                                referencedColumn:
                                    $$SourcePermissionsTableReferences
                                        ._sourceConnectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SourcePermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SourcePermissionsTable,
      SourcePermissionRow,
      $$SourcePermissionsTableFilterComposer,
      $$SourcePermissionsTableOrderingComposer,
      $$SourcePermissionsTableAnnotationComposer,
      $$SourcePermissionsTableCreateCompanionBuilder,
      $$SourcePermissionsTableUpdateCompanionBuilder,
      (SourcePermissionRow, $$SourcePermissionsTableReferences),
      SourcePermissionRow,
      PrefetchHooks Function({bool sourceConnectionId})
    >;
typedef $$SyncRunsTableCreateCompanionBuilder =
    SyncRunsCompanion Function({
      required String id,
      required String sourceConnectionId,
      required String status,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> recordsSeen,
      Value<int> recordsAccepted,
      Value<int> recordsRejected,
      Value<String?> errorCode,
      Value<String?> errorDetails,
      Value<int> rowid,
    });
typedef $$SyncRunsTableUpdateCompanionBuilder =
    SyncRunsCompanion Function({
      Value<String> id,
      Value<String> sourceConnectionId,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> recordsSeen,
      Value<int> recordsAccepted,
      Value<int> recordsRejected,
      Value<String?> errorCode,
      Value<String?> errorDetails,
      Value<int> rowid,
    });

final class $$SyncRunsTableReferences
    extends BaseReferences<_$VueniverseDatabase, $SyncRunsTable, SyncRunRow> {
  $$SyncRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourceConnectionsTable _sourceConnectionIdTable(
    _$VueniverseDatabase db,
  ) => db.sourceConnections.createAlias(
    'sync_runs__source_connection_id__source_connections__id',
  );

  $$SourceConnectionsTableProcessedTableManager get sourceConnectionId {
    final $_column = $_itemColumn<String>('source_connection_id')!;

    final manager = $$SourceConnectionsTableTableManager(
      $_db,
      $_db.sourceConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceConnectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyncSeenRecordsTable, List<SyncSeenRecordRow>>
  _syncSeenRecordsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncSeenRecords,
        aliasName: 'sync_runs__id__sync_seen_records__sync_run_id',
      );

  $$SyncSeenRecordsTableProcessedTableManager get syncSeenRecordsRefs {
    final manager = $$SyncSeenRecordsTableTableManager(
      $_db,
      $_db.syncSeenRecords,
    ).filter((f) => f.syncRunId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncSeenRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyncRunsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SyncRunsTable> {
  $$SyncRunsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsSeen => $composableBuilder(
    column: $table.recordsSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsAccepted => $composableBuilder(
    column: $table.recordsAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsRejected => $composableBuilder(
    column: $table.recordsRejected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnFilters(column),
  );

  $$SourceConnectionsTableFilterComposer get sourceConnectionId {
    final $$SourceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syncSeenRecordsRefs(
    Expression<bool> Function($$SyncSeenRecordsTableFilterComposer f) f,
  ) {
    final $$SyncSeenRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncSeenRecords,
      getReferencedColumn: (t) => t.syncRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncSeenRecordsTableFilterComposer(
            $db: $db,
            $table: $db.syncSeenRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncRunsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SyncRunsTable> {
  $$SyncRunsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsSeen => $composableBuilder(
    column: $table.recordsSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsAccepted => $composableBuilder(
    column: $table.recordsAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsRejected => $composableBuilder(
    column: $table.recordsRejected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceConnectionsTableOrderingComposer get sourceConnectionId {
    final $$SourceConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncRunsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SyncRunsTable> {
  $$SyncRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordsSeen => $composableBuilder(
    column: $table.recordsSeen,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordsAccepted => $composableBuilder(
    column: $table.recordsAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordsRejected => $composableBuilder(
    column: $table.recordsRejected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorDetails => $composableBuilder(
    column: $table.errorDetails,
    builder: (column) => column,
  );

  $$SourceConnectionsTableAnnotationComposer get sourceConnectionId {
    final $$SourceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceConnectionId,
          referencedTable: $db.sourceConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sourceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> syncSeenRecordsRefs<T extends Object>(
    Expression<T> Function($$SyncSeenRecordsTableAnnotationComposer a) f,
  ) {
    final $$SyncSeenRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncSeenRecords,
      getReferencedColumn: (t) => t.syncRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncSeenRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncSeenRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncRunsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SyncRunsTable,
          SyncRunRow,
          $$SyncRunsTableFilterComposer,
          $$SyncRunsTableOrderingComposer,
          $$SyncRunsTableAnnotationComposer,
          $$SyncRunsTableCreateCompanionBuilder,
          $$SyncRunsTableUpdateCompanionBuilder,
          (SyncRunRow, $$SyncRunsTableReferences),
          SyncRunRow,
          PrefetchHooks Function({
            bool sourceConnectionId,
            bool syncSeenRecordsRefs,
          })
        > {
  $$SyncRunsTableTableManager(_$VueniverseDatabase db, $SyncRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceConnectionId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> recordsSeen = const Value.absent(),
                Value<int> recordsAccepted = const Value.absent(),
                Value<int> recordsRejected = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRunsCompanion(
                id: id,
                sourceConnectionId: sourceConnectionId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                recordsSeen: recordsSeen,
                recordsAccepted: recordsAccepted,
                recordsRejected: recordsRejected,
                errorCode: errorCode,
                errorDetails: errorDetails,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceConnectionId,
                required String status,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> recordsSeen = const Value.absent(),
                Value<int> recordsAccepted = const Value.absent(),
                Value<int> recordsRejected = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorDetails = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRunsCompanion.insert(
                id: id,
                sourceConnectionId: sourceConnectionId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                recordsSeen: recordsSeen,
                recordsAccepted: recordsAccepted,
                recordsRejected: recordsRejected,
                errorCode: errorCode,
                errorDetails: errorDetails,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceConnectionId = false, syncSeenRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syncSeenRecordsRefs) db.syncSeenRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceConnectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceConnectionId,
                                    referencedTable: $$SyncRunsTableReferences
                                        ._sourceConnectionIdTable(db),
                                    referencedColumn: $$SyncRunsTableReferences
                                        ._sourceConnectionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syncSeenRecordsRefs)
                        await $_getPrefetchedData<
                          SyncRunRow,
                          $SyncRunsTable,
                          SyncSeenRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$SyncRunsTableReferences
                              ._syncSeenRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyncRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncSeenRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.syncRunId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SyncRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SyncRunsTable,
      SyncRunRow,
      $$SyncRunsTableFilterComposer,
      $$SyncRunsTableOrderingComposer,
      $$SyncRunsTableAnnotationComposer,
      $$SyncRunsTableCreateCompanionBuilder,
      $$SyncRunsTableUpdateCompanionBuilder,
      (SyncRunRow, $$SyncRunsTableReferences),
      SyncRunRow,
      PrefetchHooks Function({
        bool sourceConnectionId,
        bool syncSeenRecordsRefs,
      })
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String id,
      required String sourceConnectionId,
      required String recordType,
      required String cursor,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> id,
      Value<String> sourceConnectionId,
      Value<String> recordType,
      Value<String> cursor,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SyncCursorsTableReferences
    extends
        BaseReferences<_$VueniverseDatabase, $SyncCursorsTable, SyncCursorRow> {
  $$SyncCursorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourceConnectionsTable _sourceConnectionIdTable(
    _$VueniverseDatabase db,
  ) => db.sourceConnections.createAlias(
    'sync_cursors__source_connection_id__source_connections__id',
  );

  $$SourceConnectionsTableProcessedTableManager get sourceConnectionId {
    final $_column = $_itemColumn<String>('source_connection_id')!;

    final manager = $$SourceConnectionsTableTableManager(
      $_db,
      $_db.sourceConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceConnectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncCursorsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
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

  ColumnFilters<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourceConnectionsTableFilterComposer get sourceConnectionId {
    final $$SourceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
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

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceConnectionsTableOrderingComposer get sourceConnectionId {
    final $$SourceConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourceConnectionsTableAnnotationComposer get sourceConnectionId {
    final $$SourceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceConnectionId,
          referencedTable: $db.sourceConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sourceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (SyncCursorRow, $$SyncCursorsTableReferences),
          SyncCursorRow,
          PrefetchHooks Function({bool sourceConnectionId})
        > {
  $$SyncCursorsTableTableManager(
    _$VueniverseDatabase db,
    $SyncCursorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceConnectionId = const Value.absent(),
                Value<String> recordType = const Value.absent(),
                Value<String> cursor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                id: id,
                sourceConnectionId: sourceConnectionId,
                recordType: recordType,
                cursor: cursor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceConnectionId,
                required String recordType,
                required String cursor,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                id: id,
                sourceConnectionId: sourceConnectionId,
                recordType: recordType,
                cursor: cursor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncCursorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceConnectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceConnectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceConnectionId,
                                referencedTable: $$SyncCursorsTableReferences
                                    ._sourceConnectionIdTable(db),
                                referencedColumn: $$SyncCursorsTableReferences
                                    ._sourceConnectionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (SyncCursorRow, $$SyncCursorsTableReferences),
      SyncCursorRow,
      PrefetchHooks Function({bool sourceConnectionId})
    >;
typedef $$SyncSeenRecordsTableCreateCompanionBuilder =
    SyncSeenRecordsCompanion Function({
      required String id,
      required String syncRunId,
      required String sourceRecordHmac,
      Value<DateTime> seenAt,
      Value<int> rowid,
    });
typedef $$SyncSeenRecordsTableUpdateCompanionBuilder =
    SyncSeenRecordsCompanion Function({
      Value<String> id,
      Value<String> syncRunId,
      Value<String> sourceRecordHmac,
      Value<DateTime> seenAt,
      Value<int> rowid,
    });

final class $$SyncSeenRecordsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $SyncSeenRecordsTable,
          SyncSeenRecordRow
        > {
  $$SyncSeenRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyncRunsTable _syncRunIdTable(_$VueniverseDatabase db) =>
      db.syncRuns.createAlias('sync_seen_records__sync_run_id__sync_runs__id');

  $$SyncRunsTableProcessedTableManager get syncRunId {
    final $_column = $_itemColumn<String>('sync_run_id')!;

    final manager = $$SyncRunsTableTableManager(
      $_db,
      $_db.syncRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_syncRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncSeenRecordsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SyncSeenRecordsTable> {
  $$SyncSeenRecordsTableFilterComposer({
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

  ColumnFilters<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyncRunsTableFilterComposer get syncRunId {
    final $$SyncRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.syncRunId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableFilterComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncSeenRecordsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SyncSeenRecordsTable> {
  $$SyncSeenRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyncRunsTableOrderingComposer get syncRunId {
    final $$SyncRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.syncRunId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableOrderingComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncSeenRecordsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SyncSeenRecordsTable> {
  $$SyncSeenRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);

  $$SyncRunsTableAnnotationComposer get syncRunId {
    final $$SyncRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.syncRunId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncSeenRecordsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SyncSeenRecordsTable,
          SyncSeenRecordRow,
          $$SyncSeenRecordsTableFilterComposer,
          $$SyncSeenRecordsTableOrderingComposer,
          $$SyncSeenRecordsTableAnnotationComposer,
          $$SyncSeenRecordsTableCreateCompanionBuilder,
          $$SyncSeenRecordsTableUpdateCompanionBuilder,
          (SyncSeenRecordRow, $$SyncSeenRecordsTableReferences),
          SyncSeenRecordRow,
          PrefetchHooks Function({bool syncRunId})
        > {
  $$SyncSeenRecordsTableTableManager(
    _$VueniverseDatabase db,
    $SyncSeenRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSeenRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSeenRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSeenRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> syncRunId = const Value.absent(),
                Value<String> sourceRecordHmac = const Value.absent(),
                Value<DateTime> seenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncSeenRecordsCompanion(
                id: id,
                syncRunId: syncRunId,
                sourceRecordHmac: sourceRecordHmac,
                seenAt: seenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String syncRunId,
                required String sourceRecordHmac,
                Value<DateTime> seenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncSeenRecordsCompanion.insert(
                id: id,
                syncRunId: syncRunId,
                sourceRecordHmac: sourceRecordHmac,
                seenAt: seenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncSeenRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({syncRunId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (syncRunId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.syncRunId,
                                referencedTable:
                                    $$SyncSeenRecordsTableReferences
                                        ._syncRunIdTable(db),
                                referencedColumn:
                                    $$SyncSeenRecordsTableReferences
                                        ._syncRunIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncSeenRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SyncSeenRecordsTable,
      SyncSeenRecordRow,
      $$SyncSeenRecordsTableFilterComposer,
      $$SyncSeenRecordsTableOrderingComposer,
      $$SyncSeenRecordsTableAnnotationComposer,
      $$SyncSeenRecordsTableCreateCompanionBuilder,
      $$SyncSeenRecordsTableUpdateCompanionBuilder,
      (SyncSeenRecordRow, $$SyncSeenRecordsTableReferences),
      SyncSeenRecordRow,
      PrefetchHooks Function({bool syncRunId})
    >;
typedef $$RawRecordIndexTableCreateCompanionBuilder =
    RawRecordIndexCompanion Function({
      required String id,
      required String sourceConnectionId,
      required String sourceKind,
      Value<String?> sourceRecordHmac,
      required String canonicalPayloadHash,
      required String canonicalKind,
      required String canonicalId,
      required DateTime occurredAtUtc,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RawRecordIndexTableUpdateCompanionBuilder =
    RawRecordIndexCompanion Function({
      Value<String> id,
      Value<String> sourceConnectionId,
      Value<String> sourceKind,
      Value<String?> sourceRecordHmac,
      Value<String> canonicalPayloadHash,
      Value<String> canonicalKind,
      Value<String> canonicalId,
      Value<DateTime> occurredAtUtc,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RawRecordIndexTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $RawRecordIndexTable,
          RawRecordIndexRow
        > {
  $$RawRecordIndexTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourceConnectionsTable _sourceConnectionIdTable(
    _$VueniverseDatabase db,
  ) => db.sourceConnections.createAlias(
    'raw_record_index__source_connection_id__source_connections__id',
  );

  $$SourceConnectionsTableProcessedTableManager get sourceConnectionId {
    final $_column = $_itemColumn<String>('source_connection_id')!;

    final manager = $$SourceConnectionsTableTableManager(
      $_db,
      $_db.sourceConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceConnectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RawRecordIndexTableFilterComposer
    extends Composer<_$VueniverseDatabase, $RawRecordIndexTable> {
  $$RawRecordIndexTableFilterComposer({
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

  ColumnFilters<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalKind => $composableBuilder(
    column: $table.canonicalKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalId => $composableBuilder(
    column: $table.canonicalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourceConnectionsTableFilterComposer get sourceConnectionId {
    final $$SourceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawRecordIndexTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $RawRecordIndexTable> {
  $$RawRecordIndexTableOrderingComposer({
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

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalKind => $composableBuilder(
    column: $table.canonicalKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalId => $composableBuilder(
    column: $table.canonicalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceConnectionsTableOrderingComposer get sourceConnectionId {
    final $$SourceConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceConnectionId,
      referencedTable: $db.sourceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawRecordIndexTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $RawRecordIndexTable> {
  $$RawRecordIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRecordHmac => $composableBuilder(
    column: $table.sourceRecordHmac,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalKind => $composableBuilder(
    column: $table.canonicalKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalId => $composableBuilder(
    column: $table.canonicalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourceConnectionsTableAnnotationComposer get sourceConnectionId {
    final $$SourceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceConnectionId,
          referencedTable: $db.sourceConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sourceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$RawRecordIndexTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $RawRecordIndexTable,
          RawRecordIndexRow,
          $$RawRecordIndexTableFilterComposer,
          $$RawRecordIndexTableOrderingComposer,
          $$RawRecordIndexTableAnnotationComposer,
          $$RawRecordIndexTableCreateCompanionBuilder,
          $$RawRecordIndexTableUpdateCompanionBuilder,
          (RawRecordIndexRow, $$RawRecordIndexTableReferences),
          RawRecordIndexRow,
          PrefetchHooks Function({bool sourceConnectionId})
        > {
  $$RawRecordIndexTableTableManager(
    _$VueniverseDatabase db,
    $RawRecordIndexTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawRecordIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawRecordIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawRecordIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceConnectionId = const Value.absent(),
                Value<String> sourceKind = const Value.absent(),
                Value<String?> sourceRecordHmac = const Value.absent(),
                Value<String> canonicalPayloadHash = const Value.absent(),
                Value<String> canonicalKind = const Value.absent(),
                Value<String> canonicalId = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawRecordIndexCompanion(
                id: id,
                sourceConnectionId: sourceConnectionId,
                sourceKind: sourceKind,
                sourceRecordHmac: sourceRecordHmac,
                canonicalPayloadHash: canonicalPayloadHash,
                canonicalKind: canonicalKind,
                canonicalId: canonicalId,
                occurredAtUtc: occurredAtUtc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceConnectionId,
                required String sourceKind,
                Value<String?> sourceRecordHmac = const Value.absent(),
                required String canonicalPayloadHash,
                required String canonicalKind,
                required String canonicalId,
                required DateTime occurredAtUtc,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawRecordIndexCompanion.insert(
                id: id,
                sourceConnectionId: sourceConnectionId,
                sourceKind: sourceKind,
                sourceRecordHmac: sourceRecordHmac,
                canonicalPayloadHash: canonicalPayloadHash,
                canonicalKind: canonicalKind,
                canonicalId: canonicalId,
                occurredAtUtc: occurredAtUtc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RawRecordIndexTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceConnectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceConnectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceConnectionId,
                                referencedTable: $$RawRecordIndexTableReferences
                                    ._sourceConnectionIdTable(db),
                                referencedColumn:
                                    $$RawRecordIndexTableReferences
                                        ._sourceConnectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RawRecordIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $RawRecordIndexTable,
      RawRecordIndexRow,
      $$RawRecordIndexTableFilterComposer,
      $$RawRecordIndexTableOrderingComposer,
      $$RawRecordIndexTableAnnotationComposer,
      $$RawRecordIndexTableCreateCompanionBuilder,
      $$RawRecordIndexTableUpdateCompanionBuilder,
      (RawRecordIndexRow, $$RawRecordIndexTableReferences),
      RawRecordIndexRow,
      PrefetchHooks Function({bool sourceConnectionId})
    >;
typedef $$SignalSamplesTableCreateCompanionBuilder =
    SignalSamplesCompanion Function({
      required String id,
      required String signalType,
      required DateTime occurredAtUtc,
      required double value,
      required String unit,
      required int originalOffsetMinutes,
      required String originalLocalDate,
      required String provenanceJson,
      required String canonicalPayloadHash,
      Value<int> rowid,
    });
typedef $$SignalSamplesTableUpdateCompanionBuilder =
    SignalSamplesCompanion Function({
      Value<String> id,
      Value<String> signalType,
      Value<DateTime> occurredAtUtc,
      Value<double> value,
      Value<String> unit,
      Value<int> originalOffsetMinutes,
      Value<String> originalLocalDate,
      Value<String> provenanceJson,
      Value<String> canonicalPayloadHash,
      Value<int> rowid,
    });

class $$SignalSamplesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $SignalSamplesTable> {
  $$SignalSamplesTableFilterComposer({
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

  ColumnFilters<String> get signalType => $composableBuilder(
    column: $table.signalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSamplesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $SignalSamplesTable> {
  $$SignalSamplesTableOrderingComposer({
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

  ColumnOrderings<String> get signalType => $composableBuilder(
    column: $table.signalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSamplesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $SignalSamplesTable> {
  $$SignalSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get signalType => $composableBuilder(
    column: $table.signalType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => column,
  );
}

class $$SignalSamplesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $SignalSamplesTable,
          SignalSampleRow,
          $$SignalSamplesTableFilterComposer,
          $$SignalSamplesTableOrderingComposer,
          $$SignalSamplesTableAnnotationComposer,
          $$SignalSamplesTableCreateCompanionBuilder,
          $$SignalSamplesTableUpdateCompanionBuilder,
          (
            SignalSampleRow,
            BaseReferences<
              _$VueniverseDatabase,
              $SignalSamplesTable,
              SignalSampleRow
            >,
          ),
          SignalSampleRow,
          PrefetchHooks Function()
        > {
  $$SignalSamplesTableTableManager(
    _$VueniverseDatabase db,
    $SignalSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> signalType = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> originalOffsetMinutes = const Value.absent(),
                Value<String> originalLocalDate = const Value.absent(),
                Value<String> provenanceJson = const Value.absent(),
                Value<String> canonicalPayloadHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSamplesCompanion(
                id: id,
                signalType: signalType,
                occurredAtUtc: occurredAtUtc,
                value: value,
                unit: unit,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String signalType,
                required DateTime occurredAtUtc,
                required double value,
                required String unit,
                required int originalOffsetMinutes,
                required String originalLocalDate,
                required String provenanceJson,
                required String canonicalPayloadHash,
                Value<int> rowid = const Value.absent(),
              }) => SignalSamplesCompanion.insert(
                id: id,
                signalType: signalType,
                occurredAtUtc: occurredAtUtc,
                value: value,
                unit: unit,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $SignalSamplesTable,
      SignalSampleRow,
      $$SignalSamplesTableFilterComposer,
      $$SignalSamplesTableOrderingComposer,
      $$SignalSamplesTableAnnotationComposer,
      $$SignalSamplesTableCreateCompanionBuilder,
      $$SignalSamplesTableUpdateCompanionBuilder,
      (
        SignalSampleRow,
        BaseReferences<
          _$VueniverseDatabase,
          $SignalSamplesTable,
          SignalSampleRow
        >,
      ),
      SignalSampleRow,
      PrefetchHooks Function()
    >;
typedef $$HealthIntervalsTableCreateCompanionBuilder =
    HealthIntervalsCompanion Function({
      required String id,
      required String intervalType,
      required String category,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      required int originalOffsetMinutes,
      required String originalLocalDate,
      required String provenanceJson,
      required String canonicalPayloadHash,
      Value<int> rowid,
    });
typedef $$HealthIntervalsTableUpdateCompanionBuilder =
    HealthIntervalsCompanion Function({
      Value<String> id,
      Value<String> intervalType,
      Value<String> category,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<int> originalOffsetMinutes,
      Value<String> originalLocalDate,
      Value<String> provenanceJson,
      Value<String> canonicalPayloadHash,
      Value<int> rowid,
    });

class $$HealthIntervalsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $HealthIntervalsTable> {
  $$HealthIntervalsTableFilterComposer({
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

  ColumnFilters<String> get intervalType => $composableBuilder(
    column: $table.intervalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthIntervalsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $HealthIntervalsTable> {
  $$HealthIntervalsTableOrderingComposer({
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

  ColumnOrderings<String> get intervalType => $composableBuilder(
    column: $table.intervalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthIntervalsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $HealthIntervalsTable> {
  $$HealthIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get intervalType => $composableBuilder(
    column: $table.intervalType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => column,
  );
}

class $$HealthIntervalsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $HealthIntervalsTable,
          HealthIntervalRow,
          $$HealthIntervalsTableFilterComposer,
          $$HealthIntervalsTableOrderingComposer,
          $$HealthIntervalsTableAnnotationComposer,
          $$HealthIntervalsTableCreateCompanionBuilder,
          $$HealthIntervalsTableUpdateCompanionBuilder,
          (
            HealthIntervalRow,
            BaseReferences<
              _$VueniverseDatabase,
              $HealthIntervalsTable,
              HealthIntervalRow
            >,
          ),
          HealthIntervalRow,
          PrefetchHooks Function()
        > {
  $$HealthIntervalsTableTableManager(
    _$VueniverseDatabase db,
    $HealthIntervalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> intervalType = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<int> originalOffsetMinutes = const Value.absent(),
                Value<String> originalLocalDate = const Value.absent(),
                Value<String> provenanceJson = const Value.absent(),
                Value<String> canonicalPayloadHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthIntervalsCompanion(
                id: id,
                intervalType: intervalType,
                category: category,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String intervalType,
                required String category,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                required int originalOffsetMinutes,
                required String originalLocalDate,
                required String provenanceJson,
                required String canonicalPayloadHash,
                Value<int> rowid = const Value.absent(),
              }) => HealthIntervalsCompanion.insert(
                id: id,
                intervalType: intervalType,
                category: category,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthIntervalsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $HealthIntervalsTable,
      HealthIntervalRow,
      $$HealthIntervalsTableFilterComposer,
      $$HealthIntervalsTableOrderingComposer,
      $$HealthIntervalsTableAnnotationComposer,
      $$HealthIntervalsTableCreateCompanionBuilder,
      $$HealthIntervalsTableUpdateCompanionBuilder,
      (
        HealthIntervalRow,
        BaseReferences<
          _$VueniverseDatabase,
          $HealthIntervalsTable,
          HealthIntervalRow
        >,
      ),
      HealthIntervalRow,
      PrefetchHooks Function()
    >;
typedef $$ContextEventsTableCreateCompanionBuilder =
    ContextEventsCompanion Function({
      required String id,
      required String category,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      Value<String?> recurrenceKeyHmac,
      required int originalOffsetMinutes,
      required String originalLocalDate,
      required String provenanceJson,
      required String canonicalPayloadHash,
      Value<int> rowid,
    });
typedef $$ContextEventsTableUpdateCompanionBuilder =
    ContextEventsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<String?> recurrenceKeyHmac,
      Value<int> originalOffsetMinutes,
      Value<String> originalLocalDate,
      Value<String> provenanceJson,
      Value<String> canonicalPayloadHash,
      Value<int> rowid,
    });

final class $$ContextEventsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ContextEventsTable,
          ContextEventRow
        > {
  $$ContextEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$EventWindowsTable, List<EventWindowRow>>
  _eventWindowsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.eventWindows,
        aliasName: 'context_events__id__event_windows__context_event_id',
      );

  $$EventWindowsTableProcessedTableManager get eventWindowsRefs {
    final manager = $$EventWindowsTableTableManager(
      $_db,
      $_db.eventWindows,
    ).filter((f) => f.contextEventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventWindowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContextEventsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ContextEventsTable> {
  $$ContextEventsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceKeyHmac => $composableBuilder(
    column: $table.recurrenceKeyHmac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventWindowsRefs(
    Expression<bool> Function($$EventWindowsTableFilterComposer f) f,
  ) {
    final $$EventWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.contextEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableFilterComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContextEventsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ContextEventsTable> {
  $$ContextEventsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceKeyHmac => $composableBuilder(
    column: $table.recurrenceKeyHmac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContextEventsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ContextEventsTable> {
  $$ContextEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<String> get recurrenceKeyHmac => $composableBuilder(
    column: $table.recurrenceKeyHmac,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => column,
  );

  Expression<T> eventWindowsRefs<T extends Object>(
    Expression<T> Function($$EventWindowsTableAnnotationComposer a) f,
  ) {
    final $$EventWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.contextEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContextEventsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ContextEventsTable,
          ContextEventRow,
          $$ContextEventsTableFilterComposer,
          $$ContextEventsTableOrderingComposer,
          $$ContextEventsTableAnnotationComposer,
          $$ContextEventsTableCreateCompanionBuilder,
          $$ContextEventsTableUpdateCompanionBuilder,
          (ContextEventRow, $$ContextEventsTableReferences),
          ContextEventRow,
          PrefetchHooks Function({bool eventWindowsRefs})
        > {
  $$ContextEventsTableTableManager(
    _$VueniverseDatabase db,
    $ContextEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContextEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContextEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContextEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<String?> recurrenceKeyHmac = const Value.absent(),
                Value<int> originalOffsetMinutes = const Value.absent(),
                Value<String> originalLocalDate = const Value.absent(),
                Value<String> provenanceJson = const Value.absent(),
                Value<String> canonicalPayloadHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContextEventsCompanion(
                id: id,
                category: category,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                recurrenceKeyHmac: recurrenceKeyHmac,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                Value<String?> recurrenceKeyHmac = const Value.absent(),
                required int originalOffsetMinutes,
                required String originalLocalDate,
                required String provenanceJson,
                required String canonicalPayloadHash,
                Value<int> rowid = const Value.absent(),
              }) => ContextEventsCompanion.insert(
                id: id,
                category: category,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                recurrenceKeyHmac: recurrenceKeyHmac,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContextEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventWindowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventWindowsRefs) db.eventWindows],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventWindowsRefs)
                    await $_getPrefetchedData<
                      ContextEventRow,
                      $ContextEventsTable,
                      EventWindowRow
                    >(
                      currentTable: table,
                      referencedTable: $$ContextEventsTableReferences
                          ._eventWindowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ContextEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).eventWindowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.contextEventId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContextEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ContextEventsTable,
      ContextEventRow,
      $$ContextEventsTableFilterComposer,
      $$ContextEventsTableOrderingComposer,
      $$ContextEventsTableAnnotationComposer,
      $$ContextEventsTableCreateCompanionBuilder,
      $$ContextEventsTableUpdateCompanionBuilder,
      (ContextEventRow, $$ContextEventsTableReferences),
      ContextEventRow,
      PrefetchHooks Function({bool eventWindowsRefs})
    >;
typedef $$ManualCheckinsTableCreateCompanionBuilder =
    ManualCheckinsCompanion Function({
      required String id,
      required String category,
      required DateTime occurredAtUtc,
      required String valueJson,
      required int originalOffsetMinutes,
      required String originalLocalDate,
      required String provenanceJson,
      required String canonicalPayloadHash,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ManualCheckinsTableUpdateCompanionBuilder =
    ManualCheckinsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<DateTime> occurredAtUtc,
      Value<String> valueJson,
      Value<int> originalOffsetMinutes,
      Value<String> originalLocalDate,
      Value<String> provenanceJson,
      Value<String> canonicalPayloadHash,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ManualCheckinsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ManualCheckinsTable> {
  $$ManualCheckinsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManualCheckinsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ManualCheckinsTable> {
  $$ManualCheckinsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManualCheckinsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ManualCheckinsTable> {
  $$ManualCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get originalOffsetMinutes => $composableBuilder(
    column: $table.originalOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalLocalDate => $composableBuilder(
    column: $table.originalLocalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provenanceJson => $composableBuilder(
    column: $table.provenanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalPayloadHash => $composableBuilder(
    column: $table.canonicalPayloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ManualCheckinsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ManualCheckinsTable,
          ManualCheckinRow,
          $$ManualCheckinsTableFilterComposer,
          $$ManualCheckinsTableOrderingComposer,
          $$ManualCheckinsTableAnnotationComposer,
          $$ManualCheckinsTableCreateCompanionBuilder,
          $$ManualCheckinsTableUpdateCompanionBuilder,
          (
            ManualCheckinRow,
            BaseReferences<
              _$VueniverseDatabase,
              $ManualCheckinsTable,
              ManualCheckinRow
            >,
          ),
          ManualCheckinRow,
          PrefetchHooks Function()
        > {
  $$ManualCheckinsTableTableManager(
    _$VueniverseDatabase db,
    $ManualCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> originalOffsetMinutes = const Value.absent(),
                Value<String> originalLocalDate = const Value.absent(),
                Value<String> provenanceJson = const Value.absent(),
                Value<String> canonicalPayloadHash = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualCheckinsCompanion(
                id: id,
                category: category,
                occurredAtUtc: occurredAtUtc,
                valueJson: valueJson,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required DateTime occurredAtUtc,
                required String valueJson,
                required int originalOffsetMinutes,
                required String originalLocalDate,
                required String provenanceJson,
                required String canonicalPayloadHash,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualCheckinsCompanion.insert(
                id: id,
                category: category,
                occurredAtUtc: occurredAtUtc,
                valueJson: valueJson,
                originalOffsetMinutes: originalOffsetMinutes,
                originalLocalDate: originalLocalDate,
                provenanceJson: provenanceJson,
                canonicalPayloadHash: canonicalPayloadHash,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManualCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ManualCheckinsTable,
      ManualCheckinRow,
      $$ManualCheckinsTableFilterComposer,
      $$ManualCheckinsTableOrderingComposer,
      $$ManualCheckinsTableAnnotationComposer,
      $$ManualCheckinsTableCreateCompanionBuilder,
      $$ManualCheckinsTableUpdateCompanionBuilder,
      (
        ManualCheckinRow,
        BaseReferences<
          _$VueniverseDatabase,
          $ManualCheckinsTable,
          ManualCheckinRow
        >,
      ),
      ManualCheckinRow,
      PrefetchHooks Function()
    >;
typedef $$RecomputeJobsTableCreateCompanionBuilder =
    RecomputeJobsCompanion Function({
      required String id,
      required DateTime dirtyStartUtc,
      required DateTime dirtyEndUtc,
      required String reason,
      Value<String?> sourceId,
      required String status,
      Value<int> retryCount,
      Value<String?> lastCheckpoint,
      required int analysisVersion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RecomputeJobsTableUpdateCompanionBuilder =
    RecomputeJobsCompanion Function({
      Value<String> id,
      Value<DateTime> dirtyStartUtc,
      Value<DateTime> dirtyEndUtc,
      Value<String> reason,
      Value<String?> sourceId,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastCheckpoint,
      Value<int> analysisVersion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RecomputeJobsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $RecomputeJobsTable> {
  $$RecomputeJobsTableFilterComposer({
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

  ColumnFilters<DateTime> get dirtyStartUtc => $composableBuilder(
    column: $table.dirtyStartUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dirtyEndUtc => $composableBuilder(
    column: $table.dirtyEndUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCheckpoint => $composableBuilder(
    column: $table.lastCheckpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecomputeJobsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $RecomputeJobsTable> {
  $$RecomputeJobsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get dirtyStartUtc => $composableBuilder(
    column: $table.dirtyStartUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dirtyEndUtc => $composableBuilder(
    column: $table.dirtyEndUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCheckpoint => $composableBuilder(
    column: $table.lastCheckpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecomputeJobsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $RecomputeJobsTable> {
  $$RecomputeJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dirtyStartUtc => $composableBuilder(
    column: $table.dirtyStartUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dirtyEndUtc => $composableBuilder(
    column: $table.dirtyEndUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCheckpoint => $composableBuilder(
    column: $table.lastCheckpoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecomputeJobsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $RecomputeJobsTable,
          RecomputeJobRow,
          $$RecomputeJobsTableFilterComposer,
          $$RecomputeJobsTableOrderingComposer,
          $$RecomputeJobsTableAnnotationComposer,
          $$RecomputeJobsTableCreateCompanionBuilder,
          $$RecomputeJobsTableUpdateCompanionBuilder,
          (
            RecomputeJobRow,
            BaseReferences<
              _$VueniverseDatabase,
              $RecomputeJobsTable,
              RecomputeJobRow
            >,
          ),
          RecomputeJobRow,
          PrefetchHooks Function()
        > {
  $$RecomputeJobsTableTableManager(
    _$VueniverseDatabase db,
    $RecomputeJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecomputeJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecomputeJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecomputeJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> dirtyStartUtc = const Value.absent(),
                Value<DateTime> dirtyEndUtc = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastCheckpoint = const Value.absent(),
                Value<int> analysisVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecomputeJobsCompanion(
                id: id,
                dirtyStartUtc: dirtyStartUtc,
                dirtyEndUtc: dirtyEndUtc,
                reason: reason,
                sourceId: sourceId,
                status: status,
                retryCount: retryCount,
                lastCheckpoint: lastCheckpoint,
                analysisVersion: analysisVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime dirtyStartUtc,
                required DateTime dirtyEndUtc,
                required String reason,
                Value<String?> sourceId = const Value.absent(),
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastCheckpoint = const Value.absent(),
                required int analysisVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecomputeJobsCompanion.insert(
                id: id,
                dirtyStartUtc: dirtyStartUtc,
                dirtyEndUtc: dirtyEndUtc,
                reason: reason,
                sourceId: sourceId,
                status: status,
                retryCount: retryCount,
                lastCheckpoint: lastCheckpoint,
                analysisVersion: analysisVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecomputeJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $RecomputeJobsTable,
      RecomputeJobRow,
      $$RecomputeJobsTableFilterComposer,
      $$RecomputeJobsTableOrderingComposer,
      $$RecomputeJobsTableAnnotationComposer,
      $$RecomputeJobsTableCreateCompanionBuilder,
      $$RecomputeJobsTableUpdateCompanionBuilder,
      (
        RecomputeJobRow,
        BaseReferences<
          _$VueniverseDatabase,
          $RecomputeJobsTable,
          RecomputeJobRow
        >,
      ),
      RecomputeJobRow,
      PrefetchHooks Function()
    >;
typedef $$AnalysisRunsTableCreateCompanionBuilder =
    AnalysisRunsCompanion Function({
      required String id,
      required String status,
      required DateTime rangeStartUtc,
      required DateTime rangeEndUtc,
      required int analysisVersion,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      required String inputHash,
      Value<String?> outputHash,
      Value<int> rowid,
    });
typedef $$AnalysisRunsTableUpdateCompanionBuilder =
    AnalysisRunsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<DateTime> rangeStartUtc,
      Value<DateTime> rangeEndUtc,
      Value<int> analysisVersion,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String> inputHash,
      Value<String?> outputHash,
      Value<int> rowid,
    });

final class $$AnalysisRunsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $AnalysisRunsTable,
          AnalysisRunRow
        > {
  $$AnalysisRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventWindowsTable, List<EventWindowRow>>
  _eventWindowsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.eventWindows,
        aliasName: 'analysis_runs__id__event_windows__analysis_run_id',
      );

  $$EventWindowsTableProcessedTableManager get eventWindowsRefs {
    final manager = $$EventWindowsTableTableManager(
      $_db,
      $_db.eventWindows,
    ).filter((f) => f.analysisRunId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventWindowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EvidenceBundlesTable, List<EvidenceBundleRow>>
  _evidenceBundlesRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.evidenceBundles,
        aliasName: 'analysis_runs__id__evidence_bundles__analysis_run_id',
      );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundlesRefs {
    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.analysisRunId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _evidenceBundlesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnalysisRunsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $AnalysisRunsTable> {
  $$AnalysisRunsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rangeStartUtc => $composableBuilder(
    column: $table.rangeStartUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rangeEndUtc => $composableBuilder(
    column: $table.rangeEndUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputHash => $composableBuilder(
    column: $table.inputHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputHash => $composableBuilder(
    column: $table.outputHash,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventWindowsRefs(
    Expression<bool> Function($$EventWindowsTableFilterComposer f) f,
  ) {
    final $$EventWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.analysisRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableFilterComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> evidenceBundlesRefs(
    Expression<bool> Function($$EvidenceBundlesTableFilterComposer f) f,
  ) {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.analysisRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnalysisRunsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $AnalysisRunsTable> {
  $$AnalysisRunsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rangeStartUtc => $composableBuilder(
    column: $table.rangeStartUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rangeEndUtc => $composableBuilder(
    column: $table.rangeEndUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputHash => $composableBuilder(
    column: $table.inputHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputHash => $composableBuilder(
    column: $table.outputHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalysisRunsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $AnalysisRunsTable> {
  $$AnalysisRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get rangeStartUtc => $composableBuilder(
    column: $table.rangeStartUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rangeEndUtc => $composableBuilder(
    column: $table.rangeEndUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputHash =>
      $composableBuilder(column: $table.inputHash, builder: (column) => column);

  GeneratedColumn<String> get outputHash => $composableBuilder(
    column: $table.outputHash,
    builder: (column) => column,
  );

  Expression<T> eventWindowsRefs<T extends Object>(
    Expression<T> Function($$EventWindowsTableAnnotationComposer a) f,
  ) {
    final $$EventWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.analysisRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> evidenceBundlesRefs<T extends Object>(
    Expression<T> Function($$EvidenceBundlesTableAnnotationComposer a) f,
  ) {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.analysisRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnalysisRunsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $AnalysisRunsTable,
          AnalysisRunRow,
          $$AnalysisRunsTableFilterComposer,
          $$AnalysisRunsTableOrderingComposer,
          $$AnalysisRunsTableAnnotationComposer,
          $$AnalysisRunsTableCreateCompanionBuilder,
          $$AnalysisRunsTableUpdateCompanionBuilder,
          (AnalysisRunRow, $$AnalysisRunsTableReferences),
          AnalysisRunRow,
          PrefetchHooks Function({
            bool eventWindowsRefs,
            bool evidenceBundlesRefs,
          })
        > {
  $$AnalysisRunsTableTableManager(
    _$VueniverseDatabase db,
    $AnalysisRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysisRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> rangeStartUtc = const Value.absent(),
                Value<DateTime> rangeEndUtc = const Value.absent(),
                Value<int> analysisVersion = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> inputHash = const Value.absent(),
                Value<String?> outputHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysisRunsCompanion(
                id: id,
                status: status,
                rangeStartUtc: rangeStartUtc,
                rangeEndUtc: rangeEndUtc,
                analysisVersion: analysisVersion,
                startedAt: startedAt,
                finishedAt: finishedAt,
                inputHash: inputHash,
                outputHash: outputHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required DateTime rangeStartUtc,
                required DateTime rangeEndUtc,
                required int analysisVersion,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                required String inputHash,
                Value<String?> outputHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysisRunsCompanion.insert(
                id: id,
                status: status,
                rangeStartUtc: rangeStartUtc,
                rangeEndUtc: rangeEndUtc,
                analysisVersion: analysisVersion,
                startedAt: startedAt,
                finishedAt: finishedAt,
                inputHash: inputHash,
                outputHash: outputHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnalysisRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventWindowsRefs = false, evidenceBundlesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventWindowsRefs) db.eventWindows,
                    if (evidenceBundlesRefs) db.evidenceBundles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventWindowsRefs)
                        await $_getPrefetchedData<
                          AnalysisRunRow,
                          $AnalysisRunsTable,
                          EventWindowRow
                        >(
                          currentTable: table,
                          referencedTable: $$AnalysisRunsTableReferences
                              ._eventWindowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnalysisRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventWindowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.analysisRunId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (evidenceBundlesRefs)
                        await $_getPrefetchedData<
                          AnalysisRunRow,
                          $AnalysisRunsTable,
                          EvidenceBundleRow
                        >(
                          currentTable: table,
                          referencedTable: $$AnalysisRunsTableReferences
                              ._evidenceBundlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnalysisRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).evidenceBundlesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.analysisRunId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AnalysisRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $AnalysisRunsTable,
      AnalysisRunRow,
      $$AnalysisRunsTableFilterComposer,
      $$AnalysisRunsTableOrderingComposer,
      $$AnalysisRunsTableAnnotationComposer,
      $$AnalysisRunsTableCreateCompanionBuilder,
      $$AnalysisRunsTableUpdateCompanionBuilder,
      (AnalysisRunRow, $$AnalysisRunsTableReferences),
      AnalysisRunRow,
      PrefetchHooks Function({bool eventWindowsRefs, bool evidenceBundlesRefs})
    >;
typedef $$EventWindowsTableCreateCompanionBuilder =
    EventWindowsCompanion Function({
      required String id,
      required String analysisRunId,
      required String contextEventId,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      required String status,
      Value<String?> exclusionReason,
      Value<int> rowid,
    });
typedef $$EventWindowsTableUpdateCompanionBuilder =
    EventWindowsCompanion Function({
      Value<String> id,
      Value<String> analysisRunId,
      Value<String> contextEventId,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<String> status,
      Value<String?> exclusionReason,
      Value<int> rowid,
    });

final class $$EventWindowsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $EventWindowsTable,
          EventWindowRow
        > {
  $$EventWindowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AnalysisRunsTable _analysisRunIdTable(_$VueniverseDatabase db) => db
      .analysisRuns
      .createAlias('event_windows__analysis_run_id__analysis_runs__id');

  $$AnalysisRunsTableProcessedTableManager get analysisRunId {
    final $_column = $_itemColumn<String>('analysis_run_id')!;

    final manager = $$AnalysisRunsTableTableManager(
      $_db,
      $_db.analysisRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_analysisRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContextEventsTable _contextEventIdTable(_$VueniverseDatabase db) => db
      .contextEvents
      .createAlias('event_windows__context_event_id__context_events__id');

  $$ContextEventsTableProcessedTableManager get contextEventId {
    final $_column = $_itemColumn<String>('context_event_id')!;

    final manager = $$ContextEventsTableTableManager(
      $_db,
      $_db.contextEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contextEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ControlMatchesTable, List<ControlMatchRow>>
  _controlMatchesRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.controlMatches,
        aliasName: 'event_windows__id__control_matches__event_window_id',
      );

  $$ControlMatchesTableProcessedTableManager get controlMatchesRefs {
    final manager = $$ControlMatchesTableTableManager(
      $_db,
      $_db.controlMatches,
    ).filter((f) => f.eventWindowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_controlMatchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WindowMetricsTable, List<WindowMetricRow>>
  _windowMetricsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.windowMetrics,
        aliasName: 'event_windows__id__window_metrics__event_window_id',
      );

  $$WindowMetricsTableProcessedTableManager get windowMetricsRefs {
    final manager = $$WindowMetricsTableTableManager(
      $_db,
      $_db.windowMetrics,
    ).filter((f) => f.eventWindowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_windowMetricsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventWindowsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $EventWindowsTable> {
  $$EventWindowsTableFilterComposer({
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

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => ColumnFilters(column),
  );

  $$AnalysisRunsTableFilterComposer get analysisRunId {
    final $$AnalysisRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableFilterComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextEventsTableFilterComposer get contextEventId {
    final $$ContextEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextEventId,
      referencedTable: $db.contextEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextEventsTableFilterComposer(
            $db: $db,
            $table: $db.contextEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> controlMatchesRefs(
    Expression<bool> Function($$ControlMatchesTableFilterComposer f) f,
  ) {
    final $$ControlMatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.controlMatches,
      getReferencedColumn: (t) => t.eventWindowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ControlMatchesTableFilterComposer(
            $db: $db,
            $table: $db.controlMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> windowMetricsRefs(
    Expression<bool> Function($$WindowMetricsTableFilterComposer f) f,
  ) {
    final $$WindowMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.windowMetrics,
      getReferencedColumn: (t) => t.eventWindowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WindowMetricsTableFilterComposer(
            $db: $db,
            $table: $db.windowMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventWindowsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $EventWindowsTable> {
  $$EventWindowsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnalysisRunsTableOrderingComposer get analysisRunId {
    final $$AnalysisRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableOrderingComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextEventsTableOrderingComposer get contextEventId {
    final $$ContextEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextEventId,
      referencedTable: $db.contextEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextEventsTableOrderingComposer(
            $db: $db,
            $table: $db.contextEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventWindowsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $EventWindowsTable> {
  $$EventWindowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => column,
  );

  $$AnalysisRunsTableAnnotationComposer get analysisRunId {
    final $$AnalysisRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextEventsTableAnnotationComposer get contextEventId {
    final $$ContextEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextEventId,
      referencedTable: $db.contextEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.contextEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> controlMatchesRefs<T extends Object>(
    Expression<T> Function($$ControlMatchesTableAnnotationComposer a) f,
  ) {
    final $$ControlMatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.controlMatches,
      getReferencedColumn: (t) => t.eventWindowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ControlMatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.controlMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> windowMetricsRefs<T extends Object>(
    Expression<T> Function($$WindowMetricsTableAnnotationComposer a) f,
  ) {
    final $$WindowMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.windowMetrics,
      getReferencedColumn: (t) => t.eventWindowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WindowMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.windowMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventWindowsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $EventWindowsTable,
          EventWindowRow,
          $$EventWindowsTableFilterComposer,
          $$EventWindowsTableOrderingComposer,
          $$EventWindowsTableAnnotationComposer,
          $$EventWindowsTableCreateCompanionBuilder,
          $$EventWindowsTableUpdateCompanionBuilder,
          (EventWindowRow, $$EventWindowsTableReferences),
          EventWindowRow,
          PrefetchHooks Function({
            bool analysisRunId,
            bool contextEventId,
            bool controlMatchesRefs,
            bool windowMetricsRefs,
          })
        > {
  $$EventWindowsTableTableManager(
    _$VueniverseDatabase db,
    $EventWindowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventWindowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventWindowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventWindowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> analysisRunId = const Value.absent(),
                Value<String> contextEventId = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> exclusionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventWindowsCompanion(
                id: id,
                analysisRunId: analysisRunId,
                contextEventId: contextEventId,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                status: status,
                exclusionReason: exclusionReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String analysisRunId,
                required String contextEventId,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                required String status,
                Value<String?> exclusionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventWindowsCompanion.insert(
                id: id,
                analysisRunId: analysisRunId,
                contextEventId: contextEventId,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                status: status,
                exclusionReason: exclusionReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EventWindowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                analysisRunId = false,
                contextEventId = false,
                controlMatchesRefs = false,
                windowMetricsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (controlMatchesRefs) db.controlMatches,
                    if (windowMetricsRefs) db.windowMetrics,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (analysisRunId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.analysisRunId,
                                    referencedTable:
                                        $$EventWindowsTableReferences
                                            ._analysisRunIdTable(db),
                                    referencedColumn:
                                        $$EventWindowsTableReferences
                                            ._analysisRunIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (contextEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contextEventId,
                                    referencedTable:
                                        $$EventWindowsTableReferences
                                            ._contextEventIdTable(db),
                                    referencedColumn:
                                        $$EventWindowsTableReferences
                                            ._contextEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (controlMatchesRefs)
                        await $_getPrefetchedData<
                          EventWindowRow,
                          $EventWindowsTable,
                          ControlMatchRow
                        >(
                          currentTable: table,
                          referencedTable: $$EventWindowsTableReferences
                              ._controlMatchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventWindowsTableReferences(
                                db,
                                table,
                                p0,
                              ).controlMatchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventWindowId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (windowMetricsRefs)
                        await $_getPrefetchedData<
                          EventWindowRow,
                          $EventWindowsTable,
                          WindowMetricRow
                        >(
                          currentTable: table,
                          referencedTable: $$EventWindowsTableReferences
                              ._windowMetricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventWindowsTableReferences(
                                db,
                                table,
                                p0,
                              ).windowMetricsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventWindowId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventWindowsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $EventWindowsTable,
      EventWindowRow,
      $$EventWindowsTableFilterComposer,
      $$EventWindowsTableOrderingComposer,
      $$EventWindowsTableAnnotationComposer,
      $$EventWindowsTableCreateCompanionBuilder,
      $$EventWindowsTableUpdateCompanionBuilder,
      (EventWindowRow, $$EventWindowsTableReferences),
      EventWindowRow,
      PrefetchHooks Function({
        bool analysisRunId,
        bool contextEventId,
        bool controlMatchesRefs,
        bool windowMetricsRefs,
      })
    >;
typedef $$ControlMatchesTableCreateCompanionBuilder =
    ControlMatchesCompanion Function({
      required String id,
      required String eventWindowId,
      required DateTime startAtUtc,
      required DateTime endAtUtc,
      required double score,
      required String factorsJson,
      Value<int> rowid,
    });
typedef $$ControlMatchesTableUpdateCompanionBuilder =
    ControlMatchesCompanion Function({
      Value<String> id,
      Value<String> eventWindowId,
      Value<DateTime> startAtUtc,
      Value<DateTime> endAtUtc,
      Value<double> score,
      Value<String> factorsJson,
      Value<int> rowid,
    });

final class $$ControlMatchesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ControlMatchesTable,
          ControlMatchRow
        > {
  $$ControlMatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EventWindowsTable _eventWindowIdTable(_$VueniverseDatabase db) => db
      .eventWindows
      .createAlias('control_matches__event_window_id__event_windows__id');

  $$EventWindowsTableProcessedTableManager get eventWindowId {
    final $_column = $_itemColumn<String>('event_window_id')!;

    final manager = $$EventWindowsTableTableManager(
      $_db,
      $_db.eventWindows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventWindowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WindowMetricsTable, List<WindowMetricRow>>
  _windowMetricsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.windowMetrics,
        aliasName: 'control_matches__id__window_metrics__control_match_id',
      );

  $$WindowMetricsTableProcessedTableManager get windowMetricsRefs {
    final manager = $$WindowMetricsTableTableManager(
      $_db,
      $_db.windowMetrics,
    ).filter((f) => f.controlMatchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_windowMetricsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ControlMatchesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ControlMatchesTable> {
  $$ControlMatchesTableFilterComposer({
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

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get factorsJson => $composableBuilder(
    column: $table.factorsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$EventWindowsTableFilterComposer get eventWindowId {
    final $$EventWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableFilterComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> windowMetricsRefs(
    Expression<bool> Function($$WindowMetricsTableFilterComposer f) f,
  ) {
    final $$WindowMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.windowMetrics,
      getReferencedColumn: (t) => t.controlMatchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WindowMetricsTableFilterComposer(
            $db: $db,
            $table: $db.windowMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ControlMatchesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ControlMatchesTable> {
  $$ControlMatchesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get factorsJson => $composableBuilder(
    column: $table.factorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventWindowsTableOrderingComposer get eventWindowId {
    final $$EventWindowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableOrderingComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ControlMatchesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ControlMatchesTable> {
  $$ControlMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get factorsJson => $composableBuilder(
    column: $table.factorsJson,
    builder: (column) => column,
  );

  $$EventWindowsTableAnnotationComposer get eventWindowId {
    final $$EventWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> windowMetricsRefs<T extends Object>(
    Expression<T> Function($$WindowMetricsTableAnnotationComposer a) f,
  ) {
    final $$WindowMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.windowMetrics,
      getReferencedColumn: (t) => t.controlMatchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WindowMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.windowMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ControlMatchesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ControlMatchesTable,
          ControlMatchRow,
          $$ControlMatchesTableFilterComposer,
          $$ControlMatchesTableOrderingComposer,
          $$ControlMatchesTableAnnotationComposer,
          $$ControlMatchesTableCreateCompanionBuilder,
          $$ControlMatchesTableUpdateCompanionBuilder,
          (ControlMatchRow, $$ControlMatchesTableReferences),
          ControlMatchRow,
          PrefetchHooks Function({bool eventWindowId, bool windowMetricsRefs})
        > {
  $$ControlMatchesTableTableManager(
    _$VueniverseDatabase db,
    $ControlMatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ControlMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ControlMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ControlMatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventWindowId = const Value.absent(),
                Value<DateTime> startAtUtc = const Value.absent(),
                Value<DateTime> endAtUtc = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<String> factorsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ControlMatchesCompanion(
                id: id,
                eventWindowId: eventWindowId,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                score: score,
                factorsJson: factorsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventWindowId,
                required DateTime startAtUtc,
                required DateTime endAtUtc,
                required double score,
                required String factorsJson,
                Value<int> rowid = const Value.absent(),
              }) => ControlMatchesCompanion.insert(
                id: id,
                eventWindowId: eventWindowId,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                score: score,
                factorsJson: factorsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ControlMatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventWindowId = false, windowMetricsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (windowMetricsRefs) db.windowMetrics,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventWindowId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventWindowId,
                                    referencedTable:
                                        $$ControlMatchesTableReferences
                                            ._eventWindowIdTable(db),
                                    referencedColumn:
                                        $$ControlMatchesTableReferences
                                            ._eventWindowIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (windowMetricsRefs)
                        await $_getPrefetchedData<
                          ControlMatchRow,
                          $ControlMatchesTable,
                          WindowMetricRow
                        >(
                          currentTable: table,
                          referencedTable: $$ControlMatchesTableReferences
                              ._windowMetricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ControlMatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).windowMetricsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.controlMatchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ControlMatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ControlMatchesTable,
      ControlMatchRow,
      $$ControlMatchesTableFilterComposer,
      $$ControlMatchesTableOrderingComposer,
      $$ControlMatchesTableAnnotationComposer,
      $$ControlMatchesTableCreateCompanionBuilder,
      $$ControlMatchesTableUpdateCompanionBuilder,
      (ControlMatchRow, $$ControlMatchesTableReferences),
      ControlMatchRow,
      PrefetchHooks Function({bool eventWindowId, bool windowMetricsRefs})
    >;
typedef $$WindowMetricsTableCreateCompanionBuilder =
    WindowMetricsCompanion Function({
      required String id,
      required String eventWindowId,
      Value<String?> controlMatchId,
      required String metric,
      required double value,
      required String unit,
      required String qualityState,
      Value<int> rowid,
    });
typedef $$WindowMetricsTableUpdateCompanionBuilder =
    WindowMetricsCompanion Function({
      Value<String> id,
      Value<String> eventWindowId,
      Value<String?> controlMatchId,
      Value<String> metric,
      Value<double> value,
      Value<String> unit,
      Value<String> qualityState,
      Value<int> rowid,
    });

final class $$WindowMetricsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $WindowMetricsTable,
          WindowMetricRow
        > {
  $$WindowMetricsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EventWindowsTable _eventWindowIdTable(_$VueniverseDatabase db) => db
      .eventWindows
      .createAlias('window_metrics__event_window_id__event_windows__id');

  $$EventWindowsTableProcessedTableManager get eventWindowId {
    final $_column = $_itemColumn<String>('event_window_id')!;

    final manager = $$EventWindowsTableTableManager(
      $_db,
      $_db.eventWindows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventWindowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ControlMatchesTable _controlMatchIdTable(_$VueniverseDatabase db) =>
      db.controlMatches.createAlias(
        'window_metrics__control_match_id__control_matches__id',
      );

  $$ControlMatchesTableProcessedTableManager? get controlMatchId {
    final $_column = $_itemColumn<String>('control_match_id');
    if ($_column == null) return null;
    final manager = $$ControlMatchesTableTableManager(
      $_db,
      $_db.controlMatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_controlMatchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WindowMetricsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $WindowMetricsTable> {
  $$WindowMetricsTableFilterComposer({
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

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityState => $composableBuilder(
    column: $table.qualityState,
    builder: (column) => ColumnFilters(column),
  );

  $$EventWindowsTableFilterComposer get eventWindowId {
    final $$EventWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableFilterComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ControlMatchesTableFilterComposer get controlMatchId {
    final $$ControlMatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.controlMatchId,
      referencedTable: $db.controlMatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ControlMatchesTableFilterComposer(
            $db: $db,
            $table: $db.controlMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WindowMetricsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $WindowMetricsTable> {
  $$WindowMetricsTableOrderingComposer({
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

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityState => $composableBuilder(
    column: $table.qualityState,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventWindowsTableOrderingComposer get eventWindowId {
    final $$EventWindowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableOrderingComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ControlMatchesTableOrderingComposer get controlMatchId {
    final $$ControlMatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.controlMatchId,
      referencedTable: $db.controlMatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ControlMatchesTableOrderingComposer(
            $db: $db,
            $table: $db.controlMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WindowMetricsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $WindowMetricsTable> {
  $$WindowMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get qualityState => $composableBuilder(
    column: $table.qualityState,
    builder: (column) => column,
  );

  $$EventWindowsTableAnnotationComposer get eventWindowId {
    final $$EventWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventWindowId,
      referencedTable: $db.eventWindows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ControlMatchesTableAnnotationComposer get controlMatchId {
    final $$ControlMatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.controlMatchId,
      referencedTable: $db.controlMatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ControlMatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.controlMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WindowMetricsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $WindowMetricsTable,
          WindowMetricRow,
          $$WindowMetricsTableFilterComposer,
          $$WindowMetricsTableOrderingComposer,
          $$WindowMetricsTableAnnotationComposer,
          $$WindowMetricsTableCreateCompanionBuilder,
          $$WindowMetricsTableUpdateCompanionBuilder,
          (WindowMetricRow, $$WindowMetricsTableReferences),
          WindowMetricRow,
          PrefetchHooks Function({bool eventWindowId, bool controlMatchId})
        > {
  $$WindowMetricsTableTableManager(
    _$VueniverseDatabase db,
    $WindowMetricsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WindowMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WindowMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WindowMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventWindowId = const Value.absent(),
                Value<String?> controlMatchId = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> qualityState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WindowMetricsCompanion(
                id: id,
                eventWindowId: eventWindowId,
                controlMatchId: controlMatchId,
                metric: metric,
                value: value,
                unit: unit,
                qualityState: qualityState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventWindowId,
                Value<String?> controlMatchId = const Value.absent(),
                required String metric,
                required double value,
                required String unit,
                required String qualityState,
                Value<int> rowid = const Value.absent(),
              }) => WindowMetricsCompanion.insert(
                id: id,
                eventWindowId: eventWindowId,
                controlMatchId: controlMatchId,
                metric: metric,
                value: value,
                unit: unit,
                qualityState: qualityState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WindowMetricsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventWindowId = false, controlMatchId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventWindowId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventWindowId,
                                    referencedTable:
                                        $$WindowMetricsTableReferences
                                            ._eventWindowIdTable(db),
                                    referencedColumn:
                                        $$WindowMetricsTableReferences
                                            ._eventWindowIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (controlMatchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.controlMatchId,
                                    referencedTable:
                                        $$WindowMetricsTableReferences
                                            ._controlMatchIdTable(db),
                                    referencedColumn:
                                        $$WindowMetricsTableReferences
                                            ._controlMatchIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$WindowMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $WindowMetricsTable,
      WindowMetricRow,
      $$WindowMetricsTableFilterComposer,
      $$WindowMetricsTableOrderingComposer,
      $$WindowMetricsTableAnnotationComposer,
      $$WindowMetricsTableCreateCompanionBuilder,
      $$WindowMetricsTableUpdateCompanionBuilder,
      (WindowMetricRow, $$WindowMetricsTableReferences),
      WindowMetricRow,
      PrefetchHooks Function({bool eventWindowId, bool controlMatchId})
    >;
typedef $$EvidenceBundlesTableCreateCompanionBuilder =
    EvidenceBundlesCompanion Function({
      required String id,
      required String analysisRunId,
      required String status,
      required String title,
      required String claimType,
      required String evidenceHash,
      required int promotionPolicyVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> staleAt,
      Value<String?> staleReason,
      Value<int> rowid,
    });
typedef $$EvidenceBundlesTableUpdateCompanionBuilder =
    EvidenceBundlesCompanion Function({
      Value<String> id,
      Value<String> analysisRunId,
      Value<String> status,
      Value<String> title,
      Value<String> claimType,
      Value<String> evidenceHash,
      Value<int> promotionPolicyVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> staleAt,
      Value<String?> staleReason,
      Value<int> rowid,
    });

final class $$EvidenceBundlesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $EvidenceBundlesTable,
          EvidenceBundleRow
        > {
  $$EvidenceBundlesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnalysisRunsTable _analysisRunIdTable(_$VueniverseDatabase db) => db
      .analysisRuns
      .createAlias('evidence_bundles__analysis_run_id__analysis_runs__id');

  $$AnalysisRunsTableProcessedTableManager get analysisRunId {
    final $_column = $_itemColumn<String>('analysis_run_id')!;

    final manager = $$AnalysisRunsTableTableManager(
      $_db,
      $_db.analysisRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_analysisRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EvidenceMetricsTable, List<EvidenceMetricRow>>
  _evidenceMetricsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.evidenceMetrics,
        aliasName: 'evidence_bundles__id__evidence_metrics__evidence_bundle_id',
      );

  $$EvidenceMetricsTableProcessedTableManager get evidenceMetricsRefs {
    final manager =
        $$EvidenceMetricsTableTableManager($_db, $_db.evidenceMetrics).filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _evidenceMetricsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $EvidenceDependenciesTable,
    List<EvidenceDependencyRow>
  >
  _evidenceDependenciesRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.evidenceDependencies,
        aliasName:
            'evidence_bundles__id__evidence_dependencies__evidence_bundle_id',
      );

  $$EvidenceDependenciesTableProcessedTableManager
  get evidenceDependenciesRefs {
    final manager =
        $$EvidenceDependenciesTableTableManager(
          $_db,
          $_db.evidenceDependencies,
        ).filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _evidenceDependenciesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FindingVersionsTable, List<FindingVersionRow>>
  _findingVersionsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.findingVersions,
        aliasName: 'evidence_bundles__id__finding_versions__evidence_bundle_id',
      );

  $$FindingVersionsTableProcessedTableManager get findingVersionsRefs {
    final manager =
        $$FindingVersionsTableTableManager($_db, $_db.findingVersions).filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _findingVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExplanationsTable, List<ExplanationRow>>
  _explanationsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.explanations,
        aliasName: 'evidence_bundles__id__explanations__evidence_bundle_id',
      );

  $$ExplanationsTableProcessedTableManager get explanationsRefs {
    final manager = $$ExplanationsTableTableManager($_db, $_db.explanations)
        .filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_explanationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChatSessionsTable, List<ChatSessionRow>>
  _chatSessionsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.chatSessions,
        aliasName: 'evidence_bundles__id__chat_sessions__evidence_bundle_id',
      );

  $$ChatSessionsTableProcessedTableManager get chatSessionsRefs {
    final manager = $$ChatSessionsTableTableManager($_db, $_db.chatSessions)
        .filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_chatSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExperimentProtocolsTable,
    List<ExperimentProtocolRow>
  >
  _experimentProtocolsRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.experimentProtocols,
        aliasName:
            'evidence_bundles__id__experiment_protocols__evidence_bundle_id',
      );

  $$ExperimentProtocolsTableProcessedTableManager get experimentProtocolsRefs {
    final manager =
        $$ExperimentProtocolsTableTableManager(
          $_db,
          $_db.experimentProtocols,
        ).filter(
          (f) => f.evidenceBundleId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _experimentProtocolsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EvidenceBundlesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $EvidenceBundlesTable> {
  $$EvidenceBundlesTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimType => $composableBuilder(
    column: $table.claimType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promotionPolicyVersion => $composableBuilder(
    column: $table.promotionPolicyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staleReason => $composableBuilder(
    column: $table.staleReason,
    builder: (column) => ColumnFilters(column),
  );

  $$AnalysisRunsTableFilterComposer get analysisRunId {
    final $$AnalysisRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableFilterComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> evidenceMetricsRefs(
    Expression<bool> Function($$EvidenceMetricsTableFilterComposer f) f,
  ) {
    final $$EvidenceMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceMetrics,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceMetricsTableFilterComposer(
            $db: $db,
            $table: $db.evidenceMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> evidenceDependenciesRefs(
    Expression<bool> Function($$EvidenceDependenciesTableFilterComposer f) f,
  ) {
    final $$EvidenceDependenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceDependencies,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceDependenciesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceDependencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> findingVersionsRefs(
    Expression<bool> Function($$FindingVersionsTableFilterComposer f) f,
  ) {
    final $$FindingVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.findingVersions,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FindingVersionsTableFilterComposer(
            $db: $db,
            $table: $db.findingVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> explanationsRefs(
    Expression<bool> Function($$ExplanationsTableFilterComposer f) f,
  ) {
    final $$ExplanationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.explanations,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExplanationsTableFilterComposer(
            $db: $db,
            $table: $db.explanations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chatSessionsRefs(
    Expression<bool> Function($$ChatSessionsTableFilterComposer f) f,
  ) {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> experimentProtocolsRefs(
    Expression<bool> Function($$ExperimentProtocolsTableFilterComposer f) f,
  ) {
    final $$ExperimentProtocolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.experimentProtocols,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentProtocolsTableFilterComposer(
            $db: $db,
            $table: $db.experimentProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EvidenceBundlesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $EvidenceBundlesTable> {
  $$EvidenceBundlesTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimType => $composableBuilder(
    column: $table.claimType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promotionPolicyVersion => $composableBuilder(
    column: $table.promotionPolicyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staleReason => $composableBuilder(
    column: $table.staleReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnalysisRunsTableOrderingComposer get analysisRunId {
    final $$AnalysisRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableOrderingComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceBundlesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $EvidenceBundlesTable> {
  $$EvidenceBundlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get claimType =>
      $composableBuilder(column: $table.claimType, builder: (column) => column);

  GeneratedColumn<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get promotionPolicyVersion => $composableBuilder(
    column: $table.promotionPolicyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get staleAt =>
      $composableBuilder(column: $table.staleAt, builder: (column) => column);

  GeneratedColumn<String> get staleReason => $composableBuilder(
    column: $table.staleReason,
    builder: (column) => column,
  );

  $$AnalysisRunsTableAnnotationComposer get analysisRunId {
    final $$AnalysisRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analysisRunId,
      referencedTable: $db.analysisRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysisRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.analysisRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> evidenceMetricsRefs<T extends Object>(
    Expression<T> Function($$EvidenceMetricsTableAnnotationComposer a) f,
  ) {
    final $$EvidenceMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceMetrics,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> evidenceDependenciesRefs<T extends Object>(
    Expression<T> Function($$EvidenceDependenciesTableAnnotationComposer a) f,
  ) {
    final $$EvidenceDependenciesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.evidenceDependencies,
          getReferencedColumn: (t) => t.evidenceBundleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EvidenceDependenciesTableAnnotationComposer(
                $db: $db,
                $table: $db.evidenceDependencies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> findingVersionsRefs<T extends Object>(
    Expression<T> Function($$FindingVersionsTableAnnotationComposer a) f,
  ) {
    final $$FindingVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.findingVersions,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FindingVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.findingVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> explanationsRefs<T extends Object>(
    Expression<T> Function($$ExplanationsTableAnnotationComposer a) f,
  ) {
    final $$ExplanationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.explanations,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExplanationsTableAnnotationComposer(
            $db: $db,
            $table: $db.explanations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chatSessionsRefs<T extends Object>(
    Expression<T> Function($$ChatSessionsTableAnnotationComposer a) f,
  ) {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.evidenceBundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> experimentProtocolsRefs<T extends Object>(
    Expression<T> Function($$ExperimentProtocolsTableAnnotationComposer a) f,
  ) {
    final $$ExperimentProtocolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentProtocols,
          getReferencedColumn: (t) => t.evidenceBundleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentProtocolsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentProtocols,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EvidenceBundlesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $EvidenceBundlesTable,
          EvidenceBundleRow,
          $$EvidenceBundlesTableFilterComposer,
          $$EvidenceBundlesTableOrderingComposer,
          $$EvidenceBundlesTableAnnotationComposer,
          $$EvidenceBundlesTableCreateCompanionBuilder,
          $$EvidenceBundlesTableUpdateCompanionBuilder,
          (EvidenceBundleRow, $$EvidenceBundlesTableReferences),
          EvidenceBundleRow,
          PrefetchHooks Function({
            bool analysisRunId,
            bool evidenceMetricsRefs,
            bool evidenceDependenciesRefs,
            bool findingVersionsRefs,
            bool explanationsRefs,
            bool chatSessionsRefs,
            bool experimentProtocolsRefs,
          })
        > {
  $$EvidenceBundlesTableTableManager(
    _$VueniverseDatabase db,
    $EvidenceBundlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenceBundlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidenceBundlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidenceBundlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> analysisRunId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> claimType = const Value.absent(),
                Value<String> evidenceHash = const Value.absent(),
                Value<int> promotionPolicyVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> staleAt = const Value.absent(),
                Value<String?> staleReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceBundlesCompanion(
                id: id,
                analysisRunId: analysisRunId,
                status: status,
                title: title,
                claimType: claimType,
                evidenceHash: evidenceHash,
                promotionPolicyVersion: promotionPolicyVersion,
                createdAt: createdAt,
                staleAt: staleAt,
                staleReason: staleReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String analysisRunId,
                required String status,
                required String title,
                required String claimType,
                required String evidenceHash,
                required int promotionPolicyVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> staleAt = const Value.absent(),
                Value<String?> staleReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceBundlesCompanion.insert(
                id: id,
                analysisRunId: analysisRunId,
                status: status,
                title: title,
                claimType: claimType,
                evidenceHash: evidenceHash,
                promotionPolicyVersion: promotionPolicyVersion,
                createdAt: createdAt,
                staleAt: staleAt,
                staleReason: staleReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EvidenceBundlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                analysisRunId = false,
                evidenceMetricsRefs = false,
                evidenceDependenciesRefs = false,
                findingVersionsRefs = false,
                explanationsRefs = false,
                chatSessionsRefs = false,
                experimentProtocolsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (evidenceMetricsRefs) db.evidenceMetrics,
                    if (evidenceDependenciesRefs) db.evidenceDependencies,
                    if (findingVersionsRefs) db.findingVersions,
                    if (explanationsRefs) db.explanations,
                    if (chatSessionsRefs) db.chatSessions,
                    if (experimentProtocolsRefs) db.experimentProtocols,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (analysisRunId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.analysisRunId,
                                    referencedTable:
                                        $$EvidenceBundlesTableReferences
                                            ._analysisRunIdTable(db),
                                    referencedColumn:
                                        $$EvidenceBundlesTableReferences
                                            ._analysisRunIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (evidenceMetricsRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          EvidenceMetricRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._evidenceMetricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).evidenceMetricsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (evidenceDependenciesRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          EvidenceDependencyRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._evidenceDependenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).evidenceDependenciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (findingVersionsRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          FindingVersionRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._findingVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).findingVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (explanationsRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          ExplanationRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._explanationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).explanationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chatSessionsRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          ChatSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._chatSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).chatSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (experimentProtocolsRefs)
                        await $_getPrefetchedData<
                          EvidenceBundleRow,
                          $EvidenceBundlesTable,
                          ExperimentProtocolRow
                        >(
                          currentTable: table,
                          referencedTable: $$EvidenceBundlesTableReferences
                              ._experimentProtocolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EvidenceBundlesTableReferences(
                                db,
                                table,
                                p0,
                              ).experimentProtocolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.evidenceBundleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EvidenceBundlesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $EvidenceBundlesTable,
      EvidenceBundleRow,
      $$EvidenceBundlesTableFilterComposer,
      $$EvidenceBundlesTableOrderingComposer,
      $$EvidenceBundlesTableAnnotationComposer,
      $$EvidenceBundlesTableCreateCompanionBuilder,
      $$EvidenceBundlesTableUpdateCompanionBuilder,
      (EvidenceBundleRow, $$EvidenceBundlesTableReferences),
      EvidenceBundleRow,
      PrefetchHooks Function({
        bool analysisRunId,
        bool evidenceMetricsRefs,
        bool evidenceDependenciesRefs,
        bool findingVersionsRefs,
        bool explanationsRefs,
        bool chatSessionsRefs,
        bool experimentProtocolsRefs,
      })
    >;
typedef $$EvidenceMetricsTableCreateCompanionBuilder =
    EvidenceMetricsCompanion Function({
      required String id,
      required String evidenceBundleId,
      required String metric,
      required double value,
      Value<double?> lowerBound,
      Value<double?> upperBound,
      required String unit,
      Value<int> rowid,
    });
typedef $$EvidenceMetricsTableUpdateCompanionBuilder =
    EvidenceMetricsCompanion Function({
      Value<String> id,
      Value<String> evidenceBundleId,
      Value<String> metric,
      Value<double> value,
      Value<double?> lowerBound,
      Value<double?> upperBound,
      Value<String> unit,
      Value<int> rowid,
    });

final class $$EvidenceMetricsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $EvidenceMetricsTable,
          EvidenceMetricRow
        > {
  $$EvidenceMetricsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'evidence_metrics__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id')!;

    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvidenceMetricsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $EvidenceMetricsTable> {
  $$EvidenceMetricsTableFilterComposer({
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

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lowerBound => $composableBuilder(
    column: $table.lowerBound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get upperBound => $composableBuilder(
    column: $table.upperBound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceMetricsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $EvidenceMetricsTable> {
  $$EvidenceMetricsTableOrderingComposer({
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

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lowerBound => $composableBuilder(
    column: $table.lowerBound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get upperBound => $composableBuilder(
    column: $table.upperBound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceMetricsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $EvidenceMetricsTable> {
  $$EvidenceMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get lowerBound => $composableBuilder(
    column: $table.lowerBound,
    builder: (column) => column,
  );

  GeneratedColumn<double> get upperBound => $composableBuilder(
    column: $table.upperBound,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceMetricsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $EvidenceMetricsTable,
          EvidenceMetricRow,
          $$EvidenceMetricsTableFilterComposer,
          $$EvidenceMetricsTableOrderingComposer,
          $$EvidenceMetricsTableAnnotationComposer,
          $$EvidenceMetricsTableCreateCompanionBuilder,
          $$EvidenceMetricsTableUpdateCompanionBuilder,
          (EvidenceMetricRow, $$EvidenceMetricsTableReferences),
          EvidenceMetricRow,
          PrefetchHooks Function({bool evidenceBundleId})
        > {
  $$EvidenceMetricsTableTableManager(
    _$VueniverseDatabase db,
    $EvidenceMetricsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenceMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidenceMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidenceMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> evidenceBundleId = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<double?> lowerBound = const Value.absent(),
                Value<double?> upperBound = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceMetricsCompanion(
                id: id,
                evidenceBundleId: evidenceBundleId,
                metric: metric,
                value: value,
                lowerBound: lowerBound,
                upperBound: upperBound,
                unit: unit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String evidenceBundleId,
                required String metric,
                required double value,
                Value<double?> lowerBound = const Value.absent(),
                Value<double?> upperBound = const Value.absent(),
                required String unit,
                Value<int> rowid = const Value.absent(),
              }) => EvidenceMetricsCompanion.insert(
                id: id,
                evidenceBundleId: evidenceBundleId,
                metric: metric,
                value: value,
                lowerBound: lowerBound,
                upperBound: upperBound,
                unit: unit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EvidenceMetricsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({evidenceBundleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (evidenceBundleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.evidenceBundleId,
                                referencedTable:
                                    $$EvidenceMetricsTableReferences
                                        ._evidenceBundleIdTable(db),
                                referencedColumn:
                                    $$EvidenceMetricsTableReferences
                                        ._evidenceBundleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EvidenceMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $EvidenceMetricsTable,
      EvidenceMetricRow,
      $$EvidenceMetricsTableFilterComposer,
      $$EvidenceMetricsTableOrderingComposer,
      $$EvidenceMetricsTableAnnotationComposer,
      $$EvidenceMetricsTableCreateCompanionBuilder,
      $$EvidenceMetricsTableUpdateCompanionBuilder,
      (EvidenceMetricRow, $$EvidenceMetricsTableReferences),
      EvidenceMetricRow,
      PrefetchHooks Function({bool evidenceBundleId})
    >;
typedef $$EvidenceDependenciesTableCreateCompanionBuilder =
    EvidenceDependenciesCompanion Function({
      required String id,
      required String evidenceBundleId,
      required String dependencyKind,
      required String dependencyId,
      required String dependencyHash,
      Value<int> rowid,
    });
typedef $$EvidenceDependenciesTableUpdateCompanionBuilder =
    EvidenceDependenciesCompanion Function({
      Value<String> id,
      Value<String> evidenceBundleId,
      Value<String> dependencyKind,
      Value<String> dependencyId,
      Value<String> dependencyHash,
      Value<int> rowid,
    });

final class $$EvidenceDependenciesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $EvidenceDependenciesTable,
          EvidenceDependencyRow
        > {
  $$EvidenceDependenciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'evidence_dependencies__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id')!;

    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvidenceDependenciesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $EvidenceDependenciesTable> {
  $$EvidenceDependenciesTableFilterComposer({
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

  ColumnFilters<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceDependenciesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $EvidenceDependenciesTable> {
  $$EvidenceDependenciesTableOrderingComposer({
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

  ColumnOrderings<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceDependenciesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $EvidenceDependenciesTable> {
  $$EvidenceDependenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => column,
  );

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceDependenciesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $EvidenceDependenciesTable,
          EvidenceDependencyRow,
          $$EvidenceDependenciesTableFilterComposer,
          $$EvidenceDependenciesTableOrderingComposer,
          $$EvidenceDependenciesTableAnnotationComposer,
          $$EvidenceDependenciesTableCreateCompanionBuilder,
          $$EvidenceDependenciesTableUpdateCompanionBuilder,
          (EvidenceDependencyRow, $$EvidenceDependenciesTableReferences),
          EvidenceDependencyRow,
          PrefetchHooks Function({bool evidenceBundleId})
        > {
  $$EvidenceDependenciesTableTableManager(
    _$VueniverseDatabase db,
    $EvidenceDependenciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenceDependenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidenceDependenciesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EvidenceDependenciesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> evidenceBundleId = const Value.absent(),
                Value<String> dependencyKind = const Value.absent(),
                Value<String> dependencyId = const Value.absent(),
                Value<String> dependencyHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceDependenciesCompanion(
                id: id,
                evidenceBundleId: evidenceBundleId,
                dependencyKind: dependencyKind,
                dependencyId: dependencyId,
                dependencyHash: dependencyHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String evidenceBundleId,
                required String dependencyKind,
                required String dependencyId,
                required String dependencyHash,
                Value<int> rowid = const Value.absent(),
              }) => EvidenceDependenciesCompanion.insert(
                id: id,
                evidenceBundleId: evidenceBundleId,
                dependencyKind: dependencyKind,
                dependencyId: dependencyId,
                dependencyHash: dependencyHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EvidenceDependenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({evidenceBundleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (evidenceBundleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.evidenceBundleId,
                                referencedTable:
                                    $$EvidenceDependenciesTableReferences
                                        ._evidenceBundleIdTable(db),
                                referencedColumn:
                                    $$EvidenceDependenciesTableReferences
                                        ._evidenceBundleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EvidenceDependenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $EvidenceDependenciesTable,
      EvidenceDependencyRow,
      $$EvidenceDependenciesTableFilterComposer,
      $$EvidenceDependenciesTableOrderingComposer,
      $$EvidenceDependenciesTableAnnotationComposer,
      $$EvidenceDependenciesTableCreateCompanionBuilder,
      $$EvidenceDependenciesTableUpdateCompanionBuilder,
      (EvidenceDependencyRow, $$EvidenceDependenciesTableReferences),
      EvidenceDependencyRow,
      PrefetchHooks Function({bool evidenceBundleId})
    >;
typedef $$FindingVersionsTableCreateCompanionBuilder =
    FindingVersionsCompanion Function({
      required String id,
      required String findingId,
      required String evidenceBundleId,
      required int version,
      required String status,
      required DateTime validFrom,
      Value<DateTime?> validUntil,
      Value<String?> supersedesId,
      Value<int> rowid,
    });
typedef $$FindingVersionsTableUpdateCompanionBuilder =
    FindingVersionsCompanion Function({
      Value<String> id,
      Value<String> findingId,
      Value<String> evidenceBundleId,
      Value<int> version,
      Value<String> status,
      Value<DateTime> validFrom,
      Value<DateTime?> validUntil,
      Value<String?> supersedesId,
      Value<int> rowid,
    });

final class $$FindingVersionsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $FindingVersionsTable,
          FindingVersionRow
        > {
  $$FindingVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'finding_versions__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id')!;

    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FindingVersionsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $FindingVersionsTable> {
  $$FindingVersionsTableFilterComposer({
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

  ColumnFilters<String> get findingId => $composableBuilder(
    column: $table.findingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FindingVersionsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $FindingVersionsTable> {
  $$FindingVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get findingId => $composableBuilder(
    column: $table.findingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FindingVersionsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $FindingVersionsTable> {
  $$FindingVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get findingId =>
      $composableBuilder(column: $table.findingId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => column,
  );

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FindingVersionsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $FindingVersionsTable,
          FindingVersionRow,
          $$FindingVersionsTableFilterComposer,
          $$FindingVersionsTableOrderingComposer,
          $$FindingVersionsTableAnnotationComposer,
          $$FindingVersionsTableCreateCompanionBuilder,
          $$FindingVersionsTableUpdateCompanionBuilder,
          (FindingVersionRow, $$FindingVersionsTableReferences),
          FindingVersionRow,
          PrefetchHooks Function({bool evidenceBundleId})
        > {
  $$FindingVersionsTableTableManager(
    _$VueniverseDatabase db,
    $FindingVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FindingVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FindingVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FindingVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> findingId = const Value.absent(),
                Value<String> evidenceBundleId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> validFrom = const Value.absent(),
                Value<DateTime?> validUntil = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FindingVersionsCompanion(
                id: id,
                findingId: findingId,
                evidenceBundleId: evidenceBundleId,
                version: version,
                status: status,
                validFrom: validFrom,
                validUntil: validUntil,
                supersedesId: supersedesId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String findingId,
                required String evidenceBundleId,
                required int version,
                required String status,
                required DateTime validFrom,
                Value<DateTime?> validUntil = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FindingVersionsCompanion.insert(
                id: id,
                findingId: findingId,
                evidenceBundleId: evidenceBundleId,
                version: version,
                status: status,
                validFrom: validFrom,
                validUntil: validUntil,
                supersedesId: supersedesId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FindingVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({evidenceBundleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (evidenceBundleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.evidenceBundleId,
                                referencedTable:
                                    $$FindingVersionsTableReferences
                                        ._evidenceBundleIdTable(db),
                                referencedColumn:
                                    $$FindingVersionsTableReferences
                                        ._evidenceBundleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FindingVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $FindingVersionsTable,
      FindingVersionRow,
      $$FindingVersionsTableFilterComposer,
      $$FindingVersionsTableOrderingComposer,
      $$FindingVersionsTableAnnotationComposer,
      $$FindingVersionsTableCreateCompanionBuilder,
      $$FindingVersionsTableUpdateCompanionBuilder,
      (FindingVersionRow, $$FindingVersionsTableReferences),
      FindingVersionRow,
      PrefetchHooks Function({bool evidenceBundleId})
    >;
typedef $$ExplanationsTableCreateCompanionBuilder =
    ExplanationsCompanion Function({
      required String id,
      required String evidenceBundleId,
      Value<String> evidenceHash,
      Value<String> intent,
      Value<String?> requestHash,
      required String runtime,
      Value<String> modelName,
      required String content,
      required String safetyState,
      Value<String> safetyFailuresJson,
      Value<String?> failureCode,
      required int promptVersion,
      required int outputGuardVersion,
      Value<int> latencyMillis,
      Value<bool> schemaValid,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ExplanationsTableUpdateCompanionBuilder =
    ExplanationsCompanion Function({
      Value<String> id,
      Value<String> evidenceBundleId,
      Value<String> evidenceHash,
      Value<String> intent,
      Value<String?> requestHash,
      Value<String> runtime,
      Value<String> modelName,
      Value<String> content,
      Value<String> safetyState,
      Value<String> safetyFailuresJson,
      Value<String?> failureCode,
      Value<int> promptVersion,
      Value<int> outputGuardVersion,
      Value<int> latencyMillis,
      Value<bool> schemaValid,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ExplanationsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ExplanationsTable,
          ExplanationRow
        > {
  $$ExplanationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'explanations__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id')!;

    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExplanationsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExplanationsTable> {
  $$ExplanationsTableFilterComposer({
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

  ColumnFilters<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safetyFailuresJson => $composableBuilder(
    column: $table.safetyFailuresJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputGuardVersion => $composableBuilder(
    column: $table.outputGuardVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMillis => $composableBuilder(
    column: $table.latencyMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get schemaValid => $composableBuilder(
    column: $table.schemaValid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExplanationsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExplanationsTable> {
  $$ExplanationsTableOrderingComposer({
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

  ColumnOrderings<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safetyFailuresJson => $composableBuilder(
    column: $table.safetyFailuresJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputGuardVersion => $composableBuilder(
    column: $table.outputGuardVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMillis => $composableBuilder(
    column: $table.latencyMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get schemaValid => $composableBuilder(
    column: $table.schemaValid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExplanationsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExplanationsTable> {
  $$ExplanationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intent =>
      $composableBuilder(column: $table.intent, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runtime =>
      $composableBuilder(column: $table.runtime, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get safetyFailuresJson => $composableBuilder(
    column: $table.safetyFailuresJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputGuardVersion => $composableBuilder(
    column: $table.outputGuardVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMillis => $composableBuilder(
    column: $table.latencyMillis,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get schemaValid => $composableBuilder(
    column: $table.schemaValid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExplanationsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExplanationsTable,
          ExplanationRow,
          $$ExplanationsTableFilterComposer,
          $$ExplanationsTableOrderingComposer,
          $$ExplanationsTableAnnotationComposer,
          $$ExplanationsTableCreateCompanionBuilder,
          $$ExplanationsTableUpdateCompanionBuilder,
          (ExplanationRow, $$ExplanationsTableReferences),
          ExplanationRow,
          PrefetchHooks Function({bool evidenceBundleId})
        > {
  $$ExplanationsTableTableManager(
    _$VueniverseDatabase db,
    $ExplanationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExplanationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExplanationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExplanationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> evidenceBundleId = const Value.absent(),
                Value<String> evidenceHash = const Value.absent(),
                Value<String> intent = const Value.absent(),
                Value<String?> requestHash = const Value.absent(),
                Value<String> runtime = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> safetyState = const Value.absent(),
                Value<String> safetyFailuresJson = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> promptVersion = const Value.absent(),
                Value<int> outputGuardVersion = const Value.absent(),
                Value<int> latencyMillis = const Value.absent(),
                Value<bool> schemaValid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExplanationsCompanion(
                id: id,
                evidenceBundleId: evidenceBundleId,
                evidenceHash: evidenceHash,
                intent: intent,
                requestHash: requestHash,
                runtime: runtime,
                modelName: modelName,
                content: content,
                safetyState: safetyState,
                safetyFailuresJson: safetyFailuresJson,
                failureCode: failureCode,
                promptVersion: promptVersion,
                outputGuardVersion: outputGuardVersion,
                latencyMillis: latencyMillis,
                schemaValid: schemaValid,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String evidenceBundleId,
                Value<String> evidenceHash = const Value.absent(),
                Value<String> intent = const Value.absent(),
                Value<String?> requestHash = const Value.absent(),
                required String runtime,
                Value<String> modelName = const Value.absent(),
                required String content,
                required String safetyState,
                Value<String> safetyFailuresJson = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                required int promptVersion,
                required int outputGuardVersion,
                Value<int> latencyMillis = const Value.absent(),
                Value<bool> schemaValid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExplanationsCompanion.insert(
                id: id,
                evidenceBundleId: evidenceBundleId,
                evidenceHash: evidenceHash,
                intent: intent,
                requestHash: requestHash,
                runtime: runtime,
                modelName: modelName,
                content: content,
                safetyState: safetyState,
                safetyFailuresJson: safetyFailuresJson,
                failureCode: failureCode,
                promptVersion: promptVersion,
                outputGuardVersion: outputGuardVersion,
                latencyMillis: latencyMillis,
                schemaValid: schemaValid,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExplanationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({evidenceBundleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (evidenceBundleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.evidenceBundleId,
                                referencedTable: $$ExplanationsTableReferences
                                    ._evidenceBundleIdTable(db),
                                referencedColumn: $$ExplanationsTableReferences
                                    ._evidenceBundleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExplanationsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExplanationsTable,
      ExplanationRow,
      $$ExplanationsTableFilterComposer,
      $$ExplanationsTableOrderingComposer,
      $$ExplanationsTableAnnotationComposer,
      $$ExplanationsTableCreateCompanionBuilder,
      $$ExplanationsTableUpdateCompanionBuilder,
      (ExplanationRow, $$ExplanationsTableReferences),
      ExplanationRow,
      PrefetchHooks Function({bool evidenceBundleId})
    >;
typedef $$ChatSessionsTableCreateCompanionBuilder =
    ChatSessionsCompanion Function({
      required String id,
      required String evidenceBundleId,
      Value<DateTime> createdAt,
      Value<DateTime?> closedAt,
      Value<int> rowid,
    });
typedef $$ChatSessionsTableUpdateCompanionBuilder =
    ChatSessionsCompanion Function({
      Value<String> id,
      Value<String> evidenceBundleId,
      Value<DateTime> createdAt,
      Value<DateTime?> closedAt,
      Value<int> rowid,
    });

final class $$ChatSessionsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ChatSessionsTable,
          ChatSessionRow
        > {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'chat_sessions__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id')!;

    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageRow>>
  _chatMessagesRefsTable(_$VueniverseDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.chatMessages,
        aliasName: 'chat_sessions__id__chat_messages__chat_session_id',
      );

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager(
      $_db,
      $_db.chatMessages,
    ).filter((f) => f.chatSessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chatMessagesRefs(
    Expression<bool> Function($$ChatMessagesTableFilterComposer f) f,
  ) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.chatSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableFilterComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chatMessagesRefs<T extends Object>(
    Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f,
  ) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.chatSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ChatSessionsTable,
          ChatSessionRow,
          $$ChatSessionsTableFilterComposer,
          $$ChatSessionsTableOrderingComposer,
          $$ChatSessionsTableAnnotationComposer,
          $$ChatSessionsTableCreateCompanionBuilder,
          $$ChatSessionsTableUpdateCompanionBuilder,
          (ChatSessionRow, $$ChatSessionsTableReferences),
          ChatSessionRow,
          PrefetchHooks Function({bool evidenceBundleId, bool chatMessagesRefs})
        > {
  $$ChatSessionsTableTableManager(
    _$VueniverseDatabase db,
    $ChatSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> evidenceBundleId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion(
                id: id,
                evidenceBundleId: evidenceBundleId,
                createdAt: createdAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String evidenceBundleId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion.insert(
                id: id,
                evidenceBundleId: evidenceBundleId,
                createdAt: createdAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({evidenceBundleId = false, chatMessagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chatMessagesRefs) db.chatMessages,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (evidenceBundleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.evidenceBundleId,
                                    referencedTable:
                                        $$ChatSessionsTableReferences
                                            ._evidenceBundleIdTable(db),
                                    referencedColumn:
                                        $$ChatSessionsTableReferences
                                            ._evidenceBundleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chatMessagesRefs)
                        await $_getPrefetchedData<
                          ChatSessionRow,
                          $ChatSessionsTable,
                          ChatMessageRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChatSessionsTableReferences
                              ._chatMessagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChatSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).chatMessagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chatSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChatSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ChatSessionsTable,
      ChatSessionRow,
      $$ChatSessionsTableFilterComposer,
      $$ChatSessionsTableOrderingComposer,
      $$ChatSessionsTableAnnotationComposer,
      $$ChatSessionsTableCreateCompanionBuilder,
      $$ChatSessionsTableUpdateCompanionBuilder,
      (ChatSessionRow, $$ChatSessionsTableReferences),
      ChatSessionRow,
      PrefetchHooks Function({bool evidenceBundleId, bool chatMessagesRefs})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String chatSessionId,
      required String role,
      required String content,
      required String safetyState,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> chatSessionId,
      Value<String> role,
      Value<String> content,
      Value<String> safetyState,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ChatMessagesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ChatMessagesTable,
          ChatMessageRow
        > {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _chatSessionIdTable(_$VueniverseDatabase db) => db
      .chatSessions
      .createAlias('chat_messages__chat_session_id__chat_sessions__id');

  $$ChatSessionsTableProcessedTableManager get chatSessionId {
    final $_column = $_itemColumn<String>('chat_session_id')!;

    final manager = $$ChatSessionsTableTableManager(
      $_db,
      $_db.chatSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatSessionsTableFilterComposer get chatSessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatSessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatSessionsTableOrderingComposer get chatSessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatSessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get safetyState => $composableBuilder(
    column: $table.safetyState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get chatSessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatSessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (ChatMessageRow, $$ChatMessagesTableReferences),
          ChatMessageRow,
          PrefetchHooks Function({bool chatSessionId})
        > {
  $$ChatMessagesTableTableManager(
    _$VueniverseDatabase db,
    $ChatMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chatSessionId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> safetyState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                chatSessionId: chatSessionId,
                role: role,
                content: content,
                safetyState: safetyState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chatSessionId,
                required String role,
                required String content,
                required String safetyState,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                chatSessionId: chatSessionId,
                role: role,
                content: content,
                safetyState: safetyState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatSessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chatSessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chatSessionId,
                                referencedTable: $$ChatMessagesTableReferences
                                    ._chatSessionIdTable(db),
                                referencedColumn: $$ChatMessagesTableReferences
                                    ._chatSessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (ChatMessageRow, $$ChatMessagesTableReferences),
      ChatMessageRow,
      PrefetchHooks Function({bool chatSessionId})
    >;
typedef $$ExperimentProtocolsTableCreateCompanionBuilder =
    ExperimentProtocolsCompanion Function({
      required String id,
      Value<String?> evidenceBundleId,
      required String title,
      required String status,
      required String protocolJson,
      required int version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ExperimentProtocolsTableUpdateCompanionBuilder =
    ExperimentProtocolsCompanion Function({
      Value<String> id,
      Value<String?> evidenceBundleId,
      Value<String> title,
      Value<String> status,
      Value<String> protocolJson,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExperimentProtocolsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ExperimentProtocolsTable,
          ExperimentProtocolRow
        > {
  $$ExperimentProtocolsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EvidenceBundlesTable _evidenceBundleIdTable(
    _$VueniverseDatabase db,
  ) => db.evidenceBundles.createAlias(
    'experiment_protocols__evidence_bundle_id__evidence_bundles__id',
  );

  $$EvidenceBundlesTableProcessedTableManager? get evidenceBundleId {
    final $_column = $_itemColumn<String>('evidence_bundle_id');
    if ($_column == null) return null;
    final manager = $$EvidenceBundlesTableTableManager(
      $_db,
      $_db.evidenceBundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_evidenceBundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ExperimentOccurrencesTable,
    List<ExperimentOccurrenceRow>
  >
  _experimentOccurrencesRefsTable(
    _$VueniverseDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.experimentOccurrences,
    aliasName:
        'experiment_protocols__id__experiment_occurrences__experiment_protocol_id',
  );

  $$ExperimentOccurrencesTableProcessedTableManager
  get experimentOccurrencesRefs {
    final manager =
        $$ExperimentOccurrencesTableTableManager(
          $_db,
          $_db.experimentOccurrences,
        ).filter(
          (f) =>
              f.experimentProtocolId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _experimentOccurrencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExperimentResultsTable, List<ExperimentResultRow>>
  _experimentResultsRefsTable(
    _$VueniverseDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.experimentResults,
    aliasName:
        'experiment_protocols__id__experiment_results__experiment_protocol_id',
  );

  $$ExperimentResultsTableProcessedTableManager get experimentResultsRefs {
    final manager =
        $$ExperimentResultsTableTableManager(
          $_db,
          $_db.experimentResults,
        ).filter(
          (f) =>
              f.experimentProtocolId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _experimentResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExperimentProtocolsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExperimentProtocolsTable> {
  $$ExperimentProtocolsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EvidenceBundlesTableFilterComposer get evidenceBundleId {
    final $$EvidenceBundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableFilterComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> experimentOccurrencesRefs(
    Expression<bool> Function($$ExperimentOccurrencesTableFilterComposer f) f,
  ) {
    final $$ExperimentOccurrencesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentOccurrences,
          getReferencedColumn: (t) => t.experimentProtocolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentOccurrencesTableFilterComposer(
                $db: $db,
                $table: $db.experimentOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> experimentResultsRefs(
    Expression<bool> Function($$ExperimentResultsTableFilterComposer f) f,
  ) {
    final $$ExperimentResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.experimentResults,
      getReferencedColumn: (t) => t.experimentProtocolId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentResultsTableFilterComposer(
            $db: $db,
            $table: $db.experimentResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExperimentProtocolsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExperimentProtocolsTable> {
  $$ExperimentProtocolsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EvidenceBundlesTableOrderingComposer get evidenceBundleId {
    final $$EvidenceBundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableOrderingComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExperimentProtocolsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExperimentProtocolsTable> {
  $$ExperimentProtocolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EvidenceBundlesTableAnnotationComposer get evidenceBundleId {
    final $$EvidenceBundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.evidenceBundleId,
      referencedTable: $db.evidenceBundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceBundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceBundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> experimentOccurrencesRefs<T extends Object>(
    Expression<T> Function($$ExperimentOccurrencesTableAnnotationComposer a) f,
  ) {
    final $$ExperimentOccurrencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentOccurrences,
          getReferencedColumn: (t) => t.experimentProtocolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentOccurrencesTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> experimentResultsRefs<T extends Object>(
    Expression<T> Function($$ExperimentResultsTableAnnotationComposer a) f,
  ) {
    final $$ExperimentResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentResults,
          getReferencedColumn: (t) => t.experimentProtocolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentProtocolsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExperimentProtocolsTable,
          ExperimentProtocolRow,
          $$ExperimentProtocolsTableFilterComposer,
          $$ExperimentProtocolsTableOrderingComposer,
          $$ExperimentProtocolsTableAnnotationComposer,
          $$ExperimentProtocolsTableCreateCompanionBuilder,
          $$ExperimentProtocolsTableUpdateCompanionBuilder,
          (ExperimentProtocolRow, $$ExperimentProtocolsTableReferences),
          ExperimentProtocolRow,
          PrefetchHooks Function({
            bool evidenceBundleId,
            bool experimentOccurrencesRefs,
            bool experimentResultsRefs,
          })
        > {
  $$ExperimentProtocolsTableTableManager(
    _$VueniverseDatabase db,
    $ExperimentProtocolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentProtocolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExperimentProtocolsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExperimentProtocolsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> evidenceBundleId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> protocolJson = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentProtocolsCompanion(
                id: id,
                evidenceBundleId: evidenceBundleId,
                title: title,
                status: status,
                protocolJson: protocolJson,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> evidenceBundleId = const Value.absent(),
                required String title,
                required String status,
                required String protocolJson,
                required int version,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentProtocolsCompanion.insert(
                id: id,
                evidenceBundleId: evidenceBundleId,
                title: title,
                status: status,
                protocolJson: protocolJson,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExperimentProtocolsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                evidenceBundleId = false,
                experimentOccurrencesRefs = false,
                experimentResultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (experimentOccurrencesRefs) db.experimentOccurrences,
                    if (experimentResultsRefs) db.experimentResults,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (evidenceBundleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.evidenceBundleId,
                                    referencedTable:
                                        $$ExperimentProtocolsTableReferences
                                            ._evidenceBundleIdTable(db),
                                    referencedColumn:
                                        $$ExperimentProtocolsTableReferences
                                            ._evidenceBundleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (experimentOccurrencesRefs)
                        await $_getPrefetchedData<
                          ExperimentProtocolRow,
                          $ExperimentProtocolsTable,
                          ExperimentOccurrenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExperimentProtocolsTableReferences
                              ._experimentOccurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExperimentProtocolsTableReferences(
                                db,
                                table,
                                p0,
                              ).experimentOccurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.experimentProtocolId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (experimentResultsRefs)
                        await $_getPrefetchedData<
                          ExperimentProtocolRow,
                          $ExperimentProtocolsTable,
                          ExperimentResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExperimentProtocolsTableReferences
                              ._experimentResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExperimentProtocolsTableReferences(
                                db,
                                table,
                                p0,
                              ).experimentResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.experimentProtocolId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExperimentProtocolsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExperimentProtocolsTable,
      ExperimentProtocolRow,
      $$ExperimentProtocolsTableFilterComposer,
      $$ExperimentProtocolsTableOrderingComposer,
      $$ExperimentProtocolsTableAnnotationComposer,
      $$ExperimentProtocolsTableCreateCompanionBuilder,
      $$ExperimentProtocolsTableUpdateCompanionBuilder,
      (ExperimentProtocolRow, $$ExperimentProtocolsTableReferences),
      ExperimentProtocolRow,
      PrefetchHooks Function({
        bool evidenceBundleId,
        bool experimentOccurrencesRefs,
        bool experimentResultsRefs,
      })
    >;
typedef $$ExperimentOccurrencesTableCreateCompanionBuilder =
    ExperimentOccurrencesCompanion Function({
      required String id,
      required String experimentProtocolId,
      required DateTime scheduledAtUtc,
      Value<DateTime?> completedAtUtc,
      required String status,
      required String contextJson,
      Value<int> rowid,
    });
typedef $$ExperimentOccurrencesTableUpdateCompanionBuilder =
    ExperimentOccurrencesCompanion Function({
      Value<String> id,
      Value<String> experimentProtocolId,
      Value<DateTime> scheduledAtUtc,
      Value<DateTime?> completedAtUtc,
      Value<String> status,
      Value<String> contextJson,
      Value<int> rowid,
    });

final class $$ExperimentOccurrencesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ExperimentOccurrencesTable,
          ExperimentOccurrenceRow
        > {
  $$ExperimentOccurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExperimentProtocolsTable _experimentProtocolIdTable(
    _$VueniverseDatabase db,
  ) => db.experimentProtocols.createAlias(
    'experiment_occurrences__experiment_protocol_id__experiment_protocols__id',
  );

  $$ExperimentProtocolsTableProcessedTableManager get experimentProtocolId {
    final $_column = $_itemColumn<String>('experiment_protocol_id')!;

    final manager = $$ExperimentProtocolsTableTableManager(
      $_db,
      $_db.experimentProtocols,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _experimentProtocolIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AdherenceCheckinsTable, List<AdherenceCheckinRow>>
  _adherenceCheckinsRefsTable(
    _$VueniverseDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.adherenceCheckins,
    aliasName:
        'experiment_occurrences__id__adherence_checkins__experiment_occurrence_id',
  );

  $$AdherenceCheckinsTableProcessedTableManager get adherenceCheckinsRefs {
    final manager =
        $$AdherenceCheckinsTableTableManager(
          $_db,
          $_db.adherenceCheckins,
        ).filter(
          (f) => f.experimentOccurrenceId.id.sqlEquals(
            $_itemColumn<String>('id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _adherenceCheckinsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExperimentOccurrencesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExperimentOccurrencesTable> {
  $$ExperimentOccurrencesTableFilterComposer({
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

  ColumnFilters<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ExperimentProtocolsTableFilterComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.experimentProtocolId,
      referencedTable: $db.experimentProtocols,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentProtocolsTableFilterComposer(
            $db: $db,
            $table: $db.experimentProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> adherenceCheckinsRefs(
    Expression<bool> Function($$AdherenceCheckinsTableFilterComposer f) f,
  ) {
    final $$AdherenceCheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adherenceCheckins,
      getReferencedColumn: (t) => t.experimentOccurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdherenceCheckinsTableFilterComposer(
            $db: $db,
            $table: $db.adherenceCheckins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExperimentOccurrencesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExperimentOccurrencesTable> {
  $$ExperimentOccurrencesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExperimentProtocolsTableOrderingComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentProtocolId,
          referencedTable: $db.experimentProtocols,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentProtocolsTableOrderingComposer(
                $db: $db,
                $table: $db.experimentProtocols,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExperimentOccurrencesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExperimentOccurrencesTable> {
  $$ExperimentOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  $$ExperimentProtocolsTableAnnotationComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentProtocolId,
          referencedTable: $db.experimentProtocols,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentProtocolsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentProtocols,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> adherenceCheckinsRefs<T extends Object>(
    Expression<T> Function($$AdherenceCheckinsTableAnnotationComposer a) f,
  ) {
    final $$AdherenceCheckinsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.adherenceCheckins,
          getReferencedColumn: (t) => t.experimentOccurrenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AdherenceCheckinsTableAnnotationComposer(
                $db: $db,
                $table: $db.adherenceCheckins,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentOccurrencesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExperimentOccurrencesTable,
          ExperimentOccurrenceRow,
          $$ExperimentOccurrencesTableFilterComposer,
          $$ExperimentOccurrencesTableOrderingComposer,
          $$ExperimentOccurrencesTableAnnotationComposer,
          $$ExperimentOccurrencesTableCreateCompanionBuilder,
          $$ExperimentOccurrencesTableUpdateCompanionBuilder,
          (ExperimentOccurrenceRow, $$ExperimentOccurrencesTableReferences),
          ExperimentOccurrenceRow,
          PrefetchHooks Function({
            bool experimentProtocolId,
            bool adherenceCheckinsRefs,
          })
        > {
  $$ExperimentOccurrencesTableTableManager(
    _$VueniverseDatabase db,
    $ExperimentOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentOccurrencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExperimentOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExperimentOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> experimentProtocolId = const Value.absent(),
                Value<DateTime> scheduledAtUtc = const Value.absent(),
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> contextJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentOccurrencesCompanion(
                id: id,
                experimentProtocolId: experimentProtocolId,
                scheduledAtUtc: scheduledAtUtc,
                completedAtUtc: completedAtUtc,
                status: status,
                contextJson: contextJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String experimentProtocolId,
                required DateTime scheduledAtUtc,
                Value<DateTime?> completedAtUtc = const Value.absent(),
                required String status,
                required String contextJson,
                Value<int> rowid = const Value.absent(),
              }) => ExperimentOccurrencesCompanion.insert(
                id: id,
                experimentProtocolId: experimentProtocolId,
                scheduledAtUtc: scheduledAtUtc,
                completedAtUtc: completedAtUtc,
                status: status,
                contextJson: contextJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExperimentOccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({experimentProtocolId = false, adherenceCheckinsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (adherenceCheckinsRefs) db.adherenceCheckins,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (experimentProtocolId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.experimentProtocolId,
                                    referencedTable:
                                        $$ExperimentOccurrencesTableReferences
                                            ._experimentProtocolIdTable(db),
                                    referencedColumn:
                                        $$ExperimentOccurrencesTableReferences
                                            ._experimentProtocolIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (adherenceCheckinsRefs)
                        await $_getPrefetchedData<
                          ExperimentOccurrenceRow,
                          $ExperimentOccurrencesTable,
                          AdherenceCheckinRow
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ExperimentOccurrencesTableReferences
                                  ._adherenceCheckinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExperimentOccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).adherenceCheckinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.experimentOccurrenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExperimentOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExperimentOccurrencesTable,
      ExperimentOccurrenceRow,
      $$ExperimentOccurrencesTableFilterComposer,
      $$ExperimentOccurrencesTableOrderingComposer,
      $$ExperimentOccurrencesTableAnnotationComposer,
      $$ExperimentOccurrencesTableCreateCompanionBuilder,
      $$ExperimentOccurrencesTableUpdateCompanionBuilder,
      (ExperimentOccurrenceRow, $$ExperimentOccurrencesTableReferences),
      ExperimentOccurrenceRow,
      PrefetchHooks Function({
        bool experimentProtocolId,
        bool adherenceCheckinsRefs,
      })
    >;
typedef $$AdherenceCheckinsTableCreateCompanionBuilder =
    AdherenceCheckinsCompanion Function({
      required String id,
      required String experimentOccurrenceId,
      required String responseJson,
      required DateTime recordedAtUtc,
      Value<int> rowid,
    });
typedef $$AdherenceCheckinsTableUpdateCompanionBuilder =
    AdherenceCheckinsCompanion Function({
      Value<String> id,
      Value<String> experimentOccurrenceId,
      Value<String> responseJson,
      Value<DateTime> recordedAtUtc,
      Value<int> rowid,
    });

final class $$AdherenceCheckinsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $AdherenceCheckinsTable,
          AdherenceCheckinRow
        > {
  $$AdherenceCheckinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExperimentOccurrencesTable _experimentOccurrenceIdTable(
    _$VueniverseDatabase db,
  ) => db.experimentOccurrences.createAlias(
    'adherence_checkins__experiment_occurrence_id__experiment_occurrences__id',
  );

  $$ExperimentOccurrencesTableProcessedTableManager get experimentOccurrenceId {
    final $_column = $_itemColumn<String>('experiment_occurrence_id')!;

    final manager = $$ExperimentOccurrencesTableTableManager(
      $_db,
      $_db.experimentOccurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _experimentOccurrenceIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdherenceCheckinsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $AdherenceCheckinsTable> {
  $$AdherenceCheckinsTableFilterComposer({
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

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAtUtc => $composableBuilder(
    column: $table.recordedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$ExperimentOccurrencesTableFilterComposer get experimentOccurrenceId {
    final $$ExperimentOccurrencesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentOccurrenceId,
          referencedTable: $db.experimentOccurrences,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentOccurrencesTableFilterComposer(
                $db: $db,
                $table: $db.experimentOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AdherenceCheckinsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $AdherenceCheckinsTable> {
  $$AdherenceCheckinsTableOrderingComposer({
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

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAtUtc => $composableBuilder(
    column: $table.recordedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExperimentOccurrencesTableOrderingComposer get experimentOccurrenceId {
    final $$ExperimentOccurrencesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentOccurrenceId,
          referencedTable: $db.experimentOccurrences,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentOccurrencesTableOrderingComposer(
                $db: $db,
                $table: $db.experimentOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AdherenceCheckinsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $AdherenceCheckinsTable> {
  $$AdherenceCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAtUtc => $composableBuilder(
    column: $table.recordedAtUtc,
    builder: (column) => column,
  );

  $$ExperimentOccurrencesTableAnnotationComposer get experimentOccurrenceId {
    final $$ExperimentOccurrencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentOccurrenceId,
          referencedTable: $db.experimentOccurrences,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentOccurrencesTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AdherenceCheckinsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $AdherenceCheckinsTable,
          AdherenceCheckinRow,
          $$AdherenceCheckinsTableFilterComposer,
          $$AdherenceCheckinsTableOrderingComposer,
          $$AdherenceCheckinsTableAnnotationComposer,
          $$AdherenceCheckinsTableCreateCompanionBuilder,
          $$AdherenceCheckinsTableUpdateCompanionBuilder,
          (AdherenceCheckinRow, $$AdherenceCheckinsTableReferences),
          AdherenceCheckinRow,
          PrefetchHooks Function({bool experimentOccurrenceId})
        > {
  $$AdherenceCheckinsTableTableManager(
    _$VueniverseDatabase db,
    $AdherenceCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdherenceCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdherenceCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdherenceCheckinsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> experimentOccurrenceId = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<DateTime> recordedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdherenceCheckinsCompanion(
                id: id,
                experimentOccurrenceId: experimentOccurrenceId,
                responseJson: responseJson,
                recordedAtUtc: recordedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String experimentOccurrenceId,
                required String responseJson,
                required DateTime recordedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AdherenceCheckinsCompanion.insert(
                id: id,
                experimentOccurrenceId: experimentOccurrenceId,
                responseJson: responseJson,
                recordedAtUtc: recordedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AdherenceCheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({experimentOccurrenceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (experimentOccurrenceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.experimentOccurrenceId,
                                referencedTable:
                                    $$AdherenceCheckinsTableReferences
                                        ._experimentOccurrenceIdTable(db),
                                referencedColumn:
                                    $$AdherenceCheckinsTableReferences
                                        ._experimentOccurrenceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AdherenceCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $AdherenceCheckinsTable,
      AdherenceCheckinRow,
      $$AdherenceCheckinsTableFilterComposer,
      $$AdherenceCheckinsTableOrderingComposer,
      $$AdherenceCheckinsTableAnnotationComposer,
      $$AdherenceCheckinsTableCreateCompanionBuilder,
      $$AdherenceCheckinsTableUpdateCompanionBuilder,
      (AdherenceCheckinRow, $$AdherenceCheckinsTableReferences),
      AdherenceCheckinRow,
      PrefetchHooks Function({bool experimentOccurrenceId})
    >;
typedef $$ExperimentResultsTableCreateCompanionBuilder =
    ExperimentResultsCompanion Function({
      required String id,
      required String experimentProtocolId,
      required String outcome,
      required String resultJson,
      required String evidenceHash,
      required int analysisVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> invalidatedAt,
      Value<int> rowid,
    });
typedef $$ExperimentResultsTableUpdateCompanionBuilder =
    ExperimentResultsCompanion Function({
      Value<String> id,
      Value<String> experimentProtocolId,
      Value<String> outcome,
      Value<String> resultJson,
      Value<String> evidenceHash,
      Value<int> analysisVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> invalidatedAt,
      Value<int> rowid,
    });

final class $$ExperimentResultsTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ExperimentResultsTable,
          ExperimentResultRow
        > {
  $$ExperimentResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExperimentProtocolsTable _experimentProtocolIdTable(
    _$VueniverseDatabase db,
  ) => db.experimentProtocols.createAlias(
    'experiment_results__experiment_protocol_id__experiment_protocols__id',
  );

  $$ExperimentProtocolsTableProcessedTableManager get experimentProtocolId {
    final $_column = $_itemColumn<String>('experiment_protocol_id')!;

    final manager = $$ExperimentProtocolsTableTableManager(
      $_db,
      $_db.experimentProtocols,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _experimentProtocolIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ExperimentDependenciesTable,
    List<ExperimentDependencyRow>
  >
  _experimentDependenciesRefsTable(
    _$VueniverseDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.experimentDependencies,
    aliasName:
        'experiment_results__id__experiment_dependencies__experiment_result_id',
  );

  $$ExperimentDependenciesTableProcessedTableManager
  get experimentDependenciesRefs {
    final manager =
        $$ExperimentDependenciesTableTableManager(
          $_db,
          $_db.experimentDependencies,
        ).filter(
          (f) => f.experimentResultId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _experimentDependenciesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExperimentResultsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExperimentResultsTable> {
  $$ExperimentResultsTableFilterComposer({
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

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get invalidatedAt => $composableBuilder(
    column: $table.invalidatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExperimentProtocolsTableFilterComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.experimentProtocolId,
      referencedTable: $db.experimentProtocols,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentProtocolsTableFilterComposer(
            $db: $db,
            $table: $db.experimentProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> experimentDependenciesRefs(
    Expression<bool> Function($$ExperimentDependenciesTableFilterComposer f) f,
  ) {
    final $$ExperimentDependenciesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentDependencies,
          getReferencedColumn: (t) => t.experimentResultId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentDependenciesTableFilterComposer(
                $db: $db,
                $table: $db.experimentDependencies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentResultsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExperimentResultsTable> {
  $$ExperimentResultsTableOrderingComposer({
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

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get invalidatedAt => $composableBuilder(
    column: $table.invalidatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExperimentProtocolsTableOrderingComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentProtocolId,
          referencedTable: $db.experimentProtocols,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentProtocolsTableOrderingComposer(
                $db: $db,
                $table: $db.experimentProtocols,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExperimentResultsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExperimentResultsTable> {
  $$ExperimentResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidenceHash => $composableBuilder(
    column: $table.evidenceHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analysisVersion => $composableBuilder(
    column: $table.analysisVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get invalidatedAt => $composableBuilder(
    column: $table.invalidatedAt,
    builder: (column) => column,
  );

  $$ExperimentProtocolsTableAnnotationComposer get experimentProtocolId {
    final $$ExperimentProtocolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentProtocolId,
          referencedTable: $db.experimentProtocols,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentProtocolsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentProtocols,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> experimentDependenciesRefs<T extends Object>(
    Expression<T> Function($$ExperimentDependenciesTableAnnotationComposer a) f,
  ) {
    final $$ExperimentDependenciesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.experimentDependencies,
          getReferencedColumn: (t) => t.experimentResultId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentDependenciesTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentDependencies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentResultsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExperimentResultsTable,
          ExperimentResultRow,
          $$ExperimentResultsTableFilterComposer,
          $$ExperimentResultsTableOrderingComposer,
          $$ExperimentResultsTableAnnotationComposer,
          $$ExperimentResultsTableCreateCompanionBuilder,
          $$ExperimentResultsTableUpdateCompanionBuilder,
          (ExperimentResultRow, $$ExperimentResultsTableReferences),
          ExperimentResultRow,
          PrefetchHooks Function({
            bool experimentProtocolId,
            bool experimentDependenciesRefs,
          })
        > {
  $$ExperimentResultsTableTableManager(
    _$VueniverseDatabase db,
    $ExperimentResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExperimentResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExperimentResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> experimentProtocolId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<String> evidenceHash = const Value.absent(),
                Value<int> analysisVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> invalidatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentResultsCompanion(
                id: id,
                experimentProtocolId: experimentProtocolId,
                outcome: outcome,
                resultJson: resultJson,
                evidenceHash: evidenceHash,
                analysisVersion: analysisVersion,
                createdAt: createdAt,
                invalidatedAt: invalidatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String experimentProtocolId,
                required String outcome,
                required String resultJson,
                required String evidenceHash,
                required int analysisVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> invalidatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentResultsCompanion.insert(
                id: id,
                experimentProtocolId: experimentProtocolId,
                outcome: outcome,
                resultJson: resultJson,
                evidenceHash: evidenceHash,
                analysisVersion: analysisVersion,
                createdAt: createdAt,
                invalidatedAt: invalidatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExperimentResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                experimentProtocolId = false,
                experimentDependenciesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (experimentDependenciesRefs) db.experimentDependencies,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (experimentProtocolId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.experimentProtocolId,
                                    referencedTable:
                                        $$ExperimentResultsTableReferences
                                            ._experimentProtocolIdTable(db),
                                    referencedColumn:
                                        $$ExperimentResultsTableReferences
                                            ._experimentProtocolIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (experimentDependenciesRefs)
                        await $_getPrefetchedData<
                          ExperimentResultRow,
                          $ExperimentResultsTable,
                          ExperimentDependencyRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExperimentResultsTableReferences
                              ._experimentDependenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExperimentResultsTableReferences(
                                db,
                                table,
                                p0,
                              ).experimentDependenciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.experimentResultId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExperimentResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExperimentResultsTable,
      ExperimentResultRow,
      $$ExperimentResultsTableFilterComposer,
      $$ExperimentResultsTableOrderingComposer,
      $$ExperimentResultsTableAnnotationComposer,
      $$ExperimentResultsTableCreateCompanionBuilder,
      $$ExperimentResultsTableUpdateCompanionBuilder,
      (ExperimentResultRow, $$ExperimentResultsTableReferences),
      ExperimentResultRow,
      PrefetchHooks Function({
        bool experimentProtocolId,
        bool experimentDependenciesRefs,
      })
    >;
typedef $$ExperimentDependenciesTableCreateCompanionBuilder =
    ExperimentDependenciesCompanion Function({
      required String id,
      required String experimentResultId,
      required String dependencyKind,
      required String dependencyId,
      required String dependencyHash,
      Value<int> rowid,
    });
typedef $$ExperimentDependenciesTableUpdateCompanionBuilder =
    ExperimentDependenciesCompanion Function({
      Value<String> id,
      Value<String> experimentResultId,
      Value<String> dependencyKind,
      Value<String> dependencyId,
      Value<String> dependencyHash,
      Value<int> rowid,
    });

final class $$ExperimentDependenciesTableReferences
    extends
        BaseReferences<
          _$VueniverseDatabase,
          $ExperimentDependenciesTable,
          ExperimentDependencyRow
        > {
  $$ExperimentDependenciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExperimentResultsTable _experimentResultIdTable(
    _$VueniverseDatabase db,
  ) => db.experimentResults.createAlias(
    'experiment_dependencies__experiment_result_id__experiment_results__id',
  );

  $$ExperimentResultsTableProcessedTableManager get experimentResultId {
    final $_column = $_itemColumn<String>('experiment_result_id')!;

    final manager = $$ExperimentResultsTableTableManager(
      $_db,
      $_db.experimentResults,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_experimentResultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExperimentDependenciesTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExperimentDependenciesTable> {
  $$ExperimentDependenciesTableFilterComposer({
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

  ColumnFilters<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => ColumnFilters(column),
  );

  $$ExperimentResultsTableFilterComposer get experimentResultId {
    final $$ExperimentResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.experimentResultId,
      referencedTable: $db.experimentResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentResultsTableFilterComposer(
            $db: $db,
            $table: $db.experimentResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExperimentDependenciesTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExperimentDependenciesTable> {
  $$ExperimentDependenciesTableOrderingComposer({
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

  ColumnOrderings<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExperimentResultsTableOrderingComposer get experimentResultId {
    final $$ExperimentResultsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.experimentResultId,
      referencedTable: $db.experimentResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentResultsTableOrderingComposer(
            $db: $db,
            $table: $db.experimentResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExperimentDependenciesTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExperimentDependenciesTable> {
  $$ExperimentDependenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dependencyKind => $composableBuilder(
    column: $table.dependencyKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependencyId => $composableBuilder(
    column: $table.dependencyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependencyHash => $composableBuilder(
    column: $table.dependencyHash,
    builder: (column) => column,
  );

  $$ExperimentResultsTableAnnotationComposer get experimentResultId {
    final $$ExperimentResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.experimentResultId,
          referencedTable: $db.experimentResults,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExperimentDependenciesTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExperimentDependenciesTable,
          ExperimentDependencyRow,
          $$ExperimentDependenciesTableFilterComposer,
          $$ExperimentDependenciesTableOrderingComposer,
          $$ExperimentDependenciesTableAnnotationComposer,
          $$ExperimentDependenciesTableCreateCompanionBuilder,
          $$ExperimentDependenciesTableUpdateCompanionBuilder,
          (ExperimentDependencyRow, $$ExperimentDependenciesTableReferences),
          ExperimentDependencyRow,
          PrefetchHooks Function({bool experimentResultId})
        > {
  $$ExperimentDependenciesTableTableManager(
    _$VueniverseDatabase db,
    $ExperimentDependenciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentDependenciesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExperimentDependenciesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExperimentDependenciesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> experimentResultId = const Value.absent(),
                Value<String> dependencyKind = const Value.absent(),
                Value<String> dependencyId = const Value.absent(),
                Value<String> dependencyHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentDependenciesCompanion(
                id: id,
                experimentResultId: experimentResultId,
                dependencyKind: dependencyKind,
                dependencyId: dependencyId,
                dependencyHash: dependencyHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String experimentResultId,
                required String dependencyKind,
                required String dependencyId,
                required String dependencyHash,
                Value<int> rowid = const Value.absent(),
              }) => ExperimentDependenciesCompanion.insert(
                id: id,
                experimentResultId: experimentResultId,
                dependencyKind: dependencyKind,
                dependencyId: dependencyId,
                dependencyHash: dependencyHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExperimentDependenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({experimentResultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (experimentResultId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.experimentResultId,
                                referencedTable:
                                    $$ExperimentDependenciesTableReferences
                                        ._experimentResultIdTable(db),
                                referencedColumn:
                                    $$ExperimentDependenciesTableReferences
                                        ._experimentResultIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExperimentDependenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExperimentDependenciesTable,
      ExperimentDependencyRow,
      $$ExperimentDependenciesTableFilterComposer,
      $$ExperimentDependenciesTableOrderingComposer,
      $$ExperimentDependenciesTableAnnotationComposer,
      $$ExperimentDependenciesTableCreateCompanionBuilder,
      $$ExperimentDependenciesTableUpdateCompanionBuilder,
      (ExperimentDependencyRow, $$ExperimentDependenciesTableReferences),
      ExperimentDependencyRow,
      PrefetchHooks Function({bool experimentResultId})
    >;
typedef $$ExportRecordsTableCreateCompanionBuilder =
    ExportRecordsCompanion Function({
      required String id,
      required String exportType,
      required String status,
      required String filePath,
      Value<String?> contentHash,
      required int exportSchemaVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ExportRecordsTableUpdateCompanionBuilder =
    ExportRecordsCompanion Function({
      Value<String> id,
      Value<String> exportType,
      Value<String> status,
      Value<String> filePath,
      Value<String?> contentHash,
      Value<int> exportSchemaVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ExportRecordsTableFilterComposer
    extends Composer<_$VueniverseDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableFilterComposer({
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

  ColumnFilters<String> get exportType => $composableBuilder(
    column: $table.exportType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exportSchemaVersion => $composableBuilder(
    column: $table.exportSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExportRecordsTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get exportType => $composableBuilder(
    column: $table.exportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exportSchemaVersion => $composableBuilder(
    column: $table.exportSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExportRecordsTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exportType => $composableBuilder(
    column: $table.exportType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exportSchemaVersion => $composableBuilder(
    column: $table.exportSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ExportRecordsTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $ExportRecordsTable,
          ExportRecordRow,
          $$ExportRecordsTableFilterComposer,
          $$ExportRecordsTableOrderingComposer,
          $$ExportRecordsTableAnnotationComposer,
          $$ExportRecordsTableCreateCompanionBuilder,
          $$ExportRecordsTableUpdateCompanionBuilder,
          (
            ExportRecordRow,
            BaseReferences<
              _$VueniverseDatabase,
              $ExportRecordsTable,
              ExportRecordRow
            >,
          ),
          ExportRecordRow,
          PrefetchHooks Function()
        > {
  $$ExportRecordsTableTableManager(
    _$VueniverseDatabase db,
    $ExportRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exportType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> exportSchemaVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion(
                id: id,
                exportType: exportType,
                status: status,
                filePath: filePath,
                contentHash: contentHash,
                exportSchemaVersion: exportSchemaVersion,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exportType,
                required String status,
                required String filePath,
                Value<String?> contentHash = const Value.absent(),
                required int exportSchemaVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion.insert(
                id: id,
                exportType: exportType,
                status: status,
                filePath: filePath,
                contentHash: contentHash,
                exportSchemaVersion: exportSchemaVersion,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $ExportRecordsTable,
      ExportRecordRow,
      $$ExportRecordsTableFilterComposer,
      $$ExportRecordsTableOrderingComposer,
      $$ExportRecordsTableAnnotationComposer,
      $$ExportRecordsTableCreateCompanionBuilder,
      $$ExportRecordsTableUpdateCompanionBuilder,
      (
        ExportRecordRow,
        BaseReferences<
          _$VueniverseDatabase,
          $ExportRecordsTable,
          ExportRecordRow
        >,
      ),
      ExportRecordRow,
      PrefetchHooks Function()
    >;
typedef $$DeletionAuditTableCreateCompanionBuilder =
    DeletionAuditCompanion Function({
      required String id,
      required String scope,
      Value<String?> sourceId,
      required int recordsDeleted,
      required String invalidatedJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$DeletionAuditTableUpdateCompanionBuilder =
    DeletionAuditCompanion Function({
      Value<String> id,
      Value<String> scope,
      Value<String?> sourceId,
      Value<int> recordsDeleted,
      Value<String> invalidatedJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DeletionAuditTableFilterComposer
    extends Composer<_$VueniverseDatabase, $DeletionAuditTable> {
  $$DeletionAuditTableFilterComposer({
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

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsDeleted => $composableBuilder(
    column: $table.recordsDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invalidatedJson => $composableBuilder(
    column: $table.invalidatedJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletionAuditTableOrderingComposer
    extends Composer<_$VueniverseDatabase, $DeletionAuditTable> {
  $$DeletionAuditTableOrderingComposer({
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

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsDeleted => $composableBuilder(
    column: $table.recordsDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invalidatedJson => $composableBuilder(
    column: $table.invalidatedJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletionAuditTableAnnotationComposer
    extends Composer<_$VueniverseDatabase, $DeletionAuditTable> {
  $$DeletionAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get recordsDeleted => $composableBuilder(
    column: $table.recordsDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invalidatedJson => $composableBuilder(
    column: $table.invalidatedJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DeletionAuditTableTableManager
    extends
        RootTableManager<
          _$VueniverseDatabase,
          $DeletionAuditTable,
          DeletionAuditRow,
          $$DeletionAuditTableFilterComposer,
          $$DeletionAuditTableOrderingComposer,
          $$DeletionAuditTableAnnotationComposer,
          $$DeletionAuditTableCreateCompanionBuilder,
          $$DeletionAuditTableUpdateCompanionBuilder,
          (
            DeletionAuditRow,
            BaseReferences<
              _$VueniverseDatabase,
              $DeletionAuditTable,
              DeletionAuditRow
            >,
          ),
          DeletionAuditRow,
          PrefetchHooks Function()
        > {
  $$DeletionAuditTableTableManager(
    _$VueniverseDatabase db,
    $DeletionAuditTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletionAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletionAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletionAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> recordsDeleted = const Value.absent(),
                Value<String> invalidatedJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletionAuditCompanion(
                id: id,
                scope: scope,
                sourceId: sourceId,
                recordsDeleted: recordsDeleted,
                invalidatedJson: invalidatedJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scope,
                Value<String?> sourceId = const Value.absent(),
                required int recordsDeleted,
                required String invalidatedJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletionAuditCompanion.insert(
                id: id,
                scope: scope,
                sourceId: sourceId,
                recordsDeleted: recordsDeleted,
                invalidatedJson: invalidatedJson,
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

typedef $$DeletionAuditTableProcessedTableManager =
    ProcessedTableManager<
      _$VueniverseDatabase,
      $DeletionAuditTable,
      DeletionAuditRow,
      $$DeletionAuditTableFilterComposer,
      $$DeletionAuditTableOrderingComposer,
      $$DeletionAuditTableAnnotationComposer,
      $$DeletionAuditTableCreateCompanionBuilder,
      $$DeletionAuditTableUpdateCompanionBuilder,
      (
        DeletionAuditRow,
        BaseReferences<
          _$VueniverseDatabase,
          $DeletionAuditTable,
          DeletionAuditRow
        >,
      ),
      DeletionAuditRow,
      PrefetchHooks Function()
    >;

class $VueniverseDatabaseManager {
  final _$VueniverseDatabase _db;
  $VueniverseDatabaseManager(this._db);
  $$StoreMetadataTableTableManager get storeMetadata =>
      $$StoreMetadataTableTableManager(_db, _db.storeMetadata);
  $$SourceConnectionsTableTableManager get sourceConnections =>
      $$SourceConnectionsTableTableManager(_db, _db.sourceConnections);
  $$SourcePermissionsTableTableManager get sourcePermissions =>
      $$SourcePermissionsTableTableManager(_db, _db.sourcePermissions);
  $$SyncRunsTableTableManager get syncRuns =>
      $$SyncRunsTableTableManager(_db, _db.syncRuns);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$SyncSeenRecordsTableTableManager get syncSeenRecords =>
      $$SyncSeenRecordsTableTableManager(_db, _db.syncSeenRecords);
  $$RawRecordIndexTableTableManager get rawRecordIndex =>
      $$RawRecordIndexTableTableManager(_db, _db.rawRecordIndex);
  $$SignalSamplesTableTableManager get signalSamples =>
      $$SignalSamplesTableTableManager(_db, _db.signalSamples);
  $$HealthIntervalsTableTableManager get healthIntervals =>
      $$HealthIntervalsTableTableManager(_db, _db.healthIntervals);
  $$ContextEventsTableTableManager get contextEvents =>
      $$ContextEventsTableTableManager(_db, _db.contextEvents);
  $$ManualCheckinsTableTableManager get manualCheckins =>
      $$ManualCheckinsTableTableManager(_db, _db.manualCheckins);
  $$RecomputeJobsTableTableManager get recomputeJobs =>
      $$RecomputeJobsTableTableManager(_db, _db.recomputeJobs);
  $$AnalysisRunsTableTableManager get analysisRuns =>
      $$AnalysisRunsTableTableManager(_db, _db.analysisRuns);
  $$EventWindowsTableTableManager get eventWindows =>
      $$EventWindowsTableTableManager(_db, _db.eventWindows);
  $$ControlMatchesTableTableManager get controlMatches =>
      $$ControlMatchesTableTableManager(_db, _db.controlMatches);
  $$WindowMetricsTableTableManager get windowMetrics =>
      $$WindowMetricsTableTableManager(_db, _db.windowMetrics);
  $$EvidenceBundlesTableTableManager get evidenceBundles =>
      $$EvidenceBundlesTableTableManager(_db, _db.evidenceBundles);
  $$EvidenceMetricsTableTableManager get evidenceMetrics =>
      $$EvidenceMetricsTableTableManager(_db, _db.evidenceMetrics);
  $$EvidenceDependenciesTableTableManager get evidenceDependencies =>
      $$EvidenceDependenciesTableTableManager(_db, _db.evidenceDependencies);
  $$FindingVersionsTableTableManager get findingVersions =>
      $$FindingVersionsTableTableManager(_db, _db.findingVersions);
  $$ExplanationsTableTableManager get explanations =>
      $$ExplanationsTableTableManager(_db, _db.explanations);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ExperimentProtocolsTableTableManager get experimentProtocols =>
      $$ExperimentProtocolsTableTableManager(_db, _db.experimentProtocols);
  $$ExperimentOccurrencesTableTableManager get experimentOccurrences =>
      $$ExperimentOccurrencesTableTableManager(_db, _db.experimentOccurrences);
  $$AdherenceCheckinsTableTableManager get adherenceCheckins =>
      $$AdherenceCheckinsTableTableManager(_db, _db.adherenceCheckins);
  $$ExperimentResultsTableTableManager get experimentResults =>
      $$ExperimentResultsTableTableManager(_db, _db.experimentResults);
  $$ExperimentDependenciesTableTableManager get experimentDependencies =>
      $$ExperimentDependenciesTableTableManager(
        _db,
        _db.experimentDependencies,
      );
  $$ExportRecordsTableTableManager get exportRecords =>
      $$ExportRecordsTableTableManager(_db, _db.exportRecords);
  $$DeletionAuditTableTableManager get deletionAudit =>
      $$DeletionAuditTableTableManager(_db, _db.deletionAudit);
}
