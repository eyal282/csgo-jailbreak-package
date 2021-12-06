#include <sourcemod>

#define HIDE_RADAR_CSGO 1<<12

char strGame[10];

public Plugin myinfo = 
{
    name = "Disable Radar",
    author = "Internet Bully",
    description = "Turns off Radar on spawn",
	version     = "1.2",
    url = "http://www.sourcemod.net/"
}

public void OnPluginStart() 
{
	HookEvent("player_spawn", Player_Spawn);
	
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(StrContains(strGame, "cstrike") != -1) 
		HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
}
public void Player_Spawn(Handle event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, RemoveRadar, client);
}  

public Action RemoveRadar(Handle timer, any client) 
{    
	if(StrContains(strGame, "csgo") != -1) SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
	else if(StrContains(strGame, "cstrike") != -1) 
		CSSHideRadar(client);
} 

public void Event_PlayerBlind(Handle event, const char[] name, bool dontBroadcast)  // from GoD-Tony's "Radar Config" https://forums.alliedmods.net/showthread.php?p=1471473
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		float fDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
		CreateTimer(fDuration, RemoveRadar, client);
	}
}

void CSSHideRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}
