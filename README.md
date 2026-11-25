\# LedgerLite



A mini bank data platform built end to end: partner CSV files are loaded nightly with SSIS, validated and reconciled, then served through an Accounts API, payments via messaging, reports and a web UI.



\*\*LedgerLite Lab:\*\* each interview topic has a BROKEN vs FIXED scenario with measured results (see `docs/scenario-registry.md`).



\## Structure



```

LedgerLite/

├── LedgerLite/              Visual Studio solution

│   └── LedgerLite.ETL/      SSIS project (packages: \*.dtsx)

├── database/

│   ├── LedgerSource/        Master data: Partner, Customer, Account (read-only for ETL)

│   ├── LedgerStaging/       Receiving area: raw landing, FileLoad audit, ErrorRow, reconciliation

│   └── LedgerReporting/     Validated data only

├── data/samples/            Master copies of partner CSV files

├── docs/decisions/          Architecture Decision Records (ADRs)

└── .github/                 PR template

```



\## Local setup



\- SQL Server 2022 Developer, Windows authentication (no credentials in this repo)

\- Visual Studio 2026 + SQL Server Integration Services Projects 2022+

\- Runtime folders (git-ignored): `Inbox/`, `Archive/`, `Error/` at the repo root

