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

DELETE FROM Fact.Sales;
GO

DELETE FROM Dim.Product WHERE ProductKey > 0;
GO

ALTER SEQUENCE dbo.seq_Product RESTART WITH 1;
GO

TRUNCATE TABLE audit.MergeLog;
GO

TRUNCATE TABLE audit.MergeLogDetails;
GO
