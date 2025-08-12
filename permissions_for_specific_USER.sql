 
 -- Variables
DECLARE @TableName NVARCHAR(255) = 'RiskMng_RiskFactor'
DECLARE @GroupName NVARCHAR(100) = 'MSITE\Customer Reports Managers'
 
-- Check permissions granted directly on the table
SELECT 
    'Table' AS ObjectType,
    OBJECT_NAME(major_id) AS ObjectName,
    USER_NAME(grantee_principal_id) AS Grantee,
    permission_name AS Permission,
    state_desc AS State
FROM sys.database_permissions
WHERE class_desc = 'OBJECT_OR_COLUMN'
    --AND major_id = OBJECT_ID(@TableName)
    AND grantee_principal_id = DATABASE_PRINCIPAL_ID(@GroupName)
UNION ALL
-- Check permissions inherited from the schema
SELECT 
    'Schema' AS ObjectType,
    SCHEMA_NAME(schema_id) AS ObjectName,
    USER_NAME(grantee_principal_id) AS Grantee,
    permission_name AS Permission,
    state_desc AS State
FROM sys.database_permissions
WHERE class_desc = 'SCHEMA'
    AND major_id = OBJECT_ID(@TableName)
    AND grantee_principal_id = DATABASE_PRINCIPAL_ID(@GroupName);


	select *  FROM sys.database_permissions
