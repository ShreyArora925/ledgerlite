/* =============================================================
   LedgerStaging: receiving area for partner files
   PartnerTxnLanding = 1:1 copy of the CSV as text + load metadata
   FileLoad          = one audit row per file
   ErrorRow          = rejected rows with reason
   ReconciliationResult = file total vs loaded + rejected
   Re-runnable: drops and recreates the tables.
   ============================================================= */
USE master;
GO
IF DB_ID('LedgerStaging') IS NULL
    CREATE DATABASE LedgerStaging;
GO
USE LedgerStaging;
GO

DROP TABLE IF EXISTS dbo.ReconciliationResult;
DROP TABLE IF EXISTS dbo.ErrorRow;
DROP TABLE IF EXISTS dbo.PartnerTxnLanding;
DROP TABLE IF EXISTS dbo.FileLoad;
GO

CREATE TABLE dbo.FileLoad (
    FileLoadId    int IDENTITY(1,1) NOT NULL CONSTRAINT PK_FileLoad PRIMARY KEY,
    FileName      nvarchar(260)  NOT NULL,
    PartnerCode   varchar(10)    NULL,
    Status        varchar(20)    NOT NULL CONSTRAINT DF_FileLoad_Status DEFAULT ('Started')
                  CONSTRAINT CK_FileLoad_Status CHECK (Status IN ('Started','Succeeded','Failed','Skipped')),
    RowsInFile    int            NULL,
    RowsLoaded    int            NULL,
    RowsRejected  int            NULL,
    StartedAt     datetime2(3)   NOT NULL CONSTRAINT DF_FileLoad_StartedAt DEFAULT (SYSUTCDATETIME()),
    EndedAt       datetime2(3)   NULL,
    ErrorMessage  nvarchar(4000) NULL
);

CREATE TABLE dbo.PartnerTxnLanding (
    LandingId     bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_PartnerTxnLanding PRIMARY KEY,
    -- CSV columns, all text, all nullable: accept anything, validate later
    TxnRef        varchar(50)    NULL,
    AccountNumber varchar(50)    NULL,
    TxnDate       varchar(50)    NULL,
    Amount        varchar(50)    NULL,
    Currency      varchar(10)    NULL,
    TxnType       varchar(20)    NULL,
    Description   nvarchar(500)  NULL,
    -- load metadata
    FileLoadId    int            NULL CONSTRAINT FK_PartnerTxnLanding_FileLoad REFERENCES dbo.FileLoad (FileLoadId),
    FileName      nvarchar(260)  NULL,
    RowNumber     int            NULL,
    LoadDate      datetime2(3)   NOT NULL CONSTRAINT DF_PartnerTxnLanding_LoadDate DEFAULT (SYSUTCDATETIME())
);

CREATE INDEX IX_PartnerTxnLanding_FileLoadId ON dbo.PartnerTxnLanding (FileLoadId);

CREATE TABLE dbo.ErrorRow (
    ErrorRowId       bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_ErrorRow PRIMARY KEY,
    FileLoadId       int            NOT NULL CONSTRAINT FK_ErrorRow_FileLoad REFERENCES dbo.FileLoad (FileLoadId),
    LandingId        bigint         NULL,
    RowNumber        int            NULL,
    TxnRef           varchar(50)    NULL,
    ErrorColumn      varchar(50)    NULL,
    ErrorReason      nvarchar(500)  NOT NULL,
    RawData          nvarchar(max)  NULL,
    CreatedAt        datetime2(3)   NOT NULL CONSTRAINT DF_ErrorRow_CreatedAt DEFAULT (SYSUTCDATETIME())
);

CREATE TABLE dbo.ReconciliationResult (
    ReconciliationId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ReconciliationResult PRIMARY KEY,
    FileLoadId       int          NOT NULL CONSTRAINT FK_ReconciliationResult_FileLoad REFERENCES dbo.FileLoad (FileLoadId),
    RowsInFile       int          NOT NULL,
    RowsLoaded       int          NOT NULL,
    RowsRejected     int          NOT NULL,
    Result           varchar(4)   NOT NULL CONSTRAINT CK_ReconciliationResult_Result CHECK (Result IN ('PASS','FAIL')),
    CheckedAt        datetime2(3) NOT NULL CONSTRAINT DF_ReconciliationResult_CheckedAt DEFAULT (SYSUTCDATETIME())
);
GO

/* ---------- Verify: expect 4 tables ---------- */
SELECT name AS TableName FROM sys.tables ORDER BY name;