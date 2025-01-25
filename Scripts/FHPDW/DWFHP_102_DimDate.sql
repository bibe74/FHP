/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

/**
 * @table Dim.Date
 * @description Dimensione Data
*/

--DROP TABLE Dim.Date;
GO

IF OBJECT_ID('Dim.Date') IS NULL
BEGIN

    SELECT
        D.DateKey,
        D.Date,
        CAST(D.Date AS DATETIME) AS Datetime,
        D.FullDateIT AS DateNameIT,
        YEAR(D.Date) AS Year,
        D.Year AS YearNameIT,
        CASE WHEN MONTH(D.Date) < 7 THEN 'H1' ELSE 'H2' END AS Semester,
        D.Year + CASE WHEN MONTH(D.Date) < 7 THEN 'H1' ELSE 'H2' END AS SemesterYear,
        CASE WHEN MONTH(D.Date) < 7 THEN 'H1' ELSE 'H2' END + ' ' + D.Year AS SemesterYearNameIT,
        D.Quarter,
        D.Year + 'Q' + D.Quarter AS QuarterYear,
        'Q' + D.Quarter + ' ' + D.Year AS QuarterYearNameIT,
        MONTH(D.Date) AS Month,
        D.MonthNameIT,
        YEAR(D.Date) * 100 + MONTH(D.Date) AS MonthYear,
        D.MonthNameIT + ' ' + D.Year AS MonthYearNameIT,
        D.DayOfMonth,
        D.DayOfWeekUK AS DayOfWeek,
        D.DayNameIT AS DayOfWeekNameIT,
        CAST(0 AS BIT) AS MonthIsClosed,
		CAST(0 AS BIT) AS MonthIsCurrent,
		CAST(0 AS BIT) AS MonthIsPrevious

    INTO Dim.Date

    FROM tools.dbo.DimDate D
    WHERE D.DateKey BETWEEN 20180101 AND 20191231;

    ALTER TABLE Dim.Date ADD CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED (DateKey);

    ALTER TABLE Dim.Date ALTER COLUMN MonthIsClosed BIT NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Date_Date ON Dim.Date (Date);
    CREATE UNIQUE NONCLUSTERED INDEX IX_Dim_Date_Datetime ON Dim.Date (Datetime);

    INSERT INTO Dim.Date
    (
        DateKey,
        Date,
        Datetime,
        DateNameIT,
        Year,
        YearNameIT,
        Semester,
        SemesterYear,
        SemesterYearNameIT,
        Quarter,
        QuarterYear,
        QuarterYearNameIT,
        Month,
        MonthNameIT,
        MonthYear,
        MonthYearNameIT,
        DayOfMonth,
        DayOfWeek,
        DayOfWeekNameIT,
        MonthIsClosed,
		MonthIsCurrent,
		MonthIsPrevious
    )
    VALUES
    (   -1,         -- DateKey - int
        CAST('19000101' AS DATE), -- Date - date
        CAST('19000101' AS DATETIME), -- Datetime - datetime
        '',        -- DateNameIT - char(10)
        0,         -- Year - int
        '',        -- YearNameIT - char(4)
        '',        -- Semester - varchar(2)
        '',        -- SemesterYear - varchar(6)
        '',        -- SemesterYearNameIT - varchar(7)
        '',        -- Quarter - char(1)
        '',        -- QuarterYear - varchar(6)
        '',        -- QuarterYearNameIT - varchar(7)
        0,         -- Month - int
        '',        -- MonthNameIT - varchar(9)
        0,         -- MonthYear - int
        '',        -- MonthYearNameIT - varchar(14)
        '',        -- DayOfMonth - varchar(2)
        '',        -- DayOfWeek - char(1)
        '',        -- DayOfWeekNameIT - varchar(9)
        0,         -- MonthIsClosed - bit
        0,         -- MonthIsCurrent - bit
        0          -- MonthIsPrevious - bit
    );

END;
GO

IF OBJECT_ID('Dim.usp_ClosePastMonths', N'P') IS NULL EXEC('CREATE PROCEDURE Dim.usp_ClosePastMonths AS RETURN 0;');
GO

ALTER PROCEDURE Dim.usp_ClosePastMonths (
	@CurrentDate DATETIME2 = NULL
)
AS
BEGIN

SET NOCOUNT ON;

IF (@CurrentDate IS NULL) SET @CurrentDate = CURRENT_TIMESTAMP;

UPDATE Dim.Date
SET MonthIsClosed = CAST(0 AS BIT),
	MonthIsCurrent = CAST(0 AS BIT),
	MonthIsPrevious = CAST(0 AS BIT);

UPDATE Dim.Date
SET MonthIsClosed = CAST(1 AS BIT)
WHERE Date <= DATEADD(DAY, -DATEPART(DAY, @CurrentDate), @CurrentDate);

UPDATE Dim.Date
SET MonthIsCurrent = CAST(1 AS BIT)
WHERE Year = YEAR(@CurrentDate)
	AND Month = MONTH(@CurrentDate);

UPDATE Dim.Date
SET MonthIsPrevious = CAST(1 AS BIT)
WHERE Year = YEAR(DATEADD(DAY, -DATEPART(DAY, @CurrentDate), @CurrentDate))
	AND Month = MONTH(DATEADD(DAY, -DATEPART(DAY, @CurrentDate), @CurrentDate));

END;
GO

EXEC Dim.usp_ClosePastMonths;
GO

SELECT * FROM Dim.Date;
GO
