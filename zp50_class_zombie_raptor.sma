/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Zombie: Raptor -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

new const zombieclass2_name[] = "Raptor Zombie";
new const zombieclass2_models[][] = { "zombie_source" };
new const zombieclass1_info[] = "Muy rápido pero frágil"
new const zombieclass1_shortinfo[] = "Rápido"
new const zombieclass2_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" };

new cvar_zombie_classic_health, cvar_zombie_classic_speed, cvar_zombie_classic_gravity, cvar_zombie_classic_knockback;
new cvar_zombie_health, cvar_zombie_speed, cvar_zombie_gravity, cvar_zombie_knockback, cvar_zombie_jump;
new Float:g_zombie_health, g_zombie_speed, g_zombie_gravity, g_zombie_knockback;

new g_ZombieClassID;

public plugin_precache()
{
    register_plugin("[ZP] Class: Zombie: Raptor", ZP_VERSION_STRING, "ZP Dev Team")

    // Registrar cvars
    cvar_zombie_classic_health = register_cvar("zp_classic_zombie_health", "2250");
    cvar_zombie_classic_speed = register_cvar("zp_classic_zombie_speed", "0.95");
    cvar_zombie_classic_gravity = register_cvar("zp_classic_zombie_gravity", "1");
    cvar_zombie_classic_knockback = register_cvar("zp_classic_zombie_knockback", "1");

    cvar_zombie_health = register_cvar("zp_zombie_raptor_health", "0.5");
    cvar_zombie_speed = register_cvar("zp_zombie_raptor_speed", "1.25");
    cvar_zombie_gravity = register_cvar("zp_zombie_raptor_gravity", "1");
    cvar_zombie_knockback = register_cvar("zp_zombie_raptor_knockback", "1.5");
    cvar_zombie_jump = register_cvar("zp_raptor_zombie_jump", "0")

    // Obtener valores y registrar clase
    g_zombie_health = get_pcvar_num(cvar_zombie_classic_health) * get_pcvar_float(cvar_zombie_health);
    g_zombie_speed = get_pcvar_float(cvar_zombie_classic_speed) * get_pcvar_float(cvar_zombie_speed);
    g_zombie_gravity = get_pcvar_float(cvar_zombie_classic_gravity) * get_pcvar_float(cvar_zombie_gravity);
    g_zombie_knockback = get_pcvar_float(cvar_zombie_classic_knockback) * get_pcvar_float(cvar_zombie_knockback);

    g_ZombieClassID = zp_class_zombie_register(
        zombieclass2_name,
        zombieclass1_info,
        floatround(g_zombie_health),
        g_zombie_speed,
        g_zombie_gravity,
		zombieclass1_shortinfo,
        get_pcvar_num(cvar_zombie_jump)
    );

    zp_class_zombie_register_kb(g_ZombieClassID, g_zombie_knockback);

    new index;
    for (index = 0; index < sizeof zombieclass2_models; index++)
        zp_class_zombie_register_model(g_ZombieClassID, zombieclass2_models[index]);
    for (index = 0; index < sizeof zombieclass2_clawmodels; index++)
        zp_class_zombie_register_claw(g_ZombieClassID, zombieclass2_clawmodels[index]);
}