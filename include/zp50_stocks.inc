native bool:zp_is_super_class(id)

/**
 * Intenta activar una habilidad aleatoria llamando a una función
 * si se cumple la probabilidad indicada.
 *
 * @param prob            Probabilidad de activación (0.0 – 100.0)
 * @param function        Nombre de la función a ejecutar (debe aceptar: id, Float:current_time)
 * @param plugin          Nombre del plugin que tiene function
 * @param id              Jugador objetivo
 * @param current_time    Tiempo actual (usa get_gametime() o similar)
 *
 * @return true si la habilidad fue activada, false si no.
 */
native zp_try_activate_random(id, Float:prob, const function[], const plugin[], const any:parameter[] = "");