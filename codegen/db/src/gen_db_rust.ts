import { snakeToCamel, uppercaseFirst } from './gen_utils';
import * as t from './types';


function gen_type(type: t.Type): string {
    switch (type.tag) {
        case "bool":
            return "bool";
        case "i32":
            return "i32";
        case "i64":
            return "i64";
        case "str":
            return "String";
        case "f32":
            return "f32";

        case "f64":
            return "f64";

        case "json":
            return "serde_json::Value";

        case "byte_array":
            return "Vec<u8>";

        case "timestamp":
            return "chrono::DateTime<chrono::offset::Utc>";

        case "date":
            return "chrono::NaiveDate";

        case "uuid":
            return "uuid::Uuid";

        case "serial_i32":
            return "i32";

        case "serial_i64":
            return "i64";

        case "array":
            return `Vec<${gen_type(type.type)}>`;

        case "enum":
            return `crate::${type.name}`;

        default:
            throw `not implemented: ${type.tag}!`;
    }
}

function nullable(t: string, nullable: boolean): string {
    if (nullable) {
        if (t.startsWith("&'a ")) {
            if (t == "&'a str") return "&'a Option<String>";
            return `&'a Option<${t.slice(4, t.length)}>`;
        }
        return `Option<${t}>`;
    }
    return t;
}

function gen_column_type<T extends t.Type>(table: t.Table, column: t.Column<T>): string {
    let id_type_name = column_id_type_name(table, column);
    if (id_type_name) {
        return uppercaseFirst(snakeToCamel(table.name + "_" + column.name));
    }
    let t;
    //@ts-ignore
    let fk_constraint: t.ColumnConstraintForeignKey | undefined = column.constraints.find(c => c.tag == "foreign_key");
    if (fk_constraint) {
        t = uppercaseFirst(snakeToCamel(fk_constraint.table + "_" + fk_constraint.column));
    } else {
        t = gen_type(column.type.type);
    }

    return nullable(t, column.type.tag == "nullable_column_type");
}


function gen_insert_type(type: t.Type, nullable: boolean): string {
    switch (type.tag) {
        case "bool":
            if (nullable) {
                return "Option<bool>";
            } else {
                return "bool";
            }
        case "i32":
            if (nullable) {
                return "Option<i32>";
            } else {
                return "i32";
            }
        case "i64":
            if (nullable) {
                return "Option<i64>";
            } else {
                return "i64";
            }
        case "str":
            if (nullable) {
                return "Option<&'a String>";
            } else {
                return "&'a str";
            }
        case "f32":
            if (nullable) {
                return "Option<f32>";
            } else {
                return "f32";
            }

        case "f64":
            if (nullable) {
                return "Option<f64>";
            } else {
                return "f64";
            }

        case "json":
            // TODO: enforce the correct type of json value here, after we add proper json types
            if (nullable) {
                return "Option<serde_json::Value>";
            } else {
                return "serde_json::Value";
            }

        case "byte_array":
            if (nullable) {
                return "Option<&'a Vec<u8>>";
            } else {
                return "&'a [u8]";
            }

        case "timestamp":
            if (nullable) {
                return "Option<&'a chrono::DateTime<chrono::offset::Utc>>";
            } else {
                return "&'a chrono::DateTime<chrono::offset::Utc>";
            }

        case "date":
            if (nullable) {
                return "Option<&'a chrono::NaiveDate>";
            } else {
                return "&'a chrono::NaiveDate";
            }

        case "uuid":
            if (nullable) {
                return "Option<&'a uuid::Uuid>";
            } else {
                return "&'a uuid::Uuid";
            }

        case "array":
            if (nullable) {
                return `Option<&'a Vec<${gen_type(type.type)}>>`;
            } else {
                return `&'a [${gen_type(type.type)}]`;
            }

        case "serial_i32":
            return "XXXi32XXX";

        case "serial_i64":
            return "XXXi64XXX";

        case "enum":
            if (nullable) {
                return `Option<crate::${type.name}>`;
            } else {
                return `crate::${type.name}`;
            }
        //return `&'a ${type.name}`;
        // when we understand how to encode this type automatically via SQLx, we can do it this way.

        default:
            throw `not implemented: ${type.tag}!`;
    }
}


function gen_update_type(type: t.Type, nullable: boolean): string {
    switch (type.tag) {
        case "bool":
            if (nullable) {
                return "Option<Option<bool>>";
            } else {
                return "Option<bool>";
            }
        case "i32":
            if (nullable) {
                return "Option<Option<i32>>";
            } else {
                return "Option<i32>";
            }
        case "i64":
            if (nullable) {
                return "Option<Option<i64>>";
            } else {
                return "Option<i64>";
            }
        case "str":
            if (nullable) {
                return "Option<Option<&'a String>>";
            } else {
                return "Option<&'a String>";
            }
        case "f32":
            if (nullable) {
                return "Option<Option<f32>>";
            } else {
                return "Option<f32>";
            }

        case "f64":
            if (nullable) {
                return "Option<Option<f64>>";
            } else {
                return "Option<f64>";
            }

        case "json":
            // TODO: enforce the correct type of json value here, after we add proper json types
            if (nullable) {
                return "Option<Option<serde_json::Value>>";
            } else {
                return "Option<serde_json::Value>";
            }

        case "byte_array":
            if (nullable) {
                return "Option<Option<&'a Vec<u8>>>";
            } else {
                return "Option<&'a Vec<u8>>";
            }

        case "timestamp":
            if (nullable) {
                return "Option<Option<&'a chrono::DateTime<chrono::offset::Utc>>>";
            } else {
                return "Option<&'a chrono::DateTime<chrono::offset::Utc>>";
            }

        case "date":
            if (nullable) {
                return "Option<Option<&'a chrono::NaiveDate>>";
            } else {
                return "Option<&'a chrono::NaiveDate>";
            }

        case "uuid":
            if (nullable) {
                return "Option<Option<&'a uuid::Uuid>>";
            } else {
                return "Option<&'a uuid::Uuid>";
            }

        case "array":
            if (nullable) {
                return `Option<Option<&'a Vec<${gen_type(type.type)}>>>`;
            } else {
                return `Option<&'a Vec<${gen_type(type.type)}>>`;
            }

        case "serial_i32":
            return "XXXi32XXX";

        case "serial_i64":
            return "XXXi64XXX";

        case "enum":
            if (nullable) {
                return `Option<Option<crate::${type.name}>>`;
            } else {
                return `Option<crate::${type.name}>`;
            }
        //return `&'a ${type.name}`;
        // when we understand how to decode this type automatically via SQLx, we can do it this way.

        default:
            throw `not implemented: ${type.tag}!`;
    }
}

function insert_column_type_is_option<T extends t.Type>(column: t.Column<T>): boolean {
    return column.type.tag == "nullable_column_type";
}

function gen_insert_column_type<T extends t.Type>(column: t.Column<T>): string {
    let t;
    //@ts-ignore
    let fk_constraint: t.ColumnConstraintForeignKey | undefined = column.constraints.find(c => c.tag == "foreign_key");
    if (fk_constraint) {
        return nullable(uppercaseFirst(snakeToCamel(fk_constraint.table + "_" + fk_constraint.column)), insert_column_type_is_option(column));
    } else {
        return gen_insert_type(column.type.type, insert_column_type_is_option(column));
    }
}

function gen_insert_arg_for_column<T extends t.Type>(column: t.Column<T>): string {
    return (column.type.tag == "nullable_column_type" && gen_insert_column_type(column).startsWith("&") ? "*" : "")
        + "new."
        + column.name
        + (column.type.type.tag == "enum" ? " as _" : "");
}

function gen_select_arg_for_column<T extends t.Type>(column: t.Column<T>): string {
    return column.name
        + (column.type.type.tag == "enum" ? ` as "${column.name}:crate::${column.type.type.name}"` : "");
}

function update_column_type_is_option(table: t.Table, column: t.Column<any>): boolean {
    return column.name !== "updated_by" && (!t.is_part_of_primary_key(table, column));
}
function gen_update_column_type<T extends t.Type>(table: t.Table, column: t.Column<T>): string {
    // my own primary key
    let id_type_name = column_id_type_name(table, column);
    if (id_type_name) {
        return uppercaseFirst(snakeToCamel(table.name + "_" + column.name));
    }
    //@ts-ignore
    let fk_constraint: t.ColumnConstraintForeignKey | undefined = column.constraints.find(c => c.tag == "foreign_key");
    if (fk_constraint) {
        if (update_column_type_is_option(table, column)) {
            return `Option<${nullable(uppercaseFirst(snakeToCamel(fk_constraint.table + "_" + fk_constraint.column)), insert_column_type_is_option(column))}>`;
        } else {
            return nullable(uppercaseFirst(snakeToCamel(fk_constraint.table + "_" + fk_constraint.column)), insert_column_type_is_option(column));
        }
    } else {
        return gen_update_type(column.type.type, insert_column_type_is_option(column));
    }
}

function gen_model_field<T extends t.Type>(table: t.Table, column: t.Column<T>): string {
    return `pub ${column.name}: ${gen_column_type(table, column)}`;
}


function primary_keys_type(table: t.Table): string {
    let primary_keys = t.primary_keys(table);

    function id_type_or_gen_type(c: t.Column<any> | undefined): string {
        if (c === undefined) throw "primary key column not found!";
        return gen_column_type(table, c);
    }

    return primary_keys.length == 1 ?
        id_type_or_gen_type(table.columns.find(c => c.name == primary_keys[0])) :
    `(${primary_keys.map(k => id_type_or_gen_type(table.columns.find(c => c.name == k)))})`
    ;
}

function table_name(table: t.Table): string {
    return uppercaseFirst(snakeToCamel(table.name));
}

function gen_insert(table: t.Table): { insert_type_declaration: string, insert_function_declaration: string; } {
    let name = uppercaseFirst(snakeToCamel(table.name));
    let primary_keys = t.primary_keys(table);
    let insert_columns = table.columns.filter(c => c.name != "id" && c.name != "deleted" && (c.type.default === undefined || !t.default_is_raw(c.type.default)));
    let insert_has_lifetime = insert_columns.some(c => gen_insert_type(c.type.type, insert_column_type_is_option(c)).includes("'a"));

    let insert_args = insert_columns.map((c, i) => {
        return {
            name: c.name,
            value: "$" + (i+1)
        }
    });

    if (insert_args.length == 0) {
        let sql_partial = `INSERT INTO ${table.name}
                        VALUES (DEFAULT)`
        return {
            insert_type_declaration: ``,
            insert_function_declaration: `pub async fn insert_returning_pk(
                    transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
                ) -> Result<${primary_keys_type(table)}, sqlx::Error> {
                    sqlx::query!(
                        "
                        ${sql_partial}
                        RETURNING ${primary_keys.length == 1 ? primary_keys[0] : `${primary_keys.join(", ")}`}
                        ",
                        ${insert_columns.map(gen_insert_arg_for_column).join(",\n            ")}
                    )
                    .fetch_one(&mut *transaction)
                    .await
                    .map(|r| ${primary_keys.length == 1? `r.${primary_keys[0]}`: `(${primary_keys.map(k => `r.${k}`).join(", ")})`})
                }
                
                pub async fn insert(
                    transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
                ) -> Result<${name}, sqlx::Error> {
                    sqlx::query_as!(${name},
                        r#"
                        ${sql_partial}
                        RETURNING ${table.columns.map(gen_select_arg_for_column).join(", ")}
                        "#,
                        ${insert_columns.map(gen_insert_arg_for_column).join(",\n            ")}
                    )
                    .fetch_one(&mut *transaction)
                    .await
                }`
        }
    }

    let sql_partial =  
        `INSERT INTO ${table.name} (${insert_args.map(a => a.name).join(", ")})
                VALUES (${insert_args.map(a => a.value).join(", ")})`;

    return {
        insert_type_declaration: `#[derive(Debug)]
pub struct Insert${name}${insert_has_lifetime ? "<'a>" : ""} {
    ${insert_columns.map(c => `pub ${c.name}: ` + gen_insert_column_type(c)).join(",\n    ")}
}`, insert_function_declaration: `pub async fn insert_returning_pk(
        transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        new: Insert${name}${insert_has_lifetime ? "<'_>" : ""},
    ) -> Result<${primary_keys_type(table)}, sqlx::Error> {
        sqlx::query!(
            "
            ${sql_partial}
            RETURNING ${primary_keys.length == 1 ? primary_keys[0] : `${primary_keys.join(", ")}`}
            ",
            ${insert_columns.map(gen_insert_arg_for_column).join(",\n            ")}
        )
        .fetch_one(&mut *transaction)
        .await
        .map(|r| ${primary_keys.length == 1? `r.${primary_keys[0]}`: `(${primary_keys.map(k => `r.${k}`).join(", ")})`})
    }
    
    pub async fn insert(
        transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        new: Insert${name}${insert_has_lifetime ? "<'_>" : ""},
    ) -> Result<${name}, sqlx::Error> {
        sqlx::query_as!(${name},
            r#"
            ${sql_partial}
            RETURNING ${table.columns.map(gen_select_arg_for_column).join(", ")}
            "#,
            ${insert_columns.map(gen_insert_arg_for_column).join(",\n            ")}
        )
        .fetch_one(&mut *transaction)
        .await
    }`};
}


function gen_update_arg_for_column<T extends t.Type>(table: t.Table, column: t.Column<T>): string {
    return "update."
        + column.name
        + (update_column_type_is_option(table, column) ? ".as_ref()" : "");
}

function gen_column_update(table: t.Table, column: t.Column<any>): string {
    let is_primary_key = t.is_part_of_primary_key(table, column);
    if (is_primary_key) {
        return `q.where_("${column.name}", ${gen_update_arg_for_column(table, column)});`;
    }
    return `q.${update_column_type_is_option(table, column) ? "update_if_some" : "update"}("${column.name}", ${gen_update_arg_for_column(table, column)});`;
}

function gen_history_update(table: t.Table): string {
    let history_table = t.history_table(table);
    let primary_keys: string[] = t.primary_keys(table);
    return `sqlx::query!(r#"INSERT INTO ${history_table.name} (${history_table.columns.map(c => c.name).join(", ")})
            SELECT ${history_table.columns.map(c => c.name).join(", ")} FROM ${table.name} WHERE ${primary_keys.map((k, i) => `${k} = $${i + 1}`).join(" AND ")}"#,
            ${primary_keys.map((k) => `update.${k}`).join(",\n            ")}
        ).execute(&mut *transaction).await?;
`;
}

function gen_update(table: t.Table): { update_type_declaration: string, update_function_declaration: string; } {
    let name = uppercaseFirst(snakeToCamel(table.name));
    let update_columns = table.columns.filter(c => c.name != "created_by" && c.name != "updated_at" && c.name != "created_at");
    let update_has_lifetime = update_columns.some(c => gen_update_type(c.type.type, update_column_type_is_option(table, c)).includes("'a"));

    if (update_columns.length == 0) return { update_type_declaration: "", update_function_declaration: "" };

    return {
        update_type_declaration: `#[derive(Debug)]
pub struct Update${name}${update_has_lifetime ? "<'a>" : ""} {
    ${update_columns.map(c => `pub ${c.name}: ` + gen_update_column_type(table, c)).join(",\n    ")}
}`, update_function_declaration: `pub async fn update(
        transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
        update: Update${name}${update_has_lifetime ? "<'_>" : ""},
    ) -> Result<(), sqlx::Error> {
        ${table.with_history ? gen_history_update(table) : ""}
        let mut q = crate::update_builder::UpdateBuilder::new("${table.name}");
        ${update_columns.map(c => gen_column_update(table, c)).join("\n        ")}

        q.execute(&mut *transaction).await
    }`};
}

function gen_query_by_id(table: t.Table): string {
    let primary_keys = t.primary_keys(table);
    
    return `pub async fn get_by_pk(
        executor: impl sqlx::Executor<'_, Database = sqlx::Postgres>,
        pk: ${primary_keys_type(table)},
    ) -> Result<${table_name(table)}, sqlx::Error> {
        sqlx::query_as!(${table_name(table)},
            r#"
            SELECT 
                ${table.name}.${table.columns.map(gen_select_arg_for_column).join(",\n                ")}
            FROM ${table.name}
            WHERE
                ${primary_keys.map((k,i) => `${k} = $${i+1}`).join (" AND ")}
            "#,
            ${primary_keys.length == 1? "pk" : primary_keys.map((k,i) => `pk.${i}`).join(", ")}
        )
        .fetch_one(executor)
        .await
    }`
}

function gen_sqlx_type(name: string, table: t.Table): string {
    return `#[derive(Debug, sqlx::FromRow, Clone)]
pub struct ${name} {
    ${table.columns.map(c => gen_model_field(table, c)).join(",\n    ")}
}

impl<'r> sqlx::Decode<'r, sqlx::Postgres> for ${name}
where
    String: sqlx::Type<sqlx::Postgres>,
    Option<String>: sqlx::Decode<'r, sqlx::Postgres>,
    Option<String>: sqlx::Type<sqlx::Postgres>,
{
    fn decode(
        value: sqlx::postgres::PgValueRef<'r>,
    ) -> Result<${name}, Box<dyn std::error::Error + 'static + Send + Sync>> {
        let mut decoder = sqlx::postgres::types::PgRecordDecoder::new(value)?;

        ${table.columns.map(c => `let ${c.name} = decoder.try_decode::<${gen_column_type(table, c)}>()?;`).join("\n        ")}

        Ok(${name} {
            ${table.columns.map(c => c.name).join(",\n            ")}
        })
    }
}

impl sqlx::Type<sqlx::Postgres> for ${name} {
    fn type_info() -> sqlx::postgres::PgTypeInfo {
        sqlx::postgres::PgTypeInfo::with_name("${name}")
    }
}`;
}

function gen_indexes(name: string, table: t.Table): string {
    let r: string[] = [];

    if (table.indexes === undefined) return "";

    for(let index of table.indexes) {
        if ("columns" in index) {
            r.push(`pub static ${(name+"_"+index.name+"_index").toUpperCase()}: &str = "LOWER(${index.columns.join(" || ' ' || ")})";`)
        }
    }
    return r.join("\n");
}

function gen_model(table: t.Table): string {
    let name = uppercaseFirst(snakeToCamel(table.name));

    let sqlx_type_declaration = gen_sqlx_type(name, table);
    let index_constant_declaration = gen_indexes(name, table);

    let { insert_type_declaration, insert_function_declaration } = gen_insert(table);
    let { update_type_declaration, update_function_declaration } = gen_update(table);
    let query_by_id_function_declaration = gen_query_by_id(table);

    return `${sqlx_type_declaration}

${index_constant_declaration}

${insert_type_declaration}
${update_type_declaration}

impl ${name} {
    ${insert_function_declaration}
    ${update_function_declaration}
    ${query_by_id_function_declaration}
}
`;
}


function gen_enum(e: t.Enum): string {
    return `#[derive(Debug, Clone, Copy, sqlx::Type, PartialEq)]pub enum ${e.name} {
    ${e.values.map((n) => `${n}`).join(",\n    ")}
}
`;
}

function column_id_type_name(t: t.Table, c: t.Column<any>): string | null {
    let pk_constraint = c.constraints.findIndex(c => c.tag == "primary_key");
    if (pk_constraint != -1) {
        if (c.constraints.findIndex(c => c.tag == "foreign_key") == -1) {
            let id_type_name = uppercaseFirst(snakeToCamel(t.name + "_" + c.name));
            return id_type_name;
        }
    }
    return null;
}

export function gen_id_types(tables: t.Table[]): string[] {
    let id_types: string[] = [];

    // every primary key that is not already a foreign key to another table's primary key gets a type,
    // so we can easily see how tables link to each other

    for (let t of tables) {
        for (let c of t.columns) {
            let id_type_name = column_id_type_name(t, c);
            if (id_type_name !== null) {
                id_types.push(`pub type ${id_type_name} = ${gen_type(c.type.type)};`);
            }
        }
    }

    return id_types;
}

export function gen_module(module: t.Module): string {
    return `// AUTOMATICALLY GENERATED by codegen/db, do NOT edit!
use crate::id_types::*;

${(module.enums || []).map(gen_enum).join("\n\n")}
${module.tables.map(gen_model).join("\n\n")}`;
}
