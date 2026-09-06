// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TiposClienteTable extends TiposCliente
    with TableInfo<$TiposClienteTable, TipoCliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposClienteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codTipoClienteMeta = const VerificationMeta(
    'codTipoCliente',
  );
  @override
  late final GeneratedColumn<String> codTipoCliente = GeneratedColumn<String>(
    'cod_tipo_cliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreTipoClienteMeta = const VerificationMeta(
    'nombreTipoCliente',
  );
  @override
  late final GeneratedColumn<String> nombreTipoCliente =
      GeneratedColumn<String>(
        'nombre_tipo_cliente',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codTipoCliente,
    nombreTipoCliente,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_cliente';
  @override
  VerificationContext validateIntegrity(
    Insertable<TipoCliente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_tipo_cliente')) {
      context.handle(
        _codTipoClienteMeta,
        codTipoCliente.isAcceptableOrUnknown(
          data['cod_tipo_cliente']!,
          _codTipoClienteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codTipoClienteMeta);
    }
    if (data.containsKey('nombre_tipo_cliente')) {
      context.handle(
        _nombreTipoClienteMeta,
        nombreTipoCliente.isAcceptableOrUnknown(
          data['nombre_tipo_cliente']!,
          _nombreTipoClienteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreTipoClienteMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codTipoCliente};
  @override
  TipoCliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TipoCliente(
      codTipoCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_tipo_cliente'],
      )!,
      nombreTipoCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_tipo_cliente'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $TiposClienteTable createAlias(String alias) {
    return $TiposClienteTable(attachedDatabase, alias);
  }
}

class TipoCliente extends DataClass implements Insertable<TipoCliente> {
  final String codTipoCliente;
  final String nombreTipoCliente;
  final bool activo;
  const TipoCliente({
    required this.codTipoCliente,
    required this.nombreTipoCliente,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_tipo_cliente'] = Variable<String>(codTipoCliente);
    map['nombre_tipo_cliente'] = Variable<String>(nombreTipoCliente);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  TiposClienteCompanion toCompanion(bool nullToAbsent) {
    return TiposClienteCompanion(
      codTipoCliente: Value(codTipoCliente),
      nombreTipoCliente: Value(nombreTipoCliente),
      activo: Value(activo),
    );
  }

  factory TipoCliente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TipoCliente(
      codTipoCliente: serializer.fromJson<String>(json['codTipoCliente']),
      nombreTipoCliente: serializer.fromJson<String>(json['nombreTipoCliente']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codTipoCliente': serializer.toJson<String>(codTipoCliente),
      'nombreTipoCliente': serializer.toJson<String>(nombreTipoCliente),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  TipoCliente copyWith({
    String? codTipoCliente,
    String? nombreTipoCliente,
    bool? activo,
  }) => TipoCliente(
    codTipoCliente: codTipoCliente ?? this.codTipoCliente,
    nombreTipoCliente: nombreTipoCliente ?? this.nombreTipoCliente,
    activo: activo ?? this.activo,
  );
  TipoCliente copyWithCompanion(TiposClienteCompanion data) {
    return TipoCliente(
      codTipoCliente: data.codTipoCliente.present
          ? data.codTipoCliente.value
          : this.codTipoCliente,
      nombreTipoCliente: data.nombreTipoCliente.present
          ? data.nombreTipoCliente.value
          : this.nombreTipoCliente,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TipoCliente(')
          ..write('codTipoCliente: $codTipoCliente, ')
          ..write('nombreTipoCliente: $nombreTipoCliente, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(codTipoCliente, nombreTipoCliente, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TipoCliente &&
          other.codTipoCliente == this.codTipoCliente &&
          other.nombreTipoCliente == this.nombreTipoCliente &&
          other.activo == this.activo);
}

class TiposClienteCompanion extends UpdateCompanion<TipoCliente> {
  final Value<String> codTipoCliente;
  final Value<String> nombreTipoCliente;
  final Value<bool> activo;
  final Value<int> rowid;
  const TiposClienteCompanion({
    this.codTipoCliente = const Value.absent(),
    this.nombreTipoCliente = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiposClienteCompanion.insert({
    required String codTipoCliente,
    required String nombreTipoCliente,
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codTipoCliente = Value(codTipoCliente),
       nombreTipoCliente = Value(nombreTipoCliente);
  static Insertable<TipoCliente> custom({
    Expression<String>? codTipoCliente,
    Expression<String>? nombreTipoCliente,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codTipoCliente != null) 'cod_tipo_cliente': codTipoCliente,
      if (nombreTipoCliente != null) 'nombre_tipo_cliente': nombreTipoCliente,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiposClienteCompanion copyWith({
    Value<String>? codTipoCliente,
    Value<String>? nombreTipoCliente,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return TiposClienteCompanion(
      codTipoCliente: codTipoCliente ?? this.codTipoCliente,
      nombreTipoCliente: nombreTipoCliente ?? this.nombreTipoCliente,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codTipoCliente.present) {
      map['cod_tipo_cliente'] = Variable<String>(codTipoCliente.value);
    }
    if (nombreTipoCliente.present) {
      map['nombre_tipo_cliente'] = Variable<String>(nombreTipoCliente.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposClienteCompanion(')
          ..write('codTipoCliente: $codTipoCliente, ')
          ..write('nombreTipoCliente: $nombreTipoCliente, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientesTable extends Clientes with TableInfo<$ClientesTable, Cliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codClienteMeta = const VerificationMeta(
    'codCliente',
  );
  @override
  late final GeneratedColumn<String> codCliente = GeneratedColumn<String>(
    'cod_cliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apellidoMeta = const VerificationMeta(
    'apellido',
  );
  @override
  late final GeneratedColumn<String> apellido = GeneratedColumn<String>(
    'apellido',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoClienteMeta = const VerificationMeta(
    'tipoCliente',
  );
  @override
  late final GeneratedColumn<String> tipoCliente = GeneratedColumn<String>(
    'tipo_cliente',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tipos_cliente (cod_tipo_cliente)',
    ),
  );
  static const VerificationMeta _fechaIngresoMeta = const VerificationMeta(
    'fechaIngreso',
  );
  @override
  late final GeneratedColumn<int> fechaIngreso = GeneratedColumn<int>(
    'fecha_ingreso',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantLecturasMeta = const VerificationMeta(
    'cantLecturas',
  );
  @override
  late final GeneratedColumn<int> cantLecturas = GeneratedColumn<int>(
    'cant_lecturas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalComprasMeta = const VerificationMeta(
    'totalCompras',
  );
  @override
  late final GeneratedColumn<int> totalCompras = GeneratedColumn<int>(
    'total_compras',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _montoTotalCentavosMeta =
      const VerificationMeta('montoTotalCentavos');
  @override
  late final GeneratedColumn<int> montoTotalCentavos = GeneratedColumn<int>(
    'monto_total_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimaVisitaMeta = const VerificationMeta(
    'ultimaVisita',
  );
  @override
  late final GeneratedColumn<int> ultimaVisita = GeneratedColumn<int>(
    'ultima_visita',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codCliente,
    nombre,
    apellido,
    tipoCliente,
    fechaIngreso,
    cantLecturas,
    totalCompras,
    montoTotalCentavos,
    ultimaVisita,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cliente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_cliente')) {
      context.handle(
        _codClienteMeta,
        codCliente.isAcceptableOrUnknown(data['cod_cliente']!, _codClienteMeta),
      );
    } else if (isInserting) {
      context.missing(_codClienteMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('apellido')) {
      context.handle(
        _apellidoMeta,
        apellido.isAcceptableOrUnknown(data['apellido']!, _apellidoMeta),
      );
    } else if (isInserting) {
      context.missing(_apellidoMeta);
    }
    if (data.containsKey('tipo_cliente')) {
      context.handle(
        _tipoClienteMeta,
        tipoCliente.isAcceptableOrUnknown(
          data['tipo_cliente']!,
          _tipoClienteMeta,
        ),
      );
    }
    if (data.containsKey('fecha_ingreso')) {
      context.handle(
        _fechaIngresoMeta,
        fechaIngreso.isAcceptableOrUnknown(
          data['fecha_ingreso']!,
          _fechaIngresoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaIngresoMeta);
    }
    if (data.containsKey('cant_lecturas')) {
      context.handle(
        _cantLecturasMeta,
        cantLecturas.isAcceptableOrUnknown(
          data['cant_lecturas']!,
          _cantLecturasMeta,
        ),
      );
    }
    if (data.containsKey('total_compras')) {
      context.handle(
        _totalComprasMeta,
        totalCompras.isAcceptableOrUnknown(
          data['total_compras']!,
          _totalComprasMeta,
        ),
      );
    }
    if (data.containsKey('monto_total_centavos')) {
      context.handle(
        _montoTotalCentavosMeta,
        montoTotalCentavos.isAcceptableOrUnknown(
          data['monto_total_centavos']!,
          _montoTotalCentavosMeta,
        ),
      );
    }
    if (data.containsKey('ultima_visita')) {
      context.handle(
        _ultimaVisitaMeta,
        ultimaVisita.isAcceptableOrUnknown(
          data['ultima_visita']!,
          _ultimaVisitaMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codCliente};
  @override
  Cliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cliente(
      codCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_cliente'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      apellido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apellido'],
      )!,
      tipoCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_cliente'],
      ),
      fechaIngreso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fecha_ingreso'],
      )!,
      cantLecturas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cant_lecturas'],
      )!,
      totalCompras: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_compras'],
      )!,
      montoTotalCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto_total_centavos'],
      )!,
      ultimaVisita: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ultima_visita'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $ClientesTable createAlias(String alias) {
    return $ClientesTable(attachedDatabase, alias);
  }
}

class Cliente extends DataClass implements Insertable<Cliente> {
  final String codCliente;
  final String nombre;
  final String apellido;
  final String? tipoCliente;
  final int fechaIngreso;
  final int cantLecturas;
  final int totalCompras;
  final int montoTotalCentavos;
  final int? ultimaVisita;
  final bool activo;
  const Cliente({
    required this.codCliente,
    required this.nombre,
    required this.apellido,
    this.tipoCliente,
    required this.fechaIngreso,
    required this.cantLecturas,
    required this.totalCompras,
    required this.montoTotalCentavos,
    this.ultimaVisita,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_cliente'] = Variable<String>(codCliente);
    map['nombre'] = Variable<String>(nombre);
    map['apellido'] = Variable<String>(apellido);
    if (!nullToAbsent || tipoCliente != null) {
      map['tipo_cliente'] = Variable<String>(tipoCliente);
    }
    map['fecha_ingreso'] = Variable<int>(fechaIngreso);
    map['cant_lecturas'] = Variable<int>(cantLecturas);
    map['total_compras'] = Variable<int>(totalCompras);
    map['monto_total_centavos'] = Variable<int>(montoTotalCentavos);
    if (!nullToAbsent || ultimaVisita != null) {
      map['ultima_visita'] = Variable<int>(ultimaVisita);
    }
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ClientesCompanion toCompanion(bool nullToAbsent) {
    return ClientesCompanion(
      codCliente: Value(codCliente),
      nombre: Value(nombre),
      apellido: Value(apellido),
      tipoCliente: tipoCliente == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoCliente),
      fechaIngreso: Value(fechaIngreso),
      cantLecturas: Value(cantLecturas),
      totalCompras: Value(totalCompras),
      montoTotalCentavos: Value(montoTotalCentavos),
      ultimaVisita: ultimaVisita == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaVisita),
      activo: Value(activo),
    );
  }

  factory Cliente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cliente(
      codCliente: serializer.fromJson<String>(json['codCliente']),
      nombre: serializer.fromJson<String>(json['nombre']),
      apellido: serializer.fromJson<String>(json['apellido']),
      tipoCliente: serializer.fromJson<String?>(json['tipoCliente']),
      fechaIngreso: serializer.fromJson<int>(json['fechaIngreso']),
      cantLecturas: serializer.fromJson<int>(json['cantLecturas']),
      totalCompras: serializer.fromJson<int>(json['totalCompras']),
      montoTotalCentavos: serializer.fromJson<int>(json['montoTotalCentavos']),
      ultimaVisita: serializer.fromJson<int?>(json['ultimaVisita']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codCliente': serializer.toJson<String>(codCliente),
      'nombre': serializer.toJson<String>(nombre),
      'apellido': serializer.toJson<String>(apellido),
      'tipoCliente': serializer.toJson<String?>(tipoCliente),
      'fechaIngreso': serializer.toJson<int>(fechaIngreso),
      'cantLecturas': serializer.toJson<int>(cantLecturas),
      'totalCompras': serializer.toJson<int>(totalCompras),
      'montoTotalCentavos': serializer.toJson<int>(montoTotalCentavos),
      'ultimaVisita': serializer.toJson<int?>(ultimaVisita),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  Cliente copyWith({
    String? codCliente,
    String? nombre,
    String? apellido,
    Value<String?> tipoCliente = const Value.absent(),
    int? fechaIngreso,
    int? cantLecturas,
    int? totalCompras,
    int? montoTotalCentavos,
    Value<int?> ultimaVisita = const Value.absent(),
    bool? activo,
  }) => Cliente(
    codCliente: codCliente ?? this.codCliente,
    nombre: nombre ?? this.nombre,
    apellido: apellido ?? this.apellido,
    tipoCliente: tipoCliente.present ? tipoCliente.value : this.tipoCliente,
    fechaIngreso: fechaIngreso ?? this.fechaIngreso,
    cantLecturas: cantLecturas ?? this.cantLecturas,
    totalCompras: totalCompras ?? this.totalCompras,
    montoTotalCentavos: montoTotalCentavos ?? this.montoTotalCentavos,
    ultimaVisita: ultimaVisita.present ? ultimaVisita.value : this.ultimaVisita,
    activo: activo ?? this.activo,
  );
  Cliente copyWithCompanion(ClientesCompanion data) {
    return Cliente(
      codCliente: data.codCliente.present
          ? data.codCliente.value
          : this.codCliente,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      apellido: data.apellido.present ? data.apellido.value : this.apellido,
      tipoCliente: data.tipoCliente.present
          ? data.tipoCliente.value
          : this.tipoCliente,
      fechaIngreso: data.fechaIngreso.present
          ? data.fechaIngreso.value
          : this.fechaIngreso,
      cantLecturas: data.cantLecturas.present
          ? data.cantLecturas.value
          : this.cantLecturas,
      totalCompras: data.totalCompras.present
          ? data.totalCompras.value
          : this.totalCompras,
      montoTotalCentavos: data.montoTotalCentavos.present
          ? data.montoTotalCentavos.value
          : this.montoTotalCentavos,
      ultimaVisita: data.ultimaVisita.present
          ? data.ultimaVisita.value
          : this.ultimaVisita,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cliente(')
          ..write('codCliente: $codCliente, ')
          ..write('nombre: $nombre, ')
          ..write('apellido: $apellido, ')
          ..write('tipoCliente: $tipoCliente, ')
          ..write('fechaIngreso: $fechaIngreso, ')
          ..write('cantLecturas: $cantLecturas, ')
          ..write('totalCompras: $totalCompras, ')
          ..write('montoTotalCentavos: $montoTotalCentavos, ')
          ..write('ultimaVisita: $ultimaVisita, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    codCliente,
    nombre,
    apellido,
    tipoCliente,
    fechaIngreso,
    cantLecturas,
    totalCompras,
    montoTotalCentavos,
    ultimaVisita,
    activo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cliente &&
          other.codCliente == this.codCliente &&
          other.nombre == this.nombre &&
          other.apellido == this.apellido &&
          other.tipoCliente == this.tipoCliente &&
          other.fechaIngreso == this.fechaIngreso &&
          other.cantLecturas == this.cantLecturas &&
          other.totalCompras == this.totalCompras &&
          other.montoTotalCentavos == this.montoTotalCentavos &&
          other.ultimaVisita == this.ultimaVisita &&
          other.activo == this.activo);
}

class ClientesCompanion extends UpdateCompanion<Cliente> {
  final Value<String> codCliente;
  final Value<String> nombre;
  final Value<String> apellido;
  final Value<String?> tipoCliente;
  final Value<int> fechaIngreso;
  final Value<int> cantLecturas;
  final Value<int> totalCompras;
  final Value<int> montoTotalCentavos;
  final Value<int?> ultimaVisita;
  final Value<bool> activo;
  final Value<int> rowid;
  const ClientesCompanion({
    this.codCliente = const Value.absent(),
    this.nombre = const Value.absent(),
    this.apellido = const Value.absent(),
    this.tipoCliente = const Value.absent(),
    this.fechaIngreso = const Value.absent(),
    this.cantLecturas = const Value.absent(),
    this.totalCompras = const Value.absent(),
    this.montoTotalCentavos = const Value.absent(),
    this.ultimaVisita = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientesCompanion.insert({
    required String codCliente,
    required String nombre,
    required String apellido,
    this.tipoCliente = const Value.absent(),
    required int fechaIngreso,
    this.cantLecturas = const Value.absent(),
    this.totalCompras = const Value.absent(),
    this.montoTotalCentavos = const Value.absent(),
    this.ultimaVisita = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codCliente = Value(codCliente),
       nombre = Value(nombre),
       apellido = Value(apellido),
       fechaIngreso = Value(fechaIngreso);
  static Insertable<Cliente> custom({
    Expression<String>? codCliente,
    Expression<String>? nombre,
    Expression<String>? apellido,
    Expression<String>? tipoCliente,
    Expression<int>? fechaIngreso,
    Expression<int>? cantLecturas,
    Expression<int>? totalCompras,
    Expression<int>? montoTotalCentavos,
    Expression<int>? ultimaVisita,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codCliente != null) 'cod_cliente': codCliente,
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (tipoCliente != null) 'tipo_cliente': tipoCliente,
      if (fechaIngreso != null) 'fecha_ingreso': fechaIngreso,
      if (cantLecturas != null) 'cant_lecturas': cantLecturas,
      if (totalCompras != null) 'total_compras': totalCompras,
      if (montoTotalCentavos != null)
        'monto_total_centavos': montoTotalCentavos,
      if (ultimaVisita != null) 'ultima_visita': ultimaVisita,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientesCompanion copyWith({
    Value<String>? codCliente,
    Value<String>? nombre,
    Value<String>? apellido,
    Value<String?>? tipoCliente,
    Value<int>? fechaIngreso,
    Value<int>? cantLecturas,
    Value<int>? totalCompras,
    Value<int>? montoTotalCentavos,
    Value<int?>? ultimaVisita,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return ClientesCompanion(
      codCliente: codCliente ?? this.codCliente,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      tipoCliente: tipoCliente ?? this.tipoCliente,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      cantLecturas: cantLecturas ?? this.cantLecturas,
      totalCompras: totalCompras ?? this.totalCompras,
      montoTotalCentavos: montoTotalCentavos ?? this.montoTotalCentavos,
      ultimaVisita: ultimaVisita ?? this.ultimaVisita,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codCliente.present) {
      map['cod_cliente'] = Variable<String>(codCliente.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (apellido.present) {
      map['apellido'] = Variable<String>(apellido.value);
    }
    if (tipoCliente.present) {
      map['tipo_cliente'] = Variable<String>(tipoCliente.value);
    }
    if (fechaIngreso.present) {
      map['fecha_ingreso'] = Variable<int>(fechaIngreso.value);
    }
    if (cantLecturas.present) {
      map['cant_lecturas'] = Variable<int>(cantLecturas.value);
    }
    if (totalCompras.present) {
      map['total_compras'] = Variable<int>(totalCompras.value);
    }
    if (montoTotalCentavos.present) {
      map['monto_total_centavos'] = Variable<int>(montoTotalCentavos.value);
    }
    if (ultimaVisita.present) {
      map['ultima_visita'] = Variable<int>(ultimaVisita.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesCompanion(')
          ..write('codCliente: $codCliente, ')
          ..write('nombre: $nombre, ')
          ..write('apellido: $apellido, ')
          ..write('tipoCliente: $tipoCliente, ')
          ..write('fechaIngreso: $fechaIngreso, ')
          ..write('cantLecturas: $cantLecturas, ')
          ..write('totalCompras: $totalCompras, ')
          ..write('montoTotalCentavos: $montoTotalCentavos, ')
          ..write('ultimaVisita: $ultimaVisita, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstrategiasTable extends Estrategias
    with TableInfo<$EstrategiasTable, Estrategia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstrategiasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codEstrategiaMeta = const VerificationMeta(
    'codEstrategia',
  );
  @override
  late final GeneratedColumn<String> codEstrategia = GeneratedColumn<String>(
    'cod_estrategia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreEstrategiaMeta = const VerificationMeta(
    'nombreEstrategia',
  );
  @override
  late final GeneratedColumn<String> nombreEstrategia = GeneratedColumn<String>(
    'nombre_estrategia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalVecesAplicadaMeta =
      const VerificationMeta('totalVecesAplicada');
  @override
  late final GeneratedColumn<int> totalVecesAplicada = GeneratedColumn<int>(
    'total_veces_aplicada',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ventasGeneradasMeta = const VerificationMeta(
    'ventasGeneradas',
  );
  @override
  late final GeneratedColumn<int> ventasGeneradas = GeneratedColumn<int>(
    'ventas_generadas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codEstrategia,
    nombreEstrategia,
    totalVecesAplicada,
    ventasGeneradas,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estrategias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Estrategia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_estrategia')) {
      context.handle(
        _codEstrategiaMeta,
        codEstrategia.isAcceptableOrUnknown(
          data['cod_estrategia']!,
          _codEstrategiaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codEstrategiaMeta);
    }
    if (data.containsKey('nombre_estrategia')) {
      context.handle(
        _nombreEstrategiaMeta,
        nombreEstrategia.isAcceptableOrUnknown(
          data['nombre_estrategia']!,
          _nombreEstrategiaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreEstrategiaMeta);
    }
    if (data.containsKey('total_veces_aplicada')) {
      context.handle(
        _totalVecesAplicadaMeta,
        totalVecesAplicada.isAcceptableOrUnknown(
          data['total_veces_aplicada']!,
          _totalVecesAplicadaMeta,
        ),
      );
    }
    if (data.containsKey('ventas_generadas')) {
      context.handle(
        _ventasGeneradasMeta,
        ventasGeneradas.isAcceptableOrUnknown(
          data['ventas_generadas']!,
          _ventasGeneradasMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codEstrategia};
  @override
  Estrategia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Estrategia(
      codEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_estrategia'],
      )!,
      nombreEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_estrategia'],
      )!,
      totalVecesAplicada: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_veces_aplicada'],
      )!,
      ventasGeneradas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ventas_generadas'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $EstrategiasTable createAlias(String alias) {
    return $EstrategiasTable(attachedDatabase, alias);
  }
}

class Estrategia extends DataClass implements Insertable<Estrategia> {
  final String codEstrategia;
  final String nombreEstrategia;
  final int totalVecesAplicada;
  final int ventasGeneradas;
  final bool activo;
  const Estrategia({
    required this.codEstrategia,
    required this.nombreEstrategia,
    required this.totalVecesAplicada,
    required this.ventasGeneradas,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_estrategia'] = Variable<String>(codEstrategia);
    map['nombre_estrategia'] = Variable<String>(nombreEstrategia);
    map['total_veces_aplicada'] = Variable<int>(totalVecesAplicada);
    map['ventas_generadas'] = Variable<int>(ventasGeneradas);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  EstrategiasCompanion toCompanion(bool nullToAbsent) {
    return EstrategiasCompanion(
      codEstrategia: Value(codEstrategia),
      nombreEstrategia: Value(nombreEstrategia),
      totalVecesAplicada: Value(totalVecesAplicada),
      ventasGeneradas: Value(ventasGeneradas),
      activo: Value(activo),
    );
  }

  factory Estrategia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Estrategia(
      codEstrategia: serializer.fromJson<String>(json['codEstrategia']),
      nombreEstrategia: serializer.fromJson<String>(json['nombreEstrategia']),
      totalVecesAplicada: serializer.fromJson<int>(json['totalVecesAplicada']),
      ventasGeneradas: serializer.fromJson<int>(json['ventasGeneradas']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codEstrategia': serializer.toJson<String>(codEstrategia),
      'nombreEstrategia': serializer.toJson<String>(nombreEstrategia),
      'totalVecesAplicada': serializer.toJson<int>(totalVecesAplicada),
      'ventasGeneradas': serializer.toJson<int>(ventasGeneradas),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  Estrategia copyWith({
    String? codEstrategia,
    String? nombreEstrategia,
    int? totalVecesAplicada,
    int? ventasGeneradas,
    bool? activo,
  }) => Estrategia(
    codEstrategia: codEstrategia ?? this.codEstrategia,
    nombreEstrategia: nombreEstrategia ?? this.nombreEstrategia,
    totalVecesAplicada: totalVecesAplicada ?? this.totalVecesAplicada,
    ventasGeneradas: ventasGeneradas ?? this.ventasGeneradas,
    activo: activo ?? this.activo,
  );
  Estrategia copyWithCompanion(EstrategiasCompanion data) {
    return Estrategia(
      codEstrategia: data.codEstrategia.present
          ? data.codEstrategia.value
          : this.codEstrategia,
      nombreEstrategia: data.nombreEstrategia.present
          ? data.nombreEstrategia.value
          : this.nombreEstrategia,
      totalVecesAplicada: data.totalVecesAplicada.present
          ? data.totalVecesAplicada.value
          : this.totalVecesAplicada,
      ventasGeneradas: data.ventasGeneradas.present
          ? data.ventasGeneradas.value
          : this.ventasGeneradas,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Estrategia(')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('nombreEstrategia: $nombreEstrategia, ')
          ..write('totalVecesAplicada: $totalVecesAplicada, ')
          ..write('ventasGeneradas: $ventasGeneradas, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    codEstrategia,
    nombreEstrategia,
    totalVecesAplicada,
    ventasGeneradas,
    activo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Estrategia &&
          other.codEstrategia == this.codEstrategia &&
          other.nombreEstrategia == this.nombreEstrategia &&
          other.totalVecesAplicada == this.totalVecesAplicada &&
          other.ventasGeneradas == this.ventasGeneradas &&
          other.activo == this.activo);
}

class EstrategiasCompanion extends UpdateCompanion<Estrategia> {
  final Value<String> codEstrategia;
  final Value<String> nombreEstrategia;
  final Value<int> totalVecesAplicada;
  final Value<int> ventasGeneradas;
  final Value<bool> activo;
  final Value<int> rowid;
  const EstrategiasCompanion({
    this.codEstrategia = const Value.absent(),
    this.nombreEstrategia = const Value.absent(),
    this.totalVecesAplicada = const Value.absent(),
    this.ventasGeneradas = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EstrategiasCompanion.insert({
    required String codEstrategia,
    required String nombreEstrategia,
    this.totalVecesAplicada = const Value.absent(),
    this.ventasGeneradas = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codEstrategia = Value(codEstrategia),
       nombreEstrategia = Value(nombreEstrategia);
  static Insertable<Estrategia> custom({
    Expression<String>? codEstrategia,
    Expression<String>? nombreEstrategia,
    Expression<int>? totalVecesAplicada,
    Expression<int>? ventasGeneradas,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codEstrategia != null) 'cod_estrategia': codEstrategia,
      if (nombreEstrategia != null) 'nombre_estrategia': nombreEstrategia,
      if (totalVecesAplicada != null)
        'total_veces_aplicada': totalVecesAplicada,
      if (ventasGeneradas != null) 'ventas_generadas': ventasGeneradas,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EstrategiasCompanion copyWith({
    Value<String>? codEstrategia,
    Value<String>? nombreEstrategia,
    Value<int>? totalVecesAplicada,
    Value<int>? ventasGeneradas,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return EstrategiasCompanion(
      codEstrategia: codEstrategia ?? this.codEstrategia,
      nombreEstrategia: nombreEstrategia ?? this.nombreEstrategia,
      totalVecesAplicada: totalVecesAplicada ?? this.totalVecesAplicada,
      ventasGeneradas: ventasGeneradas ?? this.ventasGeneradas,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codEstrategia.present) {
      map['cod_estrategia'] = Variable<String>(codEstrategia.value);
    }
    if (nombreEstrategia.present) {
      map['nombre_estrategia'] = Variable<String>(nombreEstrategia.value);
    }
    if (totalVecesAplicada.present) {
      map['total_veces_aplicada'] = Variable<int>(totalVecesAplicada.value);
    }
    if (ventasGeneradas.present) {
      map['ventas_generadas'] = Variable<int>(ventasGeneradas.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstrategiasCompanion(')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('nombreEstrategia: $nombreEstrategia, ')
          ..write('totalVecesAplicada: $totalVecesAplicada, ')
          ..write('ventasGeneradas: $ventasGeneradas, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TiposTransaccionTable extends TiposTransaccion
    with TableInfo<$TiposTransaccionTable, TipoTransaccion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposTransaccionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codTransaccionMeta = const VerificationMeta(
    'codTransaccion',
  );
  @override
  late final GeneratedColumn<String> codTransaccion = GeneratedColumn<String>(
    'cod_transaccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoTrxMeta = const VerificationMeta(
    'tipoTrx',
  );
  @override
  late final GeneratedColumn<String> tipoTrx = GeneratedColumn<String>(
    'tipo_trx',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codProtocoloMeta = const VerificationMeta(
    'codProtocolo',
  );
  @override
  late final GeneratedColumn<String> codProtocolo = GeneratedColumn<String>(
    'cod_protocolo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codTransaccion,
    tipoTrx,
    codProtocolo,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_transaccion';
  @override
  VerificationContext validateIntegrity(
    Insertable<TipoTransaccion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_transaccion')) {
      context.handle(
        _codTransaccionMeta,
        codTransaccion.isAcceptableOrUnknown(
          data['cod_transaccion']!,
          _codTransaccionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codTransaccionMeta);
    }
    if (data.containsKey('tipo_trx')) {
      context.handle(
        _tipoTrxMeta,
        tipoTrx.isAcceptableOrUnknown(data['tipo_trx']!, _tipoTrxMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoTrxMeta);
    }
    if (data.containsKey('cod_protocolo')) {
      context.handle(
        _codProtocoloMeta,
        codProtocolo.isAcceptableOrUnknown(
          data['cod_protocolo']!,
          _codProtocoloMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codTransaccion};
  @override
  TipoTransaccion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TipoTransaccion(
      codTransaccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_transaccion'],
      )!,
      tipoTrx: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_trx'],
      )!,
      codProtocolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_protocolo'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $TiposTransaccionTable createAlias(String alias) {
    return $TiposTransaccionTable(attachedDatabase, alias);
  }
}

class TipoTransaccion extends DataClass implements Insertable<TipoTransaccion> {
  final String codTransaccion;
  final String tipoTrx;
  final String? codProtocolo;
  final bool activo;
  const TipoTransaccion({
    required this.codTransaccion,
    required this.tipoTrx,
    this.codProtocolo,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_transaccion'] = Variable<String>(codTransaccion);
    map['tipo_trx'] = Variable<String>(tipoTrx);
    if (!nullToAbsent || codProtocolo != null) {
      map['cod_protocolo'] = Variable<String>(codProtocolo);
    }
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  TiposTransaccionCompanion toCompanion(bool nullToAbsent) {
    return TiposTransaccionCompanion(
      codTransaccion: Value(codTransaccion),
      tipoTrx: Value(tipoTrx),
      codProtocolo: codProtocolo == null && nullToAbsent
          ? const Value.absent()
          : Value(codProtocolo),
      activo: Value(activo),
    );
  }

  factory TipoTransaccion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TipoTransaccion(
      codTransaccion: serializer.fromJson<String>(json['codTransaccion']),
      tipoTrx: serializer.fromJson<String>(json['tipoTrx']),
      codProtocolo: serializer.fromJson<String?>(json['codProtocolo']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codTransaccion': serializer.toJson<String>(codTransaccion),
      'tipoTrx': serializer.toJson<String>(tipoTrx),
      'codProtocolo': serializer.toJson<String?>(codProtocolo),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  TipoTransaccion copyWith({
    String? codTransaccion,
    String? tipoTrx,
    Value<String?> codProtocolo = const Value.absent(),
    bool? activo,
  }) => TipoTransaccion(
    codTransaccion: codTransaccion ?? this.codTransaccion,
    tipoTrx: tipoTrx ?? this.tipoTrx,
    codProtocolo: codProtocolo.present ? codProtocolo.value : this.codProtocolo,
    activo: activo ?? this.activo,
  );
  TipoTransaccion copyWithCompanion(TiposTransaccionCompanion data) {
    return TipoTransaccion(
      codTransaccion: data.codTransaccion.present
          ? data.codTransaccion.value
          : this.codTransaccion,
      tipoTrx: data.tipoTrx.present ? data.tipoTrx.value : this.tipoTrx,
      codProtocolo: data.codProtocolo.present
          ? data.codProtocolo.value
          : this.codProtocolo,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TipoTransaccion(')
          ..write('codTransaccion: $codTransaccion, ')
          ..write('tipoTrx: $tipoTrx, ')
          ..write('codProtocolo: $codProtocolo, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(codTransaccion, tipoTrx, codProtocolo, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TipoTransaccion &&
          other.codTransaccion == this.codTransaccion &&
          other.tipoTrx == this.tipoTrx &&
          other.codProtocolo == this.codProtocolo &&
          other.activo == this.activo);
}

class TiposTransaccionCompanion extends UpdateCompanion<TipoTransaccion> {
  final Value<String> codTransaccion;
  final Value<String> tipoTrx;
  final Value<String?> codProtocolo;
  final Value<bool> activo;
  final Value<int> rowid;
  const TiposTransaccionCompanion({
    this.codTransaccion = const Value.absent(),
    this.tipoTrx = const Value.absent(),
    this.codProtocolo = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiposTransaccionCompanion.insert({
    required String codTransaccion,
    required String tipoTrx,
    this.codProtocolo = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codTransaccion = Value(codTransaccion),
       tipoTrx = Value(tipoTrx);
  static Insertable<TipoTransaccion> custom({
    Expression<String>? codTransaccion,
    Expression<String>? tipoTrx,
    Expression<String>? codProtocolo,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codTransaccion != null) 'cod_transaccion': codTransaccion,
      if (tipoTrx != null) 'tipo_trx': tipoTrx,
      if (codProtocolo != null) 'cod_protocolo': codProtocolo,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiposTransaccionCompanion copyWith({
    Value<String>? codTransaccion,
    Value<String>? tipoTrx,
    Value<String?>? codProtocolo,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return TiposTransaccionCompanion(
      codTransaccion: codTransaccion ?? this.codTransaccion,
      tipoTrx: tipoTrx ?? this.tipoTrx,
      codProtocolo: codProtocolo ?? this.codProtocolo,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codTransaccion.present) {
      map['cod_transaccion'] = Variable<String>(codTransaccion.value);
    }
    if (tipoTrx.present) {
      map['tipo_trx'] = Variable<String>(tipoTrx.value);
    }
    if (codProtocolo.present) {
      map['cod_protocolo'] = Variable<String>(codProtocolo.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposTransaccionCompanion(')
          ..write('codTransaccion: $codTransaccion, ')
          ..write('tipoTrx: $tipoTrx, ')
          ..write('codProtocolo: $codProtocolo, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VentasTable extends Ventas with TableInfo<$VentasTable, Venta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VentasTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _canalMeta = const VerificationMeta('canal');
  @override
  late final GeneratedColumn<String> canal = GeneratedColumn<String>(
    'canal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correlativoMeta = const VerificationMeta(
    'correlativo',
  );
  @override
  late final GeneratedColumn<int> correlativo = GeneratedColumn<int>(
    'correlativo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idProcesoPersuasionMeta =
      const VerificationMeta('idProcesoPersuasion');
  @override
  late final GeneratedColumn<String> idProcesoPersuasion =
      GeneratedColumn<String>(
        'id_proceso_persuasion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _codClienteMeta = const VerificationMeta(
    'codCliente',
  );
  @override
  late final GeneratedColumn<String> codCliente = GeneratedColumn<String>(
    'cod_cliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clientes (cod_cliente)',
    ),
  );
  static const VerificationMeta _codEstrategiaMeta = const VerificationMeta(
    'codEstrategia',
  );
  @override
  late final GeneratedColumn<String> codEstrategia = GeneratedColumn<String>(
    'cod_estrategia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES estrategias (cod_estrategia)',
    ),
  );
  static const VerificationMeta _tipoTransaccionMeta = const VerificationMeta(
    'tipoTransaccion',
  );
  @override
  late final GeneratedColumn<String> tipoTransaccion = GeneratedColumn<String>(
    'tipo_transaccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tipos_transaccion (cod_transaccion)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canal,
    correlativo,
    idProcesoPersuasion,
    codCliente,
    codEstrategia,
    tipoTransaccion,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ventas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Venta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('canal')) {
      context.handle(
        _canalMeta,
        canal.isAcceptableOrUnknown(data['canal']!, _canalMeta),
      );
    } else if (isInserting) {
      context.missing(_canalMeta);
    }
    if (data.containsKey('correlativo')) {
      context.handle(
        _correlativoMeta,
        correlativo.isAcceptableOrUnknown(
          data['correlativo']!,
          _correlativoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correlativoMeta);
    }
    if (data.containsKey('id_proceso_persuasion')) {
      context.handle(
        _idProcesoPersuasionMeta,
        idProcesoPersuasion.isAcceptableOrUnknown(
          data['id_proceso_persuasion']!,
          _idProcesoPersuasionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idProcesoPersuasionMeta);
    }
    if (data.containsKey('cod_cliente')) {
      context.handle(
        _codClienteMeta,
        codCliente.isAcceptableOrUnknown(data['cod_cliente']!, _codClienteMeta),
      );
    } else if (isInserting) {
      context.missing(_codClienteMeta);
    }
    if (data.containsKey('cod_estrategia')) {
      context.handle(
        _codEstrategiaMeta,
        codEstrategia.isAcceptableOrUnknown(
          data['cod_estrategia']!,
          _codEstrategiaMeta,
        ),
      );
    }
    if (data.containsKey('tipo_transaccion')) {
      context.handle(
        _tipoTransaccionMeta,
        tipoTransaccion.isAcceptableOrUnknown(
          data['tipo_transaccion']!,
          _tipoTransaccionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tipoTransaccionMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Venta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Venta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      canal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canal'],
      )!,
      correlativo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correlativo'],
      )!,
      idProcesoPersuasion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_proceso_persuasion'],
      )!,
      codCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_cliente'],
      )!,
      codEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_estrategia'],
      ),
      tipoTransaccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_transaccion'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $VentasTable createAlias(String alias) {
    return $VentasTable(attachedDatabase, alias);
  }
}

class Venta extends DataClass implements Insertable<Venta> {
  final int id;
  final String canal;
  final int correlativo;
  final String idProcesoPersuasion;
  final String codCliente;
  final String? codEstrategia;
  final String tipoTransaccion;
  final int timestamp;
  const Venta({
    required this.id,
    required this.canal,
    required this.correlativo,
    required this.idProcesoPersuasion,
    required this.codCliente,
    this.codEstrategia,
    required this.tipoTransaccion,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['canal'] = Variable<String>(canal);
    map['correlativo'] = Variable<int>(correlativo);
    map['id_proceso_persuasion'] = Variable<String>(idProcesoPersuasion);
    map['cod_cliente'] = Variable<String>(codCliente);
    if (!nullToAbsent || codEstrategia != null) {
      map['cod_estrategia'] = Variable<String>(codEstrategia);
    }
    map['tipo_transaccion'] = Variable<String>(tipoTransaccion);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  VentasCompanion toCompanion(bool nullToAbsent) {
    return VentasCompanion(
      id: Value(id),
      canal: Value(canal),
      correlativo: Value(correlativo),
      idProcesoPersuasion: Value(idProcesoPersuasion),
      codCliente: Value(codCliente),
      codEstrategia: codEstrategia == null && nullToAbsent
          ? const Value.absent()
          : Value(codEstrategia),
      tipoTransaccion: Value(tipoTransaccion),
      timestamp: Value(timestamp),
    );
  }

  factory Venta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Venta(
      id: serializer.fromJson<int>(json['id']),
      canal: serializer.fromJson<String>(json['canal']),
      correlativo: serializer.fromJson<int>(json['correlativo']),
      idProcesoPersuasion: serializer.fromJson<String>(
        json['idProcesoPersuasion'],
      ),
      codCliente: serializer.fromJson<String>(json['codCliente']),
      codEstrategia: serializer.fromJson<String?>(json['codEstrategia']),
      tipoTransaccion: serializer.fromJson<String>(json['tipoTransaccion']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'canal': serializer.toJson<String>(canal),
      'correlativo': serializer.toJson<int>(correlativo),
      'idProcesoPersuasion': serializer.toJson<String>(idProcesoPersuasion),
      'codCliente': serializer.toJson<String>(codCliente),
      'codEstrategia': serializer.toJson<String?>(codEstrategia),
      'tipoTransaccion': serializer.toJson<String>(tipoTransaccion),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Venta copyWith({
    int? id,
    String? canal,
    int? correlativo,
    String? idProcesoPersuasion,
    String? codCliente,
    Value<String?> codEstrategia = const Value.absent(),
    String? tipoTransaccion,
    int? timestamp,
  }) => Venta(
    id: id ?? this.id,
    canal: canal ?? this.canal,
    correlativo: correlativo ?? this.correlativo,
    idProcesoPersuasion: idProcesoPersuasion ?? this.idProcesoPersuasion,
    codCliente: codCliente ?? this.codCliente,
    codEstrategia: codEstrategia.present
        ? codEstrategia.value
        : this.codEstrategia,
    tipoTransaccion: tipoTransaccion ?? this.tipoTransaccion,
    timestamp: timestamp ?? this.timestamp,
  );
  Venta copyWithCompanion(VentasCompanion data) {
    return Venta(
      id: data.id.present ? data.id.value : this.id,
      canal: data.canal.present ? data.canal.value : this.canal,
      correlativo: data.correlativo.present
          ? data.correlativo.value
          : this.correlativo,
      idProcesoPersuasion: data.idProcesoPersuasion.present
          ? data.idProcesoPersuasion.value
          : this.idProcesoPersuasion,
      codCliente: data.codCliente.present
          ? data.codCliente.value
          : this.codCliente,
      codEstrategia: data.codEstrategia.present
          ? data.codEstrategia.value
          : this.codEstrategia,
      tipoTransaccion: data.tipoTransaccion.present
          ? data.tipoTransaccion.value
          : this.tipoTransaccion,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Venta(')
          ..write('id: $id, ')
          ..write('canal: $canal, ')
          ..write('correlativo: $correlativo, ')
          ..write('idProcesoPersuasion: $idProcesoPersuasion, ')
          ..write('codCliente: $codCliente, ')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('tipoTransaccion: $tipoTransaccion, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canal,
    correlativo,
    idProcesoPersuasion,
    codCliente,
    codEstrategia,
    tipoTransaccion,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Venta &&
          other.id == this.id &&
          other.canal == this.canal &&
          other.correlativo == this.correlativo &&
          other.idProcesoPersuasion == this.idProcesoPersuasion &&
          other.codCliente == this.codCliente &&
          other.codEstrategia == this.codEstrategia &&
          other.tipoTransaccion == this.tipoTransaccion &&
          other.timestamp == this.timestamp);
}

class VentasCompanion extends UpdateCompanion<Venta> {
  final Value<int> id;
  final Value<String> canal;
  final Value<int> correlativo;
  final Value<String> idProcesoPersuasion;
  final Value<String> codCliente;
  final Value<String?> codEstrategia;
  final Value<String> tipoTransaccion;
  final Value<int> timestamp;
  const VentasCompanion({
    this.id = const Value.absent(),
    this.canal = const Value.absent(),
    this.correlativo = const Value.absent(),
    this.idProcesoPersuasion = const Value.absent(),
    this.codCliente = const Value.absent(),
    this.codEstrategia = const Value.absent(),
    this.tipoTransaccion = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  VentasCompanion.insert({
    this.id = const Value.absent(),
    required String canal,
    required int correlativo,
    required String idProcesoPersuasion,
    required String codCliente,
    this.codEstrategia = const Value.absent(),
    required String tipoTransaccion,
    required int timestamp,
  }) : canal = Value(canal),
       correlativo = Value(correlativo),
       idProcesoPersuasion = Value(idProcesoPersuasion),
       codCliente = Value(codCliente),
       tipoTransaccion = Value(tipoTransaccion),
       timestamp = Value(timestamp);
  static Insertable<Venta> custom({
    Expression<int>? id,
    Expression<String>? canal,
    Expression<int>? correlativo,
    Expression<String>? idProcesoPersuasion,
    Expression<String>? codCliente,
    Expression<String>? codEstrategia,
    Expression<String>? tipoTransaccion,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canal != null) 'canal': canal,
      if (correlativo != null) 'correlativo': correlativo,
      if (idProcesoPersuasion != null)
        'id_proceso_persuasion': idProcesoPersuasion,
      if (codCliente != null) 'cod_cliente': codCliente,
      if (codEstrategia != null) 'cod_estrategia': codEstrategia,
      if (tipoTransaccion != null) 'tipo_transaccion': tipoTransaccion,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  VentasCompanion copyWith({
    Value<int>? id,
    Value<String>? canal,
    Value<int>? correlativo,
    Value<String>? idProcesoPersuasion,
    Value<String>? codCliente,
    Value<String?>? codEstrategia,
    Value<String>? tipoTransaccion,
    Value<int>? timestamp,
  }) {
    return VentasCompanion(
      id: id ?? this.id,
      canal: canal ?? this.canal,
      correlativo: correlativo ?? this.correlativo,
      idProcesoPersuasion: idProcesoPersuasion ?? this.idProcesoPersuasion,
      codCliente: codCliente ?? this.codCliente,
      codEstrategia: codEstrategia ?? this.codEstrategia,
      tipoTransaccion: tipoTransaccion ?? this.tipoTransaccion,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (canal.present) {
      map['canal'] = Variable<String>(canal.value);
    }
    if (correlativo.present) {
      map['correlativo'] = Variable<int>(correlativo.value);
    }
    if (idProcesoPersuasion.present) {
      map['id_proceso_persuasion'] = Variable<String>(
        idProcesoPersuasion.value,
      );
    }
    if (codCliente.present) {
      map['cod_cliente'] = Variable<String>(codCliente.value);
    }
    if (codEstrategia.present) {
      map['cod_estrategia'] = Variable<String>(codEstrategia.value);
    }
    if (tipoTransaccion.present) {
      map['tipo_transaccion'] = Variable<String>(tipoTransaccion.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VentasCompanion(')
          ..write('id: $id, ')
          ..write('canal: $canal, ')
          ..write('correlativo: $correlativo, ')
          ..write('idProcesoPersuasion: $idProcesoPersuasion, ')
          ..write('codCliente: $codCliente, ')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('tipoTransaccion: $tipoTransaccion, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $TiposProductoTable extends TiposProducto
    with TableInfo<$TiposProductoTable, TipoProducto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposProductoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tipoProductoMeta = const VerificationMeta(
    'tipoProducto',
  );
  @override
  late final GeneratedColumn<String> tipoProducto = GeneratedColumn<String>(
    'tipo_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreTipoProductoMeta =
      const VerificationMeta('nombreTipoProducto');
  @override
  late final GeneratedColumn<String> nombreTipoProducto =
      GeneratedColumn<String>(
        'nombre_tipo_producto',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    tipoProducto,
    nombreTipoProducto,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_producto';
  @override
  VerificationContext validateIntegrity(
    Insertable<TipoProducto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tipo_producto')) {
      context.handle(
        _tipoProductoMeta,
        tipoProducto.isAcceptableOrUnknown(
          data['tipo_producto']!,
          _tipoProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tipoProductoMeta);
    }
    if (data.containsKey('nombre_tipo_producto')) {
      context.handle(
        _nombreTipoProductoMeta,
        nombreTipoProducto.isAcceptableOrUnknown(
          data['nombre_tipo_producto']!,
          _nombreTipoProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreTipoProductoMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tipoProducto};
  @override
  TipoProducto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TipoProducto(
      tipoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_producto'],
      )!,
      nombreTipoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_tipo_producto'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $TiposProductoTable createAlias(String alias) {
    return $TiposProductoTable(attachedDatabase, alias);
  }
}

class TipoProducto extends DataClass implements Insertable<TipoProducto> {
  final String tipoProducto;
  final String nombreTipoProducto;
  final bool activo;
  const TipoProducto({
    required this.tipoProducto,
    required this.nombreTipoProducto,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tipo_producto'] = Variable<String>(tipoProducto);
    map['nombre_tipo_producto'] = Variable<String>(nombreTipoProducto);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  TiposProductoCompanion toCompanion(bool nullToAbsent) {
    return TiposProductoCompanion(
      tipoProducto: Value(tipoProducto),
      nombreTipoProducto: Value(nombreTipoProducto),
      activo: Value(activo),
    );
  }

  factory TipoProducto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TipoProducto(
      tipoProducto: serializer.fromJson<String>(json['tipoProducto']),
      nombreTipoProducto: serializer.fromJson<String>(
        json['nombreTipoProducto'],
      ),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tipoProducto': serializer.toJson<String>(tipoProducto),
      'nombreTipoProducto': serializer.toJson<String>(nombreTipoProducto),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  TipoProducto copyWith({
    String? tipoProducto,
    String? nombreTipoProducto,
    bool? activo,
  }) => TipoProducto(
    tipoProducto: tipoProducto ?? this.tipoProducto,
    nombreTipoProducto: nombreTipoProducto ?? this.nombreTipoProducto,
    activo: activo ?? this.activo,
  );
  TipoProducto copyWithCompanion(TiposProductoCompanion data) {
    return TipoProducto(
      tipoProducto: data.tipoProducto.present
          ? data.tipoProducto.value
          : this.tipoProducto,
      nombreTipoProducto: data.nombreTipoProducto.present
          ? data.nombreTipoProducto.value
          : this.nombreTipoProducto,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TipoProducto(')
          ..write('tipoProducto: $tipoProducto, ')
          ..write('nombreTipoProducto: $nombreTipoProducto, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tipoProducto, nombreTipoProducto, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TipoProducto &&
          other.tipoProducto == this.tipoProducto &&
          other.nombreTipoProducto == this.nombreTipoProducto &&
          other.activo == this.activo);
}

class TiposProductoCompanion extends UpdateCompanion<TipoProducto> {
  final Value<String> tipoProducto;
  final Value<String> nombreTipoProducto;
  final Value<bool> activo;
  final Value<int> rowid;
  const TiposProductoCompanion({
    this.tipoProducto = const Value.absent(),
    this.nombreTipoProducto = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiposProductoCompanion.insert({
    required String tipoProducto,
    required String nombreTipoProducto,
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tipoProducto = Value(tipoProducto),
       nombreTipoProducto = Value(nombreTipoProducto);
  static Insertable<TipoProducto> custom({
    Expression<String>? tipoProducto,
    Expression<String>? nombreTipoProducto,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tipoProducto != null) 'tipo_producto': tipoProducto,
      if (nombreTipoProducto != null)
        'nombre_tipo_producto': nombreTipoProducto,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiposProductoCompanion copyWith({
    Value<String>? tipoProducto,
    Value<String>? nombreTipoProducto,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return TiposProductoCompanion(
      tipoProducto: tipoProducto ?? this.tipoProducto,
      nombreTipoProducto: nombreTipoProducto ?? this.nombreTipoProducto,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tipoProducto.present) {
      map['tipo_producto'] = Variable<String>(tipoProducto.value);
    }
    if (nombreTipoProducto.present) {
      map['nombre_tipo_producto'] = Variable<String>(nombreTipoProducto.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposProductoCompanion(')
          ..write('tipoProducto: $tipoProducto, ')
          ..write('nombreTipoProducto: $nombreTipoProducto, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, Producto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codLoteProductoMeta = const VerificationMeta(
    'codLoteProducto',
  );
  @override
  late final GeneratedColumn<String> codLoteProducto = GeneratedColumn<String>(
    'cod_lote_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreProductoMeta = const VerificationMeta(
    'nombreProducto',
  );
  @override
  late final GeneratedColumn<String> nombreProducto = GeneratedColumn<String>(
    'nombre_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoProductoMeta = const VerificationMeta(
    'tipoProducto',
  );
  @override
  late final GeneratedColumn<String> tipoProducto = GeneratedColumn<String>(
    'tipo_producto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tipos_producto (tipo_producto)',
    ),
  );
  static const VerificationMeta _precioUnitarioCentavosMeta =
      const VerificationMeta('precioUnitarioCentavos');
  @override
  late final GeneratedColumn<int> precioUnitarioCentavos = GeneratedColumn<int>(
    'precio_unitario_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaCreacionStockMeta =
      const VerificationMeta('fechaCreacionStock');
  @override
  late final GeneratedColumn<int> fechaCreacionStock = GeneratedColumn<int>(
    'fecha_creacion_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDisponibleMeta = const VerificationMeta(
    'totalDisponible',
  );
  @override
  late final GeneratedColumn<int> totalDisponible = GeneratedColumn<int>(
    'total_disponible',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalVendidosMeta = const VerificationMeta(
    'totalVendidos',
  );
  @override
  late final GeneratedColumn<int> totalVendidos = GeneratedColumn<int>(
    'total_vendidos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cierresVentaMeta = const VerificationMeta(
    'cierresVenta',
  );
  @override
  late final GeneratedColumn<int> cierresVenta = GeneratedColumn<int>(
    'cierres_venta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalVecesMostradoMeta =
      const VerificationMeta('totalVecesMostrado');
  @override
  late final GeneratedColumn<int> totalVecesMostrado = GeneratedColumn<int>(
    'total_veces_mostrado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codLoteProducto,
    nombreProducto,
    tipoProducto,
    precioUnitarioCentavos,
    fechaCreacionStock,
    totalDisponible,
    totalVendidos,
    cierresVenta,
    totalVecesMostrado,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Producto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_lote_producto')) {
      context.handle(
        _codLoteProductoMeta,
        codLoteProducto.isAcceptableOrUnknown(
          data['cod_lote_producto']!,
          _codLoteProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codLoteProductoMeta);
    }
    if (data.containsKey('nombre_producto')) {
      context.handle(
        _nombreProductoMeta,
        nombreProducto.isAcceptableOrUnknown(
          data['nombre_producto']!,
          _nombreProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreProductoMeta);
    }
    if (data.containsKey('tipo_producto')) {
      context.handle(
        _tipoProductoMeta,
        tipoProducto.isAcceptableOrUnknown(
          data['tipo_producto']!,
          _tipoProductoMeta,
        ),
      );
    }
    if (data.containsKey('precio_unitario_centavos')) {
      context.handle(
        _precioUnitarioCentavosMeta,
        precioUnitarioCentavos.isAcceptableOrUnknown(
          data['precio_unitario_centavos']!,
          _precioUnitarioCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioUnitarioCentavosMeta);
    }
    if (data.containsKey('fecha_creacion_stock')) {
      context.handle(
        _fechaCreacionStockMeta,
        fechaCreacionStock.isAcceptableOrUnknown(
          data['fecha_creacion_stock']!,
          _fechaCreacionStockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaCreacionStockMeta);
    }
    if (data.containsKey('total_disponible')) {
      context.handle(
        _totalDisponibleMeta,
        totalDisponible.isAcceptableOrUnknown(
          data['total_disponible']!,
          _totalDisponibleMeta,
        ),
      );
    }
    if (data.containsKey('total_vendidos')) {
      context.handle(
        _totalVendidosMeta,
        totalVendidos.isAcceptableOrUnknown(
          data['total_vendidos']!,
          _totalVendidosMeta,
        ),
      );
    }
    if (data.containsKey('cierres_venta')) {
      context.handle(
        _cierresVentaMeta,
        cierresVenta.isAcceptableOrUnknown(
          data['cierres_venta']!,
          _cierresVentaMeta,
        ),
      );
    }
    if (data.containsKey('total_veces_mostrado')) {
      context.handle(
        _totalVecesMostradoMeta,
        totalVecesMostrado.isAcceptableOrUnknown(
          data['total_veces_mostrado']!,
          _totalVecesMostradoMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codLoteProducto};
  @override
  Producto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Producto(
      codLoteProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_lote_producto'],
      )!,
      nombreProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_producto'],
      )!,
      tipoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_producto'],
      ),
      precioUnitarioCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_unitario_centavos'],
      )!,
      fechaCreacionStock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fecha_creacion_stock'],
      )!,
      totalDisponible: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_disponible'],
      )!,
      totalVendidos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_vendidos'],
      )!,
      cierresVenta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cierres_venta'],
      )!,
      totalVecesMostrado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_veces_mostrado'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }
}

class Producto extends DataClass implements Insertable<Producto> {
  final String codLoteProducto;
  final String nombreProducto;
  final String? tipoProducto;
  final int precioUnitarioCentavos;
  final int fechaCreacionStock;
  final int totalDisponible;
  final int totalVendidos;
  final int cierresVenta;
  final int totalVecesMostrado;
  final bool activo;
  const Producto({
    required this.codLoteProducto,
    required this.nombreProducto,
    this.tipoProducto,
    required this.precioUnitarioCentavos,
    required this.fechaCreacionStock,
    required this.totalDisponible,
    required this.totalVendidos,
    required this.cierresVenta,
    required this.totalVecesMostrado,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_lote_producto'] = Variable<String>(codLoteProducto);
    map['nombre_producto'] = Variable<String>(nombreProducto);
    if (!nullToAbsent || tipoProducto != null) {
      map['tipo_producto'] = Variable<String>(tipoProducto);
    }
    map['precio_unitario_centavos'] = Variable<int>(precioUnitarioCentavos);
    map['fecha_creacion_stock'] = Variable<int>(fechaCreacionStock);
    map['total_disponible'] = Variable<int>(totalDisponible);
    map['total_vendidos'] = Variable<int>(totalVendidos);
    map['cierres_venta'] = Variable<int>(cierresVenta);
    map['total_veces_mostrado'] = Variable<int>(totalVecesMostrado);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      codLoteProducto: Value(codLoteProducto),
      nombreProducto: Value(nombreProducto),
      tipoProducto: tipoProducto == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoProducto),
      precioUnitarioCentavos: Value(precioUnitarioCentavos),
      fechaCreacionStock: Value(fechaCreacionStock),
      totalDisponible: Value(totalDisponible),
      totalVendidos: Value(totalVendidos),
      cierresVenta: Value(cierresVenta),
      totalVecesMostrado: Value(totalVecesMostrado),
      activo: Value(activo),
    );
  }

  factory Producto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Producto(
      codLoteProducto: serializer.fromJson<String>(json['codLoteProducto']),
      nombreProducto: serializer.fromJson<String>(json['nombreProducto']),
      tipoProducto: serializer.fromJson<String?>(json['tipoProducto']),
      precioUnitarioCentavos: serializer.fromJson<int>(
        json['precioUnitarioCentavos'],
      ),
      fechaCreacionStock: serializer.fromJson<int>(json['fechaCreacionStock']),
      totalDisponible: serializer.fromJson<int>(json['totalDisponible']),
      totalVendidos: serializer.fromJson<int>(json['totalVendidos']),
      cierresVenta: serializer.fromJson<int>(json['cierresVenta']),
      totalVecesMostrado: serializer.fromJson<int>(json['totalVecesMostrado']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codLoteProducto': serializer.toJson<String>(codLoteProducto),
      'nombreProducto': serializer.toJson<String>(nombreProducto),
      'tipoProducto': serializer.toJson<String?>(tipoProducto),
      'precioUnitarioCentavos': serializer.toJson<int>(precioUnitarioCentavos),
      'fechaCreacionStock': serializer.toJson<int>(fechaCreacionStock),
      'totalDisponible': serializer.toJson<int>(totalDisponible),
      'totalVendidos': serializer.toJson<int>(totalVendidos),
      'cierresVenta': serializer.toJson<int>(cierresVenta),
      'totalVecesMostrado': serializer.toJson<int>(totalVecesMostrado),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  Producto copyWith({
    String? codLoteProducto,
    String? nombreProducto,
    Value<String?> tipoProducto = const Value.absent(),
    int? precioUnitarioCentavos,
    int? fechaCreacionStock,
    int? totalDisponible,
    int? totalVendidos,
    int? cierresVenta,
    int? totalVecesMostrado,
    bool? activo,
  }) => Producto(
    codLoteProducto: codLoteProducto ?? this.codLoteProducto,
    nombreProducto: nombreProducto ?? this.nombreProducto,
    tipoProducto: tipoProducto.present ? tipoProducto.value : this.tipoProducto,
    precioUnitarioCentavos:
        precioUnitarioCentavos ?? this.precioUnitarioCentavos,
    fechaCreacionStock: fechaCreacionStock ?? this.fechaCreacionStock,
    totalDisponible: totalDisponible ?? this.totalDisponible,
    totalVendidos: totalVendidos ?? this.totalVendidos,
    cierresVenta: cierresVenta ?? this.cierresVenta,
    totalVecesMostrado: totalVecesMostrado ?? this.totalVecesMostrado,
    activo: activo ?? this.activo,
  );
  Producto copyWithCompanion(ProductosCompanion data) {
    return Producto(
      codLoteProducto: data.codLoteProducto.present
          ? data.codLoteProducto.value
          : this.codLoteProducto,
      nombreProducto: data.nombreProducto.present
          ? data.nombreProducto.value
          : this.nombreProducto,
      tipoProducto: data.tipoProducto.present
          ? data.tipoProducto.value
          : this.tipoProducto,
      precioUnitarioCentavos: data.precioUnitarioCentavos.present
          ? data.precioUnitarioCentavos.value
          : this.precioUnitarioCentavos,
      fechaCreacionStock: data.fechaCreacionStock.present
          ? data.fechaCreacionStock.value
          : this.fechaCreacionStock,
      totalDisponible: data.totalDisponible.present
          ? data.totalDisponible.value
          : this.totalDisponible,
      totalVendidos: data.totalVendidos.present
          ? data.totalVendidos.value
          : this.totalVendidos,
      cierresVenta: data.cierresVenta.present
          ? data.cierresVenta.value
          : this.cierresVenta,
      totalVecesMostrado: data.totalVecesMostrado.present
          ? data.totalVecesMostrado.value
          : this.totalVecesMostrado,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Producto(')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('nombreProducto: $nombreProducto, ')
          ..write('tipoProducto: $tipoProducto, ')
          ..write('precioUnitarioCentavos: $precioUnitarioCentavos, ')
          ..write('fechaCreacionStock: $fechaCreacionStock, ')
          ..write('totalDisponible: $totalDisponible, ')
          ..write('totalVendidos: $totalVendidos, ')
          ..write('cierresVenta: $cierresVenta, ')
          ..write('totalVecesMostrado: $totalVecesMostrado, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    codLoteProducto,
    nombreProducto,
    tipoProducto,
    precioUnitarioCentavos,
    fechaCreacionStock,
    totalDisponible,
    totalVendidos,
    cierresVenta,
    totalVecesMostrado,
    activo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Producto &&
          other.codLoteProducto == this.codLoteProducto &&
          other.nombreProducto == this.nombreProducto &&
          other.tipoProducto == this.tipoProducto &&
          other.precioUnitarioCentavos == this.precioUnitarioCentavos &&
          other.fechaCreacionStock == this.fechaCreacionStock &&
          other.totalDisponible == this.totalDisponible &&
          other.totalVendidos == this.totalVendidos &&
          other.cierresVenta == this.cierresVenta &&
          other.totalVecesMostrado == this.totalVecesMostrado &&
          other.activo == this.activo);
}

class ProductosCompanion extends UpdateCompanion<Producto> {
  final Value<String> codLoteProducto;
  final Value<String> nombreProducto;
  final Value<String?> tipoProducto;
  final Value<int> precioUnitarioCentavos;
  final Value<int> fechaCreacionStock;
  final Value<int> totalDisponible;
  final Value<int> totalVendidos;
  final Value<int> cierresVenta;
  final Value<int> totalVecesMostrado;
  final Value<bool> activo;
  final Value<int> rowid;
  const ProductosCompanion({
    this.codLoteProducto = const Value.absent(),
    this.nombreProducto = const Value.absent(),
    this.tipoProducto = const Value.absent(),
    this.precioUnitarioCentavos = const Value.absent(),
    this.fechaCreacionStock = const Value.absent(),
    this.totalDisponible = const Value.absent(),
    this.totalVendidos = const Value.absent(),
    this.cierresVenta = const Value.absent(),
    this.totalVecesMostrado = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String codLoteProducto,
    required String nombreProducto,
    this.tipoProducto = const Value.absent(),
    required int precioUnitarioCentavos,
    required int fechaCreacionStock,
    this.totalDisponible = const Value.absent(),
    this.totalVendidos = const Value.absent(),
    this.cierresVenta = const Value.absent(),
    this.totalVecesMostrado = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codLoteProducto = Value(codLoteProducto),
       nombreProducto = Value(nombreProducto),
       precioUnitarioCentavos = Value(precioUnitarioCentavos),
       fechaCreacionStock = Value(fechaCreacionStock);
  static Insertable<Producto> custom({
    Expression<String>? codLoteProducto,
    Expression<String>? nombreProducto,
    Expression<String>? tipoProducto,
    Expression<int>? precioUnitarioCentavos,
    Expression<int>? fechaCreacionStock,
    Expression<int>? totalDisponible,
    Expression<int>? totalVendidos,
    Expression<int>? cierresVenta,
    Expression<int>? totalVecesMostrado,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codLoteProducto != null) 'cod_lote_producto': codLoteProducto,
      if (nombreProducto != null) 'nombre_producto': nombreProducto,
      if (tipoProducto != null) 'tipo_producto': tipoProducto,
      if (precioUnitarioCentavos != null)
        'precio_unitario_centavos': precioUnitarioCentavos,
      if (fechaCreacionStock != null)
        'fecha_creacion_stock': fechaCreacionStock,
      if (totalDisponible != null) 'total_disponible': totalDisponible,
      if (totalVendidos != null) 'total_vendidos': totalVendidos,
      if (cierresVenta != null) 'cierres_venta': cierresVenta,
      if (totalVecesMostrado != null)
        'total_veces_mostrado': totalVecesMostrado,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? codLoteProducto,
    Value<String>? nombreProducto,
    Value<String?>? tipoProducto,
    Value<int>? precioUnitarioCentavos,
    Value<int>? fechaCreacionStock,
    Value<int>? totalDisponible,
    Value<int>? totalVendidos,
    Value<int>? cierresVenta,
    Value<int>? totalVecesMostrado,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      codLoteProducto: codLoteProducto ?? this.codLoteProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      tipoProducto: tipoProducto ?? this.tipoProducto,
      precioUnitarioCentavos:
          precioUnitarioCentavos ?? this.precioUnitarioCentavos,
      fechaCreacionStock: fechaCreacionStock ?? this.fechaCreacionStock,
      totalDisponible: totalDisponible ?? this.totalDisponible,
      totalVendidos: totalVendidos ?? this.totalVendidos,
      cierresVenta: cierresVenta ?? this.cierresVenta,
      totalVecesMostrado: totalVecesMostrado ?? this.totalVecesMostrado,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codLoteProducto.present) {
      map['cod_lote_producto'] = Variable<String>(codLoteProducto.value);
    }
    if (nombreProducto.present) {
      map['nombre_producto'] = Variable<String>(nombreProducto.value);
    }
    if (tipoProducto.present) {
      map['tipo_producto'] = Variable<String>(tipoProducto.value);
    }
    if (precioUnitarioCentavos.present) {
      map['precio_unitario_centavos'] = Variable<int>(
        precioUnitarioCentavos.value,
      );
    }
    if (fechaCreacionStock.present) {
      map['fecha_creacion_stock'] = Variable<int>(fechaCreacionStock.value);
    }
    if (totalDisponible.present) {
      map['total_disponible'] = Variable<int>(totalDisponible.value);
    }
    if (totalVendidos.present) {
      map['total_vendidos'] = Variable<int>(totalVendidos.value);
    }
    if (cierresVenta.present) {
      map['cierres_venta'] = Variable<int>(cierresVenta.value);
    }
    if (totalVecesMostrado.present) {
      map['total_veces_mostrado'] = Variable<int>(totalVecesMostrado.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosCompanion(')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('nombreProducto: $nombreProducto, ')
          ..write('tipoProducto: $tipoProducto, ')
          ..write('precioUnitarioCentavos: $precioUnitarioCentavos, ')
          ..write('fechaCreacionStock: $fechaCreacionStock, ')
          ..write('totalDisponible: $totalDisponible, ')
          ..write('totalVendidos: $totalVendidos, ')
          ..write('cierresVenta: $cierresVenta, ')
          ..write('totalVecesMostrado: $totalVecesMostrado, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DetalleVentaTable extends DetalleVenta
    with TableInfo<$DetalleVentaTable, DetalleVentaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetalleVentaTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ventaIdMeta = const VerificationMeta(
    'ventaId',
  );
  @override
  late final GeneratedColumn<int> ventaId = GeneratedColumn<int>(
    'venta_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ventas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _codLoteProductoMeta = const VerificationMeta(
    'codLoteProducto',
  );
  @override
  late final GeneratedColumn<String> codLoteProducto = GeneratedColumn<String>(
    'cod_lote_producto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (cod_lote_producto)',
    ),
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioUnitarioCentavosMeta =
      const VerificationMeta('precioUnitarioCentavos');
  @override
  late final GeneratedColumn<int> precioUnitarioCentavos = GeneratedColumn<int>(
    'precio_unitario_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ventaId,
    codLoteProducto,
    cantidad,
    precioUnitarioCentavos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detalle_venta';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetalleVentaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('venta_id')) {
      context.handle(
        _ventaIdMeta,
        ventaId.isAcceptableOrUnknown(data['venta_id']!, _ventaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ventaIdMeta);
    }
    if (data.containsKey('cod_lote_producto')) {
      context.handle(
        _codLoteProductoMeta,
        codLoteProducto.isAcceptableOrUnknown(
          data['cod_lote_producto']!,
          _codLoteProductoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codLoteProductoMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('precio_unitario_centavos')) {
      context.handle(
        _precioUnitarioCentavosMeta,
        precioUnitarioCentavos.isAcceptableOrUnknown(
          data['precio_unitario_centavos']!,
          _precioUnitarioCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioUnitarioCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetalleVentaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetalleVentaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ventaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}venta_id'],
      )!,
      codLoteProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_lote_producto'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cantidad'],
      )!,
      precioUnitarioCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_unitario_centavos'],
      )!,
    );
  }

  @override
  $DetalleVentaTable createAlias(String alias) {
    return $DetalleVentaTable(attachedDatabase, alias);
  }
}

class DetalleVentaData extends DataClass
    implements Insertable<DetalleVentaData> {
  final int id;
  final int ventaId;
  final String codLoteProducto;
  final int cantidad;
  final int precioUnitarioCentavos;
  const DetalleVentaData({
    required this.id,
    required this.ventaId,
    required this.codLoteProducto,
    required this.cantidad,
    required this.precioUnitarioCentavos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['venta_id'] = Variable<int>(ventaId);
    map['cod_lote_producto'] = Variable<String>(codLoteProducto);
    map['cantidad'] = Variable<int>(cantidad);
    map['precio_unitario_centavos'] = Variable<int>(precioUnitarioCentavos);
    return map;
  }

  DetalleVentaCompanion toCompanion(bool nullToAbsent) {
    return DetalleVentaCompanion(
      id: Value(id),
      ventaId: Value(ventaId),
      codLoteProducto: Value(codLoteProducto),
      cantidad: Value(cantidad),
      precioUnitarioCentavos: Value(precioUnitarioCentavos),
    );
  }

  factory DetalleVentaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetalleVentaData(
      id: serializer.fromJson<int>(json['id']),
      ventaId: serializer.fromJson<int>(json['ventaId']),
      codLoteProducto: serializer.fromJson<String>(json['codLoteProducto']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      precioUnitarioCentavos: serializer.fromJson<int>(
        json['precioUnitarioCentavos'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ventaId': serializer.toJson<int>(ventaId),
      'codLoteProducto': serializer.toJson<String>(codLoteProducto),
      'cantidad': serializer.toJson<int>(cantidad),
      'precioUnitarioCentavos': serializer.toJson<int>(precioUnitarioCentavos),
    };
  }

  DetalleVentaData copyWith({
    int? id,
    int? ventaId,
    String? codLoteProducto,
    int? cantidad,
    int? precioUnitarioCentavos,
  }) => DetalleVentaData(
    id: id ?? this.id,
    ventaId: ventaId ?? this.ventaId,
    codLoteProducto: codLoteProducto ?? this.codLoteProducto,
    cantidad: cantidad ?? this.cantidad,
    precioUnitarioCentavos:
        precioUnitarioCentavos ?? this.precioUnitarioCentavos,
  );
  DetalleVentaData copyWithCompanion(DetalleVentaCompanion data) {
    return DetalleVentaData(
      id: data.id.present ? data.id.value : this.id,
      ventaId: data.ventaId.present ? data.ventaId.value : this.ventaId,
      codLoteProducto: data.codLoteProducto.present
          ? data.codLoteProducto.value
          : this.codLoteProducto,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      precioUnitarioCentavos: data.precioUnitarioCentavos.present
          ? data.precioUnitarioCentavos.value
          : this.precioUnitarioCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetalleVentaData(')
          ..write('id: $id, ')
          ..write('ventaId: $ventaId, ')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitarioCentavos: $precioUnitarioCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ventaId,
    codLoteProducto,
    cantidad,
    precioUnitarioCentavos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetalleVentaData &&
          other.id == this.id &&
          other.ventaId == this.ventaId &&
          other.codLoteProducto == this.codLoteProducto &&
          other.cantidad == this.cantidad &&
          other.precioUnitarioCentavos == this.precioUnitarioCentavos);
}

class DetalleVentaCompanion extends UpdateCompanion<DetalleVentaData> {
  final Value<int> id;
  final Value<int> ventaId;
  final Value<String> codLoteProducto;
  final Value<int> cantidad;
  final Value<int> precioUnitarioCentavos;
  const DetalleVentaCompanion({
    this.id = const Value.absent(),
    this.ventaId = const Value.absent(),
    this.codLoteProducto = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.precioUnitarioCentavos = const Value.absent(),
  });
  DetalleVentaCompanion.insert({
    this.id = const Value.absent(),
    required int ventaId,
    required String codLoteProducto,
    required int cantidad,
    required int precioUnitarioCentavos,
  }) : ventaId = Value(ventaId),
       codLoteProducto = Value(codLoteProducto),
       cantidad = Value(cantidad),
       precioUnitarioCentavos = Value(precioUnitarioCentavos);
  static Insertable<DetalleVentaData> custom({
    Expression<int>? id,
    Expression<int>? ventaId,
    Expression<String>? codLoteProducto,
    Expression<int>? cantidad,
    Expression<int>? precioUnitarioCentavos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ventaId != null) 'venta_id': ventaId,
      if (codLoteProducto != null) 'cod_lote_producto': codLoteProducto,
      if (cantidad != null) 'cantidad': cantidad,
      if (precioUnitarioCentavos != null)
        'precio_unitario_centavos': precioUnitarioCentavos,
    });
  }

  DetalleVentaCompanion copyWith({
    Value<int>? id,
    Value<int>? ventaId,
    Value<String>? codLoteProducto,
    Value<int>? cantidad,
    Value<int>? precioUnitarioCentavos,
  }) {
    return DetalleVentaCompanion(
      id: id ?? this.id,
      ventaId: ventaId ?? this.ventaId,
      codLoteProducto: codLoteProducto ?? this.codLoteProducto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitarioCentavos:
          precioUnitarioCentavos ?? this.precioUnitarioCentavos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ventaId.present) {
      map['venta_id'] = Variable<int>(ventaId.value);
    }
    if (codLoteProducto.present) {
      map['cod_lote_producto'] = Variable<String>(codLoteProducto.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (precioUnitarioCentavos.present) {
      map['precio_unitario_centavos'] = Variable<int>(
        precioUnitarioCentavos.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetalleVentaCompanion(')
          ..write('id: $id, ')
          ..write('ventaId: $ventaId, ')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitarioCentavos: $precioUnitarioCentavos')
          ..write(')'))
        .toString();
  }
}

class VCierresPorTipoProductoData extends DataClass {
  final String? tipoProducto;
  final String? nombreTipoProducto;
  final String codCliente;
  final String cliente;
  final String codLoteProducto;
  final String nombreProducto;
  final int cantidad;
  final int importeCentavos;
  final String? codEstrategia;
  final String? nombreEstrategia;
  final int timestamp;
  const VCierresPorTipoProductoData({
    this.tipoProducto,
    this.nombreTipoProducto,
    required this.codCliente,
    required this.cliente,
    required this.codLoteProducto,
    required this.nombreProducto,
    required this.cantidad,
    required this.importeCentavos,
    this.codEstrategia,
    this.nombreEstrategia,
    required this.timestamp,
  });
  factory VCierresPorTipoProductoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VCierresPorTipoProductoData(
      tipoProducto: serializer.fromJson<String?>(json['tipoProducto']),
      nombreTipoProducto: serializer.fromJson<String?>(
        json['nombreTipoProducto'],
      ),
      codCliente: serializer.fromJson<String>(json['codCliente']),
      cliente: serializer.fromJson<String>(json['cliente']),
      codLoteProducto: serializer.fromJson<String>(json['codLoteProducto']),
      nombreProducto: serializer.fromJson<String>(json['nombreProducto']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      importeCentavos: serializer.fromJson<int>(json['importeCentavos']),
      codEstrategia: serializer.fromJson<String?>(json['codEstrategia']),
      nombreEstrategia: serializer.fromJson<String?>(json['nombreEstrategia']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tipoProducto': serializer.toJson<String?>(tipoProducto),
      'nombreTipoProducto': serializer.toJson<String?>(nombreTipoProducto),
      'codCliente': serializer.toJson<String>(codCliente),
      'cliente': serializer.toJson<String>(cliente),
      'codLoteProducto': serializer.toJson<String>(codLoteProducto),
      'nombreProducto': serializer.toJson<String>(nombreProducto),
      'cantidad': serializer.toJson<int>(cantidad),
      'importeCentavos': serializer.toJson<int>(importeCentavos),
      'codEstrategia': serializer.toJson<String?>(codEstrategia),
      'nombreEstrategia': serializer.toJson<String?>(nombreEstrategia),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  VCierresPorTipoProductoData copyWith({
    Value<String?> tipoProducto = const Value.absent(),
    Value<String?> nombreTipoProducto = const Value.absent(),
    String? codCliente,
    String? cliente,
    String? codLoteProducto,
    String? nombreProducto,
    int? cantidad,
    int? importeCentavos,
    Value<String?> codEstrategia = const Value.absent(),
    Value<String?> nombreEstrategia = const Value.absent(),
    int? timestamp,
  }) => VCierresPorTipoProductoData(
    tipoProducto: tipoProducto.present ? tipoProducto.value : this.tipoProducto,
    nombreTipoProducto: nombreTipoProducto.present
        ? nombreTipoProducto.value
        : this.nombreTipoProducto,
    codCliente: codCliente ?? this.codCliente,
    cliente: cliente ?? this.cliente,
    codLoteProducto: codLoteProducto ?? this.codLoteProducto,
    nombreProducto: nombreProducto ?? this.nombreProducto,
    cantidad: cantidad ?? this.cantidad,
    importeCentavos: importeCentavos ?? this.importeCentavos,
    codEstrategia: codEstrategia.present
        ? codEstrategia.value
        : this.codEstrategia,
    nombreEstrategia: nombreEstrategia.present
        ? nombreEstrategia.value
        : this.nombreEstrategia,
    timestamp: timestamp ?? this.timestamp,
  );
  @override
  String toString() {
    return (StringBuffer('VCierresPorTipoProductoData(')
          ..write('tipoProducto: $tipoProducto, ')
          ..write('nombreTipoProducto: $nombreTipoProducto, ')
          ..write('codCliente: $codCliente, ')
          ..write('cliente: $cliente, ')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('nombreProducto: $nombreProducto, ')
          ..write('cantidad: $cantidad, ')
          ..write('importeCentavos: $importeCentavos, ')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('nombreEstrategia: $nombreEstrategia, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tipoProducto,
    nombreTipoProducto,
    codCliente,
    cliente,
    codLoteProducto,
    nombreProducto,
    cantidad,
    importeCentavos,
    codEstrategia,
    nombreEstrategia,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VCierresPorTipoProductoData &&
          other.tipoProducto == this.tipoProducto &&
          other.nombreTipoProducto == this.nombreTipoProducto &&
          other.codCliente == this.codCliente &&
          other.cliente == this.cliente &&
          other.codLoteProducto == this.codLoteProducto &&
          other.nombreProducto == this.nombreProducto &&
          other.cantidad == this.cantidad &&
          other.importeCentavos == this.importeCentavos &&
          other.codEstrategia == this.codEstrategia &&
          other.nombreEstrategia == this.nombreEstrategia &&
          other.timestamp == this.timestamp);
}

class VCierresPorTipoProducto
    extends ViewInfo<VCierresPorTipoProducto, VCierresPorTipoProductoData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  VCierresPorTipoProducto(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    tipoProducto,
    nombreTipoProducto,
    codCliente,
    cliente,
    codLoteProducto,
    nombreProducto,
    cantidad,
    importeCentavos,
    codEstrategia,
    nombreEstrategia,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'v_cierres_por_tipo_producto';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW v_cierres_por_tipo_producto AS SELECT p.tipo_producto AS tipoProducto, tp.nombre_tipo_producto AS nombreTipoProducto, c.cod_cliente AS codCliente, c.nombre || \' \' || c.apellido AS cliente, p.cod_lote_producto AS codLoteProducto, p.nombre_producto AS nombreProducto, d.cantidad AS cantidad, d.precio_unitario_centavos * d.cantidad AS importeCentavos, e.cod_estrategia AS codEstrategia, e.nombre_estrategia AS nombreEstrategia, v.timestamp AS timestamp FROM detalle_venta AS d INNER JOIN ventas AS v ON v.id = d.venta_id INNER JOIN productos AS p ON p.cod_lote_producto = d.cod_lote_producto LEFT JOIN tipos_producto AS tp ON tp.tipo_producto = p.tipo_producto INNER JOIN clientes AS c ON c.cod_cliente = v.cod_cliente LEFT JOIN estrategias AS e ON e.cod_estrategia = v.cod_estrategia',
  };
  @override
  VCierresPorTipoProducto get asDslTable => this;
  @override
  VCierresPorTipoProductoData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VCierresPorTipoProductoData(
      tipoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipoProducto'],
      ),
      nombreTipoProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombreTipoProducto'],
      ),
      codCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codCliente'],
      )!,
      cliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente'],
      )!,
      codLoteProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codLoteProducto'],
      )!,
      nombreProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombreProducto'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cantidad'],
      )!,
      importeCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importeCentavos'],
      )!,
      codEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codEstrategia'],
      ),
      nombreEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombreEstrategia'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  late final GeneratedColumn<String> tipoProducto = GeneratedColumn<String>(
    'tipoProducto',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> nombreTipoProducto =
      GeneratedColumn<String>(
        'nombreTipoProducto',
        aliasedName,
        true,
        type: DriftSqlType.string,
      );
  late final GeneratedColumn<String> codCliente = GeneratedColumn<String>(
    'codCliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> cliente = GeneratedColumn<String>(
    'cliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> codLoteProducto = GeneratedColumn<String>(
    'codLoteProducto',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> nombreProducto = GeneratedColumn<String>(
    'nombreProducto',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> importeCentavos = GeneratedColumn<int>(
    'importeCentavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> codEstrategia = GeneratedColumn<String>(
    'codEstrategia',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> nombreEstrategia = GeneratedColumn<String>(
    'nombreEstrategia',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  @override
  VCierresPorTipoProducto createAlias(String alias) {
    return VCierresPorTipoProducto(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'detalle_venta',
    'ventas',
    'productos',
    'tipos_producto',
    'clientes',
    'estrategias',
    'tipos_cliente',
    'tipos_transaccion',
  };
}

class $GestosTable extends Gestos with TableInfo<$GestosTable, Gesto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GestosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codGestoMeta = const VerificationMeta(
    'codGesto',
  );
  @override
  late final GeneratedColumn<String> codGesto = GeneratedColumn<String>(
    'cod_gesto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreGestoMeta = const VerificationMeta(
    'nombreGesto',
  );
  @override
  late final GeneratedColumn<String> nombreGesto = GeneratedColumn<String>(
    'nombre_gesto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codGesto,
    nombreGesto,
    descripcion,
    activo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gestos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Gesto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cod_gesto')) {
      context.handle(
        _codGestoMeta,
        codGesto.isAcceptableOrUnknown(data['cod_gesto']!, _codGestoMeta),
      );
    } else if (isInserting) {
      context.missing(_codGestoMeta);
    }
    if (data.containsKey('nombre_gesto')) {
      context.handle(
        _nombreGestoMeta,
        nombreGesto.isAcceptableOrUnknown(
          data['nombre_gesto']!,
          _nombreGestoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreGestoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codGesto};
  @override
  Gesto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Gesto(
      codGesto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_gesto'],
      )!,
      nombreGesto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_gesto'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
    );
  }

  @override
  $GestosTable createAlias(String alias) {
    return $GestosTable(attachedDatabase, alias);
  }
}

class Gesto extends DataClass implements Insertable<Gesto> {
  final String codGesto;
  final String nombreGesto;
  final String? descripcion;
  final bool activo;
  const Gesto({
    required this.codGesto,
    required this.nombreGesto,
    this.descripcion,
    required this.activo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cod_gesto'] = Variable<String>(codGesto);
    map['nombre_gesto'] = Variable<String>(nombreGesto);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  GestosCompanion toCompanion(bool nullToAbsent) {
    return GestosCompanion(
      codGesto: Value(codGesto),
      nombreGesto: Value(nombreGesto),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      activo: Value(activo),
    );
  }

  factory Gesto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Gesto(
      codGesto: serializer.fromJson<String>(json['codGesto']),
      nombreGesto: serializer.fromJson<String>(json['nombreGesto']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codGesto': serializer.toJson<String>(codGesto),
      'nombreGesto': serializer.toJson<String>(nombreGesto),
      'descripcion': serializer.toJson<String?>(descripcion),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  Gesto copyWith({
    String? codGesto,
    String? nombreGesto,
    Value<String?> descripcion = const Value.absent(),
    bool? activo,
  }) => Gesto(
    codGesto: codGesto ?? this.codGesto,
    nombreGesto: nombreGesto ?? this.nombreGesto,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    activo: activo ?? this.activo,
  );
  Gesto copyWithCompanion(GestosCompanion data) {
    return Gesto(
      codGesto: data.codGesto.present ? data.codGesto.value : this.codGesto,
      nombreGesto: data.nombreGesto.present
          ? data.nombreGesto.value
          : this.nombreGesto,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Gesto(')
          ..write('codGesto: $codGesto, ')
          ..write('nombreGesto: $nombreGesto, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(codGesto, nombreGesto, descripcion, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Gesto &&
          other.codGesto == this.codGesto &&
          other.nombreGesto == this.nombreGesto &&
          other.descripcion == this.descripcion &&
          other.activo == this.activo);
}

class GestosCompanion extends UpdateCompanion<Gesto> {
  final Value<String> codGesto;
  final Value<String> nombreGesto;
  final Value<String?> descripcion;
  final Value<bool> activo;
  final Value<int> rowid;
  const GestosCompanion({
    this.codGesto = const Value.absent(),
    this.nombreGesto = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GestosCompanion.insert({
    required String codGesto,
    required String nombreGesto,
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codGesto = Value(codGesto),
       nombreGesto = Value(nombreGesto);
  static Insertable<Gesto> custom({
    Expression<String>? codGesto,
    Expression<String>? nombreGesto,
    Expression<String>? descripcion,
    Expression<bool>? activo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codGesto != null) 'cod_gesto': codGesto,
      if (nombreGesto != null) 'nombre_gesto': nombreGesto,
      if (descripcion != null) 'descripcion': descripcion,
      if (activo != null) 'activo': activo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GestosCompanion copyWith({
    Value<String>? codGesto,
    Value<String>? nombreGesto,
    Value<String?>? descripcion,
    Value<bool>? activo,
    Value<int>? rowid,
  }) {
    return GestosCompanion(
      codGesto: codGesto ?? this.codGesto,
      nombreGesto: nombreGesto ?? this.nombreGesto,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codGesto.present) {
      map['cod_gesto'] = Variable<String>(codGesto.value);
    }
    if (nombreGesto.present) {
      map['nombre_gesto'] = Variable<String>(nombreGesto.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GestosCompanion(')
          ..write('codGesto: $codGesto, ')
          ..write('nombreGesto: $nombreGesto, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InteraccionesTable extends Interacciones
    with TableInfo<$InteraccionesTable, Interaccion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InteraccionesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _canalMeta = const VerificationMeta('canal');
  @override
  late final GeneratedColumn<String> canal = GeneratedColumn<String>(
    'canal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correlativoMeta = const VerificationMeta(
    'correlativo',
  );
  @override
  late final GeneratedColumn<int> correlativo = GeneratedColumn<int>(
    'correlativo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idProcesoPersuasionMeta =
      const VerificationMeta('idProcesoPersuasion');
  @override
  late final GeneratedColumn<String> idProcesoPersuasion =
      GeneratedColumn<String>(
        'id_proceso_persuasion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _codClienteMeta = const VerificationMeta(
    'codCliente',
  );
  @override
  late final GeneratedColumn<String> codCliente = GeneratedColumn<String>(
    'cod_cliente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clientes (cod_cliente)',
    ),
  );
  static const VerificationMeta _codEstrategiaMeta = const VerificationMeta(
    'codEstrategia',
  );
  @override
  late final GeneratedColumn<String> codEstrategia = GeneratedColumn<String>(
    'cod_estrategia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES estrategias (cod_estrategia)',
    ),
  );
  static const VerificationMeta _codGestoMeta = const VerificationMeta(
    'codGesto',
  );
  @override
  late final GeneratedColumn<String> codGesto = GeneratedColumn<String>(
    'cod_gesto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gestos (cod_gesto)',
    ),
  );
  static const VerificationMeta _codLoteProductoMeta = const VerificationMeta(
    'codLoteProducto',
  );
  @override
  late final GeneratedColumn<String> codLoteProducto = GeneratedColumn<String>(
    'cod_lote_producto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (cod_lote_producto)',
    ),
  );
  static const VerificationMeta _tipoTransaccionMeta = const VerificationMeta(
    'tipoTransaccion',
  );
  @override
  late final GeneratedColumn<String> tipoTransaccion = GeneratedColumn<String>(
    'tipo_transaccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tipos_transaccion (cod_transaccion)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nivelDeInteresMeta = const VerificationMeta(
    'nivelDeInteres',
  );
  @override
  late final GeneratedColumn<int> nivelDeInteres = GeneratedColumn<int>(
    'nivel_de_interes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canal,
    correlativo,
    idProcesoPersuasion,
    codCliente,
    codEstrategia,
    codGesto,
    codLoteProducto,
    tipoTransaccion,
    timestamp,
    nivelDeInteres,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interacciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Interaccion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('canal')) {
      context.handle(
        _canalMeta,
        canal.isAcceptableOrUnknown(data['canal']!, _canalMeta),
      );
    } else if (isInserting) {
      context.missing(_canalMeta);
    }
    if (data.containsKey('correlativo')) {
      context.handle(
        _correlativoMeta,
        correlativo.isAcceptableOrUnknown(
          data['correlativo']!,
          _correlativoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correlativoMeta);
    }
    if (data.containsKey('id_proceso_persuasion')) {
      context.handle(
        _idProcesoPersuasionMeta,
        idProcesoPersuasion.isAcceptableOrUnknown(
          data['id_proceso_persuasion']!,
          _idProcesoPersuasionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idProcesoPersuasionMeta);
    }
    if (data.containsKey('cod_cliente')) {
      context.handle(
        _codClienteMeta,
        codCliente.isAcceptableOrUnknown(data['cod_cliente']!, _codClienteMeta),
      );
    } else if (isInserting) {
      context.missing(_codClienteMeta);
    }
    if (data.containsKey('cod_estrategia')) {
      context.handle(
        _codEstrategiaMeta,
        codEstrategia.isAcceptableOrUnknown(
          data['cod_estrategia']!,
          _codEstrategiaMeta,
        ),
      );
    }
    if (data.containsKey('cod_gesto')) {
      context.handle(
        _codGestoMeta,
        codGesto.isAcceptableOrUnknown(data['cod_gesto']!, _codGestoMeta),
      );
    }
    if (data.containsKey('cod_lote_producto')) {
      context.handle(
        _codLoteProductoMeta,
        codLoteProducto.isAcceptableOrUnknown(
          data['cod_lote_producto']!,
          _codLoteProductoMeta,
        ),
      );
    }
    if (data.containsKey('tipo_transaccion')) {
      context.handle(
        _tipoTransaccionMeta,
        tipoTransaccion.isAcceptableOrUnknown(
          data['tipo_transaccion']!,
          _tipoTransaccionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tipoTransaccionMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('nivel_de_interes')) {
      context.handle(
        _nivelDeInteresMeta,
        nivelDeInteres.isAcceptableOrUnknown(
          data['nivel_de_interes']!,
          _nivelDeInteresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nivelDeInteresMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Interaccion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Interaccion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      canal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canal'],
      )!,
      correlativo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correlativo'],
      )!,
      idProcesoPersuasion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_proceso_persuasion'],
      )!,
      codCliente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_cliente'],
      )!,
      codEstrategia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_estrategia'],
      ),
      codGesto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_gesto'],
      ),
      codLoteProducto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cod_lote_producto'],
      ),
      tipoTransaccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_transaccion'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      nivelDeInteres: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nivel_de_interes'],
      )!,
    );
  }

  @override
  $InteraccionesTable createAlias(String alias) {
    return $InteraccionesTable(attachedDatabase, alias);
  }
}

class Interaccion extends DataClass implements Insertable<Interaccion> {
  final int id;
  final String canal;
  final int correlativo;
  final String idProcesoPersuasion;
  final String codCliente;
  final String? codEstrategia;
  final String? codGesto;
  final String? codLoteProducto;
  final String tipoTransaccion;
  final int timestamp;
  final int nivelDeInteres;
  const Interaccion({
    required this.id,
    required this.canal,
    required this.correlativo,
    required this.idProcesoPersuasion,
    required this.codCliente,
    this.codEstrategia,
    this.codGesto,
    this.codLoteProducto,
    required this.tipoTransaccion,
    required this.timestamp,
    required this.nivelDeInteres,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['canal'] = Variable<String>(canal);
    map['correlativo'] = Variable<int>(correlativo);
    map['id_proceso_persuasion'] = Variable<String>(idProcesoPersuasion);
    map['cod_cliente'] = Variable<String>(codCliente);
    if (!nullToAbsent || codEstrategia != null) {
      map['cod_estrategia'] = Variable<String>(codEstrategia);
    }
    if (!nullToAbsent || codGesto != null) {
      map['cod_gesto'] = Variable<String>(codGesto);
    }
    if (!nullToAbsent || codLoteProducto != null) {
      map['cod_lote_producto'] = Variable<String>(codLoteProducto);
    }
    map['tipo_transaccion'] = Variable<String>(tipoTransaccion);
    map['timestamp'] = Variable<int>(timestamp);
    map['nivel_de_interes'] = Variable<int>(nivelDeInteres);
    return map;
  }

  InteraccionesCompanion toCompanion(bool nullToAbsent) {
    return InteraccionesCompanion(
      id: Value(id),
      canal: Value(canal),
      correlativo: Value(correlativo),
      idProcesoPersuasion: Value(idProcesoPersuasion),
      codCliente: Value(codCliente),
      codEstrategia: codEstrategia == null && nullToAbsent
          ? const Value.absent()
          : Value(codEstrategia),
      codGesto: codGesto == null && nullToAbsent
          ? const Value.absent()
          : Value(codGesto),
      codLoteProducto: codLoteProducto == null && nullToAbsent
          ? const Value.absent()
          : Value(codLoteProducto),
      tipoTransaccion: Value(tipoTransaccion),
      timestamp: Value(timestamp),
      nivelDeInteres: Value(nivelDeInteres),
    );
  }

  factory Interaccion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Interaccion(
      id: serializer.fromJson<int>(json['id']),
      canal: serializer.fromJson<String>(json['canal']),
      correlativo: serializer.fromJson<int>(json['correlativo']),
      idProcesoPersuasion: serializer.fromJson<String>(
        json['idProcesoPersuasion'],
      ),
      codCliente: serializer.fromJson<String>(json['codCliente']),
      codEstrategia: serializer.fromJson<String?>(json['codEstrategia']),
      codGesto: serializer.fromJson<String?>(json['codGesto']),
      codLoteProducto: serializer.fromJson<String?>(json['codLoteProducto']),
      tipoTransaccion: serializer.fromJson<String>(json['tipoTransaccion']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      nivelDeInteres: serializer.fromJson<int>(json['nivelDeInteres']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'canal': serializer.toJson<String>(canal),
      'correlativo': serializer.toJson<int>(correlativo),
      'idProcesoPersuasion': serializer.toJson<String>(idProcesoPersuasion),
      'codCliente': serializer.toJson<String>(codCliente),
      'codEstrategia': serializer.toJson<String?>(codEstrategia),
      'codGesto': serializer.toJson<String?>(codGesto),
      'codLoteProducto': serializer.toJson<String?>(codLoteProducto),
      'tipoTransaccion': serializer.toJson<String>(tipoTransaccion),
      'timestamp': serializer.toJson<int>(timestamp),
      'nivelDeInteres': serializer.toJson<int>(nivelDeInteres),
    };
  }

  Interaccion copyWith({
    int? id,
    String? canal,
    int? correlativo,
    String? idProcesoPersuasion,
    String? codCliente,
    Value<String?> codEstrategia = const Value.absent(),
    Value<String?> codGesto = const Value.absent(),
    Value<String?> codLoteProducto = const Value.absent(),
    String? tipoTransaccion,
    int? timestamp,
    int? nivelDeInteres,
  }) => Interaccion(
    id: id ?? this.id,
    canal: canal ?? this.canal,
    correlativo: correlativo ?? this.correlativo,
    idProcesoPersuasion: idProcesoPersuasion ?? this.idProcesoPersuasion,
    codCliente: codCliente ?? this.codCliente,
    codEstrategia: codEstrategia.present
        ? codEstrategia.value
        : this.codEstrategia,
    codGesto: codGesto.present ? codGesto.value : this.codGesto,
    codLoteProducto: codLoteProducto.present
        ? codLoteProducto.value
        : this.codLoteProducto,
    tipoTransaccion: tipoTransaccion ?? this.tipoTransaccion,
    timestamp: timestamp ?? this.timestamp,
    nivelDeInteres: nivelDeInteres ?? this.nivelDeInteres,
  );
  Interaccion copyWithCompanion(InteraccionesCompanion data) {
    return Interaccion(
      id: data.id.present ? data.id.value : this.id,
      canal: data.canal.present ? data.canal.value : this.canal,
      correlativo: data.correlativo.present
          ? data.correlativo.value
          : this.correlativo,
      idProcesoPersuasion: data.idProcesoPersuasion.present
          ? data.idProcesoPersuasion.value
          : this.idProcesoPersuasion,
      codCliente: data.codCliente.present
          ? data.codCliente.value
          : this.codCliente,
      codEstrategia: data.codEstrategia.present
          ? data.codEstrategia.value
          : this.codEstrategia,
      codGesto: data.codGesto.present ? data.codGesto.value : this.codGesto,
      codLoteProducto: data.codLoteProducto.present
          ? data.codLoteProducto.value
          : this.codLoteProducto,
      tipoTransaccion: data.tipoTransaccion.present
          ? data.tipoTransaccion.value
          : this.tipoTransaccion,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      nivelDeInteres: data.nivelDeInteres.present
          ? data.nivelDeInteres.value
          : this.nivelDeInteres,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Interaccion(')
          ..write('id: $id, ')
          ..write('canal: $canal, ')
          ..write('correlativo: $correlativo, ')
          ..write('idProcesoPersuasion: $idProcesoPersuasion, ')
          ..write('codCliente: $codCliente, ')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('codGesto: $codGesto, ')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('tipoTransaccion: $tipoTransaccion, ')
          ..write('timestamp: $timestamp, ')
          ..write('nivelDeInteres: $nivelDeInteres')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canal,
    correlativo,
    idProcesoPersuasion,
    codCliente,
    codEstrategia,
    codGesto,
    codLoteProducto,
    tipoTransaccion,
    timestamp,
    nivelDeInteres,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Interaccion &&
          other.id == this.id &&
          other.canal == this.canal &&
          other.correlativo == this.correlativo &&
          other.idProcesoPersuasion == this.idProcesoPersuasion &&
          other.codCliente == this.codCliente &&
          other.codEstrategia == this.codEstrategia &&
          other.codGesto == this.codGesto &&
          other.codLoteProducto == this.codLoteProducto &&
          other.tipoTransaccion == this.tipoTransaccion &&
          other.timestamp == this.timestamp &&
          other.nivelDeInteres == this.nivelDeInteres);
}

class InteraccionesCompanion extends UpdateCompanion<Interaccion> {
  final Value<int> id;
  final Value<String> canal;
  final Value<int> correlativo;
  final Value<String> idProcesoPersuasion;
  final Value<String> codCliente;
  final Value<String?> codEstrategia;
  final Value<String?> codGesto;
  final Value<String?> codLoteProducto;
  final Value<String> tipoTransaccion;
  final Value<int> timestamp;
  final Value<int> nivelDeInteres;
  const InteraccionesCompanion({
    this.id = const Value.absent(),
    this.canal = const Value.absent(),
    this.correlativo = const Value.absent(),
    this.idProcesoPersuasion = const Value.absent(),
    this.codCliente = const Value.absent(),
    this.codEstrategia = const Value.absent(),
    this.codGesto = const Value.absent(),
    this.codLoteProducto = const Value.absent(),
    this.tipoTransaccion = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.nivelDeInteres = const Value.absent(),
  });
  InteraccionesCompanion.insert({
    this.id = const Value.absent(),
    required String canal,
    required int correlativo,
    required String idProcesoPersuasion,
    required String codCliente,
    this.codEstrategia = const Value.absent(),
    this.codGesto = const Value.absent(),
    this.codLoteProducto = const Value.absent(),
    required String tipoTransaccion,
    required int timestamp,
    required int nivelDeInteres,
  }) : canal = Value(canal),
       correlativo = Value(correlativo),
       idProcesoPersuasion = Value(idProcesoPersuasion),
       codCliente = Value(codCliente),
       tipoTransaccion = Value(tipoTransaccion),
       timestamp = Value(timestamp),
       nivelDeInteres = Value(nivelDeInteres);
  static Insertable<Interaccion> custom({
    Expression<int>? id,
    Expression<String>? canal,
    Expression<int>? correlativo,
    Expression<String>? idProcesoPersuasion,
    Expression<String>? codCliente,
    Expression<String>? codEstrategia,
    Expression<String>? codGesto,
    Expression<String>? codLoteProducto,
    Expression<String>? tipoTransaccion,
    Expression<int>? timestamp,
    Expression<int>? nivelDeInteres,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canal != null) 'canal': canal,
      if (correlativo != null) 'correlativo': correlativo,
      if (idProcesoPersuasion != null)
        'id_proceso_persuasion': idProcesoPersuasion,
      if (codCliente != null) 'cod_cliente': codCliente,
      if (codEstrategia != null) 'cod_estrategia': codEstrategia,
      if (codGesto != null) 'cod_gesto': codGesto,
      if (codLoteProducto != null) 'cod_lote_producto': codLoteProducto,
      if (tipoTransaccion != null) 'tipo_transaccion': tipoTransaccion,
      if (timestamp != null) 'timestamp': timestamp,
      if (nivelDeInteres != null) 'nivel_de_interes': nivelDeInteres,
    });
  }

  InteraccionesCompanion copyWith({
    Value<int>? id,
    Value<String>? canal,
    Value<int>? correlativo,
    Value<String>? idProcesoPersuasion,
    Value<String>? codCliente,
    Value<String?>? codEstrategia,
    Value<String?>? codGesto,
    Value<String?>? codLoteProducto,
    Value<String>? tipoTransaccion,
    Value<int>? timestamp,
    Value<int>? nivelDeInteres,
  }) {
    return InteraccionesCompanion(
      id: id ?? this.id,
      canal: canal ?? this.canal,
      correlativo: correlativo ?? this.correlativo,
      idProcesoPersuasion: idProcesoPersuasion ?? this.idProcesoPersuasion,
      codCliente: codCliente ?? this.codCliente,
      codEstrategia: codEstrategia ?? this.codEstrategia,
      codGesto: codGesto ?? this.codGesto,
      codLoteProducto: codLoteProducto ?? this.codLoteProducto,
      tipoTransaccion: tipoTransaccion ?? this.tipoTransaccion,
      timestamp: timestamp ?? this.timestamp,
      nivelDeInteres: nivelDeInteres ?? this.nivelDeInteres,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (canal.present) {
      map['canal'] = Variable<String>(canal.value);
    }
    if (correlativo.present) {
      map['correlativo'] = Variable<int>(correlativo.value);
    }
    if (idProcesoPersuasion.present) {
      map['id_proceso_persuasion'] = Variable<String>(
        idProcesoPersuasion.value,
      );
    }
    if (codCliente.present) {
      map['cod_cliente'] = Variable<String>(codCliente.value);
    }
    if (codEstrategia.present) {
      map['cod_estrategia'] = Variable<String>(codEstrategia.value);
    }
    if (codGesto.present) {
      map['cod_gesto'] = Variable<String>(codGesto.value);
    }
    if (codLoteProducto.present) {
      map['cod_lote_producto'] = Variable<String>(codLoteProducto.value);
    }
    if (tipoTransaccion.present) {
      map['tipo_transaccion'] = Variable<String>(tipoTransaccion.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (nivelDeInteres.present) {
      map['nivel_de_interes'] = Variable<int>(nivelDeInteres.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InteraccionesCompanion(')
          ..write('id: $id, ')
          ..write('canal: $canal, ')
          ..write('correlativo: $correlativo, ')
          ..write('idProcesoPersuasion: $idProcesoPersuasion, ')
          ..write('codCliente: $codCliente, ')
          ..write('codEstrategia: $codEstrategia, ')
          ..write('codGesto: $codGesto, ')
          ..write('codLoteProducto: $codLoteProducto, ')
          ..write('tipoTransaccion: $tipoTransaccion, ')
          ..write('timestamp: $timestamp, ')
          ..write('nivelDeInteres: $nivelDeInteres')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TiposClienteTable tiposCliente = $TiposClienteTable(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  late final $EstrategiasTable estrategias = $EstrategiasTable(this);
  late final $TiposTransaccionTable tiposTransaccion = $TiposTransaccionTable(
    this,
  );
  late final $VentasTable ventas = $VentasTable(this);
  late final $TiposProductoTable tiposProducto = $TiposProductoTable(this);
  late final $ProductosTable productos = $ProductosTable(this);
  late final $DetalleVentaTable detalleVenta = $DetalleVentaTable(this);
  late final VCierresPorTipoProducto vCierresPorTipoProducto =
      VCierresPorTipoProducto(this);
  late final $GestosTable gestos = $GestosTable(this);
  late final $InteraccionesTable interacciones = $InteraccionesTable(this);
  late final Index idxClientesTipo = Index(
    'idx_clientes_tipo',
    'CREATE INDEX idx_clientes_tipo ON clientes (tipo_cliente)',
  );
  late final Index idxProductosTipo = Index(
    'idx_productos_tipo',
    'CREATE INDEX idx_productos_tipo ON productos (tipo_producto)',
  );
  late final Index idxInteraccionesProceso = Index(
    'idx_interacciones_proceso',
    'CREATE INDEX idx_interacciones_proceso ON interacciones (id_proceso_persuasion)',
  );
  late final Index idxInteraccionesCliente = Index(
    'idx_interacciones_cliente',
    'CREATE INDEX idx_interacciones_cliente ON interacciones (cod_cliente)',
  );
  late final Index idxInteraccionesEstrategia = Index(
    'idx_interacciones_estrategia',
    'CREATE INDEX idx_interacciones_estrategia ON interacciones (cod_estrategia)',
  );
  late final Index idxInteraccionesTimestamp = Index(
    'idx_interacciones_timestamp',
    'CREATE INDEX idx_interacciones_timestamp ON interacciones (timestamp)',
  );
  late final Index idxVentasProceso = Index(
    'idx_ventas_proceso',
    'CREATE INDEX idx_ventas_proceso ON ventas (id_proceso_persuasion)',
  );
  late final Index idxVentasCliente = Index(
    'idx_ventas_cliente',
    'CREATE INDEX idx_ventas_cliente ON ventas (cod_cliente)',
  );
  late final Index idxVentasEstrategia = Index(
    'idx_ventas_estrategia',
    'CREATE INDEX idx_ventas_estrategia ON ventas (cod_estrategia)',
  );
  late final Index idxVentasTimestamp = Index(
    'idx_ventas_timestamp',
    'CREATE INDEX idx_ventas_timestamp ON ventas (timestamp)',
  );
  late final Index idxDetalleProducto = Index(
    'idx_detalle_producto',
    'CREATE INDEX idx_detalle_producto ON detalle_venta (cod_lote_producto)',
  );
  Selectable<Kpi1CierreVentasPorMesResult> kpi1CierreVentasPorMes() {
    return customSelect(
      'WITH intentos AS (SELECT strftime(\'%Y-%m\', timestamp / 1000, \'unixepoch\') AS mes, COUNT(DISTINCT id_proceso_persuasion) AS n FROM interacciones GROUP BY mes), cierres AS (SELECT strftime(\'%Y-%m\', timestamp / 1000, \'unixepoch\') AS mes, COUNT(DISTINCT id_proceso_persuasion) AS n FROM ventas GROUP BY mes) SELECT i.mes AS mes, COALESCE(c.n, 0) AS cierres, i.n AS intentos, ROUND(100.0 * COALESCE(c.n, 0) / i.n, 2) AS porcentaje FROM intentos AS i LEFT JOIN cierres AS c ON c.mes = i.mes ORDER BY i.mes',
      variables: [],
      readsFrom: {this.interacciones, this.ventas},
    ).map(
      (QueryRow row) => Kpi1CierreVentasPorMesResult(
        mes: row.read<String>('mes'),
        cierres: row.read<int>('cierres'),
        intentos: row.read<int>('intentos'),
        porcentaje: row.read<double>('porcentaje'),
      ),
    );
  }

  Selectable<double> kpi2VentasSinProductoAlternativo() {
    return customSelect(
      'WITH productos_por_proceso AS (SELECT id_proceso_persuasion AS pid, COUNT(DISTINCT cod_lote_producto) AS n_prod FROM interacciones WHERE cod_lote_producto IS NOT NULL GROUP BY id_proceso_persuasion) SELECT ROUND(100.0 * SUM(CASE WHEN p.n_prod = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS porcentaje FROM productos_por_proceso AS p WHERE p.pid IN (SELECT DISTINCT id_proceso_persuasion FROM ventas)',
      variables: [],
      readsFrom: {this.interacciones, this.ventas},
    ).map((QueryRow row) => row.read<double>('porcentaje'));
  }

  Selectable<Kpi3EfectividadEstrategiaPorTipoClienteResult>
  kpi3EfectividadEstrategiaPorTipoCliente() {
    return customSelect(
      'SELECT cl.tipo_cliente AS tipoCliente, e.cod_estrategia AS codEstrategia, e.nombre_estrategia AS nombreEstrategia, COUNT(DISTINCT v.id_proceso_persuasion) AS ventasGeneradas, COUNT(DISTINCT i.id_proceso_persuasion) AS vecesAplicada, ROUND(100.0 * COUNT(DISTINCT v.id_proceso_persuasion) / NULLIF(COUNT(DISTINCT i.id_proceso_persuasion), 0), 2) AS efectividad FROM interacciones AS i JOIN clientes AS cl ON cl.cod_cliente = i.cod_cliente JOIN estrategias AS e ON e.cod_estrategia = i.cod_estrategia LEFT JOIN ventas AS v ON v.id_proceso_persuasion = i.id_proceso_persuasion AND v.cod_estrategia = i.cod_estrategia GROUP BY cl.tipo_cliente, e.cod_estrategia ORDER BY cl.tipo_cliente, efectividad DESC',
      variables: [],
      readsFrom: {
        this.clientes,
        this.estrategias,
        this.ventas,
        this.interacciones,
      },
    ).map(
      (QueryRow row) => Kpi3EfectividadEstrategiaPorTipoClienteResult(
        tipoCliente: row.readNullable<String>('tipoCliente'),
        codEstrategia: row.read<String>('codEstrategia'),
        nombreEstrategia: row.read<String>('nombreEstrategia'),
        ventasGeneradas: row.read<int>('ventasGeneradas'),
        vecesAplicada: row.read<int>('vecesAplicada'),
        efectividad: row.read<double>('efectividad'),
      ),
    );
  }

  Selectable<Kpi4VentasPorDiaSemanaResult> kpi4VentasPorDiaSemana() {
    return customSelect(
      'SELECT CAST(strftime(\'%w\', timestamp / 1000, \'unixepoch\') AS INTEGER) AS diaSemana, COUNT(*) AS ventas, ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ventas), 2) AS porcentaje FROM ventas GROUP BY diaSemana ORDER BY diaSemana',
      variables: [],
      readsFrom: {this.ventas},
    ).map(
      (QueryRow row) => Kpi4VentasPorDiaSemanaResult(
        diaSemana: row.read<int>('diaSemana'),
        ventas: row.read<int>('ventas'),
        porcentaje: row.read<double>('porcentaje'),
      ),
    );
  }

  Future<int> batchActualizarTotalVecesAplicada() {
    return customUpdate(
      'UPDATE estrategias SET total_veces_aplicada = (SELECT COUNT(*) FROM interacciones AS i WHERE i.cod_estrategia = estrategias.cod_estrategia)',
      variables: [],
      updates: {this.estrategias},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> batchActualizarVentasGeneradas() {
    return customUpdate(
      'UPDATE estrategias SET ventas_generadas = (SELECT COUNT(*) FROM ventas AS v WHERE v.cod_estrategia = estrategias.cod_estrategia)',
      variables: [],
      updates: {this.estrategias},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> batchActualizarCantLecturas() {
    return customUpdate(
      'UPDATE clientes SET cant_lecturas = (SELECT COUNT(DISTINCT i.id_proceso_persuasion) FROM interacciones AS i WHERE i.cod_cliente = clientes.cod_cliente)',
      variables: [],
      updates: {this.clientes},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> batchActualizarTotalesCliente() {
    return customUpdate(
      'UPDATE clientes SET total_compras = (SELECT COUNT(*) FROM ventas AS v WHERE v.cod_cliente = clientes.cod_cliente), monto_total_centavos = (SELECT COALESCE(SUM(d.cantidad * d.precio_unitario_centavos), 0) FROM ventas AS v JOIN detalle_venta AS d ON d.venta_id = v.id WHERE v.cod_cliente = clientes.cod_cliente), ultima_visita = (SELECT MAX(v.timestamp) FROM ventas AS v WHERE v.cod_cliente = clientes.cod_cliente)',
      variables: [],
      updates: {this.clientes},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> batchActualizarCierresVenta() {
    return customUpdate(
      'UPDATE productos SET cierres_venta = (SELECT COUNT(*) FROM detalle_venta AS d WHERE d.cod_lote_producto = productos.cod_lote_producto)',
      variables: [],
      updates: {this.productos},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> batchActualizarTotalVendidos() {
    return customUpdate(
      'UPDATE productos SET total_vendidos = (SELECT COUNT(*) FROM detalle_venta AS d WHERE d.cod_lote_producto = productos.cod_lote_producto)',
      variables: [],
      updates: {this.productos},
      updateKind: UpdateKind.update,
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tiposCliente,
    clientes,
    estrategias,
    tiposTransaccion,
    ventas,
    tiposProducto,
    productos,
    detalleVenta,
    vCierresPorTipoProducto,
    gestos,
    interacciones,
    idxClientesTipo,
    idxProductosTipo,
    idxInteraccionesProceso,
    idxInteraccionesCliente,
    idxInteraccionesEstrategia,
    idxInteraccionesTimestamp,
    idxVentasProceso,
    idxVentasCliente,
    idxVentasEstrategia,
    idxVentasTimestamp,
    idxDetalleProducto,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ventas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('detalle_venta', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TiposClienteTableCreateCompanionBuilder =
    TiposClienteCompanion Function({
      required String codTipoCliente,
      required String nombreTipoCliente,
      Value<bool> activo,
      Value<int> rowid,
    });
typedef $$TiposClienteTableUpdateCompanionBuilder =
    TiposClienteCompanion Function({
      Value<String> codTipoCliente,
      Value<String> nombreTipoCliente,
      Value<bool> activo,
      Value<int> rowid,
    });

final class $$TiposClienteTableReferences
    extends BaseReferences<_$AppDatabase, $TiposClienteTable, TipoCliente> {
  $$TiposClienteTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClientesTable, List<Cliente>> _clientesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.clientes,
    aliasName: 'tipos_cliente__cod_tipo_cliente__clientes__tipo_cliente',
  );

  $$ClientesTableProcessedTableManager get clientesRefs {
    final manager = $$ClientesTableTableManager($_db, $_db.clientes).filter(
      (f) => f.tipoCliente.codTipoCliente.sqlEquals(
        $_itemColumn<String>('cod_tipo_cliente')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_clientesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TiposClienteTableFilterComposer
    extends Composer<_$AppDatabase, $TiposClienteTable> {
  $$TiposClienteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codTipoCliente => $composableBuilder(
    column: $table.codTipoCliente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreTipoCliente => $composableBuilder(
    column: $table.nombreTipoCliente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> clientesRefs(
    Expression<bool> Function($$ClientesTableFilterComposer f) f,
  ) {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTipoCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.tipoCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableFilterComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposClienteTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposClienteTable> {
  $$TiposClienteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codTipoCliente => $composableBuilder(
    column: $table.codTipoCliente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreTipoCliente => $composableBuilder(
    column: $table.nombreTipoCliente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiposClienteTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposClienteTable> {
  $$TiposClienteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codTipoCliente => $composableBuilder(
    column: $table.codTipoCliente,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreTipoCliente => $composableBuilder(
    column: $table.nombreTipoCliente,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  Expression<T> clientesRefs<T extends Object>(
    Expression<T> Function($$ClientesTableAnnotationComposer a) f,
  ) {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTipoCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.tipoCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableAnnotationComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposClienteTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiposClienteTable,
          TipoCliente,
          $$TiposClienteTableFilterComposer,
          $$TiposClienteTableOrderingComposer,
          $$TiposClienteTableAnnotationComposer,
          $$TiposClienteTableCreateCompanionBuilder,
          $$TiposClienteTableUpdateCompanionBuilder,
          (TipoCliente, $$TiposClienteTableReferences),
          TipoCliente,
          PrefetchHooks Function({bool clientesRefs})
        > {
  $$TiposClienteTableTableManager(_$AppDatabase db, $TiposClienteTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposClienteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiposClienteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiposClienteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codTipoCliente = const Value.absent(),
                Value<String> nombreTipoCliente = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposClienteCompanion(
                codTipoCliente: codTipoCliente,
                nombreTipoCliente: nombreTipoCliente,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codTipoCliente,
                required String nombreTipoCliente,
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposClienteCompanion.insert(
                codTipoCliente: codTipoCliente,
                nombreTipoCliente: nombreTipoCliente,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TiposClienteTable, TipoCliente>(table),
                  $$TiposClienteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({clientesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (clientesRefs) db.clientes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clientesRefs)
                    await $_getPrefetchedData<
                      TipoCliente,
                      $TiposClienteTable,
                      Cliente
                    >(
                      currentTable: table,
                      referencedTable: $$TiposClienteTableReferences
                          ._clientesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TiposClienteTableReferences(
                            db,
                            table,
                            p0,
                          ).clientesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.tipoCliente == item.codTipoCliente,
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

typedef $$TiposClienteTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiposClienteTable,
      TipoCliente,
      $$TiposClienteTableFilterComposer,
      $$TiposClienteTableOrderingComposer,
      $$TiposClienteTableAnnotationComposer,
      $$TiposClienteTableCreateCompanionBuilder,
      $$TiposClienteTableUpdateCompanionBuilder,
      (TipoCliente, $$TiposClienteTableReferences),
      TipoCliente,
      PrefetchHooks Function({bool clientesRefs})
    >;
typedef $$ClientesTableCreateCompanionBuilder = ClientesCompanion Function({
  required String codCliente,
  required String nombre,
  required String apellido,
  Value<String?> tipoCliente,
  required int fechaIngreso,
  Value<int> cantLecturas,
  Value<int> totalCompras,
  Value<int> montoTotalCentavos,
  Value<int?> ultimaVisita,
  Value<bool> activo,
  Value<int> rowid,
});
typedef $$ClientesTableUpdateCompanionBuilder = ClientesCompanion Function({
  Value<String> codCliente,
  Value<String> nombre,
  Value<String> apellido,
  Value<String?> tipoCliente,
  Value<int> fechaIngreso,
  Value<int> cantLecturas,
  Value<int> totalCompras,
  Value<int> montoTotalCentavos,
  Value<int?> ultimaVisita,
  Value<bool> activo,
  Value<int> rowid,
});

final class $$ClientesTableReferences
    extends BaseReferences<_$AppDatabase, $ClientesTable, Cliente> {
  $$ClientesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TiposClienteTable _tipoClienteTable(_$AppDatabase db) => db
      .tiposCliente
      .createAlias('clientes__tipo_cliente__tipos_cliente__cod_tipo_cliente');

  $$TiposClienteTableProcessedTableManager? get tipoCliente {
    final $_column = $_itemColumn<String>('tipo_cliente');
    if ($_column == null) return null;
    final manager = $$TiposClienteTableTableManager(
      $_db,
      $_db.tiposCliente,
    ).filter((f) => f.codTipoCliente.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoClienteTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VentasTable, List<Venta>> _ventasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ventas,
    aliasName: 'clientes__cod_cliente__ventas__cod_cliente',
  );

  $$VentasTableProcessedTableManager get ventasRefs {
    final manager = $$VentasTableTableManager($_db, $_db.ventas).filter(
      (f) => f.codCliente.codCliente.sqlEquals(
        $_itemColumn<String>('cod_cliente')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_ventasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InteraccionesTable, List<Interaccion>>
  _interaccionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.interacciones,
    aliasName: 'clientes__cod_cliente__interacciones__cod_cliente',
  );

  $$InteraccionesTableProcessedTableManager get interaccionesRefs {
    final manager = $$InteraccionesTableTableManager($_db, $_db.interacciones)
        .filter(
          (f) => f.codCliente.codCliente.sqlEquals(
            $_itemColumn<String>('cod_cliente')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_interaccionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClientesTableFilterComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codCliente => $composableBuilder(
    column: $table.codCliente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apellido => $composableBuilder(
    column: $table.apellido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fechaIngreso => $composableBuilder(
    column: $table.fechaIngreso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantLecturas => $composableBuilder(
    column: $table.cantLecturas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCompras => $composableBuilder(
    column: $table.totalCompras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montoTotalCentavos => $composableBuilder(
    column: $table.montoTotalCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ultimaVisita => $composableBuilder(
    column: $table.ultimaVisita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  $$TiposClienteTableFilterComposer get tipoCliente {
    final $$TiposClienteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoCliente,
      referencedTable: $db.tiposCliente,
      getReferencedColumn: (t) => t.codTipoCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposClienteTableFilterComposer(
            $db: $db,
            $table: $db.tiposCliente,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ventasRefs(
    Expression<bool> Function($$VentasTableFilterComposer f) f,
  ) {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interaccionesRefs(
    Expression<bool> Function($$InteraccionesTableFilterComposer f) f,
  ) {
    final $$InteraccionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableFilterComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codCliente => $composableBuilder(
    column: $table.codCliente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apellido => $composableBuilder(
    column: $table.apellido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fechaIngreso => $composableBuilder(
    column: $table.fechaIngreso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantLecturas => $composableBuilder(
    column: $table.cantLecturas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCompras => $composableBuilder(
    column: $table.totalCompras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montoTotalCentavos => $composableBuilder(
    column: $table.montoTotalCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ultimaVisita => $composableBuilder(
    column: $table.ultimaVisita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  $$TiposClienteTableOrderingComposer get tipoCliente {
    final $$TiposClienteTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoCliente,
      referencedTable: $db.tiposCliente,
      getReferencedColumn: (t) => t.codTipoCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposClienteTableOrderingComposer(
            $db: $db,
            $table: $db.tiposCliente,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClientesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codCliente => $composableBuilder(
    column: $table.codCliente,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get apellido =>
      $composableBuilder(column: $table.apellido, builder: (column) => column);

  GeneratedColumn<int> get fechaIngreso => $composableBuilder(
    column: $table.fechaIngreso,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cantLecturas => $composableBuilder(
    column: $table.cantLecturas,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCompras => $composableBuilder(
    column: $table.totalCompras,
    builder: (column) => column,
  );

  GeneratedColumn<int> get montoTotalCentavos => $composableBuilder(
    column: $table.montoTotalCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ultimaVisita => $composableBuilder(
    column: $table.ultimaVisita,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  $$TiposClienteTableAnnotationComposer get tipoCliente {
    final $$TiposClienteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoCliente,
      referencedTable: $db.tiposCliente,
      getReferencedColumn: (t) => t.codTipoCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposClienteTableAnnotationComposer(
            $db: $db,
            $table: $db.tiposCliente,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ventasRefs<T extends Object>(
    Expression<T> Function($$VentasTableAnnotationComposer a) f,
  ) {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> interaccionesRefs<T extends Object>(
    Expression<T> Function($$InteraccionesTableAnnotationComposer a) f,
  ) {
    final $$InteraccionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableAnnotationComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientesTable,
          Cliente,
          $$ClientesTableFilterComposer,
          $$ClientesTableOrderingComposer,
          $$ClientesTableAnnotationComposer,
          $$ClientesTableCreateCompanionBuilder,
          $$ClientesTableUpdateCompanionBuilder,
          (Cliente, $$ClientesTableReferences),
          Cliente,
          PrefetchHooks Function({
            bool tipoCliente,
            bool ventasRefs,
            bool interaccionesRefs,
          })
        > {
  $$ClientesTableTableManager(_$AppDatabase db, $ClientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codCliente = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> apellido = const Value.absent(),
                Value<String?> tipoCliente = const Value.absent(),
                Value<int> fechaIngreso = const Value.absent(),
                Value<int> cantLecturas = const Value.absent(),
                Value<int> totalCompras = const Value.absent(),
                Value<int> montoTotalCentavos = const Value.absent(),
                Value<int?> ultimaVisita = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientesCompanion(
                codCliente: codCliente,
                nombre: nombre,
                apellido: apellido,
                tipoCliente: tipoCliente,
                fechaIngreso: fechaIngreso,
                cantLecturas: cantLecturas,
                totalCompras: totalCompras,
                montoTotalCentavos: montoTotalCentavos,
                ultimaVisita: ultimaVisita,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codCliente,
                required String nombre,
                required String apellido,
                Value<String?> tipoCliente = const Value.absent(),
                required int fechaIngreso,
                Value<int> cantLecturas = const Value.absent(),
                Value<int> totalCompras = const Value.absent(),
                Value<int> montoTotalCentavos = const Value.absent(),
                Value<int?> ultimaVisita = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientesCompanion.insert(
                codCliente: codCliente,
                nombre: nombre,
                apellido: apellido,
                tipoCliente: tipoCliente,
                fechaIngreso: fechaIngreso,
                cantLecturas: cantLecturas,
                totalCompras: totalCompras,
                montoTotalCentavos: montoTotalCentavos,
                ultimaVisita: ultimaVisita,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClientesTable, Cliente>(table),
                  $$ClientesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tipoCliente = false,
                ventasRefs = false,
                interaccionesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ventasRefs) db.ventas,
                    if (interaccionesRefs) db.interacciones,
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
                        if (tipoCliente) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoCliente,
                            referencedTable: $$ClientesTableReferences
                                ._tipoClienteTable(db),
                            referencedColumn: $$ClientesTableReferences
                                ._tipoClienteTable(db)
                                .codTipoCliente,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ventasRefs)
                        await $_getPrefetchedData<
                          Cliente,
                          $ClientesTable,
                          Venta
                        >(
                          currentTable: table,
                          referencedTable: $$ClientesTableReferences
                              ._ventasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientesTableReferences(
                                db,
                                table,
                                p0,
                              ).ventasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.codCliente == item.codCliente,
                              ),
                          typedResults: items,
                        ),
                      if (interaccionesRefs)
                        await $_getPrefetchedData<
                          Cliente,
                          $ClientesTable,
                          Interaccion
                        >(
                          currentTable: table,
                          referencedTable: $$ClientesTableReferences
                              ._interaccionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientesTableReferences(
                                db,
                                table,
                                p0,
                              ).interaccionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.codCliente == item.codCliente,
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

typedef $$ClientesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientesTable,
      Cliente,
      $$ClientesTableFilterComposer,
      $$ClientesTableOrderingComposer,
      $$ClientesTableAnnotationComposer,
      $$ClientesTableCreateCompanionBuilder,
      $$ClientesTableUpdateCompanionBuilder,
      (Cliente, $$ClientesTableReferences),
      Cliente,
      PrefetchHooks Function({
        bool tipoCliente,
        bool ventasRefs,
        bool interaccionesRefs,
      })
    >;
typedef $$EstrategiasTableCreateCompanionBuilder =
    EstrategiasCompanion Function({
      required String codEstrategia,
      required String nombreEstrategia,
      Value<int> totalVecesAplicada,
      Value<int> ventasGeneradas,
      Value<bool> activo,
      Value<int> rowid,
    });
typedef $$EstrategiasTableUpdateCompanionBuilder =
    EstrategiasCompanion Function({
      Value<String> codEstrategia,
      Value<String> nombreEstrategia,
      Value<int> totalVecesAplicada,
      Value<int> ventasGeneradas,
      Value<bool> activo,
      Value<int> rowid,
    });

final class $$EstrategiasTableReferences
    extends BaseReferences<_$AppDatabase, $EstrategiasTable, Estrategia> {
  $$EstrategiasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VentasTable, List<Venta>> _ventasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ventas,
    aliasName: 'estrategias__cod_estrategia__ventas__cod_estrategia',
  );

  $$VentasTableProcessedTableManager get ventasRefs {
    final manager = $$VentasTableTableManager($_db, $_db.ventas).filter(
      (f) => f.codEstrategia.codEstrategia.sqlEquals(
        $_itemColumn<String>('cod_estrategia')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_ventasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InteraccionesTable, List<Interaccion>>
  _interaccionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.interacciones,
    aliasName: 'estrategias__cod_estrategia__interacciones__cod_estrategia',
  );

  $$InteraccionesTableProcessedTableManager get interaccionesRefs {
    final manager = $$InteraccionesTableTableManager($_db, $_db.interacciones)
        .filter(
          (f) => f.codEstrategia.codEstrategia.sqlEquals(
            $_itemColumn<String>('cod_estrategia')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_interaccionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EstrategiasTableFilterComposer
    extends Composer<_$AppDatabase, $EstrategiasTable> {
  $$EstrategiasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codEstrategia => $composableBuilder(
    column: $table.codEstrategia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreEstrategia => $composableBuilder(
    column: $table.nombreEstrategia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVecesAplicada => $composableBuilder(
    column: $table.totalVecesAplicada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ventasGeneradas => $composableBuilder(
    column: $table.ventasGeneradas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ventasRefs(
    Expression<bool> Function($$VentasTableFilterComposer f) f,
  ) {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interaccionesRefs(
    Expression<bool> Function($$InteraccionesTableFilterComposer f) f,
  ) {
    final $$InteraccionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableFilterComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EstrategiasTableOrderingComposer
    extends Composer<_$AppDatabase, $EstrategiasTable> {
  $$EstrategiasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codEstrategia => $composableBuilder(
    column: $table.codEstrategia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreEstrategia => $composableBuilder(
    column: $table.nombreEstrategia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVecesAplicada => $composableBuilder(
    column: $table.totalVecesAplicada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ventasGeneradas => $composableBuilder(
    column: $table.ventasGeneradas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstrategiasTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstrategiasTable> {
  $$EstrategiasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codEstrategia => $composableBuilder(
    column: $table.codEstrategia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreEstrategia => $composableBuilder(
    column: $table.nombreEstrategia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVecesAplicada => $composableBuilder(
    column: $table.totalVecesAplicada,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ventasGeneradas => $composableBuilder(
    column: $table.ventasGeneradas,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  Expression<T> ventasRefs<T extends Object>(
    Expression<T> Function($$VentasTableAnnotationComposer a) f,
  ) {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> interaccionesRefs<T extends Object>(
    Expression<T> Function($$InteraccionesTableAnnotationComposer a) f,
  ) {
    final $$InteraccionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableAnnotationComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EstrategiasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EstrategiasTable,
          Estrategia,
          $$EstrategiasTableFilterComposer,
          $$EstrategiasTableOrderingComposer,
          $$EstrategiasTableAnnotationComposer,
          $$EstrategiasTableCreateCompanionBuilder,
          $$EstrategiasTableUpdateCompanionBuilder,
          (Estrategia, $$EstrategiasTableReferences),
          Estrategia,
          PrefetchHooks Function({bool ventasRefs, bool interaccionesRefs})
        > {
  $$EstrategiasTableTableManager(_$AppDatabase db, $EstrategiasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstrategiasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstrategiasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstrategiasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codEstrategia = const Value.absent(),
                Value<String> nombreEstrategia = const Value.absent(),
                Value<int> totalVecesAplicada = const Value.absent(),
                Value<int> ventasGeneradas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstrategiasCompanion(
                codEstrategia: codEstrategia,
                nombreEstrategia: nombreEstrategia,
                totalVecesAplicada: totalVecesAplicada,
                ventasGeneradas: ventasGeneradas,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codEstrategia,
                required String nombreEstrategia,
                Value<int> totalVecesAplicada = const Value.absent(),
                Value<int> ventasGeneradas = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstrategiasCompanion.insert(
                codEstrategia: codEstrategia,
                nombreEstrategia: nombreEstrategia,
                totalVecesAplicada: totalVecesAplicada,
                ventasGeneradas: ventasGeneradas,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EstrategiasTable, Estrategia>(table),
                  $$EstrategiasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ventasRefs = false, interaccionesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ventasRefs) db.ventas,
                    if (interaccionesRefs) db.interacciones,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ventasRefs)
                        await $_getPrefetchedData<
                          Estrategia,
                          $EstrategiasTable,
                          Venta
                        >(
                          currentTable: table,
                          referencedTable: $$EstrategiasTableReferences
                              ._ventasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EstrategiasTableReferences(
                                db,
                                table,
                                p0,
                              ).ventasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.codEstrategia == item.codEstrategia,
                              ),
                          typedResults: items,
                        ),
                      if (interaccionesRefs)
                        await $_getPrefetchedData<
                          Estrategia,
                          $EstrategiasTable,
                          Interaccion
                        >(
                          currentTable: table,
                          referencedTable: $$EstrategiasTableReferences
                              ._interaccionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EstrategiasTableReferences(
                                db,
                                table,
                                p0,
                              ).interaccionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.codEstrategia == item.codEstrategia,
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

typedef $$EstrategiasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EstrategiasTable,
      Estrategia,
      $$EstrategiasTableFilterComposer,
      $$EstrategiasTableOrderingComposer,
      $$EstrategiasTableAnnotationComposer,
      $$EstrategiasTableCreateCompanionBuilder,
      $$EstrategiasTableUpdateCompanionBuilder,
      (Estrategia, $$EstrategiasTableReferences),
      Estrategia,
      PrefetchHooks Function({bool ventasRefs, bool interaccionesRefs})
    >;
typedef $$TiposTransaccionTableCreateCompanionBuilder =
    TiposTransaccionCompanion Function({
      required String codTransaccion,
      required String tipoTrx,
      Value<String?> codProtocolo,
      Value<bool> activo,
      Value<int> rowid,
    });
typedef $$TiposTransaccionTableUpdateCompanionBuilder =
    TiposTransaccionCompanion Function({
      Value<String> codTransaccion,
      Value<String> tipoTrx,
      Value<String?> codProtocolo,
      Value<bool> activo,
      Value<int> rowid,
    });

final class $$TiposTransaccionTableReferences
    extends
        BaseReferences<_$AppDatabase, $TiposTransaccionTable, TipoTransaccion> {
  $$TiposTransaccionTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$VentasTable, List<Venta>> _ventasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ventas,
    aliasName: 'tipos_transaccion__cod_transaccion__ventas__tipo_transaccion',
  );

  $$VentasTableProcessedTableManager get ventasRefs {
    final manager = $$VentasTableTableManager($_db, $_db.ventas).filter(
      (f) => f.tipoTransaccion.codTransaccion.sqlEquals(
        $_itemColumn<String>('cod_transaccion')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_ventasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InteraccionesTable, List<Interaccion>>
  _interaccionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.interacciones,
    aliasName:
        'tipos_transaccion__cod_transaccion__interacciones__tipo_transaccion',
  );

  $$InteraccionesTableProcessedTableManager get interaccionesRefs {
    final manager = $$InteraccionesTableTableManager($_db, $_db.interacciones)
        .filter(
          (f) => f.tipoTransaccion.codTransaccion.sqlEquals(
            $_itemColumn<String>('cod_transaccion')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_interaccionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TiposTransaccionTableFilterComposer
    extends Composer<_$AppDatabase, $TiposTransaccionTable> {
  $$TiposTransaccionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codTransaccion => $composableBuilder(
    column: $table.codTransaccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoTrx => $composableBuilder(
    column: $table.tipoTrx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codProtocolo => $composableBuilder(
    column: $table.codProtocolo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ventasRefs(
    Expression<bool> Function($$VentasTableFilterComposer f) f,
  ) {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTransaccion,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.tipoTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interaccionesRefs(
    Expression<bool> Function($$InteraccionesTableFilterComposer f) f,
  ) {
    final $$InteraccionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTransaccion,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.tipoTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableFilterComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposTransaccionTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposTransaccionTable> {
  $$TiposTransaccionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codTransaccion => $composableBuilder(
    column: $table.codTransaccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoTrx => $composableBuilder(
    column: $table.tipoTrx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codProtocolo => $composableBuilder(
    column: $table.codProtocolo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiposTransaccionTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposTransaccionTable> {
  $$TiposTransaccionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codTransaccion => $composableBuilder(
    column: $table.codTransaccion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoTrx =>
      $composableBuilder(column: $table.tipoTrx, builder: (column) => column);

  GeneratedColumn<String> get codProtocolo => $composableBuilder(
    column: $table.codProtocolo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  Expression<T> ventasRefs<T extends Object>(
    Expression<T> Function($$VentasTableAnnotationComposer a) f,
  ) {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTransaccion,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.tipoTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> interaccionesRefs<T extends Object>(
    Expression<T> Function($$InteraccionesTableAnnotationComposer a) f,
  ) {
    final $$InteraccionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codTransaccion,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.tipoTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableAnnotationComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposTransaccionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiposTransaccionTable,
          TipoTransaccion,
          $$TiposTransaccionTableFilterComposer,
          $$TiposTransaccionTableOrderingComposer,
          $$TiposTransaccionTableAnnotationComposer,
          $$TiposTransaccionTableCreateCompanionBuilder,
          $$TiposTransaccionTableUpdateCompanionBuilder,
          (TipoTransaccion, $$TiposTransaccionTableReferences),
          TipoTransaccion,
          PrefetchHooks Function({bool ventasRefs, bool interaccionesRefs})
        > {
  $$TiposTransaccionTableTableManager(
    _$AppDatabase db,
    $TiposTransaccionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposTransaccionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiposTransaccionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiposTransaccionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codTransaccion = const Value.absent(),
                Value<String> tipoTrx = const Value.absent(),
                Value<String?> codProtocolo = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposTransaccionCompanion(
                codTransaccion: codTransaccion,
                tipoTrx: tipoTrx,
                codProtocolo: codProtocolo,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codTransaccion,
                required String tipoTrx,
                Value<String?> codProtocolo = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposTransaccionCompanion.insert(
                codTransaccion: codTransaccion,
                tipoTrx: tipoTrx,
                codProtocolo: codProtocolo,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TiposTransaccionTable, TipoTransaccion>(table),
                  $$TiposTransaccionTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ventasRefs = false, interaccionesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ventasRefs) db.ventas,
                    if (interaccionesRefs) db.interacciones,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ventasRefs)
                        await $_getPrefetchedData<
                          TipoTransaccion,
                          $TiposTransaccionTable,
                          Venta
                        >(
                          currentTable: table,
                          referencedTable: $$TiposTransaccionTableReferences
                              ._ventasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TiposTransaccionTableReferences(
                                db,
                                table,
                                p0,
                              ).ventasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tipoTransaccion == item.codTransaccion,
                              ),
                          typedResults: items,
                        ),
                      if (interaccionesRefs)
                        await $_getPrefetchedData<
                          TipoTransaccion,
                          $TiposTransaccionTable,
                          Interaccion
                        >(
                          currentTable: table,
                          referencedTable: $$TiposTransaccionTableReferences
                              ._interaccionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TiposTransaccionTableReferences(
                                db,
                                table,
                                p0,
                              ).interaccionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tipoTransaccion == item.codTransaccion,
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

typedef $$TiposTransaccionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiposTransaccionTable,
      TipoTransaccion,
      $$TiposTransaccionTableFilterComposer,
      $$TiposTransaccionTableOrderingComposer,
      $$TiposTransaccionTableAnnotationComposer,
      $$TiposTransaccionTableCreateCompanionBuilder,
      $$TiposTransaccionTableUpdateCompanionBuilder,
      (TipoTransaccion, $$TiposTransaccionTableReferences),
      TipoTransaccion,
      PrefetchHooks Function({bool ventasRefs, bool interaccionesRefs})
    >;
typedef $$VentasTableCreateCompanionBuilder = VentasCompanion Function({
  Value<int> id,
  required String canal,
  required int correlativo,
  required String idProcesoPersuasion,
  required String codCliente,
  Value<String?> codEstrategia,
  required String tipoTransaccion,
  required int timestamp,
});
typedef $$VentasTableUpdateCompanionBuilder = VentasCompanion Function({
  Value<int> id,
  Value<String> canal,
  Value<int> correlativo,
  Value<String> idProcesoPersuasion,
  Value<String> codCliente,
  Value<String?> codEstrategia,
  Value<String> tipoTransaccion,
  Value<int> timestamp,
});

final class $$VentasTableReferences
    extends BaseReferences<_$AppDatabase, $VentasTable, Venta> {
  $$VentasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientesTable _codClienteTable(_$AppDatabase db) =>
      db.clientes.createAlias('ventas__cod_cliente__clientes__cod_cliente');

  $$ClientesTableProcessedTableManager get codCliente {
    final $_column = $_itemColumn<String>('cod_cliente')!;

    final manager = $$ClientesTableTableManager(
      $_db,
      $_db.clientes,
    ).filter((f) => f.codCliente.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codClienteTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EstrategiasTable _codEstrategiaTable(_$AppDatabase db) => db
      .estrategias
      .createAlias('ventas__cod_estrategia__estrategias__cod_estrategia');

  $$EstrategiasTableProcessedTableManager? get codEstrategia {
    final $_column = $_itemColumn<String>('cod_estrategia');
    if ($_column == null) return null;
    final manager = $$EstrategiasTableTableManager(
      $_db,
      $_db.estrategias,
    ).filter((f) => f.codEstrategia.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codEstrategiaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TiposTransaccionTable _tipoTransaccionTable(_$AppDatabase db) =>
      db.tiposTransaccion.createAlias(
        'ventas__tipo_transaccion__tipos_transaccion__cod_transaccion',
      );

  $$TiposTransaccionTableProcessedTableManager get tipoTransaccion {
    final $_column = $_itemColumn<String>('tipo_transaccion')!;

    final manager = $$TiposTransaccionTableTableManager(
      $_db,
      $_db.tiposTransaccion,
    ).filter((f) => f.codTransaccion.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoTransaccionTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DetalleVentaTable, List<DetalleVentaData>>
  _detalleVentaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detalleVenta,
    aliasName: 'ventas__id__detalle_venta__venta_id',
  );

  $$DetalleVentaTableProcessedTableManager get detalleVentaRefs {
    final manager = $$DetalleVentaTableTableManager(
      $_db,
      $_db.detalleVenta,
    ).filter((f) => f.ventaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_detalleVentaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VentasTableFilterComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableFilterComposer({
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

  ColumnFilters<String> get canal => $composableBuilder(
    column: $table.canal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientesTableFilterComposer get codCliente {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableFilterComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableFilterComposer get codEstrategia {
    final $$EstrategiasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableFilterComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableFilterComposer get tipoTransaccion {
    final $$TiposTransaccionTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableFilterComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> detalleVentaRefs(
    Expression<bool> Function($$DetalleVentaTableFilterComposer f) f,
  ) {
    final $$DetalleVentaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detalleVenta,
      getReferencedColumn: (t) => t.ventaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetalleVentaTableFilterComposer(
            $db: $db,
            $table: $db.detalleVenta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VentasTableOrderingComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableOrderingComposer({
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

  ColumnOrderings<String> get canal => $composableBuilder(
    column: $table.canal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientesTableOrderingComposer get codCliente {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableOrderingComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableOrderingComposer get codEstrategia {
    final $$EstrategiasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableOrderingComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableOrderingComposer get tipoTransaccion {
    final $$TiposTransaccionTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableOrderingComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VentasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canal =>
      $composableBuilder(column: $table.canal, builder: (column) => column);

  GeneratedColumn<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ClientesTableAnnotationComposer get codCliente {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableAnnotationComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableAnnotationComposer get codEstrategia {
    final $$EstrategiasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableAnnotationComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableAnnotationComposer get tipoTransaccion {
    final $$TiposTransaccionTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableAnnotationComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> detalleVentaRefs<T extends Object>(
    Expression<T> Function($$DetalleVentaTableAnnotationComposer a) f,
  ) {
    final $$DetalleVentaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detalleVenta,
      getReferencedColumn: (t) => t.ventaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetalleVentaTableAnnotationComposer(
            $db: $db,
            $table: $db.detalleVenta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VentasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VentasTable,
          Venta,
          $$VentasTableFilterComposer,
          $$VentasTableOrderingComposer,
          $$VentasTableAnnotationComposer,
          $$VentasTableCreateCompanionBuilder,
          $$VentasTableUpdateCompanionBuilder,
          (Venta, $$VentasTableReferences),
          Venta,
          PrefetchHooks Function({
            bool codCliente,
            bool codEstrategia,
            bool tipoTransaccion,
            bool detalleVentaRefs,
          })
        > {
  $$VentasTableTableManager(_$AppDatabase db, $VentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> canal = const Value.absent(),
                Value<int> correlativo = const Value.absent(),
                Value<String> idProcesoPersuasion = const Value.absent(),
                Value<String> codCliente = const Value.absent(),
                Value<String?> codEstrategia = const Value.absent(),
                Value<String> tipoTransaccion = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
              }) => VentasCompanion(
                id: id,
                canal: canal,
                correlativo: correlativo,
                idProcesoPersuasion: idProcesoPersuasion,
                codCliente: codCliente,
                codEstrategia: codEstrategia,
                tipoTransaccion: tipoTransaccion,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String canal,
                required int correlativo,
                required String idProcesoPersuasion,
                required String codCliente,
                Value<String?> codEstrategia = const Value.absent(),
                required String tipoTransaccion,
                required int timestamp,
              }) => VentasCompanion.insert(
                id: id,
                canal: canal,
                correlativo: correlativo,
                idProcesoPersuasion: idProcesoPersuasion,
                codCliente: codCliente,
                codEstrategia: codEstrategia,
                tipoTransaccion: tipoTransaccion,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VentasTable, Venta>(table),
                  $$VentasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                codCliente = false,
                codEstrategia = false,
                tipoTransaccion = false,
                detalleVentaRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (detalleVentaRefs) db.detalleVenta,
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
                        if (codCliente) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codCliente,
                            referencedTable: $$VentasTableReferences
                                ._codClienteTable(db),
                            referencedColumn: $$VentasTableReferences
                                ._codClienteTable(db)
                                .codCliente,
                          ) as T;
                        }
                        if (codEstrategia) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codEstrategia,
                            referencedTable: $$VentasTableReferences
                                ._codEstrategiaTable(db),
                            referencedColumn: $$VentasTableReferences
                                ._codEstrategiaTable(db)
                                .codEstrategia,
                          ) as T;
                        }
                        if (tipoTransaccion) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoTransaccion,
                            referencedTable: $$VentasTableReferences
                                ._tipoTransaccionTable(db),
                            referencedColumn: $$VentasTableReferences
                                ._tipoTransaccionTable(db)
                                .codTransaccion,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (detalleVentaRefs)
                        await $_getPrefetchedData<
                          Venta,
                          $VentasTable,
                          DetalleVentaData
                        >(
                          currentTable: table,
                          referencedTable: $$VentasTableReferences
                              ._detalleVentaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VentasTableReferences(
                                db,
                                table,
                                p0,
                              ).detalleVentaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ventaId == item.id,
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

typedef $$VentasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VentasTable,
      Venta,
      $$VentasTableFilterComposer,
      $$VentasTableOrderingComposer,
      $$VentasTableAnnotationComposer,
      $$VentasTableCreateCompanionBuilder,
      $$VentasTableUpdateCompanionBuilder,
      (Venta, $$VentasTableReferences),
      Venta,
      PrefetchHooks Function({
        bool codCliente,
        bool codEstrategia,
        bool tipoTransaccion,
        bool detalleVentaRefs,
      })
    >;
typedef $$TiposProductoTableCreateCompanionBuilder =
    TiposProductoCompanion Function({
      required String tipoProducto,
      required String nombreTipoProducto,
      Value<bool> activo,
      Value<int> rowid,
    });
typedef $$TiposProductoTableUpdateCompanionBuilder =
    TiposProductoCompanion Function({
      Value<String> tipoProducto,
      Value<String> nombreTipoProducto,
      Value<bool> activo,
      Value<int> rowid,
    });

final class $$TiposProductoTableReferences
    extends BaseReferences<_$AppDatabase, $TiposProductoTable, TipoProducto> {
  $$TiposProductoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProductosTable, List<Producto>>
  _productosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productos,
    aliasName: 'tipos_producto__tipo_producto__productos__tipo_producto',
  );

  $$ProductosTableProcessedTableManager get productosRefs {
    final manager = $$ProductosTableTableManager($_db, $_db.productos).filter(
      (f) => f.tipoProducto.tipoProducto.sqlEquals(
        $_itemColumn<String>('tipo_producto')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_productosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TiposProductoTableFilterComposer
    extends Composer<_$AppDatabase, $TiposProductoTable> {
  $$TiposProductoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tipoProducto => $composableBuilder(
    column: $table.tipoProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreTipoProducto => $composableBuilder(
    column: $table.nombreTipoProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productosRefs(
    Expression<bool> Function($$ProductosTableFilterComposer f) f,
  ) {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.tipoProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposProductoTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposProductoTable> {
  $$TiposProductoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tipoProducto => $composableBuilder(
    column: $table.tipoProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreTipoProducto => $composableBuilder(
    column: $table.nombreTipoProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiposProductoTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposProductoTable> {
  $$TiposProductoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tipoProducto => $composableBuilder(
    column: $table.tipoProducto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreTipoProducto => $composableBuilder(
    column: $table.nombreTipoProducto,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  Expression<T> productosRefs<T extends Object>(
    Expression<T> Function($$ProductosTableAnnotationComposer a) f,
  ) {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.tipoProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TiposProductoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiposProductoTable,
          TipoProducto,
          $$TiposProductoTableFilterComposer,
          $$TiposProductoTableOrderingComposer,
          $$TiposProductoTableAnnotationComposer,
          $$TiposProductoTableCreateCompanionBuilder,
          $$TiposProductoTableUpdateCompanionBuilder,
          (TipoProducto, $$TiposProductoTableReferences),
          TipoProducto,
          PrefetchHooks Function({bool productosRefs})
        > {
  $$TiposProductoTableTableManager(_$AppDatabase db, $TiposProductoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposProductoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiposProductoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiposProductoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tipoProducto = const Value.absent(),
                Value<String> nombreTipoProducto = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposProductoCompanion(
                tipoProducto: tipoProducto,
                nombreTipoProducto: nombreTipoProducto,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tipoProducto,
                required String nombreTipoProducto,
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposProductoCompanion.insert(
                tipoProducto: tipoProducto,
                nombreTipoProducto: nombreTipoProducto,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TiposProductoTable, TipoProducto>(table),
                  $$TiposProductoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productosRefs) db.productos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productosRefs)
                    await $_getPrefetchedData<
                      TipoProducto,
                      $TiposProductoTable,
                      Producto
                    >(
                      currentTable: table,
                      referencedTable: $$TiposProductoTableReferences
                          ._productosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TiposProductoTableReferences(
                            db,
                            table,
                            p0,
                          ).productosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.tipoProducto == item.tipoProducto,
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

typedef $$TiposProductoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiposProductoTable,
      TipoProducto,
      $$TiposProductoTableFilterComposer,
      $$TiposProductoTableOrderingComposer,
      $$TiposProductoTableAnnotationComposer,
      $$TiposProductoTableCreateCompanionBuilder,
      $$TiposProductoTableUpdateCompanionBuilder,
      (TipoProducto, $$TiposProductoTableReferences),
      TipoProducto,
      PrefetchHooks Function({bool productosRefs})
    >;
typedef $$ProductosTableCreateCompanionBuilder = ProductosCompanion Function({
  required String codLoteProducto,
  required String nombreProducto,
  Value<String?> tipoProducto,
  required int precioUnitarioCentavos,
  required int fechaCreacionStock,
  Value<int> totalDisponible,
  Value<int> totalVendidos,
  Value<int> cierresVenta,
  Value<int> totalVecesMostrado,
  Value<bool> activo,
  Value<int> rowid,
});
typedef $$ProductosTableUpdateCompanionBuilder = ProductosCompanion Function({
  Value<String> codLoteProducto,
  Value<String> nombreProducto,
  Value<String?> tipoProducto,
  Value<int> precioUnitarioCentavos,
  Value<int> fechaCreacionStock,
  Value<int> totalDisponible,
  Value<int> totalVendidos,
  Value<int> cierresVenta,
  Value<int> totalVecesMostrado,
  Value<bool> activo,
  Value<int> rowid,
});

final class $$ProductosTableReferences
    extends BaseReferences<_$AppDatabase, $ProductosTable, Producto> {
  $$ProductosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TiposProductoTable _tipoProductoTable(_$AppDatabase db) => db
      .tiposProducto
      .createAlias('productos__tipo_producto__tipos_producto__tipo_producto');

  $$TiposProductoTableProcessedTableManager? get tipoProducto {
    final $_column = $_itemColumn<String>('tipo_producto');
    if ($_column == null) return null;
    final manager = $$TiposProductoTableTableManager(
      $_db,
      $_db.tiposProducto,
    ).filter((f) => f.tipoProducto.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoProductoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DetalleVentaTable, List<DetalleVentaData>>
  _detalleVentaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detalleVenta,
    aliasName: 'productos__cod_lote_producto__detalle_venta__cod_lote_producto',
  );

  $$DetalleVentaTableProcessedTableManager get detalleVentaRefs {
    final manager = $$DetalleVentaTableTableManager($_db, $_db.detalleVenta)
        .filter(
          (f) => f.codLoteProducto.codLoteProducto.sqlEquals(
            $_itemColumn<String>('cod_lote_producto')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_detalleVentaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InteraccionesTable, List<Interaccion>>
  _interaccionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.interacciones,
    aliasName: 'productos__cod_lote_producto__interacciones__cod_lote_producto',
  );

  $$InteraccionesTableProcessedTableManager get interaccionesRefs {
    final manager = $$InteraccionesTableTableManager($_db, $_db.interacciones)
        .filter(
          (f) => f.codLoteProducto.codLoteProducto.sqlEquals(
            $_itemColumn<String>('cod_lote_producto')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_interaccionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductosTableFilterComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codLoteProducto => $composableBuilder(
    column: $table.codLoteProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fechaCreacionStock => $composableBuilder(
    column: $table.fechaCreacionStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDisponible => $composableBuilder(
    column: $table.totalDisponible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVendidos => $composableBuilder(
    column: $table.totalVendidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cierresVenta => $composableBuilder(
    column: $table.cierresVenta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVecesMostrado => $composableBuilder(
    column: $table.totalVecesMostrado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  $$TiposProductoTableFilterComposer get tipoProducto {
    final $$TiposProductoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoProducto,
      referencedTable: $db.tiposProducto,
      getReferencedColumn: (t) => t.tipoProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposProductoTableFilterComposer(
            $db: $db,
            $table: $db.tiposProducto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> detalleVentaRefs(
    Expression<bool> Function($$DetalleVentaTableFilterComposer f) f,
  ) {
    final $$DetalleVentaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.detalleVenta,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetalleVentaTableFilterComposer(
            $db: $db,
            $table: $db.detalleVenta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interaccionesRefs(
    Expression<bool> Function($$InteraccionesTableFilterComposer f) f,
  ) {
    final $$InteraccionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableFilterComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codLoteProducto => $composableBuilder(
    column: $table.codLoteProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fechaCreacionStock => $composableBuilder(
    column: $table.fechaCreacionStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDisponible => $composableBuilder(
    column: $table.totalDisponible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVendidos => $composableBuilder(
    column: $table.totalVendidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cierresVenta => $composableBuilder(
    column: $table.cierresVenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVecesMostrado => $composableBuilder(
    column: $table.totalVecesMostrado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  $$TiposProductoTableOrderingComposer get tipoProducto {
    final $$TiposProductoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoProducto,
      referencedTable: $db.tiposProducto,
      getReferencedColumn: (t) => t.tipoProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposProductoTableOrderingComposer(
            $db: $db,
            $table: $db.tiposProducto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codLoteProducto => $composableBuilder(
    column: $table.codLoteProducto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombreProducto => $composableBuilder(
    column: $table.nombreProducto,
    builder: (column) => column,
  );

  GeneratedColumn<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fechaCreacionStock => $composableBuilder(
    column: $table.fechaCreacionStock,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDisponible => $composableBuilder(
    column: $table.totalDisponible,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVendidos => $composableBuilder(
    column: $table.totalVendidos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cierresVenta => $composableBuilder(
    column: $table.cierresVenta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVecesMostrado => $composableBuilder(
    column: $table.totalVecesMostrado,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  $$TiposProductoTableAnnotationComposer get tipoProducto {
    final $$TiposProductoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoProducto,
      referencedTable: $db.tiposProducto,
      getReferencedColumn: (t) => t.tipoProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposProductoTableAnnotationComposer(
            $db: $db,
            $table: $db.tiposProducto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> detalleVentaRefs<T extends Object>(
    Expression<T> Function($$DetalleVentaTableAnnotationComposer a) f,
  ) {
    final $$DetalleVentaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.detalleVenta,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetalleVentaTableAnnotationComposer(
            $db: $db,
            $table: $db.detalleVenta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> interaccionesRefs<T extends Object>(
    Expression<T> Function($$InteraccionesTableAnnotationComposer a) f,
  ) {
    final $$InteraccionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableAnnotationComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductosTable,
          Producto,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (Producto, $$ProductosTableReferences),
          Producto,
          PrefetchHooks Function({
            bool tipoProducto,
            bool detalleVentaRefs,
            bool interaccionesRefs,
          })
        > {
  $$ProductosTableTableManager(_$AppDatabase db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codLoteProducto = const Value.absent(),
                Value<String> nombreProducto = const Value.absent(),
                Value<String?> tipoProducto = const Value.absent(),
                Value<int> precioUnitarioCentavos = const Value.absent(),
                Value<int> fechaCreacionStock = const Value.absent(),
                Value<int> totalDisponible = const Value.absent(),
                Value<int> totalVendidos = const Value.absent(),
                Value<int> cierresVenta = const Value.absent(),
                Value<int> totalVecesMostrado = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                codLoteProducto: codLoteProducto,
                nombreProducto: nombreProducto,
                tipoProducto: tipoProducto,
                precioUnitarioCentavos: precioUnitarioCentavos,
                fechaCreacionStock: fechaCreacionStock,
                totalDisponible: totalDisponible,
                totalVendidos: totalVendidos,
                cierresVenta: cierresVenta,
                totalVecesMostrado: totalVecesMostrado,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codLoteProducto,
                required String nombreProducto,
                Value<String?> tipoProducto = const Value.absent(),
                required int precioUnitarioCentavos,
                required int fechaCreacionStock,
                Value<int> totalDisponible = const Value.absent(),
                Value<int> totalVendidos = const Value.absent(),
                Value<int> cierresVenta = const Value.absent(),
                Value<int> totalVecesMostrado = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                codLoteProducto: codLoteProducto,
                nombreProducto: nombreProducto,
                tipoProducto: tipoProducto,
                precioUnitarioCentavos: precioUnitarioCentavos,
                fechaCreacionStock: fechaCreacionStock,
                totalDisponible: totalDisponible,
                totalVendidos: totalVendidos,
                cierresVenta: cierresVenta,
                totalVecesMostrado: totalVecesMostrado,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductosTable, Producto>(table),
                  $$ProductosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tipoProducto = false,
                detalleVentaRefs = false,
                interaccionesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (detalleVentaRefs) db.detalleVenta,
                    if (interaccionesRefs) db.interacciones,
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
                        if (tipoProducto) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoProducto,
                            referencedTable: $$ProductosTableReferences
                                ._tipoProductoTable(db),
                            referencedColumn: $$ProductosTableReferences
                                ._tipoProductoTable(db)
                                .tipoProducto,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (detalleVentaRefs)
                        await $_getPrefetchedData<
                          Producto,
                          $ProductosTable,
                          DetalleVentaData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._detalleVentaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).detalleVentaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.codLoteProducto == item.codLoteProducto,
                              ),
                          typedResults: items,
                        ),
                      if (interaccionesRefs)
                        await $_getPrefetchedData<
                          Producto,
                          $ProductosTable,
                          Interaccion
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._interaccionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).interaccionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.codLoteProducto == item.codLoteProducto,
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

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductosTable,
      Producto,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (Producto, $$ProductosTableReferences),
      Producto,
      PrefetchHooks Function({
        bool tipoProducto,
        bool detalleVentaRefs,
        bool interaccionesRefs,
      })
    >;
typedef $$DetalleVentaTableCreateCompanionBuilder =
    DetalleVentaCompanion Function({
      Value<int> id,
      required int ventaId,
      required String codLoteProducto,
      required int cantidad,
      required int precioUnitarioCentavos,
    });
typedef $$DetalleVentaTableUpdateCompanionBuilder =
    DetalleVentaCompanion Function({
      Value<int> id,
      Value<int> ventaId,
      Value<String> codLoteProducto,
      Value<int> cantidad,
      Value<int> precioUnitarioCentavos,
    });

final class $$DetalleVentaTableReferences
    extends
        BaseReferences<_$AppDatabase, $DetalleVentaTable, DetalleVentaData> {
  $$DetalleVentaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VentasTable _ventaIdTable(_$AppDatabase db) =>
      db.ventas.createAlias('detalle_venta__venta_id__ventas__id');

  $$VentasTableProcessedTableManager get ventaId {
    final $_column = $_itemColumn<int>('venta_id')!;

    final manager = $$VentasTableTableManager(
      $_db,
      $_db.ventas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ventaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductosTable _codLoteProductoTable(_$AppDatabase db) =>
      db.productos.createAlias(
        'detalle_venta__cod_lote_producto__productos__cod_lote_producto',
      );

  $$ProductosTableProcessedTableManager get codLoteProducto {
    final $_column = $_itemColumn<String>('cod_lote_producto')!;

    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.codLoteProducto.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codLoteProductoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DetalleVentaTableFilterComposer
    extends Composer<_$AppDatabase, $DetalleVentaTable> {
  $$DetalleVentaTableFilterComposer({
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

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => ColumnFilters(column),
  );

  $$VentasTableFilterComposer get ventaId {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableFilterComposer get codLoteProducto {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetalleVentaTableOrderingComposer
    extends Composer<_$AppDatabase, $DetalleVentaTable> {
  $$DetalleVentaTableOrderingComposer({
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

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  $$VentasTableOrderingComposer get ventaId {
    final $$VentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableOrderingComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableOrderingComposer get codLoteProducto {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetalleVentaTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetalleVentaTable> {
  $$DetalleVentaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<int> get precioUnitarioCentavos => $composableBuilder(
    column: $table.precioUnitarioCentavos,
    builder: (column) => column,
  );

  $$VentasTableAnnotationComposer get ventaId {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableAnnotationComposer get codLoteProducto {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetalleVentaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetalleVentaTable,
          DetalleVentaData,
          $$DetalleVentaTableFilterComposer,
          $$DetalleVentaTableOrderingComposer,
          $$DetalleVentaTableAnnotationComposer,
          $$DetalleVentaTableCreateCompanionBuilder,
          $$DetalleVentaTableUpdateCompanionBuilder,
          (DetalleVentaData, $$DetalleVentaTableReferences),
          DetalleVentaData,
          PrefetchHooks Function({bool ventaId, bool codLoteProducto})
        > {
  $$DetalleVentaTableTableManager(_$AppDatabase db, $DetalleVentaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetalleVentaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetalleVentaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetalleVentaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ventaId = const Value.absent(),
                Value<String> codLoteProducto = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<int> precioUnitarioCentavos = const Value.absent(),
              }) => DetalleVentaCompanion(
                id: id,
                ventaId: ventaId,
                codLoteProducto: codLoteProducto,
                cantidad: cantidad,
                precioUnitarioCentavos: precioUnitarioCentavos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ventaId,
                required String codLoteProducto,
                required int cantidad,
                required int precioUnitarioCentavos,
              }) => DetalleVentaCompanion.insert(
                id: id,
                ventaId: ventaId,
                codLoteProducto: codLoteProducto,
                cantidad: cantidad,
                precioUnitarioCentavos: precioUnitarioCentavos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DetalleVentaTable, DetalleVentaData>(table),
                  $$DetalleVentaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ventaId = false, codLoteProducto = false}) {
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
                    if (ventaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ventaId,
                        referencedTable: $$DetalleVentaTableReferences
                            ._ventaIdTable(db),
                        referencedColumn: $$DetalleVentaTableReferences
                            ._ventaIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (codLoteProducto) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.codLoteProducto,
                        referencedTable: $$DetalleVentaTableReferences
                            ._codLoteProductoTable(db),
                        referencedColumn: $$DetalleVentaTableReferences
                            ._codLoteProductoTable(db)
                            .codLoteProducto,
                      ) as T;
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

typedef $$DetalleVentaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetalleVentaTable,
      DetalleVentaData,
      $$DetalleVentaTableFilterComposer,
      $$DetalleVentaTableOrderingComposer,
      $$DetalleVentaTableAnnotationComposer,
      $$DetalleVentaTableCreateCompanionBuilder,
      $$DetalleVentaTableUpdateCompanionBuilder,
      (DetalleVentaData, $$DetalleVentaTableReferences),
      DetalleVentaData,
      PrefetchHooks Function({bool ventaId, bool codLoteProducto})
    >;
typedef $$GestosTableCreateCompanionBuilder = GestosCompanion Function({
  required String codGesto,
  required String nombreGesto,
  Value<String?> descripcion,
  Value<bool> activo,
  Value<int> rowid,
});
typedef $$GestosTableUpdateCompanionBuilder = GestosCompanion Function({
  Value<String> codGesto,
  Value<String> nombreGesto,
  Value<String?> descripcion,
  Value<bool> activo,
  Value<int> rowid,
});

final class $$GestosTableReferences
    extends BaseReferences<_$AppDatabase, $GestosTable, Gesto> {
  $$GestosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InteraccionesTable, List<Interaccion>>
  _interaccionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.interacciones,
    aliasName: 'gestos__cod_gesto__interacciones__cod_gesto',
  );

  $$InteraccionesTableProcessedTableManager get interaccionesRefs {
    final manager = $$InteraccionesTableTableManager($_db, $_db.interacciones)
        .filter(
          (f) =>
              f.codGesto.codGesto.sqlEquals($_itemColumn<String>('cod_gesto')!),
        );

    final cache = $_typedResult.readTableOrNull(_interaccionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GestosTableFilterComposer
    extends Composer<_$AppDatabase, $GestosTable> {
  $$GestosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codGesto => $composableBuilder(
    column: $table.codGesto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreGesto => $composableBuilder(
    column: $table.nombreGesto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> interaccionesRefs(
    Expression<bool> Function($$InteraccionesTableFilterComposer f) f,
  ) {
    final $$InteraccionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codGesto,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codGesto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableFilterComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GestosTableOrderingComposer
    extends Composer<_$AppDatabase, $GestosTable> {
  $$GestosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codGesto => $composableBuilder(
    column: $table.codGesto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreGesto => $composableBuilder(
    column: $table.nombreGesto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GestosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GestosTable> {
  $$GestosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codGesto =>
      $composableBuilder(column: $table.codGesto, builder: (column) => column);

  GeneratedColumn<String> get nombreGesto => $composableBuilder(
    column: $table.nombreGesto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  Expression<T> interaccionesRefs<T extends Object>(
    Expression<T> Function($$InteraccionesTableAnnotationComposer a) f,
  ) {
    final $$InteraccionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codGesto,
      referencedTable: $db.interacciones,
      getReferencedColumn: (t) => t.codGesto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InteraccionesTableAnnotationComposer(
            $db: $db,
            $table: $db.interacciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GestosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GestosTable,
          Gesto,
          $$GestosTableFilterComposer,
          $$GestosTableOrderingComposer,
          $$GestosTableAnnotationComposer,
          $$GestosTableCreateCompanionBuilder,
          $$GestosTableUpdateCompanionBuilder,
          (Gesto, $$GestosTableReferences),
          Gesto,
          PrefetchHooks Function({bool interaccionesRefs})
        > {
  $$GestosTableTableManager(_$AppDatabase db, $GestosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GestosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GestosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GestosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codGesto = const Value.absent(),
                Value<String> nombreGesto = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GestosCompanion(
                codGesto: codGesto,
                nombreGesto: nombreGesto,
                descripcion: descripcion,
                activo: activo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codGesto,
                required String nombreGesto,
                Value<String?> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GestosCompanion.insert(
                codGesto: codGesto,
                nombreGesto: nombreGesto,
                descripcion: descripcion,
                activo: activo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GestosTable, Gesto>(table),
                  $$GestosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({interaccionesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (interaccionesRefs) db.interacciones,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (interaccionesRefs)
                    await $_getPrefetchedData<Gesto, $GestosTable, Interaccion>(
                      currentTable: table,
                      referencedTable: $$GestosTableReferences
                          ._interaccionesRefsTable(db),
                      managerFromTypedResult: (p0) => $$GestosTableReferences(
                        db,
                        table,
                        p0,
                      ).interaccionesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.codGesto == item.codGesto,
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

typedef $$GestosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GestosTable,
      Gesto,
      $$GestosTableFilterComposer,
      $$GestosTableOrderingComposer,
      $$GestosTableAnnotationComposer,
      $$GestosTableCreateCompanionBuilder,
      $$GestosTableUpdateCompanionBuilder,
      (Gesto, $$GestosTableReferences),
      Gesto,
      PrefetchHooks Function({bool interaccionesRefs})
    >;
typedef $$InteraccionesTableCreateCompanionBuilder =
    InteraccionesCompanion Function({
      Value<int> id,
      required String canal,
      required int correlativo,
      required String idProcesoPersuasion,
      required String codCliente,
      Value<String?> codEstrategia,
      Value<String?> codGesto,
      Value<String?> codLoteProducto,
      required String tipoTransaccion,
      required int timestamp,
      required int nivelDeInteres,
    });
typedef $$InteraccionesTableUpdateCompanionBuilder =
    InteraccionesCompanion Function({
      Value<int> id,
      Value<String> canal,
      Value<int> correlativo,
      Value<String> idProcesoPersuasion,
      Value<String> codCliente,
      Value<String?> codEstrategia,
      Value<String?> codGesto,
      Value<String?> codLoteProducto,
      Value<String> tipoTransaccion,
      Value<int> timestamp,
      Value<int> nivelDeInteres,
    });

final class $$InteraccionesTableReferences
    extends BaseReferences<_$AppDatabase, $InteraccionesTable, Interaccion> {
  $$InteraccionesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClientesTable _codClienteTable(_$AppDatabase db) => db.clientes
      .createAlias('interacciones__cod_cliente__clientes__cod_cliente');

  $$ClientesTableProcessedTableManager get codCliente {
    final $_column = $_itemColumn<String>('cod_cliente')!;

    final manager = $$ClientesTableTableManager(
      $_db,
      $_db.clientes,
    ).filter((f) => f.codCliente.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codClienteTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EstrategiasTable _codEstrategiaTable(_$AppDatabase db) =>
      db.estrategias.createAlias(
        'interacciones__cod_estrategia__estrategias__cod_estrategia',
      );

  $$EstrategiasTableProcessedTableManager? get codEstrategia {
    final $_column = $_itemColumn<String>('cod_estrategia');
    if ($_column == null) return null;
    final manager = $$EstrategiasTableTableManager(
      $_db,
      $_db.estrategias,
    ).filter((f) => f.codEstrategia.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codEstrategiaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GestosTable _codGestoTable(_$AppDatabase db) =>
      db.gestos.createAlias('interacciones__cod_gesto__gestos__cod_gesto');

  $$GestosTableProcessedTableManager? get codGesto {
    final $_column = $_itemColumn<String>('cod_gesto');
    if ($_column == null) return null;
    final manager = $$GestosTableTableManager(
      $_db,
      $_db.gestos,
    ).filter((f) => f.codGesto.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codGestoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductosTable _codLoteProductoTable(_$AppDatabase db) =>
      db.productos.createAlias(
        'interacciones__cod_lote_producto__productos__cod_lote_producto',
      );

  $$ProductosTableProcessedTableManager? get codLoteProducto {
    final $_column = $_itemColumn<String>('cod_lote_producto');
    if ($_column == null) return null;
    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.codLoteProducto.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_codLoteProductoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TiposTransaccionTable _tipoTransaccionTable(_$AppDatabase db) =>
      db.tiposTransaccion.createAlias(
        'interacciones__tipo_transaccion__tipos_transaccion__cod_transaccion',
      );

  $$TiposTransaccionTableProcessedTableManager get tipoTransaccion {
    final $_column = $_itemColumn<String>('tipo_transaccion')!;

    final manager = $$TiposTransaccionTableTableManager(
      $_db,
      $_db.tiposTransaccion,
    ).filter((f) => f.codTransaccion.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoTransaccionTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InteraccionesTableFilterComposer
    extends Composer<_$AppDatabase, $InteraccionesTable> {
  $$InteraccionesTableFilterComposer({
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

  ColumnFilters<String> get canal => $composableBuilder(
    column: $table.canal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nivelDeInteres => $composableBuilder(
    column: $table.nivelDeInteres,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientesTableFilterComposer get codCliente {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableFilterComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableFilterComposer get codEstrategia {
    final $$EstrategiasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableFilterComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GestosTableFilterComposer get codGesto {
    final $$GestosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codGesto,
      referencedTable: $db.gestos,
      getReferencedColumn: (t) => t.codGesto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GestosTableFilterComposer(
            $db: $db,
            $table: $db.gestos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableFilterComposer get codLoteProducto {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableFilterComposer get tipoTransaccion {
    final $$TiposTransaccionTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableFilterComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InteraccionesTableOrderingComposer
    extends Composer<_$AppDatabase, $InteraccionesTable> {
  $$InteraccionesTableOrderingComposer({
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

  ColumnOrderings<String> get canal => $composableBuilder(
    column: $table.canal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nivelDeInteres => $composableBuilder(
    column: $table.nivelDeInteres,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientesTableOrderingComposer get codCliente {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableOrderingComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableOrderingComposer get codEstrategia {
    final $$EstrategiasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableOrderingComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GestosTableOrderingComposer get codGesto {
    final $$GestosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codGesto,
      referencedTable: $db.gestos,
      getReferencedColumn: (t) => t.codGesto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GestosTableOrderingComposer(
            $db: $db,
            $table: $db.gestos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableOrderingComposer get codLoteProducto {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableOrderingComposer get tipoTransaccion {
    final $$TiposTransaccionTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableOrderingComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InteraccionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InteraccionesTable> {
  $$InteraccionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canal =>
      $composableBuilder(column: $table.canal, builder: (column) => column);

  GeneratedColumn<int> get correlativo => $composableBuilder(
    column: $table.correlativo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idProcesoPersuasion => $composableBuilder(
    column: $table.idProcesoPersuasion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get nivelDeInteres => $composableBuilder(
    column: $table.nivelDeInteres,
    builder: (column) => column,
  );

  $$ClientesTableAnnotationComposer get codCliente {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codCliente,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.codCliente,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableAnnotationComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstrategiasTableAnnotationComposer get codEstrategia {
    final $$EstrategiasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codEstrategia,
      referencedTable: $db.estrategias,
      getReferencedColumn: (t) => t.codEstrategia,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstrategiasTableAnnotationComposer(
            $db: $db,
            $table: $db.estrategias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GestosTableAnnotationComposer get codGesto {
    final $$GestosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codGesto,
      referencedTable: $db.gestos,
      getReferencedColumn: (t) => t.codGesto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GestosTableAnnotationComposer(
            $db: $db,
            $table: $db.gestos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableAnnotationComposer get codLoteProducto {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codLoteProducto,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.codLoteProducto,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TiposTransaccionTableAnnotationComposer get tipoTransaccion {
    final $$TiposTransaccionTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoTransaccion,
      referencedTable: $db.tiposTransaccion,
      getReferencedColumn: (t) => t.codTransaccion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TiposTransaccionTableAnnotationComposer(
            $db: $db,
            $table: $db.tiposTransaccion,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InteraccionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InteraccionesTable,
          Interaccion,
          $$InteraccionesTableFilterComposer,
          $$InteraccionesTableOrderingComposer,
          $$InteraccionesTableAnnotationComposer,
          $$InteraccionesTableCreateCompanionBuilder,
          $$InteraccionesTableUpdateCompanionBuilder,
          (Interaccion, $$InteraccionesTableReferences),
          Interaccion,
          PrefetchHooks Function({
            bool codCliente,
            bool codEstrategia,
            bool codGesto,
            bool codLoteProducto,
            bool tipoTransaccion,
          })
        > {
  $$InteraccionesTableTableManager(_$AppDatabase db, $InteraccionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InteraccionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InteraccionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InteraccionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> canal = const Value.absent(),
                Value<int> correlativo = const Value.absent(),
                Value<String> idProcesoPersuasion = const Value.absent(),
                Value<String> codCliente = const Value.absent(),
                Value<String?> codEstrategia = const Value.absent(),
                Value<String?> codGesto = const Value.absent(),
                Value<String?> codLoteProducto = const Value.absent(),
                Value<String> tipoTransaccion = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> nivelDeInteres = const Value.absent(),
              }) => InteraccionesCompanion(
                id: id,
                canal: canal,
                correlativo: correlativo,
                idProcesoPersuasion: idProcesoPersuasion,
                codCliente: codCliente,
                codEstrategia: codEstrategia,
                codGesto: codGesto,
                codLoteProducto: codLoteProducto,
                tipoTransaccion: tipoTransaccion,
                timestamp: timestamp,
                nivelDeInteres: nivelDeInteres,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String canal,
                required int correlativo,
                required String idProcesoPersuasion,
                required String codCliente,
                Value<String?> codEstrategia = const Value.absent(),
                Value<String?> codGesto = const Value.absent(),
                Value<String?> codLoteProducto = const Value.absent(),
                required String tipoTransaccion,
                required int timestamp,
                required int nivelDeInteres,
              }) => InteraccionesCompanion.insert(
                id: id,
                canal: canal,
                correlativo: correlativo,
                idProcesoPersuasion: idProcesoPersuasion,
                codCliente: codCliente,
                codEstrategia: codEstrategia,
                codGesto: codGesto,
                codLoteProducto: codLoteProducto,
                tipoTransaccion: tipoTransaccion,
                timestamp: timestamp,
                nivelDeInteres: nivelDeInteres,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InteraccionesTable, Interaccion>(table),
                  $$InteraccionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                codCliente = false,
                codEstrategia = false,
                codGesto = false,
                codLoteProducto = false,
                tipoTransaccion = false,
              }) {
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
                        if (codCliente) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codCliente,
                            referencedTable: $$InteraccionesTableReferences
                                ._codClienteTable(db),
                            referencedColumn: $$InteraccionesTableReferences
                                ._codClienteTable(db)
                                .codCliente,
                          ) as T;
                        }
                        if (codEstrategia) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codEstrategia,
                            referencedTable: $$InteraccionesTableReferences
                                ._codEstrategiaTable(db),
                            referencedColumn: $$InteraccionesTableReferences
                                ._codEstrategiaTable(db)
                                .codEstrategia,
                          ) as T;
                        }
                        if (codGesto) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codGesto,
                            referencedTable: $$InteraccionesTableReferences
                                ._codGestoTable(db),
                            referencedColumn: $$InteraccionesTableReferences
                                ._codGestoTable(db)
                                .codGesto,
                          ) as T;
                        }
                        if (codLoteProducto) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.codLoteProducto,
                            referencedTable: $$InteraccionesTableReferences
                                ._codLoteProductoTable(db),
                            referencedColumn: $$InteraccionesTableReferences
                                ._codLoteProductoTable(db)
                                .codLoteProducto,
                          ) as T;
                        }
                        if (tipoTransaccion) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoTransaccion,
                            referencedTable: $$InteraccionesTableReferences
                                ._tipoTransaccionTable(db),
                            referencedColumn: $$InteraccionesTableReferences
                                ._tipoTransaccionTable(db)
                                .codTransaccion,
                          ) as T;
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

typedef $$InteraccionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InteraccionesTable,
      Interaccion,
      $$InteraccionesTableFilterComposer,
      $$InteraccionesTableOrderingComposer,
      $$InteraccionesTableAnnotationComposer,
      $$InteraccionesTableCreateCompanionBuilder,
      $$InteraccionesTableUpdateCompanionBuilder,
      (Interaccion, $$InteraccionesTableReferences),
      Interaccion,
      PrefetchHooks Function({
        bool codCliente,
        bool codEstrategia,
        bool codGesto,
        bool codLoteProducto,
        bool tipoTransaccion,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TiposClienteTableTableManager get tiposCliente =>
      $$TiposClienteTableTableManager(_db, _db.tiposCliente);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
  $$EstrategiasTableTableManager get estrategias =>
      $$EstrategiasTableTableManager(_db, _db.estrategias);
  $$TiposTransaccionTableTableManager get tiposTransaccion =>
      $$TiposTransaccionTableTableManager(_db, _db.tiposTransaccion);
  $$VentasTableTableManager get ventas =>
      $$VentasTableTableManager(_db, _db.ventas);
  $$TiposProductoTableTableManager get tiposProducto =>
      $$TiposProductoTableTableManager(_db, _db.tiposProducto);
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$DetalleVentaTableTableManager get detalleVenta =>
      $$DetalleVentaTableTableManager(_db, _db.detalleVenta);
  $$GestosTableTableManager get gestos =>
      $$GestosTableTableManager(_db, _db.gestos);
  $$InteraccionesTableTableManager get interacciones =>
      $$InteraccionesTableTableManager(_db, _db.interacciones);
}

class Kpi1CierreVentasPorMesResult {
  final String mes;
  final int cierres;
  final int intentos;
  final double porcentaje;
  Kpi1CierreVentasPorMesResult({
    required this.mes,
    required this.cierres,
    required this.intentos,
    required this.porcentaje,
  });
}

class Kpi3EfectividadEstrategiaPorTipoClienteResult {
  final String? tipoCliente;
  final String codEstrategia;
  final String nombreEstrategia;
  final int ventasGeneradas;
  final int vecesAplicada;
  final double efectividad;
  Kpi3EfectividadEstrategiaPorTipoClienteResult({
    this.tipoCliente,
    required this.codEstrategia,
    required this.nombreEstrategia,
    required this.ventasGeneradas,
    required this.vecesAplicada,
    required this.efectividad,
  });
}

class Kpi4VentasPorDiaSemanaResult {
  final int diaSemana;
  final int ventas;
  final double porcentaje;
  Kpi4VentasPorDiaSemanaResult({
    required this.diaSemana,
    required this.ventas,
    required this.porcentaje,
  });
}
