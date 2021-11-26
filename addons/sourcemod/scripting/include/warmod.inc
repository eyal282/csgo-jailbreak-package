#define SPECTATOR_TEAM 1
#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

#define DEFAULT_CT_NAME "Counter-Terrorists"
#define DEFAULT_T_NAME "Terrorists"

#define PLAYER_DISC -1
#define PLAYER_READY 1
#define PLAYER_UNREADY 2

#define SCORE_CT 0
#define SCORE_T 1

#define SCORE_FIRST_HALF 0
#define SCORE_SECOND_HALF 1

#define DMG_MSG_SIZE 8192

#define NUM_WEAPONS        28
#define LOG_HIT_OFFSET     7

#define	LOG_HIT_SHOTS      0
#define	LOG_HIT_HITS       1
#define	LOG_HIT_KILLS      2
#define	LOG_HIT_HEADSHOTS  3
#define	LOG_HIT_TEAMKILLS  4
#define	LOG_HIT_DAMAGE     5
#define	LOG_HIT_DEATHS     6
#define LOG_HIT_GENERIC    7
#define LOG_HIT_HEAD       8
#define LOG_HIT_CHEST      9
#define LOG_HIT_STOMACH    10
#define LOG_HIT_LEFTARM    11
#define LOG_HIT_RIGHTARM   12
#define LOG_HIT_LEFTLEG    13
#define LOG_HIT_RIGHTLEG   14
#define LOG_HIT_NUM        15

#define CLUTCH_LAST        0
#define CLUTCH_VERSUS      1
#define CLUTCH_FRAGS       2
#define CLUTCH_WON         3
#define CLUTCH_NUM         4

#define WM_VERSION "3.0.11"
#define WM_DESCRIPTION "An automative service created by Twelve-60 of GameTech (www.gametech.com.au) for CS:S competition matches"


/*********************************************************
 *  called when a match starting LiveOn3 
 * 
 * @noreturn		
 *********************************************************/
forward OnLiveOn3();


/*********************************************************
 *  called when a match reaches half time
 *  includes when in overtime
 * 
 * @noreturn
 *********************************************************/
forward OnHalfTime();


/*********************************************************
 *  called when a match reaches full time
 *  not called if match is prematurely reset
 * 
 * @noreturn
 *********************************************************/
forward OnEndMatch();


/*********************************************************
 *  called when a match half is reset
 *  only occurs if match was currently underway
 * 
 * @noreturn
 *********************************************************/
forward OnResetHalf();


/*********************************************************
 *  called when a match is reset
 *  only occurs if match was currently underway
 * 
 * @noreturn
 *********************************************************/
forward OnResetMatch();


/*********************************************************
 *  get the logstring ("player<userid><authid><team>") for the specified client
 * 
 * @param  client		the client index to get name for
 * @param  String:LogString	the buffer to save the logstring in
 * @param  size			the size of the buffer
 * @return 			-1 on not connected
 *				client index
 *********************************************************/

stock CS_GetLogString(client, String:LogString[], size)
{
	if (client == 0 || !IsClientInGame(client))
		return -1;

	new String:player_name[32];
	new userid;
	new String:authid[32];
	new String:team[32];
	
	GetClientName(client, player_name, sizeof(player_name));
	GetClientAuthString(client, authid, sizeof(authid));
	userid = GetClientUserId(client);
	
	if (GetClientTeam(client) == TERRORIST_TEAM)
	{
		team = "TERRORIST";
	}
	else if(GetClientTeam(client) == COUNTER_TERRORIST_TEAM)
	{
		team = "CT";
	}
	else if(GetClientTeam(client) == SPECTATOR_TEAM)
	{
		team = "Spectator";
	}
	
	Format(LogString, size, "%s<%d><%s><%s>", player_name, userid, authid, team);

	return client;
}


/*********************************************************
 *  get the advanced logstring ("player<userid><authid><team><origin_x><origin_y><origin_z><velocity_x><velocity_y><velocity_z><health><armour><helmut>") for the specified client
 * 
 * @param  client		the client index to get name for
 * @param  String:LogString	the buffer to save the logstring in
 * @param  size			the size of the buffer
 * @return 			-1 on not connected
 *				client index
 *********************************************************/

stock CS_GetAdvLogString(client, String:LogString[], size)
{
	if (client == 0 || !IsClientConnected(client))
	{
		return -1;
	}
	
	new String:player_name[32];
	new userid;
	new String:authid[32];
	new String:team[32];
	new Float:player_origin[3];
	new Float:eye_angles[3];
	
	GetClientName(client, player_name, sizeof(player_name));
	GetClientAuthString(client, authid, sizeof(authid));
	userid = GetClientUserId(client);
	
	if (GetClientTeam(client) == TERRORIST_TEAM)
	{
		team = "TERRORIST";
	}
	else if(GetClientTeam(client) == COUNTER_TERRORIST_TEAM)
	{
		team = "CT";
	}
	else if(GetClientTeam(client) == SPECTATOR_TEAM)
	{
		team = "Spectator";
	}
		
	GetClientAbsOrigin(client, player_origin);
	GetClientEyeAngles(client, eye_angles);

	Format(LogString, size, "%s<%d><%s><%s><%.2f><%.2f><%.2f><%.2f><%.2f><%.2f><%.2f><%.2f><%.2f><%d><%d><%d>", player_name, userid, authid, team, player_origin[0], player_origin[1], player_origin[2] + GetEntPropFloat(client, Prop_Send, "m_vecViewOffset[2]"), eye_angles[0], eye_angles[1], eye_angles[2], GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]"), GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]"), GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]"), GetEntProp(client, Prop_Send, "m_iHealth"), GetEntProp(client, Prop_Send, "m_ArmorValue"), GetEntProp(client, Prop_Send, "m_bHasHelmet"));

	return client;
}


/*********************************************************
 *  get the comma'd string version of an integer
 * 
 * @param  OldMoney		the integer to convert
 * @param  String:NewMoney	the buffer to save the string in
 * @param  size			the size of the buffer
 * @noreturn
 *********************************************************/

stock IntToMoney(OldMoney, String:NewMoney[], size)
{
	new String:Temp[32];
	new String:OldMoneyStr[32];
	new tempChar;
	new RealLen = 0;

	IntToString(OldMoney, OldMoneyStr, sizeof(OldMoneyStr));

	for (new i = strlen(OldMoneyStr) - 1; i >= 0; i--)
	{
		if (RealLen % 3 == 0 && RealLen != strlen(OldMoneyStr) && i != strlen(OldMoneyStr)-1)
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, sizeof(Temp), "%s,%s", tempChar, Temp);
		}
		else
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, sizeof(Temp), "%s%s", tempChar, Temp);
		}
		RealLen++;
	}
	Format(NewMoney, size, "%s", Temp);
}


/*********************************************************
 *  get the team index opposite to the specified team
 * 
 * @param  team		team index to get opposite of
 * @return		false on error
 *			team index
 *********************************************************/

stock GetOtherTeam(team)
{
	if (team == 2)
	{
		return 3;
	}
	else if (team == 3)
	{
		return 2;
	}
	else
	{
		return false;
	}
}


/*********************************************************
 *  swap all players to the opposite team
 *  allows for skin choice
 * 
 * @noreturn
 *********************************************************/

stock CS_SwapTeams()
{
	new max_clients = GetMaxClients();
	for (new i = 1; i <= max_clients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			ChangeClientTeam(i, GetOtherTeam(GetClientTeam(i)));
		}
	}
}


/*********************************************************
 *  returns number of clients currently playing on a team
 * 
 * return		count
 *********************************************************/

stock CS_GetPlayingCount()
{
	new count;
	new max_clients = GetMaxClients();
	for (new i = 1; i <= max_clients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			count++;
		}
	}
	return count;
}


/*********************************************************
 *  strip all weapons from specified client but the knife
 * 
 * @noreturn
 *********************************************************/

stock CS_StripButKnife(client, bool:equip=true)
{
	if (!IsClientInGame(client) || GetClientTeam(client) <= 1)
	{
		return false;
	}
	
	new item_index;
	for (new i = 0; i < 5; i++)
	{
		if (i == 2)
		{
			continue;
		}
		if ((item_index = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, item_index);
		}
		if (equip)
		{
			CS_EquipKnife(client);
		}
	}

	return true;
}


/*********************************************************
 *  return the number of players alive on a given team
 * 
 * @noreturn
 *********************************************************/

stock GetNumAlive(team)
{
	new count;
	new max_clients = GetMaxClients();
	for (new i = 1; i < max_clients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
		{
			count++;
		}
	}
	return count;
}


/*********************************************************
 *  Equip the specified client with the knife
 * 
 * @noreturn
 *********************************************************/

stock CS_EquipKnife(client)
{
	ClientCommand(client, "slot3");
}


/*********************************************************
 *  Removing filename invalid characters
 * 
 * @noreturn
 *********************************************************/

stock StripFilename(String:filename[], size)
{
	ReplaceString(filename, size, "\\", "");
	ReplaceString(filename, size, "/", "");
	ReplaceString(filename, size, ":", "");
	ReplaceString(filename, size, "*", "");
	ReplaceString(filename, size, "?", "");
	ReplaceString(filename, size, "<", "");
	ReplaceString(filename, size, ">", "");
	ReplaceString(filename, size, "|", "");
	ReplaceString(filename, size, ";", "");
	ReplaceString(filename, size, "-", "+");
	ReplaceString(filename, size, " ", "_");
}


/*********************************************************
 *  Converting a string to lowercase
 * 
 * @noreturn
 *********************************************************/

stock StringToLower(String:input[], size)
{
	for (new i = 0; i < size; i++)
	{
		input[i] = CharToLower(input[i]);
	}
}


/*********************************************************
 *  Hide setting an int cvar
 * 
 * @noreturn
 *********************************************************/
 
stock SetConVarIntHidden(Handle:cvar, const value)
{
	new String:cvar_name[64];
	new String:value_string[512];
	new flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, flags & ~FCVAR_NOTIFY);
	SetConVarInt(cvar, value);
	GetConVarName(cvar, cvar_name, sizeof(cvar_name));
	IntToString(value, value_string, sizeof(value_string));
	Steam_SetRule(cvar_name, value_string);
	SetConVarFlags(cvar, flags);
}


/*********************************************************
 *  Hide setting a string cvar
 * 
 * @noreturn
 *********************************************************/
 
stock SetConVarStringHidden(Handle:cvar, String:value[])
{
	new String:cvar_name[64];
	new flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, flags & ~FCVAR_NOTIFY);
	SetConVarString(cvar, value);
	GetConVarName(cvar, cvar_name, sizeof(cvar_name));
	Steam_SetRule(cvar_name, value);
	SetConVarFlags(cvar, flags);
}