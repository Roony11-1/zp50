#include <amxmodx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <zp50_core>
#include <zp50_items>
#include <zp50_stocks>
#include <zp50_effects>
#include <zp50_color_const>

#define ITEM_NAME "Pulse Shock"
#define ITEM_COST 0
#define PULSE_RADIUS 1275
#define PULSE_EFFECT_RADIUS (PULSE_RADIUS - 525)
#define PULSE_DURATION 7
#define PULSE_USES 5

#define TASK_GLOW 105
#define ID_GLOW (taskid - TASK_GLOW)

new g_ItemID;
new const g_sound_pulse[] = "zombie_plague_chile/pulse_shock.wav";
new sprite_beam, cvar_pulse_color[3];

new bool:g_HasPulse[33];
new g_PulseCount[33];

public plugin_init()
{
    register_plugin("[ZP] Item: Pulse Shock", ZP_VERSION_STRING, "ricardo");
    g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST);

    // CVARs para color
    cvar_pulse_color[0] = ZP_COLOR_PULSES_R;
    cvar_pulse_color[1] = ZP_COLOR_PULSES_G;
    cvar_pulse_color[2] = ZP_COLOR_PULSES_B;

    register_event("DeathMsg", "event_death", "a");
    register_clcmd("pulse", "pulsecmd");
}

public plugin_precache()
{
    sprite_beam = precache_model("sprites/laserbeam.spr");
    precache_sound(g_sound_pulse);
}

//==================================================
// EVENTOS DE ZP
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

    g_HasPulse[id] = true;
    g_PulseCount[id] += PULSE_USES;
}

public zp_fw_core_infect_pre(id)      { reset_pulse(id); }
public zp_fw_core_cure_pre(id)        { if (zp_is_super_class(id)) reset_pulse(id); }
public client_connect(id)             { reset_pulse(id); }
public client_disconnected(id)        { reset_pulse(id); }
public event_death()                  { reset_pulse(read_data(2)); }

//==================================================
// COMANDOS
//==================================================

public pulsecmd(id)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    if (!g_HasPulse[id])
        return PLUGIN_HANDLED;

    efectoPulse(id);
    restar_usos(id);

    return PLUGIN_HANDLED;
}

//==================================================
// LÓGICA DE USOS
//==================================================

stock restar_usos(id)
{
    g_PulseCount[id]--;
    client_print(id, print_center, "Has usado un Pulse Shock. Te quedan: %d", g_PulseCount[id]);

    if (g_PulseCount[id] <= 0)
    {
        reset_pulse(id);
        client_print(id, print_center, "Te has quedado sin usos de Pulse Shock");
    }
}

stock reset_pulse(id)
{
    g_HasPulse[id] = false;
    g_PulseCount[id] = 0;
}

//==================================================
// EFECTO PRINCIPAL
//==================================================

stock efectoPulse(id)
{
    new origin[3];
    get_user_origin(id, origin);

    new r = get_pcvar_num(cvar_pulse_color[0]);
    new g = get_pcvar_num(cvar_pulse_color[1]);
    new b = get_pcvar_num(cvar_pulse_color[2]);

    apply_knockback_and_fade(id, origin, r, g, b);
    show_beam_ring(origin, r, g, b);
    show_dynamic_light(origin, r, g, b);
    apply_player_glow(id, r, g, b);
    emit_sound(id, CHAN_ITEM, g_sound_pulse, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

//==================================================
// EFECTOS DE IMPACTO
//==================================================

stock apply_knockback_and_fade(id, origin[3], r, g, b)
{
    for (new i = 1; i <= 32; i++)
    {
        if (!is_user_alive(i) || !zp_core_is_zombie(i) || i == id)
            continue;

        new target_origin[3];
        get_user_origin(i, target_origin);

        if (get_distance(origin, target_origin) > PULSE_EFFECT_RADIUS)
            continue;

        new Float:velocity[3];
        velocity[0] = float(target_origin[0] - origin[0]);
        velocity[1] = float(target_origin[1] - origin[1]);
        velocity[2] = 0.0;

        new Float:length = floatsqroot(velocity[0]*velocity[0] + velocity[1]*velocity[1]);
        if (length == 0.0)
            continue;

        const Float:knockback_power = 2000.0;
        velocity[0] = velocity[0] / length * knockback_power;
        velocity[1] = velocity[1] / length * knockback_power;
        velocity[2] = 1000.0;

        entity_set_vector(i, EV_VEC_velocity, velocity);
        ScreenFadeOut(i, PULSE_DURATION, r, g, b);

        new Float:punch[3];
        punch[0] = random_float(-30.0, 30.0);  // pitch
        punch[1] = random_float(-60.0, 60.0);  // yaw
        punch[2] = random_float(-15.0, 15.0);  // roll

        set_pev(i, pev_punchangle, punch);
    }
}

//==================================================
// EFECTOS VISUALES
//==================================================

stock show_beam_ring(origin[3], r, g, b)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMTORUS);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + PULSE_RADIUS + 500);
    write_short(sprite_beam);
    write_byte(0);
    write_byte(0);
    write_byte(7);
    write_byte(10);
    write_byte(0);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(200);
    write_byte(0);
    message_end();
}

stock show_dynamic_light(origin[3], r, g, b)
{
    DLightId(origin[0], origin[1], origin[2], r, g, b, 2, 10, 0);
}

stock apply_player_glow(id, r, g, b)
{
    set_user_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 25);
    set_task(0.2, "removeGlow", id + TASK_GLOW);
}

public removeGlow(taskid)
{
    new id = ID_GLOW;
    if (is_user_connected(id))
        set_user_rendering(id);
}