/*
 * Constants
 *
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * <http://github.com/szapp/g2freeAim>
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License
 * along with G2 Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * Free aim internal constants, do not modify! Change the settings in freeAim\config\settings.d
 */
const string FREEAIM_VERSION            = "G2 Free Aim v0.1.2"; // Do not change under any circumstances

const int    FREEAIM_DRAWTIME_READY     = 650;                  // Time (ms) for readying the bow. Fixed by animation
const int    FREEAIM_DRAWTIME_RELOAD    = 1110;                 // Time (ms) for reloading the bow. Fixed by animation

const int    FREEAIM_RETICLE_MIN_SIZE   = 32;                   // Smallest reticle size in pixels
const int    FREEAIM_RETICLE_MAX_SIZE   = 64;                   // Biggest reticle size in pixels

const string FREEAIM_TRAIL_FX           = "freeAim_TRAIL";      // Trailstrip FX. Should not be changed
const string FREEAIM_BREAK_FX           = "freeAim_DESTROY";    // FX of projectile breaking on impact with world

const int    FREEAIM_MAX_DIST           = 5000;                 // 50m. Shooting/reticle adjustments. Do not change

const float  FREEAIM_SCATTER_HIT        = 2.6;                  // (Visual angle)/2 within which everything is a hit
const float  FREEAIM_SCATTER_MISS       = 3.3;                  // (Visual angle)/2 outside which everything is a miss
const float  FREEAIM_SCATTER_MAX        = 5.0;                  // (Visual angle)/2 of maximum scatter (all in degrees)

const int    FLOAT1C                    = 1120403456;           // 100 as float
const int    FLOAT3C                    = 1133903872;           // 300 as float
const int    FLOAT1K                    = 1148846080;           // 1000 as float

const int    FREEAIM_ACTIVE             = 0;                    // Internal. Do not change
const int    FREEAIM_FOCUS_COLLECTION   = 1;                    // Internal. Do not change (change in ini-file)

var   int    freeAimRayInterval;                                // Perform trace ray every x ms (change in ini-file)
var   int    freeAimRayPrevCalcTime;                            // Time of last trace ray calculation
var   int    freeAimDebugWSBBox[6];                             // Weaksopt boundingbox for debug visualization
var   int    freeAimDebugWSTrj[6];                              // Projectile trajectory for debug visualization
var   int    freeAimDebugTRBBox[6];                             // Trace ray intersection for debug visualization
var   int    freeAimDebugTRTrj[6];                              // Trace ray trajectory for debug visualization
var   int    freeAimDebugTRPrevVob;                             // Trace ray detected vob bbox pointer for debugging
var   int    freeAimReticleHndl;                                // Holds the handle of the reticle
var   int    freeAimBowDrawOnset;                               // Time onset of drawing the bow
var   int    freeAimRecoil;                                     // Amount of vertical mouse manipulation
