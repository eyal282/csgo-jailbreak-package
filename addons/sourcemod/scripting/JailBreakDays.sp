#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <eyal-jailbreak>

enum enDay
{
	NULL_DAY = 0,
	LR_DAY,
	FS_DAY,
	SCOUT_DAY,
	KNIFE_DAY,
	WAR_DAY,
	SDEAGLE_DAY
}

new String:DayName[][] =
{
	"IF YOU SEE THIS MESSAGE CONTACT ADMIN!",
	"IF YOU SEE THIS MESSAGE CONTACT ADMIN!",
	"FreeStyle Day",
	"Scout Day",
	"Knife Day",
	"War Day",
	"Super Deagle Day"
}

native Gangs_HasGang(client);
native Gangs_GetClientGangName(client, String:GangName[], len);
native Gangs_PrintToChatGang(String:GangName[], String:format[], any:...);
native Gangs_AddClientDonations(client, amount);
native Gangs_GiveGangCredits(const String:GangName[], amount);
native Gangs_GiveClientCredits(client, amount);
native Gangs_AreClientsSameGang(client, otherClient);
native Gangs_TryDestroyGlow(client);
native Float:Gangs_GetFFDamageDecrease(client);

new String:BotName[] = "GlowX Bot";

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "JailBreak Days",
	author = "Eyal282",
	description = "JailBreak Days",
	version = PLUGIN_VERSION,
	url = ""
}

new bool:IgnorePlayerDeaths;

new Handle:hcv_TeammatesAreEnemies = INVALID_HANDLE;
new Handle:hcv_IgnoreRoundWinConditions = INVALID_HANDLE;

new Handle:fw_OnDayStatus = INVALID_HANDLE;

new Handle:hTimer_StartDay = INVALID_HANDLE;

new enDay:DayActive = NULL_DAY;

new String:DayWeapon[64], bool:DayHSOnly;

new DayCountDown;

new Bot;

new bool:GlowRemoved;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	 CreateNative("JailBreakDays_IsDayActive", Native_IsDayActive);
	 
	 return APLRes_Success;
}


public Native_IsDayActive(Handle:plugin, numParams)
{
	return DayActive > LR_DAY;
}

public OnPluginStart()
{
	if(WePlay_IPCheck())
	{
		RegAdminCmd("sm_startfsday", Command_StartFSDay, ADMFLAG_ROOT);
		RegAdminCmd("sm_startscoutday", Command_StartScoutDay, ADMFLAG_ROOT);
		RegAdminCmd("sm_startknifeday", Command_StartKnifeDay, ADMFLAG_ROOT);
		RegAdminCmd("sm_startwarday", Command_StartWarDay, ADMFLAG_ROOT);
		RegAdminCmd("sm_startsdeagleday", Command_StartSDeagleDay, ADMFLAG_ROOT);
		
		HookEvent("weapon_fire", Event_WeaponTryFire, EventHookMode_Post);
		HookEvent("weapon_fire_on_empty", Event_WeaponTryFire, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	}
	
	hcv_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	hcv_IgnoreRoundWinConditions = FindConVar("mp_ignore_round_win_conditions");
	
	// Called when there's a need to inform plugins of day status. Not guaranteed to be the exact start or stop.
	// public JailBreakDays_OnDayStatus(bool:DayActive)
	
	fw_OnDayStatus = CreateGlobalForward("JailBreakDays_OnDayStatus", ET_Ignore, Param_Cell);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		OnClientPutInServer(i);
	}
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(DayActive != SCOUT_DAY)
		return Plugin_Continue;
	
	new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(wep == -1)
		return Plugin_Continue;
		
	new String:Classname[64];
	GetEdictClassname(wep, Classname, sizeof(Classname));
	
	if(StrEqual(Classname, "weapon_ssg08"))
		buttons &= ~IN_ATTACK2;
		
	return Plugin_Continue;
}

public OnMapStart()
{
	hTimer_StartDay = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	if(client == Bot && Bot != 0)
	{
		Bot = 0;
		
		if(DayActive > LR_DAY)
			CreateBot();
	}
		
	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, SDKEvent_WeaponCanUse);
	SDKHook(client, SDKHook_PostThinkPost, SDKEvent_PostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, SDKEvent_OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, SDKEvent_TraceAttack);
}

public Action SDKEvent_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	if(!IsEntityPlayer(attacker))
		return Plugin_Continue;
	
	else if(DayActive <= LR_DAY)
		return Plugin_Continue;
	
	if(!Gangs_AreClientsSameGang(victim, attacker))
		return Plugin_Continue;
		
	
	new bool:OnlyGangLeft = true;
	
	new refClient = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_T)
			continue;
		
		if(refClient == 0)
		{
			refClient = i;
			
			continue;
		}
		
		else if(!Gangs_AreClientsSameGang(i, refClient))
		{
			OnlyGangLeft = false;

			break;
		}
	}
	
	if(!OnlyGangLeft)
	{
		damage *= 1.0 - Gangs_GetFFDamageDecrease(victim);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action SDKEvent_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{	
	if(!IsEntityPlayer(attacker))
		return Plugin_Continue;
	
	else if(DayActive <= LR_DAY)
		return Plugin_Continue;
	
	if(GetClientTeam(attacker) != GetClientTeam(victim))
	{
		damage = 0.0;
		
		return Plugin_Changed;
	}
	
	else if(!DayHSOnly)
		return Plugin_Continue;
	
	else if(hitgroup == 1)
		return Plugin_Continue;
		
	damage = 0.0;
	return Plugin_Changed;
}
public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if(DayActive == SCOUT_DAY)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action:Eyal282_VoteCT_OnVoteCTStartAutoPre()
{
	if(DayActive >= LR_DAY)
	{
		if(hTimer_StartDay == INVALID_HANDLE && !IsVoteInProgress())
			ServerCommand("sm_silentcvar mp_teammates_are_enemies 1");
			
		return Plugin_Handled;
	}	
	return Plugin_Continue;
}

public Action:SDKEvent_WeaponCanUse(client, weapon)
{
	if(IgnorePlayerDeaths) // The very moment a day begins.
		return Plugin_Continue;
		
	switch(DayActive)
	{
		case SCOUT_DAY:
		{
			new String:Classname[64];
			GetEdictClassname(weapon, Classname, sizeof(Classname));

			if(StrEqual(Classname, "weapon_ssg08"))
				return Plugin_Continue;

			else if(GetAliveTeamCount(CS_TEAM_T) == 2 && strncmp(Classname, "weapon_knife", 12) == 0)
				return Plugin_Continue;
				
			AcceptEntityInput(weapon, "Kill");
			return Plugin_Handled;
		}
		
		case KNIFE_DAY:
		{
			new String:Classname[64];
			GetEdictClassname(weapon, Classname, sizeof(Classname));

			if(strncmp(Classname, "weapon_knife", 12) == 0)
				return Plugin_Continue;
				
			AcceptEntityInput(weapon, "Kill");
			return Plugin_Handled;
		}
		
		case SDEAGLE_DAY:
		{
			new String:Classname[64];
			GetEdictClassname(weapon, Classname, sizeof(Classname));

			if(StrEqual(Classname, "weapon_deagle"))
				return Plugin_Continue;
				
			PrintToChat(client, Classname);
			AcceptEntityInput(weapon, "Kill");
			return Plugin_Handled;
		}
		
		case WAR_DAY:
		{
			new String:Classname[64];
			GetEdictClassname(weapon, Classname, sizeof(Classname));

			if(StrEqual(Classname, DayWeapon))
				return Plugin_Continue;
				
			AcceptEntityInput(weapon, "Kill");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:SDKEvent_PostThinkPost(client)
{
	if(DayActive == SCOUT_DAY)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if(weapon != -1)
			SetEntPropFloat(weapon, Prop_Send, "m_fAccuracyPenalty", 0.0);
	}
}

public Action:Command_StartFSDay(client, args)
{
	ServerCommand("sm_silentstopck");
	
	StopDay(false);
	
	StartFSDay();
	
	ServerCommand("sm_stopvotect");
	ServerCommand("sm_egr");
	
	PrintToChatAll("%s \x05%N \x01started \x07%s! ", PREFIX, client, DayName[DayActive]);
	
	return Plugin_Handled;
}


public Action:Command_StartScoutDay(client, args)
{

	StopDay(false);
	
	StartScoutDay();
	
	ServerCommand("sm_stopvotect");
	ServerCommand("sm_egr");
	
	PrintToChatAll("%s \x05%N \x01started \x07%s! ", PREFIX, client, DayName[DayActive]);
	
	return Plugin_Handled;
}

public Action:Command_StartKnifeDay(client, args)
{
	ServerCommand("sm_silentstopck");
	
	StopDay(false);
	
	StartKnifeDay();
	
	ServerCommand("sm_stopvotect");
	ServerCommand("sm_egr");
	
	PrintToChatAll("%s \x05%N \x01started \x07%s! ", PREFIX, client, DayName[DayActive]);
	
	return Plugin_Handled;
}

public Action:Command_StartWarDay(client, args)
{
	ServerCommand("sm_silentstopck");
	
	ServerCommand("sm_stopvotect");
	ServerCommand("sm_egr");
	
	StopDay(false);
	
	SelectWeaponWarDay();
	
	PrintToChatAll("%s \x05%N \x01started \x07%s! ", PREFIX, client, DayName[DayActive]);
	
	return Plugin_Handled;
}

public Action:Command_StartSDeagleDay(client, args)
{
	ServerCommand("sm_silentstopck");
	
	StopDay(false);
	
	StartSDeagleDay();
	
	ServerCommand("sm_stopvotect");
	ServerCommand("sm_egr");
	
	PrintToChatAll("%s \x05%N \x01started \x07%s! ", PREFIX, client, DayName[DayActive]);
	
	return Plugin_Handled;
}

public StartFSDay()
{
	SetConVarBool(hcv_IgnoreRoundWinConditions, true);
	
	ServerCommand("sm_hardopen");

	DayActive = FS_DAY;
	
	IgnorePlayerDeaths = true;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	IgnorePlayerDeaths = false;
	
	DayCountDown = 10 + 1;
	hTimer_StartDay = CreateTimer(1.0, Timer_StartDay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public StartScoutDay()
{
	SetConVarBool(hcv_IgnoreRoundWinConditions, true);
	
	DayActive = SCOUT_DAY;
	
	ServerCommand("sm_hardopen");
	
	new Count = GetEntityCount();
	
	for(new i=MaxClients+1;i < Count;i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		new String:Classname[64];
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "game_player_equip") || StrEqual(Classname, "player_weaponstrip") || StrContains(Classname, "weapon_") != -1)
			AcceptEntityInput(i, "Kill");
	}
	
	IgnorePlayerDeaths = true;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	IgnorePlayerDeaths = false;
	
	DayCountDown = 10 + 1;
	hTimer_StartDay = CreateTimer(1.0, Timer_StartDay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public StartKnifeDay()
{
	SetConVarBool(hcv_IgnoreRoundWinConditions, true);
	
	DayActive = KNIFE_DAY;
	
	ServerCommand("sm_hardopen");
	
	new Count = GetEntityCount();
	
	for(new i=MaxClients+1;i < Count;i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		new String:Classname[64];
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "game_player_equip") || StrEqual(Classname, "player_weaponstrip") || StrContains(Classname, "weapon_") != -1)
			AcceptEntityInput(i, "Kill");
	}
	
	IgnorePlayerDeaths = true;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	IgnorePlayerDeaths = false;

	DayCountDown = 10 + 1;
	hTimer_StartDay = CreateTimer(1.0, Timer_StartDay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public StartSDeagleDay()
{
	SetConVarBool(hcv_IgnoreRoundWinConditions, true);
	
	DayActive = SDEAGLE_DAY;
	
	ServerCommand("sm_hardopen");
	
	new Count = GetEntityCount();
	
	for(new i=MaxClients+1;i < Count;i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		new String:Classname[64];
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "game_player_equip") || StrEqual(Classname, "player_weaponstrip") || StrContains(Classname, "weapon_") != -1)
			AcceptEntityInput(i, "Kill");
	}

	IgnorePlayerDeaths = true;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	IgnorePlayerDeaths = false;
	
	DayCountDown = 10 + 1;
	hTimer_StartDay = CreateTimer(1.0, Timer_StartDay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}


SelectWeaponWarDay()
{
	if(IsVoteInProgress())
		CancelVote();
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	Handle hMenu = CreateMenu(WarDayWeapon_VoteHandler);
	SetMenuTitle(hMenu, "Choose which weapon will play:");
	
	AddMenuItem(hMenu, "weapon_ak47", "AK-47");
	AddMenuItem(hMenu, "weapon_awp", "AWP");
	AddMenuItem(hMenu, "weapon_m4a1", "M4A4");
	AddMenuItem(hMenu, "weapon_sg556", "SG-553");
	AddMenuItem(hMenu, "weapon_aug", "AUG");
	AddMenuItem(hMenu, "weapon_scar20", "Scar20");

	VoteMenuToAll(hMenu, 10);
	
	DayActive = WAR_DAY;
}


public int WarDayWeapon_VoteHandler(Handle hMenu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_VoteCancel)
	{
		param1 = GetRandomInt(0, 5); // 5 = (Amount of items - 1)
		
		new String:WeaponTitle[64];
		GetMenuItem(hMenu, param1, DayWeapon, sizeof(DayWeapon), _, WeaponTitle, sizeof(WeaponTitle));
		
		PrintToChatAll("%s The winning weapon is \x07%s", PREFIX, WeaponTitle);

		SelectHSWarDay();
		
		return;
	}
	else if (action == MenuAction_VoteEnd)
	{			
	
		new String:WeaponTitle[64];
		GetMenuItem(hMenu, param1, DayWeapon, sizeof(DayWeapon), _, WeaponTitle, sizeof(WeaponTitle));
		
		PrintToChatAll("%s The winning weapon is \x07%s", PREFIX, WeaponTitle);
		
		SelectHSWarDay();
	}
}

SelectHSWarDay()
{
	if(IsVoteInProgress())
	{
		ServerCommand("mp_restartgame 1");
		
		PrintToChatAll("%s Error couldn't start vote for \x07HS \x01only, contact \x05Eyal282!", PREFIX);
		return;
	}	
	
	Handle hMenu = CreateMenu(WarDayHS_VoteHandler);
	
	// Prefix
	SetMenuTitle(hMenu, "Should HeadShot Only rules apply?");
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");

	VoteMenuToAll(hMenu, 10);
}


public int WarDayHS_VoteHandler(Handle hMenu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_VoteCancel)
	{
		if(DayActive != WAR_DAY)
			return;
			
		param1 = GetRandomInt(0, 1);
		
		DayHSOnly = !param1;
		
		PrintToChatAll("%s HS Only is \x07%sactive!", PREFIX, DayHSOnly ? "" : "not ");
		
		StartWarDay();
		
		return;
	}
	else if (action == MenuAction_VoteEnd)
	{		
		if(DayActive != WAR_DAY)
			return;
			
		DayHSOnly = !param1;
		

		PrintToChatAll("%s HS Only is \x07%sactive!", PREFIX, DayHSOnly ? "" : "not ");
		
		StartWarDay();
	}
}

StartWarDay()
{
	ServerCommand("sm_hardopen");
	
	SetConVarBool(hcv_IgnoreRoundWinConditions, true);
	
	new Count = GetEntityCount();
	
	for(new i=MaxClients+1;i < Count;i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		new String:Classname[64];
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "game_player_equip") || StrEqual(Classname, "player_weaponstrip") || StrContains(Classname, "weapon_") != -1)
			AcceptEntityInput(i, "Kill");
	}
	
	IgnorePlayerDeaths = true;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsValidTeam(i))
			continue;
		
		ChangeClientTeam(i, CS_TEAM_T);
		
		CS_RespawnPlayer(i);
	}	
	
	IgnorePlayerDeaths = false;
	
	DayCountDown = 10 + 1;
	hTimer_StartDay = CreateTimer(1.0, Timer_StartDay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:Timer_StartDay(Handle:hTimer)
{
	DayCountDown--;
	
	KickBotImposters();
	
	Call_StartForward(fw_OnDayStatus);
	
	Call_PushCell(true);
	
	Call_Finish();
	
	if(DayCountDown == 0)
	{
		SetConVarBool(hcv_TeammatesAreEnemies, true);
		
		PrintCenterTextAll("<font color='#FF0000'>%s has begun</font>", DayName[DayActive]);
	
		hTimer_StartDay = INVALID_HANDLE;
		
		CreateBot();
		
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("<font color='#FFFFFF'>%s will begin in </font><font color='#FF0000'>%i</font> <font color='#FFFFFF'>second%s!</font><font color='#FF0000'></font>", DayName[DayActive], DayCountDown, DayCountDown == 1 ? "" : "s");
		
	return Plugin_Continue;
}

stock StopDay(bool:Restart = true, bool:ShouldKickBot = true)
{
	GlowRemoved = false;
	
	if(DayActive > LR_DAY && IsVoteInProgress())
		CancelVote();
		
	DayActive = NULL_DAY;
	
	DayHSOnly = false;
	
	SetConVarBool(hcv_TeammatesAreEnemies, false);
	SetConVarBool(hcv_IgnoreRoundWinConditions, false);
	
	if(Restart)
		ServerCommand("mp_restartgame 1");
	
	if(hTimer_StartDay != INVALID_HANDLE)
	{
		CloseHandle(hTimer_StartDay);
		hTimer_StartDay = INVALID_HANDLE;
	}
	
	if(ShouldKickBot)
	{
		KickBot();
	}
	
	Call_StartForward(fw_OnDayStatus);
	
	Call_PushCell(false);
	
	Call_Finish();
}

CreateBot()
{
	KickBot();
	
	Bot = CreateFakeClient(BotName);
		
	KickBotImposters();
	
	if(Bot != 0)
	{
		DispatchSpawn(Bot);
		
		ActivateEntity(Bot);
		
		ChangeClientTeam(Bot, CS_TEAM_CT);
		
		CS_RespawnPlayer(Bot);
		
		SetEntProp(Bot, Prop_Data, "m_takedamage", 0);
		
		SetEntityRenderMode(Bot, RENDER_NONE);
		
		new Float:Origin[3];
		GetEntPropVector(Bot, Prop_Data, "m_vecOrigin", Origin);
		
		Origin[2] = -32767.0;
		TeleportEntity(Bot, Origin, NULL_VECTOR, NULL_VECTOR);
	}
}
KickBot()
{
	if(Bot != 0)
	{
		ChangeClientTeam(Bot, CS_TEAM_SPECTATOR);
		
		KickClient(Bot);
		
		Bot = 0;
	}
	else
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(!IsFakeClient(i))
				continue;
				
			new String:Name[64];
			GetClientName(i, Name, sizeof(Name));
			
			if(StrEqual(Name, BotName))
			{
				ChangeClientTeam(i, CS_TEAM_SPECTATOR);
				
				KickClient(i);
			}
		}
	}
}

KickBotImposters()
{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(IsFakeClient(i))
				continue;
				
			new String:Name[64];
			GetClientName(i, Name, sizeof(Name));
			
			if(StrEqual(Name, BotName))
				KickClient(i, "This name is restricted");
		}
}
public Action:Event_RoundStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	StopDay(false);
}

public Action:Event_WeaponTryFire(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(DayActive == NULL_DAY)
		return;

	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	new String:Classname[64];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(StrEqual(Classname, "weapon_deagle") || StrEqual(Classname, "weapon_ssg08"))
		SetClientAmmo(client, weapon, 999);
		
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(DayActive == NULL_DAY || IgnorePlayerDeaths)
		return;
	
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	
	if(IsFakeClient(victim))
		return;
		
	else if(DayActive == LR_DAY)
	{
		StopDay(true, true);
		
		return;
	}
	
	new LivingT = GetAliveTeamCount(CS_TEAM_T);
	new bool:OnlyGangLeft = LivingT > 1; // Don't care if the day is over
	
	
	new refClient = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_T)
			continue;
		
		if(refClient == 0)
		{
			refClient = i;
			
			continue;
		}
		
		else if(!Gangs_AreClientsSameGang(i, refClient))
		{
			OnlyGangLeft = false;

			break;
		}
	}
	
	if(OnlyGangLeft && !GlowRemoved)
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(!IsPlayerAlive(i))
				continue;
				
			Gangs_TryDestroyGlow(i);
		}
		
		new String:GangName[32];
		Gangs_GetClientGangName(refClient, GangName, sizeof(GangName));
		
		PrintToChatAll("%s The gang \x07%s \x01won the \x05day! \x01it will now fight eachother.", PREFIX, GangName);
		
		GlowRemoved = true;
	}
	
	if(LivingT == 2 && DayActive == SCOUT_DAY)
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			GivePlayerItem(i, "weapon_knife");
		}
		
		PrintToChatAll("%s FIGHT FIGHT FIGHT", PREFIX);
		PrintToChatAll("%s FIGHT FIGHT FIGHT", PREFIX);
		PrintToChatAll("%s FIGHT FIGHT FIGHT", PREFIX);
		PrintToChatAll("%s FIGHT FIGHT FIGHT", PREFIX);
		PrintToChatAll("%s FIGHT FIGHT FIGHT", PREFIX);
	}
	
	if(LivingT != 1)
		return;
		
	new Winner = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(!IsPlayerAlive(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_T)
			continue;
			
		Winner = i;
		break;
	}
	
	if(Winner != 0)
	{
		PrintToChatAll("%s \x05%N \x01won the \x07%s! ", PREFIX, Winner, DayName[DayActive]);
		PrintCenterTextAll("<font color='#FF0000'>%N</font><font color='#FFFFFF'> won the %s!</font>", Winner, DayName[DayActive]);
	    
		new Reward = 50 * GetPlayersCount();
		
		if(Gangs_HasGang(Winner))
		{
			new String:GangName[64];
			Gangs_GetClientGangName(Winner, GangName, sizeof(GangName));

			Gangs_GiveGangCredits(GangName, Reward);
			Gangs_AddClientDonations(Winner, Reward);
			
			Gangs_PrintToChatGang(GangName, " \x0B[JB Gangs] \x05%N \x01has earned \x07%i \x01credits for his gang by winning the \x07%s! ", Winner, Reward, DayName[DayActive]);
		}
		
		Reward = RoundFloat(float(Reward) / 1.5);
		
		PrintToChatAll(" \x0B[JB Gangs] \x05%N \x01has earned \x07%i \x01gang credits by winning the \x07%s! ", Winner, Reward, DayName[DayActive]);
		
		Gangs_GiveClientCredits(Winner, Reward);
		
		ChangeClientTeam(victim, CS_TEAM_CT);
		
		RequestFrame(Frame_RespawnASAP, victim);
		
		KickBot();
		
		DayActive = LR_DAY;
	}
	else
		ServerCommand("mp_restartgame 1");
}

public void Frame_RespawnASAP(victim)
{
	if(!IsClientInGame(victim)) // victim can't be replaced in one frame, no need for user id.
		return;
		
	CS_RespawnPlayer(victim);
}


public Action:Event_PlayerHurt(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client;
	if(DayActive != NULL_DAY)
	{
		client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
		SetEntityMaxHealth(client, GetEntityHealth(client));
	}
	
	if(DayActive != SDEAGLE_DAY)
		return;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == 0 || client == 0)
		return;
		
	BitchSlapBackwards(client, attacker, 5150.0);
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(hEvent, "userid");
	
	CreateTimer(0.1, Timer_PlayerSpawn, UserId, TIMER_FLAG_NO_MAPCHANGE);
	
}

public Action:Timer_PlayerSpawn(Handle:hTimer, UserId)
{
	if(DayActive <= LR_DAY)
		return;
		
	new client = GetClientOfUserId(UserId);
	
	switch(DayActive)
	{
		case FS_DAY, KNIFE_DAY:
		{
			UC_StripPlayerWeapons(client);
			
			GivePlayerItem(client, "weapon_knife");
		}
		
		case SCOUT_DAY:
		{
			new LivingT = 0;
			
			for(new i=1;i <= MaxClients;i++)
			{
				if(!IsClientInGame(i))
					continue;
					
				else if(!IsValidTeam(i))
					continue;
				
				LivingT++;
			}	
			
			UC_StripPlayerWeapons(client);
				
			GivePlayerItem(client, "weapon_ssg08");
				
			if(LivingT == 2)
				GivePlayerItem(client, "weapon_knife");	
		}
		
		case SDEAGLE_DAY:
		{
			UC_StripPlayerWeapons(client);
		
			GivePlayerItem(client, "weapon_deagle");
			
			SetEntityHealth(client, 350);
		}
		
		case WAR_DAY:
		{
			UC_StripPlayerWeapons(client);
		
			GivePlayerItem(client, DayWeapon);
			
			SetEntityHealth(client, 250);
		}
	}
	
	SetEntityMaxHealth(client, GetEntityHealth(client));
}
stock GetAliveTeamCount(Team)
{
	new count = 0;
	
	for(new i=1;i <= MaxClients;i++)
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

stock GetPlayersCount()
{
	new count = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_T && GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		count++;
	}
	
	return count;
}

stock bool:IsValidTeam(client)
{
	return (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT);
}


stock UC_StripPlayerWeapons(client)
{
	for(new i=0;i <= 5;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			i--; // This is to strip all nades, and zeus & knife
		}
	}
}

stock SetClientAmmo(client, weapon, ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
    
  new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  if(ammotype == -1) return;
  
  SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

public BitchSlapBackwards(victim, weapon, Float:strength) // Stole the dodgeball tactic from https://forums.alliedmods.net/showthread.php?t=17116
{
	new Float:origin[3], Float:velocity[3];
	GetEntPropVector(weapon, Prop_Data, "m_vecOrigin", origin);
	GetVelocityFromOrigin(victim, origin, strength, velocity);
	velocity[2] = strength / 10.0;
	
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
}


stock GetVelocityFromOrigin(ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3]) // Will crash server if fSpeed = -1.0
{
	new Float:fEntOrigin[3];
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", fEntOrigin);
	
	// Velocity = Distance / Time
	
	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0];
	fDistance[1] = fEntOrigin[1] - fOrigin[1];
	fDistance[2] = fEntOrigin[2] - fOrigin[2];

	new Float:fTime = ( GetVectorDistance(fEntOrigin, fOrigin) / fSpeed );
	
	if(fTime == 0.0)
		fTime = 1 / (fSpeed + 1.0);
		
	fVelocity[0] = fDistance[0] / fTime;
	fVelocity[1] = fDistance[1] / fTime;
 	fVelocity[2] = fDistance[2] / fTime;

	return (fVelocity[0] && fVelocity[1] && fVelocity[2]);
}

stock bool IsEntityPlayer(int entity)
{
	if(entity == 0 || entity > MaxClients)
		return false;
		
	return true;
}

stock SetEntityMaxHealth(entity, amount)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", amount);
}

stock GetEntityHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

// Bar, do not sell the include below this line

#include <smlib>

/**
* בודק האם השרת מאושר ע"י בודק האייפי של וויפליי
*
* @return					true if client is high management, false otherwise.
*/
stock bool:WePlay_IPCheck()
{
	new String:ServerIP[32];
	
	char Path[256];
	FormatEx(Path, sizeof(Path), "scripts/sound_dont_prefetch.txt"); // LMAOOOO. Total bullshit file name
	
	Server_GetIPString(ServerIP, sizeof(ServerIP));
	
	Handle hFile = OpenFile(Path, "r");
	
	if(hFile == INVALID_HANDLE)
		return false;
		
	new String:FileLine[256];
	
	ReadFileLine(hFile, FileLine, sizeof(FileLine));
	
	ReplaceString(FileLine, sizeof(FileLine), "_", ".");
	
	ReplaceString(FileLine, sizeof(FileLine), "-", ":");
	
	CloseHandle(hFile);
	
	char params[2][64];
	char IPAddress[64]
	int Port;
	
	ExplodeString(FileLine, ":", params, 2, 64, false);
	
	FormatEx(IPAddress, sizeof(IPAddress), params[0]);
	
	Port = StringToInt(params[1]);
	
	char FullServerIP[64], FullIP[64];
	
	FormatEx(FullServerIP, sizeof(FullServerIP), "%s:%i", ServerIP, Server_GetPort());
	FormatEx(FullIP, sizeof(FullIP), "%s:%i", IPAddress, Port);
	
	if(!StrEqual(FullServerIP, FullIP))
	{
		return false;
	}
	
	return true;
}


stock void StringToLower(char[] sSource)
{
	for (int i = 0; i < strlen(sSource); i++) {
		if (sSource[i] == '\0')
			break;

		sSource[i] = CharToLower(sSource[i]);
	}
}


stock bool:IsClientEyal(client)
{
	new String:steamid[64];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		
	if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
		return true;
		
	return false;
}

stock bool:IsClientBar(client)
{
	new String:steamid[64];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		
	if(StrEqual(steamid, "STEAM_1:1:110581296"))
		return true;
		
	return false;
}