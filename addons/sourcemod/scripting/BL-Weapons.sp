#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

new Handle:cpLastRifle = INVALID_HANDLE;
new Handle:cpLastPistol = INVALID_HANDLE;
new Handle:cpNeverShow = INVALID_HANDLE;
//new Handle:hcv_CK = INVALID_HANDLE;

new bool:SaveLastGuns[MAXPLAYERS+1];
new bool:DontShow[MAXPLAYERS+1];

enum struct enWeapons
{
	char enWeaponName[64];
	char enWeaponClassname[64];
}

enWeapons RifleList[] =
{
	{ "M4A1", "weapon_m4a1" },
	{ "M4A1-S", "weapon_m4a1_silencer" },
	{ "AK47", "weapon_ak47" },
	{ "AWP", "weapon_awp" },
	{ "FAMAS", "weapon_famas" },
	{ "Galil AR", "weapon_galilar" },
	{ "SG553", "weapon_sg556" },
	{ "AUG", "weapon_aug" },
	{ "UMP-45", "weapon_ump45" }
};

enWeapons PistolList[] =
{
	{ "Desert Eagle", "weapon_deagle" },
	{ "USP-S", "weapon_usp_silencer" },
	{ "P2000", "weapon_hkp2000" },
	{ "Glock-18", "weapon_glock" },
	{ "P250", "weapon_p250" },
	{ "Tec-9", "weapon_tec9" },
	{ "Five-Seven", "weapon_fiveseven" },
	{ "CZ75-Auto", "weapon_cz75a" },
	{ "Dual Berettas", "weapon_elite" }
};

public Plugin:myinfo = 
{
	name = "[CSGO] JailBreak Weapons Menu",
	author = "Eyal282",
	description = "Gives the Guards a menu to pick their favourite weapon",
	version = "1.0",
	url = "None."
}

new Handle:hcv_Enabled = INVALID_HANDLE;

public OnPluginStart()
{
	// The cvar to enable the plugin. 0 = Disabled. Other values = Enabled.
	hcv_Enabled = CreateConVar("jb_weapons_enabled", "1");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	RegConsoleCmd("sm_guns", Command_Guns, "Disable auto gun choice");

	cpLastRifle = RegClientCookie("WeaponsMenu_LastRifle", "Player's Last Chosen Rifle", CookieAccess_Private);
	cpLastPistol = RegClientCookie("WeaponsMenu_LastPistol", "Player's Last Chosen Pistol", CookieAccess_Private);
	cpNeverShow = RegClientCookie("WeaponsMenu_NeverShow", "Should the player see the weapon menu at all?", CookieAccess_Private);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		DontShow[i] = false;
		SaveLastGuns[i] = false;
	}
	
}

public OnClientConnected(client)
{
	DontShow[client] = false;
	SaveLastGuns[client] = false;
}

public OnConfigsExecuted()
{
	//hcv_CK = FindConVar("adp_ck_enabled");
}

public Action:Command_Guns(client, args)
{
	if(SaveLastGuns[client])
	{
		SaveLastGuns[client] = false;
		PrintToChat(client, " \x05Last guns save\x01 is now disabled.");
	}
	
	SetClientDontShow(client, false);
	DontShow[client] = false;
	return Plugin_Handled;
}
public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(GetConVarInt(hcv_Enabled) == 0)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));			
	
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	StripPlayerWeapons(client);
	GivePlayerItem(client, "weapon_knife");
	
	if(GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Continue;
	
	else if(DontShow[client])
		return Plugin_Continue;
	
	else if(GetClientDontShow(client))
		return Plugin_Continue;
		
	else if(SaveLastGuns[client])
	{
		PrintToChat(client, "\x01Type\x05 !guns\x01 to disable\x05 auto gun save\x01.");
		RequestFrame(GivePistol, GetClientUserId(client));
		RequestFrame(GiveRifle, GetClientUserId(client));
		return Plugin_Continue;
	}
	
	new String:TempFormat[150];
	new Handle:hMenu = CreateMenu(Choice_MenuHandler);
	
	AddMenuItem(hMenu, "", "Choose your guns");
	AddMenuItem(hMenu, "", "Last Guns");
	AddMenuItem(hMenu, "", "Last Guns + Save");
	AddMenuItem(hMenu, "", "Don't show again");
	AddMenuItem(hMenu, "", "Never show again");
	
	Format(TempFormat, sizeof(TempFormat), "Choose your guns:\n \nLast Rifle: %s\nLast Pistol: %s \n ", RifleList[GetClientLastRifle(client)], PistolList[GetClientLastPistol(client)]);
	
	SetMenuTitle(hMenu, TempFormat);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public Choice_MenuHandler(Handle:hMenu, MenuAction:action, client, item) // client and item are only valid in MenuAction_Select and something else.
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == CS_TEAM_CT)
				{
					switch(item+1)
					{
						case 1: ShowWeaponsMenu(client);
						case 2:
						{
							RequestFrame(GivePistol, GetClientUserId(client));
							RequestFrame(GiveRifle, GetClientUserId(client));
						}
						case 3:
						{
							RequestFrame(GivePistol, GetClientUserId(client));
							RequestFrame(GiveRifle, GetClientUserId(client));
							SaveLastGuns[client] = true;
						}
						case 4:
						{
							DontShow[client] = true;
							SaveLastGuns[client] = false;
							
							PrintToChat(client, "\x01Type\x05 !guns\x01 to see the weapon menu again.");
							PrintToChat(client, "\x01The weapon menu will not appear again until you reconnect.");
						}
						case 5:
						{
							SetClientDontShow(client, true);
							SaveLastGuns[client] = false;
							
							PrintToChat(client, "\x01Type\x05 !guns\x01 to see the weapon menu again.");
							PrintToChat(client, "\x01The weapon menu will never appear again even after you logout.");
						}
					}
				}
			}
		}	
	}
	hMenu = INVALID_HANDLE;
}

public ShowWeaponsMenu(client)
{
	new Handle:hMenu = CreateMenu(Weapons_MenuHandler);
	
	for(new i=0;i < sizeof(RifleList);i++)
	{
		AddMenuItem(hMenu, "", RifleList[i].enWeaponName);
	}
	
	SetMenuTitle(hMenu, "Choose your rifle:");
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Weapons_MenuHandler(Handle:hMenu, MenuAction:action, client, item) // client and item are only valid in MenuAction_Select and something else.
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == CS_TEAM_CT)
				{
					SetClientLastRifle(client, item);
					
					RequestFrame(GiveRifle, GetClientUserId(client));
					
					ShowPistolMenu(client);
				}
			}
		}	
	}
	hMenu = INVALID_HANDLE;
}

ShowPistolMenu(client)
{
	if(GetConVarInt(hcv_Enabled) == 0)
		return;
	
	else if(!IsClientInGame(client))
		return;
	
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return;
	
	new Handle:hMenu = CreateMenu(Pistols_MenuHandler);
	
	for(new i=0;i < sizeof(PistolList);i++)
	{
		AddMenuItem(hMenu, "", PistolList[i].enWeaponName);
	}
	
	SetMenuTitle(hMenu, "Choose your pistol:");
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Pistols_MenuHandler(Handle:hMenu, MenuAction:action, client, item) // client and item are only valid in MenuAction_Select and something else.
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == CS_TEAM_CT)
				{
					SetClientLastPistol(client, item);
					
					RequestFrame(GivePistol, GetClientUserId(client));
				}				
			}
		}	
	}
	hMenu = INVALID_HANDLE;
}

public GivePistol(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return;
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
							
	if(weapon != -1)
		CS_DropWeapon(client, weapon, false, true);
		
	GivePlayerItem(client, PistolList[GetClientLastPistol(client)].enWeaponClassname);
}

public GiveRifle(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return;
		
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
							
	if(weapon != -1)
		CS_DropWeapon(client, weapon, false, true);
		
	GivePlayerItem(client, RifleList[GetClientLastRifle(client)].enWeaponClassname);
}
stock StripPlayerWeapons(client)
{
	for(new i=0;i <= 5;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			i--;
		}
	}
}

stock SetClientArmor(client, amount, helmet=-1) // helmet: -1 = unchanged, 0 = no helmet, 1 = yes helmet
{
	if(helmet != -1)
		SetEntProp(client, Prop_Send, "m_bHasHelmet", helmet);
		
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
}


stock SetClientLastPistol(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpLastPistol, strAmount);
	
}

stock GetClientLastPistol(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpLastPistol, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}


stock SetClientLastRifle(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpLastRifle, strAmount);
	
}

stock GetClientLastRifle(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpLastRifle, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}


stock bool:GetClientDontShow(client)
{
	new String:strNeverShow[50];
	GetClientCookie(client, cpNeverShow, strNeverShow, sizeof(strNeverShow));
	
	if(strNeverShow[0] == EOS)
	{
		SetClientDontShow(client, false);
		return true;
	}
	
	return view_as<bool>(StringToInt(strNeverShow));
}

stock bool:SetClientDontShow(client, bool:value)
{
	new String:strNeverShow[50];
	
	IntToString(view_as<int>(value), strNeverShow, sizeof(strNeverShow));
	SetClientCookie(client, cpNeverShow, strNeverShow);
	
	return value;
}


stock PrintToChatEyal(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			

		new String:steamid[64];
		GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144"))
			PrintToChat(i, buffer);
	}
}