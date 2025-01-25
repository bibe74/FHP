/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/* Importare dai file CSV le tabelle dbo.ALL_PP e dbo.Sales_PP */

/**
 * @table Import.AdministrativeADUsers
 * @description Tabella di importazione per utenti "Admin", abilitati a vedere tutti i clienti
*/

---DROP TABLE Import.AdministrativeADUsers;
GO

SELECT
	LOWER(A.ADUser) AS ADUser,
	UPPER(A.Description) AS Description 

INTO Import.AdministrativeADUsers

FROM dbo.ALL_PP A 
LEFT JOIN dbo.Sales_PP S ON S.AD = A.ADUser
WHERE S.AD IS NULL
ORDER BY A.ADUser;
GO

ALTER TABLE Import.AdministrativeADUsers ALTER COLUMN ADUser NVARCHAR(40) NOT NULL;
ALTER TABLE Import.AdministrativeADUsers ALTER COLUMN Description NVARCHAR(100) NOT NULL;
GO

ALTER TABLE Import.AdministrativeADUsers ADD CONSTRAINT PK_Import_AdministrativeADUsers PRIMARY KEY CLUSTERED (ADUser);
GO

/**
 * @table Import.TerritorialADUsers
 * @description Tabella di importazione per utenti "Sales", abilitati a vedere i propri clienti
*/

--DROP TABLE Import.TerritorialADUsers;
GO

SELECT DISTINCT
	RIGHT(REPLICATE(N'0', 10) + CONVERT(NVARCHAR(10), COD), 10) AS CODAGENTE,
	LOWER(COALESCE(AD, N'<nessuno>')) AS ADUser,
	UPPER(Cognome + N' ' + Nome) AS Description,
	RIGHT(REPLICATE(N'0', 10) + CONVERT(NVARCHAR(10), CODPADRE), 20) AS CODAGENTEPADRE,
	UPPER(Cognome2) AS SalesGroupDescription,
    LOWER(COALESCE(AD, N'')) AS SalesGroupADUser

INTO Import.TerritorialADUsers

FROM dbo.Sales_PP 
ORDER BY CODAGENTE,
	ADUser;
GO

ALTER TABLE Import.TerritorialADUsers ALTER COLUMN CODAGENTE NVARCHAR(10) NOT NULL;
ALTER TABLE Import.TerritorialADUsers ALTER COLUMN ADUser NVARCHAR(40) NOT NULL;
GO

ALTER TABLE Import.TerritorialADUsers ADD CONSTRAINT PK_Import_TerritorialADUsers PRIMARY KEY CLUSTERED (CODAGENTE, ADUser);
GO

ALTER TABLE Import.TerritorialADUsers ALTER COLUMN Description NVARCHAR(100) NOT NULL;
ALTER TABLE Import.TerritorialADUsers ALTER COLUMN CODAGENTEPADRE NVARCHAR(20) NOT NULL;
ALTER TABLE Import.TerritorialADUsers ALTER COLUMN SalesGroupDescription NVARCHAR(40) NOT NULL;
ALTER TABLE Import.TerritorialADUsers ALTER COLUMN SalesGroupADUser NVARCHAR(40) NOT NULL;
GO

SELECT * FROM Import.TerritorialADUsers;
GO

/* Query extra, utilizzate per l'aggiunta dei campi 

ALTER TABLE Import.TerritorialADUsers ADD CODAGENTEPADRE NVARCHAR(20) NULL;
GO

UPDATE T
SET T.CODAGENTEPADRE = RIGHT(REPLICATE(N'0', 10) + CONVERT(NVARCHAR(10), CODPADRE), 10)
FROM Import.TerritorialADUsers T
INNER JOIN dbo.Sales_PP SPP ON RIGHT(REPLICATE(N'0', 10) + CONVERT(NVARCHAR(10), COD), 10) = CODAGENTE
	AND LOWER(COALESCE(AD, N'<nessuno>')) = ADUser;
GO

UPDATE T
SET T.CODAGENTEPADRE = N''
FROM Import.TerritorialADUsers T
LEFT JOIN Import.TerritorialADUsers RKA ON RKA.CODAGENTE = T.CODAGENTEPADRE
WHERE RKA.CODAGENTE IS NULL;
GO

ALTER TABLE Import.TerritorialADUsers ALTER COLUMN CODAGENTEPADRE NVARCHAR(20) NOT NULL;
GO

ALTER TABLE Import.TerritorialADUsers ADD SalesGroupDescription NVARCHAR(40) NULL;
GO

UPDATE T
SET T.SalesGroupDescription = UPPER(Cognome2)
FROM Import.TerritorialADUsers T
INNER JOIN dbo.Sales_PP SPP ON RIGHT(REPLICATE(N'0', 10) + CONVERT(NVARCHAR(10), SPP.COD), 10) = T.CODAGENTE;
GO

ALTER TABLE Import.TerritorialADUsers ALTER COLUMN SalesGroupDescription NVARCHAR(40) NOT NULL;
GO

ALTER TABLE Import.TerritorialADUsers ADD SalesGroupADUser NVARCHAR(40) NULL;
GO

UPDATE T
	SET T.SalesGroupADUser = COALESCE(RKA.ADUser, N'')
FROM Import.TerritorialADUsers T
LEFT JOIN Import.TerritorialADUsers RKA ON RKA.CODAGENTE = T.CODAGENTEPADRE;
GO

ALTER TABLE Import.TerritorialADUsers ALTER COLUMN SalesGroupADUser NVARCHAR(40) NOT NULL;
GO

*/

/* Aggiornare manualmente le tabelle di Import in base a quanto richiesto */
