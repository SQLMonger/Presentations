SELECT
       EC.name AS edge_constraint_name
     , OBJECT_NAME(EC.parent_object_id) AS [edge table]
     , OBJECT_NAME(ECC.from_object_id) AS [From Node table]
     , OBJECT_NAME(ECC.to_object_id) AS [To Node table],
EC.type_desc,
     EC.create_date 
  FROM sys.edge_constraints EC
INNER JOIN sys.edge_constraint_clauses ECC
    ON EC.object_id = ECC.object_id
GO
SELECT
       EC.name AS edge_constraint_name
     , OBJECT_NAME(EC.parent_object_id) AS [edge table]
     , OBJECT_NAME(ECC.from_object_id) AS [From Node table]
     , OBJECT_NAME(ECC.to_object_id) AS [To Node table],
EC.type_desc,
     EC.create_date 
  FROM sys.edge_constraints EC
INNER JOIN sys.edge_constraint_clauses ECC
    ON EC.object_id = ECC.object_id
WHERE ECC.from_object_id = object_id('administrator')
