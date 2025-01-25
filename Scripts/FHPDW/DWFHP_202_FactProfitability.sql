/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table LandingDbFlorence.RiepilogoProfitability
 * @description Riepilogo profitability

 * @depends DBFlorencePP.dbo._Profitability

SELECT TOP 1 * FROM DBFlorencePP.dbo._Profitability;
*/

IF OBJECT_ID('LandingDbFlorence.RiepilogoProfitabilityView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.RiepilogoProfitabilityView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.RiepilogoProfitabilityView
AS
WITH DateFineMese
AS (
	SELECT
		Year,
		Month,
		MAX(Date) AS DataFineMese 
	FROM Dim.Date
	GROUP BY Year,
		Month
)
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
        T.NET1,
        T.NETSALES,
		T.NET3,
		T.GP,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Misure
    T.NET1,
    T.NETSALES,
	T.NET3,
	T.GP
	
FROM (

    SELECT
        'IT1C' AS CODSOCIETA,
        DFM.DataFineMese AS DATA,
        P.CODCLI,
        P.CODART,
        SUM(P.NET1) AS NET1,
        SUM(P.NETSALES) AS NETSALES,
        SUM(P.NET3) AS NET3,
        SUM(P.GROSSPROFIT) AS GP

    FROM DBFlorencePP.dbo._Profitability P
	INNER JOIN DateFineMese DFM ON DFM.Year = P.ANNO AND DFM.Month = P.MESE
    GROUP BY DFM.DataFineMese,
        P.CODCLI,
        P.CODART

) T;
GO

--DROP TABLE LandingDbFlorence.RiepilogoProfitability;
GO

IF OBJECT_ID('LandingDbFlorence.RiepilogoProfitability', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.RiepilogoProfitability FROM LandingDbFlorence.RiepilogoProfitabilityView;

END;
GO

/**
 * @procedure usp_Merge_RiepilogoProfitability
 * @description Sincronizzazione RiepilogoProfitability
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_RiepilogoProfitability', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_RiepilogoProfitability AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_RiepilogoProfitability
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.RiepilogoProfitability AS DST
USING LandingDbFlorence.RiepilogoProfitabilityView AS SRC
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
        NET1,
        NETSALES,
		NET3,
		GP
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
        SRC.NET1,
        SRC.NETSALES,
		SRC.NET3,
		SRC.GP
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
        DST.ChangeHashKey = SRC.ChangeHashKey,
        DST.DatetimeUpdated = SRC.DatetimeUpdated,
        DST.NET1 = SRC.NET1,
        DST.NETSALES = SRC.NETSALES,
		DST.NET3 = SRC.NET3,
		DST.GP = SRC.GP
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'RiepilogoProfitability' AS TableName,
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

EXEC LandingDbFlorence.usp_Merge_RiepilogoProfitability;
GO

SELECT * FROM LandingDbFlorence.RiepilogoProfitability;
GO

/**
 * @table Staging.fProfitability
 * @description Tabella di staging per tabella dei fatti Profitability

 * @depends LandingDbFlorence.RiepilogoProfitability
 * @depends Dim.Division
 * @depends Dim.Product

SELECT TOP 1 * FROM LandingDbFlorence.RiepilogoProfitability;
SELECT TOP 1 * FROM Dim.Division;
SELECT TOP 1 * FROM Dim.Product;
*/

IF OBJECT_ID('Staging.fProfitabilityView', N'V') IS NULL EXEC('CREATE VIEW Staging.fProfitabilityView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.fProfitabilityView
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
        SUM(T.Net1),
		SUM(T.NetSales),
		SUM(T.Net3),
		SUM(T.GP),
		' '
    ))) AS ChangeHashKey,

	-- Misure
    SUM(T.Net1) AS Net1,
    SUM(T.NetSales) AS NetSales,
	SUM(T.Net3) AS Net3,
	SUM(T.GP) AS GP
	
FROM (

    SELECT
	    D.DivisionKey,
	    D.DivisionBusinessKey,
        DF.DateKey,
		RF.CODCLI,
		COALESCE(C.CustomerKey, CASE WHEN RF.CODCLI = N'' THEN -D.DivisionKey ELSE -100-D.DivisionKey END) AS CustomerKey,
		COALESCE(C.CustomerBusinessKey, CASE WHEN COALESCE(RF.CODCLI, N'') = N'' THEN N'' ELSE N'???' END) AS CustomerBusinessKey,
        COALESCE(P.ProductKey, -D.DivisionKey) AS ProductKey,
        COALESCE(P.ProductBusinessKey, N'') AS ProductBusinessKey,
        RF.NET1 AS Net1,
        RF.NETSALES AS NetSales,
		RF.NET3 AS Net3,
		RF.GP AS GP

    FROM LandingDbFlorence.RiepilogoProfitability RF
    INNER JOIN Dim.Division D ON D.DivisionBusinessKey = RF.CODSOCIETA
    --INNER JOIN Dim.Date DF ON DF.Date = RF.DATA
    INNER JOIN Dim.Date DF ON DF.Datetime = RF.DATA
	LEFT JOIN Dim.Customer C ON C.DivisionBusinessKey = RF.CODSOCIETA AND C.CustomerBusinessKey = RF.CODCLI
    LEFT JOIN Dim.Product P ON P.DivisionBusinessKey = RF.CODSOCIETA AND P.ProductBusinessKey = RF.CODART
	WHERE RF.Datetimeupdated > DATEADD(DAY,  -1, CURRENT_TIMESTAMP)

) T
LEFT JOIN dim.Customer CC ON CC.CustomerKey = T.CustomerKey
GROUP BY T.DivisionKey,
    T.DivisionBusinessKey,
    T.DateKey,
    T.CustomerKey,
	T.CustomerBusinessKey,
    T.ProductKey,
    T.ProductBusinessKey;
GO

--DROP TABLE Staging.fProfitability;
GO

IF OBJECT_ID('Staging.fProfitability', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.fProfitability FROM Staging.fProfitabilityView;

	ALTER TABLE Staging.fProfitability ALTER COLUMN ProductBusinessKey NVARCHAR(18) NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN CustomerBusinessKey NVARCHAR(10) NOT NULL;

	ALTER TABLE Staging.fProfitability ADD CONSTRAINT PK_Staging_fProfitability PRIMARY KEY CLUSTERED (DivisionBusinessKey, DateKey, CustomerBusinessKey, ProductBusinessKey);

	ALTER TABLE Staging.fProfitability ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

	ALTER TABLE Staging.fProfitability ALTER COLUMN CustomerKey INT NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN ProductKey INT NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN Net1 DECIMAL(18, 2) NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN NetSales DECIMAL(18, 2) NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN Net3 DECIMAL(18, 2) NOT NULL;
	ALTER TABLE Staging.fProfitability ALTER COLUMN GP DECIMAL(18, 2) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_fProfitability
 * @description Popolamento tabella di staging per tabella dei fatti Sales
*/

IF OBJECT_ID('Staging.usp_Reload_fProfitability', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_fProfitability AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_fProfitability
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.fProfitability;

INSERT INTO Staging.fProfitability
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
    Net1,
    NetSales,
	Net3,
	GP
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
    Net1,
    NetSales,
	Net3,
	GP

FROM Staging.fProfitabilityView;

END;
GO

EXEC Staging.usp_Reload_fProfitability;
GO

/**
 * @table Fact.Profitability
 * @description Tabella dei fatti Profitability

 * @depends Staging.fProfitability

SELECT TOP 1 * FROM Staging.fProfitability;
*/

--DROP TABLE Fact.Profitability; DROP SEQUENCE dbo.seq_Profitability;
GO

IF OBJECT_ID('dbo.seq_Profitability', 'SO') IS NULL
BEGIN

	CREATE SEQUENCE dbo.seq_Profitability
	AS BIGINT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE
	CACHE 1000;

END;
GO

--DROP TABLE Fact.Profitability;
GO

IF OBJECT_ID('Fact.Profitability') IS NULL
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
        CAST(1 AS BIGINT) AS ProfitabilityKey,

        -- Data warehouse
        HistoricalHashKey,
        ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid,

        -- Misure
        Net1,
        NetSales,
		Net3,
		GP

	INTO Fact.Profitability

	FROM Staging.fProfitability;

	ALTER TABLE Fact.Profitability ALTER COLUMN ProfitabilityKey INT NOT NULL;

	ALTER TABLE Fact.Profitability ADD CONSTRAINT DFT_Fact_Profitability_ProfitabilityKey DEFAULT (NEXT VALUE FOR dbo.seq_Profitability) FOR ProfitabilityKey;

	ALTER TABLE Fact.Profitability ADD CONSTRAINT PK_Fact_Profitability PRIMARY KEY CLUSTERED (ProfitabilityKey);

    ALTER TABLE Fact.Profitability ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Fact.Profitability ALTER COLUMN IsRowValid BIT NOT NULL;

	ALTER TABLE Fact.Profitability ADD CONSTRAINT FK_Fact_Profitability_DivisionKey FOREIGN KEY (DivisionKey) REFERENCES Dim.Division (DivisionKey);
	ALTER TABLE Fact.Profitability ADD CONSTRAINT FK_Fact_Profitability_DateKey FOREIGN KEY (DateKey) REFERENCES Dim.Date (DateKey);
	ALTER TABLE Fact.Profitability ADD CONSTRAINT FK_Fact_Profitability_CustomerKey FOREIGN KEY (CustomerKey) REFERENCES Dim.Customer (CustomerKey);
	ALTER TABLE Fact.Profitability ADD CONSTRAINT FK_Fact_Profitability_ProductKey FOREIGN KEY (ProductKey) REFERENCES Dim.Product (ProductKey);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Fact_Profitability_DivisionBusinessKey_DateKey_CustomerBusinessKey_ProductBusinessKey ON Fact.Profitability (DivisionBusinessKey, DateKey, CustomerBusinessKey, ProductBusinessKey);

END;
GO

/**
 * @procedure Fact.usp_Merge_Profitability
 * @description Aggiornamento tabella dei fatti Profitability
*/

IF OBJECT_ID('Fact.usp_Merge_Profitability', N'P') IS NULL EXEC('CREATE PROCEDURE Fact.usp_Merge_Profitability AS RETURN 0;');
GO

ALTER PROCEDURE Fact.usp_Merge_Profitability
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Fact.Profitability AS TGT
USING Staging.fProfitability AS SRC ON (
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
        --ProfitabilityKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
        Net1,
        NetSales,
		Net3,
		GP
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
        SRC.Net1,
        SRC.NetSales,
		SRC.Net3,
		SRC.GP
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP,
        TGT.Net1 = SRC.Net1,
        TGT.NetSales = SRC.NetSales,
		TGT.Net3 = SRC.Net3,
		TGT.GP = SRC.GP

--WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Fact' AS SchemaName,
    N'Profitability' AS TableName,
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

EXEC Fact.usp_Merge_Profitability;
GO

SELECT * FROM audit.MergeLogDetails;
GO
