// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TerrainsTable extends Terrains
    with TableInfo<$TerrainsTable, TerrainRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TerrainsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nom, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'terrains';
  @override
  VerificationContext validateIntegrity(
    Insertable<TerrainRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TerrainRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TerrainRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $TerrainsTable createAlias(String alias) {
    return $TerrainsTable(attachedDatabase, alias);
  }
}

class TerrainRow extends DataClass implements Insertable<TerrainRow> {
  final int id;
  final String nom;
  final int type;
  const TerrainRow({required this.id, required this.nom, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nom'] = Variable<String>(nom);
    map['type'] = Variable<int>(type);
    return map;
  }

  TerrainsCompanion toCompanion(bool nullToAbsent) {
    return TerrainsCompanion(id: Value(id), nom: Value(nom), type: Value(type));
  }

  factory TerrainRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TerrainRow(
      id: serializer.fromJson<int>(json['id']),
      nom: serializer.fromJson<String>(json['nom']),
      type: serializer.fromJson<int>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nom': serializer.toJson<String>(nom),
      'type': serializer.toJson<int>(type),
    };
  }

  TerrainRow copyWith({int? id, String? nom, int? type}) => TerrainRow(
    id: id ?? this.id,
    nom: nom ?? this.nom,
    type: type ?? this.type,
  );
  TerrainRow copyWithCompanion(TerrainsCompanion data) {
    return TerrainRow(
      id: data.id.present ? data.id.value : this.id,
      nom: data.nom.present ? data.nom.value : this.nom,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TerrainRow(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nom, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TerrainRow &&
          other.id == this.id &&
          other.nom == this.nom &&
          other.type == this.type);
}

class TerrainsCompanion extends UpdateCompanion<TerrainRow> {
  final Value<int> id;
  final Value<String> nom;
  final Value<int> type;
  const TerrainsCompanion({
    this.id = const Value.absent(),
    this.nom = const Value.absent(),
    this.type = const Value.absent(),
  });
  TerrainsCompanion.insert({
    this.id = const Value.absent(),
    required String nom,
    required int type,
  }) : nom = Value(nom),
       type = Value(type);
  static Insertable<TerrainRow> custom({
    Expression<int>? id,
    Expression<String>? nom,
    Expression<int>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nom != null) 'nom': nom,
      if (type != null) 'type': type,
    });
  }

  TerrainsCompanion copyWith({
    Value<int>? id,
    Value<String>? nom,
    Value<int>? type,
  }) {
    return TerrainsCompanion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TerrainsCompanion(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $MaintenancesTable extends Maintenances
    with TableInfo<$MaintenancesTable, MaintenanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _terrainIdMeta = const VerificationMeta(
    'terrainId',
  );
  @override
  late final GeneratedColumn<int> terrainId = GeneratedColumn<int>(
    'terrain_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentaireMeta = const VerificationMeta(
    'commentaire',
  );
  @override
  late final GeneratedColumn<String> commentaire = GeneratedColumn<String>(
    'commentaire',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sacsMantoUtilisesMeta = const VerificationMeta(
    'sacsMantoUtilises',
  );
  @override
  late final GeneratedColumn<int> sacsMantoUtilises = GeneratedColumn<int>(
    'sacs_manto_utilises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sacsSottomantoUtilisesMeta =
      const VerificationMeta('sacsSottomantoUtilises');
  @override
  late final GeneratedColumn<int> sacsSottomantoUtilises = GeneratedColumn<int>(
    'sacs_sottomanto_utilises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sacsSiliceUtilisesMeta =
      const VerificationMeta('sacsSiliceUtilises');
  @override
  late final GeneratedColumn<int> sacsSiliceUtilises = GeneratedColumn<int>(
    'sacs_silice_utilises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    terrainId,
    type,
    commentaire,
    date,
    sacsMantoUtilises,
    sacsSottomantoUtilises,
    sacsSiliceUtilises,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenances';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('terrain_id')) {
      context.handle(
        _terrainIdMeta,
        terrainId.isAcceptableOrUnknown(data['terrain_id']!, _terrainIdMeta),
      );
    } else if (isInserting) {
      context.missing(_terrainIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('commentaire')) {
      context.handle(
        _commentaireMeta,
        commentaire.isAcceptableOrUnknown(
          data['commentaire']!,
          _commentaireMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sacs_manto_utilises')) {
      context.handle(
        _sacsMantoUtilisesMeta,
        sacsMantoUtilises.isAcceptableOrUnknown(
          data['sacs_manto_utilises']!,
          _sacsMantoUtilisesMeta,
        ),
      );
    }
    if (data.containsKey('sacs_sottomanto_utilises')) {
      context.handle(
        _sacsSottomantoUtilisesMeta,
        sacsSottomantoUtilises.isAcceptableOrUnknown(
          data['sacs_sottomanto_utilises']!,
          _sacsSottomantoUtilisesMeta,
        ),
      );
    }
    if (data.containsKey('sacs_silice_utilises')) {
      context.handle(
        _sacsSiliceUtilisesMeta,
        sacsSiliceUtilises.isAcceptableOrUnknown(
          data['sacs_silice_utilises']!,
          _sacsSiliceUtilisesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      terrainId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}terrain_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      commentaire: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commentaire'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      sacsMantoUtilises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sacs_manto_utilises'],
      )!,
      sacsSottomantoUtilises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sacs_sottomanto_utilises'],
      )!,
      sacsSiliceUtilises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sacs_silice_utilises'],
      )!,
    );
  }

  @override
  $MaintenancesTable createAlias(String alias) {
    return $MaintenancesTable(attachedDatabase, alias);
  }
}

class MaintenanceRow extends DataClass implements Insertable<MaintenanceRow> {
  final int id;
  final int terrainId;
  final String type;
  final String? commentaire;
  final int date;
  final int sacsMantoUtilises;
  final int sacsSottomantoUtilises;
  final int sacsSiliceUtilises;
  const MaintenanceRow({
    required this.id,
    required this.terrainId,
    required this.type,
    this.commentaire,
    required this.date,
    required this.sacsMantoUtilises,
    required this.sacsSottomantoUtilises,
    required this.sacsSiliceUtilises,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['terrain_id'] = Variable<int>(terrainId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || commentaire != null) {
      map['commentaire'] = Variable<String>(commentaire);
    }
    map['date'] = Variable<int>(date);
    map['sacs_manto_utilises'] = Variable<int>(sacsMantoUtilises);
    map['sacs_sottomanto_utilises'] = Variable<int>(sacsSottomantoUtilises);
    map['sacs_silice_utilises'] = Variable<int>(sacsSiliceUtilises);
    return map;
  }

  MaintenancesCompanion toCompanion(bool nullToAbsent) {
    return MaintenancesCompanion(
      id: Value(id),
      terrainId: Value(terrainId),
      type: Value(type),
      commentaire: commentaire == null && nullToAbsent
          ? const Value.absent()
          : Value(commentaire),
      date: Value(date),
      sacsMantoUtilises: Value(sacsMantoUtilises),
      sacsSottomantoUtilises: Value(sacsSottomantoUtilises),
      sacsSiliceUtilises: Value(sacsSiliceUtilises),
    );
  }

  factory MaintenanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceRow(
      id: serializer.fromJson<int>(json['id']),
      terrainId: serializer.fromJson<int>(json['terrainId']),
      type: serializer.fromJson<String>(json['type']),
      commentaire: serializer.fromJson<String?>(json['commentaire']),
      date: serializer.fromJson<int>(json['date']),
      sacsMantoUtilises: serializer.fromJson<int>(json['sacsMantoUtilises']),
      sacsSottomantoUtilises: serializer.fromJson<int>(
        json['sacsSottomantoUtilises'],
      ),
      sacsSiliceUtilises: serializer.fromJson<int>(json['sacsSiliceUtilises']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'terrainId': serializer.toJson<int>(terrainId),
      'type': serializer.toJson<String>(type),
      'commentaire': serializer.toJson<String?>(commentaire),
      'date': serializer.toJson<int>(date),
      'sacsMantoUtilises': serializer.toJson<int>(sacsMantoUtilises),
      'sacsSottomantoUtilises': serializer.toJson<int>(sacsSottomantoUtilises),
      'sacsSiliceUtilises': serializer.toJson<int>(sacsSiliceUtilises),
    };
  }

  MaintenanceRow copyWith({
    int? id,
    int? terrainId,
    String? type,
    Value<String?> commentaire = const Value.absent(),
    int? date,
    int? sacsMantoUtilises,
    int? sacsSottomantoUtilises,
    int? sacsSiliceUtilises,
  }) => MaintenanceRow(
    id: id ?? this.id,
    terrainId: terrainId ?? this.terrainId,
    type: type ?? this.type,
    commentaire: commentaire.present ? commentaire.value : this.commentaire,
    date: date ?? this.date,
    sacsMantoUtilises: sacsMantoUtilises ?? this.sacsMantoUtilises,
    sacsSottomantoUtilises:
        sacsSottomantoUtilises ?? this.sacsSottomantoUtilises,
    sacsSiliceUtilises: sacsSiliceUtilises ?? this.sacsSiliceUtilises,
  );
  MaintenanceRow copyWithCompanion(MaintenancesCompanion data) {
    return MaintenanceRow(
      id: data.id.present ? data.id.value : this.id,
      terrainId: data.terrainId.present ? data.terrainId.value : this.terrainId,
      type: data.type.present ? data.type.value : this.type,
      commentaire: data.commentaire.present
          ? data.commentaire.value
          : this.commentaire,
      date: data.date.present ? data.date.value : this.date,
      sacsMantoUtilises: data.sacsMantoUtilises.present
          ? data.sacsMantoUtilises.value
          : this.sacsMantoUtilises,
      sacsSottomantoUtilises: data.sacsSottomantoUtilises.present
          ? data.sacsSottomantoUtilises.value
          : this.sacsSottomantoUtilises,
      sacsSiliceUtilises: data.sacsSiliceUtilises.present
          ? data.sacsSiliceUtilises.value
          : this.sacsSiliceUtilises,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRow(')
          ..write('id: $id, ')
          ..write('terrainId: $terrainId, ')
          ..write('type: $type, ')
          ..write('commentaire: $commentaire, ')
          ..write('date: $date, ')
          ..write('sacsMantoUtilises: $sacsMantoUtilises, ')
          ..write('sacsSottomantoUtilises: $sacsSottomantoUtilises, ')
          ..write('sacsSiliceUtilises: $sacsSiliceUtilises')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    terrainId,
    type,
    commentaire,
    date,
    sacsMantoUtilises,
    sacsSottomantoUtilises,
    sacsSiliceUtilises,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceRow &&
          other.id == this.id &&
          other.terrainId == this.terrainId &&
          other.type == this.type &&
          other.commentaire == this.commentaire &&
          other.date == this.date &&
          other.sacsMantoUtilises == this.sacsMantoUtilises &&
          other.sacsSottomantoUtilises == this.sacsSottomantoUtilises &&
          other.sacsSiliceUtilises == this.sacsSiliceUtilises);
}

class MaintenancesCompanion extends UpdateCompanion<MaintenanceRow> {
  final Value<int> id;
  final Value<int> terrainId;
  final Value<String> type;
  final Value<String?> commentaire;
  final Value<int> date;
  final Value<int> sacsMantoUtilises;
  final Value<int> sacsSottomantoUtilises;
  final Value<int> sacsSiliceUtilises;
  const MaintenancesCompanion({
    this.id = const Value.absent(),
    this.terrainId = const Value.absent(),
    this.type = const Value.absent(),
    this.commentaire = const Value.absent(),
    this.date = const Value.absent(),
    this.sacsMantoUtilises = const Value.absent(),
    this.sacsSottomantoUtilises = const Value.absent(),
    this.sacsSiliceUtilises = const Value.absent(),
  });
  MaintenancesCompanion.insert({
    this.id = const Value.absent(),
    required int terrainId,
    required String type,
    this.commentaire = const Value.absent(),
    required int date,
    this.sacsMantoUtilises = const Value.absent(),
    this.sacsSottomantoUtilises = const Value.absent(),
    this.sacsSiliceUtilises = const Value.absent(),
  }) : terrainId = Value(terrainId),
       type = Value(type),
       date = Value(date);
  static Insertable<MaintenanceRow> custom({
    Expression<int>? id,
    Expression<int>? terrainId,
    Expression<String>? type,
    Expression<String>? commentaire,
    Expression<int>? date,
    Expression<int>? sacsMantoUtilises,
    Expression<int>? sacsSottomantoUtilises,
    Expression<int>? sacsSiliceUtilises,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (terrainId != null) 'terrain_id': terrainId,
      if (type != null) 'type': type,
      if (commentaire != null) 'commentaire': commentaire,
      if (date != null) 'date': date,
      if (sacsMantoUtilises != null) 'sacs_manto_utilises': sacsMantoUtilises,
      if (sacsSottomantoUtilises != null)
        'sacs_sottomanto_utilises': sacsSottomantoUtilises,
      if (sacsSiliceUtilises != null)
        'sacs_silice_utilises': sacsSiliceUtilises,
    });
  }

  MaintenancesCompanion copyWith({
    Value<int>? id,
    Value<int>? terrainId,
    Value<String>? type,
    Value<String?>? commentaire,
    Value<int>? date,
    Value<int>? sacsMantoUtilises,
    Value<int>? sacsSottomantoUtilises,
    Value<int>? sacsSiliceUtilises,
  }) {
    return MaintenancesCompanion(
      id: id ?? this.id,
      terrainId: terrainId ?? this.terrainId,
      type: type ?? this.type,
      commentaire: commentaire ?? this.commentaire,
      date: date ?? this.date,
      sacsMantoUtilises: sacsMantoUtilises ?? this.sacsMantoUtilises,
      sacsSottomantoUtilises:
          sacsSottomantoUtilises ?? this.sacsSottomantoUtilises,
      sacsSiliceUtilises: sacsSiliceUtilises ?? this.sacsSiliceUtilises,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (terrainId.present) {
      map['terrain_id'] = Variable<int>(terrainId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (commentaire.present) {
      map['commentaire'] = Variable<String>(commentaire.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (sacsMantoUtilises.present) {
      map['sacs_manto_utilises'] = Variable<int>(sacsMantoUtilises.value);
    }
    if (sacsSottomantoUtilises.present) {
      map['sacs_sottomanto_utilises'] = Variable<int>(
        sacsSottomantoUtilises.value,
      );
    }
    if (sacsSiliceUtilises.present) {
      map['sacs_silice_utilises'] = Variable<int>(sacsSiliceUtilises.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenancesCompanion(')
          ..write('id: $id, ')
          ..write('terrainId: $terrainId, ')
          ..write('type: $type, ')
          ..write('commentaire: $commentaire, ')
          ..write('date: $date, ')
          ..write('sacsMantoUtilises: $sacsMantoUtilises, ')
          ..write('sacsSottomantoUtilises: $sacsSottomantoUtilises, ')
          ..write('sacsSiliceUtilises: $sacsSiliceUtilises')
          ..write(')'))
        .toString();
  }
}

class $StockItemsTable extends StockItems
    with TableInfo<$StockItemsTable, StockItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
  );
  static const VerificationMeta _minThresholdMeta = const VerificationMeta(
    'minThreshold',
  );
  @override
  late final GeneratedColumn<int> minThreshold = GeneratedColumn<int>(
    'min_threshold',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    quantity,
    unit,
    comment,
    isCustom,
    minThreshold,
    updatedAt,
    category,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
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
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    } else if (isInserting) {
      context.missing(_isCustomMeta);
    }
    if (data.containsKey('min_threshold')) {
      context.handle(
        _minThresholdMeta,
        minThreshold.isAcceptableOrUnknown(
          data['min_threshold']!,
          _minThresholdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      minThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_threshold'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $StockItemsTable createAlias(String alias) {
    return $StockItemsTable(attachedDatabase, alias);
  }
}

class StockItemRow extends DataClass implements Insertable<StockItemRow> {
  final int id;
  final String name;
  final int quantity;
  final String unit;
  final String? comment;
  final bool isCustom;
  final int? minThreshold;
  final DateTime updatedAt;
  final String? category;
  final int sortOrder;
  const StockItemRow({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.comment,
    required this.isCustom,
    this.minThreshold,
    required this.updatedAt,
    this.category,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<int>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || minThreshold != null) {
      map['min_threshold'] = Variable<int>(minThreshold);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  StockItemsCompanion toCompanion(bool nullToAbsent) {
    return StockItemsCompanion(
      id: Value(id),
      name: Value(name),
      quantity: Value(quantity),
      unit: Value(unit),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      isCustom: Value(isCustom),
      minThreshold: minThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(minThreshold),
      updatedAt: Value(updatedAt),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      sortOrder: Value(sortOrder),
    );
  }

  factory StockItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockItemRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      comment: serializer.fromJson<String?>(json['comment']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      minThreshold: serializer.fromJson<int?>(json['minThreshold']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      category: serializer.fromJson<String?>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(unit),
      'comment': serializer.toJson<String?>(comment),
      'isCustom': serializer.toJson<bool>(isCustom),
      'minThreshold': serializer.toJson<int?>(minThreshold),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'category': serializer.toJson<String?>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  StockItemRow copyWith({
    int? id,
    String? name,
    int? quantity,
    String? unit,
    Value<String?> comment = const Value.absent(),
    bool? isCustom,
    Value<int?> minThreshold = const Value.absent(),
    DateTime? updatedAt,
    Value<String?> category = const Value.absent(),
    int? sortOrder,
  }) => StockItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    comment: comment.present ? comment.value : this.comment,
    isCustom: isCustom ?? this.isCustom,
    minThreshold: minThreshold.present ? minThreshold.value : this.minThreshold,
    updatedAt: updatedAt ?? this.updatedAt,
    category: category.present ? category.value : this.category,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  StockItemRow copyWithCompanion(StockItemsCompanion data) {
    return StockItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      comment: data.comment.present ? data.comment.value : this.comment,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      minThreshold: data.minThreshold.present
          ? data.minThreshold.value
          : this.minThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('comment: $comment, ')
          ..write('isCustom: $isCustom, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    quantity,
    unit,
    comment,
    isCustom,
    minThreshold,
    updatedAt,
    category,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.comment == this.comment &&
          other.isCustom == this.isCustom &&
          other.minThreshold == this.minThreshold &&
          other.updatedAt == this.updatedAt &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder);
}

class StockItemsCompanion extends UpdateCompanion<StockItemRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> quantity;
  final Value<String> unit;
  final Value<String?> comment;
  final Value<bool> isCustom;
  final Value<int?> minThreshold;
  final Value<DateTime> updatedAt;
  final Value<String?> category;
  final Value<int> sortOrder;
  const StockItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.comment = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.minThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  StockItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.quantity = const Value.absent(),
    required String unit,
    this.comment = const Value.absent(),
    required bool isCustom,
    this.minThreshold = const Value.absent(),
    required DateTime updatedAt,
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name),
       unit = Value(unit),
       isCustom = Value(isCustom),
       updatedAt = Value(updatedAt);
  static Insertable<StockItemRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<String>? comment,
    Expression<bool>? isCustom,
    Expression<int>? minThreshold,
    Expression<DateTime>? updatedAt,
    Expression<String>? category,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (comment != null) 'comment': comment,
      if (isCustom != null) 'is_custom': isCustom,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  StockItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? quantity,
    Value<String>? unit,
    Value<String?>? comment,
    Value<bool>? isCustom,
    Value<int?>? minThreshold,
    Value<DateTime>? updatedAt,
    Value<String?>? category,
    Value<int>? sortOrder,
  }) {
    return StockItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      comment: comment ?? this.comment,
      isCustom: isCustom ?? this.isCustom,
      minThreshold: minThreshold ?? this.minThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (minThreshold.present) {
      map['min_threshold'] = Variable<int>(minThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('comment: $comment, ')
          ..write('isCustom: $isCustom, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabase.connect(DatabaseConnection c) : super.connect(c);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TerrainsTable terrains = $TerrainsTable(this);
  late final $MaintenancesTable maintenances = $MaintenancesTable(this);
  late final $StockItemsTable stockItems = $StockItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    terrains,
    maintenances,
    stockItems,
  ];
}

typedef $$TerrainsTableCreateCompanionBuilder =
    TerrainsCompanion Function({
      Value<int> id,
      required String nom,
      required int type,
    });
typedef $$TerrainsTableUpdateCompanionBuilder =
    TerrainsCompanion Function({
      Value<int> id,
      Value<String> nom,
      Value<int> type,
    });

class $$TerrainsTableFilterComposer
    extends Composer<_$AppDatabase, $TerrainsTable> {
  $$TerrainsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TerrainsTableOrderingComposer
    extends Composer<_$AppDatabase, $TerrainsTable> {
  $$TerrainsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TerrainsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TerrainsTable> {
  $$TerrainsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$TerrainsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TerrainsTable,
          TerrainRow,
          $$TerrainsTableFilterComposer,
          $$TerrainsTableOrderingComposer,
          $$TerrainsTableAnnotationComposer,
          $$TerrainsTableCreateCompanionBuilder,
          $$TerrainsTableUpdateCompanionBuilder,
          (
            TerrainRow,
            BaseReferences<_$AppDatabase, $TerrainsTable, TerrainRow>,
          ),
          TerrainRow,
          PrefetchHooks Function()
        > {
  $$TerrainsTableTableManager(_$AppDatabase db, $TerrainsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TerrainsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TerrainsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TerrainsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<int> type = const Value.absent(),
              }) => TerrainsCompanion(id: id, nom: nom, type: type),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nom,
                required int type,
              }) => TerrainsCompanion.insert(id: id, nom: nom, type: type),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TerrainsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TerrainsTable,
      TerrainRow,
      $$TerrainsTableFilterComposer,
      $$TerrainsTableOrderingComposer,
      $$TerrainsTableAnnotationComposer,
      $$TerrainsTableCreateCompanionBuilder,
      $$TerrainsTableUpdateCompanionBuilder,
      (TerrainRow, BaseReferences<_$AppDatabase, $TerrainsTable, TerrainRow>),
      TerrainRow,
      PrefetchHooks Function()
    >;
typedef $$MaintenancesTableCreateCompanionBuilder =
    MaintenancesCompanion Function({
      Value<int> id,
      required int terrainId,
      required String type,
      Value<String?> commentaire,
      required int date,
      Value<int> sacsMantoUtilises,
      Value<int> sacsSottomantoUtilises,
      Value<int> sacsSiliceUtilises,
    });
typedef $$MaintenancesTableUpdateCompanionBuilder =
    MaintenancesCompanion Function({
      Value<int> id,
      Value<int> terrainId,
      Value<String> type,
      Value<String?> commentaire,
      Value<int> date,
      Value<int> sacsMantoUtilises,
      Value<int> sacsSottomantoUtilises,
      Value<int> sacsSiliceUtilises,
    });

class $$MaintenancesTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenancesTable> {
  $$MaintenancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get terrainId => $composableBuilder(
    column: $table.terrainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commentaire => $composableBuilder(
    column: $table.commentaire,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sacsMantoUtilises => $composableBuilder(
    column: $table.sacsMantoUtilises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sacsSottomantoUtilises => $composableBuilder(
    column: $table.sacsSottomantoUtilises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sacsSiliceUtilises => $composableBuilder(
    column: $table.sacsSiliceUtilises,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaintenancesTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenancesTable> {
  $$MaintenancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get terrainId => $composableBuilder(
    column: $table.terrainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentaire => $composableBuilder(
    column: $table.commentaire,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sacsMantoUtilises => $composableBuilder(
    column: $table.sacsMantoUtilises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sacsSottomantoUtilises => $composableBuilder(
    column: $table.sacsSottomantoUtilises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sacsSiliceUtilises => $composableBuilder(
    column: $table.sacsSiliceUtilises,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaintenancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenancesTable> {
  $$MaintenancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get terrainId =>
      $composableBuilder(column: $table.terrainId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get commentaire => $composableBuilder(
    column: $table.commentaire,
    builder: (column) => column,
  );

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get sacsMantoUtilises => $composableBuilder(
    column: $table.sacsMantoUtilises,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sacsSottomantoUtilises => $composableBuilder(
    column: $table.sacsSottomantoUtilises,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sacsSiliceUtilises => $composableBuilder(
    column: $table.sacsSiliceUtilises,
    builder: (column) => column,
  );
}

class $$MaintenancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenancesTable,
          MaintenanceRow,
          $$MaintenancesTableFilterComposer,
          $$MaintenancesTableOrderingComposer,
          $$MaintenancesTableAnnotationComposer,
          $$MaintenancesTableCreateCompanionBuilder,
          $$MaintenancesTableUpdateCompanionBuilder,
          (
            MaintenanceRow,
            BaseReferences<_$AppDatabase, $MaintenancesTable, MaintenanceRow>,
          ),
          MaintenanceRow,
          PrefetchHooks Function()
        > {
  $$MaintenancesTableTableManager(_$AppDatabase db, $MaintenancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> terrainId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> commentaire = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int> sacsMantoUtilises = const Value.absent(),
                Value<int> sacsSottomantoUtilises = const Value.absent(),
                Value<int> sacsSiliceUtilises = const Value.absent(),
              }) => MaintenancesCompanion(
                id: id,
                terrainId: terrainId,
                type: type,
                commentaire: commentaire,
                date: date,
                sacsMantoUtilises: sacsMantoUtilises,
                sacsSottomantoUtilises: sacsSottomantoUtilises,
                sacsSiliceUtilises: sacsSiliceUtilises,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int terrainId,
                required String type,
                Value<String?> commentaire = const Value.absent(),
                required int date,
                Value<int> sacsMantoUtilises = const Value.absent(),
                Value<int> sacsSottomantoUtilises = const Value.absent(),
                Value<int> sacsSiliceUtilises = const Value.absent(),
              }) => MaintenancesCompanion.insert(
                id: id,
                terrainId: terrainId,
                type: type,
                commentaire: commentaire,
                date: date,
                sacsMantoUtilises: sacsMantoUtilises,
                sacsSottomantoUtilises: sacsSottomantoUtilises,
                sacsSiliceUtilises: sacsSiliceUtilises,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaintenancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenancesTable,
      MaintenanceRow,
      $$MaintenancesTableFilterComposer,
      $$MaintenancesTableOrderingComposer,
      $$MaintenancesTableAnnotationComposer,
      $$MaintenancesTableCreateCompanionBuilder,
      $$MaintenancesTableUpdateCompanionBuilder,
      (
        MaintenanceRow,
        BaseReferences<_$AppDatabase, $MaintenancesTable, MaintenanceRow>,
      ),
      MaintenanceRow,
      PrefetchHooks Function()
    >;
typedef $$StockItemsTableCreateCompanionBuilder =
    StockItemsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> quantity,
      required String unit,
      Value<String?> comment,
      required bool isCustom,
      Value<int?> minThreshold,
      required DateTime updatedAt,
      Value<String?> category,
      Value<int> sortOrder,
    });
typedef $$StockItemsTableUpdateCompanionBuilder =
    StockItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> quantity,
      Value<String> unit,
      Value<String?> comment,
      Value<bool> isCustom,
      Value<int?> minThreshold,
      Value<DateTime> updatedAt,
      Value<String?> category,
      Value<int> sortOrder,
    });

class $$StockItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<int> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$StockItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockItemsTable,
          StockItemRow,
          $$StockItemsTableFilterComposer,
          $$StockItemsTableOrderingComposer,
          $$StockItemsTableAnnotationComposer,
          $$StockItemsTableCreateCompanionBuilder,
          $$StockItemsTableUpdateCompanionBuilder,
          (
            StockItemRow,
            BaseReferences<_$AppDatabase, $StockItemsTable, StockItemRow>,
          ),
          StockItemRow,
          PrefetchHooks Function()
        > {
  $$StockItemsTableTableManager(_$AppDatabase db, $StockItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int?> minThreshold = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => StockItemsCompanion(
                id: id,
                name: name,
                quantity: quantity,
                unit: unit,
                comment: comment,
                isCustom: isCustom,
                minThreshold: minThreshold,
                updatedAt: updatedAt,
                category: category,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> quantity = const Value.absent(),
                required String unit,
                Value<String?> comment = const Value.absent(),
                required bool isCustom,
                Value<int?> minThreshold = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => StockItemsCompanion.insert(
                id: id,
                name: name,
                quantity: quantity,
                unit: unit,
                comment: comment,
                isCustom: isCustom,
                minThreshold: minThreshold,
                updatedAt: updatedAt,
                category: category,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockItemsTable,
      StockItemRow,
      $$StockItemsTableFilterComposer,
      $$StockItemsTableOrderingComposer,
      $$StockItemsTableAnnotationComposer,
      $$StockItemsTableCreateCompanionBuilder,
      $$StockItemsTableUpdateCompanionBuilder,
      (
        StockItemRow,
        BaseReferences<_$AppDatabase, $StockItemsTable, StockItemRow>,
      ),
      StockItemRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TerrainsTableTableManager get terrains =>
      $$TerrainsTableTableManager(_db, _db.terrains);
  $$MaintenancesTableTableManager get maintenances =>
      $$MaintenancesTableTableManager(_db, _db.maintenances);
  $$StockItemsTableTableManager get stockItems =>
      $$StockItemsTableTableManager(_db, _db.stockItems);
}
