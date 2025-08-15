/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Depredador -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine> // Necesario para constantes de botones
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
#include <zp50_stocks>

#define PLUGIN_NAME "[ZP] Class: Depredador"
#define PLUGIN_AUTOR "ricardo"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_depredador_player[][] = { "zombie_source" }
new const models_depredador_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
new const sound_ability[][] = { "garg/gar_breathe1.wav", "garg/gar_breathe2.wav", "garg/gar_breathe3.wav" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define PEV_SPEC_TARGET pev_iuser2

#define INVISIBILITY_TIME 15.0 // Tiempo en segundos
#define INVISIBILITY_COOLDOWN (INVISIBILITY_TIME + 15.0) // Tiempo de espera entre usos

// Custom models
new Array:g_models_depredador_player
new Array:g_models_depredador_claw
new Array:g_sound_ability

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define TASK_INVIS 500
#define ID_INVIS (taskid - TASK_INVIS)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new bool:g_IsInvisible[33], g_LastButton[33], Float:g_NextInvisibilityTime[33]
new g_IsDepredador

new cvar_depredador_health, cvar_depredador_base_health, cvar_depredador_speed, cvar_depredador_gravity
new cvar_depredador_glow
new cvar_depredador_aura, r, g, b
new cvar_depredador_damage, cvar_depredador_kill_explode
new cvar_depredador_grenade_frost, cvar_depredador_grenade_fire

public plugin_init()
{
	register_plugin(PLUGIN_NAME, ZP_VERSION_STRING, PLUGIN_AUTOR)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)

	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_depredador_health = register_cvar("zp_depredador_health", "0")
	cvar_depredador_base_health = register_cvar("zp_depredador_base_health", "750")
	cvar_depredador_speed = register_cvar("zp_depredador_speed", "1.25")
	cvar_depredador_gravity = register_cvar("zp_depredador_gravity", "0.5")
	cvar_depredador_glow = register_cvar("zp_depredador_glow", "0")
	cvar_depredador_aura = register_cvar("zp_depredador_aura", "0")

	r = ZP_COLOR_DEPREDADOR_R;
	g = ZP_COLOR_DEPREDADOR_G;
	b = ZP_COLOR_DEPREDADOR_B;

	cvar_depredador_damage = register_cvar("zp_depredador_damage", "3.25")
	cvar_depredador_kill_explode = register_cvar("zp_depredador_kill_explode", "1")
	cvar_depredador_grenade_frost = register_cvar("zp_depredador_grenade_frost", "0")
	cvar_depredador_grenade_fire = register_cvar("zp_depredador_grenade_fire", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_depredador_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_depredador_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)

	g_sound_ability = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "DEPREDADOR", g_models_depredador_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE DEPREDADOR", g_models_depredador_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_depredador_player) == 0)
	{
		for (index = 0; index < sizeof models_depredador_player; index++)
			ArrayPushString(g_models_depredador_player, models_depredador_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "DEPREDADOR", g_models_depredador_player)
	}
	if (ArraySize(g_models_depredador_claw) == 0)
	{
		for (index = 0; index < sizeof models_depredador_claw; index++)
			ArrayPushString(g_models_depredador_claw, models_depredador_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE DEPREDADOR", g_models_depredador_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_depredador_player); index++)
	{
		ArrayGetString(g_models_depredador_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_depredador_claw); index++)
	{
		ArrayGetString(g_models_depredador_claw, index, model, charsmax(model))
		precache_model(model)
	}
	if (ArraySize(g_sound_ability) == 0)
	{
		for (index = 0; index < sizeof sound_ability; index++)
			ArrayPushString(g_sound_ability, sound_ability[index])
	}

	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_ability); index++)
	{
		ArrayGetString(g_sound_ability, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public plugin_natives()
{
	register_library("zp50_class_depredador")
	register_native("zp_class_depredador_get", "native_class_depredador_get")
	register_native("zp_class_depredador_set", "native_class_depredador_set")
	register_native("zp_class_depredador_get_count", "native_class_depredador_get_count")
	
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
	if (flag_get(g_IsDepredador, id))
	{
		// Remove depredador glow
		if (get_pcvar_num(cvar_depredador_glow))
			set_user_rendering(id)
		
		// Remove depredador aura
		if (get_pcvar_num(cvar_depredador_aura))
			remove_task(id+TASK_AURA)

		quitarInvisibilidad(id)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was depredador before disconnecting)
	quitarInvisibilidad(id)
	flag_unset(g_IsDepredador, id)
}

public activar_invisibilidad(id)
{
	new Float:current_time = get_gametime();

	if (g_IsInvisible[id])
	{
		new Float:remaining = (g_NextInvisibilityTime[id] - INVISIBILITY_COOLDOWN) + INVISIBILITY_TIME - current_time;
		if (remaining < 0.0) 
			remaining = 0.0; // Evitar negativos
		client_print(id, print_center, "Eres invisible por: %.1f segundos.", remaining);

		return;
	}

	if (current_time < g_NextInvisibilityTime[id])
	{
		new Float:remaining = g_NextInvisibilityTime[id] - current_time;
		client_print(id, print_center, "Habilidad disponible en: %.1f segundos.", remaining);

		return;
	}

	// Activar invisibilidad
	g_IsInvisible[id] = true;
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
	client_print(id, print_center, "¡Eres invisible!");

	// Establecer cooldown para próximo uso
	g_NextInvisibilityTime[id] = current_time + INVISIBILITY_COOLDOWN;

	// Programar tarea para desactivar invisibilidad luego del tiempo definido
	set_task(INVISIBILITY_TIME, "desactivar_invisibilidad", id + TASK_INVIS)

	efectosInvisibilidad(id);
}


public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !flag_get(g_IsDepredador, id))
		return FMRES_IGNORED;

	static buttons;
	buttons = get_uc(uc_handle, UC_Buttons);

	// Lógica para jugador humano al presionar RELOAD
	if ((buttons & IN_RELOAD) && !(g_LastButton[id] & IN_RELOAD))
	{
		activar_invisibilidad(id);
	}

	g_LastButton[id] = buttons;

	return FMRES_IGNORED;
}

public desactivar_invisibilidad(taskid)
{
	new id = ID_INVIS

	// Verificamos que el jugador esté conectado y sea depredador
	if (!is_user_connected(id) || !flag_get(g_IsDepredador, id))
		return

	// Solo si está invisible
	if (g_IsInvisible[id])
	{
		g_IsInvisible[id] = false
		set_user_rendering(id) // Restaurar visual por defecto
		client_print(id, print_center, "Invisibilidad desactivada.")
		efectosInvisibilidad(id) // Efectos visuales opcionales
	}
}

public FM_client_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED

	// Solo aplicamos a jugadores (evita index out of bounds)
	if (!is_user_connected(e) || !is_user_alive(e))
		return FMRES_IGNORED

	// Validar target del espectador si corresponde
	new target = 0
	if (!is_user_alive(id))
		target = pev(id, PEV_SPEC_TARGET)

	// Si el jugador e es depredador e invisible
	if (flag_get(g_IsDepredador, e) && g_IsInvisible[e])
	{
		// Mostrar depredador a aliados o espectadores siguiendo a alguien
		if (
			(!is_user_alive(id) && (target == 0 || is_user_alive(target))) ||
			(zp_core_is_zombie(id))
		)
		{
			set_es(es, ES_RenderMode, kRenderTransAdd)
			set_es(es, ES_RenderAmt, 255)
			set_es(es, ES_RenderColor, 255, 255, 255)
			set_es(es, ES_RenderFx, kRenderFxHologram)
			return FMRES_HANDLED
		}
		else
		{
			// Ocultar al depredador invisible a los enemigos
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}


// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;

	new Float:current_time = get_gametime();

	if (flag_get(g_IsDepredador, victim))
	{
		// Lógica más natural para bots
		if (is_user_bot(victim))
		{
			// Esperamos que ya puedan volverse invisibles
			if (!g_IsInvisible[victim] && current_time >= g_NextInvisibilityTime[victim])
				zp_try_activate_random(victim, 55.0, "activar_invisibilidad", PLUGIN_NAME);

			return FMRES_IGNORED;
		}
	}
	
	// Depredador attacking human
	if (flag_get(g_IsDepredador, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore depredador damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set depredador damage
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_depredador_damage))
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsDepredador, victim))
	{
		// Depredador explodes!
		if (get_pcvar_num(cvar_depredador_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove depredador aura
		if (get_pcvar_num(cvar_depredador_aura))
			remove_task(victim+TASK_AURA)

		quitarInvisibilidad(victim)
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Depredador
	if (flag_get(g_IsDepredador, id) && !get_pcvar_num(cvar_depredador_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Depredador
	if (flag_get(g_IsDepredador, id) && !get_pcvar_num(cvar_depredador_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsDepredador, id))
	{
		// Remove depredador glow
		if (get_pcvar_num(cvar_depredador_glow))
			set_user_rendering(id)
		
		// Remove depredador aura
		if (get_pcvar_num(cvar_depredador_aura))
			remove_task(id+TASK_AURA)
		
		// Remove depredador flag
		quitarInvisibilidad(id)
		flag_unset(g_IsDepredador, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsDepredador, id))
	{
		// Remove depredador glow
		if (get_pcvar_num(cvar_depredador_glow))
			set_user_rendering(id)
		
		// Remove depredador aura
		if (get_pcvar_num(cvar_depredador_aura))
			remove_task(id+TASK_AURA)
		
		// Remove depredador flag
		quitarInvisibilidad(id)
		flag_unset(g_IsDepredador, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Depredador attributes?
	if (!flag_get(g_IsDepredador, id))
	{
		remove_task(id + TASK_INVIS)
		return;
	}
		

	// Reset tiempo invisibilidad
	quitarInvisibilidad(id)
	
	// Health
	if (get_pcvar_num(cvar_depredador_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_depredador_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_depredador_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_depredador_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_depredador_speed))
	
	// Apply depredador player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_depredador_player, random_num(0, ArraySize(g_models_depredador_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply depredador claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_depredador_claw, random_num(0, ArraySize(g_models_depredador_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Depredador glow
	if (get_pcvar_num(cvar_depredador_glow))
		set_user_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 25)
	
	// Depredador aura task
	if (get_pcvar_num(cvar_depredador_aura))
		set_task(0.1, "depredador_aura", id+TASK_AURA, _, _, "b")
}

public native_class_depredador_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsDepredador, id);
}

public native_class_depredador_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsDepredador, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a depredador (%d)", id)
		return false;
	}
	
	flag_set(g_IsDepredador, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_depredador_get_count(plugin_id, num_params)
{
	return GetDepredadorCount();
}

// Depredador aura task
public depredador_aura(taskid)
{
	// Obtener origen del jugador
	new origin[3]
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

// Get Depredador Count -returns alive depredador number-
GetDepredadorCount()
{
	new iDepredador, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsDepredador, id))
			iDepredador++
	}
	
	return iDepredador;
}

quitarInvisibilidad(id)
{
	g_IsInvisible[id] = false;
	g_NextInvisibilityTime[id] = 0.0;

	set_user_rendering(id)              // Restaurar apariencia normal
	remove_task(id + TASK_INVIS)        // Cancelar tarea si aún está activa
}

efectosInvisibilidad(id)
{
	// Obtener origen del jugador
	new origin[3]
	get_user_origin(id, origin)

	ScreenFadeOut(id, 1, r, g, b);

	ScreenShake(id, 4, 2, 10);

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
	write_byte(4) // life
	write_byte(0) // decay rate
	message_end()

	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_ability, random_num(0, ArraySize(g_sound_ability) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
