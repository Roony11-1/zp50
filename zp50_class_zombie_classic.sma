/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Classic Zombie"
new const zombieclass1_info[] = "El más normalito de todos"
new const zombieclass1_shortinfo[] = "Balanceado"
new const zombieclass1_models[][] = { "zombie_source" }
new const zombieclass1_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }

new cvar_zombie_classic_health, cvar_zombie_classic_speed, cvar_zombie_classic_gravity, cvar_zombie_classic_knockback, cvar_zombie_classic_jump

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Classic", ZP_VERSION_STRING, "ZP Dev Team")

	// Health (int)
	cvar_zombie_classic_health = register_cvar("zp_classic_zombie_health", "2250")

	// Speed (float)
	cvar_zombie_classic_speed = register_cvar("zp_classic_zombie_speed", "0.95")

	// Gravity (float)
	cvar_zombie_classic_gravity = register_cvar("zp_classic_zombie_gravity", "1")

	// Knockback (float)
	cvar_zombie_classic_knockback = register_cvar("zp_classic_zombie_knockback", "1")

	cvar_zombie_classic_jump = register_cvar("zp_classic_zombie_jump", "0")
	
	new index

	g_ZombieClassID = zp_class_zombie_register(
	zombieclass1_name,
	zombieclass1_info,
	get_pcvar_num(cvar_zombie_classic_health),
	get_pcvar_float(cvar_zombie_classic_speed),
	get_pcvar_float(cvar_zombie_classic_gravity),
	zombieclass1_shortinfo,
	get_pcvar_num(cvar_zombie_classic_jump))

	zp_class_zombie_register_kb(g_ZombieClassID, float(get_pcvar_num(cvar_zombie_classic_knockback)))

	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
}
