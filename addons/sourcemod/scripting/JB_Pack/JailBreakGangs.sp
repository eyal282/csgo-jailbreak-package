

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <eyal-jailbreak>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/SourceMod-GameData-Updater/master/Offsets/PlayerMaxSpeed/updatefile.txt"

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

#pragma newdecls required

char NET_WORTH_ORDER_BY_FORMULA[512];

bool dbFullConnected = false;

native bool JailBreakDays_IsDayActive();

int GangColors[][] =
{
   {255, 0, 0}, // red
   {0, 255, 0}, // green
   {137, 209, 183}, // green כהה
   {4, 1, 254}, // Blue
   {194, 1, 254}, // perpol
   {194, 255, 254}, // d תכלת
   {75, 150, 102}, // d ירוק בהיר
   {47, 44, 16}, // d חום
   {193, 168, 16}, // d צהוב זהב
   {193, 103, 16}, // d כתום
   {193, 103, 111}, // d pink
   {193, 36, 111}, // d pink כהה
   {193, 255, 111}, // d green כהה
   {253, 255, 111}, // d Yellow כהה
   {10, 107, 111}, // d תכלת כהה
   {126, 3, 0}, // d חום חזק
   {126, 108, 170}, // d סגלגל
   {240, 156, 20}, // d כתמתם
   {234, 30, 80}, // d ורדורד
   {156, 120, 80}, // d חםחם
   {156, 120, 229}, // d סגול פנים
   {156, 120, 229}, // d ורוד כהה
   {33, 120, 229}, // d כחלכל
   {33, 120, 7}, // d ירקרק
   {254, 120, 7}, // d כתום חזק
   {161, 207, 254}, // d תכלת חלש
   {254, 207, 254}, // d ורוד פוקסי
   {137, 147, 148}, // d אפור
   {252, 64, 100}, // d אדם דם
   {58, 64, 100}, // d אפור חלש
   {55, 51, 72}, // d שחרחר
   {145, 127, 162} // d סגל גל בהיר
}

Handle dbGangs = INVALID_HANDLE;

Handle hcv_HonorPerKill = INVALID_HANDLE;

#define MIN_PLAYERS_FOR_GC 3

#define GANG_COSTCREATE 100000

#define GANG_HEALTHCOST 7500
#define GANG_HEALTHMAX 5
#define GANG_HEALTHINCREASE 2

#define GANG_SPEEDCOST 8000
#define GANG_SPEEDMAX 8
#define GANG_SPEEDINCREASE 3.5

#define GANG_NADECOST 5000
#define GANG_NADEMAX 10
#define GANG_NADEINCREASE 1.5

#define GANG_GETCREDITSCOST 6000
#define GANG_GETCREDITSMAX 10
#define GANG_GETCREDITSINCREASE 15

#define GANG_FRIENDLYFIRECOST 7500
#define GANG_FRIENDLYFIREMAX 5
#define GANG_FRIENDLYFIREINCREASE 20

#define GANG_INITSIZE 4
#define GANG_SIZEINCREASE 1
#define GANG_SIZECOST 6500
#define GANG_SIZEMAX 3

#define GANG_NULL ""

#define RANK_NULL -1
#define RANK_MEMBER 0
#define RANK_OFFICER 1
#define RANK_ADMIN 2
#define RANK_MANAGER 3
#define RANK_COLEADER 4
#define RANK_LEADER 420

// Variables about the client's gang.

int ClientRank[MAXPLAYERS+1], ClientGangHonor[MAXPLAYERS+1], ClientHonor[MAXPLAYERS+1];
bool ClientLoadedFromDb[MAXPLAYERS + 1];
char ClientGang[MAXPLAYERS+1][32], ClientMotd[MAXPLAYERS+1][32], ClientTag[MAXPLAYERS+1][32];

int ClientHealthPerkT[MAXPLAYERS+1], ClientSpeedPerkT[MAXPLAYERS+1], ClientNadePerkT[MAXPLAYERS+1], ClientHealthPerkCT[MAXPLAYERS+1], ClientSpeedPerkCT[MAXPLAYERS+1], ClientGetHonorPerk[MAXPLAYERS+1], ClientGangSizePerk[MAXPLAYERS+1], ClientFriendlyFirePerk[MAXPLAYERS+1];

// ClientAccessManage basically means if the client can either invite, kick, upgrade, promote or MOTD.
int ClientAccessManage[MAXPLAYERS+1], ClientAccessInvite[MAXPLAYERS+1], ClientAccessKick[MAXPLAYERS+1], ClientAccessPromote[MAXPLAYERS+1], ClientAccessUpgrade[MAXPLAYERS+1], ClientAccessMOTD[MAXPLAYERS+1];

// Extra Variables.
bool GangAttemptLeave[MAXPLAYERS+1], GangAttemptDisband[MAXPLAYERS+1], GangAttemptStepDown[MAXPLAYERS+1], MotdShown[MAXPLAYERS+1];
int GangStepDownTarget[MAXPLAYERS + 1];
char GangCreateName[MAXPLAYERS+1][32], GangCreateTag[MAXPLAYERS+1][10];
int ClientMembersCount[MAXPLAYERS+1];
int ClientWhiteGlow[MAXPLAYERS+1], ClientColorfulGlow[MAXPLAYERS+1], ClientGlowColorSlot[MAXPLAYERS+1];// White glow is how gang members see themselves, colorful glow is how other players see gang members.

int ClientActionEdit[MAXPLAYERS + 1];

bool CachedSpawn[MAXPLAYERS + 1], CanGetHonor[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "JB Gangs",
    author = "Eyal282",
    description = "Gang System for JailBreak",
    version = "1.0",
    url = "NULL"
};

public void OnPluginStart()
{	

	Format(NET_WORTH_ORDER_BY_FORMULA, sizeof(NET_WORTH_ORDER_BY_FORMULA), "%i + GangHonor + GangHealthPerkT*0.5*%i*(GangHealthPerkT+1) + GangHealthPerkCT*0.5*%i*(GangHealthPerkCT+1) + GangSpeedPerkT*0.5*%i*(GangSpeedPerkT+1) + GangSpeedPerkCT*0.5*%i*(GangSpeedPerkCT+1) + GangNadePerkT*0.5*%i*(GangNadePerkT+1) + GangGetHonorPerk*0.5*%i*(GangGetHonorPerk+1) + GangSizePerk*0.5*%i*(GangSizePerk+1) + GangFFPerk*0.5*%i*(GangFFPerk+1)", GANG_COSTCREATE, GANG_HEALTHCOST, GANG_HEALTHCOST, GANG_SPEEDCOST, GANG_SPEEDCOST, GANG_NADECOST, GANG_GETCREDITSCOST, GANG_SIZECOST, GANG_FRIENDLYFIRECOST);
		
	dbFullConnected = false;
	
	dbGangs = INVALID_HANDLE;
	
	ConnectDatabase();
	
	AddCommandListener(CommandListener_Say, "say");
	AddCommandListener(CommandListener_Say, "say_team");
	
	RegConsoleCmd("sm_donategang", Command_DonateGang);
	RegConsoleCmd("sm_motdgang", Command_MotdGang);
	RegConsoleCmd("sm_creategang", Command_CreateGang);
	RegConsoleCmd("sm_gangtag", Command_CreateGangTag);
	RegConsoleCmd("sm_confirmleavegang", Command_LeaveGang);
	RegConsoleCmd("sm_confirmdisbandgang", Command_DisbandGang);
	RegConsoleCmd("sm_confirmstepdowngang", Command_StepDown);
	RegConsoleCmd("sm_gang", Command_Gang);
	RegConsoleCmd("sm_gethonor", Command_GC);
	RegConsoleCmd("sm_gc", Command_GC);
	
	RegAdminCmd("sm_breachgang", Command_BreachGang, ADMFLAG_ROOT, "Breaches into a gang as a member.");
	RegAdminCmd("sm_breachgangrank", Command_BreachGangRank, ADMFLAG_ROOT, "Sets your rank within your gang.");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	char HonorPerKillCvarName[] = "gang_system_honor_per_kill";
	
	hcv_HonorPerKill = CreateConVar(HonorPerKillCvarName, "100", "Amount of honor you get per kill as T");
	
	ServerCommand("sm_cvar protect %s", HonorPerKillCvarName);
	
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	//HandleGameData();
}

public void OnLibraryAdded(const char[] name)
{
	/*
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	*/
}

public void OnPluginEnd()
{
	for(int i=1;i < MAXPLAYERS+1;i++)
	{
		TryDestroyGlow(i);
	}
}
/*
HandleGameData()
{	
	new String:FileName[300], Handle:hGameConf;

	BuildPath(Path_SM, FileName, sizeof(FileName), "gamedata/%s.txt", const_GameDataFile);
	if( !FileExists(FileName) )
	{
		if(!Updater_ForceUpdate())
			SetFailState("Could not find offset PlayerMaxSpeedOffset.");
			
		return;
	}
	
	
	hGameConf = LoadGameConfigFile(const_GameDataFile);
	
	new PlayerMaxSpeedOffset = GameConfGetOffset(hGameConf, "PlayerMaxSpeedOffset");
	
	DHook_PlayerMaxSpeed = DHookCreate(PlayerMaxSpeedOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, CCSPlayer_GetPlayerMaxSpeed);
	
	if(DHook_PlayerMaxSpeed == INVALID_HANDLE)
	{
		if(!Updater_ForceUpdate())
			SetFailState("Could not DHook PlayerMaxSpeed");
			
		return;
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		DHookEntity(DHook_PlayerMaxSpeed, true, i);
	}
}

public MRESReturn:CCSPlayer_GetPlayerMaxSpeed(client, Handle:hReturn, Handle:hParams)
{	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return MRES_Ignored;
	
	else if(GetAliveTeamCount(CS_TEAM_T) <= 1)
		return MRES_Ignored;
	
	new Float:Maxspeed = DHookGetReturn(hReturn);
	
	if(Maxspeed < 1.0)
		return MRES_Ignored;
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_T: Maxspeed += (ClientSpeedPerkT[client] * GANG_SPEEDINCREASE);
		case CS_TEAM_CT: Maxspeed += (ClientSpeedPerkCT[client] * GANG_SPEEDINCREASE);
	}

	DHookSetReturn(hReturn, Maxspeed);
	return MRES_Supercede;
}

public Updater_OnPluginUpdated()
{
	new String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));

	ServerCommand("changelevel %s", MapName);
}
*/
public void LastRequest_OnLRStarted(int Prisoner, int Guard)
{
///	SDKUnhook(Prisoner, SDKHook_PostThink, Event_PreThinkT);
//	SDKUnhook(Prisoner, SDKHook_PostThink, Event_PreThinkCT);
	//SDKUnhook(Guard, SDKHook_PreThink, Event_PreThinkT);
	//SDKUnhook(Guard, SDKHook_PreThink, Event_PreThinkCT);
}

public void Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	CachedSpawn[client] = false;
	RequestFrame(Event_PlayerSpawnPlusFrame, GetEventInt(hEvent, "userid"));
}
public void Event_PlayerSpawnPlusFrame(int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(CachedSpawn[client])
		return;
		
	else if(!IsValidPlayer(client))
		return;
		
	else if(!IsPlayerAlive(client))
		return;
	
	else if(!IsClientGang(client))
		return;
	
	CachedSpawn[client] = true;
	
	TryDestroyGlow(client);
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			if(ClientHealthPerkT[client] > 0)	
			{
				SetEntityHealth(client, GetEntityHealth(client) + (ClientHealthPerkT[client] * GANG_HEALTHINCREASE));
				SetEntityMaxHealth(client, GetEntityMaxHealth(client) + (ClientHealthPerkT[client] * GANG_HEALTHINCREASE));
			}
			
			if(ClientNadePerkT[client] > 0)
			{
				if(GetRandomFloat(0.0, 100.0) <= (float(ClientNadePerkT[client]) * GANG_NADEINCREASE))
				{
					switch(GetRandomInt(0, 3))
					{
						case 0: GivePlayerItem(client, "weapon_incgrenade");
						case 1: GivePlayerItem(client, "weapon_flashbang");
						case 2: GivePlayerItem(client, "weapon_hegrenade");
						case 3: GivePlayerItem(client, "weapon_decoy");
					}
					
					PrintToChat(client, " %s \x05You \x01spawned with a random nade for being in a \x07gang! " ,PREFIX);
				}
			}
			
			if(IsClientGang(client) && JailBreakDays_IsDayActive())
				CreateGlow(client);
		}
		case CS_TEAM_CT:
		{
			if(ClientHealthPerkCT[client] > 0)	
			{
				SetEntityHealth(client, GetEntityHealth(client) + (ClientHealthPerkCT[client] * GANG_HEALTHINCREASE));
				SetEntityMaxHealth(client, GetEntityMaxHealth(client) + (ClientHealthPerkCT[client] * GANG_HEALTHINCREASE));
			}
		}
	}
}

void CreateGlow(int client)
{
	if(EntRefToEntIndex(ClientWhiteGlow[client]) != INVALID_ENT_REFERENCE && EntRefToEntIndex(ClientColorfulGlow[client]) != INVALID_ENT_REFERENCE)
		return;
		
	if(ClientWhiteGlow[client] != 0 || ClientColorfulGlow[client] != 0)
	{
		TryDestroyGlow(client);
		ClientWhiteGlow[client] = 0;
		ClientColorfulGlow[client] = 0;
	}	
	
	CreateWhiteGlow(client);
	
	CreateColorfulGlow(client);
}

void CreateWhiteGlow(int client)
{
	char Model[PLATFORM_MAX_PATH];
	float Origin[3], Angles[3];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	// Find the location of the weapon
	GetClientEyePosition(client, Origin);
	Origin[2] -= 75.0;
	GetClientEyeAngles(client, Angles);
	int GlowEnt = CreateEntityByName("prop_dynamic_glow");
	
	DispatchKeyValue(GlowEnt, "model", Model);
	DispatchKeyValue(GlowEnt, "disablereceiveshadows", "1");
	DispatchKeyValue(GlowEnt, "disableshadows", "1");
	DispatchKeyValue(GlowEnt, "solid", "0");
	DispatchKeyValue(GlowEnt, "spawnflags", "256");
	DispatchKeyValue(GlowEnt, "renderamt", "0");
	SetEntProp(GlowEnt, Prop_Send, "m_CollisionGroup", 11);
		
	// Spawn and teleport the entity
	DispatchSpawn(GlowEnt);
	
	int fEffects = GetEntProp(GlowEnt, Prop_Send, "m_fEffects");
	SetEntProp(GlowEnt, Prop_Send, "m_fEffects", fEffects|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);

	// Give glowing effect to the entity
	SetEntProp(GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(GlowEnt, Prop_Send, "m_flGlowMaxDist", 10000.0);

	// Set glowing color
	SetVariantColor({255, 255, 255, 255});
	AcceptEntityInput(GlowEnt, "SetGlowColor");

	// Set the activator and group the entity
	SetVariantString("!activator");
	AcceptEntityInput(GlowEnt, "SetParent", client);
	
	SetVariantString("primary");
	AcceptEntityInput(GlowEnt, "SetParentAttachment", GlowEnt, GlowEnt, 0);
	
	AcceptEntityInput(GlowEnt, "TurnOn");
	
	SetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity", client);
	
	char iName[32];

	FormatEx(iName, sizeof(iName), "Gang-Glow %i", GetClientUserId(client));
	SetEntPropString(GlowEnt, Prop_Data, "m_iName", iName);
	
	SDKHook(GlowEnt, SDKHook_SetTransmit, Hook_ShouldSeeWhiteGlow);
	
	CreateTimer(0.1, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.3, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.1, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	
	ClientWhiteGlow[client] = GlowEnt;
}


void CreateColorfulGlow(int client)
{
	char Model[PLATFORM_MAX_PATH];
	float Origin[3], Angles[3];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	// Find the location of the weapon
	GetClientEyePosition(client, Origin);
	Origin[2] -= 75.0;
	GetClientEyeAngles(client, Angles);
	int GlowEnt = CreateEntityByName("prop_dynamic_glow");
	
	DispatchKeyValue(GlowEnt, "model", Model);
	DispatchKeyValue(GlowEnt, "disablereceiveshadows", "1");
	DispatchKeyValue(GlowEnt, "disableshadows", "1");
	DispatchKeyValue(GlowEnt, "solid", "0");
	DispatchKeyValue(GlowEnt, "spawnflags", "256");
	DispatchKeyValue(GlowEnt, "renderamt", "0");
	SetEntProp(GlowEnt, Prop_Send, "m_CollisionGroup", 11);
		
	// Spawn and teleport the entity
	DispatchSpawn(GlowEnt);
	
	int fEffects = GetEntProp(GlowEnt, Prop_Send, "m_fEffects");
	SetEntProp(GlowEnt, Prop_Send, "m_fEffects", fEffects|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);

	// Give glowing effect to the entity
	SetEntProp(GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(GlowEnt, Prop_Send, "m_flGlowMaxDist", 10000.0);

	// Set glowing color
	
	int VarColor[4] = {255, 255, 255, 255};
	
	for(int i=0;i < 3;i++)
	{
		VarColor[i] = GangColors[ClientGlowColorSlot[client]][i];
	}
	
	SetVariantColor(VarColor);
	AcceptEntityInput(GlowEnt, "SetGlowColor");

	// Set the activator and group the entity
	SetVariantString("!activator");
	AcceptEntityInput(GlowEnt, "SetParent", client);
	
	SetVariantString("primary");
	AcceptEntityInput(GlowEnt, "SetParentAttachment", GlowEnt, GlowEnt, 0);
	
	AcceptEntityInput(GlowEnt, "TurnOn");
	
	SetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity", client);
	
	char iName[32];

	FormatEx(iName, sizeof(iName), "Gang-Glow %i", GetClientUserId(client));
	SetEntPropString(GlowEnt, Prop_Data, "m_iName", iName);
	
	SDKHook(GlowEnt, SDKHook_SetTransmit, Hook_ShouldSeeColorfulGlow);
	
	CreateTimer(0.1, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.3, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.1, Timer_CheckGlowPlayerModel, EntIndexToEntRef(GlowEnt), TIMER_FLAG_NO_MAPCHANGE);
	
	ClientColorfulGlow[client] = GlowEnt;
}

public Action Timer_CheckGlowPlayerModel(Handle hTimer, int Ref)
{
	int GlowEnt = EntRefToEntIndex(Ref);
	
	if(GlowEnt == INVALID_ENT_REFERENCE)
		return;
		
	int client = GetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return;
		
	char Model[PLATFORM_MAX_PATH];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	SetEntityModel(GlowEnt, Model);
}

public Action Hook_ShouldSeeWhiteGlow(int glow, int viewer)
{
	if(!IsValidEntity(glow))
		return Plugin_Continue;
		
	int client = GetEntPropEnt(glow, Prop_Send, "m_hOwnerEntity");
	
	if(client == viewer)
		return Plugin_Handled;
		
	else if(!AreClientsSameGang(client, viewer))
		return Plugin_Handled;
		
	else if(GetClientTeam(viewer) != GetClientTeam(client))
		return Plugin_Handled;
	
	int ObserverTarget = GetEntPropEnt(viewer, Prop_Send, "m_hObserverTarget"); // This is the player the viewer is spectating. No need to check if it's invalid ( -1 )
	
	if(ObserverTarget == client)
		return Plugin_Handled;

	return Plugin_Continue;
}


public Action Hook_ShouldSeeColorfulGlow(int glow, int viewer)
{
	if(!IsValidEntity(glow))
		return Plugin_Continue;
		
	int client = GetEntPropEnt(glow, Prop_Send, "m_hOwnerEntity");
	
	if(AreClientsSameGang(client, viewer))
		return Plugin_Handled;
	
	int ObserverTarget = GetEntPropEnt(viewer, Prop_Send, "m_hObserverTarget"); // This is the player the viewer is spectating. No need to check if it's invalid ( -1 )
	
	if(ObserverTarget == client)
		return Plugin_Handled;

	return Plugin_Continue;
}
public Action Event_PlayerDeath(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	TryDestroyGlow(victim);
	
	if(IsPlayer(attacker) && attacker != victim && (GetClientTeam(victim) == CS_TEAM_CT || GetAliveTeamCount(CS_TEAM_T) == 0))
	{
		int honor = GetConVarInt(hcv_HonorPerKill);
		
		bool IsVIP = CheckCommandAccess(attacker, "sm_null_command", ADMFLAG_CUSTOM2, true);
		
		if(IsVIP)
			honor *= 2;
			
		PrintToChat(attacker, "%s \x05You \x01gained \x02%i%s \x01credits for your \x07kill.", PREFIX, GetConVarInt(hcv_HonorPerKill), IsVIP ? " x 2" : "");
		
		
		GiveClientHonor(attacker, honor);
	}
}
public Action Event_RoundEnd(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		CanGetHonor[i] = true;
		
		if(IsClientGang(i) && ClientGetHonorPerk[i] > 0 && GetPlayerCount() >= MIN_PLAYERS_FOR_GC)
			PrintToChat(i, " %s \x05You \x01can write \x07!gc \x01in the chat to get \x10%i \x01credits!", PREFIX , ClientGetHonorPerk[i] * GANG_GETCREDITSINCREASE);
		
	}
}
void TryDestroyGlow(int client)
{	
	if(ClientWhiteGlow[client] != 0 && IsValidEntity(ClientWhiteGlow[client]))
	{
		AcceptEntityInput(ClientWhiteGlow[client], "Kill");
		ClientWhiteGlow[client] = 0;
	}
	
	if(ClientColorfulGlow[client] != 0 && IsValidEntity(ClientColorfulGlow[client]))
	{
		AcceptEntityInput(ClientColorfulGlow[client], "Kill");
		ClientColorfulGlow[client] = 0;
	}
	
	int ent = -1; // Some bugs don't fix themselves...
	
	while((ent = FindEntityByClassname(ent, "prop_dynamic_glow")) != -1)
	{
		char iName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", iName, sizeof(iName));
		
		if(strncmp(iName, "Gang-Glow", 9) != 0)
			continue;
		
		char dummy_value[1], sUserId[11];
		int pos = BreakString(iName, dummy_value, 0);
		
		BreakString(iName[pos], sUserId, sizeof(sUserId));
		
		int i = GetClientOfUserId(StringToInt(sUserId));
		
		if(i == 0 || !IsPlayerAlive(i) || i == client)
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public void OnClientSettingsChanged(int client)
{	
	if(IsValidPlayer(client))
		StoreClientLastInfo(client);
}

public void ConnectDatabase()
{
	char error[256];
	Handle hndl = INVALID_HANDLE;
	if((hndl = SQLite_UseDatabase("JB_Gangs", error, sizeof(error))) == INVALID_HANDLE)
		SetFailState(error);

	else
	{
		dbGangs = hndl;
		
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Members (GangName VARCHAR(32) NOT NULL, AuthId VARCHAR(32) NOT NULL UNIQUE, GangRank INT(20) NOT NULL, GangDonated INT(20) NOT NULL, LastName VARCHAR(32) NOT NULL, GangInviter VARCHAR(32) NOT NULL, GangJoinDate INT(20) NOT NULL, LastConnect INT(20) NOT NULL)", 0, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Gangs (GangName VARCHAR(32) NOT NULL UNIQUE, GangTag VARCHAR(10) NOT NULL UNIQUE, GangMotd VARCHAR(100) NOT NULL, GangHonor INT(20) NOT NULL, GangHealthPerkT INT(20) NOT NULL, GangSpeedPerkT INT(20) NOT NULL, GangNadePerkT INT(20) NOT NULL, GangHealthPerkCT INT(20) NOT NULL, GangSpeedPerkCT INT(20) NOT NULL, GangGetHonorPerk INT(20) NOT NULL, GangSizePerk INT(20) NOT NULL)", 1, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Honor (AuthId VARCHAR(32) NOT NULL UNIQUE, Honor INT(11) NOT NULL)", 2, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_upgradelogs (GangName VARCHAR(32) NOT NULL, AuthId VARCHAR(32) NOT NULL, Perk VARCHAR(32) NOT NULL, BValue INT NOT NULL, AValue INT NOT NULL, timestamp INT NOT NULL)", 3, DBPrio_High); 
		
		char sQuery[512];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankInvite INT(11) NOT NULL DEFAULT %i", RANK_OFFICER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);

		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankKick INT(11) NOT NULL DEFAULT %i", RANK_OFFICER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankPromote INT(11) NOT NULL DEFAULT %i", RANK_MANAGER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankUpgrade INT(11) NOT NULL DEFAULT %i", RANK_COLEADER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankMOTD INT(11) NOT NULL DEFAULT %i", RANK_MANAGER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs RENAME COLUMN GangCredits TO GangHonor");
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs RENAME COLUMN GangGetCreditsPerk TO GangGetHonorPerk");
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);

		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Credits RENAME TO GangSystem_Honor");
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);		
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Honor RENAME COLUMN Credits TO Honor");
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangFFPerk INT(11) NOT NULL DEFAULT 0");
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		dbFullConnected = true;
		
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
		
			else if(!IsClientAuthorized(i))
				continue;
			
			LoadClientGang(i);
		}
	}
}

public void SQLCB_Error(Handle owner, Handle hndl, const char[] Error, int QueryUniqueID) 
{ 
    /* If something fucked up. */ 
	if (hndl == null) 
		SetFailState("%s --> %i", Error, QueryUniqueID); 
} 

public void SQLCB_ErrorIgnore(Handle owner, Handle hndl, const char[] Error, int Data) 
{ 
} 

public void OnClientPutInServer(int client)
{
//	DHookEntity(DHook_PlayerMaxSpeed, true, client);	
	
	ClientWhiteGlow[client] = 0;
	ClientColorfulGlow[client] = 0;
}

public void OnClientConnected(int client)
{	
	ResetVariables(client, true);
	
	CanGetHonor[client] = false;
} 

void ResetVariables(int client, bool login = true)
{
	ClientHonor[client] = 0;
	ClientHealthPerkT[client] = 0;
	ClientSpeedPerkT[client] = 0;
	ClientNadePerkT[client] = 0;
	ClientHealthPerkCT[client] = 0;
	ClientSpeedPerkCT[client] = 0;
	
	ClientAccessManage[client] = RANK_LEADER;
	ClientAccessInvite[client] = RANK_LEADER;
	ClientAccessKick[client] = RANK_LEADER;
	ClientAccessPromote[client] = RANK_LEADER;
	ClientAccessUpgrade[client] = RANK_LEADER;
	ClientAccessMOTD[client] = RANK_LEADER;
	
	ClientGlowColorSlot[client] = -1;
	
	if(login)
	{
		GangAttemptLeave[client] = false;
		GangAttemptDisband[client] = false;
		GangAttemptStepDown[client] = false;
		GangStepDownTarget[client] = -1;
		ClientGang[client] = GANG_NULL;
		ClientRank[client] = RANK_NULL;
		ClientGangHonor[client] = 0;
	}
	ClientMotd[client] = "";
	ClientTag[client] = "";
	ClientLoadedFromDb[client] = false;
}

public void OnClientDisconnect(int client)
{
	char AuthId[35], Name[64];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	Format(Name, sizeof(Name), "%N", client);
	
	StoreAuthIdLastInfo(AuthId, Name); // Safer
	
	TryDestroyGlow(client);
}

public void OnClientPostAdminCheck(int client)
{
	if(!dbFullConnected)
		return;
		
	MotdShown[client] = false;
		
	CanGetHonor[client] = false;
	
	LoadClientGang(client);
}

void LoadClientGang(int client, int LowPrio = false)
{
	char AuthId[35]
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE AuthId = '%s'", AuthId);

	if(!LowPrio)
		SQL_TQuery(dbGangs, SQLCB_LoadClientGang, sQuery, GetClientUserId(client));
	
	else
		SQL_TQuery(dbGangs, SQLCB_LoadClientGang, sQuery, GetClientUserId(client), DBPrio_Low);
		
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Honor WHERE AuthId = '%s'", AuthId);
	
	if(!LowPrio)
		SQL_TQuery(dbGangs, SQLCB_LoadClientHonor, sQuery, GetClientUserId(client));
	
	else
		SQL_TQuery(dbGangs, SQLCB_LoadClientHonor, sQuery, GetClientUserId(client), DBPrio_Low);
}	

public void SQLCB_LoadClientGang(Handle owner, Handle hndl, char[] error, any data)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	int client = GetClientOfUserId(data);
	if(client == 0)
	{
		return;
	}
	else 
	{
		StoreClientLastInfo(client);
		
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			ClientRank[client] = SQL_FetchInt(hndl, 2);
			
			for(int i=1;i <= MaxClients;i++)
			{
				if(!IsClientInGame(i))
					continue;
				
				if(client == i)
					continue;
					
				if(!AreClientsSameGang(client, i))
					continue;

				ClientGlowColorSlot[client] = ClientGlowColorSlot[i];
			}
			
			if(ClientGlowColorSlot[client] == -1)
			{
				for(int i=0;i < sizeof(GangColors);i++)
				{
					bool glowTaken = false;
					
					for(int compareClient=1;compareClient <= MaxClients;compareClient++)
					{
						if(!IsClientInGame(compareClient))
							continue;
							
						else if(!IsClientGang(compareClient))
							continue;
							
						if(ClientGlowColorSlot[compareClient] == i)
						{
							glowTaken = true;
						}
					}
					
					if(!glowTaken)
					{
						ClientGlowColorSlot[client] = i;
						
						break;
					}
				}
			}
			char sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
			SQL_TQuery(dbGangs, SQLCB_LoadGangByClient, sQuery, GetClientUserId(client), DBPrio_High);
		}
		else
		{
			ClientLoadedFromDb[client] = true;
			
			if(IsPlayerAlive(client))
				TryDestroyGlow(client);
		}
	}
}

public void SQLCB_LoadGangByClient(Handle owner, Handle hndl, char[] error, any data)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	int client = GetClientOfUserId(data);
	if(client == 0)
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			SQL_FetchString(hndl, 1, ClientTag[client], sizeof(ClientTag[]));
			SQL_FetchString(hndl, 2, ClientMotd[client], sizeof(ClientMotd[]));
			ClientGangHonor[client] = SQL_FetchInt(hndl, 3);
			ClientHealthPerkT[client] = SQL_FetchInt(hndl, 4);
			ClientSpeedPerkT[client] = SQL_FetchInt(hndl, 5);
			ClientNadePerkT[client] = SQL_FetchInt(hndl, 6);
			ClientHealthPerkCT[client] = SQL_FetchInt(hndl, 7);
			ClientSpeedPerkCT[client] = SQL_FetchInt(hndl, 8);
			ClientGetHonorPerk[client] = SQL_FetchInt(hndl, 9);
			ClientGangSizePerk[client] = SQL_FetchInt(hndl, 10);
			ClientAccessInvite[client] = SQL_FetchInt(hndl, 11);
			ClientAccessKick[client] = SQL_FetchInt(hndl, 12);
			ClientAccessPromote[client] = SQL_FetchInt(hndl, 13);
			ClientAccessUpgrade[client] = SQL_FetchInt(hndl, 14);
			ClientAccessMOTD[client] = SQL_FetchInt(hndl, 15);
			ClientFriendlyFirePerk[client] = SQL_FetchInt(hndl, 16);
			
			int Smallest = ClientAccessInvite[client];
			
			if(ClientAccessKick[client] < Smallest)
				Smallest = ClientAccessKick[client];
				
			if(ClientAccessPromote[client] < Smallest)
				Smallest = ClientAccessPromote[client];
				
			if(ClientAccessUpgrade[client] < Smallest)
				Smallest = ClientAccessUpgrade[client];
				
			if(ClientAccessMOTD[client] < Smallest)
				Smallest = ClientAccessMOTD[client];
				
			ClientAccessManage[client] = Smallest;
			
			if(ClientMotd[client][0] != EOS && !MotdShown[client])
			{
				PrintToChat(client, " \x01=======\x07GANG MOTD\x01=========");
				PrintToChat(client, " %s", ClientGang[client]);
				PrintToChat(client, " %s", ClientMotd[client]);
				PrintToChat(client, " \x01=======\x07GANG MOTD\x01=========");
				MotdShown[client] = true;
			}	
			
			if(IsPlayerAlive(client))
				CreateGlow(client);
				
			char sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s'", ClientGang[client]);
			
			SQL_TQuery(dbGangs, SQLCB_CheckMemberCount, sQuery, GetClientUserId(client));
		}
		else // Gang was deleted
		{
			char AuthId[35];
			GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
			
			KickAuthIdFromGang(AuthId, ClientGang[client]);
			
			ClientGang[client] = GANG_NULL;
			
			if(IsPlayerAlive(client))
				TryDestroyGlow(client);
		}
		
					
		ClientLoadedFromDb[client] = true;
	}
}


public void SQLCB_LoadClientHonor(Handle owner, Handle hndl, char[] error, any data)
{
	if(hndl == null)
		SetFailState(error);

	int client = GetClientOfUserId(data);
	
	if(client == 0)
		return;

	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			ClientHonor[client] = SQL_FetchInt(hndl, 1);
		}
		else
		{
			char AuthId[35];
			GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
			
			// The reason I use INSERT OR IGNORE rather than just INSERT is bots, that can have multiple steam IDs.
			char sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO GangSystem_Honor (AuthId, Honor) VALUES ('%s', 0)", AuthId);
			
			SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 4);
			ClientHonor[client] = 0;
		}
	}
}

stock void KickClientFromGang(int client, const char[] GangName)
{
	char AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	KickAuthIdFromGang(AuthId, GangName);
}

stock void KickAuthIdFromGang(const char[] AuthId, const char[] GangName)
{
	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Members WHERE AuthId = '%s' AND GangName = '%s'", AuthId, GangName);
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 5);
	
	UpdateInGameAuthId(AuthId);
}

public Action CommandListener_Say(int client, const char[] command, int args) 
{
	if(!IsValidPlayer(client))
		return Plugin_Continue;	
	
	char Args[256];
	GetCmdArgString(Args, sizeof(Args))
	StripQuotes(Args);
	
	if(Args[0] == '#')
	{
		ReplaceStringEx(Args, sizeof(Args), "#", "");
		
		if(Args[0] == EOS)
		{	
			PrintToChat(client, " %s \x01Gang message cannot be \x07empty." ,PREFIX);
			return Plugin_Handled;
		}
		char RankName[32];
		GetRankName(GetClientRank(client), RankName, sizeof(RankName));
		
		PrintToChatGang(ClientGang[client], "\x04[Gang Chat] \x05%s \x04%N\x01 : %s", RankName, client, Args);
		
		return Plugin_Handled;
	}
	
	RequestFrame(ListenerSayPlusFrame, GetClientUserId(client));
	return Plugin_Continue;
}

public void ListenerSayPlusFrame(int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(IsClientGang(client))
	{
		if(GangAttemptDisband[client] || GangAttemptLeave[client] || GangAttemptStepDown[client])
			PrintToChat(client, " %s The operation has been \x07aborted!", PREFIX);
			
		GangAttemptDisband[client] = false;
		GangAttemptLeave[client] = false;
		GangAttemptStepDown[client] = false;
		GangStepDownTarget[client] = -1;
	}
}


public Action Command_MotdGang(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, " %s \x05You \x01have to be in a gang to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, ClientAccessMOTD[client]))
	{
		char RankName[32];
		GetRankName(ClientAccessMOTD[client], RankName, sizeof(RankName));
		PrintToChat(client, " %s \x05You \x01have to be a gang \x07%s \x01to use this \x07command!", PREFIX, RankName);
		return Plugin_Handled;	
	}
	
	char Args[100];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, " %s Invalid motd! \x05You \x01can only use \x07SPACEBAR, \x07a-z, A-Z\x01, _, -, \x070-9", PREFIX);
		return Plugin_Handled;
	}
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangMotd = '%s' WHERE GangName = '%s'", Args, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 6);
	
	PrintToChat(client, "%s The gang's motd has been changed to \x07%s", PREFIX, Args);
	
	return Plugin_Handled;
}
public Action Command_DonateGang(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to be in a \x07gang \x01to use this command!", PREFIX);
		return Plugin_Handled;
	}
	char Args[20];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	int amount = StringToInt(Args);
	
	if(StrEqual(Args, "all", false))
	{
		amount = ClientHonor[client];
		
		amount -= amount % 50;
		IntToString(amount, Args, sizeof(Args));
	}	
	if(!IsStringNumber(Args) || Args[0] == EOS)
	{
		PrintToChat(client, "%s Invalid Usage! \x07!donategang \x01<amount>", PREFIX);
		return Plugin_Handled;
	}
	else if(amount < 50 || (amount % 50) != 0)
	{
		PrintToChat(client, "%s \x05You \x01must donate at least \x0750 \x01credits and in multiples of \x0750!", PREFIX);
		return Plugin_Handled;
	}
	else if(amount > ClientHonor[client])
	{
		PrintToChat(client, "%s \x05You \x01cannot donate more credits than you \x07have.", PREFIX);
		return Plugin_Handled;
	}
	Handle hMenu = CreateMenu(DonateGang_MenuHandler);
	
	AddMenuItem(hMenu, Args, "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuTitle(hMenu, "%s Gang Donation\n\nAre you sure you want to donate %i credits?", MENU_PREFIX, amount);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int DonateGang_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		if(!IsClientGang(client))
			return;
		
		if(item + 1 == 1)
		{
			char strAmount[20];
			GetMenuItem(hMenu, item, strAmount, sizeof(strAmount))
			
			int amount = StringToInt(strAmount);
			DonateToGang(client, amount);
		}
	}
}

public Action Command_CreateGang(int client, int args)
{
	if(!ClientLoadedFromDb[client])
	{
		PrintToChat(client, "%s \x05You \x01weren't loaded from the database \x07yet!", PREFIX);
		return Plugin_Handled;
	}
	else if(IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to leave your current \x07gang \x01to create a new \x07one!", PREFIX);
		return Plugin_Handled;
	}
	
	char Args[32];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(Args[0] == EOS)
	{
		PrintToChat(client, "%s Invalid Usage! \x07!creategang \x01<name>", PREFIX);
		return Plugin_Handled;		
	}	
	else if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, "%s Invalid name! \x05You \x01can only use \x07a-z, A-Z\x01, _, -, \x070-9!", PREFIX);
		return Plugin_Handled;
	}
	
	GangCreateName[client] = Args;
	if(GangCreateTag[client][0] == EOS)
	{
		PrintToChat(client, "%s Name selected! Please select your \x07gang \x01tag using \x07!gangtag.", PREFIX);
		return Plugin_Handled;
	}	
	Handle hMenu = CreateMenu(CreateGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuExitButton(hMenu, false);
	
	SetMenuTitle(hMenu, "%s Create Gang\nGang Name: %s\nGang Tag: %s\nCost: %i", MENU_PREFIX, GangCreateName[client], GangCreateTag[client], GANG_COSTCREATE);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action Command_CreateGangTag(int client, int args)
{
	if(IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to leave your current gang to create a new \x07one!", PREFIX);
		return Plugin_Handled;
	}
	
	char Args[10];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(strlen(Args) != 6)
	{
		PrintToChat(client, "%s The gang tag has to be \x076 \x01characters long!", PREFIX);
		return Plugin_Handled;
	}
	GangCreateTag[client] = Args;
	if(GangCreateName[client][0] == EOS)
	{
		PrintToChat(client, "%s Tag selected! Please select your gang name using \x07!creategang.", PREFIX);
		return Plugin_Handled;
	}	
		
	else if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, "%s Invalid tag! \x05You \x01can only use \x07a-z, A-Z\x01, _, -, \x070-9!", PREFIX);
		return Plugin_Handled;
	}
	Handle hMenu = CreateMenu(CreateGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuExitButton(hMenu, false);
	
	SetMenuTitle(hMenu, "%s Create Gang\nGang Name: %s\nGang Tag: %s\nCost: %i",MENU_PREFIX, GangCreateName[client], GangCreateTag[client], GANG_COSTCREATE);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
public Action Command_LeaveGang(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to be in a gang to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!GangAttemptLeave[client])
	{
		PrintToChat(client, "%s \x05You \x01have not made an attempt to leave your gang with \x07!gang.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09has left the gang!", PREFIX, client);
	KickClientFromGang(client, ClientGang[client]);
	
	GangAttemptLeave[client] = false;
	
	return Plugin_Handled;
}

public Action Command_DisbandGang(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to be in a gang to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, RANK_LEADER))
	{
		PrintToChat(client, "%s \x05You \x01have to be the gang's leader to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}	
	else if(!GangAttemptDisband[client])
	{
		PrintToChat(client, "%s \x05You \x01have not made an attempt to disband your gang with \x07!gang.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatAll("%s \x05%N \x01has disbanded the gang \x07%s!", PREFIX, client, ClientGang[client]);
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDisbanded, sQuery, DP);
	
	GangAttemptDisband[client] = false;
	return Plugin_Handled;
}

public Action Command_StepDown(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to be in a gang to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, RANK_LEADER))
	{
		PrintToChat(client, "%s \x05You \x01have to be the gang's leader to use this \x07command!", PREFIX);
		return Plugin_Handled;
	}	
	else if(!GangAttemptStepDown[client])
	{
		PrintToChat(client, "%s \x05You \x01have not made an attempt to step down from your rank with \x07!gang.", PREFIX);
		return Plugin_Handled;
	}
	
	int NewLeader = GetClientOfUserId(GangStepDownTarget[client]);
	
	if(NewLeader == 0)
	{
		PrintToChat(client, "%s The selected target has \x07disconnected.", PREFIX);
		return Plugin_Handled;
	}
	
	else if(!AreClientsSameGang(client, NewLeader))
	{
		PrintToChat(client, "%s The selected target has left the \x07gang.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatGang(ClientGang[client], "%s \x05%N \x01has stepped down to \x07Co-Leader.", PREFIX, client);
	PrintToChatGang(ClientGang[client], "%s \x05%N \x01is now the gang \x07Leader.", PREFIX, NewLeader);
	
	char AuthId[35], AuthIdNewLeader[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientAuthId(NewLeader, AuthId_Engine, AuthIdNewLeader, sizeof(AuthIdNewLeader));
	
	SetAuthIdRank(AuthId, ClientGang[client], RANK_COLEADER);
	SetAuthIdRank(AuthIdNewLeader, ClientGang[NewLeader], RANK_LEADER);
	
	GangAttemptStepDown[client] = false;
	GangStepDownTarget[client] = -1;
	return Plugin_Handled;
}

public void SQLCB_GangDisbanded(Handle owner, Handle hndl, char[] error, Handle DP)
{
	char GangName[32];
	ResetPack(DP);
	
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(!StrEqual(GangName, ClientGang[i], false))
			continue;
		
		OnClientConnected(i);
		OnClientPutInServer(i);
		
		OnClientPostAdminCheck(i);
	}
}
public int CreateGang_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
	
		if(IsClientGang(client))
			return;
			
		if(item + 1 == 1)
		{
			if(GangCreateName[client][0] == EOS || GangCreateTag[client][0] == EOS || StringHasInvalidCharacters(GangCreateName[client]) || StringHasInvalidCharacters(GangCreateTag[client]))
				return;

			TryCreateGang(client, GangCreateName[client], GangCreateTag[client]);
		}
		else
		{
			GangCreateName[client] = GANG_NULL;
			GangCreateTag[client] = GANG_NULL;
		}	
	}
}
public Action Command_GC(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01have to be in a gang to use this \x01command!", PREFIX);
		return Plugin_Handled;
	}
	else if(ClientGetHonorPerk[client] <= 0)
	{
		PrintToChat(client, "%s Your gang does not have that \x07perk.", PREFIX);
		return Plugin_Handled;
	}
	else if(!CanGetHonor[client])
	{
		PrintToChat(client, "%s \x05You \x01have already received credits this \x07round!", PREFIX);
		return Plugin_Handled;	
	}
	else if(GetPlayerCount() < MIN_PLAYERS_FOR_GC)
	{
		PrintToChat(client, "%s \x05You \x01can only use \x07!gc \x01from \x103 \x01players and above.", PREFIX);
		return Plugin_Handled;		
	}
	
	int received = ClientGetHonorPerk[client] * GANG_GETCREDITSINCREASE;
	GiveClientHonor(client, received);
	PrintToChat(client, "%s \x05You \x01have received \x07%i \x01credits with \x07!gc.", PREFIX, received);
	CanGetHonor[client] = false;
	
	return Plugin_Handled;
}

public Action Command_BreachGang(int client, int args)
{
	if(IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01must not be in a gang to move yourself into another \x07gang.", PREFIX);
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		PrintToChat(client, "Usage: \x07sm_breachgang \x01<gang name>");
		return Plugin_Handled;
	}
	
	char GangName[32];
	GetCmdArgString(GangName, sizeof(GangName));
	StripQuotes(GangName);
	
	char AuthId[35];
	Handle DP = CreateDataPack();
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	WritePackString(DP, AuthId);
	
	FinishAddAuthIdToGang(GangName, AuthId, RANK_MEMBER, AuthId, DP);
	
	return Plugin_Handled;
}

public Action Command_BreachGangRank(int client, int args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x05You \x01must be in a gang to set your gang \x07rank.", PREFIX);
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		PrintToChat(client, "Usage: sm_breachgangrank <rank {0~%i}>", RANK_COLEADER+1);
		return Plugin_Handled;
	}
	
	char RankToSet[11];
	GetCmdArg(1, RankToSet, sizeof(RankToSet));
	
	int Rank = StringToInt(RankToSet);
	
	if(Rank > RANK_COLEADER)
		Rank = RANK_LEADER;
		
	char AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	SetAuthIdRank(AuthId, ClientGang[client], Rank);
	
	return Plugin_Handled;
}
public Action Command_Gang(int client, int args)
{
	if(!ClientLoadedFromDb[client])
	{
		PrintToChat(client, "%s \x05You \x01weren't loaded from the database \x07yet!", PREFIX);
		return Plugin_Handled;
	}
	GangAttemptLeave[client] = false;
	GangAttemptDisband[client] = false;

	Handle hMenu = CreateMenu(Gang_MenuHandler);
		
	bool isGang = IsClientGang(client);
	
	bool isLeader = (IsClientGang(client) && CheckGangAccess(client, RANK_LEADER));
	
	char TempFormat[100];
	
	if(!isGang)
	{
		Format(TempFormat, sizeof(TempFormat), "Create Gang [ %i Honor ]", GANG_COSTCREATE);
		AddMenuItem(hMenu, "Create", TempFormat, !isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	AddMenuItem(hMenu, "Donate", "Donate To Gang", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "Member List", "Member List", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "Perks", "Gang Perks", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "Manage", "Manage Gang", CheckGangAccess(client, ClientAccessManage[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "Leave", "Leave Gang", !isLeader && isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "Top", "Top Gangs");
	
	SetMenuTitle(hMenu, "%s Gang Menu\nCurrent Gang: %s\nYour credits: %i\nYour Gang's credits: %i", MENU_PREFIX, isGang ? ClientGang[client] : "None", ClientHonor[client], isGang ? ClientGangHonor[client] : 0);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	LoadClientGang(client, true);
	return Plugin_Handled;
}


public int Gang_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		GangAttemptLeave[client] = false;
		GangAttemptDisband[client] = false;
		
		char Info[32];
		GetMenuItem(hMenu, item, Info, sizeof(Info));
		
		if(StrEqual(Info, "Create"))
		{
			PrintToChat(client, "%s Use \x07!creategang \x01<name> to create a \x07gang.", PREFIX);
		}
		else if(StrEqual(Info, "Donate"))
		{
			PrintToChat(client, "%s Use \x07!donategang \x01<amount> to donate to your \x07gang.", PREFIX);
		}
		else if(StrEqual(Info, "Member List"))
		{
			if(IsClientGang(client))
				ShowMembersMenu(client);
		}
		else if(StrEqual(Info, "Perks"))
		{
			if(IsClientGang(client))
				ShowGangPerks(client)
		}
		else if(StrEqual(Info, "Manage"))
		{
			if(IsClientGang(client) && CheckGangAccess(client, ClientAccessManage[client]))
				ShowManageGangMenu(client);
		}
		else if(StrEqual(Info, "Leave"))
		{
			if(GetClientRank(client) == RANK_LEADER || !IsClientGang(client))
				return;

			GangAttemptLeave[client] = true;
			PrintToChat(client, "%s Write \x07!confirmleavegang \x01if you are absolutely sure you want to leave the \x07gang.", PREFIX);
			PrintToChat(client, "%s Write anything else in the chat to \x07abort.", PREFIX);
		}
		else if(StrEqual(Info, "Top"))
		{
				ShowTopGangsMenu(client);
		}
	}
}

void ShowTopGangsMenu(int client)
{
	char sQuery[1024];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT GangName, (%!s) as net_worth FROM GangSystem_Gangs ORDER BY net_worth DESC", NET_WORTH_ORDER_BY_FORMULA);
	SQL_TQuery(dbGangs, SQLCB_ShowTopGangsMenu, sQuery, GetClientUserId(client));
}


public void SQLCB_ShowTopGangsMenu(Handle owner, Handle hndl, char[] error, int UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(SQL_GetRowCount(hndl) == 0)
		return;
	
	Handle hMenu = CreateMenu(Dummy_MenuHandler);
	
	int Rank = 1;
	while(SQL_FetchRow(hndl))
	{
		char GangName[32];
		SQL_FetchString(hndl, 0, GangName, sizeof(GangName));
	
		int NetWorth = SQL_FetchInt(hndl, 1);
		char TempFormat[256];
		FormatEx(TempFormat, sizeof(TempFormat), "%s [Net worth: %i]", GangName, NetWorth);
		
		if(StrEqual(ClientGang[client], GangName))
			PrintToChat(client, " %s \x01Your gang \x07%s \x01is ranked \x07[%i]. \x01Net Worth: \x07%i \x01credits", PREFIX, GangName, Rank, NetWorth); // BAR COLOR
			
		AddMenuItem(hMenu, "", TempFormat);
		
		Rank++;
	}
	
	SetMenuTitle(hMenu, "Top Gangs:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Dummy_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
}

void ShowGangPerks(int client)
{
	Handle hMenu = CreateMenu(Perks_MenuHandler);
	
	char TempFormat[150];
	
	Format(TempFormat, sizeof(TempFormat), "Health ( T ) [ %i / %i ] Bonus: +%i [ %i per level ]", ClientHealthPerkT[client], GANG_HEALTHMAX, ClientHealthPerkT[client] * GANG_HEALTHINCREASE, GANG_HEALTHINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Speed ( T ) [ %i / %i ] Bonus: +%.1f [ %.1f per level ]", ClientSpeedPerkT[client], GANG_SPEEDMAX, ClientSpeedPerkT[client] * GANG_SPEEDINCREASE, GANG_SPEEDINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Nade Chance ( T ) [ %i / %i ] Bonus: %.3f%% [ %.3f per level ]", ClientNadePerkT[client], GANG_NADEMAX, ClientNadePerkT[client] * GANG_NADEINCREASE, GANG_NADEINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);

	Format(TempFormat, sizeof(TempFormat), "Health ( CT ) [ %i / %i ] Bonus: +%i [ %i per level ]", ClientHealthPerkCT[client], GANG_HEALTHMAX, ClientHealthPerkCT[client] * GANG_HEALTHINCREASE, GANG_HEALTHINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);

	Format(TempFormat, sizeof(TempFormat), "Speed ( CT ) [ %i / %i ] Bonus: +%.1f [ %.1f per level ]", ClientSpeedPerkCT[client], GANG_SPEEDMAX, ClientSpeedPerkCT[client] * GANG_SPEEDINCREASE, GANG_SPEEDINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Get Credits [ %i / %i ] Bonus: %i [ %i per level ]", ClientGetHonorPerk[client], GANG_GETCREDITSMAX, ClientGetHonorPerk[client] * GANG_GETCREDITSINCREASE, GANG_GETCREDITSINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Gang Size [ %i / %i ] Bonus: %i [ %i per level ]", ClientGangSizePerk[client], GANG_SIZEMAX, ClientGangSizePerk[client] * GANG_SIZEINCREASE, GANG_SIZEINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Friendly Fire Decrease [ %i / %i ] Bonus: -%i%% [ %i%% per level ]\nNote: Friendly Fire decrease applies on Days only.", ClientFriendlyFirePerk[client], GANG_FRIENDLYFIREMAX, ClientFriendlyFirePerk[client] * GANG_FRIENDLYFIREINCREASE, GANG_FRIENDLYFIREINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Perks_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
}


void ShowManageGangMenu(int client)
{
	Handle hMenu = CreateMenu(ManageGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Invite To Gang", CheckGangAccess(client, ClientAccessInvite[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Kick From Gang", CheckGangAccess(client, ClientAccessKick[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Promote Member", CheckGangAccess(client, ClientAccessPromote[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Upgrade Perks",CheckGangAccess(client, ClientAccessUpgrade[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Set Gang MOTD", CheckGangAccess(client, ClientAccessMOTD[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Disband Gang", CheckGangAccess(client, RANK_LEADER) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Manage Actions Access", CheckGangAccess(client, RANK_LEADER) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	SetMenuTitle(hMenu, "%s Manage Gang", MENU_PREFIX);
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int ManageGang_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, ClientAccessManage[client]))
		{
			Command_Gang(client, 0);
			return;
		}	
		switch(item + 1)
		{
			case 1:
			{
				if(!ClientAccessInvite[client])
					return;
					
				else if(ClientMembersCount[client] >= (GANG_INITSIZE + (ClientGangSizePerk[client] * GANG_SIZEINCREASE)))
				{
					PrintToChat(client, "%s The gang is \x07full!", PREFIX);
					return;
				}
				ShowInviteMenu(client);
			}
			
			case 2:
			{
				if(!ClientAccessKick[client])
					return;
					
				ShowKickMenu(client);
			}
			case 3:
			{
				if(!ClientAccessPromote[client])
					return;
					
				ShowPromoteMenu(client);
			}
			case 4:
			{
				if(!ClientAccessUpgrade[client])
					return;
					
				ShowUpgradeMenu(client);
			}
			case 5:
			{
				if(!ClientAccessMOTD[client])
					return;
					
				PrintToChat(client, "%s Use \x07!motdgang \x01<new motd> to change the gang's \x07motd.", PREFIX);
			}
			
			case 6:
			{
				if(!CheckGangAccess(client, RANK_LEADER))
					return;
					
				GangAttemptDisband[client] = true;
				PrintToChat(client, "%s Write \x07!confirmdisbandgang \x01to confirm DELETION of the \x05gang.", PREFIX);
				PrintToChat(client, "%s Write anything else in the chat to abort deleting the \x05gang.", PREFIX);
				PrintToChat(client, "%s ATTENTION! THIS ACTION WILL PERMANENTLY DELETE YOUR \x07GANG\x01, IT IS NOT UNDOABLE AND YOU WILL NOT BE \x07REFUNDED!!!", PREFIX);
			}
			
			case 7:
			{
				if(!CheckGangAccess(client, RANK_LEADER))
					return;
					
				ShowActionAccessMenu(client);
			}
		}
	}
}


void ShowActionAccessMenu(int client)
{
	Handle hMenu = CreateMenu(ActionAccess_MenuHandler);
	char RankName[32];
	char TempFormat[256];
	GetRankName(ClientAccessInvite[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Invite to Gang - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessKick[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Kick from Gang - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessPromote[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Promote Member - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessUpgrade[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Upgrade Perks - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessMOTD[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Set Gang MOTD - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int ActionAccess_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_LEADER))
			return;
			
		ClientActionEdit[client] = item;
		
		ShowActionAccessSetRankMenu(client);
	
	}
}

void ShowActionAccessSetRankMenu(int client)
{
	Handle hMenu = CreateMenu(ActionAccessSetRank_MenuHandler);
	char RankName[32];
	
	for(int i=RANK_MEMBER;i <= GetClientRank(client);i++)
	{
		if(i == GetClientRank(client) && !CheckGangAccess(client, RANK_LEADER))
			break;
			
		else if(i > RANK_COLEADER)
			i = RANK_LEADER;
			
		GetRankName(i, RankName, sizeof(RankName));
		
		AddMenuItem(hMenu, "", RankName);
	}
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	
	char RightName[32];
	
	switch(ClientActionEdit[client])
	{
		case 0: RightName = "Invite";
		case 1: RightName = "Kick";
		case 2: RightName = "Promote";
		case 3: RightName = "Upgrade";
		case 4: RightName = "MOTD";
	}

	SetMenuTitle(hMenu, "Choose which minimum rank will have right to %s", RightName);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int ActionAccessSetRank_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowActionAccessMenu(client);

	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_LEADER))
			return;
			
		int TrueRank = item > RANK_COLEADER ? RANK_LEADER : item;
		
		char ColumnName[32];
		switch(ClientActionEdit[client])
		{
			case 0: ColumnName = "GangMinRankInvite";
			case 1: ColumnName = "GangMinRankKick";
			case 2: ColumnName = "GangMinRankPromote";
			case 3: ColumnName = "GangMinRankUpgrade";
			case 4: ColumnName = "GangMinRankMOTD";
		}
		
		Handle DP = CreateDataPack();
		
		WritePackString(DP, ClientGang[client]);
		
		char sQuery[256];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET '%s' = %i WHERE GangName = '%s'", ColumnName, TrueRank, ClientGang[client]);
		SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP);
	}
}
void ShowUpgradeMenu(int client)
{
	Handle hMenu = CreateMenu(Upgrade_MenuHandler);

	char TempFormat[100], strUpgradeCost[20];
	
	int upgradecost = GetUpgradeCost(ClientHealthPerkT[client], GANG_HEALTHCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Health ( T ) [ %i / %i ] Cost: %i", ClientHealthPerkT[client], GANG_HEALTHMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientSpeedPerkT[client], GANG_SPEEDCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Speed ( T ) [ %i / %i ] Cost: %i", ClientSpeedPerkT[client], GANG_SPEEDMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientNadePerkT[client], GANG_NADECOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Nade Chance ( T ) [ %i / %i ] Cost: %i", ClientNadePerkT[client], GANG_NADEMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientHealthPerkCT[client], GANG_HEALTHCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Health ( CT ) [ %i / %i ] Cost: %i", ClientHealthPerkCT[client], GANG_HEALTHMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	upgradecost = GetUpgradeCost(ClientSpeedPerkCT[client], GANG_SPEEDCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Speed ( CT ) [ %i / %i ] Cost: %i", ClientSpeedPerkCT[client], GANG_SPEEDMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientGetHonorPerk[client], GANG_GETCREDITSCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Get Credits [ %i / %i ] Cost: %i", ClientGetHonorPerk[client], GANG_GETCREDITSMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientGangSizePerk[client], GANG_SIZECOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Gang Size [ %i / %i ] Cost: %i", ClientGangSizePerk[client], GANG_SIZEMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientFriendlyFirePerk[client], GANG_FRIENDLYFIRECOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Friendly Fire Decrease [ %i / %i ] Cost: %i", ClientFriendlyFirePerk[client], GANG_FRIENDLYFIREMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	SetMenuTitle(hMenu, "%s Choose what perks to upgrade:", MENU_PREFIX);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Upgrade_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_MANAGER))
			return;
		
		char strUpgradeCost[20];
		GetMenuItem(hMenu, item, strUpgradeCost, sizeof(strUpgradeCost))
		LoadClientGang_TryUpgrade(client, item, StringToInt(strUpgradeCost));
	}
}


void LoadClientGang_TryUpgrade(int client, int item, int upgradecost)
{
	char AuthId[35]
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE AuthId = '%s'", AuthId);
	
	Handle DP = CreateDataPack()
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackCell(DP, item);
	WritePackCell(DP, upgradecost);
	SQL_TQuery(dbGangs, SQLCB_LoadClientGang_TryUpgrade, sQuery, DP, DBPrio_High);
}	

public void SQLCB_LoadClientGang_TryUpgrade(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	int client = GetClientOfUserId(ReadPackCell(DP));
	if (!IsValidPlayer(client))
	{
		CloseHandle(DP);
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			ClientRank[client] = SQL_FetchInt(hndl, 2);
			
			char sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
			SQL_TQuery(dbGangs, SQLCB_LoadGangByClient_TryUpgrade, sQuery, DP, DBPrio_High);
		}
		else
		{
			CloseHandle(DP);
			ClientLoadedFromDb[client] = true;
		}
	}
}

public void SQLCB_LoadGangByClient_TryUpgrade(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	ResetPack(DP);
	
	int client = GetClientOfUserId(ReadPackCell(DP));
	int item = ReadPackCell(DP);
	int upgradecost = ReadPackCell(DP);
	
	CloseHandle(DP);
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			SQL_FetchString(hndl, 1, ClientTag[client], sizeof(ClientTag[]));
			SQL_FetchString(hndl, 2, ClientMotd[client], sizeof(ClientMotd[]));
			ClientGangHonor[client] = SQL_FetchInt(hndl, 3);
			ClientHealthPerkT[client] = SQL_FetchInt(hndl, 4);
			ClientSpeedPerkT[client] = SQL_FetchInt(hndl, 5);
			ClientNadePerkT[client] = SQL_FetchInt(hndl, 6);
			ClientHealthPerkCT[client] = SQL_FetchInt(hndl, 7);
			ClientSpeedPerkCT[client] = SQL_FetchInt(hndl, 8);
			ClientGetHonorPerk[client] = SQL_FetchInt(hndl, 9);
			ClientGangSizePerk[client] = SQL_FetchInt(hndl, 10);
			
			TryUpgradePerk(client, item, upgradecost);
		}
	}
}

void TryUpgradePerk(int client, int item, int upgradecost) // Safety accomplished.
{
	if(ClientGangHonor[client] < upgradecost)
	{	
		PrintToChat(client, "%s Your gang doesn't have enough credits to \x07upgrade.", PREFIX);
		return;
	}	
	int PerkToUse, PerkMax;
	char PerkName[32], PerkNick[32];
	
	switch(item + 1)
	{
		case 1: PerkToUse = ClientHealthPerkT[client], PerkMax = GANG_HEALTHMAX, PerkName = "GangHealthPerkT", PerkNick = "Health ( T )";
		case 2: PerkToUse = ClientSpeedPerkT[client], PerkMax = GANG_SPEEDMAX, PerkName = "GangSpeedPerkT", PerkNick = "Speed ( T )";
		case 3: PerkToUse = ClientNadePerkT[client], PerkMax = GANG_NADEMAX, PerkName = "GangNadePerkT", PerkNick = "Nade Chance ( T )";
		case 4: PerkToUse = ClientHealthPerkCT[client], PerkMax = GANG_HEALTHMAX, PerkName = "GangHealthPerkCT", PerkNick = "Health ( CT )";
		case 5: PerkToUse = ClientSpeedPerkCT[client], PerkMax = GANG_SPEEDMAX, PerkName = "GangSpeedPerkCT", PerkNick = "Speed ( CT )";
		case 6: PerkToUse = ClientGetHonorPerk[client], PerkMax = GANG_GETCREDITSMAX, PerkName = "GangGetHonorPerk", PerkNick = "Get Credits";
		case 7: PerkToUse = ClientGangSizePerk[client], PerkMax = GANG_SIZEMAX, PerkName = "GangSizePerk", PerkNick = "Gang Size";
		case 8: PerkToUse = ClientFriendlyFirePerk[client], PerkMax = GANG_FRIENDLYFIREMAX, PerkName = "GangFFPerk", PerkNick = "Friendly Fire Decrease";
		default: return;
	}
	
	if(PerkToUse >= PerkMax)
	{	
		PrintToChat(client, "%s Your gang has \x07already \x01maxed this perk!", PREFIX);
		return;
	}
		
	char sQuery[256];
	
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_upgradelogs (GangName, AuthId, Perk, BValue, AValue, timestamp) VALUES ('%s', '%s', '%s', %i, %i, %i)", ClientGang[client], steamid, PerkName, PerkToUse, PerkToUse+1, GetTime());
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 7, DBPrio_High);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor - %i WHERE GangName = '%s'", upgradecost, ClientGang[client]);
	
	Handle DP = CreateDataPack(), DP2 = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET %s = %s + 1 WHERE GangName = '%s'", PerkName, PerkName, ClientGang[client]);
	WritePackString(DP2, ClientGang[client]);
	SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP2);
	
	PrintToChatGang(ClientGang[client], "%s \x05%N \x01has upgraded the gang perk \x07%s!", PREFIX, client, PerkNick);

}

public void SQLCB_UpdateGang(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
		SetFailState(error);
	
	ResetPack(DP);
	
	char GangName[32];
	ReadPackString(DP, GangName, sizeof(GangName));

	CloseHandle(DP);
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		ResetVariables(i, false);
		
		LoadClientGang(i);
	}
}


void ShowPromoteMenu(int client)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowPromoteMenu, sQuery, GetClientUserId(client));
}

public void SQLCB_ShowPromoteMenu(Handle owner, Handle hndl, char[] error, int UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	int client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		Handle hMenu = CreateMenu(Promote_MenuHandler);
	
		char TempFormat[200], Info[250], iAuthId[35], Name[64];
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			int Rank = SQL_FetchInt(hndl, 2);
			
			char strRank[32];
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			
			int LastConnect = SQL_FetchInt(hndl, 7);
			
			Format(Info, sizeof(Info), "\"%s\" \"%s\" \"%i\" \"%i\"", iAuthId, Name, Rank, LastConnect);
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, Info, TempFormat, Rank < GetClientRank(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Choose who to promote:", MENU_PREFIX);
		
		SetMenuExitButton(hMenu, true);
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public int Promote_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		char Info[200];
		GetMenuItem(hMenu, item, Info, sizeof(Info));
		
		PromoteMenu_ChooseRank(client, Info);
	}
}

void PromoteMenu_ChooseRank(int client, const char[] Info)
{
	Handle hMenu = CreateMenu(ChooseRank_MenuHandler);
	
	for(int i=RANK_MEMBER;i <= GetClientRank(client);i++)
	{
		if(i == GetClientRank(client) && !CheckGangAccess(client, RANK_LEADER))
			break;
			
		else if(i > RANK_COLEADER)
			i = RANK_LEADER;
			
		char RankName[20];
		GetRankName(i, RankName, sizeof(RankName));
		
		AddMenuItem(hMenu, Info, RankName);
	}
	
	char iAuthId[35], Name[64], strRank[11], strLastConnect[11];
	
	int len = BreakString(Info, iAuthId, sizeof(iAuthId));
	
	int len2 = BreakString(Info[len], Name, sizeof(Name));
	
	int len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
	
	BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));

	char Date[64];
	FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", StringToInt(strLastConnect));		
	
	SetMenuTitle(hMenu, "%s Choose the rank you want to give to %s\nTarget's Last Connect: %s", MENU_PREFIX, Name, Date);
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}

public int ChooseRank_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowPromoteMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		char Info[200], iAuthId[35], strRank[20], strLastConnect[11], Name[64];
		GetMenuItem(hMenu, item, Info, sizeof(Info));
		
		int len = BreakString(Info, iAuthId, sizeof(iAuthId));
		
		int len2 = BreakString(Info[len], Name, sizeof(Name));
		
		int len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
		
		BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));
		
		if(item > RANK_COLEADER)
			item = RANK_LEADER;
			
		if(item < GetClientRank(client))
		{
			char NewRank[32];
			GetRankName(item, NewRank, sizeof(NewRank));
			PrintToChatGang(ClientGang[client], " %s has been \x07promoted \x01to \x05%s", Name, NewRank);
			SetAuthIdRank(iAuthId, ClientGang[client], item);
		}
		else
		{
			GangAttemptStepDown[client] = true;
			
			int target = FindClientByAuthId(iAuthId);
			
			if(target == 0)
			{
				PrintToChat(client, "%s The target must be \x05connected \x01for a step-down action for security \x07reasons.", PREFIX);
				
				return;
			}
			
			GangStepDownTarget[client] = GetClientUserId(target);
			
			PrintToChat(client, "%s Attention! \x05You are attempting to promote a player to be the \x07Leader.", PREFIX);
			PrintToChat(client, "%s By doing so you will become a \x07Co-Leader \x01in the gang.", PREFIX);
			PrintToChat(client, "%s This action is irreversible, the new \x07leader \x01can kick you if he wants.", PREFIX);
			PrintToChat(client, "%s If you read all above and sure you want to continue, write \x07!confirmstepdowngang.", PREFIX);
			PrintToChat(client, "%s Write anything else in the chat to abort the \x07action", PREFIX);
		}
	}
}

void ShowKickMenu(int client)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowKickMenu, sQuery, GetClientUserId(client));
}

public void SQLCB_ShowKickMenu(Handle owner, Handle hndl, char[] error, int UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	int client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		Handle hMenu = CreateMenu(Kick_MenuHandler);
	
		char TempFormat[200], Info[250], iAuthId[35], Name[64];
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			int Rank = SQL_FetchInt(hndl, 2);
			
			char strRank[32];
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			
			int LastConnect = SQL_FetchInt(hndl, 7);
			
			Format(Info, sizeof(Info), "\"%s\" \"%s\" \"%i\" \"%i\"", iAuthId, Name, Rank, LastConnect);
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, Info, TempFormat, Rank < GetClientRank(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Choose who to kick:", MENU_PREFIX);
		
		SetMenuExitButton(hMenu, true);
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}


public int Kick_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		char Info[200], iAuthId[35], strRank[20], strLastConnect[11], Name[64];
		GetMenuItem(hMenu, item, Info, sizeof(Info));
		
		int len = BreakString(Info, iAuthId, sizeof(iAuthId));
		
		int len2 = BreakString(Info[len], Name, sizeof(Name));
		
		int len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
		
		BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));
		
		if(StringToInt(strRank) >= GetClientRank(client)) // Should never return but better safe than sorry.
			return;
			
		ShowConfirmKickMenu(client, iAuthId, Name, StringToInt(strLastConnect));
	}
}

void ShowConfirmKickMenu(int client, const char[] iAuthId, const char[] Name, int LastConnect)
{
	Handle hMenu = CreateMenu(ConfirmKick_MenuHandler);
	
	AddMenuItem(hMenu, iAuthId, "Yes");
	AddMenuItem(hMenu, Name, "No"); // This will also be used.
	
	char Date[64];
	FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", LastConnect);
	
	SetMenuTitle(hMenu, "%s Gang Kick\nAre you sure you want to kick %s?\nSteam ID of target: %s\nTarget's last connect: %s", MENU_PREFIX, Name, iAuthId, Date);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 60);
}

public int ConfirmKick_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowKickMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(item + 1 == 1)
		{
			char iAuthId[35], Name[64];
			GetMenuItem(hMenu, 0, iAuthId, sizeof(iAuthId))
			GetMenuItem(hMenu, 1, Name, sizeof(Name))
			
			PrintToChatGang(ClientGang[client], "%s \x05%N \x01has kicked \x07%s \x01from the gang!", PREFIX, client, Name);
			
			KickAuthIdFromGang(iAuthId, ClientGang[client]);
		}
	}
}

void ShowInviteMenu(int client)
{
	Handle hMenu = CreateMenu(Invite_MenuHandler);
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(IsClientGang(i))
			continue;
			
		//else if(IsFakeClient(i))
			//continue;
	
		char strUserId[20], iName[64];
		IntToString(GetClientUserId(i), strUserId, sizeof(strUserId));
		GetClientName(i, iName, sizeof(iName));
		
		AddMenuItem(hMenu, strUserId, iName);
	}
	
	SetMenuTitle(hMenu, "%s Choose who to invite:", MENU_PREFIX);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Invite_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		char strUserId[20];
		GetMenuItem(hMenu, item, strUserId, sizeof(strUserId))
		
		int target = GetClientOfUserId(StringToInt(strUserId));
		
		if(IsValidPlayer(target))
		{
			if(!IsClientGang(target))
			{
				if(!IsFakeClient(target))
				{
					char AuthId[35];
					GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
					ShowAcceptInviteMenu(target, AuthId, ClientGang[client]);
					PrintToChat(client, "%s \x05You \x01have invited \x07%N \x01to join the gang!", PREFIX, target);
				}
				else
				{
					char AuthId[35];
					GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
					AddClientToGang(target, AuthId, ClientGang[client]);
				}
			}
		}
	}
}

void ShowAcceptInviteMenu(int target, const char[] AuthIdInviter, const char[] GangName)
{
	if(!IsValidPlayer(target))
		return;
	
	Handle hMenu = CreateMenu(AcceptInvite_MenuHandler);
	
	AddMenuItem(hMenu, AuthIdInviter, "Yes");
	AddMenuItem(hMenu, GangName, "No"); // This info string will also be used.
	
	SetMenuTitle(hMenu, "%s Gang Invite\nWould you like to join the gang %s?", MENU_PREFIX, GangName);
	DisplayMenu(hMenu, target, 10);
}

public int AcceptInvite_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		if(item + 1 == 1)
		{
			char AuthIdInviter[35], GangName[32];
			GetMenuItem(hMenu, 0, AuthIdInviter, sizeof(AuthIdInviter))
			GetMenuItem(hMenu, 1, GangName, sizeof(GangName))
			
			char LastGang[32];
			LastGang = ClientGang[client];
			
			ClientGang[client] = GangName;
			PrintToChatGang(ClientGang[client], "%s \x05%N \x01has joined the \x07gang!", PREFIX, client);
			ClientGang[client] = LastGang;
			
			AddClientToGang(client, AuthIdInviter, GangName);
		}
	}
}

void ShowMembersMenu(int client)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowMembersMenu, sQuery, GetClientUserId(client));
}


public void SQLCB_ShowMembersMenu(Handle owner, Handle hndl, char[] error, int UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	int client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		Handle hMenu = CreateMenu(Members_MenuHandler);
	
		char TempFormat[200], iAuthId[35], Name[64];
		while(SQL_FetchRow(hndl))
		{
			char strRank[32];
			int Rank = SQL_FetchInt(hndl, 2);
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, iAuthId, TempFormat, ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Member List:", MENU_PREFIX);
		
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}


public int Members_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
}

void TryCreateGang(int client, const char[] GangName, const char[] GangTag)
{	
	if(GangName[0] == EOS)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s The selected gang name is \x07invalid.", PREFIX);
		return;
	}
	else if(GangTag[0] == EOS)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s The selected gang tag is \x07invalid.", PREFIX);
		return;
	}	
	else if(ClientHonor[client] < GANG_COSTCREATE)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s \x05You \x01need \x07%i \x01more credits to open a gang!", PREFIX, GANG_COSTCREATE - ClientHonor[client]);
		return;
	}
	Handle DP = CreateDataPack();
	WritePackCell(DP, GetClientUserId(client));
	WritePackString(DP, GangName);
	WritePackString(DP, GangTag);
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE lower(GangName) = lower('%s') OR lower(GangTag) = lower('%s')", GangName, GangTag);
	SQL_TQuery(dbGangs, SQLCB_CreateGang_CheckTakenNameOrTag, sQuery, DP);
}


public void SQLCB_CreateGang_CheckTakenNameOrTag(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	ResetPack(DP);
	
	int client = GetClientOfUserId(ReadPackCell(DP));
	char GangName[32], GangTag[10];
	
	ReadPackString(DP, GangName, sizeof(GangName));
	ReadPackString(DP, GangTag, sizeof(GangTag));
	
	CloseHandle(DP);
	
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) == 0)
		{
			CreateGang(client, GangName, GangTag);
			PrintToChat(client, "%s The gang was \x07created!", PREFIX)
		}
		else // Gang name is taken.
		{
			bool NameTaken = false;
			bool TagTaken = false;
			
			char iGangName[32], iGangTag[10];
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, iGangName, sizeof(iGangName));
				SQL_FetchString(hndl, 1, iGangTag, sizeof(iGangTag));
				
				if(StrEqual(iGangName, GangName, false))
					NameTaken = true;
					
				if(StrEqual(iGangTag, GangTag, false))
					TagTaken = true;
			}
			
			if(NameTaken)
			{	
				GangCreateName[client] = GANG_NULL;
				PrintToChat(client, "%s The selected gang name is \x07already \x01taken!", PREFIX);
			
			}
			if(TagTaken)
			{
				GangCreateTag[client] = GANG_NULL;
				PrintToChat(client, "%s The selected gang tag is \x07already \x01taken!", PREFIX);
			}
		}
	}
}

void CreateGang(int client, const char[] GangName, const char[] GangTag)
{
	if(ClientHonor[client] < GANG_COSTCREATE)
		return;
		
	char sQuery[256];
	
	char AuthId[35];
	
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));

	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Members WHERE GangName = '%s'", GangName); // Just in case.
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 8, DBPrio_High);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, AuthId);
	WritePackString(DP, GangName);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_Gangs (GangName, GangTag, GangMotd, GangHonor, GangHealthPerkT, GangSpeedPerkT, GangNadePerkT, GangHealthPerkCT, GangSpeedPerkCT, GangGetHonorPerk, GangSizePerk) VALUES ('%s', '%s', '', 0, 0, 0, 0, 0, 0, 0, 0)", GangName, GangTag);
	SQL_TQuery(dbGangs, SQLCB_GangCreated, sQuery, DP);
	
	GiveClientHonor(client, -1 * GANG_COSTCREATE);
}

public void SQLCB_GangCreated(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
		SetFailState(error);
	
	ResetPack(DP);
	
	char AuthId[35], GangName[32];
	ReadPackString(DP, AuthId, sizeof(AuthId));
	ReadPackString(DP, GangName, sizeof(GangName));

	CloseHandle(DP);
	
	AddAuthIdToGang(AuthId, AuthId, GangName, RANK_LEADER);
}
stock void AddClientToGang(int client, const char[] AuthIdInviter, const char[] GangName, int GangRank = RANK_MEMBER)
{
	char AuthId[35];
	
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	AddAuthIdToGang(AuthId, AuthIdInviter, GangName, GangRank);

}

stock void AddAuthIdToGang(const char[] AuthId, const char[] AuthIdInviter, const char[] GangName, int GangRank = RANK_MEMBER)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", GangName);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, AuthId);
	WritePackString(DP, AuthIdInviter);
	WritePackString(DP, GangName);
	WritePackCell(DP, GangRank);
	SQL_TQuery(dbGangs, SQLCB_AuthIdAddToGang_CheckSize, sQuery, DP);

}

public void SQLCB_AuthIdAddToGang_CheckSize(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
		SetFailState(error);
		
	if(SQL_GetRowCount(hndl) != 0)
	{
		SQL_FetchRow(hndl);
		
		int Size = GANG_INITSIZE + (SQL_FetchInt(hndl, 10) * GANG_SIZEINCREASE);
		
		WritePackCell(DP, Size);
		
		ResetPack(DP);
		char AuthId[1], GangName[32];
		ReadPackString(DP, AuthId, 0);
		ReadPackString(DP, AuthId, 0);
		ReadPackString(DP, GangName, sizeof(GangName));
		
		char sQuery[256];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s'", GangName);
		SQL_TQuery(dbGangs, SQLCB_AuthIdAddToGang_CheckMemberCount, sQuery, DP);
	}
	else
	{	
		CloseHandle(DP);
		return;
	}
}

// This callback is used to get someone's member count
public void SQLCB_CheckMemberCount(Handle owner, Handle hndl, char[] error, int UserId)
{
	int MemberCount = SQL_GetRowCount(hndl);
	
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	ClientMembersCount[client] = MemberCount;
	
}

public void SQLCB_AuthIdAddToGang_CheckMemberCount(Handle owner, Handle hndl, char[] error, Handle DP)
{
	
	int MemberCount = SQL_GetRowCount(hndl);
	
	ResetPack(DP);
	char AuthId[35], AuthIdInviter[35], GangName[32];
	ReadPackString(DP, AuthId, sizeof(AuthId));
	ReadPackString(DP, AuthIdInviter, sizeof(AuthIdInviter));
	ReadPackString(DP, GangName, sizeof(GangName));
	int GangRank = ReadPackCell(DP);
	int Size = ReadPackCell(DP);
	
	if(MemberCount >= Size)
	{
		CloseHandle(DP);
			
		PrintToChatGang(GangName, "%s \x03The gang is full!", PREFIX);
		return;
	}
	
	FinishAddAuthIdToGang(GangName, AuthId, GangRank, AuthIdInviter, DP);
}

// The DataPack will contain the invited auth ID as the first thing to be added.
public void FinishAddAuthIdToGang(const char[] GangName, const char[] AuthId, int GangRank, char[] AuthIdInviter, Handle DP)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_Members (GangName, AuthId, GangRank, GangInviter, GangDonated, LastName, GangJoinDate, LastConnect) VALUES ('%s', '%s', %i, '%s', 0, '', %i, %i)", GangName, AuthId, GangRank, AuthIdInviter, GetTime(), GetTime());

	SQL_TQuery(dbGangs, SQLCB_AuthIdAddedToGang, sQuery, DP);
}
public void SQLCB_AuthIdAddedToGang(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	char AuthId[35];
	
	ReadPackString(DP, AuthId, sizeof(AuthId));
	
	CloseHandle(DP);
	
	UpdateInGameAuthId(AuthId);
}

stock void UpdateInGameAuthId(const char[] AuthId)
{
	char iAuthId[35];
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		GetClientAuthId(i, AuthId_Engine, iAuthId, sizeof(iAuthId));
		
		if(StrEqual(AuthId, iAuthId, true))
		{
			ClientLoadedFromDb[i] = false;
			
			ResetVariables(i, true);
			LoadClientGang(i);
			break;
		}
	}
}

stock int FindClientByAuthId(const char[] AuthId)
{
	char iAuthId[35];
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		GetClientAuthId(i, AuthId_Engine, iAuthId, sizeof(iAuthId));
		
		if(StrEqual(AuthId, iAuthId, true))
			return i;
	}
	
	return 0;
}
stock void StoreClientLastInfo(int client)
{
	
	char AuthId[35], Name[64];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));

	Format(Name, sizeof(Name), "%N", client);
	StoreAuthIdLastInfo(AuthId, Name);
}


stock void StoreAuthIdLastInfo(const char[] AuthId, const char[] Name)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET LastName = '%s', LastConnect = %i WHERE AuthId = '%s'", Name, GetTime(), AuthId);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 9, DBPrio_Low);
}

stock void SetAuthIdRank(const char[] AuthId, const char[] GangName, int Rank = RANK_MEMBER)
{
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangRank = %i WHERE AuthId = '%s' AND GangName = '%s'", Rank, AuthId, GangName);
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 10);
	
	UpdateInGameAuthId(AuthId);
}

stock void DonateToGang(int client, int amount)
{
	if(!IsValidPlayer(client))
		return;
		
	else if(!IsClientGang(client))
		return;
		
	char AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor + %i WHERE GangName = '%s'", amount, ClientGang[client]);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDonated, sQuery, DP);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangDonated = GangDonated + %i WHERE AuthId = '%s'", amount, AuthId);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 11);
	
	GiveClientHonor(client, -1 * amount);
	
	PrintToChatGang(ClientGang[client], "%s \x05%N \x01has donated \x07%i \x01to the gang!", PREFIX, client, amount);
}

public void SQLCB_GangDonated(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	char GangName[32];
	ResetPack(DP);
	
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		LoadClientGang(i);
	}
	
	
}
stock bool IsClientGang(int client)
{
	return ClientGang[client][0] != EOS ? true : false;
}

stock int GetClientRank(int client)
{
	return ClientRank[client];
}

// returns true if the clients are in the same gang, or if checking the same client while he has a gang.
stock bool AreClientsSameGang(int client, int otherclient)
{
	if(!IsClientGang(client) || !IsClientGang(otherclient))
		return false;
		
	return StrEqual(ClientGang[client], ClientGang[otherclient], true);
}

stock void PrintToChatGang(const char[] GangName, const char[] format, any ...)
{
	char buffer[291];
	VFormat(buffer, sizeof(buffer), format, 3);
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
			
		PrintToChat(i, buffer);
	}
}


stock bool IsValidPlayer(int client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}


stock bool IsPlayer(int client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return true;
}


stock void GetRankName(int Rank, char[] buffer, int length)
{
	switch(Rank)
	{
		case RANK_MEMBER: Format(buffer, length, "Member");
		case RANK_OFFICER: Format(buffer, length, "Officer");
		case RANK_ADMIN: Format(buffer, length, "Admin");
		case RANK_MANAGER: Format(buffer, length, "Manager");
		case RANK_COLEADER: Format(buffer, length, "Co-Leader");
		case RANK_LEADER: Format(buffer, length, "Leader");
	}
}

stock bool CheckGangAccess(int client, int Rank)
{
	return (GetClientRank(client) >= Rank);
}

stock bool IsStringNumber(const char[] source)
{
	if(!IsCharNumeric(source[0]) && source[0] != '-')
		return false;
			
	for(int i=1;i < strlen(source);i++)
	{
		if(!IsCharNumeric(source[i]))
			return false;
	}
	
	return true;
}

stock bool StringHasInvalidCharacters(const char[] source)
{
	for(int i=0;i < strlen(source);i++)
	{
		if(!IsCharNumeric(source[i]) && !IsCharAlpha(source[i]) && source[i] != '-' && source[i] != '_' && source[i] != ' ')
			return true;
	}
	
	return false;
}


stock int GetEntityHealth(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock int GetEntityMaxHealth(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

stock void SetEntityMaxHealth(int entity, int amount)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", amount);
}


stock int GetUpgradeCost(int CurrentPerkLevel, int PerkCost)
{
	return (CurrentPerkLevel + 1) * PerkCost;
}

public void JailBreakDays_OnDayStatus(bool DayActive)
{
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		if(DayActive)
		{
			CreateGlow(i);
		}	
		else
			TryDestroyGlow(i);
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Gangs_HasGang", Native_HasGang);
	CreateNative("Gangs_AreClientsSameGang", Native_AreClientsSameGang);
	CreateNative("Gangs_GetClientGangName", Native_GetClientGangName);
	CreateNative("Gangs_GetClientGangTag", Native_GetClientGangTag);
	CreateNative("Gangs_GiveGangCredits", Native_GiveGangHonor);
	CreateNative("Gangs_GiveClientCredits", Native_GiveClientHonor);
	CreateNative("Gangs_GiveGangHonor", Native_GiveGangHonor);
	CreateNative("Gangs_GiveClientHonor", Native_GiveClientHonor);
	CreateNative("Gangs_AddClientDonations", Native_AddClientDonations);
	CreateNative("Gangs_PrintToChatGang", Native_PrintToChatGang);
	CreateNative("Gangs_TryDestroyGlow", Native_TryDestroyGlow);
	CreateNative("Gangs_GetFFDamageDecrease", Native_GetFFDamageDecrease);
	 
	RegPluginLibrary("JB Gangs");
	return APLRes_Success;
}

public int Native_HasGang(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return IsClientGang(client);
}

public int Native_AreClientsSameGang(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int otherClient = GetNativeCell(2);
	return AreClientsSameGang(client, otherClient);
}

public int Native_GetClientGangName(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int len = GetNativeCell(3);
    if(!IsClientGang(client))
    {
   		return;
  	}
    SetNativeString(2, ClientGang[client], len, false);
}

public int Native_GetClientGangTag(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int len = GetNativeCell(3);
    if(!IsClientGang(client))
    {
   		return;
  	}
    SetNativeString(2, ClientTag[client], len, false);
}


public int Native_PrintToChatGang(Handle plugin, int numParams)
{
	char GangName[32];
	
	GetNativeString(1, GangName, sizeof(GangName));
	char buffer[192];
	
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);
	
	PrintToChatGang(GangName, buffer);
}

public int Native_TryDestroyGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	TryDestroyGlow(client);
}

public int Native_GiveClientHonor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int amount = GetNativeCell(2);
	
	GiveClientHonor(client, amount);
}


public int Native_AddClientDonations(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int amount = GetNativeCell(2);
	
	char AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangDonated = GangDonated + %i WHERE AuthId = '%s'", amount, AuthId);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDonated, sQuery, DP);
}

public int Native_GiveGangHonor(Handle plugin, int numParams)
{
	char GangName[32];
	
	GetNativeString(1, GangName, sizeof(GangName));
	int amount = GetNativeCell(2);
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor + %i WHERE GangName = '%s'", amount, GangName);
	
	Handle DP = CreateDataPack();
	
	WritePackString(DP, GangName);
	
	SQL_TQuery(dbGangs, SQLCB_GiveGangHonor, sQuery, DP);    
}

public any Native_GetFFDamageDecrease(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return float(ClientFriendlyFirePerk[client] * GANG_FRIENDLYFIREINCREASE) / 100.0;
}

public void SQLCB_GiveGangHonor(Handle owner, Handle hndl, char[] error, Handle DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	char GangName[32];
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		LoadClientGang(i);
	}	
}
stock void PrintToChatEyal(const char[] format, any ...)
{
	char buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			

		char steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144"))
			PrintToChat(i, buffer);
	}
}

stock int GetPlayerCount()
{
	int Count, Team;
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		Team = GetClientTeam(i);
		if(Team != CS_TEAM_CT && Team != CS_TEAM_T)	
			continue;
			
		Count++;
	}
	
	return Count;
}

stock void LogGangAction(const char[] format, any ...)
{
	char buffer[291], Path[256];
	VFormat(buffer, sizeof(buffer), format, 2);	
	
	BuildPath(Path_SM, Path, sizeof(Path), "logs/JailBreakGangs.txt");
	LogToFile(Path, buffer);

}


stock bool IsKnifeClass(const char[] classname)
{
	if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") > -1)
		return true;
		
	return false;
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

stock void GiveClientHonor(int client, int amount)
{
	char AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	char sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Honor SET Honor = Honor + %i WHERE AuthId = '%s'", amount, AuthId);
	
	ClientHonor[client] += amount;
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 12);
}
