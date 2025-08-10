/*================================================================================
	
	------------------------
	-*- [ZP] Human Armor -*-
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
#define LIBRARY_DEPREDADOR "zp50_class_depredador"
#include <zp50_class_depredador>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_class_human>
#include <zp50_stocks>
#include <zp50_gamemodes>

// CS Player PData Offsets (win32)
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod

// Some constants
const DMG_HEGRENADE = (1<<24)

// CS sounds
new const g_sound_armor_hit[] = "player/bhit_helmet-1.wav"

new cvar_human_armor_protect
new cvar_armor_protect_nemesis, cvar_survivor_armor_protect

public plugin_init()
{
	register_plugin("[ZP] Human Armor", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_human_armor_protect = register_cvar("zp_human_armor_protect", "1")
	
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_armor_protect_nemesis = register_cvar("zp_armor_protect_nemesis", "1")
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_survivor_armor_protect = register_cvar("zp_survivor_armor_protect", "1")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
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

public plugin_precache()
{
	precache_sound(g_sound_armor_hit)
}

public zp_fw_core_cure_post(id, attacker)
{
	if (zp_is_super_class(id))
		return;

	new Float:armor
	pev(id, pev_armorvalue, armor)

	new class_id = zp_class_human_get_current(id)
	new max_armor = zp_class_human_get_max_armor(id, class_id)

	if (is_user_bot(id))
	{
		set_pev(id, pev_armorvalue, 0.0)
		set_pev(id, pev_armorvalue, float(min(random_num(1, max_armor-(random_num(1, (max_armor/50)))), max_armor)))
	}
	else // No bots
	{
		if (armor > float(max_armor))
			set_pev(id, pev_armorvalue, float(max_armor))
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Solo aplicar protección de armadura si es una ronda de infección
	if (!zp_gamemodes_get_allow_infect())
		return HAM_IGNORED;

	if (zp_core_is_last_human(victim))
		return HAM_IGNORED;

	// Zombie atacando a humano
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Ignorar daño de HE grenade
		if (damage_type & DMG_HEGRENADE)
			return HAM_IGNORED;
		
		// ¿La armadura está habilitada?
		if (!get_pcvar_num(cvar_human_armor_protect))
			return HAM_IGNORED;

		// ¿Está atacando un Némesis?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && !get_pcvar_num(cvar_armor_protect_nemesis) && zp_class_nemesis_get(attacker))
			return HAM_IGNORED;

		// ¿Está atacando un Depredador?
		if (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && !get_pcvar_num(cvar_armor_protect_nemesis) && zp_class_depredador_get(attacker))
			return HAM_IGNORED;

		// ¿La víctima es sobreviviente?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && !get_pcvar_num(cvar_survivor_armor_protect) && zp_class_survivor_get(victim))
			return HAM_IGNORED;

		// Obtener armadura del humano
		static Float:armor
		pev(victim, pev_armorvalue, armor)

		if (armor > 0.0)
		{
			emit_sound(victim, CHAN_BODY, g_sound_armor_hit, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			if (armor - damage > 0.0)
			{
				set_pev(victim, pev_armorvalue, armor - damage)
			}
			else
			{
				// Armadura agotada: dejar en 0 y permitir infección en el siguiente ataque
				cs_set_user_armor(victim, 0, CS_ARMOR_NONE)
			}

			// No aplicar daño, solo reducir armadura
			set_pdata_float(victim, OFFSET_PAINSHOCK, 0.5)
			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}