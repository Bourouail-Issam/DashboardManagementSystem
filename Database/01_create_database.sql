/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO BUILD | FILE 1/4: DATABASE + CONFIGURATION + SCHEMAS
   ----------------------------------------------------------------------------
   Run order: 01 -> 02 -> 03 -> 04          Idempotent: safe to re-run.

   Design conventions applied across all four files:
     - Three schemas separate concerns and enable per-module permissions:
         sec = identity & access (People, Users, Roles)
         cat = product catalog (categories, types, attributes, variants)
         aud = immutable audit trail (InventoryLog, procedures)
     - Explicit collation so behavior never depends on server defaults.
     - Named constraints only; no anonymous constraints in production DDL.
   ========================================================================== */

IF DB_ID(N'DashboardManagementSystemECommerceDB') IS NULL
BEGIN
    CREATE DATABASE DashboardManagementSystemECommerceDB COLLATE Latin1_General_100_CI_AS;
END
GO

/* Instance-independent database settings required for production:
   RCSI lets readers not block writers (mandatory for web workloads),
   CHECKSUM detects page corruption, AUTO_CLOSE OFF avoids cold-start stalls. */
ALTER DATABASE DashboardManagementSystemECommerceDB SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
ALTER DATABASE DashboardManagementSystemECommerceDB SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE DashboardManagementSystemECommerceDB SET AUTO_CLOSE OFF;
ALTER DATABASE DashboardManagementSystemECommerceDB SET RECURSIVE_TRIGGERS OFF;
GO

USE DashboardManagementSystemECommerceDB;
GO

/* ---------------------------------------------------------------------------
   Schemas (created via dynamic SQL because CREATE SCHEMA must be the only
   statement in its batch).
   --------------------------------------------------------------------------- */
IF SCHEMA_ID(N'sec') IS NULL EXEC (N'CREATE SCHEMA sec AUTHORIZATION dbo;');
IF SCHEMA_ID(N'cat') IS NULL EXEC (N'CREATE SCHEMA cat AUTHORIZATION dbo;');
IF SCHEMA_ID(N'aud') IS NULL EXEC (N'CREATE SCHEMA aud AUTHORIZATION dbo;');
GO
