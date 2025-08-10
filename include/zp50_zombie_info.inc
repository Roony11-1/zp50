#if defined _zp50_zombie_info_included
  #endinput
#endif
#define _zp50_zombie_info_included

// Esto va fuera de cualquier función o stock
const ZOMBIE_STATS_NAMES[][] = {
	"Vida", "Velocidad", "Gravedad", "Knockback"
}

stock get_attribute_modifier(Float:multiplier, symbol[6])
{
    new diff = floatround((multiplier - 1.0) * 4.0);

    if (diff > 0)
    {
        for (new i = 0; i < diff && i < charsmax(symbol); i++)
            symbol[i] = '+';
        symbol[diff] = 0;
    }
    else if (diff < 0)
    {
        diff = -diff;
        for (new i = 0; i < diff && i < charsmax(symbol); i++)
            symbol[i] = '-';
        symbol[diff] = 0;
    }
    else
        symbol[0] = 0;
}

stock get_dynamic_info_from_multipliers(Float:hp, Float:spd, Float:gvt, Float:kb, info[128])
{
    info[0] = 0;

    new symbol[6];
    const Float:multipliers[4] = { hp, spd, gvt, kb };

    for (new i = 0; i < 4; i++)
    {
        get_attribute_modifier(multipliers[i], symbol);

        if (symbol[0])
        {
            format(info, charsmax(info), "%s%s%s ", info, ZOMBIE_STATS_NAMES[i], symbol);
        }
    }
}
