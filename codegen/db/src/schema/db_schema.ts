import * as t from '../types';
import * as u from './utils';

const account: t.TableName = "account";

const conversation: t.TableName = "conversation";
const message: t.TableName = "message";

export const modules: t.Module[] = [
    {
        name: "base",
        raw_sql: `CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- https://stackoverflow.com/questions/57711064/fulltext-search-missing-words
CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER DATABASE rust_makerprism SET statement_timeout = '2s';

CREATE SEQUENCE id_seq;`,
        tables: [],
    },
    {
        name: "account",
        tables: [
            t.Table(account, [
                u.AutoIncrementPrimaryKey,
                u.CreatedAt,
                u.UpdatedAt,
                u.Deleted,

                t.Column("username", t.NonNullable(t.Str), { unique: true }),
            ]),
        ],
        enums: [
        ],
    },
    {
        name: "conversation",
        tables: [
            t.Table(conversation, [
                u.AutoIncrementPrimaryKey,
                u.CreatedAt,
                u.UpdatedAt,
                u.Deleted,
            ]),

            t.Table("conversation_participant", [
                u.NonNullableForeignKey("account_id", account, "id"),
                u.NonNullableForeignKey("conversation_id", conversation, "id"),

                t.Column("messages_seen_until", t.NonNullable(t.Timestamp, { raw: "NOW()" })),
            ], {
                constraints: [
                    t.TPrimaryKey(["account_id", "conversation_id"]),
                ]
            }),
        ],
        enums: [
        ],
    },
    {
        name: "message",
        tables: [
            t.Table(message, [
                u.AutoIncrementPrimaryKey,
                u.CreatedBy(),
                u.CreatedAt,
                u.UpdatedAt,
                u.Deleted,

                u.NonNullableForeignKey("conversation", conversation, "id"),
                t.Column("content", t.NonNullable(t.Str), { }),
            ]),
        ],
        enums: [
        ],
    },
];
