# Delphi 7 BDE / dBase sample

Open and build `Project1.dpr` with Delphi 7. BDE must be installed to run it.
For a command-line full build, run the following in this directory using the
Delphi 7 compiler (adjust the installation path as needed):

```bat
"C:\Program Files (x86)\Borland\Delphi7\Bin\dcc32.exe" -B Project1.dpr
```

On form creation, the application creates `sample.dbf` beside the executable
if it does not already exist. This directory must be writable.

| Field | Type | Length |
| --- | --- | --- |
| ID | String (dBase character) | 10 |
| NAME | String (dBase character) | 50 |
| ADDRESS | String (dBase character) | 100 |

An empty table receives three sample records. Existing nonempty tables are
preserved without adding duplicate sample records on subsequent starts.
The table is opened and displayed through the existing DataSource and DBGrid.

To check runtime behavior, start once without `sample.dbf` and confirm three
rows and the three columns appear. Close and restart to confirm the row count
remains three. Runtime verification requires Delphi 7 / BDE.
