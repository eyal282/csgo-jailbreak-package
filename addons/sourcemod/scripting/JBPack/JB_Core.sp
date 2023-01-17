#include <sourcemod>
#include <eyal-jailbreak>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude < updater>    // Comment out this line to remove updater support by force.
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/csgo-jailbreak-package/master/addons/sourcemod/updatefile.txt"
#define UPDATE_URL2 "https://raw.githubusercontent.com/eyal282/sm_muted_indicator/master/addons/sourcemod/updatefile.txt"

#pragma semicolon 1
#pragma newdecls  required

public Plugin myinfo =
{
	name        = "JailBreak Core",
	author      = "Eyal282",
	description = "Core JailBreak Plugin",
	version     = "1.0",
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("JB_Core");

	return APLRes_Success;
}
public void OnPluginStart()
{

	CreateDirectory("cfg/sourcemod/JBPack", FPERM_ULTIMATE);

	SetFilePermissions("cfg/sourcemod/JBPack", FPERM_ULTIMATE);

	AutoExecConfig_SetFile("JB_Core", "sourcemod/JBPack");

	UC_CreateConVar("sm_prefix_cvar", "[{RED}JBPack{NORMAL}] {NORMAL}", "List of colors: NORMAL, RED, GREEN, LIGHTGREEN, OLIVE, LIGHTRED, GRAY, YELLOW, ORANGE, BLUE, PINK");
	UC_CreateConVar("sm_menu_prefix_cvar", "[JBPack]");

	AutoExecConfig_ExecuteFile();

	AutoExecConfig_CleanFile();

#if defined _updater_included

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		Updater_AddPlugin(UPDATE_URL2);
		
	}

#endif
}

public void OnLibraryAdded(const char[] name)
{
#if defined _updater_included

	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		Updater_AddPlugin(UPDATE_URL2);
	}

#endif
}

/**
 * Adds an informational string to the server's public "tags".
 * This string should be a short, unique identifier.
 *
 *
 * @param tag            Tag string to append.
 * @noreturn
 */
stock void AddServerTag2(const char[] tag)
{
	Handle hTags = INVALID_HANDLE;
	hTags        = FindConVar("sv_tags");

	if (hTags != INVALID_HANDLE)
	{
		int flags = GetConVarFlags(hTags);

		SetConVarFlags(hTags, flags & ~FCVAR_NOTIFY);

		char tags[50];    // max size of sv_tags cvar
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrContains(tags, tag, true) > 0) return;
		if (strlen(tags) == 0)
		{
			Format(tags, sizeof(tags), tag);
		}
		else
		{
			Format(tags, sizeof(tags), "%s,%s", tags, tag);
		}
		SetConVarString(hTags, tags, true);

		SetConVarFlags(hTags, flags);
	}
}

/**
 * Removes a tag previously added by the calling plugin.
 *
 * @param tag            Tag string to remove.
 * @noreturn
 */
stock void RemoveServerTag2(const char[] tag)
{
	Handle hTags = INVALID_HANDLE;
	hTags        = FindConVar("sv_tags");

	if (hTags != INVALID_HANDLE)
	{
		int flags = GetConVarFlags(hTags);

		SetConVarFlags(hTags, flags & ~FCVAR_NOTIFY);

		char tags[50];    // max size of sv_tags cvar
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrEqual(tags, tag, true))
		{
			Format(tags, sizeof(tags), "");
			SetConVarString(hTags, tags, true);
			return;
		}

		int pos = StrContains(tags, tag, true);
		int len = strlen(tags);
		if (len > 0 && pos > -1)
		{
			bool found;
			char taglist[50][50];
			ExplodeString(tags, ",", taglist, sizeof(taglist[]), sizeof(taglist));
			for (int i = 0; i < sizeof(taglist[]); i++)
			{
				if (StrEqual(taglist[i], tag, true))
				{
					Format(taglist[i], sizeof(taglist), "");
					found = true;
					break;
				}
			}
			if (!found) return;
			ImplodeStrings(taglist, sizeof(taglist[]), ",", tags, sizeof(tags));
			if (pos == 0)
			{
				tags[0] = 0x20;
			}
			else if (pos == len - 1)
			{
				Format(tags[strlen(tags) - 1], sizeof(tags), "");
			}
			else
			{
				ReplaceString(tags, sizeof(tags), ",,", ",");
			}

			SetConVarString(hTags, tags, true);

			SetConVarFlags(hTags, flags);
		}
	}
}