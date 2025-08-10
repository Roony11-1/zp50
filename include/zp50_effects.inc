/**
 * Create a ScreenFadeIn effect.
 *
 * @param id            User id
 * @param segundos      Seconds of duration
 * @param r             Red value (0-255)
 * @param g             Green value (0-255)
 * @param b             Blue value (0-255)
 *
 */
native ScreenFadeIn(id, segundos, r, g, b);

/**
 * Create a ScreenFadeOut effect.
 *
 * @param id            User id
 * @param segundos      Seconds of duration
 * @param r             Red value (0-255)
 * @param g             Green value (0-255)
 * @param b             Blue value (0-255)
 *
 */
native ScreenFadeOut(id, segundos, r, g, b);

/**
 * Create a ScreenShake effect.
 *
 * @param id            User id
 * @param duracion      Duration in seconds
 * @param frecuencia    Frequency of the shake
 * @param amplitud     Amplitude (intensity) of the shake
 *
 */
native ScreenShake(id, duracion, frecuencia, amplitud);

/**
 * Envía un efecto de luz dinámica (DLight) en la posición del jugador.
 *
 * @param id        ID del jugador (client index)
 * @param r         Componente rojo (0-255)
 * @param g         Componente verde (0-255)
 * @param b         Componente azul (0-255)
 * @param life      Tiempo de vida en frames (generalmente en ticks)
 * @param radius    Radio de la luz (en unidades)
 * @param decay     Velocidad a la que la luz se desvanece
 */
native DLightId(x, y, z, r, g, b, life, radius, decay);