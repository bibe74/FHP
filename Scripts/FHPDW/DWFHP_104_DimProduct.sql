/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table LandingDbFlorence.AnagraficaProdotti
 * @description Anagrafica prodotti

 * @depends DBFlorencePP.dbo._TxPP_AnagraficaProdotti

SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_AnagraficaProdotti;
*/

IF OBJECT_ID('LandingDbFlorence.AnagraficaProdottiView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.AnagraficaProdottiView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.AnagraficaProdottiView
AS
SELECT
	-- Chiavi
	T.CODSOCIETA,
    T.CODART_F,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
		T.CODSOCIETA,
        T.CODART_F,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.DESART1,
        T.DESC_ART,
        T.COD_LIV_3,
        T.DESC_LIV_3,
        T.COD_LIV_2,
        T.DESC_LIV_2,
        T.COD_LIV_1,
        T.DESC_LIV_1,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Attributi
    T.DESART1,
    T.DESC_ART,
    T.COD_LIV_3,
    T.DESC_LIV_3,
    T.COD_LIV_2,
    T.DESC_LIV_2,
    T.COD_LIV_1,
    T.DESC_LIV_1
	
FROM (

    SELECT
        AP.CODSOCIETA,
	    AP.CODART_F,
	    AP.DESART1,
	    AP.DESC_ART,
	    AP.COD_LIV_3,
	    AP.DESC_LIV_3,
	    AP.COD_LIV_2,
	    AP.DESC_LIV_2,
	    AP.COD_LIV_1,
	    AP.DESC_LIV_1

    FROM DBFlorencePP.dbo._TxPP_AnagraficaProdotti AP

) T;
GO

--DROP TABLE LandingDbFlorence.AnagraficaProdotti;
GO

IF OBJECT_ID('LandingDbFlorence.AnagraficaProdotti', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.AnagraficaProdotti FROM LandingDbFlorence.AnagraficaProdottiView;

END;
GO

/**
 * @procedure usp_Merge_AnagraficaProdotti
 * @description Sincronizzazione AnagraficaProdotti
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_AnagraficaProdotti', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaProdotti AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaProdotti
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.AnagraficaProdotti AS DST
USING LandingDbFlorence.AnagraficaProdottiView AS SRC
ON SRC.CODSOCIETA = DST.CODSOCIETA AND SRC.CODART_F = DST.CODART_F
WHEN NOT MATCHED
    THEN INSERT (
        CODSOCIETA,
        CODART_F,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        DESART1,
        DESC_ART,
        COD_LIV_3,
        DESC_LIV_3,
        COD_LIV_2,
        DESC_LIV_2,
        COD_LIV_1,
        DESC_LIV_1
    )
    VALUES (
        SRC.CODSOCIETA,
        SRC.CODART_F,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        SRC.DatetimeInserted,
        SRC.DatetimeUpdated,
        SRC.DatetimeDeleted,
        SRC.DESART1,
        SRC.DESC_ART,
        SRC.COD_LIV_3,
        SRC.DESC_LIV_3,
        SRC.COD_LIV_2,
        SRC.DESC_LIV_2,
        SRC.COD_LIV_1,
        SRC.DESC_LIV_1
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
        DST.ChangeHashKey = SRC.ChangeHashKey,
        DST.DatetimeUpdated = SRC.DatetimeUpdated,
        DST.DESART1 = SRC.DESART1,
        DST.DESC_ART = SRC.DESC_ART,
        DST.COD_LIV_3 = SRC.COD_LIV_3,
        DST.DESC_LIV_3 = SRC.DESC_LIV_3,
        DST.COD_LIV_2 = SRC.COD_LIV_2,
        DST.DESC_LIV_2 = SRC.DESC_LIV_2,
        DST.COD_LIV_1 = SRC.COD_LIV_1,
        DST.DESC_LIV_1 = SRC.DESC_LIV_1
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'AnagraficaProdotti' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.CODSOCIETA, Deleted.CODSOCIETA) AS DivisionBusinessKey,
    COALESCE(Inserted.CODART_F, Deleted.CODART_F) AS TableBusinessKey
    INTO audit.MergeLogDetails (
        SchemaName,
        TableName,
        MergeAction,
        MergeDatetime,
        DivisionBusinessKey,
        TableBusinessKey
    );

END;
GO

EXEC LandingDbFlorence.usp_Merge_AnagraficaProdotti;
GO

SELECT * FROM LandingDbFlorence.AnagraficaProdotti;
GO

/**
 * @table LandingDbFlorence.GPS
 * @description Anagrafica gruppo prodotti (Attacco)

 * @depends DBFlorencePP.dbo.GPS

SELECT TOP 100 * FROM DBFlorencePP.dbo.GPS;
*/

IF OBJECT_ID('LandingDbFlorence.GPSView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.GPSView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.GPSView
AS
SELECT
	-- Chiavi
    T.CodProd,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CodProd,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.Gruppo,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Attributi
    T.Gruppo
	
FROM (

    SELECT
        TT.CodProd,
		TT.Gruppo

    FROM DBFlorencePP.dbo.GPS TT

) T;
GO

--DROP TABLE LandingDbFlorence.GPS;
GO

IF OBJECT_ID('LandingDbFlorence.GPS', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.GPS FROM LandingDbFlorence.GPSView;

END;
GO

/**
 * @procedure usp_Merge_GPS
 * @description Sincronizzazione GPS
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_GPS', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_GPS AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_GPS
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.GPS AS DST
USING LandingDbFlorence.GPSView AS SRC
ON SRC.CodProd = DST.CodProd
WHEN NOT MATCHED
    THEN INSERT (
        CodProd,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        Gruppo
    )
    VALUES (
        SRC.CodProd,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        SRC.DatetimeInserted,
        SRC.DatetimeUpdated,
        SRC.DatetimeDeleted,
        SRC.Gruppo
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
        DST.ChangeHashKey = SRC.ChangeHashKey,
        DST.DatetimeUpdated = SRC.DatetimeUpdated,
        DST.Gruppo = SRC.Gruppo
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'GPS' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'IT1C' AS DivisionBusinessKey,
    COALESCE(Inserted.CodProd, Deleted.CodProd) AS TableBusinessKey
    INTO audit.MergeLogDetails (
        SchemaName,
        TableName,
        MergeAction,
        MergeDatetime,
        DivisionBusinessKey,
        TableBusinessKey
    );

END;
GO

EXEC LandingDbFlorence.usp_Merge_GPS;
GO

SELECT * FROM LandingDbFlorence.GPS;
GO

/**
 * @table Staging.dProduct
 * @description Tabella di staging per dimensione Prodotto

 * @depends LandingDbFlorence.AnagraficaProdotti
 * @depends Dim.Division

SELECT TOP 1 * FROM LandingDbFlorence.AnagraficaProdotti;
SELECT TOP 1 * FROM Dim.Division;
*/

IF OBJECT_ID('Staging.dProductView', N'V') IS NULL EXEC('CREATE VIEW Staging.dProductView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.dProductView
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
		T.GruppoProdotto,
		' '
    ))) AS ChangeHashKey,

	-- Attributi
    T.ProductDescription,
    T.ProductDescription2,
    T.PPHyerarchyCode,
    T.PPLevel1Description,
    T.PPLevel2Description,
    T.PPLevel3Description,
	T.GruppoProdotto
	
FROM (

    SELECT
	    D.DivisionKey,
	    D.DivisionBusinessKey,
	    AP.CODART_F AS ProductBusinessKey,
	    AP.DESART1 AS ProductDescription,
	    AP.DESC_ART AS ProductDescription2,
	    CASE
	    WHEN LEN(AP.COD_LIV_3) = 4
		    AND LEN(AP.COD_LIV_2) = 4
		    AND LEN(AP.COD_LIV_1) = 4
		    THEN CONCAT(RTRIM(LTRIM(AP.COD_LIV_3)), RTRIM(LTRIM(AP.COD_LIV_2)), RTRIM(LTRIM(AP.COD_LIV_1)))
	    WHEN LEN(AP.COD_LIV_3) = 0
		    AND LEN(AP.COD_LIV_2) = 0
		    AND LEN(AP.COD_LIV_1) = 0
		    THEN N''
	    WHEN AP.COD_LIV_3 = N'-1' THEN N''
	    ELSE N'<???>'
	    END AS PPHyerarchyCode,
	    AP.DESC_LIV_3 AS PPLevel1Description,
	    AP.DESC_LIV_2 AS PPLevel2Description,
	    AP.DESC_LIV_1 AS PPLevel3Description,
		COALESCE(GPS.Gruppo, N'') AS GruppoProdotto

    FROM LandingDbFlorence.AnagraficaProdotti AP
    INNER JOIN Dim.Division D ON D.DivisionBusinessKey = AP.CODSOCIETA
	LEFT JOIN LandingDbFlorence.GPS GPS ON GPS.CodProd = AP.CODART_F
		AND AP.CODSOCIETA = N'IT1C'

) T;
GO

--DROP TABLE Staging.dProduct;
GO

IF OBJECT_ID('Staging.dProduct', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.dProduct FROM Staging.dProductView;

	ALTER TABLE Staging.dProduct ADD CONSTRAINT PK_Staging_dProduct PRIMARY KEY CLUSTERED (DivisionBusinessKey, ProductBusinessKey);

	ALTER TABLE Staging.dProduct ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

	ALTER TABLE Staging.dProduct ALTER COLUMN ProductDescription NVARCHAR(80) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN ProductDescription2 NVARCHAR(80) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN PPHyerarchyCode NVARCHAR(12) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN PPLevel1Description NVARCHAR(50) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN PPLevel2Description NVARCHAR(50) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN PPLevel3Description NVARCHAR(50) NOT NULL;
	ALTER TABLE Staging.dProduct ALTER COLUMN GruppoProdotto NVARCHAR(50) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_dProduct
 * @description Popolamento tabella di staging per dimensione Prodotto
*/

IF OBJECT_ID('Staging.usp_Reload_dProduct', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_dProduct AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_dProduct
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.dProduct;

INSERT INTO Staging.dProduct
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
    PPLevel3Description,
	GruppoProdotto
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
    PPLevel3Description,
	GruppoProdotto

FROM Staging.dProductView;

END;
GO

EXEC Staging.usp_Reload_dProduct;
GO

/**
 * @table Dim.Product
 * @description Dimensione Prodotto

 * @depends Staging.dProduct

SELECT TOP 1 * FROM Staging.dProduct;
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
        PPLevel3Description,
		GruppoProdotto

	INTO Dim.Product

	FROM Staging.dProduct;

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
        PPLevel3Description,
		GruppoProdotto
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
        N'',       -- PPLevel3Description - nvarchar(50)
        N''        -- GruppoProdotto - nvarchar(50)

    FROM Dim.Division D;

END;
GO

/**
 * @procedure Dim.usp_Merge_Product
 * @description Aggiornamento dimensione Prodotto
*/

IF OBJECT_ID('Dim.usp_Merge_Product', N'P') IS NULL EXEC('CREATE PROCEDURE Dim.usp_Merge_Product AS RETURN 0;');
GO

ALTER PROCEDURE Dim.usp_Merge_Product
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Dim.Product AS TGT
USING Staging.dProduct AS SRC ON (
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
        PPLevel3Description,
		GruppoProdotto
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
        SRC.PPLevel3Description,
		SRC.GruppoProdotto
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
        TGT.PPLevel3Description = SRC.PPLevel3Description,
		TGT.GruppoProdotto = SRC.GruppoProdotto
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
LEFT JOIN Staging.dProduct SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.ProductBusinessKey = DST.ProductBusinessKey
WHERE DST.ProductKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ProductBusinessKey IS NULL;

UPDATE DST
    SET DST.IsRowValid = CAST(0 AS BIT),
    DST.DatetimeDeleted = CURRENT_TIMESTAMP

FROM Dim.Product DST
LEFT JOIN Staging.dProduct SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.ProductBusinessKey = DST.ProductBusinessKey
WHERE DST.ProductKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ProductBusinessKey IS NULL;

END;
GO

EXEC Dim.usp_Merge_Product;
GO

SELECT * FROM audit.MergeLogDetails;
GO
