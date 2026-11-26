/* =========================================================
   LedgerLite - M1 Step 1 - LedgerSource (master data, OLTP)
   Re-runnable: drops and recreates the database.
   ========================================================= */
USE master;
GO

IF DB_ID('LedgerSource') IS NOT NULL
BEGIN
    ALTER DATABASE LedgerSource SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LedgerSource;
END
GO

CREATE DATABASE LedgerSource;
GO

USE LedgerSource;
GO

/* ---------- Tables ---------- */
CREATE TABLE dbo.Partner
(
    PartnerId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Partner PRIMARY KEY,
    PartnerCode  VARCHAR(20)       NOT NULL CONSTRAINT UQ_Partner_PartnerCode UNIQUE,
    PartnerName  NVARCHAR(100)     NOT NULL,
    IsActive     BIT               NOT NULL CONSTRAINT DF_Partner_IsActive  DEFAULT (1),
    CreatedAt    DATETIME2(0)      NOT NULL CONSTRAINT DF_Partner_CreatedAt DEFAULT (SYSDATETIME())
);

CREATE TABLE dbo.Customer
(
    CustomerId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customer PRIMARY KEY,
    FirstName    NVARCHAR(50)      NOT NULL,
    LastName     NVARCHAR(50)      NOT NULL,
    Email        NVARCHAR(100)     NOT NULL CONSTRAINT UQ_Customer_Email UNIQUE,
    City         NVARCHAR(50)      NOT NULL,
    CreatedAt    DATETIME2(0)      NOT NULL CONSTRAINT DF_Customer_CreatedAt DEFAULT (SYSDATETIME())
);

CREATE TABLE dbo.Account
(
    AccountId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Account PRIMARY KEY,
    AccountNumber VARCHAR(20)       NOT NULL CONSTRAINT UQ_Account_AccountNumber UNIQUE,
    CustomerId    INT               NOT NULL CONSTRAINT FK_Account_Customer
                                             REFERENCES dbo.Customer (CustomerId),
    AccountType   VARCHAR(10)       NOT NULL CONSTRAINT CK_Account_AccountType
                                             CHECK (AccountType IN ('CHEQUING','SAVINGS','CREDIT')),
    Currency      CHAR(3)           NOT NULL CONSTRAINT CK_Account_Currency
                                             CHECK (Currency IN ('CAD','USD')),
    Status        VARCHAR(10)       NOT NULL CONSTRAINT CK_Account_Status
                                             CHECK (Status IN ('ACTIVE','FROZEN','CLOSED')),
    OpenedDate    DATE              NOT NULL,
    Balance       DECIMAL(18,2)     NOT NULL CONSTRAINT DF_Account_Balance DEFAULT (0)
);

/* SQL Server does NOT auto-index foreign keys - add it ourselves */
CREATE INDEX IX_Account_CustomerId ON dbo.Account (CustomerId);
GO

/* ---------- Seed: 3 partners ---------- */
INSERT INTO dbo.Partner (PartnerCode, PartnerName)
VALUES ('PARTNERA', N'Northwind Payments'),
       ('PARTNERB', N'Maple Card Services'),
       ('PARTNERC', N'Lakeshore Remittance');

/* ---------- Seed: 20 customers ---------- */
INSERT INTO dbo.Customer (FirstName, LastName, Email, City)
VALUES (N'Aarav',   N'Mehta',     N'aarav.mehta@example.com',     N'Toronto'),
       (N'Olivia',  N'Tremblay',  N'olivia.tremblay@example.com', N'Montreal'),
       (N'Liam',    N'Wong',      N'liam.wong@example.com',       N'Vancouver'),
       (N'Emma',    N'Roy',       N'emma.roy@example.com',        N'Ottawa'),
       (N'Noah',    N'Singh',     N'noah.singh@example.com',      N'Brampton'),
       (N'Ava',     N'Gagnon',    N'ava.gagnon@example.com',      N'Quebec City'),
       (N'Lucas',   N'Chen',      N'lucas.chen@example.com',      N'Markham'),
       (N'Mia',     N'Martin',    N'mia.martin@example.com',      N'Calgary'),
       (N'Ethan',   N'Patel',     N'ethan.patel@example.com',     N'Mississauga'),
       (N'Sophia',  N'Brown',     N'sophia.brown@example.com',    N'Edmonton'),
       (N'Arjun',   N'Kapoor',    N'arjun.kapoor@example.com',    N'Toronto'),
       (N'Chloe',   N'Lee',       N'chloe.lee@example.com',       N'Richmond'),
       (N'Benjamin',N'Wilson',    N'ben.wilson@example.com',      N'Halifax'),
       (N'Zoe',     N'Nguyen',    N'zoe.nguyen@example.com',      N'Winnipeg'),
       (N'Daniel',  N'Khan',      N'daniel.khan@example.com',     N'Hamilton'),
       (N'Isla',    N'Campbell',  N'isla.campbell@example.com',   N'Victoria'),
       (N'Rohan',   N'Sharma',    N'rohan.sharma@example.com',    N'Waterloo'),
       (N'Grace',   N'Taylor',    N'grace.taylor@example.com',    N'London'),
       (N'Owen',    N'Murphy',    N'owen.murphy@example.com',     N'Regina'),
       (N'Priya',   N'Desai',     N'priya.desai@example.com',     N'Oakville');

/* ---------- Seed: 30 accounts (ACC1000001 .. ACC1000030) ---------- */
WITH Numbers AS
(
    SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects
)
INSERT INTO dbo.Account (AccountNumber, CustomerId, AccountType, Currency, Status, OpenedDate, Balance)
SELECT CONCAT('ACC', 1000000 + i),
       ((i - 1) % 20) + 1,                                    -- customers 1..20, some own 2 accounts
       CASE i % 3 WHEN 0 THEN 'SAVINGS' WHEN 1 THEN 'CHEQUING' ELSE 'CREDIT' END,
       CASE WHEN i % 5 = 0 THEN 'USD' ELSE 'CAD' END,
       CASE WHEN i = 28 THEN 'FROZEN'
            WHEN i IN (29, 30) THEN 'CLOSED'
            ELSE 'ACTIVE' END,
       DATEADD(DAY, -30 * i, '2026-11-01'),
       CAST(1000 + i * 137.25 AS DECIMAL(18,2))
FROM Numbers;
GO

/* ---------- Verify ---------- */
SELECT 'Partner' AS TableName, COUNT(*) AS RowsCount FROM dbo.Partner
UNION ALL SELECT 'Customer', COUNT(*) FROM dbo.Customer
UNION ALL SELECT 'Account',  COUNT(*) FROM dbo.Account;

SELECT TOP (5) a.AccountNumber, c.FirstName, c.LastName, a.Currency, a.Status
FROM dbo.Account a
JOIN dbo.Customer c ON c.CustomerId = a.CustomerId
ORDER BY a.AccountNumber;