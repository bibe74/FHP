/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

TRUNCATE TABLE LandingDbFlorence.RiepilogoFatturato;
GO

TRUNCATE TABLE LandingDbFlorence.AnagraficaProdotti;
GO

TRUNCATE TABLE LandingDbFlorence.AnagraficaTerritorio;
GO

TRUNCATE TABLE LandingDbFlorence.AnagraficaClienti;
GO

DELETE FROM Fact.Sales;
GO

DELETE FROM Dim.Product WHERE ProductKey > 0;
GO

ALTER SEQUENCE dbo.seq_Product RESTART WITH 1;
GO

DELETE FROM Dim.Customer WHERE CustomerKey > 0;
GO

ALTER SEQUENCE dbo.seq_Customer RESTART WITH 1;
GO

TRUNCATE TABLE audit.MergeLog;
GO

TRUNCATE TABLE audit.MergeLogDetails;
GO

EXEC LandingDbFlorence.usp_Merge_AnagraficaTerritorio;
GO

EXEC LandingDbFlorence.usp_Merge_AnagraficaClienti;
GO

EXEC LandingDbFlorence.usp_Merge_GCS;
GO

EXEC Staging.usp_Reload_dCustomer;
GO

EXEC Dim.usp_Merge_Customer;
GO

EXEC LandingDbFlorence.usp_Merge_AnagraficaProdotti;
GO

EXEC LandingDbFlorence.usp_Merge_GPS;
GO

EXEC Staging.usp_Reload_dProduct;
GO

EXEC Dim.usp_Merge_Product;
GO

EXEC LandingDbFlorence.usp_Merge_RiepilogoFatturato;
GO

EXEC Staging.usp_Reload_fSales;
GO

EXEC Fact.usp_Merge_Sales;
GO

EXEC LandingDbFlorence.usp_Merge_RiepilogoProfitability;
GO

EXEC Staging.usp_Reload_fProfitability;
GO

EXEC Fact.usp_Merge_Profitability;
GO

---- Modifiche ad un quinto e cancellazione di un centesimo dei record di Product

WITH ProdottiNumerati
AS (
    SELECT
        AP.CODSOCIETA,
        AP.CODART_F,
        ROW_NUMBER() OVER (ORDER BY AP.CODSOCIETA, AP.CODART_F) AS rn

    FROM LandingDbFlorence.AnagraficaProdotti AP
)
UPDATE AP
    SET AP.DESART1 = CONCAT(N'_', DESART1),
	Changehashkey=convert(varbinary,'')
FROM LandingDbFlorence.AnagraficaProdotti AP
INNER JOIN ProdottiNumerati PN ON PN.CODSOCIETA = AP.CODSOCIETA AND PN.CODART_F = AP.CODART_F
    AND PN.rn % 5 = 0;
GO

WITH ProdottiNumerati
AS (
    SELECT
        AP.CODSOCIETA,
        AP.CODART_F,
        ROW_NUMBER() OVER (ORDER BY AP.CODSOCIETA, AP.CODART_F) AS rn

    FROM LandingDbFlorence.AnagraficaProdotti AP
)
DELETE AP
FROM LandingDbFlorence.AnagraficaProdotti AP
INNER JOIN ProdottiNumerati PN ON PN.CODSOCIETA = AP.CODSOCIETA AND PN.CODART_F = AP.CODART_F
    AND PN.rn % 100 = 1;
GO

EXEC Staging.usp_Reload_dProduct;
GO

EXEC Dim.usp_Merge_Product;
GO

SELECT * FROM audit.MergeLogView;
GO
