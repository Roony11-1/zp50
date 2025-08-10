/*================================================================================
	
	------------------------
	-*- [ZP] Nightvision -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_DEPREDADOR "zp50_class_depredador"
#include <zp50_class_depredador>
#define LIBRARY_ZOMBIE_MADNESS "zp50_item_zombie_madness"
#include <zp50_item_zombie_madness>
#include <zp50_color_const>

#define TASK_NIGHTVISION 100
#define ID_NIGHTVISION (taskid - TASK_NIGHTVISION)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

#define PEV_SPEC_TARGET pev_iuser2

new g_NightVisionActive

new g_MsgNVGToggle

new cvar_nvision_custom, cvar_nvision_radius
new cvar_nvision_zombie, cvar_zombie_color[3]
new cvar_nvision_human, cvar_human_color[3]
new cvar_nvision_spec, cvar_spec_color[3]
new cvar_nvision_nemesis, cvar_nemesis_color[3], cvar_nvision_depredador, cvar_depredador_color[3]
new cvar_nvision_survivor, cvar_survivor_color[3]
new cvar_madness_color[3]

public plugin_init()
{
	register_plugin("[ZP] Nightvision", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgNVGToggle = get_user_msgid("NVGToggle")
	register_message(g_MsgNVGToggle, "message_nvgtoggle")
	
	register_clcmd("nightvision", "clcmd_nightvision_toggle")
	register_event("ResetHUD", "event_reset_hud", "b")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	cvar_nvision_custom = register_cvar("zp_nvision_custom", "0")
	cvar_nvision_radius = register_cvar("zp_nvision_radius", "80")
	
	// Zombie
	cvar_nvision_zombie = register_cvar("zp_nvision_zombie", "2") // 1-give only // 2-give and enable
	cvar_zombie_color[0] = ZP_COLOR_ZOMBIE_R;
	cvar_zombie_color[1] = ZP_COLOR_ZOMBIE_G;
	cvar_zombie_color[2] = ZP_COLOR_ZOMBIE_B;

	cvar_madness_color[0] = ZP_COLOR_MADNESS_R;
	cvar_madness_color[1] = ZP_COLOR_MADNESS_G;
	cvar_madness_color[2] = ZP_COLOR_MADNESS_B;
	// Human
	cvar_nvision_human = register_cvar("zp_nvision_human", "0") // 1-give only // 2-give and enable
	cvar_human_color[0] = ZP_COLOR_HUMAN_R;
	cvar_human_color[1] = ZP_COLOR_HUMAN_G;
	cvar_human_color[2] = ZP_COLOR_HUMAN_B;
	// Spec
	cvar_nvision_spec = register_cvar("zp_nvision_spec", "2") // 1-give only // 2-give and enable
	cvar_spec_color[0] = ZP_COLOR_SPECT;
	cvar_spec_color[1] = ZP_COLOR_SPECT;
	cvar_spec_color[2] = ZP_COLOR_SPECT;
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_nvision_nemesis = register_cvar("zp_nvision_nemesis", "2")
		cvar_nemesis_color[0] = ZP_COLOR_NEMESIS_R;
		cvar_nemesis_color[1] = ZP_COLOR_NEMESIS_G;
		cvar_nemesis_color[2] = ZP_COLOR_NEMESIS_B;
	}

	// Depredador Class loaded?
	if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library))
	{
		cvar_nvision_depredador = register_cvar("zp_nvision_depredador", "2")
		cvar_depredador_color[0] = ZP_COLOR_DEPREDADOR_R;
		cvar_depredador_color[1] = ZP_COLOR_DEPREDADOR_G;
		cvar_depredador_color[2] = ZP_COLOR_DEPREDADOR_B;
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
	{
		cvar_nvision_survivor = register_cvar("zp_nvision_survivor", "0")
		cvar_survivor_color[0] = ZP_COLOR_SURVIVOR_R;
		cvar_survivor_color[1] = ZP_COLOR_SURVIVOR_G;
		cvar_survivor_color[2] = ZP_COLOR_SURVIVOR_B;
	}
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_DEPREDADOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
	{
		if (get_pcvar_num(cvar_nvision_nemesis))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_nemesis) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	// Depredador Class loaded?
	else if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(id))
	{
		if (get_pcvar_num(cvar_nvision_depredador))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_depredador) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_zombie))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_zombie) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
	// Always give nightvision to PODBots
	if (is_user_bot(id) && !cs_get_user_nvg(id))
		cs_set_user_nvg(id, 1)
}

public zp_fw_core_cure_post(id, attacker)
{
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
	{
		if (get_pcvar_num(cvar_nvision_survivor))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_survivor) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_human))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_human) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
	// Always give nightvision to PODBots
	if (is_user_bot(id) && !cs_get_user_nvg(id))
		cs_set_user_nvg(id, 1)
}

public clcmd_nightvision_toggle(id)
{
	if (is_user_alive(id))
	{
		// Player owns nightvision?
		if (!cs_get_user_nvg(id))
			return PLUGIN_CONTINUE;
	}
	else
	{
		// Spectator nightvision disabled?
		if (!get_pcvar_num(cvar_nvision_spec))
			return PLUGIN_CONTINUE;
	}
	
	if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
	else
		EnableNightVision(id)
	
	return PLUGIN_HANDLED;
}

// ResetHUD Removes CS Nightvision (bugfix)
public event_reset_hud(id)
{
	if (!get_pcvar_num(cvar_nvision_custom) && flag_get(g_NightVisionActive, id))
		cs_set_user_nvg_active(id, 1)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Enable spectators nightvision?
	spectator_nightvision(victim)
}

public client_putinserver(id)
{
	// Enable spectators nightvision?
	set_task(0.1, "spectator_nightvision", id)
}

public spectator_nightvision(id)
{
	// Player disconnected
	if (!is_user_connected(id))
		return;
	
	// Not a spectator
	if (is_user_alive(id))
		return;
	
	if (get_pcvar_num(cvar_nvision_spec) == 2)
	{
		if (!flag_get(g_NightVisionActive, id))
			clcmd_nightvision_toggle(id)
	}
	else if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
}

public client_disconnected(id)
{
	// Reset nightvision flags
	flag_unset(g_NightVisionActive, id)
	remove_task(id+TASK_NIGHTVISION)
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_nvgtoggle(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

// Custom Night Vision Task
public custom_nightvision_task(taskid)
{
	new id = ID_NIGHTVISION

	// Obtener origen del jugador
	static origin[3]
	get_user_origin(id, origin)

	// Enviar luz dinámica (nightvision)
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(get_pcvar_num(cvar_nvision_radius))

	// Determinar colores según la clase
	new r, g, b

	if (!is_user_alive(id))
	{
		new target = pev(id, PEV_SPEC_TARGET)

		if (is_user_alive(target))
		{
			get_player_nightvision_color(target, r, g, b)
		}
		else
		{
			// Free look → blanco
			r = get_pcvar_num(cvar_spec_color[0])
			g = get_pcvar_num(cvar_spec_color[1])
			b = get_pcvar_num(cvar_spec_color[2])
		}
	}
	else
	{
		get_player_nightvision_color(id, r, g, b)
	}

	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(2)  // life
	write_byte(0)  // decay rate
	message_end()
}

stock get_player_nightvision_color(id, &r, &g, &b)
{
	if (zp_core_is_zombie(id))
	{
		// Si tiene Furia Zombie, tomar color del aura de furia
        if (zp_item_zombie_madness_get(id))
        {
            r = get_pcvar_num(cvar_madness_color[0]);
            g = get_pcvar_num(cvar_madness_color[1]);
            b = get_pcvar_num(cvar_madness_color[2]);
        }
		else if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		{
			r = get_pcvar_num(cvar_nemesis_color[0])
			g = get_pcvar_num(cvar_nemesis_color[1])
			b = get_pcvar_num(cvar_nemesis_color[2])
		}
		else if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(id))
		{
			r = get_pcvar_num(cvar_depredador_color[0])
			g = get_pcvar_num(cvar_depredador_color[1])
			b = get_pcvar_num(cvar_depredador_color[2])
		}
		else
		{
			r = get_pcvar_num(cvar_zombie_color[0])
			g = get_pcvar_num(cvar_zombie_color[1])
			b = get_pcvar_num(cvar_zombie_color[2])
		}
	}
	else
	{
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		{
			r = get_pcvar_num(cvar_survivor_color[0])
			g = get_pcvar_num(cvar_survivor_color[1])
			b = get_pcvar_num(cvar_survivor_color[2])
		}
		else
		{
			r = get_pcvar_num(cvar_human_color[0])
			g = get_pcvar_num(cvar_human_color[1])
			b = get_pcvar_num(cvar_human_color[2])
		}
	}
}

EnableNightVision(id)
{
	flag_set(g_NightVisionActive, id)
	
	if (!get_pcvar_num(cvar_nvision_custom))
		cs_set_user_nvg_active(id, 1)
	else
		set_task(0.1, "custom_nightvision_task", id+TASK_NIGHTVISION, _, _, "b")
}

DisableNightVision(id)
{
	flag_unset(g_NightVisionActive, id)
	
	if (!get_pcvar_num(cvar_nvision_custom))
		cs_set_user_nvg_active(id, 0)
	else
		remove_task(id+TASK_NIGHTVISION)
}

stock cs_set_user_nvg_active(id, active)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_MsgNVGToggle, _, id)
	write_byte(active) // toggle
	message_end()
}