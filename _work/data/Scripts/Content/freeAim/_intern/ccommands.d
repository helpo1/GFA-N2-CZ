/*
 * Definition of all console commands
 *
 * Gothic Free Aim (GFA) v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
 *
 * This file is part of Gothic Free Aim.
 * <http://github.com/szapp/GothicFreeAim>
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * Gothic Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License along with
 * Gothic Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * Console function to enable/disable weak spot debug output. This function is registered as console command.
 * When enabled, the trajectory of the projectile and the defined weak spot of the last shot NPC is visualized with
 * bounding boxes and lines.
 */
func string GFA_DebugWeakspot(var string command) {
    GFA_DEBUG_WEAKSPOT = !GFA_DEBUG_WEAKSPOT;
    if (GFA_DEBUG_WEAKSPOT) {
        return "Debug weak spot on.";
    } else {
        return "Debug weak spot off.";
    };
};


/*
 * Console function to enable/disable trace ray debug output. This function is registered as console command.
 * When enabled, the trace ray is continuously drawn, as well as the intersection of it.
 */
func string GFA_DebugTraceRay(var string command) {
    GFA_DEBUG_TRACERAY = !GFA_DEBUG_TRACERAY;
    if (GFA_DEBUG_TRACERAY) {
        return "Debug trace ray on.";
    } else {
        return "Debug trace ray off.";
    };
};


/*
 * Console function to show GFA version. This function is registered as console command.
 * When entered in the console, the current GFA version is displayed as the console output.
 */
func string GFA_GetVersion(var string command) {
    return GFA_VERSION;
};


/*
 * Console function to show GFA license. This function is registered as console command.
 * When entered in the console, the GFA license information is displayed as the console output.
 */
func string GFA_GetLicense(var string command) {
    var int s; s = SB_New();
    SB(GFA_VERSION);
    SB(", Copyright ");
    SBc(169 /* (C) */);
    SB(" 2016-2017  mud-freak (@szapp)");
    SBc(13); SBc(10);

    SB("<http://github.com/szapp/GothicFreeAim>");
    SBc(13); SBc(10);

    SB("Released under the MIT License.");
    SBc(13); SBc(10);

    SB("For more details see <http://opensource.org/licenses/MIT>.");
    SBc(13); SBc(10);

    var string ret; ret = SB_ToString();
    SB_Destroy();

    return ret;
};


/*
 * Console function to show GFA info. This function is registered as console command.
 * When entered in the console, the GFA config is displayed as the console output.
 */
func string GFA_GetInfo(var string command) {
    const string onOff[2] = {"OFF", "ON"};

    var int s; s = SB_New();
    SB(GFA_VERSION);
    SBc(13); SBc(10);

    SB("Free aiming: ");
    SB(MEM_ReadStatStringArr(onOff, GFA_ACTIVE));
    if (GFA_ACTIVE) {
        SB(" for");
        if (GFA_RANGED) {
            SB(" (ranged)");
        };
        if (GFA_SPELLS) {
            SB(" (spells)");
        };

        SB(". Focus update every ");
        SBi(GFA_AimRayInterval);
        SB(" ms");
    };
    SBc(13); SBc(10);

    SB("Reusable projectiles: ");
    SB(MEM_ReadStatStringArr(onOff, GFA_REUSE_PROJECTILES));
    SBc(13); SBc(10);

    SB("Custom collision behaviors: ");
    SB(MEM_ReadStatStringArr(onOff, GFA_CUSTOM_COLLISIONS));
    SBc(13); SBc(10);

    SB("Criticial hit detection: ");
    SB(MEM_ReadStatStringArr(onOff, GFA_CRITICALHITS));
    SBc(13); SBc(10);

    var string ret; ret = SB_ToString();
    SB_Destroy();

    return ret;
};
