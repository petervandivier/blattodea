# Schemas

The schema file in this directory is modified from [this example postgresql database][1].

Files with the name pattern `{database}.schema.sql` excluding those in the `./example/` directory will be deployed during `./make/postdeploy`. `{database}` is first extracted from the file name and run as `create database {database};` so file names should be unique and the prefix should be a valid [identifier][2]. 

[1]: https://dataedo.com/samples/html/World_PostgreSQL/doc/World_(PostgreSQL_database)_11/home.html
[2]: https://www.cockroachlabs.com/docs/stable/sql-grammar.html#name
