section Section1; 



shared #"Child Objects" = let 

Source = Sql.Database("localhost\sql2019", "AdventureWorksDW", [Query="SELECT * FROM [graph].[DBObjects_vw]", CreateNavigationProperties=false]) 

in 

Source; 



shared Relationships = let 

Source = Sql.Database("localhost\SQL2019", "AdventureWorksDW", [Query="SELECT [EdgeID]#(lf) , [FromID]#(lf) , [ToID]#(lf) , [ConstraintName]#(lf) , [ConstraintColumns]#(lf)FROM [graph].[ForeignKeys_vw];", CreateNavigationProperties=false]) 

in 

Source; 



shared #"Parent Objects" = let 

Source = Sql.Database("localhost\sql2019", "AdventureWorksDW", [Query="SELECT * FROM [graph].[DBObjects_vw]", CreateNavigationProperties=false]), 

#"Renamed Columns" = Table.RenameColumns(Source,{{"ObjectName", "Parent Object Name"}, {"ObjectSchema", "Parent Object Schema"}, {"ObjectID", "Parent ObjectID"}, {"NodeID", "Parent NodeID"}}) 

in 

#"Renamed Columns"; 



shared Hierarchy = let 

Source = Sql.Database("localhost\sql2019", "AdventureWorksDW", [Query="WITH obj AS#(lf)(#(lf) SELECT $node_id NodeID, [ObjectName] as [ParentTable] #(lf)#(tab),CAST(NULL AS sysname) as [ChildTable]#(lf) FROM graph.DBObjects#(lf) UNION ALL#(lf) SELECT ct.$node_id#(lf)#(tab), ct.[ObjectName] [ChildTable]#(lf)#(tab), obj.[ParentTable]#(lf) FROM graph.DBObjects as ct #(lf) INNER JOIN graph.ForeignKeys as fk#(lf) ON ct.$node_id = fk.$from_id #(lf) INNER JOIN obj#(lf) ON fk.$to_id = obj.NodeID#(lf)where ct.[ObjectName] <> obj.[ParentTable]#(lf))#(lf)SELECT NodeID,[ParentTable], [ChildTable]#(lf)FROM obj#(lf)WHERE [ParentTable] IS NOT NULL#(lf)OPTION (MAXRECURSION 500) ", CreateNavigationProperties=false]) 

in 

Source; 



shared Reports = let 

Source = Sql.Database("localhost\sql2019", "AdventureWorksDW", [Query="SELECT * FROM [graph].[Report_vw]", CreateNavigationProperties=false]) 

in 

Source; 



shared #"Reports Uses" = let 

Source = Sql.Database("localhost\sql2019", "AdventureWorksDW", [Query="SELECT * FROM [graph].[ReportUses_vw]", CreateNavigationProperties=false]) 

in 

Source;