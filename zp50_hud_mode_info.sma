#include < amxmodx >
#include < zp50_gamemodes >

new g_desc[128];
new r, g, b

new cvar_zombie_color[3]
new cvar_human_color[3]
new cvar_nemesis_color[3], cvar_depredador_color[3]
new cvar_survivor_color[3]

public plugin_init()
{
    register_plugin("[ZP] Game Modes Display", "1.0", "funkyfresh95");
    
    register_event("TextMsg", "event_restart", "a", "2&#Game_C", "2&#Game_w");
    register_event("HLTV", "event_hltv", "a", "1=0", "2=0");

	// Zombie
    cvar_zombie_color[0] = register_cvar("zp_zombie_color_R", "0")
    cvar_zombie_color[1] = register_cvar("zp_zombie_color_G", "150")
    cvar_zombie_color[2] = register_cvar("zp_zombie_color_B", "0")
	// Human
    cvar_human_color[0] = register_cvar("zp_human_color_R", "0")
    cvar_human_color[1] = register_cvar("zp_human_color_G", "150")
    cvar_human_color[2] = register_cvar("zp_human_color_B", "150")
	
    cvar_nemesis_color[0] = register_cvar("zp_nemesis_color_R", "150")
    cvar_nemesis_color[1] = register_cvar("zp_nemesis_color_G", "0")
    cvar_nemesis_color[2] = register_cvar("zp_nemesis_color_B", "0")

    cvar_depredador_color[0] = register_cvar("zp_depredador_color_R", "150")
    cvar_depredador_color[1] = register_cvar("zp_depredador_color_G", "0")
    cvar_depredador_color[2] = register_cvar("zp_depredador_color_B", "0")
	
    cvar_survivor_color[0] = register_cvar("zp_survivor_color_R", "0")
    cvar_survivor_color[1] = register_cvar("zp_survivor_color_G", "0")
    cvar_survivor_color[2] = register_cvar("zp_survivor_color_B", "150")
    
    formatex(g_desc, charsmax(g_desc), "Iniciando Modalidad...");
    r = 255
    g = 255
    b = 255
}

public client_putinserver(id)
{
    if(!is_user_bot(id))
        set_task(1.0, "task_show_info", id + 100, _, _, "b");
}

public client_disconnected(id)
    remove_task(id + 100);

public event_hltv()
{
    formatex(g_desc, charsmax(g_desc), "Iniciando Modalidad...");
    r = 255
    g = 255
    b = 255
}

public event_restart()
{
    formatex(g_desc, charsmax(g_desc), "Iniciando Modalidad...");
    r = 255
    g = 255
    b = 255
}
    
public zp_fw_gamemodes_start(game_mode_id)
{
    new name[32];

    switch (game_mode_id)
    {
        case 0:
        {
            formatex(name, sizeof(name), "Infección");
            r = get_pcvar_num(cvar_zombie_color[0])
            g = get_pcvar_num(cvar_zombie_color[1])
            b = get_pcvar_num(cvar_zombie_color[2])
        }
        case 1:
        {
            formatex(name, sizeof(name), "Infección Múltiple");
            r = 200
            g = 50
            b = 0
        }
        case 2:
        {
            formatex(name, sizeof(name), "Swarm");
            r = 100
            g = 255
            b = 100
        }
        case 3:
        {
            formatex(name, sizeof(name), "Nemesis");
            r = get_pcvar_num(cvar_nemesis_color[0])
            g = get_pcvar_num(cvar_nemesis_color[1])
            b = get_pcvar_num(cvar_nemesis_color[2])
        }
        case 4:
        {
            formatex(name, sizeof(name), "Depredador");
            r = get_pcvar_num(cvar_depredador_color[0])
            g = get_pcvar_num(cvar_depredador_color[1])
            b = get_pcvar_num(cvar_depredador_color[2])
        }
        case 5:
        {
            formatex(name, sizeof(name), "Survivor");
            r = get_pcvar_num(cvar_survivor_color[0])
            g = get_pcvar_num(cvar_survivor_color[1])
            b = get_pcvar_num(cvar_survivor_color[2])
        }
        case 6:
        {
            formatex(name, sizeof(name), "Plague");
            r = 0
            g = 50
            b = 200
        }
        case 7:
        {
            formatex(name, sizeof(name), "Armageddon");
            r = 255
            g = 50
            b = 255
        }
        case 8:
        {
            formatex(name, sizeof(name), "Sobrevivir");
            r = 20
            g = 255
            b = 255
        }
        default:
        {
            formatex(name, sizeof(name), "Desconocido");
            r = 255
            g = 255
            b = 255
        }
    }

    formatex(g_desc, charsmax(g_desc), "Modo Actual: Modo %s", name);
}

public zp_fw_gamemodes_end(game_mode_id)
{
    formatex(g_desc, charsmax(g_desc), "Modalidad Terminada");
    r = 35
    g = 255
    b = 255
}

public task_show_info(taskid)
{
    static szMsg[128]
    copy(szMsg, charsmax(szMsg), g_desc);
    set_hudmessage(r, g, b, -1.0, 0.0, 2, 0.0, 1.0, 0.0, 0.0, -1);
    show_dhudmessage(0, szMsg)
} 