#include <amxmodx>
#include <zp50_core>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DEPREDADOR "zp50_class_depredador"
#include <zp50_class_depredador>

public plugin_init()
{
    register_plugin("[ZP] Stocks", ZP_VERSION_STRING, "ricardo");
}

public plugin_natives()
{
    register_native("zp_is_super_class", "isSuperClass")
    register_native("zp_try_activate_random", "native_zp_try_activate_random")
}

// Super Class Check

public isSuperClass(iplugin_id, num_params)
{
    new id = get_param(1)

    if (zp_core_is_zombie(id))
        return superZombie(id);

    return superHuman(id);
}

superZombie(id)
{
    return ((LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id)) || (LibraryExists(LIBRARY_DEPREDADOR, LibType_Library) && zp_class_depredador_get(id)));
}

superHuman(id)
{
    return (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id));
}

// ---------- Execute random time function ----------

public native_zp_try_activate_random(plugin_id, num_params)
{
    new id = get_param(1);
    new Float:prob = get_param_f(2);

    static function_name[64];
    get_string(3, function_name, charsmax(function_name));

    static plugin_name[64];
    get_string(4, plugin_name, charsmax(plugin_name));

    // Parámetro opcional: current_time
    new Float:current_time = -1.0; // valor por defecto
    if (num_params >= 5)
        current_time = get_param_f(5); // si se pasó, usarlo

    // Llamada al stock
    try_activate_random(id, function_name, plugin_name, prob, current_time);
}

stock try_activate_random(id, const function_name[], const plugin_name[], Float:prob, Float:current_time)
{
    new plugin = is_plugin_loaded(plugin_name);
    if (plugin == -1) return;

    new func = get_func_id(function_name, plugin);
    if (func == -1) return;

    // Probabilidad
    if (random_float(0.0, 100.0) <= prob)
    {
        callfunc_begin_i(func, plugin);  // Busca la función en el plugin indicado
        callfunc_push_int(id);
        if (current_time != -1)
            callfunc_push_float(current_time);
        callfunc_end();
    }
}