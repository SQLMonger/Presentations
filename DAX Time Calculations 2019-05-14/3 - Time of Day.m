let
    Source = List.Times(#time(0,0,0) , 86400, #duration(0,0,0,1)),
    convertToTable = Table.FromList(Source, Splitter.SplitByNothing(), {"DayTime"}, null, ExtraValues.Error),
    createTimeKey = Table.AddColumn(convertToTable , "TimeKey", each Time.ToText([DayTime], "HHmmss")),
    hourIndex = Table.AddColumn(createTimeKey, "HourIndex", each Time.Hour([DayTime])),
    minuteIndex = Table.AddColumn(hourIndex, "MinuteIndex", each Time.Minute([DayTime])),
    #"Add MilitaryTime" = Table.DuplicateColumn(minuteIndex, "DayTime", "Military Time"),
    #"Changed Type" = Table.TransformColumnTypes(#"Add MilitaryTime",{{"Military Time", type time}, {"HourIndex", Int64.Type}, {"MinuteIndex", Int64.Type}}),
    #"Added Index" = Table.AddIndexColumn(#"Changed Type", "Minute of Day", 1, 1),
    #"Renamed Columns1" = Table.RenameColumns(#"Added Index",{{"HourIndex", "Hour"}, {"MinuteIndex", "Minute"}}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Renamed Columns1",{{"TimeKey", Int64.Type}}),
    #"Added Shift" = Table.AddColumn(#"Changed Type2", "Shift", each if [TimeKey] < 70000 then 3 else if [TimeKey] < 153000 then 1 else 2),
    #"Changed Type3" = Table.TransformColumnTypes(#"Added Shift",{{"Shift", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type3",{{"DayTime", "Time of Day"}})
in
    #"Renamed Columns"

// tightened up, added display columns, Second & Shift Name columns

let
    Source = List.Times(#time(0,0,0) , 86400, #duration(0,0,0,1)),
    ConvertToTable = Table.FromList(Source, Splitter.SplitByNothing(), {"Time of Day"}, null, ExtraValues.Error),
    //HHMMSS formtat "TimeKey"
    CreateTimeKey = Table.AddColumn(ConvertToTable, "TimeKey", each Time.ToText([Time of Day], "HHmmss")),
    ChangeTimeKeyType = Table.TransformColumnTypes(CreateTimeKey,{{"TimeKey", Int64.Type}}),
    //Raw Hour (0-23), Minute (0-59) & second (0-59) values
    Hour = Table.AddColumn(ChangeTimeKeyType, "Hour", each Time.Hour([Time of Day]), Int64.Type),
    Minute = Table.AddColumn(Hour, "Minute", each Time.Minute([Time of Day]), Int64.Type),
    Second = Table.AddColumn(Minute, "Second", each Time.Second([Time of Day]), Int64.Type),

    //Sequential keys for sorting display values
    HourKey = Table.AddColumn(Second, "HourKey", each Time.Hour([Time of Day]), Int64.Type),
    MinuteKey = Table.AddColumn(HourKey, "MinuteKey", each ([Hour] * 60) + [Minute] , Int64.Type),
    SecondKey = Table.AddIndexColumn(MinuteKey, "SecondKey", 1, 1),
    
    //Display values for hierarchy levels
    HourOfDay = Table.AddColumn(SecondKey,"Hour of Day", each Time.ToText(#time([Hour],0,0))),
    MinuteOfDay = Table.AddColumn(HourOfDay,"Minute of Day", each Time.ToText(#time([Hour],[Minute],0))),
    MilitaryHour = Table.AddColumn(MinuteOfDay, "Military Hour", each Time.ToText(#time([Hour],[Minute],[Second]), "HH:00:00")),
    MilitaryMinute = Table.AddColumn(MilitaryHour, "Military Minute", each Time.ToText(#time([Hour],[Minute],[Second]), "HH:mm:00")),
    MilitaryTime = Table.AddColumn(MilitaryMinute, "Military Time", each Time.ToText(#time([Hour],[Minute],[Second]), "HH:mm:ss")),

    //standard work shifts (00:00 - 7:59, 8:00 - 16:59, 17:00 - 23:59)
    AddShift = Table.AddColumn(MilitaryTime, "Shift", 
        each if [TimeKey] < 70000 then 3 else if [TimeKey] < 153000 then 1 else 2 ),
    AddShiftName = Table.AddColumn(AddShift, "Shift Name", 
        each if [TimeKey] < 70000 then "Shift 3" else if [TimeKey] < 153000 then "Shift 1" else "Shift 2" ),
    #"Filtered Rows" = Table.SelectRows(AddShiftName, each true)
in
    #"Filtered Rows"