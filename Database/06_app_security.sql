/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 6/6: APPLICATION SECURITY
   The only file that creates roles and grants permissions.
   Runs AFTER file 5 (stored procedures), so every procedure already exists
   and the GRANTs can be written directly — no object guards needed.

   REMEMBER: when you add a NEW procedure in file 5, add its GRANT EXECUTE
   here too, or the app cannot run it.

   WHAT app_runtime MAY DO:
     - SELECT  cat            : read the product catalog.
     - EXECUTE per procedure  : one line each (per-object grants).
     - Nothing on aud         : fully hidden; writes reach it via the dbo
                                ownership chain (cat.usp_* -> usp_LogError).
   sec is intentionally never granted (hides People, Users, Permissions...).
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

/* --------------------------- STEP 1: ROLES ------------------------------ */
/* Create a role only if it does not exist yet (safe to re-run). */
IF DATABASE_PRINCIPAL_ID(N'app_runtime') IS NULL
    EXEC (N'CREATE ROLE [app_runtime];');
GO

IF DATABASE_PRINCIPAL_ID(N'app_admin') IS NULL
    EXEC (N'CREATE ROLE [app_admin];');
GO

/* --------------------- STEP 2: app_runtime = CATALOG READ ---------------- */
-- The application must see the catalog (products, types, attributes...).
GRANT SELECT ON SCHEMA::cat TO [app_runtime];
GO

/* ---------------------- STEP 3: app_runtime = EXECUTE -------------------- */
/* One line per procedure (procedures exist: this file runs after file 5). */
GRANT EXECUTE ON OBJECT::cat.usp_UpdateVariantStock         TO [app_runtime];
GRANT EXECUTE ON OBJECT::cat.usp_UpdateVariantPrice         TO [app_runtime];
GRANT EXECUTE ON OBJECT::cat.usp_UpdateVariantStockAndPrice TO [app_runtime];
GO

/* ------------------- STEP 4: app_admin (optional, off) ------------------- */
/* app_admin inherits ALL app_runtime rights via membership:
   ALTER ROLE [app_runtime] ADD MEMBER [app_admin];
   Then give it the security procedures (sec.*):
   GRANT EXECUTE ON SCHEMA::sec TO [app_admin];
   (sec.* procs must only ever belong to app_admin, never app_runtime). */
GO