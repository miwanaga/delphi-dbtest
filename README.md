# Delphi 7 InterBase sample

This branch uses Delphi 7's InterBase Express (IBX): TIBDatabase,
TIBTransaction and TIBTable. BDE is no longer required.

## Requirements and connection

- Delphi 7 with IBX to build `Project1.dpr`.
- A running local InterBase server and the matching 32-bit InterBase client
  (`gds32.dll`) to run the executable.
- A writable executable directory. The InterBase service account must also
  have permission to create and access `sample.gdb` in that directory.

The database path is `sample.gdb` beside the executable. This sample uses
local InterBase access; it does not configure a remote server connection.
The database contains a table named `SAMPLE` (not a table file name).

Optional: place `Project1.ini` beside `Project1.exe` to set credentials:

```ini
[InterBase]
UserName=SYSDBA
Password=masterkey
```

The defaults above are the classic sample credentials. Set the password to
match your local InterBase installation. If the executable is renamed, use
an INI file with the same base name. No credentials are stored in the DFM.

## Initialization and editing

On form creation, the application creates the database if absent, creates
`SAMPLE` if absent, then inserts three sample rows only if the table is empty.
DDL is committed before inserts; all three seed inserts share one transaction
and roll back together on failure. Existing rows are preserved on restart.

| Column | SQL type |
| --- | --- |
| ID | VARCHAR(10) |
| NAME | VARCHAR(50) |
| ADDRESS | VARCHAR(100) |

DBGrid uses TDataSource and TIBTable. Posted edits and deletes are committed
with CommitRetaining. Closing the form posts a pending grid edit; the final
read transaction is rolled back when the form is destroyed.

This replaces DBF storage; existing `sample.dbf` files are not imported or
modified. Text uses the database's default NONE character set and the Delphi
7 ANSI client; the seed data is ASCII.

## Build and runtime checks

Use delphi-build-server with compiler `delphi-7.0`, project `Project1.dpr`,
platform `Win32`, empty configuration, and mode `build`.

Runtime checks on a machine with InterBase installed:

1. Start with no `sample.gdb`: confirm SAMPLE and three rows appear.
2. Close and restart: confirm the same three rows remain.
3. Edit a row, move to another row, close and restart: confirm persistence.
4. With an empty SAMPLE table, restart: confirm three sample rows are added.
5. With invalid credentials, confirm an error is reported without overwriting
   an existing database.
