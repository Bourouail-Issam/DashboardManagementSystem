/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 3/6: SUPPORTING INDEXES
   PK/UNIQUE indexes are automatic; this file adds FK-column indexes only.
   Left-prefix rule avoids duplicates: UQ_ProductTypeAttributes(TypeId,AttrId)
   already serves TypeId lookups; UQ_PAV_Variant_Attribute already serves
   ProductVariantId lookups (IX_PAV_Variant was dropped for this reason).
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

-- DROP/CREATE pair keeps the file idempotent (rebuild, never duplicate).
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

DROP INDEX IF EXISTS IX_PAV_Attribute ON cat.ProductAttributeValues;
CREATE INDEX IX_PAV_Attribute ON cat.ProductAttributeValues (AttributeId);

-- Optional reverse lookup for faceted filters (first) / attribute value.
DROP INDEX IF EXISTS IX_PAV_AttributeValueId ON cat.ProductAttributeValues;
CREATE INDEX IX_PAV_AttributeValueId ON cat.ProductAttributeValues (AttributeValueId);
GO