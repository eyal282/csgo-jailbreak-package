#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

public Plugin:myinfo = {
	name = "Damage Indicator",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Shows where you damage and who you damage and how much.",
	version = "1.0",
	url = "NULL"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public Action:Event_PlayerHurt(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	/* hitgroup 0 = generic */
	/* hitgroup 1 = head */
	/* hitgroup 2 = chest */
	/* hitgroup 3 = stomach */
	/* hitgroup 4 = left arm */
	/* hitgroup 5 = right arm */
	/* hitgroup 6 = left leg */
	/* hitgroup 7 = right leg */
	new type = GetEventInt(hEvent, "type");
	
	if(type & DMG_FALL)
		return;
		
	new victim 			= GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker 		= GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new damage 	= GetEventInt(hEvent, "dmg_health");	
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		if(attacker == i || (!IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == attacker))
			PrintCenterText(i, "<font color='#0000FF'>-%i HP</font>", damage);
			
		else if(victim == i || (!IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == victim))
			PrintCenterText(i, "<font color='#FF0000'>-%i HP</font>", damage);
	}
}