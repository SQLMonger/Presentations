//Create Date Dimension
(StartDate as date, EndDate as date)=>

let
    //Capture the date range from the parameters
    StartDate = #date(Date.Year(StartDate), Date.Month(StartDate), 
    Date.Day(StartDate)),
    EndDate = #date(Date.Year(EndDate), Date.Month(EndDate), 
    Date.Day(EndDate)),

    //Get the number of dates that will be required for the table
    GetDateCount = Duration.Days(EndDate - StartDate),

    //Take the count of dates and turn it into a list of dates
    GetDateList = List.Dates(StartDate, GetDateCount, 
    #duration(1,0,0,0)),

    //Convert the list into a table
    DateListToTable = Table.FromList(GetDateList, 
    Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),

    //Add sequentialDayNumber
    SequentialDayNumber = Table.AddIndexColumn(DateListToTable , "SequentialDayNumber", 1, 1),

    //Create various date attributes from the date column
    //Add Year Column
    YearNumber = Table.AddColumn(SequentialDayNumber, "YearNumber", 
    each Date.Year([Date]), Int64.Type),

    //Add End of Year Column
    YearEnds = Table.AddColumn(YearNumber, "YearEnds", 
    each Date.EndOfYear([Date]), type date),

    //Add QuarterNumber Column
    QuarterNumber = Table.AddColumn(YearEnds, "QuarterNumber", 
    each Date.QuarterOfYear([Date]), Int64.Type),

    //Add Quarter Column
    Quarter = Table.AddColumn(QuarterNumber , "Quarter", 
    each "Q" & Number.ToText(Date.QuarterOfYear([Date]))),

    //Add YearQuarter Column
    YearQuarter = Table.AddColumn(Quarter , "YearQuarter", 
    each Number.ToText(Date.Year([Date])) &" Q" & Number.ToText(Date.QuarterOfYear([Date]))),

    //Add YearQuarterSort Column
    YearQuarterSort = Table.AddColumn(YearQuarter, "YearQuarterSort", 
    each Number.ToText(Date.Year([Date])) & "0" & Number.ToText(Date.QuarterOfYear([Date]))),

    //Add Week Number Column
    WeekNumber= Table.AddColumn(YearQuarterSort , "WeekNumber", 
    each Date.WeekOfYear([Date]), Int64.Type),

   //Add Week Beginning
    WeekBeginning= Table.AddColumn(WeekNumber, "Week Beginning", 
    each Date.StartOfWeek([Date]), type date),

    //Add Week Ending
    WeekEnding= Table.AddColumn(WeekBeginning, "Week Ending", 
    each Date.EndOfWeek([Date]), type date),

    //Add Month Number Column
    MonthNumber = Table.AddColumn(WeekEnding, "MonthNumber", 
    each Date.Month([Date]), Int64.Type),

    //Add YearMonthSort Column
    YearMonthSort = Table.AddColumn(MonthNumber, "YearMonthSort", 
    each Date.ToText([Date], "yyyyMM")),


    //Add YearMonth Column
    YearMonth = Table.AddColumn(YearMonthSort, "YearMonth", 
    each Date.ToText([Date], "yyyy-MM")),

    //Add Month Name Column
    MonthName = Table.AddColumn(YearMonth, "Month", 
    each Date.ToText([Date],"MMMM")),

    //Add Days in Month Column
    MonthDays = Table.AddColumn(MonthName, "MonthDays", 
    each Date.DaysInMonth([Date]), Int64.Type),

    MonthDayNumber = Table.AddColumn(MonthDays, "Day Of Month", 
    each Date.Day([Date]), Int64.Type),

    //Add Day of Week Column
    DayOfWeek = Table.AddColumn(MonthDayNumber, "Day of Week", 
    each Date.ToText([Date],"dddd")),

    //Add Day of Week Number sorting Column
    DayOfWeekNumber = Table.AddColumn(DayOfWeek , "DOW Number", 
    each Date.DayOfWeek([Date])+1, Int64.Type),

    //Add Date datatype key
    DateKey = Table.AddColumn(DayOfWeekNumber , "DateKey",
    each Date.ToText([Date], "yyyyMMdd")),

    //Add DateTime datatype key
    DateTimeKey = Table.AddColumn(DateKey , "FullDateKey",
    each DateTime.From([Date]), type datetime),

    //Add a column that returns true if the date on rows is the current date
    IsToday = Table.AddColumn(DateTimeKey, "IsToday", each Date.IsInCurrentDay([Date]), type logical),

    //Add a column that returns true if the date on rows is the current date
    IsThisYear = Table.AddColumn(IsToday, "IsThisYear", each Date.IsInCurrentYear([Date]), type logical),

    //Add a column that returns true if the date on rows is the current date
    IsThisMonth = Table.AddColumn(IsThisYear, "IsThisMonth", each Date.IsInCurrentMonth([Date]), type logical),

    //Add a column that returns true if the date a future date
    Isfuture = Table.AddColumn(IsThisMonth, "IsFuture", each Date.IsInNextNDays([Date],999999), type logical),

    //transform data types. The last two generated errors when trying to convert inline above.
    TransformTypes = Table.TransformColumnTypes(Isfuture , 
		{
		{"Date", type date}
                ,{"DateKey", Int64.Type}
                ,{"YearMonthSort", Int64.Type}
		})

in
    TransformTypes
    