/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table LandingDbFlorence.RiepilogoFatturato
 * @description Riepilogo fatturato

 * @depends DBFlorencePP.dbo._Fatturato

SELECT TOP 1 * FROM DBFlorencePP.dbo._Fatturato;
*/

IF OBJECT_ID('LandingDbFlorence.RiepilogoFatturatoView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.RiepilogoFatturatoView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.RiepilogoFatturatoView
AS
SELECT
	-- Chiavi
    T.CODSOCIETA,
    T.DATA,
    T.CODCLI,
    T.CODART,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CODSOCIETA,
        T.DATA,
        T.CODCLI,
        T.CODART,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.QTAFATT,
        T.IMPFATT,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Misure
    T.QTAFATT,
    T.IMPFATT
	
FROM (

    SELECT
        'IT1C' AS CODSOCIETA,
        F.DATA,
        F.CODCLI,
        F.CODART,
        SUM(F.QTAFATT) AS QTAFATT,
        SUM(F.IMPFATT) AS IMPFATT

    FROM DBFlorencePP.dbo._Fatturato F
    GROUP BY F.DATA,
        F.CODCLI,
        F.CODART

) T;
GO

--DROP TABLE LandingDbFlorence.RiepilogoFatturato;
GO

IF OBJECT_ID('LandingDbFlorence.RiepilogoFatturato', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.RiepilogoFatturato FROM LandingDbFlorence.RiepilogoFatturatoView;

END;
GO

/**
 * @procedure usp_Merge_RiepilogoFatturato
 * @description Sincronizzazione RiepilogoFatturato
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_RiepilogoFatturato', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_RiepilogoFatturato AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_RiepilogoFatturato
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.RiepilogoFatturato AS DST
USING LandingDbFlorence.RiepilogoFatturatoView AS SRC
ON SRC.CODSOCIETA = DST.CODSOCIETA
    AND SRC.DATA = DST.DATA
    AND SRC.CODCLI = DST.CODCLI
    AND SRC.CODART = DST.CODART
WHEN NOT MATCHED
    THEN INSERT (
        CODSOCIETA,
        DATA,
        CODCLI,
        CODART,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        QTAFATT,
        IMPFATT
    )
    VALUES (
        SRC.CODSOCIETA,
        SRC.DATA,
        SRC.CODCLI,
        SRC.CODART,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        SRC.DatetimeInserted,
        SRC.DatetimeUpdated,
        SRC.DatetimeDeleted,
        SRC.QTAFATT,
        SRC.IMPFATT
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
        DST.ChangeHashKey = SRC.ChangeHashKey,
        DST.DatetimeUpdated = SRC.DatetimeUpdated,
        DST.QTAFATT = SRC.QTAFATT,
        DST.IMPFATT = SRC.IMPFATT
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'RiepilogoFatturato' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.CODSOCIETA, Deleted.CODSOCIETA) AS DivisionBusinessKey,
    CONCAT(
        CONVERT(NVARCHAR(10), COALESCE(Inserted.DATA, Deleted.DATA), 103),
        N' ', COALESCE(Inserted.CODCLI, Deleted.CODCLI),
        N' ', COALESCE(Inserted.CODART, Deleted.CODART)
    ) AS TableBusinessKey
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

EXEC LandingDbFlorence.usp_Merge_RiepilogoFatturato;
GO

SELECT * FROM LandingDbFlorence.RiepilogoFatturato;
GO

/**
 * @table Staging.fSales
 * @description Tabella di staging per tabella dei fatti Fatturato

 * @depends LandingDbFlorence.RiepilogoFatturato
 * @depends Dim.Customer
 * @depends Dim.Product

SELECT TOP 1 * FROM LandingDbFlorence.RiepilogoFatturato;
SELECT TOP 1 * FROM Dim.Customer;
SELECT TOP 1 * FROM Dim.Product;
*/

IF OBJECT_ID('Staging.fSalesView', N'V') IS NULL EXEC('CREATE VIEW Staging.fSalesView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.fSalesView
AS
SELECT
	-- Chiavi
	T.DivisionKey,
    T.DivisionBusinessKey,
    T.DateKey,
    T.CustomerKey,
	T.CustomerBusinessKey,
    T.ProductKey,
    T.ProductBusinessKey,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.DivisionBusinessKey,
        T.DateKey,
        T.CustomerBusinessKey,
        T.ProductBusinessKey,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.SalesQuantity,
        T.SalesAmount,
		' '
    ))) AS ChangeHashKey,

	-- Misure
    T.SalesQuantity,
    T.SalesAmount
	
FROM (

    SELECT
	    D.DivisionKey,
	    D.DivisionBusinessKey,
        DF.DateKey,
		COALESCE(C.CustomerKey, CASE WHEN RF.CODCLI = N'' THEN -D.DivisionKey ELSE -100-D.DivisionKey END) AS CustomerKey,
		COALESCE(C.CustomerBusinessKey, CASE WHEN COALESCE(RF.CODCLI, N'') = N'' THEN N'' ELSE N'???' END) AS CustomerBusinessKey,
        COALESCE(P.ProductKey, -D.DivisionKey) AS ProductKey,
        COALESCE(P.ProductBusinessKey, N'') AS ProductBusinessKey,
        RF.QTAFATT AS SalesQuantity,
        RF.IMPFATT AS SalesAmount

    FROM LandingDbFlorence.RiepilogoFatturato RF
    INNER JOIN Dim.Division D ON D.DivisionBusinessKey = RF.CODSOCIETA
    --INNER JOIN Dim.Date DF ON DF.Date = RF.DATA
    INNER JOIN Dim.Date DF ON DF.Datetime = RF.DATA
	LEFT JOIN Dim.Customer C ON C.DivisionBusinessKey = RF.CODSOCIETA AND C.CustomerBusinessKey = RF.CODCLI
    LEFT JOIN Dim.Product P ON P.DivisionBusinessKey = RF.CODSOCIETA AND P.ProductBusinessKey = RF.CODART
	WHERE RF.Datetimeupdated > DATEADD(DAY,  -1, CURRENT_TIMESTAMP)

) T
LEFT JOIN dim.Customer CC ON CC.CustomerKey = T.CustomerKey;
GO

--DROP TABLE Staging.fSales;
GO

IF OBJECT_ID('Staging.fSales', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.fSales FROM Staging.fSalesView;

	ALTER TABLE Staging.fSales ALTER COLUMN ProductBusinessKey NVARCHAR(18) NOT NULL;
	ALTER TABLE Staging.fSales ALTER COLUMN CustomerBusinessKey NVARCHAR(10) NOT NULL;

	ALTER TABLE Staging.fSales ADD CONSTRAINT PK_Staging_fSales PRIMARY KEY CLUSTERED (DivisionBusinessKey, DateKey, CustomerBusinessKey, ProductBusinessKey);

	ALTER TABLE Staging.fSales ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.fSales ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

	ALTER TABLE Staging.fSales ALTER COLUMN CustomerKey INT NOT NULL;
	ALTER TABLE Staging.fSales ALTER COLUMN ProductKey INT NOT NULL;
	ALTER TABLE Staging.fSales ALTER COLUMN SalesQuantity DECIMAL(18, 2) NOT NULL;
	ALTER TABLE Staging.fSales ALTER COLUMN SalesAmount DECIMAL(18, 2) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_fSales
 * @description Popolamento tabella di staging per tabella dei fatti Fatturato
*/

IF OBJECT_ID('Staging.usp_Reload_fSales', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_fSales AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_fSales
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.fSales;

INSERT INTO Staging.fSales
(
    DivisionKey,
    DivisionBusinessKey,
    DateKey,
    CustomerKey,
	CustomerBusinessKey,
    ProductKey,
    ProductBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    SalesQuantity,
    SalesAmount
)
SELECT
    DivisionKey,
    DivisionBusinessKey,
    DateKey,
    CustomerKey,
	CustomerBusinessKey,
    ProductKey,
    ProductBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    SalesQuantity,
    SalesAmount

FROM Staging.fSalesView;

END;
GO

EXEC Staging.usp_Reload_fSales;
GO

/**
 * @table Fact.Sales
 * @description Tabella dei fatti Fatturato

 * @depends Staging.fSales

SELECT TOP 1 * FROM Staging.fSales;
*/

--DROP TABLE Fact.Sales; DROP SEQUENCE dbo.seq_Sales;
GO

IF OBJECT_ID('dbo.seq_Sales', 'SO') IS NULL
BEGIN

	CREATE SEQUENCE dbo.seq_Sales
	AS BIGINT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE
	CACHE 1000;

END;
GO

--DROP TABLE Fact.Sales;
GO

IF OBJECT_ID('Fact.Sales') IS NULL
BEGIN

	SELECT TOP 0 
		-- Chiavi
        DivisionKey,
        DivisionBusinessKey,
        DateKey,
        CustomerKey,
		CustomerBusinessKey,
        ProductKey,
        ProductBusinessKey,
        CAST(1 AS BIGINT) AS FatturatoKey,

        -- Data warehouse
        HistoricalHashKey,
        ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid,

        -- Misure
        SalesQuantity,
        SalesAmount

	INTO Fact.Sales

	FROM Staging.fSales;

	ALTER TABLE Fact.Sales ALTER COLUMN FatturatoKey INT NOT NULL;

	ALTER TABLE Fact.Sales ADD CONSTRAINT DFT_Fact_Sales_FatturatoKey DEFAULT (NEXT VALUE FOR dbo.seq_Sales) FOR FatturatoKey;

	ALTER TABLE Fact.Sales ADD CONSTRAINT PK_Fact_Sales PRIMARY KEY CLUSTERED (FatturatoKey);

    ALTER TABLE Fact.Sales ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Fact.Sales ALTER COLUMN IsRowValid BIT NOT NULL;

	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_DivisionKey FOREIGN KEY (DivisionKey) REFERENCES Dim.Division (DivisionKey);
	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_DateKey FOREIGN KEY (DateKey) REFERENCES Dim.Date (DateKey);
	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_CustomerKey FOREIGN KEY (CustomerKey) REFERENCES Dim.Customer (CustomerKey);
	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_ProductKey FOREIGN KEY (ProductKey) REFERENCES Dim.Product (ProductKey);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Fact_Sales_DivisionBusinessKey_DateKey_CustomerBusinessKey_ProductBusinessKey ON Fact.Sales (DivisionBusinessKey, DateKey, CustomerBusinessKey, ProductBusinessKey);

END;
GO

/**
 * @procedure Fact.usp_Merge_Sales
 * @description Aggiornamento tabella dei fatti Fatturato
*/

IF OBJECT_ID('Fact.usp_Merge_Sales', N'P') IS NULL EXEC('CREATE PROCEDURE Fact.usp_Merge_Sales AS RETURN 0;');
GO

ALTER PROCEDURE Fact.usp_Merge_Sales
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Fact.Sales AS TGT
USING Staging.fSales AS SRC ON (
    SRC.DivisionBusinessKey = TGT.DivisionBusinessKey
    AND SRC.DateKey = TGT.DateKey
    AND SRC.CustomerBusinessKey = TGT.CustomerBusinessKey
    AND SRC.ProductBusinessKey = TGT.ProductBusinessKey
)
WHEN NOT MATCHED
    THEN INSERT (
        DivisionKey,
        DivisionBusinessKey,
        DateKey,
        CustomerKey,
		CustomerBusinessKey,
        ProductKey,
        ProductBusinessKey,
        --FatturatoKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
        SalesQuantity,
        SalesAmount
    )
    VALUES (
        SRC.DivisionKey,
        SRC.DivisionBusinessKey,
        SRC.DateKey,
        SRC.CustomerKey,
		SRC.CustomerBusinessKey,
        SRC.ProductKey,
        SRC.ProductBusinessKey,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CAST('19000101' AS DATETIME),
        CAST(1 AS BIT),
        SRC.SalesQuantity,
        SRC.SalesAmount
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP,
        TGT.SalesQuantity = SRC.SalesQuantity,
        TGT.SalesAmount = SRC.SalesAmount
--WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Fact' AS SchemaName,
    N'Sales' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.DivisionBusinessKey, Deleted.DivisionBusinessKey) AS DivisionBusinessKey,
    CONCAT(
        CONVERT(NVARCHAR(10), COALESCE(Inserted.DateKey, Deleted.DateKey), 103),
        N' ', COALESCE(Inserted.CustomerBusinessKey, Deleted.CustomerBusinessKey),
        N' ', COALESCE(Inserted.ProductBusinessKey, Deleted.ProductBusinessKey)
    )
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

EXEC Fact.usp_Merge_Sales;
GO

SELECT * FROM audit.MergeLogDetails;
GO
