import * as t from "../types";

export function NonNullableForeignKey(name: string, table: string, column: string, opts?: { default?: t.Default<t.I64>, primary_key?: boolean; }): t.Column<any> {
    if (opts === undefined) opts = {};
    return t.Column(name, t.NonNullable(t.I64, opts.default), { foreign_key: t.CForeignKey(table, column), primary_key: opts.primary_key });    
}

export function NullableForeignKey(name: string, table: string, column: string, default_value?: t.Default<t.I64>): t.Column<t.I64> {
    return t.Column(name, t.Nullable(t.I64, default_value), { foreign_key: t.CForeignKey(table, column) });    
}

export function AccountForeignKey(name: string, opts?: { primary_key?: boolean; }) {
    if (opts === undefined) opts = {};
    return NonNullableForeignKey(name, "account", "id", opts);
}
export const CreatedAt = t.Column("created_at", t.NonNullable(t.Timestamp, { raw: "NOW()" }));
export const UpdatedAt = t.Column("updated_at", t.NonNullable(t.Timestamp, { raw: "NOW()" }));
export const Deleted = t.Column("deleted", t.NonNullable(t.Bool, false));

export function CreatedBy(opts?: { primary_key?: boolean; }) {
    return AccountForeignKey("created_by", opts );
}
export function UpdatedBy(opts?: { primary_key?: boolean; }) {
    return AccountForeignKey("updated_by", opts );
}
export const CRUD: t.Column<any>[] = [
    CreatedBy({}),
    UpdatedBy({}),
    CreatedAt,
    UpdatedAt,
    Deleted,
];


export const IndividualAutoIncrementPrimaryKey = t.Column("id", t.NonNullable(t.SerialI64), { primary_key: true });
export const AutoIncrementPrimaryKey = t.Column("id", t.NonNullable(t.I64, {raw: "nextval('id_seq')"} ), { primary_key: true });

export function NullableForeignKeyWithTextFallback(name:string, table: string, column: string): t.Column<any>[] {
    return [
        t.Column(name+"_text", t.NonNullable(t.Str, "")),
        NullableForeignKey(name+"_id", table, column),
    ]
}
