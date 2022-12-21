export type TypeName = {
    tag: "type_name",
    name: string,
};

export type Str = {
    tag: "str",
};

export type I32 = {
    tag: "i32",
};

export type Bool = {
    tag: "bool",
};

export type Json = {
    tag: "json",
};

export type I64 = {
    tag: "i64",
};

export type F32 = {
    tag: "f32",
};

export type F64 = {
    tag: "f64",
};

export type SerialI64 = {
    tag: "serial_i64",
};

export type SerialI32 = {
    tag: "serial_i32",
};

export type Timestamp = {
    tag: "timestamp",
};

export type Uuid = {
    tag: "uuid",
};

export type Date = {
    tag: "date",
};

export type ByteArray = {
    tag: "byte_array",
};

export type PrimitiveType = Str | I32 | Bool | Json | I64 | F32 | F64 | SerialI64 | SerialI32 | Timestamp | Uuid | Date | ByteArray | Enum;

export type TypeLiteral = TypeName | PrimitiveType;

export type ArrayType = {
    tag: "array",
    type: Type,
};

export type Type = TypeLiteral | ArrayType;


export const Str: Str = {
    tag: "str",
};

export const I32: I32 = {
    tag: "i32",
};

export const Bool: Bool = {
    tag: "bool",
};

export const Json: Json = {
    tag: "json",
};

export const I64: I64 = {
    tag: "i64",
};

export const F32: F32 = {
    tag: "f32",
};

export const F64: F64 = {
    tag: "f64",
};

export const SerialI64: SerialI64 = {
    tag: "serial_i64",
};

export const SerialI32: SerialI32 = {
    tag: "serial_i32",
};

export const Timestamp: Timestamp = {
    tag: "timestamp",
};

export const Uuid: Uuid = {
    tag: "uuid",
};

export const Date: Date = {
    tag: "date",
};

export const ByteArray: ByteArray = {
    tag: "byte_array",
};

export function Array(t: Type): ArrayType {
    return {
        tag: "array",
        type: t,
    };
}


export function TypeName(name: string): TypeName {
    return {
        tag: "type_name",
        name
    };
}


export type TableName = string;
export type ColumnName = string;


export type ColumnConstraintUnique = {
    tag: "unique";
};
export const CUnique: ColumnConstraintUnique = {
    tag: "unique",
};

export type ColumnConstraintPrimaryKey = {
    tag: "primary_key";
};
export const CPrimaryKey: ColumnConstraintPrimaryKey = {
    tag: "primary_key",
};


export type ColumnConstraintForeignKey = {
    tag: "foreign_key",
    table: TableName,
    column: ColumnName,
}; export function CForeignKey(table: TableName, column: ColumnName): ColumnConstraintForeignKey {
    return {
        tag: "foreign_key",
        table, column
    };
}
export type ConstraintExpression = ColumnConstraintUnique | ColumnConstraintPrimaryKey | ColumnConstraintForeignKey;
export type ColumnConstraint = ConstraintExpression;


export type Default<T> =
    (T extends I32 ? number :
        (T extends I64 ? number :
            (T extends Str ? string :
                (T extends ArrayType ? Default<ArrayType["type"]>[]
                    : (T extends Bool ? boolean : (
                        T extends Json ? object : (
                            (T extends Enum ? string : never)
                        )))))))
    | { raw: string; };

export function default_is_raw<T extends Type>(t: Default<T>): boolean {
    if (typeof t === "string") return false;
    if (typeof t === "boolean") return false;
    if (typeof t === "number") return false;
    if (typeof t === "object") {
        // TODO
        //@ts-ignore
        if ("raw" in t) return true;
    }
    return false;
}

export type NullableColumnType<T extends Type> = {
    tag: "nullable_column_type",
    type: T,
    default?: Default<T>,
};
export type NonNullableColumnType<T extends Type> = {
    tag: "column_type",
    type: T,
    default?: Default<T>,
};
export type ColumnType<T extends Type> = NullableColumnType<T> | NonNullableColumnType<T>;

export function Nullable<T extends Type>(t: T, default_value?: Default<T>): NullableColumnType<T> {
    return {
        tag: "nullable_column_type",
        type: t,
        default: default_value,
    };
}

export function NonNullable<T extends Type>(t: T, default_value?: Default<T>): NonNullableColumnType<T> {
    return {
        tag: "column_type",
        type: t,
        default: default_value,
    };
}

export type Column<T extends Type> = {
    name: ColumnName,
    type: ColumnType<T>,
    constraints: ColumnConstraint[],
};

export function Column<T extends Type>(name: ColumnName, type: ColumnType<T>, opts?: {
    foreign_key?: ColumnConstraintForeignKey,
    unique?: boolean,
    primary_key?: boolean,
    constraints?: ColumnConstraint[],
}): Column<T> {
    if (opts === undefined) opts = {};
    let constraints = [];
    if (opts.foreign_key) constraints.push(opts.foreign_key);
    if (opts.unique) constraints.push(CUnique);
    if (opts.primary_key) constraints.push(CPrimaryKey);
    return {
        name,
        type,
        constraints,
    };
}


export type TableConstraintUnique = {
    tag: "unique";
    columns: ColumnName[],
};
export function TUnique(columns: ColumnName[]): TableConstraintUnique {
    return {
        tag: "unique",
        columns,
    };
};

export type TableConstraintPrimaryKey = {
    tag: "primary_key",
    columns: ColumnName[],
};
export function TPrimaryKey(columns: ColumnName[]): TableConstraintPrimaryKey {
    return {
        tag: "primary_key",
        columns,
    };
}

/*
constraint check_group_user check (
      (receiver_user_id is null and receiver_group_id is not null) 
   or (receiver_user_id is not null and receiver_group_id is null) )


export type TableConstraitCheck = {

}

export function TCheck(columns: ColumnName[]): TableConstraintPrimaryKey {
    return {
        tag: "primary_key",
        columns,
    };
}
*/


export type TableConstraint = TableConstraintUnique | TableConstraintPrimaryKey;

export type TrigramIndex = {
    name: string;
    columns: string[];
}
export function ITrigram(name: string, columns: string[]): TrigramIndex {
    return {
        name,
        columns
    }
}

export type RawIndex = {
    name: string;
    raw: string;
}
export function IRaw(name:string, raw: string): RawIndex {
    return {
        name,
        raw
    }
}

export type TableIndex = TrigramIndex | RawIndex;

export type Table = {
    name: TableName,
    columns: Column<any>[],
    constraints?: TableConstraint[],
    indexes?: TableIndex[],
    with_history?: boolean,
};

export function Table(name: TableName, columns: Column<any>[], opts?: {
    constraints?: TableConstraint[],
    indexes?: TableIndex[],
    with_history?: boolean,
}): Table {
    if (opts == undefined) opts = {};
    return {
        name, columns, constraints: opts.constraints, indexes: opts.indexes, with_history: opts.with_history,
    };
}

export type Enum = {
    tag: "enum",
    name: string,
    values: string[],
};

export function Enum(name: string, values: string[]): Enum {
    return {
        tag: "enum",
        name, values
    };
}
export type Module = {
    name: string,
    tables: Table[],
    enums?: Enum[],
    raw_sql?: string,
};

export function is_part_of_primary_key(t: Table, c: Column<any>): boolean {
    let pk_constraint = c.constraints.find(c => c.tag == "primary_key");
    if (pk_constraint !== undefined) return true;

    let table_pk_constraint = t.constraints?.find(c => c.tag == "primary_key");
    if (table_pk_constraint !== undefined && table_pk_constraint.columns.indexOf(c.name) != -1) return true;

    return false;
}

export function primary_keys(t: Table): string[] {
    let primary_keys: string[] = [];
    for (let c of t.columns) {
        if (is_part_of_primary_key(t, c)) {
            primary_keys.push(c.name);
        }
    }
    return primary_keys;
}

export function references(column: Column<any>): null | {table: string, column: string} {
    for (let c of column.constraints) {
        if (c.tag == "foreign_key") {
            return {
                table: c.table,
                column: c.column,
            }
        }
    }
    return null;
}

export function history_table(table: Table): Table {
    let columns: Column<any>[] = [];
    let primary_keys = [];
    for (let column of table.columns) {
        if (is_part_of_primary_key(table, column)) {
            // TODO: check which table and column are being referenced
            let r = references(column);
            columns.push(
                Column(column.name, column.type, r ? {foreign_key: CForeignKey(r.table, r.column)}: {})
            );
            primary_keys.push(column.name);
        } else {
            columns.push(
                {...column, constraints: [], type: {...column.type, default: undefined}}
            );
        }
    }
    return {
        name: table.name+"_history",
        columns,
        constraints: [
            TPrimaryKey([...primary_keys, "updated_at"])
        ]
    }
}
