#define ITEM_NAME "Resortes"
#define ITEM_COST 0
#define RESORTES_COUNT 75

#include <amxmodx>
#include <fakemeta>
#include <zp50_items>
#include <zp50_core>
#include <zp50_stocks>

new g_ItemID;
new bool:g_HasResortes[33];
new g_ResortesCount[33];
new g_LastButton[33];

public plugin_init()
{
    register_plugin("[ZP] Item: Resortes", ZP_VERSION_STRING, "ricardo");

    g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST);

    register_event("DeathMsg", "event_death", "a");
    register_forward(FM_CmdStart, "fw_CmdStart");
}

public plugin_natives()
{
    register_native("zp_get_resortes", "native_get_resortes");
}

//==================================================
// FUNCIONES DE ZP
//==================================================

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return ZP_ITEM_AVAILABLE;

    if (zp_core_is_zombie(id) || zp_is_super_class(id))
        return ZP_ITEM_DONT_SHOW;

    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return;

    g_HasResortes[id] = true;
    g_ResortesCount[id] += RESORTES_COUNT;
}

public zp_fw_core_cure_pre(id)
{
    if (zp_is_super_class(id))
        reset_resortes(id);
}

public zp_fw_core_infect_pre(id)
{
    reset_resortes(id);
}

//==================================================
// HOOKS Y EVENTOS
//==================================================

public client_connect(id)        { reset_resortes(id); }
public client_disconnected(id)   { reset_resortes(id); }

public event_death()
{
    new id = read_data(2);
    if (is_valid_player(id))
        reset_resortes(id);
}

public fw_CmdStart(id, uc_handle, seed)
{
    if (!is_valid_player_alive(id))
        return FMRES_IGNORED;

    if (!g_HasResortes[id])
        return FMRES_IGNORED;

    if (!(pev(id, pev_flags) & FL_ONGROUND))
        return FMRES_IGNORED;

    new buttons = get_uc(uc_handle, UC_Buttons);

    if ((buttons & IN_JUMP) && !(g_LastButton[id] & IN_JUMP))
        descontar_resorte(id);

    g_LastButton[id] = buttons;
    return FMRES_IGNORED;
}

//==================================================
// LÓGICA DEL ITEM
//==================================================

stock descontar_resorte(id)
{
    g_ResortesCount[id]--;

    if (g_ResortesCount[id] <= 0)
    {
        reset_resortes(id);
        client_print(id, print_center, "Te has quedado sin resortes");
        return;
    }

    client_print(id, print_center, "Te quedan %d resortes", g_ResortesCount[id]);
}

stock reset_resortes(id)
{
    g_HasResortes[id] = false;
    g_ResortesCount[id] = 0;
}

//==================================================
// NATIVES
//==================================================

public native_get_resortes(plugin_id, num_params)
{
    new id = get_param(1);
    if (!is_valid_player(id))
        return false;

    return g_HasResortes[id];
}

//==================================================
// UTILIDADES
//==================================================

stock bool:is_valid_player(id)
{
    return (id >= 1 && id <= 32 && is_user_connected(id));
}

stock bool:is_valid_player_alive(id)
{
    return (is_valid_player(id) && is_user_alive(id));
}