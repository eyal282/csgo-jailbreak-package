#include <basecomm>
#include <cstrike>
#include <eyal-jailbreak>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <smlib>
#include <fuckZones>

#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls  required

#define MAX_INT 2147483647

#define DEFAULT_MODELINDEX "materials/sprites/laserbeam.vmt"
#define DEFAULT_HALOINDEX  "materials/sprites/halo.vmt"

int g_LaserIndex, g_HaloIdx;

public Plugin myinfo =
{
	name        = "JailBreak Minigame Generator",
	author      = "Eyal282",
	description = "Prodecurally generates minigames like Monopoly, Race, and KZ. The only plugin in the JailBreak package that was AI assisted.",
	version     = PLUGIN_VERSION,
	url         = ""
};

char   PREFIX[256];
char   MENU_PREFIX[64];
Handle hcv_Prefix     = INVALID_HANDLE;
Handle hcv_MenuPrefix = INVALID_HANDLE;


float g_fLastValidOrigin[MAXPLAYERS+1][3];
int g_iLastTileTouched[MAXPLAYERS+1], g_iMaxTileTouched[MAXPLAYERS+1];
bool g_bKZParticipant[MAXPLAYERS+1];
int g_refActiveZone = INVALID_ENT_REFERENCE;
int g_iTotalKZTiles;

native bool JailBreakDays_IsDayActive();


public void OnPluginEnd()
{
	int entity = -1;

	while ((entity = FindEntityByTargetname(entity, "Minigame_Brush_", false, true)) != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");		// Fixing errors in target, something skyler didn't do haha.

	RegAdminCmd("sm_kz", Command_KZ, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcekz", Command_ForceKZ, ADMFLAG_GENERIC);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		OnClientPutInServer(i);

		
	}
}


public Action Event_RoundStart(Handle hEvent, char[] name, bool dontBroadcast) 
{
	int entity = -1;

	while ((entity = FindEntityByTargetname(entity, "Minigame_Brush_", false, true)) != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(client == 0)
		return Plugin_Continue;

	g_bKZParticipant[client] = false;
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_LaserIndex = PrecacheModel(DEFAULT_MODELINDEX, true);
	g_HaloIdx = PrecacheModel(DEFAULT_HALOINDEX, true);

	CreateTimer(0.4, Timer_DisplayMinigameBrushes, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKEvent_KZDamage);

	g_bKZParticipant[client] = false;
}

public Action SDKEvent_KZDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(!g_bKZParticipant[victim])
		return Plugin_Continue;
		
	else if(!(damagetype & DMG_FALL))
		return Plugin_Continue;

	return Plugin_Handled;
}
public Action Timer_DisplayMinigameBrushes(Handle hTimer)
{

	int zone = EntRefToEntIndex(g_refActiveZone);

	if(zone == INVALID_ENT_REFERENCE)
		return Plugin_Continue;

	char iName[64];
	GetEntPropString(zone, Prop_Data, "m_iName", iName, sizeof(iName));

	bool lowVisibility = false;

	if(StrContains(iName, "Low Vis", false) != -1 || StrContains(iName, "Lowvis", false) != -1)
		lowVisibility = true;

	int entity = -1;

	while((entity = FindEntityByTargetname(entity, "Minigame_Brush_", false, true)) != -1)
	{

		GetEntPropString(entity, Prop_Data, "m_iName", iName, sizeof(iName));
		ReplaceStringEx(iName, sizeof(iName), "Minigame_Brush_KZ_", "");

		int tileNum = StringToInt(iName);

		int colors[4];

		float fOrigin[3];

		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fOrigin);

		float fMins[3], fMaxs[3];

		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;

			else if(IsFakeClient(i))
				continue;

			float iOrigin[3];

			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", iOrigin);

			GetEntPropVector(entity, Prop_Data, "m_vecMins", fMins);
			GetEntPropVector(entity, Prop_Data, "m_vecMaxs", fMaxs);

			AddVectors(fMins, fOrigin, fMins);
			AddVectors(fMaxs, fOrigin, fMaxs);

			// Show first and last 3 tiles to non-participants

			if(!g_bKZParticipant[i])
			{
				if(tileNum >= 3 && g_iTotalKZTiles - tileNum > 3)
					continue;
			}
			else if(GetVectorDistance(fOrigin, iOrigin) > 512.0 && tileNum >= g_iLastTileTouched[i] + 3)
				continue;

			int groundEntity = GetEntPropEnt(i, Prop_Data, "m_hGroundEntity");

			if(groundEntity != -1)
			{
				if(!HasEntProp(groundEntity, Prop_Data, "m_iName"))
				{
					g_iLastTileTouched[i] = -1;
				}
				else
				{

					char groundEntityTargetName[64];
					GetEntPropString(groundEntity, Prop_Data, "m_iName", groundEntityTargetName, sizeof(groundEntityTargetName));

					if(StrContains(groundEntityTargetName, "Minigame_Brush_KZ_", false) == -1)
					{
						g_iLastTileTouched[i] = -1;

						if(!fuckZones_IsClientInZoneIndex(i, zone))
						{
							TeleportEntity(i, g_fLastValidOrigin[i], NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", g_fLastValidOrigin[i]);
						}
					}
					else
					{
						ReplaceStringEx(groundEntityTargetName, sizeof(groundEntityTargetName), "Minigame_Brush_KZ_", "");
						int groundEntityTileNum = StringToInt(groundEntityTargetName);

						if(groundEntityTileNum < 0)
						{
							g_iLastTileTouched[i] = -1;
						}
					}
				}
			}

			if(tileNum < g_iLastTileTouched[i])
			{
				colors = {255, 0, 0, 255};
			}
			else if(tileNum - g_iLastTileTouched[i] < 3)
			{
				colors = {0, 255, 0, 255};
			}
			else
			{
				colors = {0, 0, 255, 255};
			}

			TE_DrawBeamBoxToClient(i, fMins, fMaxs, g_LaserIndex, g_HaloIdx, 0, 0, 0.6, 2.0, 2.0, 0, 0.0, colors, 0, DISPLAY_TYPE_FULL); 

			// Diagonal shape across the shape to ensure visibility.
			TE_SetupBeamPoints(fMins, fMaxs, g_LaserIndex, g_HaloIdx, 0, 0, 0.6, 2.0, 2.0, 1, 0.0, colors, 0); 
			TE_SendToClient(i, 0.0);

			if(lowVisibility)
			{
				if(tileNum - g_iLastTileTouched[i] < 2 && tileNum > g_iLastTileTouched[i] || tileNum == 0)
				{
					for(int a=0;a < 3;a++)
					{
						fMins[a] += 3.0;
						fMaxs[a] += 3.0;
					}
					colors = {255, 255, 20, 255};
					TE_DrawBeamBoxToClient(i, fMins, fMaxs, g_LaserIndex, g_HaloIdx, 0, 0, 0.6, 1.0, 1.0, 0, 0.0, colors, 0, DISPLAY_TYPE_FULL);
				}
			}
		}
	}

	return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
	hcv_Prefix = FindConVar("sm_prefix_cvar");

	GetConVarString(hcv_Prefix, PREFIX, sizeof(PREFIX));
	HookConVarChange(hcv_Prefix, cvChange_Prefix);

	hcv_MenuPrefix = FindConVar("sm_menu_prefix_cvar");

	GetConVarString(hcv_MenuPrefix, MENU_PREFIX, sizeof(MENU_PREFIX));
	HookConVarChange(hcv_MenuPrefix, cvChange_MenuPrefix);

	if(GetFeatureStatus(FeatureType_Native, "fuckZones_GetZoneList") != FeatureStatus_Available)
	{
		char filename[64];
		GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
		ServerCommand("sm plugins unload %s", filename);
		return;
	}

	RegPluginLibrary("JB_KZGenerator");
}


public Action Command_KZ(int client, int args)
{
	ArrayList zones = fuckZones_GetZoneList();

	for(int i=0;i < zones.Length;i++)
	{ 
		char zoneName[64];
		int zone = EntRefToEntIndex(zones.Get(i));

		if(!fuckZones_GetZoneName(zone, zoneName, sizeof(zoneName)))
			continue;

		else if(StrContains(zoneName, "KZ", false) == -1)
			continue;

		ShowMinigamesMenu(client, zone);

		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_ForceKZ(int client, int args)
{
	if(client == 0)
	{
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;

			else if(IsFakeClient(i))
				continue;

			client = i;
		}
	}

	if(client != 0)
		ForceKZ(client);

	return Plugin_Handled;
}

void ForceKZ(int client)
{
	ArrayList zones = fuckZones_GetZoneList();

	for(int i=0;i < zones.Length;i++)
	{ 
		char zoneName[64];
		int zone = EntRefToEntIndex(zones.Get(i));

		if(!fuckZones_GetZoneName(zone, zoneName, sizeof(zoneName)))
			continue;

		else if(StrContains(zoneName, "KZ", false) == -1)
			continue;

		DataPack DP;
		CreateDataTimer(0.2, Timer_InitiateForceKZ, DP, TIMER_FLAG_NO_MAPCHANGE);
		
		WritePackCell(DP, GetClientUserId(client));
		WritePackCell(DP, zone);

		return;
	}
}
public void ShowMinigamesMenu(int client, int zone)
{

	Handle hMenu = CreateMenu(Minigames_MenuHandler);

	char sZoneRef[64];
	IntToString(EntIndexToEntRef(zone), sZoneRef, sizeof(sZoneRef));

	AddMenuItem(hMenu, sZoneRef, "Create KZ Zone");
	AddMenuItem(hMenu, sZoneRef, "Remove KZ Zone");

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Minigames_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		char sZoneRef[64];
		GetMenuItem(hMenu, item, sZoneRef, sizeof(sZoneRef));

		int zone = EntRefToEntIndex(StringToInt(sZoneRef));

		if(zone == -1)
			return 0;

		g_refActiveZone = INVALID_ENT_REFERENCE;
		g_iTotalKZTiles = 0;

		switch (item)
		{
			case 0:
			{
				InitiateKZ(client, zone, false);
			}
			case 1:
			{
				TryRemoveKZ();
			}
		}

		ShowMinigamesMenu(client, zone);
	}

	return 0;
}

public Action Timer_InitiateForceKZ(Handle hTimer, Handle DP)
{
	ResetPack(DP);

	int client = GetClientOfUserId(ReadPackCell(DP));
	int zone = ReadPackCell(DP);

	if(client == 0)
	{
		Command_ForceKZ(0, 0);
		return Plugin_Continue;
	}

	float fOrigin[3], fFinalOrigin[3];
	GetClientEyePosition(client, fOrigin);
	InitiateKZ(client, zone, true);
	GetClientEyePosition(client, fOrigin);

	if(GetVectorDistance(fOrigin, fFinalOrigin) <= 4.0)
	{
		Command_ForceKZ(0, 0);
	}

	return Plugin_Continue;
}

stock void InitiateKZ(int client, int zone, bool bForce)
{
	TryRemoveKZ();

	char model[256];
	model = "models/error.mdl";

	PrecacheModel(model);

	ArrayList usedOrigins;
	usedOrigins = new ArrayList(3);

	while(!PerformRandomSpotFind(client, zone, GetRandomInt(16, 32), usedOrigins, 125.0, 160.0, GetRandomFloat(40.0, 60.0), true))
	{
		continue;
	}
	

	for(int i=0;i < usedOrigins.Length;i++)
	{
		float fOrigin[3];
		usedOrigins.GetArray(i, fOrigin);

		int entity = CreateEntityByName("func_brush");

		char iName[64];
		FormatEx(iName, sizeof(iName), "Minigame_Brush_KZ_%i", i);
		DispatchKeyValue(entity, "targetname", iName);

		SetEntityModel(entity, model);

		DispatchSpawn(entity);


		SetEntProp(entity, Prop_Data, "m_nSolidType", 2);
		SetEntProp(entity, Prop_Send, "m_fEffects", 32);

		float fMins[3] = {-16.0, -16.0, -16.0};
		float fMaxs[3] = {16.0, 16.0, 4.0};

		if(i > 0)
		{
			fMins[2] = -40.0;
		}

		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);

		
		SetEntPropVector(entity, Prop_Send, "m_vecMins", fMins);
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", fMaxs);


		SDKHook(entity, SDKHook_StartTouchPost, OnKZStartTouchPost);
	}

	g_refActiveZone = EntIndexToEntRef(zone);
	g_iTotalKZTiles = usedOrigins.Length;

	for(int i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_T)
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		else if(!fuckZones_IsClientInZoneIndex(i, zone) && !bForce)
			continue;
			
		g_bKZParticipant[i] = true;

		TeleportClientToZone(i, zone);
	}

	delete usedOrigins;
}

stock void TryRemoveKZ()
{
	int entity = -1;

	while ((entity = FindEntityByTargetname(entity, "Minigame_Brush_", false, true)) != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}

	for(int i=1;i <= MaxClients;i++)
	{
		g_iLastTileTouched[i] = 0;

		g_iMaxTileTouched[i] = 0;

		g_bKZParticipant[i] = false;


	}
}


public void OnKZStartTouchPost(int kzTile, int toucher)
{
	if(!IsPlayer(toucher))
		return;

	else if(!g_bKZParticipant[toucher])
		return;

	int groundEnt = GetEntPropEnt(toucher, Prop_Data, "m_hGroundEntity");

	if(groundEnt != kzTile)
		return;

	char iName[64];
	GetEntPropString(kzTile, Prop_Data, "m_iName", iName, sizeof(iName));
	ReplaceStringEx(iName, sizeof(iName), "Minigame_Brush_KZ_", "");

	int tileNum = StringToInt(iName);
	g_iLastTileTouched[toucher] = tileNum;

	if(g_iMaxTileTouched[toucher] < tileNum)
		g_iMaxTileTouched[toucher] = tileNum;

	if(g_refActiveZone != INVALID_ENT_REFERENCE && tileNum == g_iTotalKZTiles-1)
	{
		int zone = EntRefToEntIndex(g_refActiveZone);

		if(zone == INVALID_ENT_REFERENCE)
			return;

		for(int i=1;i<=MaxClients;i++)
		{
			if(!g_bKZParticipant[i])
				continue;

			TeleportClientToZone(i, zone);

		}

		int entity = -1;

		while ((entity = FindEntityByTargetname(entity, "Minigame_Brush_", false, true)) != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}

		g_refActiveZone = INVALID_ENT_REFERENCE;
		g_iTotalKZTiles = 0;
		
		int secondBestScore = -2;

		for(int i=1;i<=MaxClients;i++)
		{
			if(!g_bKZParticipant[i])
				continue;

			else if(i == toucher)
				continue;

			if(g_iLastTileTouched[i] > secondBestScore)
				secondBestScore = g_iLastTileTouched[i];
		}

		ArrayList secondBests = CreateArray(1);

		for(int i=1;i<=MaxClients;i++)
		{
			if(!g_bKZParticipant[i])
				continue;

			else if(i == toucher)
				continue;

			if(g_iLastTileTouched[i] == secondBestScore)
				secondBests.Push(i);
		}

		if(secondBests.Length == 0)
		{
			return;
		}
		else if(secondBests.Length > 1)
		{
			int lucky = secondBests.Get(GetRandomInt(0, secondBests.Length-1));

			secondBests.Clear();
			
			secondBests.Push(lucky);
		}

		int secondBest = secondBests.Get(0);

		if(JailBreakDays_IsDayActive())
		{
			for(int i=1;i <= MaxClients;i++)
			{
				if(!IsClientInGame(i))
					continue;
				
				else if(!IsPlayerAlive(i))
					continue;

				else if(GetClientTeam(i) != CS_TEAM_T)
					continue;

				else if(i == toucher)
					continue;

				else if(i == secondBest)
					continue;

				FinishHim(i, toucher);
			}

			FinishHim(secondBest, toucher);

			CS_RespawnPlayer(toucher);
		}
		else
		{
			UC_PrintToChatAll("%N won the KZ. Second best was %N", toucher, secondBest);
		}
	}
}

public bool TraceRayFilter(int entity, int mask, any data)
{
	if (entity != 0)
	{
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));

		if(StrEqual(classname, "func_brush"))
		{
			char iName[64];
			GetEntPropString(entity, Prop_Data, "m_iName", iName, sizeof(iName));
			ReplaceStringEx(iName, sizeof(iName), "Minigame_Brush_KZ_", "");

			int tileNum = StringToInt(iName);

			if(tileNum > 0)
				return false;
				
			return true;
		}
		
		return false;
	}

	return true;
}




public void cvChange_Prefix(Handle convar, const char[] oldValue, const char[] newValue)
{
	FormatEx(PREFIX, sizeof(PREFIX), newValue);
}

public void cvChange_MenuPrefix(Handle convar, const char[] oldValue, const char[] newValue)
{
	FormatEx(MENU_PREFIX, sizeof(MENU_PREFIX), newValue);
}


stock bool PerformRandomSpotFind(int client, int zone, int amountOfTimes, ArrayList usedOrigins, const float fMinDistanceToRelativeOrigin = 0.0, const float fMaxDistanceToRelativeOrigin = -1.0, const float fExtraHeight = 0.0, bool bSequential)
{
	int failSafe = 0;

	
	while(usedOrigins.Length < amountOfTimes)
	{
		failSafe++;

		if(failSafe > 2000)
		{
			PrintToConsoleAll("Gave up entirely");
			return false;
		}

		if(bSequential)
		{
			if(GetRandomInt(0, 1) == 0)
				FindRandomSpotInZone(client, zone, usedOrigins, fMinDistanceToRelativeOrigin, fMaxDistanceToRelativeOrigin, fExtraHeight, 1);

			else
				FindRandomSpotInZone(client, zone, usedOrigins, fMinDistanceToRelativeOrigin, fMaxDistanceToRelativeOrigin, fExtraHeight, -1);
		}
		else
			FindRandomSpotInZone(client, zone, usedOrigins, fMinDistanceToRelativeOrigin, fMaxDistanceToRelativeOrigin, fExtraHeight, 0);

		if(usedOrigins.Length >= amountOfTimes)
		{
			for(int i=0;i < usedOrigins.Length;i++)
			{
				float fUsedOrigin[3];
				usedOrigins.GetArray(i, fUsedOrigin);

				// Null vector, the map is between -32767 and 32767 units
				if(fUsedOrigin[0] >= 1000000.0)
				{
					usedOrigins.Erase(i);
					i--;
				}
			}
			return true;
		}
	}
	return true;
}
// fRelativeOrigin is an origin to compare max distance and add extra height to.
// Sequential means two spots will be parallel, and only take one path
// When you loop this stock, do not create entities or otherwise use the array usedOrigins until you're done looping.
// Also when you loop this stock, use while(usedOrigins.Length < targetOrigins) rather than inputting this stock targetOrigins times.

stock void FindRandomSpotInZone(int client, int zone, ArrayList usedOrigins, const float fMinDistanceToRelativeOrigin = 0.0, const float fMaxDistanceToRelativeOrigin = -1.0, const float fExtraHeight = 0.0, int sequence)
{
	float vecClientMins[3], vecClientMaxs[3];
	GetClientMins(client, vecClientMins);
	GetClientMaxs(client, vecClientMaxs);

	float vecMins[3], vecMaxs[3], vecOrigin[3];
	GetEntPropVector(zone, Prop_Data, "m_vecMins", vecMins);
	GetEntPropVector(zone, Prop_Data, "m_vecMaxs", vecMaxs);
	GetEntPropVector(zone, Prop_Data, "m_vecAbsOrigin", vecOrigin);

	vecOrigin[2] += 32.0;

	for(int i=0;i < 2;i++)
	{
		vecMins[i] += vecOrigin[i];
		vecMaxs[i] += vecOrigin[i];

		vecMins[i] -= vecClientMins[i];
		vecMaxs[i] -= vecClientMaxs[i];
	}

	vecMins[2] += vecOrigin[2];
	vecMaxs[2] += vecOrigin[2];

	vecMaxs[2] -= vecClientMaxs[2];

	float fRelativeOrigin[3];
	fRelativeOrigin = NULL_VECTOR;

	if(usedOrigins.Length > 0)
	{
		usedOrigins.GetArray(usedOrigins.Length - 1, fRelativeOrigin);
	}

	if(usedOrigins.Length == 0)
	{
		//PrintToConsoleAll("Null vector | %.0f %.0f %.0f", vecOrigin[0], vecOrigin[1], vecOrigin[2]);


		float vecRandom[3];

		for(int i=0;i < 2;i++)
		{
			vecRandom[i] = GetRandomFloat(vecMins[i], vecMaxs[i]);
		}

		vecRandom[2] = vecMins[2];

		usedOrigins.PushArray(vecRandom);
	}
	else
	{
		float fCurRelativeOrigin[3];
		fCurRelativeOrigin = fRelativeOrigin;
	
		fCurRelativeOrigin[2] += fExtraHeight;

		if(sequence != 0)
		{
			int failSafe = 0;
			//int correctionFailSafe = 0;

			bool bInvalid = false;

			do
			{
				bInvalid = false;

				failSafe++;

				if(failSafe > 500)
				{
					PrintToConsoleAll("Failed to find a spot in the zone after 500 tries");
					usedOrigins.Clear();
					return;
				}

				// Reassign because of the code in the front.
				if(usedOrigins.Length > 0)
				{
					usedOrigins.GetArray(usedOrigins.Length - 1, fRelativeOrigin);
				}

				fCurRelativeOrigin = fRelativeOrigin;

				fCurRelativeOrigin[2] += fExtraHeight;

				// Only change one axis to ensure they are parallel.
				fCurRelativeOrigin[GetRandomInt(0, 1)] += float(sequence) * GetRandomFloat(fMinDistanceToRelativeOrigin, fMaxDistanceToRelativeOrigin);

				if(fCurRelativeOrigin[2] + vecClientMaxs[2] + 32.0 > vecMaxs[2])
				{
					for(int i=0;i < 100;i++)
					{
						usedOrigins.PushArray(view_as<float>({1000000.0, 1000000.0, 1000000.0}));
					}

					return;
				}

				int i=0;

				for(i=0;i < usedOrigins.Length;i++)
				{
					float fUsedOrigin[3];
					usedOrigins.GetArray(i, fUsedOrigin);

					//PrintToConsole(client, "Distance from origin %i to %i: %.2f", usedOrigins.Length - 1, i, GetVectorDistance(fCurRelativeOrigin, fUsedOrigin));

					float vector1[3], vector2[3];

					vector1 = fCurRelativeOrigin;
					vector2 = fUsedOrigin;
					
					if(FloatAbs(vector1[2] - vector2[2]) <= 4.5 * fExtraHeight)
					{
						// If we climbed 4 tiles or less, pretend they are the same height to remove a tile directly above us if it made a circle of a square.
						vector1[2] = vector2[2];
					}

					if(GetVectorDistance(vector1, vector2) < fMinDistanceToRelativeOrigin)
					{

						usedOrigins.Clear();
						return;
					}
				}
			}
			while(!IsOriginInBox(fCurRelativeOrigin, vecMins, vecMaxs) || bInvalid);
		}
		else
		{
			// Save hard logic for later.
		}

		usedOrigins.PushArray(fCurRelativeOrigin);
	}
}

bool IsOriginInBox(float fOrigin[3], float vecMins[3], float vecMaxs[3])
{
	if (fOrigin[0] >= vecMins[0] && fOrigin[1] >= vecMins[1] && fOrigin[2] >= vecMins[2] && fOrigin[0] <= vecMaxs[0] && fOrigin[1] <= vecMaxs[1] && fOrigin[2] <= vecMaxs[2])
	{
		return true;
	}

	return false;
}


stock int FindEntityByTargetname(int startEnt, const char[] TargetName, bool caseSensitive, bool Contains)    // Same as FindEntityByClassname with sensitivity and contain features
{
	int entCount = GetEntityCount();

	char EntTargetName[300];
	for (int i = startEnt + 1; i < entCount; i++)
	{
		if (!IsValidEntity(i))
			continue;

		else if (!IsValidEdict(i))
			continue;

		GetEntPropString(i, Prop_Data, "m_iName", EntTargetName, sizeof(EntTargetName));

		if ((StrEqual(EntTargetName, TargetName, caseSensitive) && !Contains) || (StrContains(EntTargetName, TargetName, caseSensitive) != -1 && Contains))
			return i;
	}

	return -1;
}


void TE_DrawBeamBoxToClient(int client, float bottomCorner[3], float upperCorner[3], int modelIndex, int haloIndex, int startFrame, int frameRate, float life, float width, float endWidth, int fadeLength, float amplitude, const int color[4], int speed, int displayType)
{
	int clients[1];
	clients[0] = client;
	TE_DrawBeamBox(clients, 1, bottomCorner, upperCorner, modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed, displayType);
}

stock void TE_DrawBeamBoxToAll(float bottomCorner[3], float upperCorner[3], int modelIndex, int haloIndex, int startFrame, int frameRate, float life, float width, float endWidth, int fadeLength, float amplitude, const int color[4], int speed, int displayType)
{
	int[] clients = new int[MaxClients];
	int numClients;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[numClients++] = i;
		}
	}

	TE_DrawBeamBox(clients, numClients, bottomCorner, upperCorner, modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed, displayType);
}

void TE_DrawBeamBox(int[] clients, int numClients, float bottomCorner[3], float upperCorner[3], int modelIndex, int haloIndex, int startFrame, int frameRate, float life, float width, float endWidth, int fadeLength, float amplitude, const int color[4], int speed, int displayType)
{
	float corners[8][3];

	if (upperCorner[2] < bottomCorner[2])
	{
		float buffer[3];
		buffer       = bottomCorner;
		bottomCorner = upperCorner;
		upperCorner  = buffer;
	}

	for (int i = 0; i < 4; i++)
	{
		Array_Copy(bottomCorner, corners[i], 3);
		Array_Copy(upperCorner, corners[i + 4], 3);
	}

	corners[1][0] = upperCorner[0];
	corners[2][0] = upperCorner[0];
	corners[2][1] = upperCorner[1];
	corners[3][1] = upperCorner[1];
	corners[4][0] = bottomCorner[0];
	corners[4][1] = bottomCorner[1];
	corners[5][1] = bottomCorner[1];
	corners[7][0] = bottomCorner[0];

	for (int i = 0; i < 4; i++)
	{
		int j = (i == 3 ? 0 : i + 1);
		TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}

	if (displayType == DISPLAY_TYPE_FULL)
	{
		for (int i = 4; i < 8; i++)
		{
			int j = (i == 7 ? 4 : i + 1);
			TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
			TE_Send(clients, numClients);
		}

		for (int i = 0; i < 4; i++)
		{
			TE_SetupBeamPoints(corners[i], corners[i + 4], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
			TE_Send(clients, numClients);
		}
	}
}

stock bool IsPlayer(int client)
{
	if(client == 0)
		return false;
	
	else if(client > MaxClients)
		return false;
	
	return true;
}

stock void TeleportClientToZone(int client, int zone)
{			
	float fMins[3], fMaxs[3], fOrigin[3], fDest[3];
	GetEntPropVector(zone, Prop_Data, "m_vecMins", fMins);
	GetEntPropVector(zone, Prop_Data, "m_vecMaxs", fMaxs);
	GetEntPropVector(zone, Prop_Data, "m_vecAbsOrigin", fOrigin);
	fDest[0] = fOrigin[0] + (fMins[0] + fMaxs[0]) / 2.0;
	fDest[1] = fOrigin[1] + (fMins[1] + fMaxs[1]) / 2.0;
	fDest[2] = fOrigin[2] + (fMins[2] + fMaxs[2]) / 2.0;

	TR_TraceRayFilter(fDest, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_PLAYERSOLID, RayType_Infinite, TraceRayFilter);
	TR_GetEndPosition(fDest);
	
	TeleportEntity(client, fDest, NULL_VECTOR, NULL_VECTOR);

	g_fLastValidOrigin[client] = fDest;
}

stock void FinishHim(int victim, int attacker)
{
	if (!IsClientInGame(victim) || !IsClientInGame(attacker))
		return;

	int inflictor = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	SetEntityHealth(victim, 100);
	SetClientGodmode(victim);
	SetClientNoclip(victim);
	SDKHooks_TakeDamage(victim, inflictor, attacker, 32767.0, DMG_SLASH);
}

stock void SetClientGodmode(int client, bool godmode = false)
{
	if (godmode)
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

	else
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

stock void SetClientNoclip(int client, bool noclip = false)
{
	if (noclip)
	{
		SetEntProp(client, Prop_Send, "movetype", MOVETYPE_NOCLIP, 1);
	}
	else
		SetEntProp(client, Prop_Send, "movetype", 1, 1);
}
