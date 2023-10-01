import * as t from './types';


function gen_type(type: t.Type): string {
    switch (type.tag) {
        case "bool":
            return "BOOLEAN";
        case "i32":
            return "INTEGER";
        case "i64":
            return "BIGINT";
        case "str":
            return "TEXT";

        case "f32":
            return "FLOAT4";

        case "f64":
            return "FLOAT8";

        case "json":
            return "JSONB";

        case "byte_array":
            return "BYTEA";

        case "timestamp":
            return "TIMESTAMP WITH TIME ZONE";
            
        case "uuid":
            return "UUID";

        case "date":
            return "DATE";

        case "serial_i32":
            return "SERIAL";

        case "serial_i64":
            return "BIGSERIAL";

        case "array":
            return gen_type(type.type) + "[]";

        case "enum":
            return type.name;

        default:
            throw `not implemented: ${type.tag}!`;
    }
}

function gen_enum(t: t.Enum): string {
    return `CREATE TYPE ${t.name} AS ENUM (${t.values.map(x => `'${x}'`).join(", ")});
    `
}

function gen_column_constraint(c: t.ColumnConstraint): string {
    switch (c.tag) {
        case "unique":
            return "UNIQUE";
        case "primary_key":
            return "PRIMARY KEY";
        case "foreign_key":
            return `REFERENCES ${c.table}(${c.column})`;

        default:
            //@ts-ignore
            throw `not implemented: ${c.tag}!`;
    }
}

function gen_default_value<T extends t.Type>(t: T, value: t.Default<T> | null | undefined): string {
    if (value === undefined || value === null) return "NULL";
    if (typeof value === "boolean") return value.toString();
    if (typeof value === "string") return `'${value}'`;
    if (typeof value === "number") return value.toString();
    if (typeof value === "object") {
        // TODO
        //@ts-ignore
        if ("raw" in value) return value.raw;
        if (t.tag =="json") return `'${JSON.stringify(value)}'::JSONB`;
    }
    if (Array.isArray(value)) return `ARRAY${JSON.stringify(value)}::${gen_type(t)}`;
    throw "not implemented!";
}

function gen_column<T extends t.Type>(column: t.Column<T>): string {
    let parts: string[] = [gen_type(column.type.type),
    ...column.constraints.map(gen_column_constraint)
    ];
    if (column.type.tag == "column_type") parts.push("NOT NULL");
    if (column.type.default !== undefined || column.type.tag == "nullable_column_type") {
        parts.push(`DEFAULT ${gen_default_value(column.type.type, column.type.default)}`);
    }
    return `${column.name} ${parts.join(" ")}`;
}

function gen_table_constraint(c: t.TableConstraint): string {
    switch (c.tag) {
        case "primary_key":
            return `PRIMARY KEY (${c.columns.join(", ")})`;
        case "unique":
            return `UNIQUE (${c.columns.join(", ")})`;
        default:
            throw "not implemented!";
    }
}

function gen_table_indexes(table: t.Table): string {
    if (table.indexes === undefined) return "";
    let indexes: string[] = [];

    for (let index of table.indexes) {
        if ("columns" in index) {
            indexes.push(`CREATE INDEX ${table.name}_${index.name} ON ${table.name} ${`USING GIN (LOWER(${index.columns.join(" || ' ' || ")}) gin_trgm_ops)`};`);
        } else {
            indexes.push(`CREATE INDEX ${table.name}_${index.name} ON ${table.name} ${index.raw};`);
        }
    }

    return indexes.join("\n");
}

function gen_table(table: t.Table): string {
    let columns_and_constraints: string[] = [];
    let column_names: string[] = [];
    for (let column of table.columns) {
        column_names.push(column.name);
        columns_and_constraints.push(
            gen_column(column)
        );
    }
    if (table.constraints) {
        for (let constraint of table.constraints) {
            columns_and_constraints.push(gen_table_constraint(constraint));
        }
    }
    return `CREATE TABLE ${table.name} (
    ${columns_and_constraints.join(",\n    ")}
);`+(table.with_history? `\n\n${gen_table(t.history_table(table))}` : "");
}

export function gen_module(module: t.Module): string {
    return `-- AUTOMATICALLY GENERATED by codegen/db, do NOT edit!
${(module.enums || []).map(gen_enum).join("\n\n")}
${module.raw_sql? module.raw_sql:""}
${module.tables.map(gen_table).join("\n\n")}
    
${module.tables.map(gen_table_indexes).join("\n\n")}`;
}