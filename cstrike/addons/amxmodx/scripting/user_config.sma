#include <amxmodx>
#include <amxmisc>
#include <adv_vault>

new const sz_commands[][] = {
	"cl_backspeed",
	"cl_cmdbackup",
	"cl_cmdrate",
	"cl_corpsestay",
	"cl_crosshair_color",
	"cl_crosshair_size",
	"cl_crosshair_translucent",
	"cl_dlmax",
	"cl_download_ingame",
	"cl_dynamiccrosshair",
	"cl_forwardspeed",
	"cl_himodels"
}

new const sz_commands2[][] = {
	"cl_idealpitchscale",
	"cl_lc",
	"cl_logocolor",
	"cl_logofile",
	"cl_lw",
	"cl_minmodels",
	"cl_mousegrab",
	"cl_radartype",
	"cl_righthand",
	"cl_sidespeed",
	"cl_timeout",
	"cl_updaterate",
	"fps_max",
	"m_mousethread_sleep",
	"sensitivity"
}

new const sz_setinfo[][] = {
	"_cl_autowepswitch",
	"bottomcolor",
	"cl_dlmax",
	"cl_lc",
	"cl_lw",
	"cl_updaterate",
	"model",
	"topcolor",
	"_vgui_menus",
	"_ah",
	"_ndmh",
	"_ndmf",
	"_ndms",
	"_pw",
	"rate"
}

const ADMIN_FLAG = ADMIN_RCON
const ADMIN_PROTECT = ADMIN_BAN
const ADMIN_SAVE = ADMIN_RCON
new const sz_prefix[] = "[SUC]"

// ADMIN_FLAG FLAG para poder ver el setinfo de los jugadores, default ADMIN_RCON.
// ADMIN_PROTECT FLAG para los admines que esten protegidos si la cvar suc_protect esta activada.
// ADMIN_SAVE FLAG para los admines que puedan administrar los datos guardados.
// suc_protect protección a los admines para que no obtengan su setinfo, default: 1 (activado), 0 para desactivar.
// suc_enable las funciones del plugin se pueden usar, default: 1 (activado), 0 para desactivar.
// suc_vault activa el guardado de las configuraciones, defualt: 1 (activado), 0 para desactivar.
// sz_prefix, prefijo para los mensajes en el chat

// a partir de acá, no me hago responsable por las modificaciones.

new g_menu[200], g_maxplayers, g_msgSayText, g_conectado, g_bot, g_elegido[33][32], g_store_id[33]
new g_protect, g_activado, g_guardado

enum {
    NOMBRE_JUGADOR = 0,
	CONFIGURACION,
	CONFIGURACION2,
    MAX_CAMPOS
}

new g_vault, g_campos[MAX_CAMPOS], g_configuracion[33][1536], motd[1536], g_configuracion2[33][1536]

#define MarkBit(%1,%2) ( %1 |= ( 1 << ( %2 & 31 ) ) );
#define ClearBit(%1,%2) ( %1 &= ~ ( 1 << ( %2 & 31 ) ) );
#define IsBit(%1,%2) ( %1 & ( 1 << ( %2 & 31 ) ) )

public plugin_init(){
	register_plugin("Show User Config", "1.1", "Roccoxx")	
	
	register_clcmd("say /configs", "show_menu_players")
	register_clcmd("say /save", "show_menu_vault", ADMIN_SAVE)
	register_concmd("get_configs", "check_config", _, "<Nombre>")
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
	
	g_protect = register_cvar("suc_protect", "1")
	g_activado = register_cvar("suc_enable", "1")
	g_guardado = register_cvar("suc_vault", "1")
	
	g_vault = adv_vault_open("setinfo_pl", true)
	g_campos[NOMBRE_JUGADOR] = adv_vault_register_field(g_vault, "Nick", DATATYPE_STRING, 32)
	g_campos[CONFIGURACION] = adv_vault_register_field(g_vault, "Config", DATATYPE_STRING, 1536)
	g_campos[CONFIGURACION2] = adv_vault_register_field(g_vault, "Config2", DATATYPE_STRING, 1536)
	adv_vault_init(g_vault)
}

public client_putinserver(id){
	MarkBit(g_conectado, id)
	
	if(is_user_bot(id)) MarkBit(g_bot, id)
}

public client_disconnect(id){
	ClearBit(g_conectado, id)
	ClearBit(g_bot, id)
}

public show_menu_players(iClient){
	if(get_pcvar_num(g_activado) < 1){
		suc_print_color(iClient, "^x04%s^x01 El plugin se encuentra^x03 desactivado!", sz_prefix)
		return PLUGIN_HANDLED
	}
	
	new menu = menu_create("\y[\rSelecciona un jugador\y]", "menu_players")
	
	new name[32], pos[3]
	
	for(new i = 1; i <= g_maxplayers; i++){
		if(!IsBit(g_conectado, i)) continue;
		
		num_to_str(i, pos, charsmax(pos))
		get_user_name(i, name, charsmax(name))
		menu_additem(menu, name, pos)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "\rVolver")
	menu_setprop(menu, MPROP_NEXTNAME, "\rSiguiente")
	menu_setprop(menu, MPROP_EXITNAME, "\rSalir")
	
	menu_display(iClient,menu)
	return PLUGIN_HANDLED
}

public menu_players(iClient, menu, item){
	if(item == MENU_EXIT || get_pcvar_num(g_activado) < 1){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static player; player = item+1
	
	if(!player){
		suc_print_color(iClient, "^x04%s^x01 Jugador No Encontrado!", sz_prefix)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(IsBit(g_bot, player)){
		suc_print_color(iClient, "^x04%s^x01 No podes obtener la configuración de un^x03 BOT!", sz_prefix)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new name[32]
	get_user_name(player, name, charsmax(name))
	
	menu_destroy(menu)
	show_menu_configs(iClient, name)
	return PLUGIN_HANDLED
}

public check_config(iClient, sad, asfa){
	if(get_pcvar_num(g_activado) < 1){
		console_print(iClient, "El plugin se encuentra desactivado")
		return PLUGIN_HANDLED
	}
	
	new arg[32]; read_argv(1 , arg , 31)
	new player = cmd_target(iClient, arg, 1)
	
	if(!player){
		console_print(iClient, "No Existe Ningun Jugador Con ese Nombre")
		return PLUGIN_HANDLED
	}
	
	if(IsBit(g_bot, player)){
		console_print(iClient, "No podes obtener la configuración de un BOT")
		return PLUGIN_HANDLED
	}
	
	new name[32]; get_user_name(player, name, charsmax(name))

	show_menu_configs(iClient, name)
	return PLUGIN_HANDLED
}

public show_menu_configs(iClient, const arg[]){
	copy(g_elegido[iClient], charsmax(g_elegido[]), arg)
	
	formatex(g_menu, charsmax(g_menu), "\y[\rMenu Configuraciones\y]^n\wJugador Seleccionado: \d%s", arg)
	new menu = menu_create(g_menu, "menu_configs")
	
	menu_additem(menu, "Ver Configuraciones", "1")
	menu_additem(menu, "Ver Setinfo", "2", ADMIN_FLAG)
	
	if(get_pcvar_num(g_guardado) >= 1){
		if(adv_vault_get_prepare(g_vault, _, g_elegido[iClient])){
			menu_additem(menu, "Actualizar Setinfo en el Servidor", "3", ADMIN_SAVE)
			menu_additem(menu, "Ver Configuraciones Previas", "4", ADMIN_SAVE)
			menu_additem(menu, "Borrar Datos Guardados", "5", ADMIN_SAVE)
		}
		else menu_additem(menu, "Guardar Setinfo en el Servidor", "3", ADMIN_SAVE)
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "\rSalir")
	menu_display(iClient, menu)
}

public menu_configs(iClient, menu, item){
	if(item == MENU_EXIT || get_pcvar_num(g_activado) < 1){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new player = get_user_index(g_elegido[iClient])
	
	if(!IsBit(g_conectado, player)){
		suc_print_color(iClient, "^x04%s^x01 Jugador No Encontrado!", sz_prefix)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new name[32]
	get_user_name(iClient, name, charsmax(name))
	
	switch(item){
		case 0:{
			g_store_id[player] = iClient
			
			for(new i; i < sizeof(sz_commands); i++) query_client_cvar(player, sz_commands[i], "check_command")
			for(new i; i < sizeof(sz_commands2); i++) query_client_cvar(player, sz_commands2[i], "check_command")
			
			suc_print_color(iClient, "^x04%s^x01 Revisa Tu^x03 Consola!", sz_prefix)
			suc_print_color(player, "^x04%s^x01 Atención: El Jugador^x03 %s^x01 Ha mirado tus^x03 configuraciones!", sz_prefix, name)
		}
		case 1:{
			if(get_pcvar_num(g_protect) > 0 && is_user_admin(player) && (get_user_flags(player) & ADMIN_PROTECT)){
				suc_print_color(iClient, "^x04%s^x01 No Puedes obtener el setinfo de un^x03 Administrador!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
			
			new string[80]
			for(new i; i < sizeof(sz_setinfo); i++){
				get_user_info(player, sz_setinfo[i], string, charsmax(string))
				console_print(iClient, "setinfo %s - Valor %s", sz_setinfo[i], string)
			}

			suc_print_color(iClient, "^x04%s^x01 Revisa Tu^x03 Consola!", sz_prefix)
		}
		case 2:{
			if(get_pcvar_num(g_guardado) < 1){
				suc_print_color(iClient, "^x04%s^x01 Opcion Desactivada!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
			
			if(adv_vault_get_prepare(g_vault, _, g_elegido[iClient])) adv_vault_removekey(g_vault, _ , g_elegido[iClient])
			
			g_store_id[player] = iClient
			
			for(new i; i < sizeof(sz_commands); i++) query_client_cvar(player, sz_commands[i], "save_command", 31, name)	
			for(new i; i < sizeof(sz_commands2); i++) query_client_cvar(player, sz_commands2[i], "save_command2", 31, name)
			
			set_task(2.0, "save_client", iClient)
		}
		case 3:{
			if(get_pcvar_num(g_guardado) < 1){
				suc_print_color(iClient, "^x04%s^x01 Opcion Desactivada!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
			
			if(!adv_vault_get_prepare(g_vault, _, g_elegido[iClient]))
			{
				suc_print_color(iClient, "^x04%s^x01 Ocurrio un error al tratar de cargar los datos, intenta nuevamente!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
			
			adv_vault_get_field(g_vault, g_campos[CONFIGURACION], g_configuracion[iClient], charsmax(g_configuracion[]))
			adv_vault_get_field(g_vault, g_campos[CONFIGURACION2], g_configuracion2[iClient], charsmax(g_configuracion2[]))
			
			motd[0] = 0
	
			static len;
	
			len = format(motd, charsmax(motd), "<body bgcolor=#000000><font color=#87cefa><pre>")
	
			len += format(motd[len], charsmax(motd)-len,"<center><h1><font color=^"green^"> Configuracion: </font></h1></center>")
	
			len += format(motd[len], charsmax(motd)-len,"<left><h3><font color=^"blue^"><B>.</B> <font color=^"white^">%s</color></h3></left>^n", g_configuracion[iClient])
			len += format(motd[len], charsmax(motd)-len,"<left><h3><font color=^"blue^"><B>.</B> <font color=^"white^">%s</color></h3></left>^n", g_configuracion2[iClient])
			
			show_motd(iClient, motd, "Configuraciones De Usuario")
		}
		case 4:{
			if(get_pcvar_num(g_guardado) < 1){
				suc_print_color(iClient, "^x04%s^x01 Opcion Desactivada!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
		
			adv_vault_removekey(g_vault, _ , g_elegido[iClient])
			suc_print_color(iClient, "^x04%s^x01 Datos eliminados correctamente!", sz_prefix)
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public check_command(iClient, const command[], const value[]) console_print(g_store_id[iClient], "Cvar %s - Valor %s", command, value)

public save_command(iClient, const command[], const value[])	
	formatex(g_configuracion[g_store_id[iClient]], charsmax(g_configuracion[]), "%s %s %s", g_configuracion[g_store_id[iClient]], command, value)

public save_command2(iClient, const command[], const value[])	
	formatex(g_configuracion2[g_store_id[iClient]], charsmax(g_configuracion2[]), "%s %s %s", g_configuracion2[g_store_id[iClient]], command, value)

public save_client(iClient){
	adv_vault_set_start(g_vault)
	adv_vault_set_field(g_vault, g_campos[NOMBRE_JUGADOR], g_elegido[iClient])
	adv_vault_set_field(g_vault, g_campos[CONFIGURACION], g_configuracion[iClient])
	adv_vault_set_field(g_vault, g_campos[CONFIGURACION2], g_configuracion2[iClient])
	adv_vault_set_end(g_vault, 0, g_elegido[iClient])
	suc_print_color(iClient, "^x04%s^x01 Datos guardados correctamente!", sz_prefix)
}

public show_menu_vault(iClient){
	if(get_pcvar_num(g_activado) < 1 || get_pcvar_num(g_guardado) < 1){
		suc_print_color(iClient, "^x04%s^x01 La Opción se encuentra desactivada!", sz_prefix)
		return PLUGIN_HANDLED
	}

	new menu = menu_create("\r[\yConfiguraciones Guardadas\r]", "menu_vault"), txt[50], pos[3]	
	
	new size, keyindex; adv_vault_find_start(g_vault, g_campos[NOMBRE_JUGADOR], "", FINDFLAGS_NOT)
	
	while((keyindex = adv_vault_find_next(g_vault)))
	{
		size++
		adv_vault_get_keyname(g_vault, keyindex, txt, charsmax(txt))
		num_to_str(size, pos, charsmax(pos))
		menu_additem(menu, txt, pos, ADMIN_SAVE)
	}
	
	formatex(txt, charsmax(txt), "^n\yRegistros Encontrados \d(\r%d\d)", size) 
	
	adv_vault_find_closed(g_vault)
	
	if(size <= 0){
		menu_additem(menu, "Agregar Nuevo Registro", "1", ADMIN_SAVE)
		formatex(txt, charsmax(txt), "^n\dNo se encontraron Registros")
	}
	
	menu_addtext(menu,txt, 1)
	
	menu_setprop(menu, MPROP_EXITNAME, "\rSalir")
	menu_display(iClient, menu)
	return PLUGIN_HANDLED
}

public menu_vault(iClient, menu, item){
	if(item == MENU_EXIT || get_pcvar_num(g_activado) < 1 || get_pcvar_num(g_guardado) < 1){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new szData[2], item_access, item_callback, name[32];
	menu_item_getinfo( menu, item, item_access, szData,charsmax( szData ), name ,charsmax( name ), item_callback );
	
	menu_destroy(menu)
	
	if(equal(name, "Agregar Nuevo Registro")) show_menu_players(iClient)
	else show_menu_registros(iClient, name)

	return PLUGIN_HANDLED
}

public show_menu_registros(iClient, const Nick[]){
	if(get_pcvar_num(g_activado) < 1 || get_pcvar_num(g_guardado) < 1){
		suc_print_color(iClient, "^x04%s^x01 La Opción se encuentra desactivada!", sz_prefix)
		return PLUGIN_HANDLED
	}
	
	copy(g_elegido[iClient], charsmax(g_elegido[]), Nick)
	
	formatex(g_menu, charsmax(g_menu), "\y*** \rRegistros Del Jugador: \d%s \y***", Nick)
	new menu = menu_create(g_menu, "menu_registros")
	
	menu_additem(menu, "Ver Configuraciones", "1", ADMIN_SAVE)
	menu_additem(menu, "Borrar Datos", "2", ADMIN_SAVE)
		
	menu_setprop(menu, MPROP_EXITNAME, "\rSalir")
	menu_display(iClient, menu)
	return PLUGIN_HANDLED
}

public menu_registros(iClient, menu, item){
	if(item == MENU_EXIT || get_pcvar_num(g_activado) < 1 || get_pcvar_num(g_guardado) < 1){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	switch(item){
		case 0:{
			if(!adv_vault_get_prepare(g_vault, _, g_elegido[iClient]))
			{
				suc_print_color(iClient, "^x04%s^x01 Ocurrio un error al tratar de cargar los datos, intenta nuevamente!", sz_prefix)
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
			
			adv_vault_get_field(g_vault, g_campos[CONFIGURACION], g_configuracion[iClient], charsmax(g_configuracion[]))
			adv_vault_get_field(g_vault, g_campos[CONFIGURACION2], g_configuracion2[iClient], charsmax(g_configuracion2[]))
			
			motd[0] = 0
	
			static len;
	
			len = format(motd, charsmax(motd), "<body bgcolor=#000000><font color=#87cefa><pre>")
	
			len += format(motd[len], charsmax(motd)-len,"<center><h1><font color=^"green^"> Configuracion: </font></h1></center>")
	
			len += format(motd[len], charsmax(motd)-len,"<left><h3><font color=^"blue^"><B>.</B> <font color=^"white^">%s</color></h3></left>^n", g_configuracion[iClient])
			len += format(motd[len], charsmax(motd)-len,"<left><h3><font color=^"blue^"><B>.</B> <font color=^"white^">%s</color></h3></left>^n", g_configuracion2[iClient])
			
			show_motd(iClient, motd, "Configuraciones De Usuario")
		}
		case 1:{
			adv_vault_removekey(g_vault, _ , g_elegido[iClient])
			suc_print_color(iClient, "^x04%s^x01 Datos eliminados correctamente!", sz_prefix)
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

stock suc_print_color(id, const mensaje[], any:...)
{
	static buffer[192]; vformat(buffer, 191, mensaje, 3)
	
	if(id && !IsBit(g_conectado, id)) return;
	
	if(id)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id);
		write_byte(id);
		write_string(buffer);
		message_end();
	}
	else
	{
		for( id = 1; id <= g_maxplayers; id++)
		{
			if(!IsBit(g_conectado,id)) continue;
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id);
			write_byte(id);
			write_string(buffer);
			message_end();
		}
	}
}