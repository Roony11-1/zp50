/*================================================================================
	
	--------------------------------
	-*- [ZP] Class: Zombie: Bulleteater -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <engine> // Necesario para constantes de botones
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_class_zombie>
#include <zp50_stocks>
#include <zp50_item_zombie_madness>

#define PLUGIN_NAME "[ZP] Class: Zombie: Bulleteater"
#define PLUGIN_AUTOR "ricardo"

#define ABILITY_TIME 7.0 // Tiempo en segundos
#define ABILITY_COOLDOWN (ABILITY_TIME + 15.0) // Tiempo de espera entre usos

#define SOUND_MAX_LENGTH 64

// Rage Zombie Attributes
new const zombieclass6_name[] = "Zombie Bulleteater"
new const zombieclass6_models[][] = { "zpcl_bulleater_v3" }
new const zombieclass1_info[] = "Se come las balas y se cura"
new const zombieclass1_shortinfo[] = "Maricón"
new const zombieclass6_clawmodels[][] = { "models/zombie_plague_chile/v_bulleater_claws_v2.mdl" }
new const sound_ability[][] = { "zombie_plague_chile/bulleater_growl.wav"}

new Array:g_sound_ability

#define TASK_ABILITY 505
#define ID_ABILITY (taskid - TASK_ABILITY)

#define TASK_GLOW_RESTORE 9000
#define ID_GLOW_RESTORE (taskid - TASK_GLOW_RESTORE)

new cvar_zombie_bulleteater_health, cvar_zombie_bulleteater_speed, cvar_zombie_bulleteater_gravity, cvar_zombie_bulleteater_knockback,
cvar_zombie_bulleteater_jump;

new bool:g_IsActived[33], bool:g_IsBullet[33], g_LastButton[33], Float:g_NextAbilityTime[33]
new g_bulleteater_max_health[33]

new g_ZombieClassID

public plugin_precache()
{
    register_plugin(PLUGIN_NAME, ZP_VERSION_STRING, PLUGIN_AUTOR)

	register_forward(FM_CmdStart, "fw_CmdStart")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack");

    // Registrar cvars
	cvar_zombie_bulleteater_health = register_cvar("zp_bulleteater_zombie_health", "3000");
	cvar_zombie_bulleteater_speed = register_cvar("zp_bulleteater_zombie_speed", "1.1");
	cvar_zombie_bulleteater_gravity = register_cvar("zp_bulleteater_zombie_gravity", "1");
	cvar_zombie_bulleteater_knockback = register_cvar("zp_bulleteater_zombie_knockback", "0.8");
	cvar_zombie_bulleteater_jump = register_cvar("zp_bulleteater_zombie_jump", "60");

	g_ZombieClassID = zp_class_zombie_register(
        zombieclass6_name,
        zombieclass1_info,
        get_pcvar_num(cvar_zombie_bulleteater_health),
        get_pcvar_float(cvar_zombie_bulleteater_speed),
        get_pcvar_float(cvar_zombie_bulleteater_gravity),
		zombieclass1_shortinfo,
		get_pcvar_num(cvar_zombie_bulleteater_jump));

	zp_class_zombie_register_kb(g_ZombieClassID, get_pcvar_float(cvar_zombie_bulleteater_knockback));

    new index;
    for (index = 0; index < sizeof zombieclass6_models; index++)
        zp_class_zombie_register_model(g_ZombieClassID, zombieclass6_models[index]);
    for (index = 0; index < sizeof zombieclass6_clawmodels; index++)
        zp_class_zombie_register_claw(g_ZombieClassID, zombieclass6_clawmodels[index]);

	g_sound_ability = ArrayCreate(SOUND_MAX_LENGTH, 1);

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
	set_native_filter("native_filter")
	register_native("zp_is_bulleteating", "native_zp_is_bulleteating")
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

// -----------------------------------------------------------------------------------------------------

public zp_fw_core_infect_post(id, attacker)
{
	reset_habilidad(id)
	// Rage Zombie glow
	if (zp_class_zombie_get_current(id) == g_ZombieClassID)
	{
		// Apply custom glow, unless nemesis
		if (!(zp_is_super_class(id)))
		{
			g_bulleteater_max_health[id] = get_pcvar_num(cvar_zombie_bulleteater_health)

			if (zp_core_is_first_zombie(id))
				g_bulleteater_max_health[id] = g_bulleteater_max_health[id]*2

			g_IsBullet[id] = true;
		}
	}
}

public zp_fw_core_infect(id, attacker)
{
		reset_habilidad(id)
}

public zp_fw_core_cure(id, attacker)
{
		reset_habilidad(id)
}

public client_disconnected(id)
{
		reset_habilidad(id)
}

// -------------------------------------------------------------------------------------------------

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	// Solo zombies normales (ni humanos ni super zombies)
	if (!g_IsBullet[id] || zp_is_super_class(id))
		return FMRES_IGNORED;

	if (!zp_core_is_zombie(id))
		return FMRES_IGNORED;

	static buttons;
	buttons = get_uc(uc_handle, UC_Buttons);

	// Lógica para jugador humano al presionar RELOAD
	if ((buttons & IN_RELOAD) && !(g_LastButton[id] & IN_RELOAD))
	{
		activar_habilidad(id);
	}

	g_LastButton[id] = buttons;

	return FMRES_IGNORED;
}

public activar_habilidad(id)
{
	if (!zp_core_is_zombie(id) || zp_is_super_class(id))
		return;

	new Float:current_time = get_gametime();

	if (g_IsActived[id])
	{
		new Float:remaining = (g_NextAbilityTime[id] - ABILITY_COOLDOWN) + ABILITY_TIME - current_time;
		if (remaining < 0.0) 
			remaining = 0.0; // Evitar negativos
		client_print(id, print_center, "Eres inmune a las balas por: %.1f segundos.", remaining);

		return;
	}

	if (current_time < g_NextAbilityTime[id])
	{
		new Float:remaining = g_NextAbilityTime[id] - current_time;
		client_print(id, print_center, "Habilidad disponible en: %.1f segundos.", remaining);

		return;
	}

	g_IsActived[id] = true;
	colocar_render_habilidad(id)
	client_print(id, print_center, "¡Eres inmune a las balas!");

	// Establecer cooldown para próximo uso
	g_NextAbilityTime[id] = current_time + ABILITY_COOLDOWN;

	set_task(ABILITY_TIME, "desactivar_habilidad", id + TASK_ABILITY)

	efectosHabilidad(id);
}

public desactivar_habilidad(taskid)
{
	new id = ID_ABILITY

	// Verificamos que el jugador esté conectado y sea depredador
	if (!is_user_connected(id) || zp_class_zombie_get_current(id) != g_ZombieClassID)
		return

	// Solo si está invisible
	if (g_IsActived[id])
	{
		g_IsActived[id] = false
		set_user_rendering(id) // Restaurar visual por defecto
		client_print(id, print_center, "Tu Habilidad acabó.")
	}
}

efectosHabilidad(id)
{
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_ability, random_num(0, ArraySize(g_sound_ability) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// ----------------------------------------------------------------------------------------

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!zp_core_is_zombie(victim))
		return HAM_IGNORED;

    // Evitar auto-daño o si el atacante no está vivo
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;

	new Float:current_time = get_gametime();

    // Filtrar solo daño de balas
    if (!(damage_type & DMG_BULLET))
        return HAM_IGNORED;

	if (g_IsBullet[victim])
	{
		// Lógica para bots
		if (is_user_bot(victim))
		{
			if (!g_IsActived[victim] && current_time >= g_NextAbilityTime[victim])
			{
				zp_try_activate_random(victim, 75.0, "activar_habilidad", PLUGIN_NAME);
			}
			return FMRES_IGNORED;
		}
	}

    return HAM_IGNORED;
}

// Bloquea el impacto visual de las balas (sangre, knockback, recoil)
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!zp_core_is_zombie(victim))
		return HAM_IGNORED;

    // Evitar auto-disparo o atacante inválido
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;

    // Filtrar solo daño de balas
    if (!(damage_type & DMG_BULLET))
        return HAM_IGNORED;

    // Solo si es nuestro zombie con habilidad activa
    if (g_IsBullet[victim] && g_IsActived[victim] && !zp_item_zombie_madness_get(victim))
    {
		HealPlayer(victim, floatround(damage))

		// Cambiar a glow rojo al recibir impacto
		set_user_rendering(victim, kRenderFxGlowShell, 255, 50, 100, kRenderNormal, 10)

		// Cancelar restauración previa si la hay
		remove_task(victim + TASK_GLOW_RESTORE)
		// Restaurar el glow morado tras 0.2 segundos
		set_task(0.2, "restore_bulleteater_glow", victim + TASK_GLOW_RESTORE)

		return HAM_SUPERCEDE; // Cancela sangre, knockback y recoil
    }

    return HAM_IGNORED;
}

// -----------------------------------------------------------------------------------------------------------------

// Función para restaurar el glow morado
public restore_bulleteater_glow(taskid)
{
	new id = ID_GLOW_RESTORE
	if (is_user_alive(id) && g_IsActived[id])
	{
		colocar_render_habilidad(id)
	}
}

// -----------------------------------------------------------------------------------------------------------------

reset_habilidad(id)
{
	g_IsActived[id] = false;
	g_NextAbilityTime[id] = 0;
	g_IsBullet[id] = false;

	if (!zp_is_super_class(id))
		set_user_rendering(id)              // Restaurar apariencia normal
	remove_task(id + TASK_ABILITY)        // Cancelar tarea si aún está activa
}

colocar_render_habilidad(id)
{
	set_user_rendering(id, kRenderFxGlowShell, 255, 50, 255, kRenderNormal, 10)
}

// ------------------------------------------------------------------------------------------------------------------

public native_zp_is_bulleteating(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}

	if (g_IsBullet[id])
		return g_IsActived[id];
	
	return false;
}

// ---------------------------------------------------------------------------------

// Función para curar con límite máximo de salud
public HealPlayer(id, amount)
{
    if (!is_user_alive(id))
        return;

    new current_health = get_user_health(id);
    new max_health = g_bulleteater_max_health[id]; // zombieMaxHealth debe estar bien definido y actualizado

    new new_health = current_health + amount;

    if (max_health > 0 && new_health > max_health)
        new_health = max_health;

    set_user_health(id, new_health);
}