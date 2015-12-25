/* ----------------------------------------------------------------------------
Function: CBA_fnc_preInit

Description:
    Occurs once per mission before objects are initialized.
    Internal use only.

Parameters:
    None

Returns:
    None

Author:
    commy2
---------------------------------------------------------------------------- */
#include "script_component.hpp"

SLX_XEH_DisableLogging = uiNamespace getVariable ["SLX_XEH_DisableLogging", false]; // get from preStart

XEH_LOG("XEH: PreInit started. v" + getText (configFile >> "CfgPatches" >> "cba_common" >> "version") + ". " + PFORMAT_7("MISSIONINIT",missionName,worldName,isMultiplayer,isServer,isDedicated,hasInterface,didJIP));

SLX_XEH_STR = ""; // does nothing, never changes, backwards compatibility
SLX_XEH_COMPILE = compileFinal "compile preprocessFileLineNumbers _this"; //backwards comps
SLX_XEH_COMPILE_NEW = CBA_fnc_compileFunction; //backwards comp
SLX_XEH_DUMMY = "Logic"; // backwards comp
SLX_XEH_EH_Init = CBA_fnc_initObject; // backwards compatibility, this is frequently used in init event handlers in configs

SLX_XEH_MACHINE = [ // backwards compatibility, deprecated
    !isDedicated, // 0 - isClient (and thus has player)
    didJIP, // 1 - isJip
    !isServer, // 2 - isDedicatedClient (and thus not a Client-Server)
    isServer, // 3 - isServer
    isDedicated, // 4 - isDedicatedServer (and thus not a Client-Server)
    false, // 5 - Player Check finished, no longer works
    !isMultiplayer, // 6 - isSingleplayer
    false, // 7 - PreInit passed
    false, // 8 - PostInit passed
    isMultiplayer, // 9 - Multiplayer && respawn
    if (isDedicated) then { 0 } else { if (isServer) then { 1 } else { 2 } }, // 10 - Machine type (only 3 possible configurations)
    0, // 11 - SESSION_ID
    0, // 12 - LEVEL - Used for version determination
    false, // 13 - TIMEOUT - PostInit timedOut, always false
    productVersion, // 14 - Game
    3 // 15 - Product+Version, always Arma 3
];

PREP(getInMan);
PREP(getOutMan);
PREP(startFallbackLoop);

// make case insensitive list of all supported events
GVAR(EventsLowercase) = [];
{
    GVAR(EventsLowercase) pushBack toLower _x;
} forEach [XEH_EVENTS];

// generate list of incompatible classes
{
    private _class = configFile >> "CfgVehicles" >> _x;

    while {isClass _class} do {
        SETINCOMP(configName _class);

        _class = inheritsFrom _class;
    };
} forEach ([false, false, true] call CBA_fnc_supportMonitor);

// recompile extended event handlers when enabled
if (call CBA_fnc_isRecompileEnabled) then {
    GVAR(allEventHandlers) = configFile call CBA_fnc_compileEventHandlers; // from addon config
} else {
    GVAR(allEventHandlers) = call (uiNamespace getVariable QGVAR(fnc_getAllEventHandlers));
};

GVAR(allEventHandlers) append (missionConfigFile call CBA_fnc_compileEventHandlers); // from mission config
GVAR(allEventHandlers) append (campaignConfigFile call CBA_fnc_compileEventHandlers); // from campaign config

// add extended event handlers to classes
GVAR(fallbackRunning) = false;

// call PreInit events and add event handlers to object classes
{
    if (_x select 0 == "") then {
        if (_x select 1 == "preInit") then {
            call (_x select 2);
        };
    } else {
        _x params ["_className", "_eventName", "_eventFunc", "_allowInheritance", "_excludedClasses"];

        // backwards comp, args in _this are already switched
        if (_eventName == "firedBis") then {
            _eventName = "fired";
        };

        private _success = [_className, _eventName, _eventFunc, _allowInheritance, _excludedClasses] call CBA_fnc_addClassEventHandler;

        #ifdef DEBUG_MODE_FULL
            diag_log text format ["%1:%2=%3", _className, _eventName, _success];
        #endif
    };
} forEach GVAR(allEventHandlers);

GVAR(InitPostStack) = [];

#ifdef DEBUG_MODE_FULL
    diag_log text format ["isSheduled = %1", call CBA_fnc_isSheduled];
#endif

SLX_XEH_MACHINE set [7, true]; // PreInit passed

XEH_LOG("XEH: PreInit finished.");
