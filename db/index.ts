import {migrate} from "postgres-migrations"

require('dotenv').config();

(async () => {
  const dbConfig = {
    database: process.env.DB_DATABASE || "",
    user: process.env.DB_USER || "",
    password: process.env.DB_PASSWORD || "",
    host: process.env.DB_HOST || "",
    port: parseInt(process.env.DB_PORT || ""),

    // Default: false for backwards-compatibility
    // This might change!
    ensureDatabaseExists: true,

    defaultDatabase: "postgres",
  }

  console.log(`${process.cwd()}/sql/`);

  await migrate(dbConfig, `${process.cwd()}/sql/`, {
    logger: (msg) => console.log(msg),
  });

  console.log("finished migrating");
})();
