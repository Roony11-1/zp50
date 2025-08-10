#define ITEM_NAME "Armadura (100)"
#define ITEM_COST 0

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <zp50_items>
#include <zp50_core>
#include <zp50_stocks>
#include <zp50_class_human>

new g_ItemID
new const SOUND_ARMOR[] = "items/tr_kevlar.wav"

public plugin_init()
{
    register_plugin("[ZP] Item: Armadura", ZP_VERSION_STRING, "ricardo")
    g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
}

public plugin_precache()
{
    precache_sound(SOUND_ARMOR)
}

// Mostrar/ocultar ítem según condiciones
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return ZP_ITEM_AVAILABLE

    // Ocultar si es zombie o clase especial
    if (zp_core_is_zombie(id) || zp_is_super_class(id))
        return ZP_ITEM_DONT_SHOW

    return ZP_ITEM_AVAILABLE
}

// Dar armadura al jugador
public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return

    new maxArmorValue = get_max_armor(id)
    new currentArmor = get_user_armor(id)

    if (currentArmor < maxArmorValue)
    {
        set_user_armor(id, min(currentArmor + 100, maxArmorValue))
        emit_sound(id, CHAN_ITEM, SOUND_ARMOR, 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
    else
    {
        client_print(id, print_center, "Ya tienes la armadura completa")
    }
}

// Obtener armadura máxima
stock get_max_armor(id)
{
    return zp_class_human_get_max_armor(id, zp_class_human_get_current(id))
}