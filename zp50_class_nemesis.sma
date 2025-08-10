/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Nemesis -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_effects>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <zp50_color_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_nemesis_player[][] = { "zombie_source" }
new const models_nemesis_damaged_player[][] = { "Nemesis_2nd_frk14" }
new const models_nemesis_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
new const models_nemesis_damaged_claw[][] = { "models/zombie_plague/v_knife_nemesis_tyrant.mdl" }
new const nemesis_roar[][] = { "agrunt/ag_die2.wav", "agrunt/ag_alert1.wav", "agrunt/ag_die4.wav" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 128

// Límite de distancia para afectar a humanos cercanos (puedes ajustar)
#define EFFECT_RADIUS 300

// Custom models
new Array:g_models_nemesis_player
new Array:g_models_nemesis_damaged_player
new Array:g_models_nemesis_claw
new Array:g_models_nemesis_damaged_claw
new Array:g_sound_roar

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new g_IsNemesis, g_IsMutated

new cvar_nemesis_health, cvar_nemesis_base_health, cvar_nemesis_speed, cvar_nemesis_gravity
new cvar_nemesis_glow
new cvar_nemesis_aura, r, g, b
new cvar_nemesis_damage, cvar_nemesis_kill_explode
new cvar_nemesis_grenade_frost, cvar_nemesis_grenade_fire
new g_nemesis_max_health[33]

public plugin_init()
{
	register_plugin("[ZP] Class: Nemesis", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_nemesis_health = register_cvar("zp_nemesis_health", "0")
	cvar_nemesis_base_health = register_cvar("zp_nemesis_base_health", "2000")
	cvar_nemesis_speed = register_cvar("zp_nemesis_speed", "1.05")
	cvar_nemesis_gravity = register_cvar("zp_nemesis_gravity", "0.5")
	cvar_nemesis_glow = register_cvar("zp_nemesis_glow", "1")
	cvar_nemesis_aura = register_cvar("zp_nemesis_aura", "1")

	r = ZP_COLOR_NEMESIS_R;
	g = ZP_COLOR_NEMESIS_G;
	b = ZP_COLOR_NEMESIS_B;

	cvar_nemesis_damage = register_cvar("zp_nemesis_damage", "2.0")
	cvar_nemesis_kill_explode = register_cvar("zp_nemesis_kill_explode", "1")
	cvar_nemesis_grenade_frost = register_cvar("zp_nemesis_grenade_frost", "0")
	cvar_nemesis_grenade_fire = register_cvar("zp_nemesis_grenade_fire", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_nemesis_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_nemesis_damaged_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_nemesis_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	g_models_nemesis_damaged_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)

	g_sound_roar = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS", g_models_nemesis_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS DAMAGED", g_models_nemesis_damaged_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS DAMAGED", g_models_nemesis_damaged_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_nemesis_player) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_player; index++)
			ArrayPushString(g_models_nemesis_player, models_nemesis_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS", g_models_nemesis_player)
	}
	if (ArraySize(g_models_nemesis_damaged_player) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_damaged_player; index++)
			ArrayPushString(g_models_nemesis_damaged_player, models_nemesis_damaged_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS DAMAGED", g_models_nemesis_damaged_player)
	}
	if (ArraySize(g_models_nemesis_claw) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_claw; index++)
			ArrayPushString(g_models_nemesis_claw, models_nemesis_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	}
	if (ArraySize(g_models_nemesis_damaged_claw) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_damaged_claw; index++)
			ArrayPushString(g_models_nemesis_damaged_claw, models_nemesis_damaged_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS DAMAGED", g_models_nemesis_damaged_claw)
	}

	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_nemesis_player); index++)
	{
		ArrayGetString(g_models_nemesis_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_damaged_player); index++)
	{
		ArrayGetString(g_models_nemesis_damaged_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_claw); index++)
	{
		ArrayGetString(g_models_nemesis_claw, index, model, charsmax(model))
		precache_model(model)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_damaged_claw); index++)
	{
		ArrayGetString(g_models_nemesis_damaged_claw, index, model, charsmax(model))
		precache_model(model)
	}

	if (ArraySize(g_sound_roar) == 0)
	{
		for (index = 0; index < sizeof nemesis_roar; index++)
			ArrayPushString(g_sound_roar, nemesis_roar[index])
	}

	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_roar); index++)
	{
		ArrayGetString(g_sound_roar, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public plugin_natives()
{
	register_library("zp50_class_nemesis")
	register_native("zp_class_nemesis_get", "native_class_nemesis_get")
	register_native("zp_class_nemesis_set", "native_class_nemesis_set")
	register_native("zp_class_nemesis_mutated_get", "native_class_nemesis_mutated_get")
	register_native("zp_class_nemesis_mutated_set", "native_class_nemesis_mutated_set")
	register_native("zp_class_nemesis_get_count", "native_class_nemesis_get_count")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was nemesis before disconnecting)
	flag_unset(g_IsNemesis, id)
	flag_unset(g_IsMutated, id)
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Nemesis attacking human
	if (flag_get(g_IsNemesis, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore nemesis damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set nemesis damage
			if (flag_get(g_IsMutated, attacker))
				SetHamParamFloat(4, damage * (get_pcvar_float(cvar_nemesis_damage)+1.5))
			else
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_nemesis_damage))
			
			return HAM_HANDLED;
		}
	}
	if (flag_get(g_IsNemesis, victim))
	{
		// Ya cambió de fase antes
		if (flag_get(g_IsMutated, victim))
			return HAM_IGNORED;

		new current_health = get_user_health(victim)
		if (current_health - floatround(damage) <= floatround(g_nemesis_max_health[victim] * 0.6))
		{
			activateMutation(victim)
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsNemesis, victim))
	{
		// Nemesis explodes!
		if (get_pcvar_num(cvar_nemesis_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(victim+TASK_AURA)
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
		flag_unset(g_IsMutated, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_task(id+TASK_AURA)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
		flag_unset(g_IsMutated, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Nemesis attributes?
	if (!flag_get(g_IsNemesis, id))
		return;

	flag_unset(g_IsMutated, id)
	
	// Health
	if (get_pcvar_num(cvar_nemesis_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_nemesis_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_nemesis_health))
	
	g_nemesis_max_health[id] = get_user_health(id)
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_nemesis_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_nemesis_speed))
	
	// Apply nemesis player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_player, random_num(0, ArraySize(g_models_nemesis_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply nemesis claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_claw, random_num(0, ArraySize(g_models_nemesis_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Nemesis glow
	if (get_pcvar_num(cvar_nemesis_glow))
		set_user_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 25)
	
	// Nemesis aura task
	if (get_pcvar_num(cvar_nemesis_aura))
		set_task(0.1, "nemesis_aura", id+TASK_AURA, _, _, "b")
}

public native_class_nemesis_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsNemesis, id);
}

public native_class_nemesis_mutated_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsMutated, id);
}

public native_class_nemesis_mutated_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsNemesis, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a nemesis (%d)", id)
		return false;
	}
	
	flag_set(g_IsNemesis, id)
	flag_set(g_IsMutated, id)
	zp_core_force_infect(id)
	activateMutation(id)
	return true;
}

public native_class_nemesis_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsNemesis, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a nemesis (%d)", id)
		return false;
	}
	
	flag_set(g_IsNemesis, id)
	flag_unset(g_IsMutated, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_nemesis_get_count(plugin_id, num_params)
{
	return GetNemesisCount();
}

// Nemesis aura task
public nemesis_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(r) // r
	write_byte(g) // g
	write_byte(b) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Nemesis Count -returns alive nemesis number-
GetNemesisCount()
{
	new iNemesis, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsNemesis, id))
			iNemesis++
	}
	
	return iNemesis;
}

activateMutation(id)
{
	// Marca que ya mutó
	flag_set(g_IsMutated, id)

	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_nemesis_gravity)-0.3)
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_nemesis_speed)+0.3)

	// Cambia modelo de jugador
	new damaged_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_damaged_player, random_num(0, ArraySize(g_models_nemesis_damaged_player) - 1), damaged_model, charsmax(damaged_model))
	cs_set_player_model(id, damaged_model)

	// Cambia modelo de garras
	new claw_model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_damaged_claw, random_num(0, ArraySize(g_models_nemesis_damaged_claw) - 1), claw_model, charsmax(claw_model))
	cs_set_player_view_model(id, CSW_KNIFE, claw_model)

	new name[32]
	get_user_name(id, name, charsmax(name))
	static szMsg[128]
	format(szMsg, charsmax(szMsg), "%s ha mutado!!", name)
	set_hudmessage(r, g, b, 0.05, 0.45, 0, 0.0, 5.0, 1.0, 1.0, -1)
	show_dhudmessage(0, szMsg)

	mutationEffects(id)
}

mutationEffects(id)
{
	// Obtener origen del jugador
	new origin[3]
	get_user_origin(id, origin)

	mutationEffectsNearbyHumans(id)

	ScreenFadeIn(id, 2, r, g, b);
	ScreenShake(id, 4, 2, 10)

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_LAVASPLASH) // TE_
	write_coord(origin[0]) // X
	write_coord(origin[1]) // Y
	write_coord(origin[2]) // Z
	message_end() 

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(r) // r
	write_byte(g) // g
	write_byte(b) // b
	write_byte(4) // life
	write_byte(0) // decay rate
	message_end()

	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_roar, random_num(0, ArraySize(g_sound_roar) - 1), sound, charsmax(sound))
	PlaySoundToClients(sound)
}

// Función para aplicar efectos a humanos cercanos o con visión hacia el Nemesis mutado
mutationEffectsNearbyHumans(idNemesis)
{
    new Float:nemesisOrigin[3];
    get_user_origin(idNemesis, nemesisOrigin);

    new maxClients = get_maxplayers();

    for (new i = 1; i <= maxClients; i++)
    {
        if (!is_user_alive(i)) continue;
        if (flag_get(g_IsNemesis, i)) continue; // Ignorar Nemesis
        if (zp_core_is_zombie(i)) continue;     // Ignorar zombies si quieres, sólo humanos

        // Obtener posición jugador humano
        new Float:humanOrigin[3];
        get_user_origin(i, humanOrigin);

        // Calcular distancia
        new Float:dist = get_distance(humanOrigin, nemesisOrigin);
        if (dist > EFFECT_RADIUS) continue; // demasiado lejos

		ScreenFadeOut(i, 3, r, g, b);
		ScreenShake(i, 6, 3, 15)
    }
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}