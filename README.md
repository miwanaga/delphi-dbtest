# Delphi 7 / BDE / InterBase 6 sample

The data access layer stays BDE: TDatabase + TTable + TDataSource + DBGrid.
IBX and FireDAC are not used. Only the storage changes from dBase to InterBase.

## Requirements

- Delphi 7 with BDE and the InterBase SQL Links driver (`INTRBASE`).
- A working local InterBase 6 engine and its compatible 32-bit `gds32.dll`.
- A writable executable directory, also accessible by the InterBase engine.

InterBase 6 requires an engine even when the GDB is on the local disk. The
application specifies only a local file path; no host or TCP/IP port is used.
This is not an embedded/serverless database, and does not require ToGo.

## Connection properties

| Component/property | Value |
| --- | --- |
| Database1.DriverName | INTRBASE |
| Database1.DatabaseName | SampleInterBase (application-local BDE connection name) |
| Database1.Params['SERVER NAME'] | Absolute path to sample.gdb beside the EXE |
| Table1.DatabaseName | SampleInterBase |
| Table1.TableName | SAMPLE (table inside the GDB) |

There is no persistent BDE alias to register. Connection identity and fixed
driver options are set in the DFM; the file path and credentials are set at
runtime. Unlike dBase, TableName does not name a file and TableType stays at
its default. SQL dialect 1 is used for InterBase 6 / BDE compatibility.

Place `Project1.ini` beside `Project1.exe` to override the sample credentials:

```ini
[InterBase]
UserName=SYSDBA
Password=masterkey
```

If the executable is renamed, use an INI file with the same base name.
The default password must match your InterBase installation.

## Initialization and editing

On form creation, an absent sample.gdb is created with the InterBase 6
`isc_create_database` client API. This small bootstrap is needed before BDE
can open the database; it is not IBX. All subsequent connections, metadata
queries, table creation, inserts and grid operations use BDE/SQL Links.

A TQuery creates SAMPLE if absent. DDL is committed before preparing inserts.
If SAMPLE is empty, three rows are inserted in one transaction, with rollback
on failure. Existing rows are preserved on restart.

| Column | SQL type |
| --- | --- |
| ID | VARCHAR(10) |
| NAME | VARCHAR(50) |
| ADDRESS | VARCHAR(100) |

TTable displays and edits SAMPLE. Posted grid changes use BDE autocommit;
closing the form posts a pending edit. Existing sample.dbf is not imported
or modified. Existing GDB files must be compatible with InterBase 6 and the
BDE SQL dialect setting; a GDB created by a newer engine may not open in IB6.

## Verification

Build using delphi-build-server: compiler `delphi-7.0`, project `Project1.dpr`,
platform `Win32`, empty configuration, mode `build`.

On the Delphi 7 / InterBase 6 machine, test first start without a sample.gdb,
restart without duplicated rows, and persistence of a posted grid edit.
If startup reports unavailable database, check the local InterBase engine and
the version of gds32.dll loaded by the executable. Switching IBX to BDE does
not remove the engine requirement.
