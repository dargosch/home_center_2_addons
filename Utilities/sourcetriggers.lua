--- Functions that deal with triggered events.
-- The idea of these functions is that they encapsulate the Fibaro library functions and other structures into functions that work well when applied in boolean logic sequences.
-- @section triggers


--- A function that tests whether the scene was started manually
-- @treturn boolean A truth value (true /false)

function startedManually ()
    local startSource = fibaro:getSourceTrigger();
    return( startSource["type"] == "other");
end;

--- A function that tests whether the scene was started by a change in a global variable
-- @treturn string If started by a global variable, the name of the variable is returned.
-- @treturn boolean If started by something else, 'false' is returned.


function startedByVariable ()
    local startSource = fibaro:getSourceTrigger();
    if startSource["type"] == "global" then
        return (startSource["name"]);
    else
        return false;
    end;
end;

--- A function that tests whether the scene was started by a change in the state or property of a device.
-- @treturn table A table containting two fields:
--  'deviceID', indicating the ID of the triggering device
--  'propertyName' the property of the device that changed, causing the scene to trigger.
-- @treturn boolean A truth value (true /false).
function startedByDevice ()
    local startSource = fibaro:getSourceTrigger();
    -- startSource ={type="property",deviceID="11",propertyName="tet"}
    if startSource["type"] == "property" then
        return ({deviceID=startSource["deviceID"], propertyName=startSource["propertyName"]});
    else
        return false;
    end;
end;

--- A function that tests whether the scene is currently running.
-- Please note that the testing is stated in the negative. What is tested is whether the scene is NOT
-- running, as this is the most probable use case.
-- @treturn boolean A truth value (true /false).
function sceneNotCurrentlyRunning()
    local sceneCount = tonumber(fibaro:countScenes());
    return (sceneCount == 1);
end;

--- A function that checks that a device is drawing power, if on
-- The use case for this function is for instance a car heater. If it is turned on, it should draw power.
-- If not, it is unplugged. Of course, this function requires a device that has power reporting.
-- @tparam number id The ID of the device.
-- @tparam number threshold The power consumption threshold. If the power consumption is above this value, it is regarded to draw power. Defaults to 15W.
-- @treturn number A boolean indicating wheter the device is ON but not active (not plugged in)
function onButUnplugged(id,threshold)
    local t = threshold or 15;
    local state = tonumber(fibaro:getValue(id, "value"));
    local pow = tonumber(fibaro:getValue(id, "power"));

    return(state == 1 and pow > t);
end;

--- A function which transforms a sceneActivation to a boolean value.
-- The idea is that the scene developer could just specify what kind of keypress should be tested for. The function then takes a scene controller specific table
-- in which available key presses and a description of them is stored.
-- @tparam number id The ID of the scene controller sending sceneActivation commands.
-- @tparam string descriptionstring A textual description of the event to look for.
-- @tparam table descriptiontable A scene controller specific table of available codes and textual descriptions.
-- @see nodonSceneTable
-- @see nodonSceneTableVerbose
-- @see zwavemeSceneTable
-- @see zwavemeSceneTableVerbose

function buttonPressed(id,descriptionstring,descriptiontable)
  local dtab = descriptiontable or nodonSceneTableVerbose;
  local inDesc = tostring(descriptionstring) ;
  local scene = tonumber(fibaro:getValue(id, "sceneActivation"));
  local desc = tostring(dtab[scene]);
  return(inDesc == desc);
end;

--- Scene controller specific tables of available key presses and sceneActivation codes.
-- @section sceneActivationTables

--- A table of mappings between NodOn remote scene codes and a text description.
-- @table nodonSceneTableVerbose
-- @field 10 Button 1 Single Press
-- @field 20 Button 2 Single Press
-- @field 30 Button 3 Single Press
-- @field 40 Button 4 Single Press
-- @field 13 Button 1 Double Press
-- @field 23 Button 2 Double Press
-- @field 33 Button 3 Double Press
-- @field 43 Button 4 Double Press
-- @field 12 Button 1 Hold Press
-- @field 22 Button 2 Hold Press
-- @field 32 Button 3 Hold Press
-- @field 42 Button 4 Hold Press
-- @field 11 Button 1 Hold Released
-- @field 21 Button 2 Hold Released
-- @field 31 Button 3 Hold Released
-- @field 41 Button 4 Hold Released
-- @see buttonPressed
-- @within sceneActivationTables
nodonSceneTableVerbose = {
    [10]="Button 1 Single Press",
    [20]="Button 2 Single Press",
    [30]="Button 3 Single Press",
    [40]="Button 4 Single Press",
    [13]="Button 1 Double Press",
    [23]="Button 2 Double Press",
    [33]="Button 3 Double Press",
    [43]="Button 4 Double Press",
    [12]="Button 1 Hold Press",
    [22]="Button 2 Hold Press",
    [32]="Button 3 Hold Press",
    [42]="Button 4 Hold Press",
    [11]="Button 1 Hold Released",
    [21]="Button 2 Hold Released",
    [31]="Button 3 Hold Released",
    [41]="Button 4 Hold Released"
};

--- Compressed table for mappings between scene codes and NodOn button pressed, and manner in which it was pressed.
-- In the short forms stored, the 'SP' indicates a single press, 'DP' a double press. 'HP' indicates that the button is pressed and held, and 'HR' that it is released.
-- @table nodonSceneTable
-- @field 10 (1SP) Button 1 Single Press
-- @field 20 (2SP) Button 2 Single Press
-- @field 30 (3SP) Button 3 Single Press
-- @field 40 (4SP) Button 4 Single Press
-- @field 13 (1DP) Button 1 Double Press
-- @field 23 (2DP) Button 2 Double Press
-- @field 33 (3DP) Button 3 Double Press
-- @field 43 (4DP) Button 4 Double Press
-- @field 12 (1HP) Button 1 Hold Press
-- @field 22 (2HP) Button 2 Hold Press
-- @field 32 (3HP) Button 3 Hold Press
-- @field 42 (4HP) Button 4 Hold Press
-- @field 11 (1HR) Button 1 Hold Released
-- @field 21 (2HR) Button 2 Hold Released
-- @field 31 (3HR) Button 3 Hold Released
-- @field 41 (4HR) Button 4 Hold Released
-- @see buttonPressed
nodonSceneTable = {
    [10]="1SP",
    [20]="2SP",
    [30]="3SP",
    [40]="4SP",
    [13]="1DP",
    [23]="2DP",
    [33]="3DP",
    [43]="4DP",
    [12]="1HP",
    [22]="2HP",
    [32]="3HP",
    [42]="4HP",
    [11]="1HR",
    [21]="2HR",
    [31]="3HR",
    [41]="4HR"
};

--- A table for Zwave.me wall controller (actually keyfob) scene codes.
-- @table zwavemeSceneTableVerbose
-- @field 11 Button 1 Single Click
-- @field 21 Button 2 Single Click
-- @field 31 Button 3 Single Click
-- @field 41 Button 4 Single Click
-- @field 12 Button 1 Double Click
-- @field 22 Button 2 Double Click
-- @field 32 Button 3 Double Click
-- @field 42 Button 4 Double Click
-- @field 13 Button 1 Press and hold
-- @field 23 Button 2 Press and hold
-- @field 33 Button 3 Press and hold
-- @field 43 Button 4 Press and hold
-- @field 14 Button 1 Click and then Press and hold
-- @field 24 Button 2 Click and then Press and hold
-- @field 34 Button 3 Click and then Press and hold
-- @field 44 Button 4 Click and then Press and hold
-- @field 15 Button 1 Click and then Press and hold
-- @field 25 Button 2 Click and then Press and hold
-- @field 35 Button 3 Click and then Press and hold
-- @field 45 Button 4 Click and then Press and hold
-- @field 16 Button 1 Click and then Press and hold
-- @field 26 Button 2 Click and then Press and hold
-- @field 36 Button 3 Click and then Press and hold
-- @field 46 Button 4 Click and then Press and hold
-- @see buttonPressed
zwavemeSceneTableVerbose = {
    [11]="Button 1 Single Click",
    [21]="Button 2 Single Click",
    [31]="Button 3 Single Click",
    [41]="Button 4 Single Click",
    [12]="Button 1 Double Click",
    [22]="Button 2 Double Click",
    [32]="Button 3 Double Click",
    [42]="Button 4 Double Click",
    [13]="Button 1 Press and hold",
    [23]="Button 2 Press and hold",
    [33]="Button 3 Press and hold",
    [43]="Button 4 Press and hold",
    [14]="Button 1 Click and then Press and hold",
    [24]="Button 2 Click and then Press and hold",
    [34]="Button 3 Click and then Press and hold",
    [44]="Button 4 Click and then Press and hold",
    [15]="Button 1 Click and then Press and hold",
    [25]="Button 2 Click and then Press and hold",
    [35]="Button 3 Click and then Press and hold",
    [45]="Button 4 Click and then Press and hold",
    [16]="Button 1 Click and then Press and hold long time",
    [26]="Button 2 Click and then Press and hold long time",
    [36]="Button 3 Click and then Press and hold long time",
    [46]="Button 4 Click and then Press and hold long time"
};



--- Compressed table for mappings between scene codes and Zwave.me button pressed, and manner in which it was pressed.
-- In the short forms stored, the 'SC' indicates a single click, 'DC' a double click. 'PH' indicates that the button is pressed and held. In cases when two actions are performed, like in the case of a click followed by a press that is held, then the two actions are separated by a '_' in the code.
-- @table zwavemeSceneTable
-- @field 11 (1SC) Button 1 Single Click
-- @field 21 (2SC) Button 2 Single Click
-- @field 31 (3SC) Button 3 Single Click
-- @field 41 (4SC) Button 4 Single Click
-- @field 12 (1DC) Button 1 Double Click
-- @field 22 (2DC) Button 2 Double Click
-- @field 32 (3DC) Button 3 Double Click
-- @field 42 (4DC) Button 4 Double Click
-- @field 13 (1PH) Button 1 Press and hold
-- @field 23 (2PH) Button 2 Press and hold
-- @field 33 (3PH) Button 3 Press and hold
-- @field 43 (4PH) Button 4 Press and hold
-- @field 14 (1C_PH) Button 1 Click and then Press and hold
-- @field 24 (2C_PH) Button 2 Click and then Press and hold
-- @field 34 (3C_PH) Button 3 Click and then Press and hold
-- @field 44 (4C_PH) Button 4 Click and then Press and hold
-- @field 15 (1PLH) Button 1 Click and then Press and hold
-- @field 25 (2PLH) Button 2 Click and then Press and hold
-- @field 35 (3PLH) Button 3 Click and then Press and hold
-- @field 45 (4PLH) Button 4 Click and then Press and hold
-- @field 16 (1C_PLH) Button 1 Click and then Press and hold
-- @field 26 (1C_PLH) Button 2 Click and then Press and hold
-- @field 36 (1C_PLH) Button 3 Click and then Press and hold
-- @field 46 (1C_PLH) Button 4 Click and then Press and hold
-- @see buttonPressed
zwavemeSceneTable = {
    [11]="1SC",
    [21]="2SC",
    [31]="3SC",
    [41]="4SC",
    [12]="1DC",
    [22]="2DC",
    [32]="3DC",
    [42]="4DC",
    [13]="1PH",
    [23]="2PH",
    [33]="3PH",
    [43]="4PH",
    [14]="1C_PH",
    [24]="2C_PH",
    [34]="3C_PH",
    [44]="4C_PH",
    [15]="1PLH",
    [25]="2PLH",
    [35]="3PLH",
    [45]="4PLH",
    [16]="1C_PLH",
    [26]="1C_PLH",
    [36]="1C_PLH",
    [46]="1C_PLH"
};


