/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table Staging.dTerritorio
 * @description Tabella di staging per dimensione Territorio

 * @depends LandingDbFlorence.AnagraficaTerritorio
 * @depends Dim.Division

SELECT TOP 1 * FROM LandingDbFlorence.AnagraficaTerritorio;
SELECT TOP 1 * FROM Dim.Division;
*/

IF OBJECT_ID('Staging.dTerritorioView', N'V') IS NULL EXEC('CREATE VIEW Staging.dTerritorioView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.dTerritorioView
AS
SELECT
	-- Chiavi
	T.DivisionKey,
    T.DivisionBusinessKey,
    T.ProductBusinessKey,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.DivisionBusinessKey,
        T.ProductBusinessKey,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.ProductDescription,
        T.ProductDescription2,
        T.PPHyerarchyCode,
        T.PPLevel1Description,
        T.PPLevel2Description,
        T.PPLevel3Description,
		' '
    ))) AS ChangeHashKey,

	-- Attributi
    T.ProductDescription,
    T.ProductDescription2,
    T.PPHyerarchyCode,
    T.PPLevel1Description,
    T.PPLevel2Description,
    T.PPLevel3Description
	
FROM (

    SELECT
	    D.DivisionKey,
	    D.DivisionBusinessKey,
        ATT.CODUTENTE AS TerritorioBusinessKey,
        ATT.COGNOME AS Surname,
        ATT.NOME AS Name,
        ATT.CODUTENTEPADRE AS RegionalKeyAccountCode

    FROM LandingDbFlorence.AnagraficaTerritorio ATT
    INNER JOIN Dim.Division D ON D.DivisionBusinessKey = ATT.CODSOCIETA

) T;
GO

--DROP TABLE Staging.dTerritorio;
GO

IF OBJECT_ID('Staging.dTerritorio', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.dTerritorio FROM Staging.dTerritorioView;

	ALTER TABLE Staging.dTerritorio ADD CONSTRAINT PK_Staging_dTerritorio PRIMARY KEY CLUSTERED (DivisionBusinessKey, ProductBusinessKey);

	ALTER TABLE Staging.dTerritorio ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

	ALTER TABLE Staging.dTerritorio ALTER COLUMN ProductDescription NVARCHAR(80) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN ProductDescription2 NVARCHAR(80) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN PPHyerarchyCode NVARCHAR(12) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN PPLevel1Description NVARCHAR(50) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN PPLevel2Description NVARCHAR(50) NOT NULL;
	ALTER TABLE Staging.dTerritorio ALTER COLUMN PPLevel3Description NVARCHAR(50) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_dTerritorio
 * @description Popolamento tabella di staging per dimensione Prodotti
*/

IF OBJECT_ID('Staging.usp_Reload_dTerritorio', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_dTerritorio AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_dTerritorio
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.dTerritorio;

INSERT INTO Staging.dTerritorio
(
    DivisionKey,
    DivisionBusinessKey,
    ProductBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    ProductDescription,
    ProductDescription2,
    PPHyerarchyCode,
    PPLevel1Description,
    PPLevel2Description,
    PPLevel3Description
)
SELECT
    DivisionKey,
    DivisionBusinessKey,
    ProductBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    ProductDescription,
    ProductDescription2,
    PPHyerarchyCode,
    PPLevel1Description,
    PPLevel2Description,
    PPLevel3Description

FROM Staging.dTerritorioView;

END;
GO

EXEC Staging.usp_Reload_dTerritorio;
GO

/**
 * @table Dim.Product
 * @description Dimensione Prodotti

 * @depends Staging.dTerritorio

SELECT TOP 1 * FROM Staging.dTerritorio;
*/

--DROP TABLE Dim.Product; DROP SEQUENCE dbo.seq_Product;
GO

IF OBJECT_ID('dbo.seq_Product', 'SO') IS NULL
BEGIN

	CREATE SEQUENCE dbo.seq_Product
	AS INT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE
	CACHE 1000;

END;
GO

--DROP TABLE Fact.Sales; DROP TABLE Dim.Product;
GO

IF OBJECT_ID('Dim.Product') IS NULL
BEGIN

	SELECT TOP 0 
		-- Chiavi
        DivisionKey,
        DivisionBusinessKey,
        ProductBusinessKey,
        CAST(1 AS INT) AS ProductKey,

        -- Data warehouse
        HistoricalHashKey,
        ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid,

        -- Attributi
        ProductDescription,
        ProductDescription2,
        PPHyerarchyCode,
        PPLevel1Description,
        PPLevel2Description,
        PPLevel3Description

	INTO Dim.Product

	FROM Staging.dTerritorio;

	ALTER TABLE Dim.Product ALTER COLUMN ProductKey INT NOT NULL;

	ALTER TABLE Dim.Product ADD CONSTRAINT DFT_Dim_Product_ProductKey DEFAULT (NEXT VALUE FOR dbo.seq_Product) FOR ProductKey;

	ALTER TABLE Dim.Product ADD CONSTRAINT PK_Dim_Product PRIMARY KEY CLUSTERED (ProductKey);

    ALTER TABLE Dim.Product ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Dim.Product ALTER COLUMN IsRowValid BIT NOT NULL;

	ALTER TABLE Dim.Product ADD CONSTRAINT FK_Dim_Product_DivisionKey FOREIGN KEY (DivisionKey) REFERENCES Dim.Division (DivisionKey);	

	CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Product_DivisionBusinessKey_ProductBusinessKey ON Dim.Product (DivisionBusinessKey, ProductBusinessKey);

    INSERT INTO Dim.Product
    (
        DivisionKey,
        DivisionBusinessKey,
        ProductBusinessKey,
        ProductKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
        ProductDescription,
        ProductDescription2,
        PPHyerarchyCode,
        PPLevel1Description,
        PPLevel2Description,
        PPLevel3Description
    )
    SELECT
        D.DivisionKey,         -- DivisionKey - tinyint
        D.DivisionBusinessKey,        -- DivisionBusinessKey - char(4)
        N'',       -- ProductBusinessKey - nvarchar(18)
        -D.DivisionKey,         -- ProductKey - int
	    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            D.DivisionKey,
		    ' '
        ))) AS HistoricalHashKey,
        CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            D.DivisionKey,
		    ' '
        ))) AS ChangeHashKey,
        CURRENT_TIMESTAMP, -- DatetimeInserted - datetime
        CURRENT_TIMESTAMP, -- DatetimeUpdated - datetime
        '19000101', -- DatetimeDeleted - datetime
        1,      -- IsRowValid - bit
        N'',       -- ProductDescription - nvarchar(80)
        N'',       -- ProductDescription2 - nvarchar(80)
        N'',       -- PPHyerarchyCode - nvarchar(12)
        N'',       -- PPLevel1Description - nvarchar(50)
        N'',       -- PPLevel2Description - nvarchar(50)
        N''        -- PPLevel3Description - nvarchar(50)

    FROM Dim.Division D;

END;
GO

/**
 * @procedure Dim.usp_Merge_Product
 * @description Procedura di aggiornamento Prodotti
*/

IF OBJECT_ID('Dim.usp_Merge_Product', N'P') IS NULL EXEC('CREATE PROCEDURE Dim.usp_Merge_Product AS RETURN 0;');
GO

ALTER PROCEDURE Dim.usp_Merge_Product
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Dim.Product AS TGT
USING Staging.dTerritorio AS SRC ON (
    SRC.DivisionBusinessKey = TGT.DivisionBusinessKey
    AND SRC.ProductBusinessKey = TGT.ProductBusinessKey
)
WHEN NOT MATCHED
    THEN INSERT (
        DivisionKey,
        DivisionBusinessKey,
        ProductBusinessKey,
        --ProductKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
        ProductDescription,
        ProductDescription2,
        PPHyerarchyCode,
        PPLevel1Description,
        PPLevel2Description,
        PPLevel3Description
    )
    VALUES (
        SRC.DivisionKey,
        SRC.DivisionBusinessKey,
        SRC.ProductBusinessKey,
        --ProductKey,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CAST('19000101' AS DATETIME),
        CAST(1 AS BIT),
        SRC.ProductDescription,
        SRC.ProductDescription2,
        SRC.PPHyerarchyCode,
        SRC.PPLevel1Description,
        SRC.PPLevel2Description,
        SRC.PPLevel3Description
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP,
        TGT.ProductDescription = SRC.ProductDescription,
        TGT.ProductDescription2 = SRC.ProductDescription2,
        TGT.PPHyerarchyCode = SRC.PPHyerarchyCode,
        TGT.PPLevel1Description = SRC.PPLevel1Description,
        TGT.PPLevel2Description = SRC.PPLevel2Description,
        TGT.PPLevel3Description = SRC.PPLevel3Description
--WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Dim' AS SchemaName,
    N'Product' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.DivisionBusinessKey, Deleted.DivisionBusinessKey) AS DivisionBusinessKey,
    COALESCE(Inserted.ProductBusinessKey, Deleted.ProductBusinessKey) AS TableBusinessKey
    INTO audit.MergeLogDetails (
        SchemaName,
        TableName,
        MergeAction,
        MergeDatetime,
        DivisionBusinessKey,
        TableBusinessKey
    );

INSERT INTO audit.MergeLogDetails
(
    SchemaName,
    TableName,
    MergeAction,
    MergeDatetime,
    DivisionBusinessKey,
    TableBusinessKey
)
SELECT
    N'Dim' AS SchemaName,
    N'Product' AS TableName,
    'DELETE' AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    DST.DivisionBusinessKey,
    DST.ProductBusinessKey AS TableBusinessKey

FROM Dim.Product DST
LEFT JOIN Staging.dTerritorio SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.ProductBusinessKey = DST.ProductBusinessKey
WHERE DST.ProductKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ProductBusinessKey IS NULL;

UPDATE DST
    SET DST.IsRowValid = CAST(0 AS BIT),
    DST.DatetimeDeleted = CURRENT_TIMESTAMP

FROM Dim.Product DST
LEFT JOIN Staging.dTerritorio SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.ProductBusinessKey = DST.ProductBusinessKey
WHERE DST.ProductKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ProductBusinessKey IS NULL;

END;
GO

EXEC Dim.usp_Merge_Product;
GO

SELECT * FROM audit.MergeLogDetails;
GO
