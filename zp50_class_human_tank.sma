/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Tank -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>

// Raptor Human Attributes
new const humanclass2_name[] = "Humano Tank"
new const humanclass2_info[] = "Bastante duro pero lento"
new const humanclass2_shortinfo[] = "Como una roca!"
new const humanclass2_models[][] = { "arctic" , "guerilla" , "leet" , "terror" , "gign" , "gsg9" , "sas" , "urban" }

new cvar_human_classic_health, cvar_human_classic_armor, cvar_human_classic_speed, cvar_human_classic_gravity;
new cvar_human_health, cvar_human_armor, cvar_human_speed, cvar_human_gravity;
new Float:g_human_health, g_human_armor, g_human_speed, g_human_gravity;

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Raptor", ZP_VERSION_STRING, "ZP Dev Team")

	// Registrar cvars
	cvar_human_classic_health = register_cvar("zp_classic_human_health", "100");
	cvar_human_classic_armor = register_cvar("zp_classic_human_armor", "100");
	cvar_human_classic_speed = register_cvar("zp_classic_human_speed", "1");
	cvar_human_classic_gravity = register_cvar("zp_classic_human_gravity", "1");

	cvar_human_health = register_cvar("zp_human_tank_health", "1.5");
	cvar_human_armor = register_cvar("zp_human_tank_armor", "1.5")
	cvar_human_speed = register_cvar("zp_human_tank_speed", "0.90");
	cvar_human_gravity = register_cvar("zp_human_tank_gravity", "1.10");

	// Obtener valores y registrar clase
	g_human_health = get_pcvar_num(cvar_human_classic_health) * get_pcvar_float(cvar_human_health);
	g_human_armor = get_pcvar_float(cvar_human_classic_armor) * get_pcvar_float(cvar_human_armor);
	g_human_speed = get_pcvar_float(cvar_human_classic_speed) * get_pcvar_float(cvar_human_speed);
	g_human_gravity = get_pcvar_float(cvar_human_classic_gravity) * get_pcvar_float(cvar_human_gravity);

	g_HumanClassID = zp_class_human_register(humanclass2_name, 
	humanclass2_info, 
	floatround(g_human_health), 
	floatround(g_human_armor), 
	g_human_speed, 
	g_human_gravity,
	humanclass2_shortinfo)

	new index
	for (index = 0; index < sizeof humanclass2_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass2_models[index])
}