/*
STL SQL Server User Group Presentation
June 11th 2019
Prensenter: Clayton Groom
Twitter: @sqlmonger

https://github.com/SQLMonger/Presentations
httP://sqlmonger.com


Resources:
https://docs.microsoft.com/en-us/sql/relational-databases/graphs/sql-graph-architecture
https://www.red-gate.com/simple-talk/sql/sql-development/sql-server-graph-databases-part-1-introduction/
https://blog.bvisual.net/2018/02/09/using-visio-and-powerbi-with-graphdatabase-in-sqlserver/
https://www.youtube.com/watch?v=NnoOxwmRK5U SQL 2017 - Graph Databases / Power BI visualisation
	https://github.com/neilmillingtonmicrosoft/SQL_Graph_with_PowerBI
	https://www.linkedin.com/in/neilmillington/
	Twitter: @_neilMillington

*/
use AdventureWorksDW
go

CREATE SCHEMA graph;
GO
SELECT * FROM sys.objects
GO
DROP TABLE IF EXISTS graph.DBObjects;
go
CREATE TABLE [graph].[DBObjects]
(
     [ObjectID]     INT  PRIMARY KEY
   , [ObjectSchema] SYSNAME
   , [ObjectName]   SYSNAME
   , [ObjectType]   NVARCHAR(60)
)
AS NODE; --only difference from defining a normal table
GO

select * from graph.dbobjects

--Let's get some data into our table

INSERT INTO [graph].[DBObjects]
       ( [ObjectID]
       , [ObjectSchema]
       , [ObjectName]
       , [ObjectType]
       )
SELECT [object_id]
     , OBJECT_SCHEMA_NAME([object_id]) AS [ObjectSchema]
     , [Name]
     , [type_desc]
FROM [sys].[objects]
WHERE [type_desc] IN ('VIEW', 'USER_TABLE');
GO

SELECT * FROM graph.DBObjects;

GO

EXEC sp_help 'graph.DBObjects'

GO

-- defines the column-level realtionships between two tables
SELECT * FROM sys.sysreferences

--Link between a constraint object and a table column
SELECT *  FROM sys.sysconstraints
GO

--Get the full view of the foreign key constraints

SELECT object_name(fkeyid) AS [target], object_name(rkeyid) AS [source], object_name(c.constid) as [FKeyName], c.*, r.* 
FROM sys.sysreferences AS r
INNER JOIN sys.sysconstraints AS C
ON r.constid = c.constid

GO

--"Edge" information defined. What we really need.
SELECT * FROM  [sys].[foreign_key_columns] 

GO

--Parent view

SELECT [C].[referenced_object_id] AS [object_id]
     , [C].[parent_object_id]
     , STUFF(
		  (SELECT ', ' + QUOTENAME([P].[name])
           FROM [sys].[foreign_key_columns] AS [A]
                JOIN [sys].[columns] AS [P]
                ON [P].[object_id] = [A].[referenced_object_id]
                   AND [P].[column_id] = [A].[referenced_column_id]
           WHERE [C].[parent_object_id] = [A].[parent_object_id]
                 AND [C].[referenced_object_id] = [A].[referenced_object_id] FOR XML PATH('')
       ), 1, 2, '') AS [ColumnNames]
FROM [sys].[foreign_key_columns] AS [C]
GROUP BY [C].[referenced_object_id]
       , [C].[parent_object_id];

GO	

--child view

SELECT [CC].[parent_object_id] AS [object_id]
     , [CC].[referenced_object_id]
	 , OBJECT_NAME([cc].constraint_object_id) AS FKeyName
     , STUFF(
       (
           SELECT ', ' + QUOTENAME(OBJECT_NAME([C].[object_id])) 
				+ '.'+  QUOTENAME([C].[name]) 
				+ ' = ' + QUOTENAME(OBJECT_NAME([A].[referenced_object_id]))
				+ '.' + QUOTENAME([P].[name])
           FROM [sys].[foreign_key_columns] AS [A]
                JOIN [sys].[columns] AS [C]
                ON [C].[object_id] = [A].[parent_object_id]
                   AND [C].[column_id] = [A].[parent_column_id]
                JOIN [sys].[columns] AS [P]
                ON [P].[object_id] = [A].[referenced_object_id]
                   AND [P].[column_id] = [A].[referenced_column_id]
           WHERE [CC].[parent_object_id] = [A].[parent_object_id]
                 AND [CC].[referenced_object_id] = [A].[referenced_object_id]
				 AND [CC].constraint_object_id = [A].constraint_object_id
		   FOR XML PATH('')
       ), 1, 2, '') AS [ColumnNames]
FROM [sys].[foreign_key_columns] AS [CC]
GROUP BY [CC].[parent_object_id]
       , [CC].[referenced_object_id]
	   ,[cc].constraint_object_id


GO

DROP TABLE IF EXISTS graph.ForeignKeys;

GO

CREATE TABLE graph.ForeignKeys (ConstraintName sysname, ConstraintColumns nvarchar(2000))
AS EDGE;

GO

select * from graph.ForeignKeys;

GO

EXEC sp_help 'graph.ForeignKeys'

GO

WITH cte_References
AS (
	SELECT [CC].[parent_object_id] AS [Parent_object_id]
		 , [CC].[referenced_object_id]
		 , OBJECT_NAME([cc].constraint_object_id) AS ConstraintName
		 , STUFF(
		   (
			   SELECT ', ' + QUOTENAME(OBJECT_NAME([C].[object_id])) + '.'+  QUOTENAME([C].[name]) + ' = ' + QUOTENAME(OBJECT_NAME([A].[referenced_object_id]))+ '.' +QUOTENAME([P].[name])
			   FROM [sys].[foreign_key_columns] AS [A]
					JOIN [sys].[columns] AS [C]
					ON [C].[object_id] = [A].[parent_object_id]
					   AND [C].[column_id] = [A].[parent_column_id]
					JOIN [sys].[columns] AS [P]
					ON [P].[object_id] = [A].[referenced_object_id]
					   AND [P].[column_id] = [A].[referenced_column_id]
			   WHERE [CC].[parent_object_id] = [A].[parent_object_id]
					 AND [CC].[referenced_object_id] = [A].[referenced_object_id]
					 AND [CC].constraint_object_id = [A].constraint_object_id
			   FOR XML PATH('')
		   ), 1, 2, '') AS [ConstraintColumns]
	FROM [sys].[foreign_key_columns] AS [CC]
	GROUP BY [CC].[parent_object_id]
		   , [CC].[referenced_object_id]
		   ,[cc].constraint_object_id
	)
INSERT INTO graph.ForeignKeys($from_id, $to_id, ConstraintName, ConstraintColumns)
SELECT P.Pnode
	--, object_name(P.[objectid])
	, C.Cnode
	--, object_name(C.[objectid])
	, ConstraintName
	, ConstraintColumns
from cte_References AS R 
Inner join (select $node_id as Cnode, ObjectID from graph.DBObjects) as C
ON R.[Parent_object_id] = C.ObjectID
INNER JOIN (select $node_id as Pnode, ObjectID from graph.DBObjects) as P
ON R.[referenced_object_id] = P.ObjectID
go
select * from graph.ForeignKeys
go


/*

Querying Node and edge tables

WHERE MATCH

*/

--Parent to child
SELECT [Parent].[ObjectName] AS [Parent Table]
     , [Child].[ObjectName] AS [Child Table]
     , [LinkedTo].[ConstraintName]
     , [LinkedTo].[ConstraintColumns]
FROM [graph].[DBObjects] AS [Child]
   , [graph].[ForeignKeys] AS [LinkedTo]
   , [graph].[DBObjects] AS [Parent]
WHERE MATCH([Parent]-([LinkedTo])->[Child])
ORDER BY [Parent Table]
       , [Child Table];

--filtered: Tables with FKey relationships TO [FactInternetSales]
SELECT [Parent].[ObjectName] AS [Parent Table]
     , [Child].[ObjectName] AS [Child Table]
     , [LinkedTo].[ConstraintName]
     , [LinkedTo].[ConstraintColumns]
FROM [graph].[DBObjects] AS [Child]
   , [graph].[ForeignKeys] AS [LinkedTo]
   , [graph].[DBObjects] AS [Parent]
WHERE MATCH([Parent]-([LinkedTo])->[Child])
      AND [Child].[ObjectName] = 'FactInternetSales'
ORDER BY [Parent Table]
       , [Child Table];

--filtered, reverse direction of relationship to get all dependents for [DimDate]
SELECT [Parent].[ObjectName] AS [Child Table]
     , [Child].[ObjectName] AS [Parent Table]
     , [LinkedTo].[ConstraintName]
     , [LinkedTo].[ConstraintColumns]
FROM [graph].[DBObjects] AS [Parent]
   , [graph].[ForeignKeys] AS [LinkedTo]
   , [graph].[DBObjects] AS [Child]
WHERE MATCH([Parent]<-([LinkedTo])-[Child])
      AND [Child].[ObjectName] = 'DimDate'
ORDER BY [Parent Table]
       , [Child Table];

GO

--apply grouping, like any other table

SELECT [Child].[ObjectName] AS [Origin Table]
     , count(*) as [Refernce Count]
FROM [graph].[DBObjects] AS [Parent]
   , [graph].[ForeignKeys] AS [LinkedTo]
   , [graph].[DBObjects] AS [Child]
WHERE MATCH([Parent]<-([LinkedTo])-[Child])
      --AND [Child].[ObjectName] = 'DimDate'
group BY [Child].[ObjectName]
order by 2 desc

GO

-- three levels, non-recursive
SELECT [Parent].[ObjectName] AS [Parent Table]
     , [LinkedToChild].[ConstraintName]
     , [LinkedToChild].[ConstraintColumns]
     , [Child].[ObjectName] AS [Child Table]
	 , [LinkedToGrandChild].[ConstraintName]
     , [LinkedToGrandChild].[ConstraintColumns]
	 , [GrandChild].[ObjectName]
FROM [graph].[DBObjects] AS [Child]
   , [graph].[ForeignKeys] AS [LinkedToChild]
   , [graph].[DBObjects] AS [Parent]
   , [graph].[ForeignKeys] AS [LinkedToGrandChild]
   , [graph].[DBObjects] AS [GrandChild]
WHERE MATCH([Parent]-([LinkedToChild])->[Child]-([LinkedToGrandChild])->[GrandChild])
      AND [GrandChild].[ObjectName] = 'FactInternetSales'
ORDER BY [Parent Table]
       , [Child Table];

/*

--multi-level Recursion, using a CTE to get all the tables that have Foreign Keys into FactInternetSales

LIMITATIONS

1. Cannot use MATCH in a recursive CTE
	But can join on node_id & from_id in a recursive CTE
*/

WITH obj AS
(
  SELECT $node_id NodeID, [ObjectName] as [ParentTable] 
	,CAST(NULL AS sysname) as [ChildTable]
  FROM graph.DBObjects
  --WHERE [ObjectName] = 'FactInternetSales'
  UNION ALL
  SELECT ct.$node_id
	, ct.[ObjectName] [ChildTable]
	, obj.[ParentTable]
  FROM graph.DBObjects as ct 
  INNER JOIN graph.ForeignKeys as fk
      ON ct.$node_id = fk.$from_id 
  INNER JOIN obj
      ON fk.$to_id = obj.NodeID
where ct.[ObjectName] <> obj.[ParentTable] --ignore self references that will blow up recursion
)
SELECT  NodeID,[ParentTable], [ChildTable]
FROM obj
WHERE [ParentTable] IS NOT NULL
OPTION (MAXRECURSION 500) 

go

/* 

Power BI Source views - avoid error trying to read the graph_id_* column

Note: "SELECT * FROM ..." will not work from Power BI for any graph table

Create views to return just the needed columns and reference them in Power BI

Visual: Force-directed graph.
There are other visuals, but for brevity, we'll only look a this one...
Setup: 
	Query for Parent (node) objects
	Query for Child (node) object
	Query for Relationships (edge) objects

*/

CREATE OR ALTER VIEW [graph].[DBObjects_vw]
AS SELECT $node_id AS [NodeID]
        , [ObjectID]
        , [ObjectSchema]
        , [ObjectName]
        , [ObjectType]
   FROM [graph].[DBObjects];
GO

EXEC sp_help '[graph].[DBObjects_vw]'

GO

--will need to update the select statement in the view after rebuilding the underlying table
EXEC sp_help '[graph].[ForeignKeys]'

GO

CREATE OR ALTER VIEW [graph].[ForeignKeys_vw]
AS SELECT $edge_id AS [EdgeID]
        , $from_id AS [FromID]
        , $to_id AS [ToID]
        , [ConstraintName]
        , [ConstraintColumns]
   FROM [graph].[ForeignKeys];

GO

EXEC sp_help '[graph].[ForeignKeys_vw]'

GO
SELECT [NodeID]
        , [ObjectID]
        , [ObjectSchema]
        , [ObjectName]
        , [ObjectType]
   FROM [graph].[DBObjects_vw]

SELECT *
FROM [graph].[DBObjects_vw];


SELECT [EdgeID]
        , [FromID]
        , [ToID]
        , [ConstraintName]
        , [ConstraintColumns]
FROM [graph].[ForeignKeys_vw];


GO


-- Extend the model by adding a node table for reports

DROP TABLE IF EXISTS  [graph].[Report];
go

CREATE TABLE [graph].[Report]
(
     [ReportID]     INT  identity(1,1) PRIMARY KEY
   , [ReportName] NVARCHAR(250) not null
   , [ReportType]   NVARCHAR(30) default 'SSRS'
)
AS NODE; 

GO

INSERT [graph].[Report]([ReportName], [ReportType])
VALUES ('Sales Report', 'SSRS')
	,('Sales Analysis Workbook', 'Power BI')
	,('Sales Forecasts','Excel')
GO

select * from [graph].[Report]

go

--Create an edge table for relating reports to tables
DROP TABLE IF EXISTS  [graph].[ReportUses];
go

CREATE TABLE [graph].[ReportUses] ([UsedFor] nvarchar(30))
AS EDGE;
go

INSERT [graph].[ReportUses] ( $from_id, $to_id, [UsedFor])
VALUES 
	((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Report')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'FactInternetSales')
	,'Core Data'
	)
	,((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Report')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'DimDate')
	,'Parameter Values'
	)
	,((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Report')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'DimProduct')
	,'Parameter Values'
	)
	,((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Analysis Workbook')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'DimCustomer')
	,'Core Data'
	)
	,((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Report')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'DimSalesTerritory')
	,'Parameter Values'
	)
	,((SELECT $node_id FROM [graph].[Report] where ReportName = 'Sales Report')
	,(SELECT $node_id FROM [graph].[DBObjects] where ObjectName = 'DimProduct')
	,'Parameter Values'
	)
go

SELECT *
FROM [graph].[ReportUses];

GO

--Create views for Power BI

CREATE OR ALTER VIEW [graph].[Reports_vw]
AS SELECT $node_id AS [NodeID]
        , [ReportID]
        , [ReportName] as [Report Name]
        , [ReportType] as [Report Type]
   FROM [graph].[Report];
GO

EXEC sp_help '[graph].[Report_vw]'

GO
select * from [graph].[Report_vw]

--will need to update the select statement in the view after rebuilding the underlying table
EXEC sp_help '[graph].[ReportUses]'

GO

CREATE OR ALTER VIEW [graph].[ReportUses_vw]
AS SELECT $edge_id AS [EdgeID]
        , $from_id AS [FromID]
        , $to_id AS [ToID]
        , [UsedFor]
   FROM [graph].[ReportUses];

GO

EXEC sp_help '[graph].[ReportUses_vw]'
go

select [EdgeID]
        , [FromID]
        , [ToID]
        , [UsedFor] 
from [graph].[ReportUses_vw]
go


--Parent to child, child to report
SELECT [Parent].[ObjectName] AS [Parent Table]
     , [Child].[ObjectName] AS [Child Table]
     , [LinkedTo].[ConstraintName]
     , [LinkedTo].[ConstraintColumns]
	 , [ReportName]
	 , [UsedFor]
FROM [graph].[DBObjects] AS [Child]
   , [graph].[ForeignKeys] AS [LinkedTo]
   , [graph].[DBObjects] AS [Parent]
   , [graph].[Report] 
   , [graph].[ReportUses]
WHERE MATCH([Parent]-([LinkedTo])->[Child]<-([ReportUses])-[Report])
ORDER BY [Parent Table]
       , [Child Table];