#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "xFlane, edit by Eyal282"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>
//#include <sdkhooks>


#define PREFIX " \x0B[WePlay]\x01 "

#define SECONDS_IN_MINUTE 60

int g_iBanCTUnix[MAXPLAYERS + 1];
bool g_bBanCTBool[MAXPLAYERS + 1];

Database dbCTBan;

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	/* Translations */
	LoadTranslations("common.phrases");
	
	/* SQL */
	if (dbCTBan == INVALID_HANDLE)
	{
		char error[256];
		Database hndl;
		if((hndl = SQLite_UseDatabase("JailBreak-BanCT", error, sizeof(error))) == INVALID_HANDLE)
			SetFailState(error);

		else
		{
			dbCTBan = hndl;
			
			SQL_TQuery(dbCTBan, SQL_NoAction, "CREATE TABLE IF NOT EXISTS `jb_banct` ( `auth` varchar(32) NOT NULL UNIQUE, `banctunix` int(15) NOT NULL, `reason` varchar(256) NOT NULL, `name` varchar(64) NOT NULL, `admin` varchar(64) NOT NULL )");
		}
	}
	
	
	/* ConVars */
	RegAdminCmd("sm_banct", Command_BanCT, ADMFLAG_BAN, "Ban player from the counter-terrorist team.");
	RegAdminCmd("sm_ctban", Command_BanCT, ADMFLAG_BAN, "Ban player from the counter-terrorist team.");
	RegAdminCmd("sm_unbanct", Command_UnbanCT, ADMFLAG_BAN, "Unban player from the counter-terrorist team.");
	RegAdminCmd("sm_unctban", Command_UnbanCT, ADMFLAG_BAN, "Unban player from the counter-terrorist team.");
	RegAdminCmd("sm_ctunban", Command_UnbanCT, ADMFLAG_BAN, "Unban player from the counter-terrorist team.");
	RegAdminCmd("sm_ctbanlist", Command_CTBanList, ADMFLAG_BAN, "List of CT Bans");
}

/* Hooks, etc.. */

public void OnClientPostAdminCheck(int client)
{
	g_bBanCTBool[client] = false;
	g_iBanCTUnix[client] = 0;
	
	char SteamID[32];
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID));
	
	char aQuery[255];
	SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "SELECT banctunix from jb_banct where auth='%s'", SteamID);
	SQL_TQuery(dbCTBan, SQL_LoadPlayer, aQuery, GetClientSerial(client));
}

/* */

/* Natives */

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("Ban_CT");
	CreateNative("IsPlayerBannedFromCT", Native_IsPlayerBanned);
	CreateNative("IsPlayerBannedFromGuardsTeam", Native_IsPlayerBanned);
	
	CreateNative("GetPlayerBanCTUnix", Native_GetPlayerUnix);
}

public int Native_IsPlayerBanned(Handle plugin, int numParams) {
	
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client  index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	int currentTime = GetTime();
	if (currentTime > g_iBanCTUnix[client])
	{
		g_iBanCTUnix[client] = 0;
		g_bBanCTBool[client] = false;
		
		char SteamID[32];
		GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID));
	
		char aQuery[255];
		SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "DELETE from jb_banct where auth='%s'", SteamID);
		SQL_TQuery(dbCTBan, SQL_NoAction, aQuery);
	}
	
	return g_bBanCTBool[client] ? 1:0;
}


public int Native_GetPlayerUnix(Handle plugin, int numParams) {
	
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client  index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	return g_iBanCTUnix[client];
}
/* */

/* SQL CALLBACKS */

public void SQL_NoAction(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[BANCT] SQL ERROR: %s", error);
	}
}

public void SQL_LoadPlayer(Handle owner, Handle hndl, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	
	if(client == 0)
		return;
		
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[BANCT DATABASE] %s", error);
	}
	
	else if (SQL_GetRowCount(hndl))
	{
		int currentTime = GetTime();
		while (SQL_FetchRow(hndl))
		{
			g_iBanCTUnix[client] = SQL_FetchInt(hndl, 0);
			if (currentTime < g_iBanCTUnix[client])
			{
				g_bBanCTBool[client] = true;
			}
			else
			{
				char SteamID[32];
				GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID));
			
				char aQuery[255];
				SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "DELETE from jb_banct where auth='%s'", SteamID);
				SQL_TQuery(dbCTBan, SQL_NoAction, aQuery);
			}
		}
	}
	
	return;
}

/* */

/* Commands */

public Action Command_BanCT(int client, int args)
{
	if(args < 3)
	{
		PrintToChat(client, "%s Syntax error: /banct <target> <time (in minutes)> <reason>", PREFIX);
		return Plugin_Handled;
	}
	
	char Arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int target = FindTarget(client, Arg1, true);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(g_bBanCTBool[target])
	{
		PrintToChat(client, "%s \x02%N\x01 is already banned from the \x0Ccounter-terrorist team.", PREFIX, target);
		return Plugin_Handled;
	}
	
	char Arg2[11];
	GetCmdArg(2, Arg2, sizeof(Arg2));
	
	int time = StringToInt(Arg2);
	
	if(time <= 0)
	{
		PrintToChat(client, "%s You cant ban player for less than \x021\x01 minute.", PREFIX);
		return Plugin_Handled;
	}
	
	char ArgStr[256];
	char dummy_value[64];
	char Reason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	int len = BreakString(ArgStr, dummy_value, sizeof(dummy_value));
	
	int len2 = BreakString(ArgStr[len], dummy_value, sizeof(dummy_value));
	
	if(len2 != -1)
	{
		FormatEx(Reason, sizeof(Reason), ArgStr[len+len2]);
	}
	else
	{
		PrintToChat(client, "%s You cant ban player for without giving a reason!", PREFIX);
		return Plugin_Handled;
	}	
		
	time *= SECONDS_IN_MINUTE;

	g_iBanCTUnix[target] = GetTime() + time;
	g_bBanCTBool[target] = true;
	
	char TimeFormat[64];
	FormatTime(TimeFormat, sizeof(TimeFormat), "%d/%m/%y %H:%M:%S", g_iBanCTUnix[target]);
	
	PrintToChatAll("%s \x02%N\x01 has banned \x02%N\x01 from the \x0Ccounter-terrorist team.", PREFIX, client, target);
	PrintToChatAll("%s The ban will expire at: \x02%s\x01.", PREFIX, TimeFormat);
	
	if(GetClientTeam(target) == CS_TEAM_CT)
	{
		ForcePlayerSuicide(target);
		
		CS_SwitchTeam(target, CS_TEAM_T);
	}
	
	char SteamID[32];
	GetClientAuthId(target, AuthId_Engine, SteamID, sizeof(SteamID));
	
	char aQuery[255];
	SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "INSERT IGNORE INTO jb_banct (auth,banctunix,reason,name,admin) VALUES ('%s','%i','%s','%N','%N')", SteamID, g_iBanCTUnix[target], Reason, target, client);
	SQL_TQuery(dbCTBan, SQL_NoAction, aQuery);
	
	return Plugin_Handled;
}

public Action Command_UnbanCT(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "%s Syntax error: /unbanct <target>", PREFIX);
		return Plugin_Handled;
	}
	
	char Arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int target = FindTarget(client, Arg1, true);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(!g_bBanCTBool[target])
	{
		PrintToChat(client, "%s \x02%\x01 is not banned from the \x0Ccounter-terrorist team.", PREFIX, target);
		return Plugin_Handled;
	}
	
	g_bBanCTBool[target] = false;
	g_iBanCTUnix[target] = 0;
	
	PrintToChatAll("%s \x02%N\x01 has unbanned \x02%N\x01 from the \x0Ccounter-terrorist team.", PREFIX, client, target);
	
	char SteamID[32];
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID));
	
	char aQuery[255];
	SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "DELETE from jb_banct where auth='%s'", SteamID);
	SQL_TQuery(dbCTBan, SQL_NoAction, aQuery);
		
	return Plugin_Handled;
}


public Action Command_CTBanList(int client, int args)
{
	char aQuery[255];
	SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "SELECT * from jb_banct ORDER BY banctunix DESC");
	SQL_TQuery(dbCTBan, SQL_ShowCTBanList, aQuery, GetClientUserId(client));
		
	return Plugin_Handled;
}


public SQL_ShowCTBanList(Handle DB, Handle hndl, const char[] sError, UserId)
{
	if (hndl == null)
		ThrowError(sError);
    
	else if(SQL_GetRowCount(hndl) == 0)
		return;
		
	new client = GetClientOfUserId(UserId);
    
	if(client != 0)
	{	
		new Handle:hMenu = CreateMenu(MenuHandler_BanInfo);
	
		while(SQL_FetchRow(hndl))
		{
			new String:Name[64], String:AuthId[35];
			
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			SQL_FetchString(hndl, 3, Name, sizeof(Name));
				
			AddMenuItem(hMenu, AuthId, Name);
		}
		
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}


public int MenuHandler_BanInfo(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		char AuthId[32];
		
		GetMenuItem(hMenu, item, AuthId, sizeof(AuthId));
		
		char aQuery[255];
		SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "SELECT * from jb_banct where auth='%s'", AuthId);
		
		SQL_TQuery(dbCTBan, SQL_ShowBanInfo, aQuery, GetClientUserId(client));
	}
}

public SQL_ShowBanInfo(Handle DB, Handle hndl, const char[] sError, UserId)
{
	if (hndl == null)
		ThrowError(sError);
    
	else if(SQL_GetRowCount(hndl) != 1)
		return;
		
	new client = GetClientOfUserId(UserId);
    
	if(client != 0)
	{	
		new Handle:hMenu = CreateMenu(MenuHandler_DeleteBan);
	
		if(SQL_FetchRow(hndl))
		{
			new String:Name[64], String:AdminName[64], ExpireDate, String:TimeFormat[64], String:Reason[256], String:AuthId[35];
			
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			ExpireDate = SQL_FetchInt(hndl, 1);
			SQL_FetchString(hndl, 2, Reason, sizeof(Reason));
			SQL_FetchString(hndl, 3, Name, sizeof(Name));
			SQL_FetchString(hndl, 4, AdminName, sizeof(AdminName));
		
			FormatTime(TimeFormat, sizeof(TimeFormat), "%d/%m/%y %H:%M:%S", ExpireDate);
			
			SetMenuTitle(hMenu, "[CT Ban] Client name: %s\nAdmin Name: %s\nReason: %s\nExpires: %s", Name, AdminName, Reason, TimeFormat);
			
			AddMenuItem(hMenu, AuthId, "Remove Ban");
			
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public int MenuHandler_DeleteBan(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		char AuthId[32];
		
		GetMenuItem(hMenu, item, AuthId, sizeof(AuthId));
		
		PrintToChat(client, "%s \x02Unbanned Auth Id %s", PREFIX, AuthId);
		
		char aQuery[255];
		SQL_FormatQuery(dbCTBan, aQuery, sizeof(aQuery), "DELETE from jb_banct where auth='%s'", AuthId);
		SQL_TQuery(dbCTBan, SQL_NoAction, aQuery);
		
		new target = FindClientByAuthId(AuthId);
		
		if(target != 0)
		{
			g_bBanCTBool[target] = false;
			g_iBanCTUnix[target] = 0;
		}
	}
}

stock FindClientByAuthId(const String:AuthId[])
{
	new String:iAuthId[35];
	for(new i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		GetClientAuthId(i, AuthId_Engine, iAuthId, sizeof(iAuthId));
		
		if(StrEqual(AuthId, iAuthId, true))
			return i;
	}
	
	return 0;
}