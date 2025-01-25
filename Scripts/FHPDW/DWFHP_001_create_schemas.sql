/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;
GO

USE DWFHP;
GO

CREATE SCHEMA audit AUTHORIZATION dbo; -- Log vari
GO

CREATE SCHEMA Import AUTHORIZATION dbo; -- Dati importati una tantum o inseriti manualmente
GO

CREATE SCHEMA LandingDbFlorence AUTHORIZATION dbo; -- Tabelle sincronizzate con DbFlorence
GO

CREATE SCHEMA Staging AUTHORIZATION dbo; -- Tabelle di staging, contengono la logica del DWH
GO

CREATE SCHEMA Fact AUTHORIZATION dbo; -- Tabelle dei fatti
GO

CREATE SCHEMA Dim AUTHORIZATION dbo; -- Tabelle delle dimensioni di analisi
GO

CREATE SCHEMA Bridge AUTHORIZATION dbo; -- Tabelle di bridge per le relazioni molti-a-molti
GO
