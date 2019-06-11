SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

alter view [dbo].[DimCalendarCTE_vw]
as
/*
Dynamically generated Calendar Dimension
Author: Clayton Groom (@SQLMonger) http://twitter/sqlmonger
Includes logic to determine Time_Zone offset and generates UTC date compatible DATETIMEOFFSET Upper and Lower bound columns.
These columns can be used to determine which day of the "base" timezone a fact from another timezone belongs in.
The Daylight Savings time transition days are corrected for.
*/
with 
TimeZone_CTE as /* Get the timezone offset by comparing Server time to Local time */
    ( 
    select datediff(hour, GETUTCDATE(), getdate()) as TimeZone
    )

,DimDate_CTE as /* recursively generate the days from a start date to a future end date */
     (
     select cast('2007-01-01' as datetime) AnchorDate
     union all
     select AnchorDate + 1
     from    DimDate_CTE    
     where   AnchorDate + 1 < DATEADD(s,-1,DATEADD(YYYY, DATEDIFF(YYYY,0,GETDATE())+10,0)) /* calculated end date to stop recursion */
       )
,DSTDays_CTE as /* set of DST transiton dates. Implements 2007 forward DST rules... Second Sunday in March, First Sunday in November */
    (
    select Year(anchorDate) as [DSTYear]
	   ,max(case when month(AnchorDate) = 11 and Datepart(weekday,AnchorDate) = 1 and day(AnchorDate) <8
		  then anchorDate else null
		  end) as [DST End]
	  ,max(case when month(AnchorDate) = 3 and Datepart(weekday,AnchorDate) = 1 and day(AnchorDate) between 8 and 14
		  then anchorDate
		  else null 
		  end) as [DST Start]
   from DimDate_CTE 
   group by Year(anchorDate)
    )
,DSTTimeZone_CTE as /* Build the <Time_Zone> parameter string values needed later by the SWITCHOFFSET() function */
    (select 	
	   	  Case when GetDate() between [DST Start] and [DST End]
			 then TimeZone - 1  --reset to baseline if currently in DST
			 else TimeZone
		   end as [TimeZone]
		  ,Case when GetDate() between [DST Start] and [DST End]
			 then  TimeZone   --reset to baseline if currently in DST
			 else  TimeZone + 1
		  end as [TimeZoneDST]	   
		 ,Case when GetDate() between [DST Start] and [DST End]
			 then case when sign(TimeZone - 1) = -1 
					 then '-' + right('00' + cast(abs(TimeZone - 1)  as varchar),2) + ':00'
					 else '+' + right('00' + cast(TimeZone - 1 as varchar),2)  + ':00'
				end   --reset to baseline if currently in DST
			 else case when sign(TimeZone) = -1 
					 then '-' + right('00' + cast(abs(TimeZone)  as varchar),2) + ':00'
					 else '+' + right('00' + cast(TimeZone as varchar),2)  + ':00'
				end
		  end as [Time Zone]
		  ,Case when GetDate() between [DST Start] and [DST End]
			 then case when sign(TimeZone) = - 1 
					 then '-' + right('00' + cast(abs(TimeZone)  as varchar),2) + ':00'
					 else '+' + right('00' + cast(TimeZone as varchar),2)  + ':00'
				end   --reset to baseline if currently in DST
			 else case when sign(TimeZone + 1) = - 1 
					 then '-' + right('00' + cast(abs(TimeZone + 1)  as varchar),2) + ':00'
					 else '+' + right('00' + cast(TimeZone + 1 as varchar),2)  + ':00'
				end
		  end as [Time Zone DST]
	   from  DSTDays_CTE
	   cross join TimeZone_CTE
	   where DSTYear = Year(GETDATE()) /* Limit to the current year to get a single row */
    )
select 
	   cast(convert(varchar, AnchorDate, 112) as int) as DateKey     
	   ,cast(AnchorDate as date) as FullDateAlternateKey      
	   ,AnchorDate as [DateTime] 
	    /* Compound values needed as level keys for time dimension hierarchies*/
	   ,(Year(AnchorDate) *100) + month(AnchorDate) as MonthKey
	   ,(Year(AnchorDate) *100) + datepart(week,AnchorDate)  as WeekKey
	   ,(Year(AnchorDate) * 10) + datepart(quarter, AnchorDate) as QuarterKey
	   ,cast(convert(varchar, Dateadd(WK, -52, AnchorDate), 112) as int) as [SameBusinessDayPYKey]
	   ,cast(DATEADD(wk, -52,  AnchorDate) as date) as SameBusinessDayPY
	   ,datediff(wk, cast(cast(datepart(mm,AnchorDate) as nvarchar(2)) + '/01/' 
		  + cast(datepart(yyyy,AnchorDate) as nvarchar(4)) as smalldatetime),AnchorDate) +1 as WeekOfMonth
	   ,CONVERT(varchar, AnchorDate, 110) as [TextDate] /* use style 101 for '/' separator */
	   /* many other variations possible by casting to/from a string. the two above are the simplest forms */
	   ,year(AnchorDate) as [Year Nbr]
	   ,datepart(quarter, AnchorDate) as [Qtr Nbr]
	   ,month(AnchorDate) as [Month Nbr]
	   ,datepart(dayofyear, AnchorDate) as [DOY Nbr]
	   ,day(AnchorDate) as [DOM Nbr]
	   ,datepart(weekday, AnchorDate) as [DOW Nbr]
	   ,datepart(week, AnchorDate) as [WOY nbr]
	   /* Returns nvarchar values */
	   ,datename(Year, AnchorDate) as [Year]
	   ,datename(quarter, AnchorDate) as [Quarter]
	   ,datename(month, AnchorDate) as [Month Name]
	   ,left(datename(month, AnchorDate),3) as [Month Abbr]
	   ,datename(year, AnchorDate) + ' ' + left(datename(month, AnchorDate),3) as [Year Month]
	   ,datename(dayofyear, AnchorDate) as [DOY]
	   ,datename(day, AnchorDate) as [DOM]
	   ,datename(week, AnchorDate) as [WOY]
	   ,datename(weekday, AnchorDate) as [DOW Name]
	   ,left(datename(weekday, AnchorDate),3) as [DOW Abbr]
	   ,DATEADD(s,-1,DATEADD(YYYY, DATEDIFF(YYYY,0,AnchorDate)+1,0)) as LastDOY
	   ,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,AnchorDate),0)) as LastDay_PriorMonth
	   ,DATEADD(s,0,DATEADD(mm, DATEDIFF(m,0,AnchorDate),0)) FirstDOM	
	   ,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,AnchorDate)+1,0)) as LastDOM

	   /* Logical flags */
	   ,case when day(AnchorDate) = 1 then 'Y' else 'N' end as [First_DOM_YN]
	   ,case when day(dateadd(day,1,AnchorDate)) = 1 then 'Y' else 'N' end as [Last_DOM_YN]
	   ,case when datepart(weekday, AnchorDate) between 2 and 6 then 'Y' else 'N' end as [Weekday_YN]
	   /* Daylight Savings Time and UTC date related attributes */
	   ,s.[DST Start]
	   ,s.[DST End]
	   ,case when AnchorDate between s.[DST Start] and s.[DST End]
		  then 1 else 0
	    end as [DST Flag]
     ,[Time Zone]
	,case when AnchorDate between s.[DST Start] and s.[DST End]
		  then [Time Zone DST] 
		  else [Time Zone]
	 end as [Time Zone DST]
	,case when AnchorDate = s.[DST Start]
		  then cast(cast(anchordate as varchar) + ' ' + [Time Zone] as datetimeoffset)
		  when AnchorDate = s.[DsT End]
		  then cast(cast(anchordate as varchar) + ' ' + [Time Zone DST] as datetimeoffset) 
		  Else cast(cast(anchordate as varchar) + ' '  
					+ case when AnchorDate between s.[DST Start] and s.[DST End]
						  then [Time Zone DST] 
						  else [Time Zone]
					   end
				 as datetimeoffset)
	   End as UTCLowerBound
	,case when AnchorDate = s.[DST Start]
		  then cast(cast(anchordate as varchar) + ' ' + [Time Zone DST] as datetimeoffset) 
		  when AnchorDate = s.[DsT End]
		  then cast(cast(anchordate as varchar) + ' ' + [Time Zone]  as datetimeoffset) 
		  Else cast(cast(anchordate as varchar) + ' ' 
					+ case when AnchorDate between s.[DST Start] and s.[DST End]
						  then [Time Zone DST] 
						  else [Time Zone]
					   end  
				as datetimeoffset)
	   End as UTCUpperBound
	from    DimDate_CTE as d
	inner join DSTDays_CTE as s
	   on s.[DSTYear] =  year(AnchorDate) 
	   cross join DSTTimeZone_CTE
	--OPTION (MAXRECURSION 0) 
	--include the above option in any queries over the view...
go

--Recommend creating a real table and filling it with the results from the view/query above.
	-- And add some indexes :)
	
select * 
--into DimCalendar
from [dbo].[DimCalendarCTE_vw]
where [Year] = 2015
order by 1
option (maxrecursion 0)

