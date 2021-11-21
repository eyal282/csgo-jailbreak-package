#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#define PREFIX " \x04[WePlay #JB]\x01 "

#define PLUGIN_VERSION "1.1"

#pragma newdecls required

Handle hcv_Mode = INVALID_HANDLE;
Handle hcv_Auto = INVALID_HANDLE;
Handle hcv_GraceBeforeOpen = INVALID_HANDLE;
Handle hcv_EmptyRebel = INVALID_HANDLE;
Handle hcv_LRChainsaw = INVALID_HANDLE;

Handle dbLocal;

Handle Trie_Retriers = INVALID_HANDLE;

Handle hTimer_AutoOpen = INVALID_HANDLE;

bool OpenedThisRound = false;

char MapName[64];

int ButtonHID = -1, IsolationHID = -1;

bool CanBeGraced[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Smart Open",
	author = "Eyal282",
	description = "JailBreak Cells Open that works in a smart way",
	version = PLUGIN_VERSION,
	url = ""
}

native bool:SmartOpen_AreCellsOpen();

// returns false if couldn't open cells. Forced may fail if not assigned.
native bool:SmartOpen_OpenCells(bool:forced, bool:isolation);

public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:Error[], errorLength)
{
	CreateNative("SmartOpen_AreCellsOpen", Native_AreCellsOpen);
	CreateNative("SmartOpen_OpenCells", Native_OpenCells);
}

public any Native_AreCellsOpen(Handle:plugin, numParams)
{
	return OpenedThisRound;
}

public any Native_OpenCells(Handle:plugin, numParams)
{
	new bool:forced = GetNativeCell(1);
	new bool:isolation = GetNativeCell(2);
	
	if(OpenedThisRound && !forced)
		return false;
		
	new bool:openedCells = OpenCells();
	
	if(isolation)
		isolation = OpenIsolation();
		
	if(!openedCells && !isolation)
		return false;
		
	return true;
}
public OnPluginStart()
{	
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawnOrDeath, EventHookMode_Post);
	
	RegConsoleCmd("sm_open", Command_Open, "Opens jail cells");
	RegConsoleCmd("sm_hardopen", Command_HardOpen, "Opens jail cells and isolation");
	
	RegAdminCmd("sm_open_override", Command_OpenOverride, ADMFLAG_SLAY, "Command used for override purposes");
	RegAdminCmd("sm_assignopen", Command_AssignOpen, ADMFLAG_SLAY);
	RegAdminCmd("sm_assignisol", Command_AssignIsolation, ADMFLAG_SLAY);
	RegAdminCmd("sm_assignisolation", Command_AssignIsolation, ADMFLAG_SLAY);
	
	hcv_Mode = CreateConVar("open_cells_mode", "1", "0 - Command will not work if an admin didn't assign a button to the map, 1 - Uses all buttons in the map if button wasn't assigned to map");
	hcv_Auto = CreateConVar("open_cells_auto", "60", "After how much time to open the cells, set to -1 to disable");
	hcv_GraceBeforeOpen = CreateConVar("open_cells_grace_pre_open", "1", "1 - Players will respawn when joining before cells open");
	hcv_EmptyRebel = CreateConVar("open_cells_allow_empty_rebel", "1", "If there are no CT ( probably server empty ) terrorists are able to use !open");
	hcv_LRChainsaw = CreateConVar("open_cells_lr_chainsaw", "1", "Last terrorist can execute !open with his lr chainsaw");
	
	Trie_Retriers = CreateTrie();
}

public OnMapStart()
{
	ButtonHID = -1;
	OpenedThisRound = false;
	ConnectToDatabase();
	
	hTimer_AutoOpen = INVALID_HANDLE;
}

public OnClientAuthorized(client)
{
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new dummy_value;
	if(!GetTrieValue(Trie_Retriers, AuthId, dummy_value))
		CanBeGraced[client] = true;
}

public OnClientDisconnect(client)
{
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	SetTrieValue(Trie_Retriers, AuthId, 1, true);
}

public ConnectToDatabase()
{		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("SmartOpen", Error, sizeof(Error))) == INVALID_HANDLE)
		LogError(Error);
	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS SmartOpen_Maps (MapName VARCHAR(64) NOT NULL UNIQUE, ButtonHammerID INT(15) NOT NULL, IsolationHammerID INT(15) NOT NULL)", _, DBPrio_High);		
		
		new String:sQuery[256];
		GetCurrentMap(MapName, sizeof(MapName));
		SQL_FormatQuery(dbLocal, sQuery, sizeof(sQuery), "SELECT * FROM SmartOpen_Maps WHERE MapName = '%s'", MapName);
		
		SQL_TQuery(dbLocal, SQLCB_GetButtonHammerID, sQuery, _, DBPrio_High);
	}
}

public SQLCB_GetButtonHammerID(Handle:db, Handle:hndl, const String:sError[], dummy_value)
{
	if(hndl == null)
		ThrowError(sError);
	
	else if(SQL_GetRowCount(hndl) == 0)
	{
		new String:sQuery[256];
		SQL_FormatQuery(dbLocal, sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SmartOpen_Maps (MapName, ButtonHammerID, IsolationHammerID) VALUES ('%s', -1, -1)", MapName);	
	
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_High);
		
		ButtonHID = -1;
		IsolationHID = -1;
		return;
	}

	if(!SQL_FetchRow(hndl))
	{
		new String:sQuery[256];
		SQL_FormatQuery(dbLocal, sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SmartOpen_Maps (MapName, ButtonHammerID, IsolationHammerID) VALUES ('%s', -1, -1)", MapName);	
	
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_High);
		
		
		ButtonHID = -1;
		IsolationHID = -1;
		return;
	}
	
	ButtonHID = SQL_FetchInt(hndl, 1);
	IsolationHID = SQL_FetchInt(hndl, 2);
}

public SQLCB_Error(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_GraceBeforeOpen))
		return;
	
	if(ButtonHID == -1)
		return;
		
	new NewTeam = GetEventInt(hEvent, "team");
	
	if(NewTeam <= CS_TEAM_SPECTATOR)
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	if(!CanBeGraced[client])
		return;
	
	if(OpenedThisRound)
		return;
		
	RequestFrame(Frame_GraceSpawn, GetClientUserId(client));
}

public Frame_GraceSpawn(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	if(!CanBeGraced[client])
		return;
			
	if(OpenedThisRound)
		return;
			
	if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return;
	
	if(IsPlayerAlive(client))
		return;
		
	CS_RespawnPlayer(client);
	
	CanBeGraced[client] = false;
}

public Action:Event_PlayerSpawnOrDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	else if(!IsValidTeam(client))
		return;
		
	CanBeGraced[client] = false;
}

public Action:Event_RoundStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	UnhookEntityOutput("func_button", "OnPressed", OnButtonPressed);
	
	if(ButtonHID != -1)
	{
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
		{
			if(GetEntProp(ent, Prop_Data, "m_iHammerID") == ButtonHID)
				break;
		}
		
		if(ent != -1)
			HookSingleEntityOutput(ent, "OnPressed", OnButtonPressed);
	}
	OpenedThisRound = false;
	
	DestroyTimer(hTimer_AutoOpen);
	
	if(GetConVarFloat(hcv_Auto) != -1)
		hTimer_AutoOpen = CreateTimer(GetConVarFloat(hcv_Auto), AutoOpenCells, _, TIMER_FLAG_NO_MAPCHANGE);
		
	for(new i=1;i <= MaxClients;i++)
	{
		CanBeGraced[i] = true;
	}
	
	ClearTrie(Trie_Retriers);
}

public OnButtonPressed(const String:output[], caller, activator, Float:delay)
{
	if(GetEntProp(caller, Prop_Data, "m_iHammerID") != ButtonHID)
	{
		UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
		return;
	}
	
	else if(OpenedThisRound)
	{
		UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
		return;
	}
	
	OpenedThisRound = true;
	UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
}
public Action:AutoOpenCells(Handle:hTimer)
{
	if(ButtonHID != -1)
		OpenCells();
		
	hTimer_AutoOpen = INVALID_HANDLE;
}

public Action:Command_AssignOpen(client, args)
{
	new ent = FindEntityByAim(client, "func_button");
	
	if(ent < 0)
	{
		PrintToChat(client, "%s Couldn't find a \x07func_button \x01entity at your aim, please try \x07again" ,PREFIX);
		return Plugin_Handled;
	}
	
	new String:Classname[64];
	GetEdictClassname(ent, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "func_button", true))
	{
		PrintToChat(client, "%s Couldn't find a \x07func_button \x01entity at your aim, please try \x07again" ,PREFIX);
		return Plugin_Handled;
	}
	
	ButtonHID = GetEntProp(ent, Prop_Data, "m_iHammerID");
	
	new String:sQuery[256];

	SQL_FormatQuery(dbLocal, sQuery, sizeof(sQuery), "UPDATE SmartOpen_Maps SET ButtonHammerID = %i WHERE MapName = '%s'", ButtonHID, MapName);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_Normal);
	
	PrintToChat(client, "%s \x05Successfully \x01made the button you're aiming at as the button that opens the cells for \x07!open");
	return Plugin_Handled;
}


public Action:Command_AssignIsolation(client, args)
{
	new ent = FindEntityByAim(client, "func_door");
	
	if(ent < 0)
	{
		PrintToChat(client, "%s Couldn't find a \x07func_door \x01entity at your aim, please try \x07again", PREFIX);
		return Plugin_Handled;
	}
	
	new String:Classname[64];
	GetEdictClassname(ent, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "func_door", true))
	{
		PrintToChat(client, "%s Couldn't find a func_door entity at your aim, please try again", PREFIX);
		return Plugin_Handled;
	}
	
	IsolationHID = GetEntProp(ent, Prop_Data, "m_iHammerID");
	
	new String:sQuery[256];
	
	SQL_FormatQuery(dbLocal, sQuery, sizeof(sQuery), "UPDATE SmartOpen_Maps SET IsolationHammerID = %i WHERE MapName = '%s'", IsolationHID, MapName);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_Normal);
	
	PrintToChat(client, "%s \x05Successfully \x01made the door you're aiming at as the door of the isolation for \x07!hardopen");
	return Plugin_Handled;
}

public Action:Command_OpenOverride(client, args)
{
	return Plugin_Handled;
}
public Action:Command_Open(client, args)
{
	if(client != 0 && GetClientTeam(client) != CS_TEAM_CT && !CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false) && !CanEmptyRebel() && !CanLRChainsaw())
	{
		PrintToChat(client, "%s You must be \x0BCT \x01to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	
	else if(OpenedThisRound)
	{
		PrintToChat(client, "%s Cells were \x07already \x01opened this round!");
		return Plugin_Handled;
	}
	
	else if(ButtonHID == -1 && GetConVarInt(hcv_Mode) == 0)
	{
		PrintToChat(client, "Map does not have an assigned open button!");
		PrintToChat(client, "An admin must use !assignopen to assign a button.");
		return Plugin_Handled;
	}
	
	
	if(!OpenCells())
	{
		PrintToChat(client, "The map's assigned open button is bugged!");
		return Plugin_Handled;
	}
	
	new String:Title[64];
	
	Title = "Rebel";
	
	if(client != 0)
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
			Title = "Warden";
		
		else if(GetClientTeam(client) == CS_TEAM_T && CanLRChainsaw())
			Title = "LR"
			
		else if(CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false))
			Title = "Admin";
	}
	else 
		Title = "Admin";
	
	if(client != 0)
		PrintToChatAll("%s \x05%N \x01opened the \x07jail \x01cells!" ,PREFIX, client);
		
	return Plugin_Handled;
}

public Action:Command_HardOpen(client, args)
{
	if(client != 0 && GetClientTeam(client) != CS_TEAM_CT && !CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false) && !CanEmptyRebel())
	{
		PrintToChat(client, "%s You must be \x0BCT \x01to use this \x07command!" ,PREFIX);
		return Plugin_Handled;
	}
	
	else if(ButtonHID == -1 && GetConVarInt(hcv_Mode) == 0)
	{
		PrintToChat(client, "Map does not have an assigned open button!");
		PrintToChat(client, "An admin must use !assignopen to assign a button.");
		return Plugin_Handled;
	}
	
	else if(OpenedThisRound)
	{
		OpenIsolation();
		PrintToChat(client, "%s Cells were \x07already \x01opened this \x05round!" ,PREFIX);
		return Plugin_Handled;
	}
	else if(!OpenCells())
	{
		PrintToChat(client, "The map's assigned open button is bugged!");
		return Plugin_Handled;
	}
	
	new String:Title[64];
	
	Title = "Rebel";
	if(client != 0)
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
			Title = "Warden";
			
		else if(CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false))
			Title = "Admin";
	}
	else
		Title = "Admin";
	
	if(client != 0)
		PrintToChatAll("%s \x05%N \x01hard opened the \x07jail \x01cells!" ,PREFIX, client);
		
	OpenIsolation();
	return Plugin_Handled;
}

stock bool:OpenCells()
{
	if(OpenedThisRound)
		return false;
	
	new target;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		target = i;
		break;
	}
	
	if(target == 0)
		return false;
		
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		target = i;
		break;
	}
	new ent = -1;
	if(ButtonHID == -1)
	{
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
			AcceptEntityInput(ent, "PressIn", target);
	}
	
	else
	{
		new bool:Found = false;
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
		{
			if(GetEntProp(ent, Prop_Data, "m_iHammerID") == ButtonHID)
			{
				Found = true;
				break;
			}
		}
		
		if(!Found)
			return false;
			
		AcceptEntityInput(ent, "PressIn", target);
	}
	
	OpenedThisRound = true;
	
	return true;
}


stock bool:OpenIsolation()
{
	new target;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		target = i;
		break;
	}
	
	if(target == 0)
		return false;
		
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		target = i;
		break;
	}
	new bool:Found = false;
	
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1)
	{
		if(GetEntProp(ent, Prop_Data, "m_iHammerID") == IsolationHID)
		{
			Found = true;
			break;
		}
	}
	
	if(!Found)
		return false;
		
	AcceptEntityInput(ent, "Open", target);
	
	return true;
}

stock DestroyTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		CloseHandle(timer);
		timer = INVALID_HANDLE;
	}
}

stock FindEntityByAim(client, const String:Classname[])
{
	new Float:eyeOrigin[3], Float:eyeAngles[3];
	
	GetClientEyePosition(client, eyeOrigin);
	GetClientEyeAngles(client, eyeAngles);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, Classname);
	TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_HitClassname, DP);
	
	CloseHandle(DP);
	
	if(!TR_DidHit(INVALID_HANDLE))
		return -1;
		
	return TR_GetEntityIndex(INVALID_HANDLE);
}


public bool:TraceRay_HitClassname(entityhit, mask, Handle:DP) 
{
	new String:Classname[64], String:Classname2[64];
	
	ResetPack(DP);
	ReadPackString(DP, Classname, sizeof(Classname));
	
	GetEdictClassname(entityhit, Classname2, sizeof(Classname2));

	return StrEqual(Classname, Classname2, true);
}

stock GetTeamPlayerCount(Team)
{
	new count = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) == Team)
			count++;
	}
	return count;
}

stock bool:CanEmptyRebel()
{
	return (GetConVarBool(hcv_EmptyRebel) && GetTeamPlayerCount(CS_TEAM_CT) == 0);
}

stock bool:CanLRChainsaw()
{
	return (GetConVarBool(hcv_LRChainsaw) && GetTeamPlayerCount(CS_TEAM_T) == 1);
}

stock bool IsValidTeam(int client)
{
	return GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T;
}