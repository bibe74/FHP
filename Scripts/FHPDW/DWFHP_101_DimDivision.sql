/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table Dim.Division
 * @description Dimensione Società
*/

--DROP TABLE Dim.Division;
GO

IF OBJECT_ID('Dim.Division') IS NULL
BEGIN

	CREATE TABLE Dim.Division (
		DivisionKey TINYINT NOT NULL CONSTRAINT PK_Dim_Division PRIMARY KEY CLUSTERED,
		DivisionBusinessKey CHAR(4) NOT NULL,
		DivisionDescription NVARCHAR(20) NOT NULL
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Division_DivisionBusinessKey ON Dim.Division (DivisionBusinessKey);

	INSERT INTO Dim.Division (
		DivisionKey,
		DivisionBusinessKey,
		DivisionDescription
	)
	SELECT 1, 'IT1C', N'Consumer'
	UNION ALL SELECT 2, 'IT1P', N'Professional';

END;
GO

SELECT * FROM Dim.Division;
GO
