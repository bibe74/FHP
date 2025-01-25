USE DWFHP;
GO

/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

--CREATE SCHEMA Dim AUTHORIZATION dbo;
--CREATE SCHEMA Fact AUTHORIZATION dbo;
GO

/*
FactSales (Fatturato)
FactProfitability (Profitability)

DimDivision (Società)
DimTerritory (Territorio)
DimCustomer (Clienti)
DimProduct (Prodotti)
DimSpecialCustomer (GCS)
DimSpecialProduct (GPS)
DimDate (2018-2019)

DimADUser (Utenti Active Directory)
*/

SELECT TOP 1 * FROM DBFlorencePP.dbo._Fatturato
SELECT TOP 1 * FROM DBFlorencePP.dbo._Profitability
SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_Territorio
SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_AnagraficaGerarchia_Clienti
SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_AnagraficaProdotti
SELECT TOP 1 * FROM DBFlorencePP.dbo.GPS
SELECT TOP 1 * FROM DBFlorencePP.dbo.GCS

/**
 * @table Fact.Sales
 * @description Tabella dei fatti Fatturato

 * @depends dbo._Fatturato

SELECT TOP 100 * FROM DBFlorencePP.dbo._Fatturato;
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
		D.DivisionKey,
		DT.DateKey,
		P.ProductKey,
		CAST(1 AS BIGINT) AS SalesKey,

		-- Data Warehouse
		CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
			D.DivisionKey,
			DT.DateKey,
			P.ProductKey,
			' '
		))) AS HistoricalHashKey,
		CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
			F.QTAFATT,
			F.IMPFATT,
			' '
		))) AS ChangeHashKey,
		CURRENT_TIMESTAMP AS DatetimeInserted,
		CURRENT_TIMESTAMP AS DatetimeUpdated,

		-- Misure
		F.QTAFATT AS SalesQuantity,
		F.IMPFATT AS SalesAmount

	INTO Fact.Sales

	FROM DBFlorencePP.dbo._Fatturato F
	INNER JOIN Dim.Division D ON D.DivisionBusinessKey = 'IT1C'
	INNER JOIN Dim.Date DT ON DT.Date = F.Data
	INNER JOIN Dim.Product P ON P.DivisionBusinessKey = D.DivisionBusinessKey AND P.ProductBusinessKey = F.CODART
	WHERE F.Data >= CAST('20180101' AS DATETIME);

	ALTER TABLE Fact.Sales ALTER COLUMN SalesKey BIGINT NOT NULL;

	ALTER TABLE Fact.Sales ADD CONSTRAINT DFT_Fact_Sales_SalesKey DEFAULT (NEXT VALUE FOR dbo.seq_Sales) FOR SalesKey;

	ALTER TABLE Fact.Sales ADD CONSTRAINT PK_Fact_Sales PRIMARY KEY CLUSTERED (SalesKey);

	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_DivisionKey FOREIGN KEY (DivisionKey) REFERENCES Dim.Division (DivisionKey);
	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_DateKey FOREIGN KEY (DateKey) REFERENCES Dim.Date (DateKey);
	ALTER TABLE Fact.Sales ADD CONSTRAINT FK_Fact_Sales_ProductKey FOREIGN KEY (ProductKey) REFERENCES Dim.Product (ProductKey);
END;
GO

INSERT INTO Fact.Sales (
	DivisionKey,
	DateKey,
	ProductKey,
	HistoricalHashKey,
	ChangeHashKey,
	DatetimeInserted,
	DatetimeUpdated,
	SalesQuantity,
	SalesAmount
)
SELECT
	-- Chiavi
	D.DivisionKey,
	DT.DateKey,
	P.ProductKey,
	--CAST(1 AS BIGINT) AS SalesKey,

	-- Data Warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
		D.DivisionKey,
		DT.DateKey,
		P.ProductKey,
		' '
	))) AS HistoricalHashKey,
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
		F.QTAFATT,
		F.IMPFATT,
		' '
	))) AS ChangeHashKey,
	CURRENT_TIMESTAMP AS DatetimeInserted,
	CURRENT_TIMESTAMP AS DatetimeUpdated,

	-- Misure
	F.QTAFATT AS SalesQuantity,
	F.IMPFATT AS SalesAmount

FROM DBFlorencePP.dbo._Fatturato F
INNER JOIN Dim.Division D ON D.DivisionBusinessKey = 'IT1C'
INNER JOIN Dim.Date DT ON DT.Date = F.Data
INNER JOIN Dim.Product P ON P.DivisionBusinessKey = D.DivisionBusinessKey AND P.ProductBusinessKey = F.CODART
WHERE F.Data >= CAST('20180101' AS DATETIME);
GO

SELECT * FROM Fact.Sales;
GO


SELECT TOP 1 * FROM DBFlorencePP.dbo._Fatturato
SELECT TOP 1 * FROM DBFlorencePP.dbo._Profitability
SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_Territorio
SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_AnagraficaGerarchia_Clienti
SELECT TOP 1 * FROM DBFlorencePP.dbo.GPS
SELECT TOP 1 * FROM DBFlorencePP.dbo.GCS
