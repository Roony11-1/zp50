/*
[ZP] Extra Item: Golden MP5 NAVY
Team: Humans
*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <zp50_core>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_stocks>
#include <zp50_items>
#include <xs>

#define is_valid_player(%1) (1 <= %1 <= 32)

const ENG_NULLENT = 		-1
const EV_INT_WEAPONKEY = 	EV_INT_impulse
const ANTIDOTEGUN_WPNKEY = 	666
new const g_GMP5Ent[] = "weapon_mp5navy"

new gmp5_V_MODEL[64] = "models/zombie_plague/v_g_mp5.mdl"
new gmp5_P_MODEL[64] = "models/zombie_plague/p_g_mp5.mdl"
new gmp5_W_MODEL[64] = "models/w_mp5.mdl"

new mp5_W_MODEL[64] = "models/w_mp5.mdl"


/* Pcvars */
new Float:cvar_dmgmultiplier

// Item ID
new g_itemid

new bool:g_Hasmp5navy[33]; // para jugadores 1 a 32

// Sprite
new m_spriteTexture

const Wep_mp5navy = ((1<<CSW_MP5NAVY))

public plugin_init()
{
    /* CVARS */
    cvar_dmgmultiplier = register_cvar("zp_gmp5_dmg_multiplier", "1.5");

    register_forward(FM_SetModel, "fw_SetModel");

    // Register The Plugin
    register_plugin("[ZP] Extra: Golden MP5", "1.1", "Wisam187");

    // Register Zombie Plague extra item
    g_itemid = zp_items_register("Golden MP5", 0);

    // Weapon Pick Up
    register_event("WeapPickup", "checkModel", "b", "1=19");

    // Current Weapon Event
    register_event("CurWeapon", "checkWeapon", "be", "1=1");

    // Ham TakeDamage
    RegisterHam(Ham_Item_AddToPlayer, g_GMP5Ent, "fw_gMp5_AddToPlayer");
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack");
}

public plugin_natives()
{
    register_library("zp_extra_Golden_MP5")
    register_native("zp_mp5_user_get", "native_mp5_user_get")
}

public client_connect(id)
{
    g_Hasmp5navy[id] = false;
}

public client_disconnected(id)
{
    g_Hasmp5navy[id] = false;
}

public plugin_precache()
{
    precache_model(gmp5_V_MODEL);
    precache_model(gmp5_P_MODEL);
    precache_model(gmp5_W_MODEL);
    m_spriteTexture = precache_model("sprites/laserbeam.spr");
    precache_sound("weapons/zoom.wav");
}

public zp_fw_core_cure_post(id, attacker)
{
    if (!isSuperClass(id) && zp_class_survivor_strip_get(id))
    {
        g_Hasmp5navy[id] = false;
        zp_class_survivor_strip_unset(id);
    }

    if (isSuperClass(id))
        giveGMP5(id)
}

public checkModel(id)
{
    if (zp_core_is_zombie(id))
        return PLUGIN_HANDLED;

    if (get_user_weapon(id) == CSW_MP5NAVY && g_Hasmp5navy[id])
    {
        set_pev(id, pev_viewmodel2, gmp5_V_MODEL);
        set_pev(id, pev_weaponmodel2, gmp5_P_MODEL);
    }
    return PLUGIN_HANDLED;
}

public checkWeapon(id)
{
    if (get_user_weapon(id) == CSW_MP5NAVY && g_Hasmp5navy[id])
        checkModel(id);
    else 
        return PLUGIN_CONTINUE;

    return PLUGIN_HANDLED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if (is_valid_player(attacker) && get_user_weapon(attacker) == CSW_MP5NAVY && g_Hasmp5navy[attacker])
    {
        SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmultiplier));
    }
}

public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
    if (!(g_Hasmp5navy[Attacker] && (get_user_weapon(Attacker) == CSW_MP5NAVY)))
        return HAM_IGNORED;

    new vec2[3], Float:MyOrigin[3];
    get_user_origin(Attacker, vec2, 4); // termina; where your bullet goes (4 is cs-only)

    get_position(Attacker, 25.0, 7.5, -5.0, MyOrigin);

    // BEAMENTPOINTS
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(0);     // TE_BEAMENTPOINTS 0
    write_coord_f(MyOrigin[0]);
    write_coord_f(MyOrigin[1]);
    write_coord_f(MyOrigin[2]);
    write_coord(vec2[0]);
    write_coord(vec2[1]);
    write_coord(vec2[2]);
    write_short(m_spriteTexture);
    write_byte(1); // framestart
    write_byte(5); // framerate
    write_byte(1); // life
    write_byte(10); // width
    write_byte(0); // noise
    write_byte(255); // r
    write_byte(215); // g
    write_byte(0);   // b
    write_byte(255); // brightness
    write_byte(0);   // speed
    message_end();

    if (!isSuperClass(Attacker))
    {
        new origin[3]
        get_user_origin(Attacker, origin)

        message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
        write_byte(TE_DLIGHT) // TE id
        write_coord(origin[0]) // x
        write_coord(origin[1]) // y
        write_coord(origin[2]) // z
        write_byte(10) // radius
        write_byte(255) // r
        write_byte(215) // g
        write_byte(0) // b
        write_byte(1) // life
        write_byte(0) // decay rate
        message_end()
    }

    return HAM_HANDLED;
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if (itemid != g_itemid)
        return ZP_ITEM_AVAILABLE;

    if (zp_core_is_zombie(id) || zp_is_super_class(id))
        return ZP_ITEM_DONT_SHOW;

    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
    // This is not our item
    if (itemid != g_itemid)
        return;

    giveGMP5(id)
}

public fw_SetModel(entity, model[])
{
	// Entity is not valid
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
		
	// Entity model is not w_ak47
	if(!equal(model, mp5_W_MODEL)) 
		return FMRES_IGNORED;
		
	// Get classname
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	// Not a Weapon box
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	// Some vars
	static iOwner, iStoredGalilID
	
	// Get owner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	// Get drop weapon index (galil) to use in fw_Galil_AddToPlayer forward
	iStoredGalilID = find_ent_by_owner(ENG_NULLENT, g_GMP5Ent, entity)
	
	// Entity classname is weaponbox, and galil has founded
    if(g_Hasmp5navy[iOwner] && is_valid_ent(iStoredGalilID))
    {
        // Setting weapon options
        entity_set_int(iStoredGalilID, EV_INT_WEAPONKEY, ANTIDOTEGUN_WPNKEY);

        // Reset user vars
        g_Hasmp5navy[iOwner] = false;

        // Set weaponbox new model
        entity_set_model(entity, gmp5_W_MODEL);
        set_rendering(entity, kRenderFxGlowShell, 255, 215, 0, kRenderNormal, 25);

        return FMRES_SUPERCEDE;
    }

	return FMRES_IGNORED
}

// Added by Shidla
public fw_gMp5_AddToPlayer (GAK47, id)
{
	// Make sure that this is M79
	if( is_valid_ent(GAK47) && is_user_connected(id) && entity_get_int(GAK47, EV_INT_WEAPONKEY) == ANTIDOTEGUN_WPNKEY)
	{
		// Update
		g_Hasmp5navy[id] = true;

		// Reset weapon options
		entity_set_int(GAK47, EV_INT_WEAPONKEY, 0)

		return HAM_HANDLED
	}

	return HAM_IGNORED
}

stock drop_prim(id) 
{
    new weapons[32], num;
    get_user_weapons(id, weapons, num);
    for (new i = 0; i < num; i++) 
    {
        if (Wep_mp5navy & (1 << weapons[i])) 
        {
            static wname[32];
            get_weaponname(weapons[i], wname, sizeof wname - 1);
            engclient_cmd(id, "drop", wname);
        }
    }
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
    static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];

    pev(ent, pev_origin, vOrigin);
    pev(ent, pev_view_ofs, vUp); //for player
    xs_vec_add(vOrigin, vUp, vOrigin);
    pev(ent, pev_v_angle, vAngle); // if normal entity, use pev_angles

    angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward); //or use EngFunc_AngleVectors
    angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
    angle_vector(vAngle, ANGLEVECTOR_UP, vUp);

    vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
    vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
    vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

public native_mp5_user_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_Hasmp5navy[id];
}

giveGMP5(id)
{   
    drop_prim(id)
    give_item(id, "weapon_mp5navy");
    cs_set_user_bpammo(id, CSW_MP5NAVY, 120); // Establecer 120 balas de reserva
    g_Hasmp5navy[id] = true;
}

isSuperClass(id)
{
    if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
        return true
    
    return false
}