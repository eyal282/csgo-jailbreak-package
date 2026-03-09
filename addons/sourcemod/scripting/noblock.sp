#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name        = "No Block",
	author      = "sslice",
	description = "Removes player collisions...useful for mod-tastic servers running surf maps, etc.",
	version     = "1.0.0.0",
	url         = "http://www.steamfriends.com/"
};


bool   g_isHooked;
ConVar sm_noblock;

public void OnPluginStart()
{
	g_isHooked = true;
	HookEvent("player_spawn", OnSpawn, EventHookMode_Post);

	sm_noblock = CreateConVar("sm_noblock", "1", "Removes player vs. player collisions", FCVAR_NOTIFY | FCVAR_REPLICATED);
	HookConVarChange(sm_noblock, OnConVarChange);
}

public void OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);

	if (value == 0)
	{
		if (g_isHooked == true)
		{
			g_isHooked = false;

			UnhookEvent("player_spawn", OnSpawn, EventHookMode_Post);
		}

		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;

			else if(!IsPlayerAlive(i))
				continue;

			SetEntProp(i, Prop_Send, "m_CollisionGroup", 5);
		}
	}
	else
	{
		g_isHooked = true;

		HookEvent("player_spawn", OnSpawn, EventHookMode_Post);

		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;

			else if(!IsPlayerAlive(i))
				continue;

			SetEntProp(i, Prop_Send, "m_CollisionGroup", 2);
		}
	}
}

public Action OnSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int entity = GetClientOfUserId(userid);

	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
}
