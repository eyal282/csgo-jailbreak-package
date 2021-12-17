#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <basecomm>
#include <smlib>
#include <eyal-jailbreak>

#define MAX_MARKERS 5

#define PLUGIN_VERSION "1.0"

#define semicolon 1
#define newdecls required

native bool Eyal282_VoteCT_IsChosen(client);
native bool Eyal282_VoteCT_IsGodRound();
native bool JailBreakDays_IsDayActive();
native bool LR_isActive();

public Plugin myinfo = 
{
	name = "JailBreak CT Commands",
	author = "Eyal282, merged Skyler's JailAddons into this",
	description = "The most important and basic commands for CT.",
	version = PLUGIN_VERSION,
	url = ""
};

bool IsVIP[MAXPLAYERS+1];

int BeamIndex, HaloIdx; // HaloIndex is stolen by an include.

Handle hcv_TeammatesAreEnemies = INVALID_HANDLE;
Handle hcv_CKHealthPerT = INVALID_HANDLE;

Handle hTimer_Beacon = INVALID_HANDLE;
bool isbox = false;
bool nospam[MAXPLAYERS + 1] = false;
ConVar g_SetTimeMute;
ConVar g_tMinMute;
ConVar g_SetTimeCooldown;

Handle hcv_DeadTalk = INVALID_HANDLE;

Handle hTimer_ExpireMute = INVALID_HANDLE;


bool CKEnabled = false;

bool bCanZoom[MAXPLAYERS + 1] = true, bHasSilencer[MAXPLAYERS+1] = true, bWrongWeapon[MAXPLAYERS+1] = true;

ArrayList aMarkers = null;

enum struct markerEntry
{
	float origin[3];
	float radius;
}
public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt"); // Fixing errors in target, something skyler didn't do haha.
	
	RegConsoleCmd("sm_box", Command_Box, "Enables friendlyfire for the terrorists");
	RegConsoleCmd("sm_fd", Command_FD, "Turns on glow on a player");
	RegConsoleCmd("sm_ck", Command_CK, "Turns on CK for the rest of the vote CT");
	RegConsoleCmd("sm_givelr", cmd_givelr, "");
	RegConsoleCmd("sm_medic", cmd_medic, "");
	RegConsoleCmd("sm_deagle", cmd_deagle, "");

	RegAdminCmd("sm_silentstopck", Command_SilentStopCK, ADMFLAG_ROOT, "Turns off CK silently");
	
	hcv_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	hcv_DeadTalk = FindConVar("sv_deadtalk");
	
	hcv_CKHealthPerT = CreateConVar("ck_health_per_t", "20", "Amount of health a CT gains per T. Formula: 100 + ((cvar * tcount) / ctcount)");
	g_SetTimeMute = CreateConVar("sm_setmutetime", "30.0", "Set the mute timer on round start");
	g_tMinMute = CreateConVar("sm_t_min_mute", "2", "Minimum amount of T before round start mute occurs.");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("item_equip", Event_ItemEquip, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	
	aMarkers = CreateArray(sizeof(markerEntry))
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		OnClientPutInServer(i);
	}
}

// cmd = Were the cells opened by command or with button.
// note: This forward will fire if sm_open was used in any way.
// note: This forward will NOT fire if the cells were opened without being assigned.
public void SmartOpen_OnCellsOpened(bool cmd)
{
	if(cmd && hTimer_ExpireMute != INVALID_HANDLE)
	{
		CloseHandle(hTimer_ExpireMute);
		hTimer_ExpireMute = INVALID_HANDLE;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				PrintToChat(i, "%s The \x02terrorists \x01got unmuted through\x05 sm_open", PREFIX);
			}
			if (IsClientInGame(i) && (IsPlayerAlive(i) || GetConVarBool(hcv_DeadTalk)) && !BaseComm_IsClientMuted(i))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
}
public void OnMapStart()
{
	BeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	HaloIdx = PrecacheModel("materials/sprites/glow01.vmt", true);
	
	CKEnabled = false;
	
	hTimer_ExpireMute = INVALID_HANDLE;
	hTimer_Beacon = INVALID_HANDLE;
	
	SetConVarBool(hcv_TeammatesAreEnemies, false);
	
	CreateTimer(0.5, Timer_DrawMarkers, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
}

public Action Timer_DrawMarkers(Handle hTimer)
{
	for (int i = 0; i < GetArraySize(aMarkers);i++)
	{
		markerEntry entry;
		
		GetArrayArray(aMarkers, i, entry);
		
		float Origin[3], Radius;
		
		Origin = entry.origin;
		Radius = entry.radius;
		
		int colors[4] =  { 0, 0, 255, 255 };
		TE_SetupBeamRingPoint(Origin, Radius, Radius+0.1, BeamIndex, HaloIdx, 0, 10, 0.51, 5.0, 0.0, colors, 10, 0);
		TE_SendToAll();
	}
}


#define MAX_BUTTONS 26

int g_LastButtons[MAXPLAYERS + 1];
float g_fPressTime[MAXPLAYERS + 1][MAX_BUTTONS+1];

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	for (new i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		
		if ((buttons & button))
		{
			if (!(g_LastButtons[client] & button))
			{
				g_fPressTime[client][i] = GetGameTime();
				OnButtonPress(client, button);
			}
		}
		else if ((g_LastButtons[client] & button))
		{
			OnButtonRelease(client, button, GetGameTime() - g_fPressTime[client][i]);
		}
	}	
    
	g_LastButtons[client] = buttons;
    
	return Plugin_Continue;
}

public void OnButtonPress(int client, int button)
{
	
}

public void OnButtonRelease(int client, int button, float holdTime)
{
	if(button != IN_ATTACK2)
		return;
		
	if(bWrongWeapon[client] || bCanZoom[client] || bHasSilencer[client])
		return;
	
	if (GetClientTeam(client) != CS_TEAM_CT)
		return;
	
	if(LR_isActive())
		return;
	
	// Releasing without hold = create marker.
	// Releasing with a short hold could be a regret of action.
	// Releasing with a second hold = delete marker.
	if(holdTime < 0.2)
	{
		CreateMarker(client);
		
		if(GetArraySize(aMarkers) == 1)
			PrintToChat(client, "Hint: Hold +attack2 for a second to clear all marks.")
	}
	else if(holdTime >= 1.0)
	{	
		DeleteAllMarkers();
	}
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


public Action Event_RoundStart(Event hEvent, const char[] Name, bool dontBroadcast)
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
	
	DeleteAllMarkers();
	
	ServerCommand("mp_forcecamera 1");
	ServerCommand("sm_silentcvar sv_full_alltalk 1");
		
		
	if(GetTeamAliveCount(CS_TEAM_T) < g_tMinMute.IntValue)
	{
		if(hTimer_ExpireMute != INVALID_HANDLE)
		{
			CloseHandle(hTimer_ExpireMute);
			hTimer_ExpireMute = INVALID_HANDLE;
		}
		
		PrintToChatAll("%s The \x02terrorist \x01are not muted, they can talk now.", PREFIX);
		return;
	}
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

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	IsVIP[client] = false;
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderFx(client, RENDERFX_NONE);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	if(CKEnabled)
		CreateTimer(0.2, AddHealthCT, GetEventInt(hEvent, "userid"));
		
	if(GetClientTeam(client) == CS_TEAM_T && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && hTimer_ExpireMute != INVALID_HANDLE)
		SetClientListeningFlags(client, VOICE_MUTED);
		
	else if(!BaseComm_IsClientMuted(client))
		SetClientListeningFlags(client, VOICE_NORMAL);	
}

// Shamelessly stolen from MyJailBreak, Shanapu
public Action Event_ItemEquip(Event event, const char[] Name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(event.GetInt("userid"));

	bCanZoom[client] = event.GetBool("canzoom");
	bHasSilencer[client] = event.GetBool("hassilencer");
	bWrongWeapon[client] = false;
	
	int wepType = event.GetInt("weptype");
	
	if(wepType == 0 || wepType == 9)
	{
		bWrongWeapon[client] = true;
	}
		
	/*
	WEAPONTYPE_KNIFE = 0
	WEAPONTYPE_TASER 8
	WEAPONTYPE_GRENADE 9
	*/
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
		
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
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


stock int GetAliveTeamCount(int Team)
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

stock void DeleteAllMarkers()
{
	ClearArray(aMarkers);
}


stock void CreateMarker(int client)
{
	markerEntry entry;
	
	GetClientAimTargetPos(client, entry.origin);
	
	entry.origin[2] += 5.0;
	entry.radius = 128.0;
	
	if(GetArraySize(aMarkers) >= 1)
	{
		ShiftArrayUp(aMarkers, 0);
		SetArrayArray(aMarkers, 0, entry);
	}
	else
		PushArrayArray(aMarkers, entry);
		
	
	if(GetArraySize(aMarkers) >= MAX_MARKERS)
		ResizeArray(aMarkers, MAX_MARKERS);
}

// Shamelessly stolen from Shanapu MyJB.
int GetClientAimTargetPos(int client, float g_fPos[3]) 
{
	if (client < 1)
		return -1;

	float vAngles[3];float vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);

	TR_GetEndPosition(g_fPos, trace);
	g_fPos[2] += 5.0;

	int entity = TR_GetEntityIndex(trace);

	CloseHandle(trace);

	return entity;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, int client)
{
	if (entity == client)
		return false;

	if (entity > MaxClients)
		return false;

	if (!IsClientInGame(entity))
		return false;

	if (!IsPlayerAlive(entity))
		return false;

	return true;
}


// Start of Skyler



public Action cmd_medic(int client, int args)
{
	//int hp;
	char name[512];
	//hp = GetClientHealth(client);
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

public Action MuteHandler(Handle timer, any client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "%s The \x02terrorists \x01can talk right \x05now!", PREFIX);
		}
		if (IsClientInGame(i) && (IsPlayerAlive(i) || GetConVarBool(hcv_DeadTalk)) && !BaseComm_IsClientMuted(i))
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
	
	hTimer_ExpireMute = INVALID_HANDLE;
}

public Action Event_PlayerTeam(Event event, char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	
	CreateTimer(0.1, CheckDeathOnJoin, UserId, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckDeathOnJoin(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	else if(IsPlayerAlive(client) || GetConVarBool(hcv_DeadTalk))
		return;
		
	if(!GetConVarBool(hcv_DeadTalk) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		SetClientListeningFlags(client, VOICE_MUTED);
}

public Action cmd_box(int client, int args)
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
public Action cmd_givelr(int client, int args)
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

stock void RemoveAllWeapons(int client)
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

stock int GetPlayerCount()
{
	int count;
	for(int i=1;i <= MaxClients;i++)
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