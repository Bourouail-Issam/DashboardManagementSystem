/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO BUILD | FILE 3/4: SUPPORTING INDEXES
   ----------------------------------------------------------------------------
   Policy: PK/UNIQUE indexes are automatic; this file covers FOREIGN KEY
   columns only (JOIN / WHERE / CASCADE / NO ACTION lookup paths).
   Composite-index left-prefix rule: UQ_ProductTypeAttributes(ProductTypeId,
   AttributeId) already serves ProductTypeId searches => no duplicate index.
   Same applies to UQ_PAV_Variant_Attribute(ProductVariantId, AttributeId)
   => IX_PAV_Variant intentionally omitted (would duplicate that constraint).
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

DROP INDEX IF EXISTS IX_Users_RoleId ON sec.Users;
CREATE INDEX IX_Users_RoleId ON sec.Users (RoleId);

DROP INDEX IF EXISTS IX_Users_CreatedByUserId ON sec.Users;
CREATE INDEX IX_Users_CreatedByUserId ON sec.Users (CreatedByUserId);

DROP INDEX IF EXISTS IX_ProductTypes_CategoryId ON cat.ProductTypes;
CREATE INDEX IX_ProductTypes_CategoryId ON cat.ProductTypes (CategoryId);

DROP INDEX IF EXISTS IX_Products_Type ON cat.Products;
CREATE INDEX IX_Products_Type ON cat.Products (ProductTypeId);

DROP INDEX IF EXISTS IX_Products_CreatedBy ON cat.Products;
CREATE INDEX IX_Products_CreatedBy ON cat.Products (CreatedByUserId);

DROP INDEX IF EXISTS IX_Variants_Product ON cat.ProductVariants;
CREATE INDEX IX_Variants_Product ON cat.ProductVariants (ProductId);

DROP INDEX IF EXISTS IX_AttributeValues_Attribute ON cat.AttributeValues;
CREATE INDEX IX_AttributeValues_Attribute ON cat.AttributeValues (AttributeId);

DROP INDEX IF EXISTS IX_PTA_Attribute ON cat.ProductTypeAttributes;
CREATE INDEX IX_PTA_Attribute ON cat.ProductTypeAttributes (AttributeId);

-- IX_PAV_Variant removed — UNIQUE(ProductVariantId, AttributeId) already covers it (leftmost prefix rule)
DROP INDEX IF EXISTS IX_PAV_Attribute ON cat.ProductAttributeValues;
CREATE INDEX IX_PAV_Attribute ON cat.ProductAttributeValues (AttributeId);
