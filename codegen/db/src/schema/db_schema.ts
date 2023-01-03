import * as t from '../types';
import * as u from './utils';

const users: t.TableName = "users";

const conversation: t.TableName = "conversation";
const line: t.TableName = "line";
const message: t.TableName = "message";
const reaction: t.TableName = "reaction";
const system_event: t.TableName = "system_event";
const SystemEventKind: t.Enum = t.Enum("SystemEventKind", [
    "Join",
    "Leave"
]);

export const modules: t.Module[] = [
    {
        name: "base",
        raw_sql: `CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- https://stackoverflow.com/questions/57711064/fulltext-search-missing-words
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE SEQUENCE id_seq;`,
        tables: [],
    },
    {
        name: "users",
        tables: [
            t.Table(users, [
                u.AutoIncrementPrimaryKey,
                u.CreatedAt,
                u.UpdatedAt,
                u.Deleted,

                t.Column("public_facing_id", t.NonNullable(t.Str), { unique: true }),
                t.Column("display_name", t.NonNullable(t.Str)),
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
            ]),

            t.Table("conversation_participant", [
                u.NonNullableForeignKey("user_id", users, "id"),
                u.NonNullableForeignKey("conversation_id", conversation, "id"),

                t.Column("lines_seen_until", t.NonNullable(t.Timestamp, { raw: "NOW()" })),
            ], {
                constraints: [
                    t.TPrimaryKey(["user_id", "conversation_id"]),
                ]
            }),
        ],
        enums: [
        ],
    },
    {
        name: "lines",
        tables: [
            t.Table(line, [
                u.AutoIncrementPrimaryKey,
                u.CreatedAt,
                u.UpdatedAt,
                u.Deleted,

                u.NonNullableForeignKey("conversation_id", conversation, "id"),

                u.NullableForeignKey("thread_line_id", line, "id"),
                u.NullableForeignKey("reply_to_line_id", line, "id"),

            ]),

            t.Table(message, [
                u.NonNullableForeignKey("line_id", line, "id", { primary_key: true }),
                u.CreatedBy(),

                t.Column("content", t.NonNullable(t.Str)),
            ]),

            t.Table(system_event, [
                u.NonNullableForeignKey("line_id", line, "id", { primary_key: true }),

                t.Column("kind", t.NonNullable(SystemEventKind)),

                // join / leave
                u.NullableForeignKey("user_id", users, "id"),
            ]),

            t.Table(reaction, [
                u.NonNullableForeignKey("line_id", line, "id"),
                u.CreatedBy(),
                t.Column("reaction", t.NonNullable(t.I64)),
            ], {
                constraints: [
                    t.TPrimaryKey(["line_id", "created_by"]),
                ]
            }),


        ],
        enums: [
            SystemEventKind,
        ],
    },
    
];
