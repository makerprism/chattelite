import * as t from '../types';
import * as u from './utils';

const users: t.TableName = "users";

const conversation: t.TableName = "conversation";
const line: t.TableName = "line";
const reaction: t.TableName = "reaction";

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

                // user-defined JSON data
                t.Column("data", t.NonNullable(t.Json, {})),
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

                // user-defined JSON data stored in the conversation,
                // e.g. a chat room name or whatever
                t.Column("data", t.NonNullable(t.Json, {})),
            ]),

            t.Table("conversation_participant", [
                u.NonNullableForeignKey("user_id", users, "id"),
                u.NonNullableForeignKey("conversation_id", conversation, "id"),

                u.UpdatedAt,
                u.Deleted,

                t.Column("lines_seen_until", t.NonNullable(t.Timestamp, { raw: "NOW()" })),
            ], {
                constraints: [
                    t.TPrimaryKey(["user_id", "conversation_id"]),
                ],
                with_history: true,
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
                u.UpdatedAt, /* Note: via the server API, messages can be edited */
                u.Deleted,

                u.NonNullableForeignKey("conversation_id", conversation, "id"),

                u.NullableForeignKey("thread_line_id", line, "id"),
                u.NullableForeignKey("reply_to_line_id", line, "id"),

                // messages sent via the client API have a non-null sender
                // the server API can send messages without a sender
                u.NullableForeignKey("sender_user_id", "users", "id"),
                t.Column("message", t.NonNullable(t.Str)),
            ], {
                with_history: true,
            }),

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
        ],
    },
    
];
