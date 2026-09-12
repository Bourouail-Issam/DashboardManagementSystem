/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 4/6: AUDIT LAYER
   1. aud.InventoryLog (immutable stock/price history)  2. aud.LogErrors
   (error store) — plus the audit trigger and read-only shields.

   DESIGN NOTES:
   - No FK on log ids: the trail must survive CASCADE deletes.
   - Attribution via sp_set_session_context (direct SSMS edits => NULL).
   - RECURSIVE_TRIGGERS OFF so the trigger's internal UpdatedAt update
     does not re-fire itself.
   Procs live in file 5; grants in file 6.
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

-- Keeps the audit trigger's internal UpdatedAt update from re-firing itself.
ALTER DATABASE DashboardManagementSystemECommerceDB SET RECURSIVE_TRIGGERS OFF;
GO

-- Re-run safety: children first.
DROP TRIGGER  IF EXISTS aud.trg_LogErrors_ReadOnly;
DROP TRIGGER  IF EXISTS aud.trg_InventoryLog_ReadOnly;
DROP TRIGGER  IF EXISTS cat.trg_ProductVariants_Audit;
DROP TABLE    IF EXISTS aud.InventoryLog;
DROP TABLE    IF EXISTS aud.LogErrors;
GO

/* ==================== 1. THE IMMUTABLE INVENTORY LOG ======================= */
CREATE TABLE aud.InventoryLog
(
    LogId           INT IDENTITY (1,1) NOT NULL,
    VariantId       INT                NOT NULL,  -- no FK, deliberately
    ProductId       INT                NOT NULL,
    [Action]        NVARCHAR(10)       NOT NULL,  -- INSERT / UPDATE / DELETE
    OldQuantity     INT                NULL,      -- NULL on INSERT
    NewQuantity     INT                NULL,      -- NULL on DELETE
    OldPrice        DECIMAL(10,2)      NULL,
    NewPrice        DECIMAL(10,2)      NULL,
    ChangedByUserId INT                NULL,      -- NULL = manual edit
    ChangedAt       DATETIME2(0)       NOT NULL CONSTRAINT DF_InventoryLog_ChangedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_InventoryLog PRIMARY KEY (LogId),
    CONSTRAINT CK_InventoryLog_Action CHECK ([Action] IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

-- 1st = history of one variant; 2nd = history of one product.
CREATE INDEX IX_InventoryLog_VariantId ON aud.InventoryLog (VariantId);
CREATE INDEX IX_InventoryLog_ProductId ON aud.InventoryLog (ProductId);
GO

/* ==================== 2. THE ERROR LOG (TRY/CATCH procs) ================== */
/* Columns mirror the ERROR_*() functions available inside a CATCH block. */
CREATE TABLE aud.LogErrors
(
    ErrorLogId      INT IDENTITY (1,1) NOT NULL,
    ErrorTime       DATETIME2(0)       NOT NULL CONSTRAINT DF_LogErrors_ErrorTime DEFAULT SYSDATETIME(),
    ErrorNumber     INT                NOT NULL,
    ErrorSeverity   INT                NULL,
    ErrorState      INT                NULL,
    ErrorProcedure  NVARCHAR(128)      NULL,  -- NULL for ad-hoc batches
    ErrorLine       INT                NULL,
    ErrorMessage    NVARCHAR(4000)     NOT NULL,
    ErrorUserId     INT                NULL,

    CONSTRAINT PK_LogErrors PRIMARY KEY (ErrorLogId)
);
GO

-- "What failed lately?" is the common query => time index.
CREATE INDEX IX_LogErrors_ErrorTime ON aud.LogErrors (ErrorTime);
GO

/* ==================== 3. THE AUDIT TRIGGER =================================
   inserted = state after change, deleted = state before;
   presence of each tells us INSERT / UPDATE / DELETE.
   ------------------------------------------------------------------------- */
CREATE TRIGGER cat.trg_ProductVariants_Audit
ON cat.ProductVariants
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId INT = TRY_CAST(SESSION_CONTEXT(N'AppUserId') AS INT);

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO aud.InventoryLog
               (VariantId, ProductId, [Action], NewQuantity, NewPrice, ChangedByUserId)
        SELECT  i.ProductVariantId, i.ProductId, 'INSERT', i.Quantity, i.Price, @UserId
        FROM    inserted AS i;
    ELSE
    -- UPDATE (log only when business values actually changed) + stamp UpdatedAt
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO aud.InventoryLog
               (VariantId, ProductId, [Action], OldQuantity, NewQuantity, OldPrice, NewPrice, ChangedByUserId)
        SELECT  d.ProductVariantId, d.ProductId, 'UPDATE',
                d.Quantity, i.Quantity, d.Price, i.Price, @UserId
        FROM    deleted AS d
        JOIN    inserted AS i ON i.ProductVariantId = d.ProductVariantId
        WHERE   d.Quantity <> i.Quantity OR d.Price <> i.Price;

        UPDATE pv
        SET    pv.UpdatedAt = SYSDATETIME()
        FROM   cat.ProductVariants AS pv
        JOIN   inserted AS i ON i.ProductVariantId = pv.ProductVariantId
        JOIN   deleted  AS d ON d.ProductVariantId = pv.ProductVariantId
        WHERE  d.Quantity <> i.Quantity OR d.Price <> i.Price;
    END
    ELSE
    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO aud.InventoryLog
               (VariantId, ProductId, [Action], OldQuantity, OldPrice, ChangedByUserId)
        SELECT  d.ProductVariantId, d.ProductId, 'DELETE', d.Quantity, d.Price, @UserId
        FROM    deleted AS d;

END
GO

/* ==================== 4. SHIELDS: history is immutable ===================== */
-- No UPDATE/DELETE on either log, not even for sysadmins; INSERT stays open.
CREATE TRIGGER aud.trg_InventoryLog_ReadOnly
ON aud.InventoryLog
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR(N'Direct modification of InventoryLog is not allowed - audit history is immutable.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO

CREATE TRIGGER aud.trg_LogErrors_ReadOnly
ON aud.LogErrors
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR(N'Direct modification of LogErrors is not allowed - error history is immutable.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO