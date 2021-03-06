

--- These functions are used to either run something at a specific time, or to determine whether some action should be performed based on time information.
-- @section timers 

--- A function that tests whether the current time is within a specified time window from a given time.
-- In order to work well with the output of fibaro:call(1,"sunsetHour") and similar use cases, time is specified in the
-- form of a string ("08:10" for ten minutes past eight in the morning) in a 24 hour clock format, and an offset (in minutes).
-- When called as isTime("08:10",0,10) the function will return 'true' from 08:09:50 to 08:10:10, and 'false' outside of this time range.
-- Please note that the function will return true every time it is checked within the time range, so the calling function
-- needs to make sure that there is an appropriate delay between checks.
--
-- A call isTime("08:10",45,10) will return 'true' from 08:54:50 to 08:55:10, and 'false' earlier or later than this.
-- @tparam string timeString The textual specification of the time to test against (e.g. "08:10").
-- @tparam number offsetMinutes The number of minutes to add to the 'timeString' time.
-- @tparam number secondsWindow The size of the time window (in secons) in which the function will return 'true'. A zero (0) will cause the function to return 'true' only at 08:10:00 (and not 08:10:01) when called as isTime("08:10",0,0) so calls like that should be avoided.
-- @treturn boolean A boolean (true or false) indicating whether the current time is within the specificed time range.


function isTime (timeString, offsetMinutes, secondsWindow)
    local timeTable = timestringToTable(timeString);
    local timeEpoch = tableToEpochtime (timeTable);
    local timeWithOffset = timeEpoch + (offsetMinutes * 60);
    local now = os.time();
    return ( math.abs(timeWithOffset - now) <= secondsWindow );
end;

--- Functions that may be used for boolean tests of current date or time.
-- @section timetriggers

--- A function that checks whether the current time is within a range given as two text strings.
-- This function is often more convenient than 'isTime' as you don't have to calculate the time and offset yourself.
-- Please note that the function will return true every time it is checked within the time range, so the calling function
-- needs to make sure that there is an appropriate delay between checks.
--
-- @tparam string startTimeString a time specification in the form of "HH:MM" (e.g. "08:10") indicating the start of the time range.
-- @tparam string endTimeString a time specification in the form of HH:MM (e.g. "08:10") indicating the end of the time range.
-- @treturn boolean A boolean (true or false) indicating whether the current time is within the specificed time range.
function timeIsInRange (startTimeString, endTimeString)
    local startTimeTable = timestringToTable(startTimeString);
    local endTimeTable = timestringToTable(endTimeString);
    local startTimeEpoch = tableToEpochtime (startTimeTable);
    local endTimeEpoch = tableToEpochtime (endTimeTable);
    local newEndTimeTable = endTimeTable;
    -- allow for end time being in the upcoming day, but before startTime then
    if (endTimeEpoch < startTimeEpoch) then
        endTimeEpoch = endTimeEpoch + 24*3600;  -- add 24 hours
        -- Now, we make a new table object, to find out whether the DST status of the new end time is
        newEndTimeTable = os.date("*t",endTimeEpoch);
    end;
        -- Now, we adjust for Daylight saving time effects
    if (startTimeTable.isdst == false and newEndTimeTable.isdst == true) then
        -- In this case, start time is Not summer, and end time is in summer time
        -- which means that we are going from spring into summer
        -- then advance the clock one more hour from the end time
        endTimeEpoch = endTimeEpoch + 3600;
    elseif (startTimeTable.isdst == true and newEndTimeTable.isdst == false) then
        -- Here, we are coming into fall (from summer)
        -- then remove one hour from the time end time
         endTimeEpoch = endTimeEpoch - 3600;
    end;
    local now = os.time();
    return ( (startTimeEpoch <= now ) and (endTimeEpoch >= now));
end;



--- Check whether current time is before a specified time.
-- The function is designed to work well in a chain of checks, and therefore also makes sure that
-- time is not before the start of the day.  This functions is primarily designed to be used with "sunriseTime" or similar variables.
-- @tparam string time A time specification string, e.g. "08", "08:10" or "08:10:10"
-- If not specified, seconds is assumed to be 00, so that "08:10" is equivalent to giving "08:10:00"
-- as an argument. Thus, this function will then return 'true' up until "08:09:59" .
-- @tparam number offset an offset that should be applied to the time (in number of seconds). Negative values will cause the function to return true x seconds before the indicated time of day.
-- @treturn boolean A truth value (true/false)
-- @see os.time

function beforeTime(time, offset)
    local timeEpoch = tableToEpochtime(timestringToTable(time));
    local startOfDay = tableToEpochtime(timestringToTable("00:00"));
    local off = offset or 0;
    timeEpoch = timeEpoch + off;
    local now = os.time();
    return( (now < timeEpoch) and (now >= startOfDay ));
end;

--- Check whether current time is after a specified time.
-- The function is designed to work well in a chain of checks, and therefore also makes sure that
-- time is not after the end of the day.
-- @tparam string time A time specification string, e.g. "08", "08:10" or "08:10:10".
-- If not specified, seconds is assumed to be 00, so that "08:10" is equivalent to giving "08:10:00"
-- as an argument. Thus, this function will then return 'true' from "08:10:01" and onwards.
-- @tparam number offset an offset that should be applied to the time (in number of seconds). Negative values will cause the function to return true x seconds before the indicated time of day.
-- @treturn boolean A truth value (true/false)
-- @see os.time

function afterTime(time, offset)
    local timeEpoch = tableToEpochtime(timestringToTable(time));
    local endOfDay = tableToEpochtime(timestringToTable("23:59:59"));
    local off = offset or 0;
    timeEpoch = timeEpoch + off;
    local now = os.time();
    return( (now > timeEpoch) and (now <= endOfDay ));
end;

--- A function that selects the earlierst time specification from a list of times.
-- @param ... a list of times in string format, e.g. "HH:MM" or "HH:MM:SS". 
-- @return The time that occurs earliest in the day.
-- @usage
-- print(earliest("22","20:30:01","21","20:30"));
-- -- will return "20:30" since tis is synonumous with "20:30:00"
-- sunsetHour = tostring(fibaro:getValue(1, "sunsetHour") or "22:30:01");
-- -- This code then selects the time that occurs earliest - sunset or 22:30.
-- print(earliest(sunsetHour,"22:30"));

function earliest(...)
    local arg = {...};
    local out = nil;
    local currEpoch = nil;
    local outEpoch = nil;
    for k,time in ipairs(arg) do
        if out == nil then
            out = time;
            outEpoch = tableToEpochtime(timestringToTable(time));
        else
            currEpoch = tableToEpochtime(timestringToTable(time));
            if currEpoch < outEpoch then
                out = time;
            end;
        end;
    end;
    return(out);
end;

--- A function that selects the latest time specification from a list of times.
-- @param ... a list of times in string format, e.g. "HH:MM" or "HH:MM:SS". 
-- @return The time that occurs latest in the day.
-- @usage
-- print(earliest("22","20:30:01","21","20:30"));
-- -- will return "22".
-- sunsetHour = tostring(fibaro:getValue(1, "sunsetHour") or "22:30:01");
-- -- This code then selects the time that occurs latest - sunset or 22:30.
-- print(earliest(sunsetHour,"22:30"));

function latest(...)
    local arg = {...};
    local out = nil;
    local currEpoch = nil;
    local outEpoch = nil;
    for k,time in ipairs(arg) do
        if out == nil then
            out = time;
            outEpoch = tableToEpochtime(timestringToTable(time));
        else
            currEpoch = tableToEpochtime(timestringToTable(time));
            if currEpoch > outEpoch then
                out = time;
            end;
        end;
    end;
    return(out);
end;

--- A function that lets you specify date and time in a very flexible way through a table
-- The table should use only fields that are returned by a call to @{os.time} (year, month, day, hour, min, sec), 'wday' (1-7 scale, Sunday is 1) or 'yday' (day within the year, Jan 1st is 1).
-- @tparam table dateTable A table giving a time specification.  For instance, {day=6,hour=15} returns 'true' on Sundays at 3 pm, {year=2016,month=2, hour=9} will return 'true' every day in February 2016 at 9 am, and 'false' at any time where parts of specification is not met. In each field, a table may be given, in which case any one of the options given will be accepted.
-- @treturn boolean A boolean (true/false) indicating the complete match of the table against current time and date.
-- @see os.time
-- @usage datetimeTableTrue({month=2,minute=2})
-- -- # will return 'true' every other minute in february.
-- datetimeTableTrue({wday=2,yday=2})
-- -- # will return 'true' when tested on the January 2nd, if it is a Monday.
-- datetimeTableTrue({month=1,day=14,hour=6, min=30})
-- -- Will return 'true' when I wake up on my birthday
-- datetimeTableTrue({month=1,day={14,15,16},hour=6, min={0,30}})
-- -- Will return 'true' on the 14th,15th or 16th of January at 6:00 or 6:30.

function datetimeTableTrue (dateTable)
    local nowTodayTable = os.date("*t");
    local scorekeeper = false;
    for k,v in pairs(dateTable) do
        -- Here I intentionally disregard the boolean isdst value, as the dateTable time specification should always be "true" time
        if type (v) == "number" then
            if not (nowTodayTable[k] == dateTable[k]) then
                return(false);
            end;
        elseif type (v) == "table" then
            -- Here the logic is different. We cannot return 'false' until we have checked all elements in the list.
            for ki, vi in pairs(v) do
                if (nowTodayTable[k] == v[ki]) then
                    scorekeeper = true;
                end;
            end;
            if not scorekeeper then
                return(false)
            end;
            scorekeeper = false;
        else
            if not debug == nil then
                fibaro:debug("List of options in a field in the table should only contain numbers")
            else
                error("List of options in a field in the table should only contain numbers")
            end;
        end;
    end;
    return(true);
end;

--- A funtion that applies a time adjustment to a time specified in a string format
-- What is supplied to the function is a time in a standard format (eg "08:25", "8:25", "08:25:05").
-- A numer of minutes (or optional seconds) are then added to the time, and the time is returned as a new time string.
-- The adjustment is applied at the Epoch time level, which means that adjustments that also leads to change of date will be correctly handled.
-- For the conversion, the time specification is assumed to be refering to *today*.
-- @tparam string stringTime the time specification.
-- @tparam number adjustmentMinutes the number of minutes to be added to the time. Negative values means subtraction of time.
-- @tparam number extraSecondsAdjustment an optional number of seconds to be added too (that is, in additional to the minutes). Negative numbers means subtraction.

function stringTimeAdjust(stringTime,adjustmentMinutes,extraSecondsAdjustment)
    local extraSecs = extraSecondsAdjustment or 0;
    local timeEpoch = tableToEpochtime(timestringToTable(stringTime));
    local adjustSeconds = tonumber(adjustmentMinutes) * 60 + tonumber(extraSecs);
    local newEpochTime = timeEpoch + adjustSeconds;
    local newTime = tostring(os.date("%X",newEpochTime));
    return(newTime);
end;


--- Function that simplifies running a scene on a timer and specify the delay needed.
-- The basic structure of the function is that it takes a truth value indicating whether the scene should run.
-- The idea is that this truth value should be the result of a series of time or source evaluations combined
-- into one evaluation by 'and' and 'or' joiners, possibly with nesting.
-- The function @{runIf} will then evaluate the function supplied as the second argument, if the first argument is evaluated to 'true'. @{runIf} could also be a table of integers, which should then be the Scene IDs of scenes that should be executed.
-- 
-- After running the function constituting the scene, or the scenes with the scene ID's supplies as the'toRun' argument,  a delay may be imposed.
-- 
-- @tparam boolean shouldRun A truth value. If evaluated to 'true', then the function will be run and the delay imposed.
-- @tparam func toRun The function summarising the actions of the scene.
-- @tparam {int} toRun if instead an array is passed to the function, this is assumed to be an array of scene IDs to run.
-- @tparam[opt=0] int sleepSeconds Optional number of seconds delay that should be imposed after having performed the scene (defaults to 60). If the scene is not executed, there is not delay. Please note that the whole scene is put to sleep 'sleepSeconds' seconds, which may affect the execution of other timers.
-- @usage
-- function f () fibaro:call(12,"powerON"); end
-- -- A very simple scene function
-- runIf ( sceneNotCurrentlyRunning() and isTime("08:10",0,20) and isDayOfWeek("Mon","Tues"), f, 2*60)
-- -- This call will turn on switch 12 when tested from 08:09:40 to 08:10:20 on Mondays and Tuesdays
-- -- and then sleep for 2 minutes in order to ensure that the scene is not run constantly,
-- -- or more than once, as the 2 minutes delay combined with the call to @{sceneNotCurrentlyRunning} makes
-- -- sure that it is not evaluated again within the 20 seconds time window allowed by the call to @{isTime}.



function runIf(shouldRun, toRun, sleepSeconds )
  local delay = sleepSeconds or 0;
  if (type(toRun) == "function" and shouldRun ) then
    toRun();
  elseif ( type(toRun) == "table"  and shouldRun ) then
    for k,v in pairs(toRun) do
        v = tonumber(v);
        if ( fibaro:isSceneEnabled(v)) then
          fibaro:startScene(v);
        else
          fibaro:debug("Not running disabled scene ID:".. tostring(k));
        end;
    end;
  end;
  fibaro:sleep(delay*1000);
end;

--- A small function that just makes the script wait intil the start of the next minute.
-- Actually, the function name is a misnomer as the function rarely waits exactly one minute. 
-- It just waits until the next minute starts.

function waitUntilNextMinute()
    local currSec = os.time() % 60;
    local toWait = 60 - currSec;
    fibaro:sleep(toWait *1000);
end;

--- This function provides the basic functionality for timer schenes.
-- Essentially, it runs forever (or until the scene is stopped) and executed the supplied function every minute.
-- @tparam function fun A function that describes a set of actions to be performed. Usually this function contains a series of {runIf} calls. Please note that the argument is a function, not a call to a function. See Usage below.
-- @usage
-- funciton myFun() 
--   runIf(isWeekEnd() and timeIs("09:00"),99,0); -- Runs scene with ID 99 at 09:00 on weekends
--   runIf(isWeekEnd() and timeIs("06:30"),99,0); -- Runs scene with ID 99 at 07:30 on weekdays
-- end;
-- runEveryMinute(myFun);


function runEveryMinute(fun)
    while(true) do
        fun();
        waitUntilNextMinute();
    end;
end;

--- Function that determines whether its time to turn off the heater.
-- The determination is based on the time when the heater was turned on, an auto off time and a
-- filter boolean that makes it possible to block turning the AC off.
-- @tparam number heaterOnTime An Epoch time stamp indicating when the heater was turned on
-- @tparam number autoOffTime The number of hours after which the heater should automatically be turned off.
-- @tparam boolean blockedByOutsideTemperature A true/false value. If 'true' automatic shutoff will be blocked. The idea is that this value should be based on an expression involving the outside temperature
-- @usage
-- shouldStopHeater (fibaro:getModificationTime(193, "value"), 3, tonumber(fibaro:getValue(3, "Temperature")) <= -20 )
-- -- This call will return when checked 3 hours or more after the time when the state of
-- -- device 193 was last changed, provided that the current outside temperature is not <= -20 degrees.
-- -- If the temperature is <= -20 degrees, the function will always return 'false'
-- -- so that the heater is not stopped.

function shouldStopHeater (heaterOnTime, autoOffTime, blockedByOutsideTemperature)
    local now = os.time();
    -- Here, I negate the boolean so that a true in the block results in a false in
    -- response to the question whether the shutoff should be blocked
    local notblock = (not blockedByOutsideTemperature) or false;
    return (  notblock  or  ( now - heaterOnTime ) >= (3600 * autoOffTime) );
end;

--- Convenience funtion for printing an epoch timestamp in ISO 8601:1988 format.
-- @param timestamp a epoch time stamp, such as a time indication associated with a Fibaro event.
-- @treturn string a text representation "YYYY-MM-DD hh:mm" of the epoch timestamp, in the local timezone.

function iso8601DateTime(timestamp)
  return(os.date("%Y-%m-%d %X",tonumber(timestamp)));
end;



--- A function that determines whether the heater of a car should be turned on.
-- The determination is base on the time when you want to leave, the temperature outside and an optional value indicating whether the heater is on already or not.
-- @tparam string readyTime A time specification where the cars should be ready, e.g. "07:30" for half past 7 in the morning.
-- @tparam number tempOutside The temperature outside or inside the car (if available).
-- @tparam[opt=true] boolean eco Should eco settings be used? If not, the car motor health will be considered more important.
-- @tparam[opt=0] number manualMinutesOffset A manual offset in number of minutes. Should be negative if the heater should start ahead of time, and positive if starting should be delayed some minutes.
-- @treturn boolean A truth value (true/false).

function timeToStartCarHeater (readyTime, tempOutside, eco,manualMinutesOffset)
    local timeEpoch = tableToEpochtime(timestringToTable(readyTime));
    local offset = manualMinutesOffset or 0;
    local now = os.time();
    local startTime = timeEpoch;
    if (eco) then
        if (tempOutside <= -15) then
            -- 2 Hours before time
            startTime = timeEpoch - (3600*2) ;
        elseif (tempOutside <= -10) then
            -- 1 Hour before time
            startTime = timeEpoch - (3600*1) ;
        elseif (tempOutside <= 0) then
            -- 1 Hours before time
            startTime = timeEpoch - (3600*1);
        elseif (tempOutside <= 10) then
            -- 0.5 Hours before time
            startTime = timeEpoch - (3600*0.5);
        else
            -- if not <=10 degrees C, do not start the heater.
            return(false);
        end;
    else
        if (tempOutside <= -20) then
            -- 3 Hours before time
            startTime = timeEpoch - (3600*3);
        elseif (tempOutside <= -10) then
            -- 2 Hours before time
            startTime = timeEpoch - (3600*2);
        elseif (tempOutside <= 0) then
            -- 1 Hours before time
            startTime = timeEpoch - (3600*1);
        elseif (tempOutside <= 10) then
            -- 1Hours before time
            startTime = timeEpoch - (3600*1);
        else
            -- if not <=10 degrees C, do not start the heater.
            return(false);
        end;
    end;
    -- Now calculate whether the heater should start NOW
    return (  ( (startTime + manualMinutesOffset*60) <= now) and (now <= timeEpoch));
end;

--- Utility functions related to date and time conversions.
-- These small local functions are used heavilly by the functions in the previous section, and should therefore be included in scenes as soon as they are.
-- @section datetimeutilities

--- A function that creates a @{os.date} table from a time specified as a string. 
-- Provided that the function is not called exactly at midnight, the function will return a table that mathces the output of an os.date("*t")
-- @tparam string time A text representation (e.g. "08:10") of the time of today to concert to a @{os.date} date table. Allowed formats are "HH", "HH:MM" or "HH:MM:SS". "HH" is a short form for "HH:00" and "HH:MM" is a short for "HH:MM:00".
-- @treturn table A table with year, month,day, hour min, sec and isdst fields.
-- @see os.date
-- @usage
-- timestringToTable("08:10")
-- -- Will return 'true' when between 08:10  and 08:59
-- timestringToTable("08")
-- -- Will return 'true' the entire hour
-- timestringToTable("08:10:10")
-- -- Will return 'true' exactly at the indicated second
function timestringToTable (time)
    local dateTable = os.date("*t");
    -- Get an iterator that extracts date fields
    local g =  string.gmatch(time, "%d+");

    local hour = g() ;
    local minute = g() or 0;
    local second = g() or 0;
    -- Insert sunset inforation istead
    dateTable["hour"] = hour;
    dateTable["min"] = minute;
    dateTable["sec"] = second;
    return(dateTable);
end;


-- Utility function that computes the number of seconds since Epoch from a date and time table in the form given by os.date
-- @tparam table t A time specification table with the fields year, month, day, hour, min, sec, and isdst.
-- @treturn number An integer inficating the Epoch time stamp corresponding to the date and time given in the table.

function tableToEpochtime (t)
    local now = os.date("*t");
    local outTime = os.time{year=t.year or now.year, month=t.month or now.month,day=t.day or now.day,hour=t.hour or now.hour,min=t.min or now.min,sec=t.sec or now.sec,isdst=t.isdst or now.isdst};
    return(outTime);
end;


--- Functions that together provide a timed auto-off/on functionality, and other housekeeping type actions.
-- Useful for devices that do not have this functionality themselves, or for delayed OFF or ON that are outside of the time range offered by the device internally.
-- These functions all require that a HOUSEKEEPING variable is set up.
-- @section housekeeping
-- TODO: gör om strukturen så att man även kan säta en variabel till ett värde

--- Utility function to check the integrety of hte HOUSEKEEPING variable.
function checkHousekeepingIntegrity()
    local houseVariable = tostring(fibaro:getGlobalValue("HOUSEKEEPING"));
    local parsedVariable = json.decode(houseVariable);
    for id,cmdList in pairs(parsedVariable) do
        -- check that all keys are interpertable as epoch time stamps 
        if tonumber(id) == nil or fibaro:getGlobal(id) == nil then
            error("The 'id' field must be either a device ID or the name of a global variable!");
        end;

        for k,cmdL in pairs(cmdList) do
            -- Check that the load is a table and that it has the manditory fields
            if type(cmdL) ~= "table" and cmdL["time"] == nil or cmdL["cmd"] == nil then
                error("The command table is not well formed or does not contain manditory fields cmd and time!");
            end;
            -- basic checks of structure:
            -- here we check that the time stamp is a number, and that it is larger than the 
            -- time stamp of the time when the function was written
            -- which is unlikely to be an epoch rep. of a time event that should be executed. 
            if tonumber(cmdL["time"]) == nil or tonumber(cmdL["time"]) <= 1510469428 then
                error("The time field is not a number!");
            end;
            -- Check that commands that require a paramter gets one
            -- commnads I know about are these: 
            local oneArg ={"setValue","setSetpointMode","setMode","setFanMode","setVolume","setInterval","pressButton","setFanMode"};
            if tableValueExists(oneArg,cmdL["cmd"] ) and cmdL["value"] == nil then
                error("The cmd is one that takes one argument, but this is not supplied correctly!");
            end; 
            -- commands that I know have 2 arguments
            -- these should have a "arg1" and "arg2" specification in the command structure
            local twoArgs ={"setThermostatSetpoint","setSlider","setProperty"};
            if tableValueExists(twoArgs,cmdL["cmd"] ) and (cmdL["arg1"] == nil or cmdL["arg2"] == nil) then
                error("The cmd is one that takes two arguments, but they are not supplied correctly!");

            end;
        end       
    end;
end;



function initiateHousekeepingVariable()
    fibaro:debug("Initiating the variable HOUSEKEEPING to {}")
    local EMPTY = {};
    fibaro:setGlobal('HOUSEKEEPING',json.encode(EMPTY))
end;


--- This function sets a housekeeping task schedule for a set of devices.
-- The function requires that a HOUSEKEEPING global variable is initiated using the {@initiateHousekeepingVariable} and is fully functional.
-- This function will then insert a time when the task 'command' should be performed on devices. The time is specified by the user as a delay (relative to the current time).
-- The housekeeping task will then be performed after 'delaySeconds' seconds has elapsed, or whenever the houekeeping routine is performed after that. This makes sure that timers are not interrupted if you decide to restart your Home Center when timers are running.
-- @param deviceIDs A singe device ID or an array of IDs which should recieve the 'command' command after  'delaySeconds' seconds.
-- @tparam int delaySeconds The number of seconds that should pass before the 'command' is sent.
-- @tparam[opt='turnOff'] string command The command to be sent. The command could also be a {commad,value} tuple.
-- @usage
-- registerHousekeepingTask({10,11,13},25,"turnOn")
-- -- This will turn devices 10,11 and 13 on after 25 seconds.
-- registerHousekeepingTask({10,11,13},25,"turnOn")
-- -- This will turn devices 10,11 and 13 on after 25 seconds.
-- TODO: gör om strukturen så att man även kan säta en variabel till ett värde

function registerHousekeepingTask(deviceIDs, delaySeconds, command )
    local command = command or "turnOff";

    local timeToSet = (os.time() + delaySeconds);
    -- Reinitiate variable if it is not parable as json and is well structured
    if not pcall(checkHousekeepingIntegrity) then 
        initiateHousekeepingVariable();
    end;
    -- Get data
    local houseVariable = tostring(fibaro:getGlobalValue('HOUSEKEEPING'));
    local parsedVariable = json.decode(houseVariable)  ; 
    -- make sure that we have an array of device ids.
    if type(deviceIDs) ~= "table" and tonumber(deviceIDs) ~= nil then
        deviceIDs = {deviceIDs};
    else
        error("Please supply integer DEviceID values, either as an array or a single value!");
    end;

    for k,id in pairs(deviceIDs) do
        -- command to be inserted
        local cmdTable = {["time"]=timeToSet};
        cmdTable["cmd"]=command;
        -- This is for one argument commands
        if type(command) == "table" and #command == 2 then
            cmdTable["value"] = command[2];
        end;
        if type(command) == "table" and #command == 3 then
            cmdTable["arg1"] = command[2];
            cmdTable["arg2"] = commant[3];
        end;
        -- now we have only one sceduled command per device id
        parsedVariable[tostring(id)] = cmdTable;
    end;
    -- print and store housekeeping 
    local outString = json.encode(parsedVariable);
    fibaro:debug("Setting Housekeeping tasks: "..outString);
    fibaro:setGlobal('HOUSEKEEPING',outString);
end;

--- A procedure that performs housekeeping tasks
-- It uses the HOUSEKEEPING variable and interprets the time schedule in there. Keys in the table should be the time when tasks should be perfomrmed.
-- The value should be a list of command specifications.
-- TODO: kolla så att denna funktion verkligen fungerar!
function doHousekeeping()
    if not pcall(checkHousekeepingIntegrity) then 
        fibaro:debug("ERROR: HOUSEKEEPING tasks are not well structured. Performing reset. No taks will be performed, so you need to initiate them again.")
        initiateHousekeepingVariable();
        return(false);
    end;
    -- Get data
    local houseVariable = tostring(fibaro:getGlobalValue('HOUSEKEEPING'));
    fibaro:debug("GOT: " .. houseVariable);
    local parsedVariable = json.decode(houseVariable) ;
    debugTable(parsedVariable) ;
    for id,cmdStruct in pairs(parsedVariable) do
        now = os.time();
        local time = cmdStruct["time"];
        -- check whether the stored execution time is now or has passed.
        if time ~= nil and tonumber(time) <= now then
            -- section for device commands
            if tonumber(id) ~= nil then
                if cmdStruct["cmd"] ~= nil and cmdStruct["arg1"] ~= nil and cmdStruct["arg2"] ~= nil then
                    fibaro:call(tonumber(id),tostring(cmdStruct["cmd"]),tostring(cmdStruct["arg1"]),tostring(cmdStruct["arg2"]));
                elseif cmdStruct["cmd"] ~= nil and cmdStruct["value"] ~= nil then
                    fibaro:call(tonumber(id),tostring(cmdStruct["cmd"]),tostring(cmdStruct["value"]));
                elseif cmdStruct["cmd"] ~= nil then
                    fibaro:call(tonumber(id),tostring(cmdStruct["cmd"]));
                else
                    fibaro:debug("ERROR: The HOUSEKEEPING structure is not well formed. Please check the one associated with time ".. tostring(time));
                    printHousekeeing();
                end;
            else
                -- in this case, the ID is a string, which means that it is a variable
                if cmdStruct["cmd"] ~= nil then
                    local value = tostring(cmdStruct["cmd"]);
                    fibaro:setGlobal(id,value);
                else
                    fibaro:debug("ERROR: The HOUSEKEEPING structure is not well formed. Please check the one associated with time ".. tostring(time));
                    printHousekeeing();
                end;
            end;

            -- Now remove the executed schedule
            parsedVariable[tostring(id)]  = nil;
        end;
    end;
    -- print and store the modified housekeeping scedule
    local outString = json.encode(parsedVariable);
    fibaro:debug("Setting Housekeeping tasks: "..outString);
    fibaro:setGlobal('HOUSEKEEPING',outString);
end;

--- A utility function that may be used for printing the current housekeeping schedule.
function printHousekeeing()
    debugTable(json.decode(tostring(fibaro:getGlobalValue("HOUSEKEEPING"))));
end;




