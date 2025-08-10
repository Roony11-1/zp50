/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Classic -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>

// Classic Human Attributes
new const humanclass1_name[] = "Humano Balanceado"
new const humanclass1_info[] = "No destaca en nada"
new const humanclass1_shortinfo[] = "Clasico"
new const humanclass1_models[][] = { "arctic" , "guerilla" , "leet" , "terror" , "gign" , "gsg9" , "sas" , "urban" }
const humanclass1_health = 100
const humanclass1_maxarmor = 100
const Float:humanclass1_speed = 1.0
const Float:humanclass1_gravity = 1.0

new cvar_human_classic_health, cvar_human_classic_armor, cvar_human_classic_speed, cvar_human_classic_gravity

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Classic", ZP_VERSION_STRING, "ZP Dev Team")

	// Health (int)
	cvar_human_classic_health = register_cvar("zp_classic_human_health", "100")

	// Armor (int)
	cvar_human_classic_armor = register_cvar("zp_classic_human_armor", "100")

	// Speed (float)
	cvar_human_classic_speed = register_cvar("zp_classic_human_speed", "1")

	// Gravity (float)
	cvar_human_classic_gravity = register_cvar("zp_classic_human_gravity", "1")

	g_HumanClassID = zp_class_human_register(humanclass1_name, 
	humanclass1_info, 
	get_pcvar_num(cvar_human_classic_health), 
	get_pcvar_num(cvar_human_classic_armor), 
	get_pcvar_float(cvar_human_classic_speed), 
	get_pcvar_float(cvar_human_classic_gravity),
	humanclass1_shortinfo)

	new index
	for (index = 0; index < sizeof humanclass1_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass1_models[index])
}
