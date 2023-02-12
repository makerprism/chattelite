use sqlx::Row;
use sqlx::{postgres::PgArguments, Arguments, Encode};

pub struct UpdateBuilder {
    table: String,
    next_arg: usize,
    updates: Vec<String>,
    wheres: Vec<String>,
    args: sqlx::postgres::PgArguments,
    args_debug: Vec<String>,
}

impl UpdateBuilder {
    pub fn new(table: &str) -> UpdateBuilder {
        UpdateBuilder {
            table: table.to_owned(),
            updates: vec!["updated_at = NOW()".to_string()],
            wheres: Vec::new(),
            args: sqlx::postgres::PgArguments::default(),
            next_arg: 1,
            args_debug: Vec::new(),
        }
    }
    fn add_arg<'q, T: 'q>(&mut self, arg: T)
    where
        T: Encode<'q, <PgArguments as Arguments<'q>>::Database>
            + sqlx::Type<<PgArguments as Arguments<'q>>::Database>
            + std::marker::Send
            + std::fmt::Debug,
    {
        self.args_debug.push(format!("{:?}", &arg));
        self.args.add(arg);
        self.next_arg += 1;
    }

    pub fn update<'q, T: 'q>(&mut self, field_name: &str, arg: T) -> &mut UpdateBuilder
    where
        T: Encode<'q, <PgArguments as Arguments<'q>>::Database>
            + sqlx::Type<<PgArguments as Arguments<'q>>::Database>
            + std::marker::Send
            + std::fmt::Debug,
    {
        self.updates
            .push(format!("{} = ${}", field_name, self.next_arg));
        self.add_arg(arg);
        self
    }

    pub fn update_if_some<'q, T: 'q>(
        &mut self,
        field_name: &str,
        arg: Option<T>,
    ) -> &mut UpdateBuilder
    where
        T: Encode<'q, <PgArguments as Arguments<'q>>::Database>
            + sqlx::Type<<PgArguments as Arguments<'q>>::Database>
            + std::marker::Send
            + std::fmt::Debug,
    {
        if let Some(a) = arg {
            self.updates
                .push(format!("{} = ${}", field_name, self.next_arg));
            self.add_arg(a);
        }
        self
    }

    pub fn where_<'q, T: 'q>(&mut self, field_name: &str, arg: T) -> &mut UpdateBuilder
    where
        T: Encode<'q, <PgArguments as Arguments<'q>>::Database>
            + sqlx::Type<<PgArguments as Arguments<'q>>::Database>
            + std::marker::Send
            + std::fmt::Debug,
    {
        self.wheres
            .push(format!("{} = ${}", field_name, self.next_arg));
        self.add_arg(arg);
        self
    }

    pub fn where_any<'q, T: 'q>(&mut self, field_name: &str, arg: T) -> &mut UpdateBuilder
    where
        T: Encode<'q, <PgArguments as Arguments<'q>>::Database>
            + sqlx::Type<<PgArguments as Arguments<'q>>::Database>
            + std::marker::Send
            + std::fmt::Debug,
    {
        self.wheres
            .push(format!("{} = ANY(${})", field_name, self.next_arg));
        self.add_arg(arg);
        self
    }

    pub async fn execute(
        self,
        transaction: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    ) -> Result<chrono::DateTime<chrono::Utc>, sqlx::Error> {
        let query = format!(
            r#"
            UPDATE
                {}
            SET 
                {}
            WHERE
                {}
            RETURNING
                updated_at
            "#,
            &self.table,
            &self.updates.join(","),
            &self.wheres.join(" AND "),
        );

        println!("query: {}\nargs: {:?}", query, &self.args_debug);

        Ok(sqlx::query_with(&query, self.args)
            .fetch_one(&mut *transaction)
            .await?.try_get(0)?)
    }
}
