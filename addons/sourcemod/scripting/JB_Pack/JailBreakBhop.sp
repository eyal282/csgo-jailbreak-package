#include <sourcemod>

#define semicolon 1
#define newdecls  required

native void LR_isAutoBhopEnabled();

public Plugin myinfo =
{
	name        = "JailBreak Bhop",
	author      = "Eyal282",
	description = "Bhop API plugin",
	version     = "1.0",
	url         = ""
};

Handle hcv_AutoBhop         = INVALID_HANDLE;
Handle hcv_OriginalAutoBhop = INVALID_HANDLE;

public void OnPluginStart()
{
	hcv_AutoBhop = CreateConVar("jb_autobunnyhopping", "1", "Is auto bunnyhop enabled by default?");

	hcv_OriginalAutoBhop = FindConVar("sv_autobunnyhopping");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	SetConVarBool(hcv_OriginalAutoBhop, GetConVarBool(hcv_AutoBhop));
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0 || !IsPlayerAlive(client))
		return;

	else if (IsFakeClient(client))
		return;

	SetConVarBool(hcv_OriginalAutoBhop, GetConVarBool(hcv_AutoBhop));

	if (!GetConVarBool(hcv_AutoBhop))
		return;

	SendConVarValue(client, hcv_OriginalAutoBhop, "1");
}

public void LastRequest_OnLRStarted(int Prisoner, int Guard)
{
	if (!GetConVarBool(hcv_AutoBhop))
	{
		SetConVarBool(hcv_OriginalAutoBhop, false);
		return;
	}

	if (LR_isAutoBhopEnabled())
	{
		SendConVarValue(Prisoner, hcv_OriginalAutoBhop, "1");
		SendConVarValue(Guard, hcv_OriginalAutoBhop, "1");
	}
	else
	{
		SendConVarValue(Prisoner, hcv_OriginalAutoBhop, "0");
		SendConVarValue(Guard, hcv_OriginalAutoBhop, "0");
	}
}