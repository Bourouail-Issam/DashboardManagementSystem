/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 1/6: DATABASE + SCHEMAS
   Run order: 01 -> 06. Idempotent (safe to re-run).
   Three schemas separate concerns and enable per-module permissions:
     sec = identity & access     cat = product catalog     aud = audit trail
   ========================================================================== */

IF DB_ID(N'DashboardManagementSystemECommerceDB') IS NULL
    CREATE DATABASE DashboardManagementSystemECommerceDB COLLATE Latin1_General_100_CI_AS;
GO

/* RCSI keeps readers from blocking writers (needed for web workloads);
   CHECKSUM detects corruption; AUTO_CLOSE OFF avoids cold-start stalls. */
ALTER DATABASE DashboardManagementSystemECommerceDB SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
ALTER DATABASE DashboardManagementSystemECommerceDB SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE DashboardManagementSystemECommerceDB SET AUTO_CLOSE OFF;
ALTER DATABASE DashboardManagementSystemECommerceDB SET RECURSIVE_TRIGGERS OFF;
GO

USE DashboardManagementSystemECommerceDB;
GO

-- CREATE SCHEMA must be the only statement in its batch, hence dynamic SQL.
IF SCHEMA_ID(N'sec') IS NULL EXEC (N'CREATE SCHEMA sec AUTHORIZATION dbo;');
IF SCHEMA_ID(N'cat') IS NULL EXEC (N'CREATE SCHEMA cat AUTHORIZATION dbo;');
IF SCHEMA_ID(N'aud') IS NULL EXEC (N'CREATE SCHEMA aud AUTHORIZATION dbo;');
GO