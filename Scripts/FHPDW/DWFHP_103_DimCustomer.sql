/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table LandingDbFlorence.AnagraficaTerritorio
 * @description Anagrafica territorio

 * @depends DBFlorencePP.dbo._TxPP_Territorio

SELECT TOP 100 * FROM DBFlorencePP.dbo._TxPP_Territorio;
*/

IF OBJECT_ID('LandingDbFlorence.AnagraficaTerritorioView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.AnagraficaTerritorioView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.AnagraficaTerritorioView
AS
SELECT
	-- Chiavi
    T.CODSOCIETA,
    T.CODUTENTE,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CODSOCIETA,
        T.CODUTENTE,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.COGNOME,
        T.NOME,
        T.CODUTENTEPADRE,
		T.Padre_Cognome,
		T.Padre_Nome,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Attributi
    T.COGNOME,
    T.NOME,
    T.CODUTENTEPADRE,
	T.Padre_Cognome,
	T.Padre_Nome
	
FROM (

    SELECT
        TT.CODSOCIETA,
        TT.CODUTENTE,
        TT.COGNOME,
        TT.NOME,
        TT.CODUTENTEPADRE,
		TT.Padre_Cognome,
		TT.Padre_Nome

    FROM DBFlorencePP.dbo._TxPP_Territorio TT

) T;
GO

--DROP TABLE LandingDbFlorence.AnagraficaTerritorio;
GO

IF OBJECT_ID('LandingDbFlorence.AnagraficaTerritorio', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.AnagraficaTerritorio FROM LandingDbFlorence.AnagraficaTerritorioView;

END;
GO

/**
 * @procedure usp_Merge_AnagraficaTerritorio
 * @description Sincronizzazione AnagraficaTerritorio
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_AnagraficaTerritorio', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaTerritorio AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaTerritorio
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.AnagraficaTerritorio AS DST
USING LandingDbFlorence.AnagraficaTerritorioView AS SRC
ON SRC.CODSOCIETA = DST.CODSOCIETA AND SRC.CODUTENTE = DST.CODUTENTE
WHEN NOT MATCHED
    THEN INSERT (
        CODSOCIETA,
        CODUTENTE,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        COGNOME,
        NOME,
        CODUTENTEPADRE,
		Padre_Cognome,
		Padre_Nome
    )
    VALUES (
        SRC.CODSOCIETA,
        SRC.CODUTENTE,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        SRC.DatetimeInserted,
        SRC.DatetimeUpdated,
        SRC.DatetimeDeleted,
        SRC.COGNOME,
        SRC.NOME,
        SRC.CODUTENTEPADRE,
		SRC.Padre_Cognome,
		SRC.Padre_Nome
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
        DST.ChangeHashKey = SRC.ChangeHashKey,
        DST.DatetimeUpdated = SRC.DatetimeUpdated,
        DST.COGNOME = SRC.COGNOME,
		DST.NOME = SRC.NOME,
		DST.CODUTENTEPADRE = SRC.CODUTENTEPADRE,
		DST.Padre_Cognome = SRC.Padre_Cognome,
		DST.Padre_Nome = DST.Padre_Nome
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'AnagraficaTerritorio' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.CODSOCIETA, Deleted.CODSOCIETA) AS DivisionBusinessKey,
    COALESCE(Inserted.CODUTENTE, Deleted.CODUTENTE) AS TableBusinessKey
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

EXEC LandingDbFlorence.usp_Merge_AnagraficaTerritorio;
GO

SELECT * FROM LandingDbFlorence.AnagraficaTerritorio;
GO

/**
 * @table LandingDbFlorence.AnagraficaClienti
 * @description Anagrafica clienti

 * @depends DBFlorencePP.dbo._TxPP_AnagraficaGerarchia_Clienti

SELECT TOP 1 * FROM DBFlorencePP.dbo._TxPP_AnagraficaGerarchia_Clienti;
*/

IF OBJECT_ID('LandingDbFlorence.AnagraficaClientiView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.AnagraficaClientiView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.AnagraficaClientiView
AS
SELECT
	-- Chiavi
    T.CODSOCIETA,
    T.CODCLI_F,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
		T.CODSOCIETA,
        T.CODCLI_F,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CODUTENTEPADRE,
        T.DESCR,
        T.DATAINI,
        T.DATAFINE,
        T.RAGSOC1,
        T.CODAGENTE,
        T.CODCLI_STATISTICO,
        T.LIV1,
        T.LIV1_DESCR,
        T.LIV2,
        T.LIV2_DESCR,
        T.LIV3,
        T.LIV3_DESCR,
        T.LIV4,
        T.LIV4_DESCR,
        T.LIV5,
        T.LIV5_DESCR,
        T.LIV6,
        T.LIV6_DESCR,
        T.LIV7,
        T.LIV7_DESCR,
		' '
    ))) AS ChangeHashKey,
    CURRENT_TIMESTAMP AS DatetimeInserted,
    CURRENT_TIMESTAMP AS DatetimeUpdated,
    CAST('19000101' AS DATETIME) AS DatetimeDeleted,

	-- Attributi
    T.CODUTENTEPADRE,
    T.DESCR,
    T.DATAINI,
    T.DATAFINE,
    T.RAGSOC1,
    T.CODAGENTE,
    T.CODCLI_STATISTICO,
    T.LIV1,
    T.LIV1_DESCR,
    T.LIV2,
    T.LIV2_DESCR,
    T.LIV3,
    T.LIV3_DESCR,
    T.LIV4,
    T.LIV4_DESCR,
    T.LIV5,
    T.LIV5_DESCR,
    T.LIV6,
    T.LIV6_DESCR,
    T.LIV7,
    T.LIV7_DESCR
	
FROM (

    SELECT
        AGC.CODSOCIETA,
        AGC.CODCLI_F,

        AGC.CODUTENTEPADRE,
        AGC.DESCR,
        AGC.DATAINI,
        AGC.DATAFINE,
        AGC.RAGSOC1,
        AGC.CODAGENTE,
        AGC.CODCLI_STATISTICO,
        AGC.LIV1,
        AGC.LIV1_DESCR,
        AGC.LIV2,
        AGC.LIV2_DESCR,
        AGC.LIV3,
        AGC.LIV3_DESCR,
        AGC.LIV4,
        AGC.LIV4_DESCR,
        AGC.LIV5,
        AGC.LIV5_DESCR,
        AGC.LIV6,
        AGC.LIV6_DESCR,
        AGC.LIV7,
        AGC.LIV7_DESCR

    FROM DBFlorencePP.dbo._TxPP_AnagraficaGerarchia_Clienti AGC

) T;
GO

--DROP TABLE LandingDbFlorence.AnagraficaClienti;
GO

IF OBJECT_ID('LandingDbFlorence.AnagraficaClienti', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.AnagraficaClienti FROM LandingDbFlorence.AnagraficaClientiView;

END;
GO

/**
 * @procedure usp_Merge_AnagraficaClienti
 * @description Sincronizzazione AnagraficaClienti
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_AnagraficaClienti', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaClienti AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_AnagraficaClienti
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.AnagraficaClienti AS DST
USING LandingDbFlorence.AnagraficaClientiView AS SRC
ON SRC.CODSOCIETA = DST.CODSOCIETA AND SRC.CODCLI_F = DST.CODCLI_F
WHEN NOT MATCHED
    THEN INSERT (
        CODSOCIETA,
        CODCLI_F,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        CODUTENTEPADRE,
        DESCR,
        DATAINI,
        DATAFINE,
        RAGSOC1,
        CODAGENTE,
        CODCLI_STATISTICO,
        LIV1,
        LIV1_DESCR,
        LIV2,
        LIV2_DESCR,
        LIV3,
        LIV3_DESCR,
        LIV4,
        LIV4_DESCR,
        LIV5,
        LIV5_DESCR,
        LIV6,
        LIV6_DESCR,
        LIV7,
        LIV7_DESCR
    )
    VALUES (
        SRC.CODSOCIETA,
        SRC.CODCLI_F,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        SRC.DatetimeInserted,
        SRC.DatetimeUpdated,
        SRC.DatetimeDeleted,
        SRC.CODUTENTEPADRE,
        SRC.DESCR,
        SRC.DATAINI,
        SRC.DATAFINE,
        SRC.RAGSOC1,
        SRC.CODAGENTE,
        SRC.CODCLI_STATISTICO,
        SRC.LIV1,
        SRC.LIV1_DESCR,
        SRC.LIV2,
        SRC.LIV2_DESCR,
        SRC.LIV3,
        SRC.LIV3_DESCR,
        SRC.LIV4,
        SRC.LIV4_DESCR,
        SRC.LIV5,
        SRC.LIV5_DESCR,
        SRC.LIV6,
        SRC.LIV6_DESCR,
        SRC.LIV7,
        SRC.LIV7_DESCR
    )
WHEN MATCHED AND SRC.ChangeHashKey <> DST.ChangeHashKey
    THEN UPDATE SET
      DST.ChangeHashKey = SRC.ChangeHashKey,
      DST.DatetimeUpdated = SRC.DatetimeUpdated,
      DST.CODUTENTEPADRE = SRC.CODUTENTEPADRE,
      DST.DESCR = SRC.DESCR,
      DST.DATAINI = SRC.DATAINI,
      DST.DATAFINE = SRC.DATAFINE,
      DST.RAGSOC1 = SRC.RAGSOC1,
      DST.CODAGENTE = SRC.CODAGENTE,
      DST.CODCLI_STATISTICO = SRC.CODCLI_STATISTICO,
      DST.LIV1 = SRC.LIV1,
      DST.LIV1_DESCR = SRC.LIV1_DESCR,
      DST.LIV2 = SRC.LIV2,
      DST.LIV2_DESCR = SRC.LIV2_DESCR,
      DST.LIV3 = SRC.LIV3,
      DST.LIV3_DESCR = SRC.LIV3_DESCR,
      DST.LIV4 = SRC.LIV4,
      DST.LIV4_DESCR = SRC.LIV4_DESCR,
      DST.LIV5 = SRC.LIV5,
      DST.LIV5_DESCR = SRC.LIV5_DESCR,
      DST.LIV6 = SRC.LIV6,
      DST.LIV6_DESCR = SRC.LIV6_DESCR,
      DST.LIV7 = SRC.LIV7,
      DST.LIV7_DESCR = SRC.LIV7_DESCR
WHEN NOT MATCHED BY SOURCE
    THEN UPDATE SET
        DST.DatetimeDeleted = CURRENT_TIMESTAMP
OUTPUT N'LandingDbFlorence' AS SchemaName,
    N'AnagraficaClienti' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.CODSOCIETA, Deleted.CODSOCIETA) AS DivisionBusinessKey,
    COALESCE(Inserted.CODCLI_F, Deleted.CODCLI_F) AS TableBusinessKey
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

EXEC LandingDbFlorence.usp_Merge_AnagraficaClienti;
GO

SELECT * FROM LandingDbFlorence.AnagraficaClienti;
GO

/**
 * @table LandingDbFlorence.GCS
 * @description Anagrafica canale clienti

 * @depends DBFlorencePP.dbo.GCS

SELECT TOP 100 * FROM DBFlorencePP.dbo.GCS;
*/

IF OBJECT_ID('LandingDbFlorence.GCSView', N'V') IS NULL EXEC('CREATE VIEW LandingDbFlorence.GCSView AS SELECT 1 AS fld;');
GO

ALTER VIEW LandingDbFlorence.GCSView
AS
SELECT
	-- Chiavi
    T.CodCli,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CodCli,
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
        TT.CodCli,
		TT.Gruppo

    FROM DBFlorencePP.dbo.GCS TT

) T;
GO

--DROP TABLE LandingDbFlorence.GCS;
GO

IF OBJECT_ID('LandingDbFlorence.GCS', N'U') IS NULL
BEGIN

SELECT TOP 0 * INTO LandingDbFlorence.GCS FROM LandingDbFlorence.GCSView;

END;
GO

/**
 * @procedure usp_Merge_GCS
 * @description Sincronizzazione GCS
*/

IF OBJECT_ID('LandingDbFlorence.usp_Merge_GCS', N'P') IS NULL EXEC('CREATE PROCEDURE LandingDbFlorence.usp_Merge_GCS AS RETURN 0;');
GO

ALTER PROCEDURE LandingDbFlorence.usp_Merge_GCS
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO LandingDbFlorence.GCS AS DST
USING LandingDbFlorence.GCSView AS SRC
ON SRC.CodCli = DST.CodCli
WHEN NOT MATCHED
    THEN INSERT (
        CodCli,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        Gruppo
    )
    VALUES (
        SRC.CodCli,
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
    N'GCS' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'IT1C' AS DivisionBusinessKey,
    COALESCE(Inserted.CodCli, Deleted.CodCli) AS TableBusinessKey
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

EXEC LandingDbFlorence.usp_Merge_GCS;
GO

SELECT * FROM LandingDbFlorence.GCS;
GO

/**
 * @table Staging.dRegionalKeyAccount
 * @description Tabella di staging per attributo Regional Key Account

 * @depends Import.TerritorialADUsers

SELECT TOP 1 * FROM Import.TerritorialADUsers;
*/

IF OBJECT_ID('Staging.dRegionalKeyAccountView', N'V') IS NULL EXEC('CREATE VIEW Staging.dRegionalKeyAccountView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.dRegionalKeyAccountView
AS
SELECT
	-- Chiavi
    T.KeyAccountCode,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.KeyAccountCode,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.KeyAccountDescription,
        T.RegionalKeyAccountCode,
        T.RegionalKeyAccountDescription,
		' '
    ))) AS ChangeHashKey,

	-- Attributi
    T.KeyAccountDescription,
    T.RegionalKeyAccountCode,
    T.RegionalKeyAccountDescription
	
FROM (

	SELECT DISTINCT
		CODAGENTE AS KeyAccountCode,
		Description AS KeyAccountDescription,
		CODAGENTEPADRE AS RegionalKeyAccountCode,
		SalesGroupDescription AS RegionalKeyAccountDescription

	FROM Import.TerritorialADUsers

) T;
GO

--DROP TABLE Staging.dRegionalKeyAccount;
GO

IF OBJECT_ID('Staging.dRegionalKeyAccount', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.dRegionalKeyAccount FROM Staging.dRegionalKeyAccountView;

	ALTER TABLE Staging.dRegionalKeyAccount ADD CONSTRAINT PK_Staging_dRegionalKeyAccount PRIMARY KEY CLUSTERED (KeyAccountCode);

	ALTER TABLE Staging.dRegionalKeyAccount ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.dRegionalKeyAccount ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_dRegionalKeyAccount
 * @description Popolamento tabella di staging per attributo Regional Key Account
*/

IF OBJECT_ID('Staging.usp_Reload_dRegionalKeyAccount', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_dRegionalKeyAccount AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_dRegionalKeyAccount
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.dRegionalKeyAccount;

INSERT INTO Staging.dRegionalKeyAccount
(
    KeyAccountCode,
    HistoricalHashKey,
    ChangeHashKey,
    KeyAccountDescription,
    RegionalKeyAccountCode,
    RegionalKeyAccountDescription
)
SELECT
    KeyAccountCode,
    HistoricalHashKey,
    ChangeHashKey,
    KeyAccountDescription,
    RegionalKeyAccountCode,
    RegionalKeyAccountDescription

FROM Staging.dRegionalKeyAccountView;

END;
GO

EXEC Staging.usp_Reload_dRegionalKeyAccount;
GO

/**
 * @table Staging.dCustomer
 * @description Tabella di staging per dimensione Cliente

 * @depends LandingDbFlorence.AnagraficaClienti
 * @depends Dim.Division
 --* @depends LandingDbFlorence.AnagraficaTerritorio
 * @depends Staging.dRegionalKeyAccount

SELECT TOP 1 * FROM LandingDbFlorence.AnagraficaClienti;
SELECT TOP 1 * FROM Dim.Division;
--SELECT TOP 1 * FROM LandingDbFlorence.AnagraficaTerritorio;
SELECT TOP 1 * FROM Staging.dRegionalKeyAccount;
*/

IF OBJECT_ID('Staging.dCustomerView', N'V') IS NULL EXEC('CREATE VIEW Staging.dCustomerView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.dCustomerView
AS
SELECT
	-- Chiavi
    T.DivisionKey,
    T.DivisionBusinessKey,
    T.CustomerBusinessKey,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.DivisionKey,
        T.DivisionBusinessKey,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CustomerBusinessKey,
        T.RegionalKeyAccount,
        T.KeyAccountDescription,
        T.StartDate,
        T.EndDate,
        T.Customer,
        T.KeyAccountCode,
		T.KeyAccountDescription,
		T.RegionalKeyAccountDescription,
        T.CustomerStatisticCode,
        T.PPHyerarchyCode,
        T.PPLevel1Description,
        T.PPLevel2Description,
        T.PPLevel3Description,
        T.PPLevel4Description,
        T.PPLevel5Description,
        T.PPLevel6Description,
        T.PPLevel7Description,
		T.Canale,
		' '
    ))) AS ChangeHashKey,

	-- Attributi
    T.RegionalKeyAccount,
    --T.KeyAccountDescription,
    T.StartDate,
    T.EndDate,
    T.Customer,
    T.KeyAccountCode,
	T.KeyAccountDescription,
	T.RegionalKeyAccountDescription,
    T.CustomerStatisticCode,
    T.PPHyerarchyCode,
    T.PPLevel1Description,
    T.PPLevel2Description,
    T.PPLevel3Description,
    T.PPLevel4Description,
    T.PPLevel5Description,
    T.PPLevel6Description,
    T.PPLevel7Description,
	T.Canale
	
FROM (

    SELECT
	    D.DivisionKey,
	    D.DivisionBusinessKey,
        AGC.CODCLI_F AS CustomerBusinessKey,
        AGC.CODUTENTEPADRE AS RegionalKeyAccount,
        --AGC.DESCR AS KeyAccountDescription,
        AGC.DATAINI AS StartDate,
        AGC.DATAFINE AS EndDate,
        AGC.RAGSOC1 AS Customer,
        AGC.CODAGENTE AS KeyAccountCode,
		--UPPER(COALESCE(CONCAT(ATT.COGNOME, N' ', ATT.NOME), N'')) AS KeyAccountDescription,
		COALESCE(RKA.KeyAccountDescription, N'') AS KeyAccountDescription,
		--UPPER(COALESCE(CONCAT(ATT.Padre_Cognome, N' ', ATT.Padre_Nome), N'')) AS RegionalKeyAccountDescription,
        COALESCE(RKA.RegionalKeyAccountDescription, N'') AS RegionalKeyAccountDescription,
		AGC.CODCLI_STATISTICO AS CustomerStatisticCode,
        COALESCE(AGC.LIV7, N'') AS PPHyerarchyCode,
        COALESCE(AGC.LIV1_DESCR, N'') AS PPLevel1Description,
        COALESCE(AGC.LIV2_DESCR, N'') AS PPLevel2Description,
        COALESCE(AGC.LIV3_DESCR, N'') AS PPLevel3Description,
        COALESCE(AGC.LIV4_DESCR, N'') AS PPLevel4Description,
        COALESCE(AGC.LIV5_DESCR, N'') AS PPLevel5Description,
        COALESCE(AGC.LIV6_DESCR, N'') AS PPLevel6Description,
        COALESCE(AGC.LIV7_DESCR, N'') AS PPLevel7Description,
		COALESCE(GCS.Gruppo, N'') AS Canale

    FROM LandingDbFlorence.AnagraficaClienti AGC
    INNER JOIN Dim.Division D ON D.DivisionBusinessKey = AGC.CODSOCIETA
	--LEFT JOIN LandingDbFlorence.AnagraficaTerritorio ATT ON ATT.CODSOCIETA = AGC.CODSOCIETA AND ATT.CODUTENTE = AGC.CODAGENTE
	LEFT JOIN Staging.dRegionalKeyAccount RKA ON RKA.KeyAccountCode = AGC.CODAGENTE
	LEFT JOIN LandingDbFlorence.GCS GCS ON GCS.CodCli = AGC.CODCLI_F
		AND AGC.CODSOCIETA = 'IT1C'
) T;
GO

--DROP TABLE Staging.dCustomer;
GO

IF OBJECT_ID('Staging.dCustomer', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.dCustomer FROM Staging.dCustomerView;

	ALTER TABLE Staging.dCustomer ADD CONSTRAINT PK_Staging_dCustomer PRIMARY KEY CLUSTERED (DivisionBusinessKey, CustomerBusinessKey);

	ALTER TABLE Staging.dCustomer ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

	ALTER TABLE Staging.dCustomer ALTER COLUMN Customer NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN KeyAccountDescription NVARCHAR(101) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN RegionalKeyAccountDescription NVARCHAR(101) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN CustomerStatisticCode NVARCHAR(10) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPHyerarchyCode NVARCHAR(10) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel1Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel2Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel3Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel4Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel5Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel6Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN PPLevel7Description NVARCHAR(35) NOT NULL;
	ALTER TABLE Staging.dCustomer ALTER COLUMN Canale NVARCHAR(35) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_dCustomer
 * @description Popolamento tabella di staging per dimensione Cliente
*/

IF OBJECT_ID('Staging.usp_Reload_dCustomer', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_dCustomer AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_dCustomer
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.dCustomer;

INSERT INTO Staging.dCustomer
(
    DivisionKey,
    DivisionBusinessKey,
    CustomerBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    RegionalKeyAccount,
    StartDate,
    EndDate,
    Customer,
    KeyAccountCode,
    KeyAccountDescription,
    RegionalKeyAccountDescription,
    CustomerStatisticCode,
    PPHyerarchyCode,
    PPLevel1Description,
    PPLevel2Description,
    PPLevel3Description,
    PPLevel4Description,
    PPLevel5Description,
    PPLevel6Description,
    PPLevel7Description,
	Canale
)
SELECT
    DivisionKey,
    DivisionBusinessKey,
    CustomerBusinessKey,
    HistoricalHashKey,
    ChangeHashKey,
    RegionalKeyAccount,
    StartDate,
    EndDate,
    Customer,
    KeyAccountCode,
    KeyAccountDescription,
    RegionalKeyAccountDescription,
    CustomerStatisticCode,
    PPHyerarchyCode,
    PPLevel1Description,
    PPLevel2Description,
    PPLevel3Description,
    PPLevel4Description,
    PPLevel5Description,
    PPLevel6Description,
    PPLevel7Description,
	Canale

FROM Staging.dCustomerView;

END;
GO

EXEC Staging.usp_Reload_dCustomer;
GO

/**
 * @table Dim.Customer
 * @description Dimensione Cliente

 * @depends Staging.dCustomer

SELECT TOP 1 * FROM Staging.dCustomer;
*/

--DROP TABLE Dim.Customer; DROP SEQUENCE dbo.seq_Customer;
GO

IF OBJECT_ID('dbo.seq_Customer', 'SO') IS NULL
BEGIN

	CREATE SEQUENCE dbo.seq_Customer
	AS INT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE
	CACHE 1000;

END;
GO

--DROP TABLE Bridge.CustomerADUser; DROP TABLE Fact.Sales; DROP TABLE Dim.Customer;
GO

IF OBJECT_ID('Dim.Customer') IS NULL
BEGIN

	SELECT TOP 0 
		-- Chiavi
        DivisionKey,
        DivisionBusinessKey,
        CustomerBusinessKey,
        CAST(1 AS INT) AS CustomerKey,

        -- Data warehouse
        HistoricalHashKey,
        ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid,

        -- Attributi
        RegionalKeyAccount,
        StartDate,
        EndDate,
        Customer,
        KeyAccountCode,
        KeyAccountDescription,
        RegionalKeyAccountDescription,
        CustomerStatisticCode,
        PPHyerarchyCode,
        PPLevel1Description,
        PPLevel2Description,
        PPLevel3Description,
        PPLevel4Description,
        PPLevel5Description,
        PPLevel6Description,
        PPLevel7Description,
		Canale

	INTO Dim.Customer

	FROM Staging.dCustomer;

	ALTER TABLE Dim.Customer ALTER COLUMN CustomerKey INT NOT NULL;

	ALTER TABLE Dim.Customer ADD CONSTRAINT DFT_Dim_Customer_CustomerKey DEFAULT (NEXT VALUE FOR dbo.seq_Customer) FOR CustomerKey;

	ALTER TABLE Dim.Customer ADD CONSTRAINT PK_Dim_Customer PRIMARY KEY CLUSTERED (CustomerKey);

    ALTER TABLE Dim.Customer ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Dim.Customer ALTER COLUMN IsRowValid BIT NOT NULL;

	ALTER TABLE Dim.Customer ADD CONSTRAINT FK_Dim_Customer_DivisionKey FOREIGN KEY (DivisionKey) REFERENCES Dim.Division (DivisionKey);	

	CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Customer_DivisionBusinessKey_CustomerBusinessKey ON Dim.Customer (DivisionBusinessKey, CustomerBusinessKey);

	INSERT INTO Dim.Customer
	(
	    DivisionKey,
	    DivisionBusinessKey,
	    CustomerBusinessKey,
		CustomerKey,
	    HistoricalHashKey,
	    ChangeHashKey,
		DatetimeInserted,
		DatetimeUpdated,
		DatetimeDeleted,
		IsRowValid,
	    RegionalKeyAccount,
	    StartDate,
	    EndDate,
	    Customer,
	    KeyAccountCode,
	    KeyAccountDescription,
	    RegionalKeyAccountDescription,
	    CustomerStatisticCode,
	    PPHyerarchyCode,
	    PPLevel1Description,
	    PPLevel2Description,
	    PPLevel3Description,
	    PPLevel4Description,
	    PPLevel5Description,
	    PPLevel6Description,
	    PPLevel7Description,
		Canale
	)
	SELECT
	    D.DivisionKey,         -- DivisionKey - tinyint
	    D.DivisionBusinessKey,        -- DivisionBusinessKey - char(4)
	    N'',       -- CustomerBusinessKey - nvarchar(10)
		-D.DivisionKey,       -- CustomerKey - int
	    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            D.DivisionKey,
		    ' '
        ))) AS HistoricalHashKey,
        CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            D.DivisionKey,
		    ' '
        ))) AS ChangeHashKey,
		CURRENT_TIMESTAMP AS DatetimeInserted,
		CURRENT_TIMESTAMP AS DatetimeUpdated,
		CAST('19000101' AS DATETIME) AS DatetimeDeleted,
		CAST(1 AS BIT) AS IsRowValid,
	    '',        -- RegionalKeyAccount - varchar(3)
	    CAST('19000101'  AS DATE), -- StartDate - date
	    CAST('19000101'  AS DATE), -- EndDate - date
	    N'',       -- Customer - nvarchar(35)
	    N'',       -- KeyAccountCode - nvarchar(10)
	    N'',       -- KeyAccountDescription - nvarchar(101)
	    N'',       -- RegionalKeyAccountDescription - nvarchar(101)
	    N'',       -- CustomerStatisticCode - nvarchar(10)
	    N'',       -- PPHyerarchyCode - nvarchar(10)
	    N'',       -- PPLevel1Description - nvarchar(35)
	    N'',       -- PPLevel2Description - nvarchar(35)
	    N'',       -- PPLevel3Description - nvarchar(35)
	    N'',       -- PPLevel4Description - nvarchar(35)
	    N'',       -- PPLevel5Description - nvarchar(35)
	    N'',       -- PPLevel6Description - nvarchar(35)
	    N'',       -- PPLevel7Description - nvarchar(35)
	    N''        -- Canale - nvarchar(35)
	
	FROM Dim.Division D
	
	UNION ALL
	
	SELECT
	    D.DivisionKey,         -- DivisionKey - tinyint
	    D.DivisionBusinessKey,        -- DivisionBusinessKey - char(4)
	    N'???',       -- CustomerBusinessKey - nvarchar(10)
	    -100-D.DivisionKey,       -- CustomerKey - int
	    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            -100-D.DivisionKey,
		    ' '
        ))) AS HistoricalHashKey,
        CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
            -100-D.DivisionKey,
		    ' '
        ))) AS ChangeHashKey,
		CURRENT_TIMESTAMP AS DatetimeInserted,
		CURRENT_TIMESTAMP AS DatetimeUpdated,
		CAST('19000101' AS DATETIME) AS DatetimeDeleted,
		CAST(1 AS BIT) AS IsRowValid,
	    '',        -- RegionalKeyAccount - varchar(3)
	    CAST('19000101'  AS DATE), -- StartDate - date
	    CAST('19000101'  AS DATE), -- EndDate - date
	    N'<???>',       -- Customer - nvarchar(35)
	    N'',       -- KeyAccountCode - nvarchar(10)
	    N'',       -- KeyAccountDescription - nvarchar(101)
	    N'',       -- RegionalKeyAccountDescription - nvarchar(101)
	    N'???',       -- CustomerStatisticCode - nvarchar(10)
	    N'',       -- PPHyerarchyCode - nvarchar(10)
	    N'',       -- PPLevel1Description - nvarchar(35)
	    N'',       -- PPLevel2Description - nvarchar(35)
	    N'',       -- PPLevel3Description - nvarchar(35)
	    N'',       -- PPLevel4Description - nvarchar(35)
	    N'',       -- PPLevel5Description - nvarchar(35)
	    N'',       -- PPLevel6Description - nvarchar(35)
	    N'',       -- PPLevel7Description - nvarchar(35)
	    N''        -- Canale - nvarchar(35)
	
	FROM Dim.Division D;

END;
GO

/**
 * @procedure Dim.usp_Merge_Customer
 * @description Aggiornamento dimensione Cliente
*/

IF OBJECT_ID('Dim.usp_Merge_Customer', N'P') IS NULL EXEC('CREATE PROCEDURE Dim.usp_Merge_Customer AS RETURN 0;');
GO

ALTER PROCEDURE Dim.usp_Merge_Customer
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Dim.Customer AS TGT
USING Staging.dCustomer AS SRC ON (
    SRC.DivisionBusinessKey = TGT.DivisionBusinessKey
    AND SRC.CustomerBusinessKey = TGT.CustomerBusinessKey
)
WHEN NOT MATCHED
    THEN INSERT (
        DivisionKey,
        DivisionBusinessKey,
        CustomerBusinessKey,
        --CustomerKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
        RegionalKeyAccount,
        StartDate,
        EndDate,
        Customer,
        KeyAccountCode,
        KeyAccountDescription,
        RegionalKeyAccountDescription,
        CustomerStatisticCode,
        PPHyerarchyCode,
        PPLevel1Description,
        PPLevel2Description,
        PPLevel3Description,
        PPLevel4Description,
        PPLevel5Description,
        PPLevel6Description,
        PPLevel7Description,
		Canale
    )
    VALUES (
        SRC.DivisionKey,
        SRC.DivisionBusinessKey,
        SRC.CustomerBusinessKey,
		--CustomerKey,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CAST('19000101' AS DATETIME),
        CAST(1 AS BIT),
        SRC.RegionalKeyAccount,
        SRC.StartDate,
        SRC.EndDate,
        SRC.Customer,
        SRC.KeyAccountCode,
        SRC.KeyAccountDescription,
        SRC.RegionalKeyAccountDescription,
        SRC.CustomerStatisticCode,
        SRC.PPHyerarchyCode,
        SRC.PPLevel1Description,
        SRC.PPLevel2Description,
        SRC.PPLevel3Description,
        SRC.PPLevel4Description,
        SRC.PPLevel5Description,
        SRC.PPLevel6Description,
        SRC.PPLevel7Description,
		SRC.Canale
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP,
		TGT.RegionalKeyAccount = SRC.RegionalKeyAccount,
		TGT.StartDate = SRC.StartDate,
		TGT.EndDate = SRC.EndDate,
		TGT.Customer = SRC.Customer,
		TGT.KeyAccountCode = SRC.KeyAccountCode,
		TGT.KeyAccountDescription = SRC.KeyAccountDescription,
		TGT.RegionalKeyAccountDescription = SRC.RegionalKeyAccountDescription,
		TGT.CustomerStatisticCode = SRC.CustomerStatisticCode,
		TGT.PPHyerarchyCode = SRC.PPHyerarchyCode,
		TGT.PPLevel1Description = SRC.PPLevel1Description,
		TGT.PPLevel2Description = SRC.PPLevel2Description,
		TGT.PPLevel3Description = SRC.PPLevel3Description,
		TGT.PPLevel4Description = SRC.PPLevel4Description,
		TGT.PPLevel5Description = SRC.PPLevel5Description,
		TGT.PPLevel6Description = SRC.PPLevel6Description,
		TGT.PPLevel7Description = SRC.PPLevel7Description,
		TGT.Canale = SRC.Canale
--WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Dim' AS SchemaName,
    N'Customer' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    COALESCE(Inserted.DivisionBusinessKey, Deleted.DivisionBusinessKey) AS DivisionBusinessKey,
    COALESCE(Inserted.CustomerBusinessKey, Deleted.CustomerBusinessKey) AS TableBusinessKey
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
    N'Customer' AS TableName,
    'DELETE' AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    DST.DivisionBusinessKey,
    DST.CustomerBusinessKey AS TableBusinessKey

FROM Dim.Customer DST
LEFT JOIN Staging.dCustomer SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.CustomerBusinessKey = DST.CustomerBusinessKey
WHERE DST.CustomerKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.CustomerBusinessKey IS NULL;

UPDATE DST
    SET DST.IsRowValid = CAST(0 AS BIT),
    DST.DatetimeDeleted = CURRENT_TIMESTAMP

FROM Dim.Customer DST
LEFT JOIN Staging.dCustomer SRC ON SRC.DivisionBusinessKey = DST.DivisionBusinessKey AND SRC.CustomerBusinessKey = DST.CustomerBusinessKey
WHERE DST.CustomerKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.CustomerBusinessKey IS NULL;

END;
GO

EXEC Dim.usp_Merge_Customer;
GO

SELECT * FROM audit.MergeLogDetails;
GO

/**
 * @table Staging.dADUser
 * @description Tabella di staging per dimensione Utente Active Directory

 * @depends Import.TerritorialADUsers
 * @depends Import.AdministrativeADUsers

SELECT TOP 1 * FROM Import.TerritorialADUsers;
SELECT TOP 1 * FROM Import.AdministrativeADUsers;
*/

IF OBJECT_ID('Staging.dADUserView', N'V') IS NULL EXEC('CREATE VIEW Staging.dADUserView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.dADUserView
AS
SELECT
	-- Chiavi
	N'FHP' AS ADDomain,
	T.ADUser,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.ADUser,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.UserType,
		' '
    ))) AS ChangeHashKey,

	-- Attributi
    T.UserType
	
FROM (

    SELECT DISTINCT
		TADU.ADUser,
		N'Sales' AS UserType

	FROM Import.TerritorialADUsers TADU
	WHERE TADU.ADUser <> N'<nessuno>'

	UNION

	SELECT
		AADU.ADUser,
		N'Administrative' AS UserType

	FROM Import.AdministrativeADUsers AADU

) T;
GO

--DROP TABLE Staging.dADUser;
GO

IF OBJECT_ID('Staging.dADUser', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.dADUser FROM Staging.dADUserView;

	ALTER TABLE Staging.dADUser ADD CONSTRAINT PK_Staging_dADUser PRIMARY KEY CLUSTERED (ADDomain, ADUser);

	ALTER TABLE Staging.dADUser ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.dADUser ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_dADUser
 * @description Popolamento tabella di staging per dimensione Utente Active Directory
*/

IF OBJECT_ID('Staging.usp_Reload_dADUser', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_dADUser AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_dADUser
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.dADUser;

INSERT INTO Staging.dADUser
(
    ADDomain,
    ADUser,
    HistoricalHashKey,
    ChangeHashKey,
    UserType
)
SELECT
    ADDomain,
    ADUser,
    HistoricalHashKey,
    ChangeHashKey,
    UserType

FROM Staging.dADUserView;

END;
GO

EXEC Staging.usp_Reload_dADUser;
GO

/**
 * @table Dim.ADUser
 * @description Dimensione Utente Active Directory

 * @depends Staging.dADUser

SELECT TOP 1 * FROM Staging.dADUser;
*/

--DROP TABLE Dim.ADUser; DROP SEQUENCE dbo.seq_ADUser;
GO

IF OBJECT_ID('dbo.seq_ADUser', 'SO') IS NULL
BEGIN

	CREATE SEQUENCE dbo.seq_ADUser
	AS INT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE
	CACHE 1000;

END;
GO

--DROP TABLE Bridge.CustomerADUser; DROP TABLE Dim.ADUser;
GO

IF OBJECT_ID('Dim.ADUser') IS NULL
BEGIN

	SELECT TOP 0 
		-- Chiavi
		ADDomain,
        ADUser,
        CAST(1 AS INT) AS ADUserKey,

        -- Data warehouse
        HistoricalHashKey,
        ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid,

        -- Attributi
        UserType

	INTO Dim.ADUser

	FROM Staging.dADUser;

	ALTER TABLE Dim.ADUser ALTER COLUMN ADUserKey INT NOT NULL;

	ALTER TABLE Dim.ADUser ADD CONSTRAINT DFT_Dim_ADUser_ADUserKey DEFAULT (NEXT VALUE FOR dbo.seq_ADUser) FOR ADUserKey;

	ALTER TABLE Dim.ADUser ADD CONSTRAINT PK_Dim_ADUser PRIMARY KEY CLUSTERED (ADUserKey);

    ALTER TABLE Dim.ADUser ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Dim.ADUser ALTER COLUMN IsRowValid BIT NOT NULL;

	CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_ADUser_DivisionBusinessKey_ADUserBusinessKey ON Dim.ADUser (ADDomain, ADUser);

END;
GO

/**
 * @procedure Dim.usp_Merge_ADUser
 * @description Aggiornamento dimensione Utenti Active Directory
*/

IF OBJECT_ID('Dim.usp_Merge_ADUser', N'P') IS NULL EXEC('CREATE PROCEDURE Dim.usp_Merge_ADUser AS RETURN 0;');
GO

ALTER PROCEDURE Dim.usp_Merge_ADUser
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Dim.ADUser AS TGT
USING Staging.dADUser AS SRC ON (
    SRC.ADDomain = TGT.ADDomain
    AND SRC.ADUser = TGT.ADUser
)
WHEN NOT MATCHED
    THEN INSERT (
        ADDomain,
		ADUser,
        --ADUserKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid,
		UserType
    )
    VALUES (
        SRC.ADDomain,
        SRC.ADUser,
		--ADUserKey,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CAST('19000101' AS DATETIME),
        CAST(1 AS BIT),
        SRC.UserType
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP,
		TGT.UserType = SRC.UserType
--WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Dim' AS SchemaName,
    N'ADUser' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'' AS DivisionBusinessKey,
    COALESCE(Inserted.ADDomain, Deleted.ADDomain) + N'\' + COALESCE(Inserted.ADUser, Deleted.ADUser) AS TableBusinessKey
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
    N'ADUser' AS TableName,
    'DELETE' AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'' AS DivisionBusinessKey,
    DST.ADDomain + N'\' + DST.ADUser AS TableBusinessKey

FROM Dim.ADUser DST
LEFT JOIN Staging.dADUser SRC ON SRC.ADDomain = DST.ADDomain AND SRC.ADUser = DST.ADUser
WHERE DST.ADUserKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ADUser IS NULL;

UPDATE DST
    SET DST.IsRowValid = CAST(0 AS BIT),
    DST.DatetimeDeleted = CURRENT_TIMESTAMP

FROM Dim.ADUser DST
LEFT JOIN Staging.dADUser SRC ON SRC.ADDomain = DST.ADDomain AND SRC.ADUser = DST.ADUser
WHERE DST.ADUserKey > 0
    AND DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.ADUser IS NULL;

END;
GO

EXEC Dim.usp_Merge_ADUser;
GO

/**
 * @table Staging.bCustomerADUser
 * @description Tabella di staging per tabella di relazione Cliente / Utente Active Directory

 * @depends Dim.Customer
 * @depends Staging.dCustomer
 * @depends Import.TerritorialADUsers
 * @depends Dim.ADUser
 * @depends Import.AdministrativeADUsers

SELECT TOP 1 * FROM Dim.Customer;
SELECT TOP 1 * FROM Staging.dCustomer;
SELECT TOP 1 * FROM Import.TerritorialADUsers;
SELECT TOP 1 * FROM Dim.ADUser;
SELECT TOP 1 * FROM Import.AdministrativeADUsers;
*/

IF OBJECT_ID('Staging.bCustomerADUserView', N'V') IS NULL EXEC('CREATE VIEW Staging.bCustomerADUserView AS SELECT 1 AS fld;');
GO

ALTER VIEW Staging.bCustomerADUserView
AS
SELECT
	-- Chiavi
	T.CustomerKey,
	ADU.ADUserKey,

    -- Data warehouse
	CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        T.CustomerKey,
		ADU.ADUserKey,
		' '
    ))) AS HistoricalHashKey,
    CONVERT(VARBINARY(20), HASHBYTES('MD5', CONCAT(
        ADU.ADUserKey,
		' '
    ))) AS ChangeHashKey
	
FROM (

    SELECT
		C.CustomerKey,
		U.ADDomain,
		TADU.ADUser

	FROM Dim.Customer C
	INNER JOIN Staging.dCustomer StgC ON StgC.DivisionBusinessKey = C.DivisionBusinessKey AND StgC.CustomerBusinessKey = C.CustomerBusinessKey
	INNER JOIN Import.TerritorialADUsers TADU ON TADU.CODAGENTE = C.KeyAccountCode
	INNER JOIN Dim.ADUser U ON U.ADDomain = N'FHP' AND U.ADUser = TADU.ADUser

	UNION

	SELECT DISTINCT
		C.CustomerKey,
		U.ADDomain,
		RTADU.ADUser

	FROM Dim.Customer C
	INNER JOIN Staging.dCustomer StgC ON StgC.DivisionBusinessKey = C.DivisionBusinessKey AND StgC.CustomerBusinessKey = C.CustomerBusinessKey
	INNER JOIN Import.TerritorialADUsers TADU ON TADU.CODAGENTE = C.KeyAccountCode
	INNER JOIN Import.TerritorialADUsers RTADU ON RTADU.CODAGENTE = TADU.CODAGENTEPADRE
	INNER JOIN Dim.ADUser U ON U.ADDomain = N'FHP' AND U.ADUser = RTADU.ADUser

	UNION

	SELECT
		C.CustomerKey,
		U.ADDomain,
		AADU.ADUser

	FROM Dim.Customer C
	CROSS JOIN Import.AdministrativeADUsers AADU
	INNER JOIN Dim.ADUser U ON U.ADDomain = N'FHP' AND U.ADUser = AADU.ADUser

) T
INNER JOIN Dim.ADUser ADU ON ADU.ADDomain = T.ADDomain AND ADU.ADUser = T.ADUser;;
GO

--DROP TABLE Staging.bCustomerADUser;
GO

IF OBJECT_ID('Staging.bCustomerADUser', N'U') IS NULL
BEGIN

    SELECT TOP 0 * INTO Staging.bCustomerADUser FROM Staging.bCustomerADUserView;

	ALTER TABLE Staging.bCustomerADUser ADD CONSTRAINT PK_Staging_bCustomerADUser PRIMARY KEY CLUSTERED (CustomerKey, ADUserKey);

	ALTER TABLE Staging.bCustomerADUser ALTER COLUMN HistoricalHashKey VARBINARY(20) NOT NULL;
	ALTER TABLE Staging.bCustomerADUser ALTER COLUMN ChangeHashKey VARBINARY(20) NOT NULL;

END;
GO

/**
 * @procedure Staging.usp_Reload_bCustomerADUser
 * @description Popolamento tabella di staging per tabella di relazione Cliente / Utente Active Directory
*/

IF OBJECT_ID('Staging.usp_Reload_bCustomerADUser', N'P') IS NULL EXEC('CREATE PROCEDURE Staging.usp_Reload_bCustomerADUser AS RETURN 0;');
GO

ALTER PROCEDURE Staging.usp_Reload_bCustomerADUser
AS
BEGIN

SET NOCOUNT ON;

TRUNCATE TABLE Staging.bCustomerADUser;

INSERT INTO Staging.bCustomerADUser
(
    CustomerKey,
    ADUserKey,
    HistoricalHashKey,
    ChangeHashKey
)
SELECT
    CustomerKey,
    ADUserKey,
    HistoricalHashKey,
    ChangeHashKey

FROM Staging.bCustomerADUserView;

END;
GO

EXEC Staging.usp_Reload_bCustomerADUser;
GO

/**
 * @table Bridge.CustomerADUser
 * @description Tabella di relazione Cliente / Utente Active Directory

 * @depends Staging.bCustomerADUser

SELECT TOP 1 * FROM Staging.bCustomerADUser;
*/

--DROP TABLE Bridge.CustomerADUser;
GO

IF OBJECT_ID('Bridge.CustomerADUser') IS NULL
BEGIN

	SELECT TOP 0 
		-- Chiavi
		CustomerKey,
        ADUserKey,

        -- Data warehouse
        BCADU.HistoricalHashKey,
        BCADU.ChangeHashKey,
        CURRENT_TIMESTAMP AS DatetimeInserted,
        CURRENT_TIMESTAMP AS DatetimeUpdated,
        CAST('19000101' AS DATETIME) AS DatetimeDeleted,
        CAST(1 AS BIT) AS IsRowValid

	INTO Bridge.CustomerADUser

	FROM Staging.bCustomerADUser BCADU;

	ALTER TABLE Bridge.CustomerADUser ADD CONSTRAINT PK_Bridge_CustomerADUser PRIMARY KEY CLUSTERED (CustomerKey, ADUserKey);

    ALTER TABLE Bridge.CustomerADUser ALTER COLUMN DatetimeDeleted DATETIME NOT NULL;
    ALTER TABLE Bridge.CustomerADUser ALTER COLUMN IsRowValid BIT NOT NULL;

	ALTER TABLE Bridge.CustomerADUser ADD CONSTRAINT FK_Bridge_CustomerADUser_CustomerKey FOREIGN KEY (CustomerKey) REFERENCES Dim.Customer (CustomerKey);
	ALTER TABLE Bridge.CustomerADUser ADD CONSTRAINT FK_Bridge_CustomerADUser_ADUser FOREIGN KEY (ADUserKey) REFERENCES Dim.ADUser (ADUserKey);

END;
GO

/**
 * @procedure Bridge.usp_Merge_CustomerADUser
 * @description Aggiornamento tabella di relazione Cliente / Utente Active Directory
*/

IF OBJECT_ID('Bridge.usp_Merge_CustomerADUser', N'P') IS NULL EXEC('CREATE PROCEDURE Bridge.usp_Merge_CustomerADUser AS RETURN 0;');
GO

ALTER PROCEDURE Bridge.usp_Merge_CustomerADUser
AS
BEGIN

SET NOCOUNT ON;

MERGE INTO Bridge.CustomerADUser AS TGT
USING Staging.bCustomerADUser AS SRC ON (
	SRC.CustomerKey = TGT.CustomerKey
    AND SRC.ADUserKey = TGT.ADUserKey
)
WHEN NOT MATCHED
    THEN INSERT (
		CustomerKey,
		ADUserKey,
        HistoricalHashKey,
        ChangeHashKey,
        DatetimeInserted,
        DatetimeUpdated,
        DatetimeDeleted,
        IsRowValid
    )
    VALUES (
		SRC.CustomerKey,
        SRC.ADUserKey,
        SRC.HistoricalHashKey,
        SRC.ChangeHashKey,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CAST('19000101' AS DATETIME),
        CAST(1 AS BIT)
    )
WHEN MATCHED AND TGT.ChangeHashKey <> SRC.ChangeHashKey
    THEN UPDATE SET
        TGT.ChangeHashKey = SRC.ChangeHashKey,
        TGT.DatetimeUpdated = CURRENT_TIMESTAMP
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT N'Bridge' AS SchemaName,
    N'CustomerADUser' AS TableName,
    $action AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'' AS DivisionBusinessKey,
    CONVERT(NVARCHAR(10), COALESCE(Inserted.CustomerKey, Deleted.CustomerKey)) + ' ' + CONVERT(NVARCHAR(10), COALESCE(Inserted.ADUserKey, Deleted.ADUserKey)) AS TableBusinessKey
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
    N'Bridge' AS SchemaName,
    N'CustomerADUser' AS TableName,
    'DELETE' AS MergeAction,
    CURRENT_TIMESTAMP AS MergeDatetime,
    N'' AS DivisionBusinessKey,
    CONVERT(NVARCHAR(10), DST.CustomerKey) + ' ' + CONVERT(NVARCHAR(10), DST.ADUserKey) AS TableBusinessKey

FROM Bridge.CustomerADUser DST
LEFT JOIN Staging.bCustomerADUser SRC ON SRC.CustomerKey = DST.CustomerKey AND SRC.ADUserKey = DST.ADUserKey
WHERE DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.CustomerKey IS NULL;

UPDATE DST
    SET DST.IsRowValid = CAST(0 AS BIT),
    DST.DatetimeDeleted = CURRENT_TIMESTAMP

FROM Bridge.CustomerADUser DST
LEFT JOIN Staging.bCustomerADUser SRC ON SRC.CustomerKey = DST.CustomerKey AND SRC.ADUserKey = DST.ADUserKey
WHERE DST.IsRowValid = CAST(1 AS BIT)
    AND SRC.CustomerKey IS NULL;

END;
GO

EXEC Bridge.usp_Merge_CustomerADUser;
GO
