#define PLUGIN_AUTHOR "xoxo"
#define PLUGIN_VERSION "1.45"
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <smlib>
#include <basecomm>
#include <sdkhooks>
//#include <skyler>
#include <morecolors>
//#include <hl_gangs>
#include <eyal-jailbreak>

native LR_isActive();

bool isbox = false;
bool nospam[MAXPLAYERS + 1] = false;
ConVar g_SetTimeMute;
ConVar g_SetTimeCooldown;

new Handle:hcv_DeadTalk = INVALID_HANDLE;

new Handle:hTimer_ExpireMute = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "skyler", 
	author = PLUGIN_AUTHOR, 
	description = "nice and usefull function's for your jailbreak server", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=283190"
};

public OnPluginStart()
{
	g_SetTimeMute = CreateConVar("sm_setmutetime", "30.0", "Set the mute timer on round start");
	AutoExecConfig(true, "WePlay-jail", "sourcemod");
	
	RegConsoleCmd("sm_givelr", cmd_givelr, "");
	//RegConsoleCmd("sm_box", cmd_box, "");
	//RegConsoleCmd("sm_pvp", cmd_box, "");
	RegConsoleCmd("sm_medic", cmd_medic, "");
	RegConsoleCmd("sm_deagle", cmd_deagle, "");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	
	LoadTranslations("common.phrases.txt"); // Fixing errors in target, something skyler didn't do haha.
	
	hcv_DeadTalk = FindConVar("sv_deadtalk");
}

public OnMapStart()
{
	hTimer_ExpireMute = INVALID_HANDLE;
}


public Action cmd_medic(int client, args)
{
	int hp;
	char name[512];
	hp = GetClientHealth(client);
	GetClientName(client, name, sizeof(name));
	if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		/*
		if (hp >= 100)
		{
			PrintToChat(client, "%s you cant call a medic because you have \x02100 HP!", PREFIX);
			return Plugin_Handled;
		}
		*/
		if (nospam[client])
		{
			PrintToChat(client, "%s you cant call a medic because you still have \x02%d \x05cooldown!", PREFIX, g_SetTimeCooldown.IntValue);
			return Plugin_Handled;
		}
		if (!nospam[client])
		{
			nospam[client] = true;
			PrintToChatAll("%s \x05%s\x01 wants a \x07medic!", PREFIX, name);
			CreateTimer(g_SetTimeCooldown.FloatValue, medicHandler, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action medicHandler(Handle timer, any client)
{
	if (nospam[client])
	{
		nospam[client] = false;
		KillTimer(timer); //pervent memory leak
	}
}
public Action cmd_deagle(int client, args)
{
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "%s \x05You \x01are not in the guards team you cant active this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT && !IsPlayerAlive(client) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "%s \x5You \x01are need to be alive to active this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT || IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChatAll("%s \x01All \x07terrorist \x01alive got a empty \x05deagle! \x01Have Fun", PREFIX);
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			Client_GiveWeaponAndAmmo(i, "weapon_deagle", _, 0, _, 0);
			GivePlayerItem(i, "weapon_knife");
		}
	}
	return Plugin_Continue;
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("mp_forcecamera 1");
	ServerCommand("sm_silentcvar sv_full_alltalk 1");
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if(GetClientTeam(i) == CS_TEAM_T && !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC) && GetPlayerCount() > 2)
		{
			SetClientListeningFlags(i, VOICE_MUTED);
		}
		
		else if(!BaseComm_IsClientMuted(i))
			SetClientListeningFlags(i, VOICE_NORMAL);
	}
	
	if(hTimer_ExpireMute != INVALID_HANDLE)
	{
		CloseHandle(hTimer_ExpireMute);
		hTimer_ExpireMute = INVALID_HANDLE;
	}
	hTimer_ExpireMute = CreateTimer(g_SetTimeMute.FloatValue, MuteHandler);
	
	PrintToChatAll("%s The \x02terrorist \x01have been muted, they will be able to speak in \x05%d \x01seconds", PREFIX, g_SetTimeMute.IntValue);
}
public Action MuteHandler(Handle timer, any client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			CPrintToChat(i, "%s The \x02terrorists \x01can talk right \x05now!", PREFIX);
		}
		if (IsClientInGame(i) && (IsPlayerAlive(i) || GetConVarBool(hcv_DeadTalk)) && !BaseComm_IsClientMuted(i))
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
	
	hTimer_ExpireMute = INVALID_HANDLE;
}

public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!GetConVarBool(hcv_DeadTalk) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		SetClientListeningFlags(client, VOICE_MUTED);
		
	//int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int talive;
	talive = GetTeamAliveCount(CS_TEAM_T);
	if (talive == 1) //lastrequest time
	{
		ServerCommand("mp_teammates_are_enemies 0");
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			PrintToChat(i, "%s the friendly fire turned off automatically!", PREFIX);
			
		if(hTimer_ExpireMute != INVALID_HANDLE)
			TriggerTimer(hTimer_ExpireMute, true);
		
	}
}

public Action Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	if(GetClientTeam(client) == CS_TEAM_T && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && hTimer_ExpireMute != INVALID_HANDLE)
		SetClientListeningFlags(client, VOICE_MUTED);
		
	else if(!BaseComm_IsClientMuted(client))
		SetClientListeningFlags(client, VOICE_NORMAL);	
}

public Action Event_PlayerTeam(Event event, char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	
	CreateTimer(0.1, CheckDeathOnJoin, UserId, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CheckDeathOnJoin(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	else if(IsPlayerAlive(client) || GetConVarBool(hcv_DeadTalk))
		return;
		
	if(!GetConVarBool(hcv_DeadTalk) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		SetClientListeningFlags(client, VOICE_MUTED);
}

public Action cmd_box(int client, args)
{
	if (GetClientTeam(client) == CS_TEAM_CT || CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		Menu box = CreateMenu(BoxMenuHandler);
		box.SetTitle("[WePlay] box menu");
		if (!isbox)
			box.AddItem("box", "Enable Friendly Fire");
		else
			box.AddItem("box", "Enable Friendly Fire", ITEMDRAW_DISABLED);
		if (isbox)
			box.AddItem("box", "Disable Friendly Fire");
		else
			box.AddItem("box", "Disable Friendly Fire", ITEMDRAW_DISABLED);
		box.Display(client, MENU_TIME_FOREVER);
	}
}
public int BoxMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, item, info, sizeof(info));
		if (StrEqual(info, "box"))
		{
			if (!isbox)
			{
				ServerCommand("mp_teammates_are_enemies 1");
				PrintToChatAll("%s friendly fire turned on!", PREFIX);
			}
			if (isbox)
			{
				ServerCommand("mp_teammates_are_enemies 0");
				PrintToChatAll("%s friendly fire turned off!", PREFIX);
			}
			
		}
	}
	if (action == MenuAction_End)
	{
		isbox = !isbox;
	}
}
public Action cmd_givelr(int client, args)
{
	if(args == 0)
	{
		PrintToChat(client, "Usage: sm_givelr <#userid|name>");
		return Plugin_Handled;
	}
	else if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You are dead you cant give some one lastrequest", PREFIX);
		return Plugin_Handled;
	}
	else if(GetTeamAliveCount(CS_TEAM_T) != 1)
	{
		PrintToChat(client, "%s you are not the last terrorist!", PREFIX);
		return Plugin_Handled;
	}
	if(LR_isActive())
	{
		PrintToChat(client, "%s LR is already active!", PREFIX);
		return Plugin_Handled;
	}	
	if (GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client) && GetTeamAliveCount(CS_TEAM_T) == 1)
	{
		if (args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTerroristTarget(client, arg1, false, false);
			
			if (target <= 0)
				return Plugin_Handled;
				
			float Origin[3];
			char clientname[64];
			char targetname[64];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			CS_RespawnPlayer(target);
			TeleportEntity(target, Origin, NULL_VECTOR, NULL_VECTOR);
			ForcePlayerSuicide(client);
			GetClientName(client, clientname, sizeof(clientname));
			GetClientName(target, targetname, sizeof(targetname));
			PrintToChatAll("%s %s gave to %s the lastrequest", PREFIX, clientname, targetname);
		}
	}
	return Plugin_Handled;
}

stock RemoveAllWeapons(int client)
{
	int iWeapon;
	for (int k = 0; k <= 6; k++)
	{
		iWeapon = GetPlayerWeaponSlot(client, k);
		
		if (IsValidEdict(iWeapon))
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
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
		new TrueCount = 0, TrueTarget = -1;
		for(new i=0;i < target_count;i++)
		{
			new trgt = target_list[i];
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

stock GetPlayerCount()
{
	new count;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(GetClientTeam(i) != CS_TEAM_CT && GetClientTeam(i) != CS_TEAM_T)
			continue;
			
		count++;
	}
	
	return count;
}


stock int GetTeamAliveCount(int Team)
{
	int count = 0;
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != Team)
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		count++;
	}
	
	return count;
}	

