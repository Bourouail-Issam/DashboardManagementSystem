/* ============================================================================
   DashboardManagementSystemECommerceDB — PRO | FILE 2/6: TABLES (dependency order)
   Bodies are created before their parents are dropped on re-run; children
   first, parents last, so no constraint is ever violated during the rebuild.
   Named constraints only (so they can be managed later).
   ========================================================================== */

USE DashboardManagementSystemECommerceDB;
GO

DROP TABLE IF EXISTS cat.ProductAttributeValues;
DROP TABLE IF EXISTS cat.ProductVariants;
DROP TABLE IF EXISTS cat.Products;
DROP TABLE IF EXISTS cat.ProductTypeAttributes;
DROP TABLE IF EXISTS cat.AttributeValues;
DROP TABLE IF EXISTS cat.AttributeDefinitions;
DROP TABLE IF EXISTS cat.ProductTypes;
DROP TABLE IF EXISTS cat.Categories;
DROP TABLE IF EXISTS sec.Users;
DROP TABLE IF EXISTS sec.People;
DROP TABLE IF EXISTS sec.Roles;
GO

/* ============================== sec schema ================================ */
CREATE TABLE sec.Roles
(
    RoleId   INT IDENTITY (1,1) NOT NULL,
    RoleName NVARCHAR(50)       NOT NULL,

    CONSTRAINT PK_Roles PRIMARY KEY (RoleId),
    CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName)
);
GO

CREATE TABLE sec.People
(
    PersonId  INT IDENTITY (1,1) NOT NULL,
    FirstName NVARCHAR(50)       NOT NULL,
    MidName   NVARCHAR(50)       NULL,
    LastName  NVARCHAR(50)       NOT NULL,
    Email     NVARCHAR(150)      NOT NULL,
    Gender    TINYINT            NOT NULL,
    Address   NVARCHAR(500)      NULL,
    ImagePath NVARCHAR(500)      NULL,
    BirthDate DATE               NULL,

    CONSTRAINT PK_People PRIMARY KEY (PersonId),
    CONSTRAINT UQ_People_Email UNIQUE (Email)
);
GO

CREATE TABLE sec.Users
(
    UserId          INT IDENTITY (1,1) NOT NULL,
    PersonId        INT                NOT NULL,
    RoleId          INT                NOT NULL,
    -- Bitwise flags: each right is a power of two, stored as their sum.
    Permissions     BIGINT             NOT NULL CONSTRAINT DF_Users_Permissions DEFAULT (0),
    CreatedByUserId INT                NULL,
    IsActive        BIT                NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),

    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_PersonId UNIQUE (PersonId),   -- 1:1 with People
    CONSTRAINT FK_Users_Person FOREIGN KEY (PersonId) REFERENCES sec.People (PersonId) ON DELETE CASCADE,
    CONSTRAINT FK_Users_Role FOREIGN KEY (RoleId) REFERENCES sec.Roles (RoleId),
    -- NO ACTION required: multiple cascade paths forbid CASCADE here.
    CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.Users (UserId),
    CONSTRAINT CK_Users_Permissions CHECK (Permissions >= 0)
);
GO

/* ============================== cat schema ================================ */
CREATE TABLE cat.Categories
(
    CategoryId   INT IDENTITY (1,1) NOT NULL,
    CategoryName NVARCHAR(100)      NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Categories_Name UNIQUE (CategoryName)
);
GO

CREATE TABLE cat.ProductTypes
(
    ProductTypeId INT IDENTITY (1,1) NOT NULL,
    TypeName      NVARCHAR(100)      NOT NULL,
    CategoryId    INT                NOT NULL,
    CONSTRAINT PK_ProductTypes PRIMARY KEY (ProductTypeId),
    -- Same type name allowed in different categories, never twice in one.
    CONSTRAINT UQ_ProductTypes_Type_Category UNIQUE (TypeName, CategoryId),
    CONSTRAINT FK_ProductTypes_Category FOREIGN KEY (CategoryId) REFERENCES cat.Categories (CategoryId) ON DELETE CASCADE
);
GO

CREATE TABLE cat.AttributeDefinitions
(
    AttributeId      INT IDENTITY (1,1) NOT NULL,
    AttributeName    NVARCHAR(100)      NOT NULL,
    DataType         NVARCHAR(20)       NOT NULL,
    IsPredefinedList BIT                NOT NULL  CONSTRAINT DF_AttributeDefinitions_IsList DEFAULT (1),

    CONSTRAINT PK_AttributeDefinitions PRIMARY KEY (AttributeId),
    CONSTRAINT UQ_AttributeDefinitions_Name UNIQUE (AttributeName),
    CONSTRAINT CK_AttributeDefinitions_DataType CHECK (DataType IN ('VARCHAR', 'INT', 'DECIMAL', 'DATE', 'BOOLEAN'))
);
GO

CREATE TABLE cat.AttributeValues
(
    AttributeValueId INT IDENTITY (1,1) NOT NULL,
    AttributeId      INT                NOT NULL,
    [Value]          NVARCHAR(100)      NOT NULL,
    CONSTRAINT PK_AttributeValues PRIMARY KEY (AttributeValueId),
    CONSTRAINT UQ_AttributeValues_Attr_Value UNIQUE ([Value], AttributeId),
    -- Candidate key targeted by the composite FK below: a value belongs to
    -- exactly one attribute definition.
    CONSTRAINT UQ_AttributeValues_AVId_Attr UNIQUE (AttributeValueId, AttributeId),
    CONSTRAINT FK_AttributeValues_Attribute FOREIGN KEY (AttributeId) REFERENCES cat.AttributeDefinitions (AttributeId) ON DELETE CASCADE
);
GO

CREATE TABLE cat.ProductTypeAttributes
(
    IdProductTypeAttribute INT IDENTITY (1,1) NOT NULL,
    ProductTypeId          INT                NOT NULL,
    AttributeId            INT                NOT NULL,

    CONSTRAINT PK_ProductTypeAttributes PRIMARY KEY (IdProductTypeAttribute),
    CONSTRAINT UQ_ProductTypeAttributes UNIQUE (ProductTypeId, AttributeId),
    -- Junction rows own nothing => cascade from both sides.
    CONSTRAINT FK_PTA_ProductType FOREIGN KEY (ProductTypeId) REFERENCES cat.ProductTypes (ProductTypeId) ON DELETE CASCADE,
    CONSTRAINT FK_PTA_Attribute FOREIGN KEY (AttributeId)  REFERENCES cat.AttributeDefinitions (AttributeId) ON DELETE CASCADE
);
GO

CREATE TABLE cat.Products
(
    ProductId       INT IDENTITY (1,1) NOT NULL,
    ProductName     NVARCHAR(150)      NOT NULL,
    ProductTypeId   INT                NOT NULL,
    CreatedByUserId INT                NOT NULL,
    Status          NVARCHAR(10)       NOT NULL CONSTRAINT DF_Products_Status DEFAULT ('Draft'),
    CreatedAt       DATETIME2(0)       NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2(0)       NULL,

    CONSTRAINT PK_Products PRIMARY KEY (ProductId),
    CONSTRAINT CK_Products_Status CHECK (Status IN ('Draft', 'Published')),
    CONSTRAINT FK_Products_Type FOREIGN KEY (ProductTypeId) REFERENCES cat.ProductTypes (ProductTypeId) ON DELETE CASCADE,
    -- Creator owns history: deletion blocked while products exist.
    CONSTRAINT FK_Products_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.Users (UserId)
);
GO

CREATE TABLE cat.ProductVariants
(
    ProductVariantId INT IDENTITY (1,1) NOT NULL,
    ProductId        INT                NOT NULL,
    SKU              NVARCHAR(50)       NOT NULL,
    Price            DECIMAL(10,2)      NOT NULL,
    Quantity         INT                NOT NULL,
    CreatedAt        DATETIME2(0)       NOT NULL CONSTRAINT DF_Variants_CreatedAt DEFAULT SYSDATETIME(),
    UpdatedAt        DATETIME2(0)       NULL,

    CONSTRAINT PK_ProductVariants PRIMARY KEY (ProductVariantId),
    CONSTRAINT UQ_ProductVariants_SKU UNIQUE (SKU),
    CONSTRAINT CK_ProductVariants_Price    CHECK (Price > 0),
    CONSTRAINT CK_ProductVariants_Quantity CHECK (Quantity >= 0),
    CONSTRAINT FK_ProductVariants_Product FOREIGN KEY (ProductId) REFERENCES cat.Products (ProductId) ON DELETE CASCADE
);
GO

-- Composite FK + XOR: the value must match the row's attribute, and exactly
-- one of (AttributeValueId, FreeTextValue) is filled.
CREATE TABLE cat.ProductAttributeValues
(
    ProductAttributeValueId INT IDENTITY (1,1) NOT NULL,
    ProductVariantId        INT                NOT NULL,
    AttributeId             INT                NOT NULL,
    AttributeValueId        INT                NULL,
    FreeTextValue           NVARCHAR(255)      NULL,

    CONSTRAINT PK_ProductAttributeValues PRIMARY KEY (ProductAttributeValueId),
    CONSTRAINT UQ_PAV_Variant_Attribute UNIQUE (ProductVariantId, AttributeId),
    CONSTRAINT FK_PAV_Variant FOREIGN KEY (ProductVariantId) REFERENCES cat.ProductVariants (ProductVariantId) ON DELETE CASCADE,
    CONSTRAINT FK_PAV_Attribute FOREIGN KEY (AttributeId) REFERENCES cat.AttributeDefinitions (AttributeId),
    CONSTRAINT FK_PAV_AttributeValue FOREIGN KEY (AttributeValueId, AttributeId) REFERENCES cat.AttributeValues (AttributeValueId, AttributeId),
    CONSTRAINT CK_PAV_XOR CHECK
    (
        (AttributeValueId IS NOT NULL AND FreeTextValue IS NULL)
        OR
        (AttributeValueId IS NULL AND FreeTextValue IS NOT NULL)
    )
);
GO

/* ---------------------------------------------------------------------------
   Metadata documentation.
   sp_addextendedproperty is NOT idempotent ("Property already exists"), so
   each call needs the IF NOT EXISTS guard to be safe on re-run.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE name = N'MS_Description'
      AND major_id   = OBJECT_ID(N'sec.Users')
      AND minor_id   = COLUMNPROPERTY(OBJECT_ID(N'sec.Users'), N'Permissions', 'ColumnId')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description',
         @value = N'Bitmask of permission flags; each flag is a power of two and the stored value is their sum.',
         @level0type = N'SCHEMA', @level0name = N'sec',
         @level1type = N'TABLE',  @level1name = N'Users',
         @level2type = N'COLUMN', @level2name = N'Permissions';

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE name = N'MS_Description'
      AND major_id   = OBJECT_ID(N'sec.Users')
      AND minor_id   = COLUMNPROPERTY(OBJECT_ID(N'sec.Users'), N'IsActive', 'ColumnId')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description',
         @value = N'Soft delete: 0 = disabled account, never physically deleted.',
         @level0type = N'SCHEMA', @level0name = N'sec',
         @level1type = N'TABLE',  @level1name = N'Users',
         @level2type = N'COLUMN', @level2name = N'IsActive';

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE name = N'MS_Description'
      AND major_id   = OBJECT_ID(N'cat.Products')
      AND minor_id   = COLUMNPROPERTY(OBJECT_ID(N'cat.Products'), N'Status', 'ColumnId')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description',
         @value = N'Draft = hidden from shop, Published = visible for sale.',
         @level0type = N'SCHEMA', @level0name = N'cat',
         @level1type = N'TABLE',  @level1name = N'Products',
         @level2type = N'COLUMN', @level2name = N'Status';

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE name = N'MS_Description'
      AND major_id   = OBJECT_ID(N'cat.ProductAttributeValues')
      AND minor_id   = COLUMNPROPERTY(OBJECT_ID(N'cat.ProductAttributeValues'), N'FreeTextValue', 'ColumnId')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description',
         @value = N'Free-text spec used only when AttributeValueId is NULL (XOR rule).',
         @level0type = N'SCHEMA', @level0name = N'cat',
         @level1type = N'TABLE',  @level1name = N'ProductAttributeValues',
         @level2type = N'COLUMN', @level2name = N'FreeTextValue';
GO