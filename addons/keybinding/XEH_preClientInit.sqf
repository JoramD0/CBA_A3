#include "script_component.hpp"
SCRIPT(XEH_preInit);

ADDON = false;

// Load DIK to string conversion table.
call COMPILE_FILE(dikDecToString);

// Prepare GUI functions and variables.
PREP_SUB(gui,onButtonClick);
PREP_SUB(gui,onComboChanged);
PREP_SUB(gui,onKeyDown);
PREP_SUB(gui,onLBDblClick);
PREP_SUB(gui,updateGUI);

GVAR(input) = [];
GVAR(waitingForInput) = false;

/////////////////////////////////////////////////////////////////////////////////

// All keybinds are stored as an array in this format:
// keybind = [DIKcode, shift?, ctrl?, alt?]
//
// example: [15, true, false, false]

// Permament array that tracks all key configs registered by fnc_registerKeybindHandler.
// Format: Associative array. Access with bis_fnc_getFromPairs.
// [
//   ["modName1", [
//                  ["actionName1", keybind],
//                  ["actionName2", keybind],
//                  ["actionName3", keybind]
//                ],
//   ],
//   ["modName2", [
//                  ["actionName1", keybind],
//                  ["actionName2", keybind],
//                  ["actionName3", keybind]
//                ],
//   ]
// ]
profileNamespace setVariable [QGVAR(registry), []];

// Temporary array that tracks loaded key handlers for specified keybinds.
// Format: Array of arrays
//      [["modName", "actionName", keybind, "functionName", "ehID"]]
GVAR(handlers) = [];

// Counter for indexing added key handlers.
GVAR(ehCounter) = 512;

/////////////////////////////////////////////////////////////////////////////////

// Announce initialization complete
ADDON = true;