#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <eyal-jailbreak>

#define PLUGIN_VERSION "1.0"

#define semicolon 1
#define newdecls required

native bool Eyal282_VoteCT_IsChosen(client);
native bool Eyal282_VoteCT_IsGodRound();
native bool JailBreakDays_IsDayActive();

public Plugin myinfo = 
{
	name = "CT Commands",
	author = "Eyal282",
	description = "The most important and basic commands for CT.",
	version = PLUGIN_VERSION,
	url = ""
};

bool IsVIP[MAXPLAYERS+1];

int BeamIndex, HaloIdx; // HaloIndex is stolen by an include.

Handle hcv_TeammatesAreEnemies = INVALID_HANDLE;
Handle hcv_CKHealthPerT = INVALID_HANDLE;

Handle hTimer_Beacon = INVALID_HANDLE;

bool CKEnabled = false;


public void OnPluginStart()
{
	RegConsoleCmd("sm_box", Command_Box, "Enables friendlyfire for the terrorists");
	RegConsoleCmd("sm_fd", Command_FD, "Turns on glow on a player");
	RegConsoleCmd("sm_ck", Command_CK, "Turns on CK for the rest of the vote CT");

	RegAdminCmd("sm_silentstopck", Command_SilentStopCK, ADMFLAG_ROOT, "Turns off CK silently");
	
	hcv_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	
	hcv_CKHealthPerT = CreateConVar("ck_health_per_t", "20", "Amount of health a CT gains per T. Formula: 100 + ((cvar * tcount) / ctcount)");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		OnClientPutInServer(i);
	}
}

public void OnMapStart()
{
	BeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	HaloIdx = PrecacheModel("materials/sprites/glow01.vmt", true);
	
	CKEnabled = false;
	
	SetConVarBool(hcv_TeammatesAreEnemies, false);
	
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsEntityPlayer(attacker))
		return Plugin_Continue;
		
	else if(GetClientTeam(victim) == GetClientTeam(attacker) && GetClientTeam(victim) == CS_TEAM_CT)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}


public Action Hook_WeaponCanUse(int client, int weapon)
{
	if(!CKEnabled || GetTeamPlayerCount(CS_TEAM_T, true) == 1)
		return Plugin_Continue;
	
	char Classname[15];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	
	if(StrEqual(Classname, "weapon_knife"))
		return Plugin_Continue;
		
	AcceptEntityInput(weapon, "Kill");
	return Plugin_Handled;
}


public Action Event_RoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	SetConVarBool(hcv_TeammatesAreEnemies, false);
	
	if(CKEnabled)
	{
		int Count = GetEntityCount();
		for(int i=MaxClients;i < Count;i++)
		{
			if(!IsValidEntity(i))
				continue;
				
			char Classname[15];
			GetEntityClassname(i, Classname, sizeof(Classname));
			
			if(strncmp(Classname, "weapon_", 7) != 0)
				continue;
				
			else if(StrEqual(Classname, "weapon_knife"))
				continue;
				
			AcceptEntityInput(i, "Kill");
		}
	}
}

// Note to self: This has EventHookMode_PostNoCopy, meaning I can't use GetEventInt until I change to EventHookMode_Post.

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	IsVIP[client] = false;
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderFx(client, RENDERFX_NONE);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	
	
	if(CKEnabled)
		CreateTimer(0.2, AddHealthCT, GetEventInt(hEvent, "userid"));
}

public Action AddHealthCT(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return;
		
	else if(!IsPlayerAlive(client))
		return;
		
	int health = GetEntProp(client, Prop_Send, "m_iHealth");
	
	// Cannot divide by zero here, because the current client must be a living ct.
	health += ( (GetConVarInt(hcv_CKHealthPerT) * GetTeamPlayerCount(CS_TEAM_T)) / GetTeamPlayerCount(CS_TEAM_CT) )
	
	SetEntityHealth(client, health);
}
public void OnClientDisconnect_Post(int client)
{
	if(GetTeamPlayerCount(CS_TEAM_T, true) < 2 || ( GetTeamPlayerCount(CS_TEAM_CT, true) == 0 && !JailBreakDays_IsDayActive() ))
		SetConVarBool(hcv_TeammatesAreEnemies, false);
}

public Action Event_PlayerDeath(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	if(GetTeamPlayerCount(CS_TEAM_T, true) < 2 || ( GetTeamPlayerCount(CS_TEAM_CT, true) == 0 && !JailBreakDays_IsDayActive() ))
		SetConVarBool(hcv_TeammatesAreEnemies, false);

}

public Action Command_FD(int client, int args)
{
	if((GetClientTeam(client) != CS_TEAM_CT || !IsPlayerAlive(client)) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		ReplyToCommand(client, "You don't have access to this command");
		
		return Plugin_Handled;
	}
	
	else if(args == 0)
	{
		ReplyToCommand(client, "Usage: sm_fd <target>");
		return Plugin_Handled;
	}
	char Arg[64];
	GetCmdArgString(Arg, sizeof(Arg));
	
	int target = FindTerroristTarget(client, Arg, false, false);
	
	if(target == -1)
		return Plugin_Handled;
		
	IsVIP[target] = !IsVIP[target];
	
	PrintToChatAll(" %s \x05%N \x01%s \x10Freeday \x01%s \x05%N ", PREFIX, client, IsVIP[target] ? "Gave" : "Took", IsVIP[target] ? "To" : "From", target);
	
	SetEntityRenderColor(target, 0, 128, 128, 255);

	if(IsVIP[target])
	{
		SetEntityRenderMode(target, RENDER_GLOW);
		SetEntityRenderFx(target, RENDERFX_GLOWSHELL);
		
		if(hTimer_Beacon == INVALID_HANDLE)
		{
			hTimer_Beacon = CreateTimer(0.3, Timer_BeaconVIP, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
	else
	{
		SetEntityRenderMode(target, RENDER_NORMAL);
		SetEntityRenderFx(target, RENDERFX_NONE);
	}
	
	return Plugin_Handled;
}

public Action Timer_BeaconVIP(Handle hTimer)
{
	bool AnyVIP = false;
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsVIP[i])
			continue;
		
		// Stolen from eylonap vote ct since I refuse to waste my time checking these stuff lol.
		float pos[3];
		int rgba[4];
		GetClientAbsOrigin(i, pos);
		pos[2] += 9;
		rgba[0] = GetRandomInt(10, 250);
		rgba[1] = GetRandomInt(10, 250);
		rgba[2] = GetRandomInt(10, 250);
		rgba[3] = 250;
		SetEntityRenderColor(i, rgba[0], rgba[1], rgba[2], rgba[3]);
		TE_SetupBeamRingPoint(pos, 5.0, 70.0, BeamIndex, HaloIdx, 0, 32, 0.45, 3.0, 0.0, rgba, 6, 0);
		TE_SendToAll();
		AnyVIP = true;
	}	
	
	if(!AnyVIP)
	{
		hTimer_Beacon = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Command_Box(int client, args)
{
	if((GetClientTeam(client) != CS_TEAM_CT || !IsPlayerAlive(client)) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		ReplyToCommand(client, "You don't have access to this command");
		
		return Plugin_Handled;
	}
	
	Handle hMenu = CreateMenu(Box_MenuHandler);
	
	SetMenuTitle(hMenu, "Box status: %s", GetConVarBool(hcv_TeammatesAreEnemies) ? "Enabled" : "Disabled");
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Box_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		if(GetClientTeam(client) != CS_TEAM_CT && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
			return;

		bool Enable = (item == 0)
		SetConVarBool(hcv_TeammatesAreEnemies, Enable);
				
		PrintToChatAll(" %s \x05%N \x01%s \x02box! ", PREFIX, client, Enable ? "enabled" : "disabled");
	}
}


public Action Command_CK(int client, int args)
{
	if((GetClientTeam(client) != CS_TEAM_CT || !Eyal282_VoteCT_IsChosen(client)) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		ReplyToCommand(client, "You don't have access to this command");
		
		return Plugin_Handled;
	}
	
	else if(CKEnabled)
	{
		ReplyToCommand(client, "CK is already running");
		
		return Plugin_Handled;
	}
	
	else if(!Eyal282_VoteCT_IsGodRound() && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		ReplyToCommand(client, " \x07CK \x01can only be \x07started \x01in \x07God Round. ");
		
		return Plugin_Handled;
	}
	
	Handle hMenu = CreateMenu(CK_MenuHandler);
	
	AddMenuItem(hMenu, "", "Start CK", CKEnabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu, "", "Stop CK", !CKEnabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	SetMenuTitle(hMenu, "[WePlay] CK");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}


public int CK_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
			return;

		switch(item)
		{
			case 0:
			{
				CKEnabled = true;
			}
			
			case 1:
			{
				CKEnabled = false;
			}
		}
		
		ServerCommand("mp_restartgame 1");
	}
}

public Action Command_SilentStopCK(int client, int args)
{
	CKEnabled = false;
	
	return Plugin_Handled;
}

public void Eyal282_VoteCT_OnVoteCTStart(int ChosenUserId)
{
	CKEnabled = false;
}

stock int GetTeamPlayerCount(int Team, bool onlyAlive = false)
{
	int count = 0;
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(onlyAlive && !IsPlayerAlive(i))
			continue;
			
		else if(GetClientTeam(i) == Team)
			count++;
	}
	return count;
}

/**
 * Wraps ProcessTargetString() and handles producing error messages for
 * bad targets.
 *
 * @param client	Client who issued command
 * @param target	Client's target argument
 * @param nobots	Optional. Set to true if bots should NOT be targetted
 * @param immunity	Optional. Set to false to ignore target immunity.
 * @return			Index of target client, or -1 on error.
 */
stock int FindTerroristTarget(int client, const char[] target, bool nobots = false, bool immunity = true)
{
	char target_name[MAX_TARGET_LENGTH];
	int target_list[1], target_count;
	bool tn_is_ml;
	
	int flags;
	if (nobots)
	{
		flags |= COMMAND_FILTER_NO_BOTS;
	}
	if (!immunity)
	{
		flags |= COMMAND_FILTER_NO_IMMUNITY;
	}
	
	if ((target_count = ProcessTargetString(
			target,
			client, 
			target_list, 
			1, 
			flags,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		int TrueCount = 0, TrueTarget = -1;
		for(int i=0;i < target_count;i++)
		{
			int trgt = target_list[i];
			if(GetClientTeam(trgt) == CS_TEAM_T)
			{
				TrueCount++;
				TrueTarget = trgt;
			}
		}
		
		if(TrueCount > 1)
		{
			ReplyToTargetError(client, COMMAND_TARGET_AMBIGUOUS);
			return -1;
		}
		return TrueTarget;
	}
	else
	{
		ReplyToTargetError(client, target_count);
		return -1;
	}
}

stock bool IsEntityPlayer(int entity)
{
	if(entity <= 0)
		return false;
		
	else if(entity > MaxClients)
		return false;
		
	return true;
}