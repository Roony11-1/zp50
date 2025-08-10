#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_item_resortes>

public plugin_init()
{
    register_plugin("[ZP] No Fall Damage", ZP_VERSION_STRING, "ricardo");

    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage");
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
    // Validar jugador vivo y conectado
    if (!is_user_alive(victim))
        return HAM_IGNORED;

    // Si no es zombie y no tiene resortes → no bloquear
    if (!zp_core_is_zombie(victim) && !zp_get_resortes(victim))
        return HAM_IGNORED;

    // Bloquear daño por caída
    if (damagebits & DMG_FALL)
        return HAM_SUPERCEDE;

    return HAM_IGNORED;
}
