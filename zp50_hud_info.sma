/*================================================================================
	
	----------------------------
	-*- [ZP] HUD Information -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <zp50_class_human>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_DEPREDADOR "zp50_class_depredador"
#include <zp50_class_depredador>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>
#define LIBRARY_ZOMBIE_MADNESS "zp50_item_zombie_madness"
#include <zp50_item_zombie_madness>
#include <zp50_color_const>

const Float:HUD_SPECT_X = 0.01
const Float:HUD_SPECT_Y = 0.15
const Float:HUD_STATS_X = 0.01
const Float:HUD_STATS_Y = 0.15

#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

const PEV_SPEC_TARGET = pev_iuser2

new g_MsgSync

new cvar_zombie_color[3], cvar_human_color[3], cvar_nemesis_color[3], cvar_depredador_color[3], cvar_survivor_color[3], cvar_madness_color[3]

public plugin_init()
{
	register_plugin("[ZP] HUD Information", ZP_VERSION_STRING, "ZP Dev Team")
	// Zombie
	cvar_zombie_color[0] = ZP_COLOR_ZOMBIE_R;
	cvar_zombie_color[1] = ZP_COLOR_ZOMBIE_G;
	cvar_zombie_color[2] = ZP_COLOR_ZOMBIE_B;

	cvar_madness_color[0] = ZP_COLOR_MADNESS_R;
	cvar_madness_color[1] = ZP_COLOR_MADNESS_G;
	cvar_madness_color[2] = ZP_COLOR_MADNESS_B;
	// Human
	cvar_human_color[0] = ZP_COLOR_HUMAN_R;
	cvar_human_color[1] = ZP_COLOR_HUMAN_G;
	cvar_human_color[2] = ZP_COLOR_HUMAN_B;

	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_nemesis_color[0] = ZP_COLOR_NEMESIS_R;
		cvar_nemesis_color[1] = ZP_COLOR_NEMESIS_G;
		cvar_nemesis_color[2] = ZP_COLOR_NEMESIS_B;
	}

	// Depredador Class loaded?
	if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library))
	{
		cvar_depredador_color[0] = ZP_COLOR_DEPREDADOR_R;
		cvar_depredador_color[1] = ZP_COLOR_DEPREDADOR_G;
		cvar_depredador_color[2] = ZP_COLOR_DEPREDADOR_B;
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
	{
		cvar_survivor_color[0] = ZP_COLOR_SURVIVOR_R;
		cvar_survivor_color[1] = ZP_COLOR_SURVIVOR_G;
		cvar_survivor_color[2] = ZP_COLOR_SURVIVOR_B;
	}
	
	g_MsgSync = CreateHudSyncObj()
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_AMMOPACKS) || equal(module, LIBRARY_DEPREDADOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		// Set the custom HUD display task
		set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	}
}

public client_disconnected(id)
{
	remove_task(id+TASK_SHOWHUD)
}

// Mostrar HUD al jugador o espectador
public ShowHUD(taskid)
{
	new id = ID_SHOWHUD

	// Si no está vivo, ver a quién está espectando
	new target = id
	if (!is_user_alive(id))
	{
		target = pev(id, PEV_SPEC_TARGET)
		if (!is_user_alive(target)) return
	}

	static class_name[32]
	new red, green, blue
	get_player_class_info(target, class_name, charsmax(class_name), red, green, blue)

	// Mostrar HUD unificado (ya sea espectador o jugador vivo)
	ShowPlayerInfoHUD(id, target, class_name)
}

// Obtener nombre de clase y color
get_player_class_info(player, class_name[], maxlen, &r, &g, &b)
{
	// Obtener color desde cvars (reutiliza tu función nueva)
	get_player_hud_color(player, r, g, b)

	static transkey[64]

	if (zp_core_is_zombie(player))
	{
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player))
			formatex(class_name, maxlen, "%L", player, "CLASS_NEMESIS")
		else if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(player))
			formatex(class_name, maxlen, "%L", player, "CLASS_DEPREDADOR")
		else
		{
			zp_class_zombie_get_name(zp_class_zombie_get_current(player), class_name, maxlen)
			formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad)
				formatex(class_name, maxlen, "%L", player, transkey)
		}
	}
	else
	{
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player))
			formatex(class_name, maxlen, "%L", player, "CLASS_SURVIVOR")
		else
		{
			zp_class_human_get_name(zp_class_human_get_current(player), class_name, maxlen)
			formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad)
				formatex(class_name, maxlen, "%L", player, transkey)
		}
	}
}

// Muestra el HUD
ShowPlayerInfoHUD(viewer, target, const class_name[])
{
	new name[32]
	get_user_name(target, name, charsmax(name))

	// Color del HUD basado en el objetivo observado (o en sí mismo)
	new r, g, b
	get_player_hud_color(target, r, g, b)

	// Coordenadas distintas según quién lo ve
	new Float:x = (viewer == target) ? HUD_STATS_X : HUD_SPECT_X
	new Float:y = (viewer == target) ? HUD_STATS_Y : HUD_SPECT_Y

	set_hudmessage(r, g, b, x, y, 0, 6.0, 1.1, 0.0, 0.0, -1)

	new hud_text[128], extra[32]
	if (!(zp_core_is_zombie(target) || get_player_super_human_class(target)))
		formatex(extra, charsmax(extra), "Armadura: %d^n", get_user_armor(target))
	else
		formatex(extra, charsmax(extra), "")

	// Texto: si el viewer es el mismo que el target (jugador vivo), no muestra el nombre
	if (viewer == target)
	{
		formatex(hud_text, charsmax(hud_text),
			"Vida: %d^n%sClase: %s^nAmmoPacks: %d",
			get_user_health(target),
			extra,
			class_name,
			zp_ammopacks_get(target))
	}
	else
	{
		formatex(hud_text, charsmax(hud_text),
			"Jugador: %s^nVida: %d^n%sClase: %s^nAmmoPacks: %d",
			name,
			get_user_health(target),
			extra,
			class_name,
			zp_ammopacks_get(target))
	}

	ShowSyncHudMsg(viewer, g_MsgSync, hud_text)
}

get_player_hud_color(player, &r, &g, &b)
{
	if (zp_core_is_zombie(player))
	{
		// Si tiene Furia Zombie, tomar color del aura de furia
		if (zp_item_zombie_madness_get(player))
		{
			r = get_pcvar_num(cvar_madness_color[0]);
			g = get_pcvar_num(cvar_madness_color[1]);
			b = get_pcvar_num(cvar_madness_color[2]);
			//server_print("Jugador %d tiene Furia Zombie: color R=%d G=%d B=%d\n", player, r, g, b);
		}
		else if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player))
		{
			r = get_pcvar_num(cvar_nemesis_color[0]);
			g = get_pcvar_num(cvar_nemesis_color[1]);
			b = get_pcvar_num(cvar_nemesis_color[2]);
			//server_print("Jugador %d es Nemesis: color R=%d G=%d B=%d\n", player, r, g, b);
		}
		else if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(player))
		{
			r = get_pcvar_num(cvar_depredador_color[0]);
			g = get_pcvar_num(cvar_depredador_color[1]);
			b = get_pcvar_num(cvar_depredador_color[2]);
			//server_print("Jugador %d es Depredador: color R=%d G=%d B=%d\n", player, r, g, b);
		}
		else
		{
			r = get_pcvar_num(cvar_zombie_color[0]);
			g = get_pcvar_num(cvar_zombie_color[1]);
			b = get_pcvar_num(cvar_zombie_color[2]);
			//server_print("Jugador %d es Zombie normal: color R=%d G=%d B=%d\n", player, r, g, b);
		}
	}
	else
	{
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player))
		{
			r = get_pcvar_num(cvar_survivor_color[0]);
			g = get_pcvar_num(cvar_survivor_color[1]);
			b = get_pcvar_num(cvar_survivor_color[2]);
		}
		else
		{
			r = get_pcvar_num(cvar_human_color[0]);
			g = get_pcvar_num(cvar_human_color[1]);
			b = get_pcvar_num(cvar_human_color[2]);
		}
	}
}

get_player_super_human_class(id)
{
	return (zp_class_survivor_get(id))
}