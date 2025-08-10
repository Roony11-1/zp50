/*================================================================================
	
	------------------------------------------
	-*- [ZP] Game Mode: Sobrevivir -*-
	------------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_sobrevivir[][] = { "ambience/the_horror2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_sobrevivir

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 255
#define HUD_EVENT_B 255

new g_MaxPlayers

new cvar_sobrevivir_chance, cvar_sobrevivir_min_players, cvar_sobrevivir_min_zombies
new cvar_sobrevivir_ratio, cvar_sobrevivir_show_hud, cvar_sobrevivir_sounds
new cvar_sobrevivir_allow_respawn, cvar_respawn_after_last_human

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Sobrevivir", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Sobrevivir Mode")
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_sobrevivir_chance = register_cvar("zp_sobrevivir_chance", "20")
	cvar_sobrevivir_min_players = register_cvar("zp_sobrevivir_min_players", "0")
	cvar_sobrevivir_min_zombies = register_cvar("zp_sobrevivir_min_zombies", "2")
	cvar_sobrevivir_ratio = register_cvar("zp_sobrevivir_ratio", "0.15")
	cvar_sobrevivir_show_hud = register_cvar("zp_sobrevivir_show_hud", "1")
	cvar_sobrevivir_sounds = register_cvar("zp_sobrevivir_sounds", "1")
	cvar_sobrevivir_allow_respawn = register_cvar("zp_sobrevivir_allow_respawn", "1")
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "1")
	
	// Initialize arrays
	g_sound_sobrevivir = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SOBREVIVIR", g_sound_sobrevivir)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_sobrevivir) == 0)
	{
		for (index = 0; index < sizeof sound_sobrevivir; index++)
			ArrayPushString(g_sound_sobrevivir, sound_sobrevivir[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SOBREVIVIR", g_sound_sobrevivir)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_sobrevivir); index++)
	{
		ArrayGetString(g_sound_sobrevivir, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_sobrevivir_allow_respawn))
		return PLUGIN_HANDLED;
	
	// Respawn if only the last human is left?
	if (!get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	new alive_count = GetAliveCount()
	
	// Calculate zombie count with current ratio setting
	new zombie_count = floatround(alive_count * get_pcvar_float(cvar_sobrevivir_ratio), floatround_ceil)
	
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_sobrevivir_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (alive_count < get_pcvar_num(cvar_sobrevivir_min_players))
			return PLUGIN_HANDLED;
		
		// Min zombies
		if (zombie_count < get_pcvar_num(cvar_sobrevivir_min_zombies))
			return PLUGIN_HANDLED;
	}
	
	// Zombie count should be smaller than alive players count, so that there's humans left in the round
	if (zombie_count >= alive_count)
		return PLUGIN_HANDLED;
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{
	// iMaxZombies is rounded up, in case there aren't enough players
	new iZombies, id, alive_count = GetAliveCount()
	new iMaxZombies = floatround(alive_count * get_pcvar_float(cvar_sobrevivir_ratio), floatround_ceil)
	
	// Randomly turn iMaxZombies players into zombies
	while (iZombies < iMaxZombies)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a zombie
		if (!is_user_alive(id) || zp_core_is_zombie(id))
			continue;
		
		// Turn into a zombie
		zp_core_infect(id, 0)
		iZombies++
	}
	
	// Turn the remaining players into humans
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Only those of them who aren't zombies
		if (!is_user_alive(id) || zp_core_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	// Play sobrevivir infection sound
	if (get_pcvar_num(cvar_sobrevivir_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_sobrevivir, random_num(0, ArraySize(g_sound_sobrevivir) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_sobrevivir_show_hud))
	{
		showDHud()
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

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}

showDHud()
{
	static szMsg[128]
	format(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "NOTICE_SOBREVIVIR")
	set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	show_dhudmessage(0, szMsg)
}