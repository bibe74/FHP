/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table audit.MergeLogDetails
 * @description Dettaglio log procedure di Merge
*/

--DROP TABLE audit.MergeLogDetails;
GO

CREATE TABLE audit.MergeLogDetails (
    MergeLogDetailId BIGINT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_audit_MergeLogDetails PRIMARY KEY CLUSTERED,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    MergeAction VARCHAR(10) NOT NULL,
    MergeDatetime DATETIME NOT NULL,
    DivisionBusinessKey CHAR(4) NULL,
    TableBusinessKey NVARCHAR(255) NULL
);
GO

/**
 * @table audit.MergeLog
 * @description Riepilogo dei log delle procedure di Merge

 * @depends audit.MergeLogDetails
*/

IF OBJECT_ID('audit.MergeLogView', N'V') IS NULL EXEC('CREATE VIEW audit.MergeLogView AS SELECT 1 AS fld;');
GO

ALTER VIEW audit.MergeLogView
AS
SELECT
    CAST(MLD.MergeDatetime AS DATE) AS MergeDate,
    MLD.SchemaName,
    MLD.TableName,
    SUM(CASE WHEN MLD.MergeAction = 'INSERT' THEN 1 ELSE NULL END) AS InsertCount,
    SUM(CASE WHEN MLD.MergeAction = 'UPDATE' THEN 1 ELSE NULL END) AS UpdateCount,
    SUM(CASE WHEN MLD.MergeAction = 'DELETE' THEN 1 ELSE NULL END) AS DeleteCount

FROM audit.MergeLogDetails MLD
GROUP BY CAST(MLD.MergeDatetime AS DATE),
    MLD.SchemaName,
    MLD.TableName;
GO

--DROP TABLE audit.MergeLog;
GO

IF OBJECT_ID('audit.MergeLog', N'U') IS NULL
BEGIN

    SELECT TOP 0
        IDENTITY(BIGINT, 1, 1) AS PKMergeLog,
        MergeDate,
        SchemaName,
        TableName,
        InsertCount,
        UpdateCount,
        DeleteCount

    INTO audit.MergeLog

    FROM audit.MergeLogView;

    ALTER TABLE audit.MergeLog ADD CONSTRAINT PK_audit_MergeLog PRIMARY KEY CLUSTERED (PKMergeLog);

END;
GO

/**
 * @procedure audit.usp_CompactMergeLog
 * @description Compattamento log delle procedure di Merge
*/

IF OBJECT_ID('audit.usp_CompactMergeLog', N'P') IS NULL EXEC('CREATE PROCEDURE audit.usp_CompactMergeLog AS RETURN 0;');
GO

ALTER PROCEDURE audit.usp_CompactMergeLog
AS
BEGIN

SET NOCOUNT ON;

    INSERT INTO audit.MergeLog
    (
        MergeDate,
        SchemaName,
        TableName,
        InsertCount,
        UpdateCount,
        DeleteCount
    )
    SELECT
        MergeDate,
        SchemaName,
        TableName,
        InsertCount,
        UpdateCount,
        DeleteCount
    FROM audit.MergeLogView;

    TRUNCATE TABLE audit.MergeLogDetails;

END;
GO

EXEC audit.usp_CompactMergeLog;
GO
