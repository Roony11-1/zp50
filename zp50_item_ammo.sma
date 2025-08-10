/*
[ZP] Extra Item: Recargas y Balas Infinitas
Solo para humanos
*/

#include <amxmodx>
#include <zp50_core>
#include <zp50_items>
#include <zp50_stocks>

#define ITEM_NAME_RELOADS "Recargas Infinitas"
#define ITEM_COST_RELOADS 12

#define ITEM_NAME_BULLETS "Balas Infinitas"
#define ITEM_COST_BULLETS 25

new g_ItemReloads, g_ItemBullets
new bool:g_HasReloads[33], bool:g_HasBullets[33]

public plugin_init()
{
    register_plugin("[ZP] Extra: Ammo Infinita", ZP_VERSION_STRING, "ricardo")

    g_ItemReloads = zp_items_register(ITEM_NAME_RELOADS, ITEM_COST_RELOADS)
    g_ItemBullets = zp_items_register(ITEM_NAME_BULLETS, ITEM_COST_BULLETS)

    register_event("DeathMsg", "onDeath", "a")
}

public plugin_natives()
{
    register_native("zp_has_recargas", "native_has_recargas")
    register_native("zp_has_balas", "native_has_balas")
}

// Limpieza al conectar/desconectar
public client_connect(id)       { reset_ammo_status(id); }
public client_disconnected(id)  { reset_ammo_status(id); }
public onDeath()                { reset_ammo_status(read_data(2)); }

// Resetear al curar o infectar
public zp_fw_core_cure_pre(id)
{
    if (zp_is_super_class(id))
        reset_ammo_status(id);
}
public zp_fw_core_infect_pre(id) { reset_ammo_status(id); }

// Mostrar solo para humanos no super
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if ((itemid == g_ItemReloads || itemid == g_ItemBullets) &&
        (zp_core_is_zombie(id) || zp_is_super_class(id)))
    {
        return ZP_ITEM_DONT_SHOW
    }
    return ZP_ITEM_AVAILABLE
}

// Asignar flags al comprar
public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if (itemid == g_ItemReloads)
    {
        g_HasReloads[id] = true
        client_print(id, print_chat, "Has comprado Recargas Infinitas.");
    }
    else if (itemid == g_ItemBullets)
    {
        g_HasBullets[id] = true
        client_print(id, print_chat, "Has comprado Balas Infinitas.");
    }
}

// Natives para consultar
public native_has_recargas(plugin_id, num_params)
{
    new id = get_param(1)
    return (id >= 1 && id <= 32) ? g_HasReloads[id] : false
}
public native_has_balas(plugin_id, num_params)
{
    new id = get_param(1)
    return (id >= 1 && id <= 32) ? g_HasBullets[id] : false
}

// Función común para limpiar
reset_ammo_status(id)
{
    g_HasReloads[id] = false;
    g_HasBullets[id] = false;
}