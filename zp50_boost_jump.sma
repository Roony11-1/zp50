#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <zp50_core>           // Para identificar zombies y humanos
#include <zp50_class_zombie>
#include <zp50_stocks>
#include <zp50_item_resortes>

#define CONSTANTE_SALTO 270.0

new g_LastButton[33];        // Estado previo de botón salto

public plugin_init()
{
    register_plugin("[ZP] Boost Jump System", ZP_VERSION_STRING, "ricardo");
    register_forward(FM_CmdStart, "fw_CmdStart");
}

public fw_CmdStart(id, uc_handle, seed)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return FMRES_IGNORED;

    if (zp_is_super_class(id)) // Superclase no puede saltar con boost
        return FMRES_IGNORED;

    if (!(zp_core_is_zombie(id) || zp_get_resortes(id)))
        return FMRES_IGNORED;

    if (!(pev(id, pev_flags) & FL_ONGROUND))
        return FMRES_IGNORED;

    new buttons = get_uc(uc_handle, UC_Buttons);

    if ((buttons & IN_JUMP) && !(g_LastButton[id] & IN_JUMP))
        aplicarSalto(id);

    g_LastButton[id] = buttons;

    return FMRES_IGNORED;
}

public aplicarSalto(id)
{
    new Float:vel[3];
    entity_get_vector(id, EV_VEC_velocity, vel);

    vel[2] += obtener_potencia_salto(id);

    entity_set_vector(id, EV_VEC_velocity, vel);
}


stock Float:obtener_potencia_salto(id)
{
    new Float:potencia = CONSTANTE_SALTO;

    // Ejemplo: si es zombie, sumar su potencia extra
    if (zp_core_is_zombie(id))
    {
        potencia += zp_class_zombie_get_jump(id, zp_class_zombie_get_current(id));
    }
    else // Humano
    {
        if (zp_get_resortes(id))
            potencia += 150.0;
    }

    // Aquí puedes agregar más condiciones, como otros ítems, perks, estados, etc.

    return potencia;
}