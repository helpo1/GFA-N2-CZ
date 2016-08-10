// *********************
// SPL_Blink (mud-freak)
// *********************

const int SPL_COST_BLINK     =   10; // Mana cost. Can be freely adjusted.
const int STEP_BLINK         =    3; // "Time" before creating aim vob. Kepp in synch with the invest ani duration.
const int SPL_BLINK_MAXDIST  = 1000; // Maximum distance (cm) to blink. Can be freely adjusted.
const int SPL_BLINK_OBJDIST  =   75; // Set by PFX radius. Do not touch.

INSTANCE Spell_Blink (C_Spell_Proto) {
    time_per_mana            = 50; // STEP_BLINK * time_per_mana + time_per_mana = ramp up time.
    damage_per_level         = 0;
    spelltype                = SPELL_NEUTRAL;
    canTurnDuringInvest      = 1; // Not working. For a hack see updateHeroYrot()
    targetCollectAlgo        = TARGET_COLLECT_FOCUS;
    targetCollectType        = TARGET_TYPE_ALL;
    //targetCollectRange       = 0;
    //targetCollectAzi         = 0;
    //targetCollectElev        = 0;
};

func void hookOnInvest() {
    var zCVob her; her = Hlp_GetNpc(hero);
    // If blink is not actually being invested
    if (Npc_GetActiveSpell(her) != SPL_Blink) { return; };
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    // Prepare vob variables
    var String vobname; vobname = ConCatStrings("BlinkObj_", IntToString(MEM_ReadInt(_@(her)+MEM_NpcID_Offset)));
    var int vobPtr; vobPtr = MEM_SearchVobByName(vobname);
    if (!vobPtr) { // Aim vob should not exist
        // Create and name aim vob
        vobPtr = MEM_Alloc(sizeof_zCVob);
        const int zCVob__zCVob = 6283744; //0x5FE1E0
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, vobname); // _zCObject_objectName
          // DEBUG: Give vob visual and collision
          const int zCVob__SetVisual = 6301312; //0x602680
          CALL_zStringPtrParam("NW_NATURE_BAUMSTUMPF_02_115P.3DS"); // Visual
          CALL__thiscall(vobPtr, zCVob__SetVisual);
        // Insert aim vob into world
        const int zCWorld__AddVobAsChild = 6440352; //0x6245A0
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };


    // Manually enable rotation around y-axis
    if (!aimModifier) { aimModifier = FLOATEINS; };
    updateHeroYrot(aimModifier); // Outsourced since it might be useful for other spells/weapons as well (free aim)

    // Set trace ray (start from caster and go along the outvector of the camera vob)
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = her.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_MAXDIST));
    pos[1] = her.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_MAXDIST));
    pos[2] = her.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_MAXDIST));

    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From caster to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_POLY_TEST_WATER | zTRACERAY_POLY_IGNORE_TRANSP))) {
        // Set new position to intersection (point where the trace ray made contact with a polygon)
        pos[0] = MEM_World.foundIntersection[0];
        pos[1] = MEM_World.foundIntersection[1];
        pos[2] = MEM_World.foundIntersection[2];
    } else {
        // If nothing is in the way, set new position to max distance
        pos[0] = addf(pos[0], pos[3]);
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
    // Substract OBJDIST to get away from intersection (do it also if there was no intersection, to make it smoother)
    pos[0] = subf(pos[0], mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_OBJDIST))); // Pos = pos - (dir * OBJDIS)
    pos[1] = subf(pos[1], mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_OBJDIST)));
    pos[2] = subf(pos[2], mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_OBJDIST)));

    // Update aim vob position (FX will tag along)
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    CALL_PtrParam(_@(pos));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);

    // Get distance for aim multiplier. For smoother aiming: slower in distance, faster in proximity
    var int dx; dx = subf(pos[0], her.trafoObjToWorld[ 3]);
    var int dy; dy = subf(pos[1], her.trafoObjToWorld[ 7]);
    var int dz; dz = subf(pos[2], her.trafoObjToWorld[11]);
    var int dist3d; dist3d = sqrtf(addf(addf(sqrf(dx), sqrf(dy)), sqrf(dz))); // Simply the euclidean distance
    aimModifier = subf(FLOATEINS, divf(dist3d, mkf(SPL_BLINK_MAXDIST*2))); // 1 - (dist * (maxdist * 2))


    // Set focus vob
    const int oCNpc__SetFocusVob = 7547744; //0x732B60
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(her), oCNpc__SetFocusVob);
};



/* Frame function for invest loop. Updates aim vob by mouse movement
 *
 * The function does the following.
 * 1. Update mouse movement
 * 2. Retrieve (or create) aim vob
 * 3. Shoot trace ray from caster along the camera axis
 * 4. Position aim vob at end (intersection) of trace ray
 * 5. Get distance to aim vob for mouse movement multiplier
 */
var int spnum;
func void Spell_Invest_Blink(var int casterId) {
    var zCVob caster; caster = Hlp_GetNpc(casterId);
    if (Npc_GetActiveSpell(caster) != SPL_Blink) { // If blink is not actually being casted
        if (FF_Active(Spell_Invest_Blink)) { FF_RemoveData(Spell_Invest_Blink, casterId); };
        return;
    };
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    // The line below retrieves self.id by address. I was too lazy to store 'self' just for this
    var String vobname; vobname = ConCatStrings("BlinkObj_", IntToString(MEM_ReadInt(_@(caster)+MEM_NpcID_Offset)));
    var int vobPtr; vobPtr = MEM_SearchVobByName(vobname);



        var int nVPtr;
        const int oCNpc__GetFocusVob = 7547824; //0x732BB0


    if (!vobPtr) { // Aim vob should not exist
        // Create and name aim vob
        vobPtr = MEM_Alloc(sizeof_zCVob);
        const int zCVob__zCVob = 6283744; //0x5FE1E0
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, vobname); // _zCObject_objectName
          // DEBUG: Give vob visual and collision
          const int zCVob__SetVisual = 6301312; //0x602680
          CALL_zStringPtrParam("NW_NATURE_BAUMSTUMPF_02_115P.3DS"); // Visual
          CALL__thiscall(vobPtr, zCVob__SetVisual);
        // Insert aim vob into world
        const int zCWorld__AddVobAsChild = 6440352; //0x6245A0
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
        // Set vob as focus vob (for target FX)
        // MEM_WriteInt(_@(caster)+2476, vobPtr);


/*        CALL__thiscall(_@(caster), oCNpc__GetFocusVob);
        nVPtr = CALL_RetValAsPtr();
        MEM_Info(ConCatStrings("### vob pointer: ", IntToString(nVPtr)));
        MEM_Info(ConCatStrings("### vob name: ", MEM_ReadString(nVPtr+16)));

        const int oCNpc__SetFocusVob = 7547744; //0x732B60
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(caster), oCNpc__SetFocusVob);*/

        CALL__thiscall(_@(caster), oCNpc__GetFocusVob);
        nVPtr = CALL_RetValAsPtr();
        MEM_Info(ConCatStrings("### vob pointer: ", IntToString(nVPtr)));
        MEM_Info(ConCatStrings("### vob name: ", MEM_ReadString(nVPtr+16)));


        // Get oCSpell


        // WORKING BLOCK
/*        const int oCNpc__GetSpellBook = 7596544; //0x73EA00
        CALL__thiscall(_@(caster), oCNpc__GetSpellBook);
        var int mbok; mbok = CALL_RetValAsPtr();

        const int oCMag_Book__GetSelectedSpell = 4683648; //0x477780
        CALL__thiscall(mbok, oCMag_Book__GetSelectedSpell);
        var int spellPtr; spellPtr = CALL_RetValAsPtr();

        MEM_Info(ConCatStrings("### spellPtr: ", IntToString(spellPtr)));

        const int oCSpell__GetSpellID = 4744320; //0x486480
        CALL__thiscall(spellPtr, oCSpell__GetSpellID);
        var int splname; splname = CALL_RetValAsPtr();
        MEM_Info(ConCatStrings("### splname: ", IntToString(splname)));

        var oCNpc dumhlp; dumhlp = Hlp_GetNpc(DMT_1299_OberDementor_DI);

        const int oCSpell__Setup = 4737328; //0x484930
        CALL_IntParam(SPL_Blink);
        CALL_PtrParam(_@(dumhlp));
        CALL_PtrParam(_@(caster));
        CALL__thiscall(spellPtr, oCSpell__Setup);
*/




/*      // Only valid for current focus
        const int oCSpell__IsValidTarget = 4743632; //0x4861D0
        MEM_Info(ConCatStrings("### dumhlp: ", dumhlp.name));
        MEM_Info(ConCatStrings("### other: ", other.name));
        CALL_PtrParam(_@(dumhlp));
        CALL__thiscall(spellPtr, oCSpell__IsValidTarget);
        var int valVob; valVob = CALL_RetValAsInt();
        MEM_Info(ConCatStrings("### valid vob: ", IntToString(valVob)));
*/
/*        const int oCSpell__GetVob = 4744304; //0x486470 == ZS_Righthand
        MEM_Info("### thiscall getvob");
        CALL__thiscall(spellPtr, oCSpell__GetVob);
        var int nVPtr; nVPtr = CALL_RetValAsPtr();
        MEM_Info(ConCatStrings("### GetVob name: ", MEM_ReadString(nVPtr+16)));

        //var zCVob spellVob; spellVob = _^(nVPtr);
        CALL_zStringPtrParam("NW_NATURE_BAUMSTUMPF_02_115P.3DS"); // Visual
        CALL__thiscall(nVPtr, zCVob__SetVisual);*/
    };

    // Manually enable rotation around y-axis
    if (!aimModifier) { aimModifier = FLOATEINS; };
    updateHeroYrot(aimModifier); // Outsourced since it might be useful for other spells/weapons as well (free aim)

    // Set trace ray (start from caster and go along the outvector of the camera vob)
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = caster.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_MAXDIST));
    pos[1] = caster.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_MAXDIST));
    pos[2] = caster.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_MAXDIST));

    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From caster to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_POLY_TEST_WATER | zTRACERAY_POLY_IGNORE_TRANSP))) {
        // Set new position to intersection (point where the trace ray made contact with a polygon)
        pos[0] = MEM_World.foundIntersection[0];
        pos[1] = MEM_World.foundIntersection[1];
        pos[2] = MEM_World.foundIntersection[2];
    } else {
        // If nothing is in the way, set new position to max distance
        pos[0] = addf(pos[0], pos[3]);
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
    // Substract OBJDIST to get away from intersection (do it also if there was no intersection, to make it smoother)
    pos[0] = subf(pos[0], mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_OBJDIST))); // Pos = pos - (dir * OBJDIS)
    pos[1] = subf(pos[1], mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_OBJDIST)));
    pos[2] = subf(pos[2], mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_OBJDIST)));

    // Update aim vob position (FX will tag along)
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    CALL_PtrParam(_@(pos));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);

    // Get distance for aim multiplier. For smoother aiming: slower in distance, faster in proximity
    var int dx; dx = subf(pos[0], caster.trafoObjToWorld[ 3]);
    var int dy; dy = subf(pos[1], caster.trafoObjToWorld[ 7]);
    var int dz; dz = subf(pos[2], caster.trafoObjToWorld[11]);
    var int dist3d; dist3d = sqrtf(addf(addf(sqrf(dx), sqrf(dy)), sqrf(dz))); // Simply the euclidean distance
    aimModifier = subf(FLOATEINS, divf(dist3d, mkf(SPL_BLINK_MAXDIST*2))); // 1 - (dist * (maxdist * 2))
};

func int Spell_Logic_Blink(var int manaInvested) {
    // Not enough mana; only hero is allowed to use this spell
    if (self.attribute[ATR_MANA] < STEP_BLINK) || (!Npc_IsPlayer(self)) { return SPL_DONTINVEST; };

    // Three levels: Build up spell, create aim vob, start passive invest loop
    if (manaInvested <= STEP_BLINK*1) {
        self.aivar[AIV_SpellLevel] = 0; // Start with lvl 0
        // Small fix in case a vob is caught in focus (happens rarely when switching between spells very fast)
       /* var oCNPC caster; caster = Hlp_GetNpc(self);
        const int oCNpc__ClearFocusVob = 7547840; //0x732BC0
        CALL__thiscall(_@(caster), oCNpc__ClearFocusVob);*/ // TEMPORARY
        return SPL_STATUS_CANINVEST_NO_MANADEC;
    } else if (manaInvested > (STEP_BLINK*1)) && (self.aivar[AIV_SpellLevel] <= 0) {
        // Start frame function
        //if (FF_Active(Spell_Invest_Blink)) { FF_RemoveData(Spell_Invest_Blink, Hlp_GetInstanceID(self)); };
        //FF_ApplyExtData(Spell_Invest_Blink, 0, -1, Hlp_GetInstanceID(self));
        self.aivar[AIV_SpellLevel] = 1;
        return SPL_NEXTLEVEL; // Do not go to level two yet, because we need to be sure the vob is created first!
    } else if (manaInvested > (STEP_BLINK*2)) && (self.aivar[AIV_SpellLevel] <= 1) {
        self.aivar[AIV_SpellLevel] = 2;
        return SPL_NEXTLEVEL; // Now we are ready to got to level 2 (meaning from here on the spell is "armed")
    } else if (manaInvested > (STEP_BLINK*5)) && (self.aivar[AIV_SpellLevel] <= 2) {
        self.aivar[AIV_SpellLevel] = 3;
        return SPL_NEXTLEVEL; // TESTING
    };

    // Aiming does not cost mana
    return SPL_STATUS_CANINVEST_NO_MANADEC;
};

func void Spell_Cast_Blink(var int spellLevel) {
    // Remove FF and aim FX
    if (FF_Active(Spell_Invest_Blink)) { FF_RemoveData(Spell_Invest_Blink, Hlp_GetInstanceID(self)); };

    // Spell was aborted by caster before it started (ramp up not finished)
    if (spellLevel < 2) { return; };

    // Retrieve position from aim vob
    var int vobPtr; vobPtr = MEM_SearchVobByName(ConCatStrings("BlinkObj_", IntToString(self.id)));
    if (!vobPtr) {
        // MEM_Error("Blink: Failed to retrieve destination (aim vob)"); // Don't break immersion
        AI_PlayAni(self, "T_CASTFAIL"); // Much nicer
        Wld_PlayEffect("SPELLFX_BLINK_FAIL", self, self, 0, 0, 0, FALSE);
        MEM_Warn("Blink: Failed to retrieve destination (aim vob)");
        return;
    };
    var zCVob vob; vob = _^(vobPtr);
    var zCVob caster; caster = Hlp_GetNpc(self);
    var int pos[6]; // Combined pos[3] and dir[3]
    pos[0] = vob.trafoObjToWorld[ 3];   pos[3] = caster.trafoObjToWorld[ 2];
    pos[1] = vob.trafoObjToWorld[ 7];   pos[4] = caster.trafoObjToWorld[ 6];
    pos[2] = vob.trafoObjToWorld[11];   pos[5] = caster.trafoObjToWorld[10];

    // Delete aim vob from world
    const int zCWorld__RemoveVob = 6441840; //0x624B70
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), zCWorld__RemoveVob);
    vobPtr = 0; // Don't free vobPtr. Seems to be done in zCWorld::RemoveVob

    // Check if destination wp already (from last cast) exists
    const int zCWayNet__GetWaypoint = 8061744; //0x7B0330
    CALL__fastcall(_@(MEM_Waynet), _@s(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id))), zCWayNet__GetWaypoint);
    var int wpPtr; wpPtr = CALL_RetValAsInt();
    if (wpPtr) { // Delete old wp first
        const int zCWayNet__DeleteWaypoint = 8049328; //0x7AD2B0
        CALL_PtrParam(wpPtr);
        CALL__thiscall(_@(MEM_Waynet), zCWayNet__DeleteWaypoint);
    };

    // Create wp
    wpPtr = MEM_Alloc(124); // sizeof_zCWaypoint
    const int zCWaypoint__zCWaypoint = 8058736; //0x7AF770
    CALL__thiscall(wpPtr, zCWaypoint__zCWaypoint);
    // Set position and name wp (position needs to before adding it to the waynet)
    MEM_CopyWords(_@(pos), wpPtr+68, 6);
    const int zCWaypoint__SetName = 8059824; //0x7AFBB0
    CALL_zStringPtrParam(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    CALL__thiscall(wpPtr, zCWaypoint__SetName);
    // Insert wp into waynet
    const int zCWayNet__InsertWaypoint = 8048896; //0x7AD100
    CALL_PtrParam(wpPtr);
    CALL__thiscall(_@(MEM_Waynet), zCWayNet__InsertWaypoint);

    // Decrease mana (the usual)
    self.attribute[ATR_MANA] -= SPL_COST_BLINK;
    if (self.attribute[ATR_MANA] < 0) { self.attribute[ATR_MANA] = 0; };
    self.aivar[AIV_SelectSpell] += 1; // Since NPCs can't use this spell. This is just for completeness

    // Teleport to wp
    AI_Teleport(self, ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    // AI_PlayAni(self, "T_HEASHOOT_2_STAND"); // Not working here. AI_Teleport clears EM (AI queue)
};
