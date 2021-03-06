# DAX Time Calculations 
    Presented 2019-05-14 at the St. Louis Microsoft BI User Group
    Topics: Calendar and Time of day Power Query scripts
            DAX Time calculation prototype template (various sources)
            Power BI Templates

# Presentation outline 
Presentation outline and example code

Resources
The majority of the calculation included in the presented template have been collected from numerous sources. Full credit goes to the individuals who created them in the first place, primarily http://www.sqlbi.com. This presentation shows you how to create your own "library" of calculations that work against a standardized calendar table to allow you to quickly generate the DAX calculation text for any table and measure.

https://github.com/SQLMonger/Presentations
https://sqlmonger.com 
https://twitter.com/sqlmonger 
Clayton@sqlmonger.com

https://www.daxpatterns.com/time-patterns/
https://www.sqlbi.com/articles/week-based-time-intelligence-in-dax/
https://blog.crossjoin.co.uk/2013/11/19/generating-a-date-dimension-table-in-power-query/
https://www.mattmasson.com/2014/02/creating-a-date-dimension-with-a-power-query-script/
http://geekswithblogs.net/darrengosbell/archive/2014/03/23/extending-the-powerquery-date-table-generator-to-include-iso-weeks.aspx
https://ginameronek.com/2014/10/01/its-just-a-matter-of-time-power-bi-date-time-dimension-toolkit/
https://www.sqlbi.com/articles/userelationship-in-calculated-columns/
https://dash-intel.com/powerbi/modeling_date_functions.php
Example database: AdventureworksDW: https://github.com/microsoft/sql-server-samples 



Reed Havens - Templates: All M solution http://www.havensconsulting.net/blog-and-media
Avi Sing - http://www.avising.com

The need for a calendar dimension
    Continuous dates & date attributes to allow for navigation along the "time line"

Methods for creation:
    Calendar dimension table in SQL database (good)
    
    SQL CTE - Generate a time dimension from thin air (better)
    M Script - Generate a time dimension from less than thin air (Best - No database engine required)
    //file: "2 - Time Intelligence DAX measure template.DAX"

Necessary elements of a calendar dimension
    continuous set of date values with no gaps
    Dates and date attributes (list)
Calendar hierarchy attributes (Year, Quarter, Month, Day), (Fiscal Year, Fiscal Month, Fiscal Week, Day)
    Year
            Year Begin Date
            Year End Date
            Prior Year
     Fiscal Year
            FYear Begin Date
            FYear End Date
            Prior FYear
    Quarter
        Prior Quarter
    Month/Period
    Week
    Day
Navigation attributes 
    sequential year, Quarter, Month, Week, day numbers
    Offsets from current day, week, month, Quarter, Year
    Period "buckets" (Prior 30, 60, 90 ,120 days)

Calcuations
    Standardize your calendar dimension. Attributes and names need to be locked down to enable creation of calculation templates

    Template calculations using the standard names, with placeholders for the:
		<DATE TABLE>
		<FactTable>
			<Measure>
Optionally:
		<SemiAdditiveFact>
			<SemiAddditiveMeasure>

    use a "{measure} {suffix}" naming convention. So that all time calculations for a base measure group together.

Turn it into a function with Parameters
     Add BeginDate and EndDate parameters
     Invoke to build table
     Pull Begin/End dates from fact source into a parameter table (2e example)
Build a template

testing calculations
Use calculated tables in Power BI to visualize the filtered table results


Demo steps:

1. New Power BI file
2. Add Parameters for StartDate & EndDate
3. Add M script for Calendar Function using a blank query & advandce editor. Name fnCalendar.
    "2 - fnCalendar.m"
4. Add M Script for Time of Day. Name the query "Time Of Day"
    "3 - Time of Day.m"
5. Invoke fnCalendar Function to create calednar table
6. Get some fact data from SQL Server
7. Add DAX columns to the Calendar Table to complete the needed columns
8. Model changes:
    set calendar table
    set data types (short date)
    no Aggregation on numerics
    hide columns
    set sort orders
    Create hierarchies
    add relationships
    rename columns? may have to If I missed getting all my updates in sync :)
//9. Save model. Save as Template.
//10. Create some base measures : Sales Amount = sum([SalesAmount])
//11. generate time calculations from template
    //"4 - Time Intelligence DAX measure template.DAX"

If time:
change parameters to query based off of data values in the fact & swap out parameter name for table/column reference
    //example: SQLAgent history model
calculations over inactive relationships
https://www.sqlbi.com/articles/userelationship-in-calculated-columns/

USERELATIONSHIP (
        FactInternetSales[DueDateKey],
        Calendar[DateKey]
    )

//base measure & build time calc over it
Sales By Due Date = CALCULATE (
    sum(FactInternetSales[SalesAmount]),
    USERELATIONSHIP (FactInternetSales[DueDateKey], Calendar[DateKey])
)

