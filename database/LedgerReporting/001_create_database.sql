/* =============================================================
   LedgerReporting: validated data only (tables added in later sessions)
   ============================================================= */
USE master;
GO
IF DB_ID('LedgerReporting') IS NULL
    CREATE DATABASE LedgerReporting;
GO