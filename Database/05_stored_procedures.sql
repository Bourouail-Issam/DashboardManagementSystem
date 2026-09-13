/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 5/6: STORED PROCEDURES

   HOUSE RULES (agreed pattern):
     - CREATE OR ALTER       => safe to re-run.
     - SET XACT_ABORT ON     => auto rollback, no explicit transactions.
     - THROW (not RAISERROR) => real SqlException to the app, stops the batch.
     - sp_set_session_context BEFORE any write => audit stamps the real user.
     - New proc? add its GRANT EXECUTE line in FILE 6, or the app can't run it.

   COMPOSITE RULE: stock + price change together in ONE proc, ONE UPDATE, ONE
   transaction. Two separate procs would run two transactions — a crash could
   leave the pair on disk mismatched. Here that is impossible.
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

/* ============================================================================
   SECTION A — ERROR LOGGING (called from a CATCH block)
   Auto-reads the calling CATCH's ERROR_*() functions, hence no parameters.
   No EXECUTE AS needed: app_runtime has no right on aud, but the dbo
   ownership chain (cat.usp_* -> usp_LogError -> aud tables) covers the write.
   ========================================================================== */

CREATE OR ALTER PROCEDURE aud.usp_LogError
AS
BEGIN
    SET NOCOUNT ON;

    -- ERROR_*() are NULL outside a CATCH block; nothing useful to store.
    IF ERROR_NUMBER() IS NULL
        RETURN;

    INSERT INTO aud.LogErrors
           (ErrorTime, ErrorNumber, ErrorSeverity, ErrorState,
            ErrorProcedure, ErrorLine, ErrorMessage, ErrorUserId)
    SELECT SYSDATETIME(),
           ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
           ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(),
           TRY_CAST(SESSION_CONTEXT(N'AppUserId') AS INT);
END
GO

/* ============================================================================
   SECTION B — INVENTORY (stock & price changes)
   ========================================================================== */

CREATE OR ALTER PROCEDURE cat.usp_UpdateVariantStock
    @VariantId   INT,
    @NewQuantity INT,
    @UserId      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Business rule: zero is allowed (out of stock), negative is not.
    IF @NewQuantity < 0
        THROW 50010, N'Quantity cannot be negative.', 1;

    -- Clear error instead of an obscure FK failure later.
    IF NOT EXISTS (SELECT 1 FROM cat.ProductVariants
                   WHERE ProductVariantId = @VariantId)
        THROW 50011, N'Product variant not found.', 1;

    EXEC sp_set_session_context @key = N'AppUserId', @value = @UserId;

    UPDATE cat.ProductVariants
    SET    Quantity = @NewQuantity
    WHERE  ProductVariantId = @VariantId;
END
GO

CREATE OR ALTER PROCEDURE cat.usp_UpdateVariantPrice
    @VariantId INT,
    @NewPrice  DECIMAL(10,2),
    @UserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Business rule: price strictly positive.
    IF @NewPrice <= 0
        THROW 50020, N'Price must be greater than zero.', 1;

    IF NOT EXISTS (SELECT 1 FROM cat.ProductVariants
                   WHERE ProductVariantId = @VariantId)
        THROW 50021, N'Product variant not found.', 1;

    EXEC sp_set_session_context @key = N'AppUserId', @value = @UserId;

    UPDATE cat.ProductVariants
    SET    Price = @NewPrice
    WHERE  ProductVariantId = @VariantId;
END
GO

/* ============================================================================
   Stock + price together — the full pattern.

   RETRY LOOP (deadlock 1205): a victim is normal & temporary; retry up to
   3 times, pausing 200 ms — the second attempt usually succeeds.

   WHY XACT_STATE() NOT @@TRANCOUNT? @@TRANCOUNT counts open batches;
   XACT_STATE() says if the transaction is still usable. -1 (uncommittable)
   or 0 (victim) both need a rollback before retrying.

   THROW PLACEMENT: THROW must not directly follow CONTINUE/BREAK in a CATCH
   (parser quirk). We exit with @Failed and throw guarded outside the loop.
   ========================================================================== */

CREATE OR ALTER PROCEDURE cat.usp_UpdateVariantStockAndPrice
    @VariantId   INT,
    @NewQuantity INT,
    @NewPrice    DECIMAL(10,2),
    @UserId      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RetryCount INT = 0;
    DECLARE @MaxRetries INT = 3;
    DECLARE @Failed BIT = 0;

    -- Validate BEFORE opening the transaction: a failed check touches nothing.
    IF @NewQuantity < 0
        THROW 50010, N'Quantity cannot be negative.', 1;

    IF @NewPrice <= 0
        THROW 50020, N'Price must be greater than zero.', 1;

    IF NOT EXISTS (SELECT 1 FROM cat.ProductVariants
                   WHERE ProductVariantId = @VariantId)
        THROW 50031, N'Product variant not found.', 1;

    EXEC sp_set_session_context @key = N'AppUserId', @value = @UserId;

    WHILE 1 = 1
    BEGIN
        BEGIN TRY
            -- One transaction, one UPDATE: stock + price change together.
            BEGIN TRANSACTION;

                UPDATE cat.ProductVariants
                SET    Quantity = @NewQuantity,
                       Price    = @NewPrice
                WHERE  ProductVariantId = @VariantId;

            COMMIT TRANSACTION;
            RETURN 0;
        END TRY
        BEGIN CATCH
            -- Preserve the failure before doing anything else.
            EXEC aud.usp_LogError;

            -- Repair the transaction state (-1 uncommittable / 0 victim).
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            -- Deadlock with retries left? pause, then loop again.
            IF ERROR_NUMBER() = 1205 AND @RetryCount < @MaxRetries
            BEGIN
                SET @RetryCount = @RetryCount + 1;
                WAITFOR DELAY '00:00:00.200';
                CONTINUE;
            END

            -- Non-retryable: quit the loop and throw below.
            SET @Failed = 1;
            BREAK;
        END CATCH
    END

    -- The exact cause is already in aud.LogErrors from the CATCH.
    IF @Failed = 1
        THROW 50030, N'Update failed. See aud.LogErrors for details.', 1;
END
GO

/* ============================================================================
   SECTION C — CATALOG (future)
   e.g. cat.usp_Catalog_AddProduct, cat.usp_Catalog_SetProductStatus
   ========================================================================== */

/* ============================================================================
   SECTION D — SECURITY (admin only, future)
   e.g. sec.usp_Security_CreateUser  — grant to app_admin only (see file 6).
   ========================================================================== */

/* ============================================================================
   SECTION E — ORDERS (future)
   ========================================================================== */