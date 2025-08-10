#include <amxmodx>
#include <fakemeta>
#include <zp50_core>

const UNIT_SECOND = (1<<12)

const FFADE_IN = 0x0001;
const FFADE_OUT = 0x0000;

new g_MsgScreenFade;
new g_MsgScreenShake;

public plugin_init()
{
    register_plugin("[ZP] Screen Effects", ZP_VERSION_STRING, "ricardo");
    
    g_MsgScreenFade = get_user_msgid("ScreenFade");
    g_MsgScreenShake = get_user_msgid("ScreenShake");
}

public plugin_natives()
{
    // Registrar natives para exportar
    register_native("ScreenFadeIn", "native_ScreenFadeIn");
    register_native("ScreenFadeOut", "native_ScreenFadeOut");
    register_native("ScreenShake", "native_ScreenShake");
    register_native("DLightId", "native_DLightId");
}

// Native para luz en la posicion del jugador
public native_DLightId(plugin_id, num_params)
{
    new x = get_param(1);
    new y = get_param(2);
    new z = get_param(3);
    new r = get_param(4);
    new g = get_param(5);
    new b = get_param(6);
    new life = get_param(7);
    new radius = get_param(8);
    new decay = get_param(9);

    new origin[3]
    origin[0] = x
    origin[1] = y
    origin[2] = z

    // Validar rangos 0-255
    r = (r < 0) ? 0 : (r > 255) ? 255 : r;
    g = (g < 0) ? 0 : (g > 255) ? 255 : g;
    b = (b < 0) ? 0 : (b > 255) ? 255 : b;

    life = (life < 0) ? 0 : (life > 255) ? 255 : life;
    radius = (radius < 0) ? 0 : (radius > 255) ? 255 : radius;
    decay = (decay < 0) ? 0 : (decay > 255) ? 255 : decay;

    message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_DLIGHT);      // TE id
    write_coord(origin[0]);      // x
    write_coord(origin[1]);      // y
    write_coord(origin[2]);      // z
    write_byte(radius);          // radius
    write_byte(r);               // r
    write_byte(g);               // g
    write_byte(b);               // b
    write_byte(life);            // life
    write_byte(decay);           // decay rate
    message_end();
}

// Native para fundido "fade in"
public native_ScreenFadeIn(plugin_id, num_params)
{
    new id = get_param(1)
    new segundos = get_param(2)
    new r = get_param(3)
    new g = get_param(4)
    new b = get_param(5)

    // Validar rangos 0-255
    r = (r < 0) ? 0 : (r > 255) ? 255 : r;
    g = (g < 0) ? 0 : (g > 255) ? 255 : g;
    b = (b < 0) ? 0 : (b > 255) ? 255 : b;

    message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id);
    write_short(UNIT_SECOND * segundos);
    write_short(0);
    write_short(FFADE_IN);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(255);
    message_end();
}

// Native para fundido "fade out"
public native_ScreenFadeOut(plugin_id, num_params)
{
    new id = get_param(1)
    new segundos = get_param(2)
    new r = get_param(3)
    new g = get_param(4)
    new b = get_param(5)

    // Validar rangos 0-255
    r = (r < 0) ? 0 : (r > 255) ? 255 : r;
    g = (g < 0) ? 0 : (g > 255) ? 255 : g;
    b = (b < 0) ? 0 : (b > 255) ? 255 : b;

    message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id);
    write_short(UNIT_SECOND * segundos);
    write_short(0);
    write_short(FFADE_OUT);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(255);
    message_end();
}

// Native para efecto temblor
public native_ScreenShake(plugin_id, num_params)
{
    new id = get_param(1)
    new duracion = get_param(2)
    new frecuencia = get_param(3)
    new amplitud = get_param(4)

    message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenShake, _, id);
    write_short(UNIT_SECOND * duracion);
    write_short(UNIT_SECOND * frecuencia);
    write_short(UNIT_SECOND * amplitud);
    message_end();
}
