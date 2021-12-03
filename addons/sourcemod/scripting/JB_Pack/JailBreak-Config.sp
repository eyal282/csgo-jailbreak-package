#include <sourcemod>
#define semicolon 1
#define newdecls required

public Plugin myinfo = {
	name = "JailBreak Config",
	author = "Eyal282",
	description = "Basic JailBreak Config",
	version = "1.0",
	url = ""
};

enum struct enCvarList
{
	char name[64];
	char value[256];
}

// Cvar, Value
enCvarList cvarList[] = 
{
	{ "sm_vote_delay", "0" },
	{ "uc_party_mode", "0" }
}
public void OnMapStart( ) {
	CreateTimer(5.0, Timer_ExecuteConfig, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ExecuteConfig(Handle hTimer)
{
	for (int i = 0; i < sizeof(cvarList);i++)
	{
		ConVar convar = FindConVar(cvarList[i].name);
		
		if(convar != null)
		{
			SetConVarString(convar, cvarList[i].value);
		}
	}
}