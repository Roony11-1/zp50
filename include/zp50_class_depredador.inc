#if defined _zp50_class_depredador_included
  #endinput
#endif
#define _zp50_class_depredador_included

#include <zp50_class_zombie>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_depredador
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_depredador
	#endif
#else
	#pragma library zp50_class_depredador
#endif


/**
 * Returns whether a player is a depredador
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_class_depredador_get(id)

/**
 * Forces a player to become a depredador
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_depredador_set(id)

/**
 * Returns number of alive depredador
 *
 * @return		depredador count.
 */
native zp_class_depredador_get_count()
