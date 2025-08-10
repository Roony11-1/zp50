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
    register_native("zp_is_super_class", "isSuperClass", 1)
}

public isSuperClass(id)
{
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