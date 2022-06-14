#include <sourcemod>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude < updater>    // Comment out this line to remove updater support by force.
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/csgo-jailbreak-package/master/addons/sourcemod/updatefile.txt"

#define semicolon 1
#define newdecls  required

public Plugin myinfo =
{
	name        = "JailBreak Core",
	author      = "Eyal282",
	description = "Core JailBreak Plugin for updater support",
	version     = "1.0",
	url         = ""
};

public void OnPluginStart()
{
#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}

public void OnLibraryAdded(const char[] name)
{
#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}