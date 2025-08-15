#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zp50_core>

// Data Config
#define MODEL_V "models/zombie_plague_chile/v_ak47pal.mdl"
#define MODEL_P "models/zombie_plague_chile/p_ak47pal.mdl"
#define MODEL_W "models/w_buffak.mdl"
#define MODEL_W_OLD "models/w_ak47.mdl"

#define CSW_BASE CSW_AK47
#define weapon_base "weapon_ak47"

#define SUBMODEL -1 // can -1
#define WEAPON_CODE 2692015
#define WEAPON_EVENT "events/ak47.sc"

#define ANIME_SHOOT 3
#define ANIME_RELOAD 1 // can -1
#define ANIME_DRAW 2 // can -1
#define ANIME_IDLE 0 // can -1

// Weapon Config
#define DAMAGE_A 50 // 66 for Zombie
#define ACCURACY 50 // 0 - 100 ; -1 Default
#define CLIP 30
#define BPAMMO 90
#define SPEED_A 1 // 0.0775
#define RECOIL 0.75
#define RELOAD_TIME 2.0

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Base, g_Clip[33], Float:g_Recoil[33][3], g_OldWeapon[33]

new g_MsgCurWeapon

new m_spriteTexture

public plugin_init()
{
    register_plugin("[ZP] Item: Ak47 Paladin", ZP_VERSION_STRING, "ricardo");

    // Cache
    g_MsgCurWeapon = get_user_msgid("CurWeapon")

    // Evento
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

    // Fakemeta
    register_forward(FM_SetModel, "fw_SetModel")

    // Ham
	RegisterHam(Ham_Weapon_Reload, weapon_base, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_base, "fw_Weapon_Reload_Post", 1)	
    RegisterHam(Ham_Item_PostFrame, weapon_base, "fw_Item_PostFrame")
    RegisterHam(Ham_Item_Deploy, weapon_base, "fw_Item_Deploy_Post", 1)
    RegisterHam(Ham_Item_AddToPlayer, weapon_base, "fw_Item_AddToPlayer_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base, "fw_Weapon_PrimaryAttack")
    RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base, "fw_Weapon_PrimaryAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")

    // Get
	register_clcmd("say /ak", "Get_Base")
}

public plugin_precache()
{
	precache_model(MODEL_V)
	precache_model(MODEL_P)
	precache_model(MODEL_W)

    m_spriteTexture = precache_model("sprites/laserbeam.spr");
}

public Get_Base(id) // Funcion para añadir el arma al jugador
{
	Set_BitVar(g_Had_Base, id)
	give_item(id, weapon_base)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASE)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_BASE, BPAMMO)
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_BASE)
	write_byte(CLIP)
	message_end()
	
	cs_set_weapon_silen(Ent, 0, 0)
}

// -- EVENTOS -----------------------------------------------------

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	static SubModel; SubModel = SUBMODEL
	
	if((CSWID == CSW_BASE && g_OldWeapon[id] != CSW_BASE) && Get_BitVar(g_Had_Base, id))
		if(SubModel != -1) 
            Draw_NewWeapon(id, CSWID)
        
    else if((CSWID == CSW_BASE && g_OldWeapon[id] == CSW_BASE) && Get_BitVar(g_Had_Base, id)) 
    {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASE)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
        static Float:Speed

        Speed = SPEED_A

		set_pdata_float(Ent, 46, Speed, 4)
		set_pdata_float(Ent, 47, Speed, 4)
		
	} 
    else if(CSWID != CSW_BASE && g_OldWeapon[id] == CSW_BASE)
		if(SubModel != -1) 
            Draw_NewWeapon(id, CSWID)
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_BASE)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASE)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			engfunc(EngFunc_SetModel, ent, MODEL_P)	
			set_pev(ent, pev_body, SUBMODEL)
		}
	} else 
    {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASE)
		
		if(pev_valid(ent)) 
            set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
}

// -- FAKEMETA -----------------------------------------------------------------------------

public fw_SetModel(entity, model[]) // Cuando el arma la suelta un jugador y queda como una entidad de ella misma
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_base, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, MODEL_W)
			set_pev(entity, pev_body, SUBMODEL)
		
			Remove_Base(iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

// -- Hamsandwich ----------------------------------------------------------------------------------------

public fw_Item_AddToPlayer_Post(Ent, id) // Cuando recoge un arma desde el suelo
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		Set_BitVar(g_Had_Base, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_HANDLED	
}

public fw_Item_Deploy_Post(Ent) // Cuando sacas el arma se ejecuta una animacion y le coloca el modelo
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
		
	static SubModel; SubModel = SUBMODEL
	
	set_pev(Id, pev_viewmodel2, MODEL_V)
	set_pev(Id, pev_weaponmodel2, SubModel != -1 ? "" : MODEL_P)
	
	static Draw; Draw = ANIME_DRAW
	if(Draw != -1) Set_WeaponAnim(Id, ANIME_DRAW)
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_user_alive(id))
		return

	if(!Get_BitVar(g_Had_Base, id))
		return

	pev(id, pev_punchangle, g_Recoil[id])
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)

	if(!is_user_alive(id))
		return

	if(!Get_BitVar(g_Had_Base, id))
		return

	static Float:Push[3]
	pev(id, pev_punchangle, Push)
    if (RECOIL == 0.0)
        set_pev(id, pev_punchangle, g_Recoil[id]);
    else
    {
        xs_vec_sub(Push, g_Recoil[id], Push)
        xs_vec_mul_scalar(Push, RECOIL, Push)
        xs_vec_add(Push, g_Recoil[id], Push)
        set_pev(id, pev_punchangle, Push)
    }
	
	// Acc
	static Accena; Accena = ACCURACY
	if(Accena != -1)
	{
		static Float:Accuracy
		Accuracy = (float(100 - ACCURACY) * 1.5) / 100.0

		set_pdata_float(Ent, 62, Accuracy, 4);
	}
}

public fw_Weapon_Reload(ent) // Ejecuta la logica si puede recargar
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_BASE)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= CLIP)
		return HAM_SUPERCEDE		
			
	g_Clip[id] = iClip	
	
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent) // Se ejecuta durante la recarga, este le asigna la animacion de recarga y el tiempo de recarga
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if(g_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_Clip[id], 4)
		
		static Reload; Reload = ANIME_RELOAD
		if(Reload != -1) Set_WeaponAnim(id, ANIME_RELOAD)
		Set_PlayerNextAttack(id, RELOAD_TIME)
	}
	
	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASE)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_BASE, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
	}		
	
	return HAM_IGNORED
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASE || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE_A));

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
    write_byte(0); // r
    write_byte(255); // g
    write_byte(255);   // b
    write_byte(255); // brightness
    write_byte(0);   // speed
    message_end();

    new origin[3]
    get_user_origin(Attacker, origin)

    message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
    write_byte(TE_DLIGHT) // TE id
    write_coord(origin[0]) // x
    write_coord(origin[1]) // y
    write_coord(origin[2]) // z
    write_byte(10) // radius
    write_byte(0) // r
    write_byte(255) // g
    write_byte(255) // b
    write_byte(1) // life
    write_byte(0) // decay rate
    message_end()

	
	return HAM_HANDLED
}

// ------------------------------------------------------------------------

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
}

// ---------------------------------------------------------------------------

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
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