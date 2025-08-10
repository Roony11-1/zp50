/*================================================================================
	
	----------------------------
	-*- [ZP] Effects: Infect -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hlsdk_const>
#include <amx_settings_api>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DEPREDADOR "zp50_class_depredador"
#include <zp50_class_depredador>
#include <zp50_core>
#include <zp50_effects>
#include <zp50_color_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_infect[][] = { "zombie_plague/zombie_infec1.wav" , "zombie_plague/zombie_infec2.wav" , "zombie_plague/zombie_infec3.wav" , "scientist/c1a0_sci_catscream.wav" , "scientist/scream01.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_infect

// HUD messages
#define HUD_INFECT_X 0.05
#define HUD_INFECT_Y 0.45
#define HUD_INFECT_R 255
#define HUD_INFECT_G 0
#define HUD_INFECT_B 0

// Some constants
const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000

new g_MsgDeathMsg, g_MsgScoreAttrib
new g_MsgDamage

new cvar_infect_show_hud
new cvar_infect_show_notice
new cvar_infect_sounds

new g_syncHud

new cvar_infect_screen_fade
new cvar_infect_screen_shake
new cvar_infect_hud_icon
new cvar_infect_tracers
new cvar_infect_particles
new cvar_infect_sparkle

public plugin_init()
{
	register_plugin("[ZP] Effects: Infect", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_MsgDamage = get_user_msgid("Damage")

	g_syncHud = CreateHudSyncObj()
	
	cvar_infect_show_hud = register_cvar("zp_infect_show_hud", "1")
	cvar_infect_show_notice = register_cvar("zp_infect_show_notice", "1")
	cvar_infect_sounds = register_cvar("zp_infect_sounds", "1")
	
	cvar_infect_screen_fade = register_cvar("zp_infect_screen_fade", "1")
	cvar_infect_screen_shake = register_cvar("zp_infect_screen_shake", "1")
	cvar_infect_hud_icon = register_cvar("zp_infect_hud_icon", "1")
	cvar_infect_tracers = register_cvar("zp_infect_tracers", "1")
	cvar_infect_particles = register_cvar("zp_infect_particles", "1")
	cvar_infect_sparkle = register_cvar("zp_infect_sparkle", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_infect = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE INFECT", g_sound_infect)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_infect) == 0)
	{
		for (index = 0; index < sizeof sound_infect; index++)
			ArrayPushString(g_sound_infect, sound_infect[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE INFECT", g_sound_infect)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_infect); index++)
	{
		ArrayGetString(g_sound_infect, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public zp_fw_core_infect_post(id, attacker)
{	
	// Attacker is valid?
	if (is_user_connected(attacker))
	{
		// Infection sounds?
		if (get_pcvar_num(cvar_infect_sounds))
		{
			static sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_infect, random_num(0, ArraySize(g_sound_infect) - 1), sound, charsmax(sound))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Player infected himself
		if (attacker == id)
		{
			// Show Infection HUD notice? (except for first zombie)
			if (get_pcvar_num(cvar_infect_show_hud) && !zp_core_is_first_zombie(id))
			{
				new name[32]
				get_user_name(id, name, charsmax(name))
				static szMsg[128]
				format(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "NOTICE_INFECT", name)
				set_hudmessage(HUD_INFECT_R, HUD_INFECT_G, HUD_INFECT_B, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_syncHud, szMsg)
			}
		}
		else
		{
			// Show Infection HUD notice?
			if (get_pcvar_num(cvar_infect_show_hud))
			{
				new attacker_name[32], victim_name[32]
				get_user_name(attacker, attacker_name, charsmax(attacker_name))
				get_user_name(id, victim_name, charsmax(victim_name))
				static szMsg[128]
				format(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "NOTICE_INFECT2", victim_name, attacker_name)
				set_hudmessage(HUD_INFECT_R, HUD_INFECT_G, HUD_INFECT_B, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_syncHud, szMsg)
			}
			
			// Show infection death notice?
			if (get_pcvar_num(cvar_infect_show_notice))
			{
				// Send death notice and fix the "dead" attrib on scoreboard
				SendDeathMsg(attacker, id)
				FixDeadAttrib(id)
			}
		}
	}
	
	// Infection special effects
	infection_effects(id)
}

// Modificación de infection_effects para usar colores de clase solo para zombies
infection_effects(id)
{
    // Obtener origen del jugador
    new origin[3]
    get_user_origin(id, origin)

    // Variables para color
    new r, g, b;
    if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
    {
		r = ZP_COLOR_NEMESIS_R;
		g = ZP_COLOR_NEMESIS_G;
		b = ZP_COLOR_NEMESIS_B;
    }
    else if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(id))
    {
		r = ZP_COLOR_DEPREDADOR_R;
		g = ZP_COLOR_DEPREDADOR_G;
		b = ZP_COLOR_DEPREDADOR_B;
    }
    else
    {
        r = ZP_COLOR_ZOMBIE_R;
        g = ZP_COLOR_ZOMBIE_G;
        b = ZP_COLOR_ZOMBIE_B;
    }

    // Screen fade?
    if (get_pcvar_num(cvar_infect_screen_fade))
    {
		ScreenFadeOut(id, 1, r, g, b)
    }

    // Screen shake?
    if (get_pcvar_num(cvar_infect_screen_shake))
    {
		ScreenShake(id, 4, 2, 10)
    }

    // Infection icon?
    if (get_pcvar_num(cvar_infect_hud_icon))
    {
        message_begin(MSG_ONE_UNRELIABLE, g_MsgDamage, _, id)
        write_byte(0) // damage save
        write_byte(0) // damage take
        write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
        write_coord(0) // x
        write_coord(0) // y
        write_coord(0) // z
        message_end()
    }

    // Tracers?
    if (get_pcvar_num(cvar_infect_tracers))
    {
        message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
        write_byte(TE_IMPLOSION) // TE id
        write_coord(origin[0]) // x
        write_coord(origin[1]) // y
        write_coord(origin[2]) // z
        write_byte(128) // radius
        write_byte(20) // count
        write_byte(3) // duration
        message_end()
    }

    // Particle burst?
    if (get_pcvar_num(cvar_infect_particles))
    {
        message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
        write_byte(TE_PARTICLEBURST) // TE id
        write_coord(origin[0]) // x
        write_coord(origin[1]) // y
        write_coord(origin[2]) // z
        write_short(50) // radius
        write_byte(70) // color
        write_byte(3) // duration (will be randomized a bit)
        message_end()
    }

    // Light sparkle?
    if (get_pcvar_num(cvar_infect_sparkle))
    {
		DLightId(origin[0], origin[1], origin[2], r, g, b, 2, 20, 0)
    }
}

// Send Death Message for infections
SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("infection") // killer's weapon
	message_end()
}

// Fix Dead Attrib on scoreboard
FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}