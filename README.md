# Show-User-Config
View and save a user's settings on the server

This plugin consists of being able to see the configurations of a user on the server, which can be saved and later viewed if they wish, it contains cvars for better handling of the plugin and they can also edit it in the .sma

This plugin requires: https://amxmodx-es.com/Thread-API-Advanced-Vault-System-1-5-12-06-2015

CVARS:

ADMIN_FLAG -> FLAG to be able to see the players' setinfo, default ADMIN_RCON.
ADMIN_PROTECT -> FLAG for admins that are protected if the cvar suc_protect is enabled.
ADMIN_SAVE -> FLAG for admins who can manage saved data.
suc_protect -> protection to the admins so that they do not obtain their setinfo, default: 1 (activated), 0 to deactivate.
suc_enable -> plugin functions can be used, default: 1 (enabled), 0 to disable.
suc_vault -> enables saving settings, defualt: 1 (enabled), 0 to disable.
sz_prefix -> prefix for chat messages, default: "[SUC]"

USAGE:
Write /configs in the chat to open the menu of connected players and when you select it you can see your configuration, setinfo, save-delete-update the configuration and see your previous configuration if you already had one saved.
Write /save in the chat to open the registry management menu (saved configurations) and if there are none you can start adding one.
Write get_configs in the console followed by the name of the player in quotes whose configuration you want to manage. Example: get_configs "roccoxx"

FOR MORE INFO: https://amxmodx-es.com/Thread-Show-User-Config-1-1

