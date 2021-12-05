#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define semicolon 1
#define newdecls required

Handle Team

public Plugin myinfo = {
	name = "Auto Join On Connect",
	author = "Author was lost by a thief :(",
	description = "Auto Join On Connect",
	version = "1.0",
	url = ""
};

public void OnPluginStart( ) {
	Team = CreateConVar( "sm_join_team", "2", "Do not edit this" )
	HookEvent( "player_connect_full", Event_OnFullConnect, EventHookMode_Post )
}

public Action Event_OnFullConnect( Handle event, const char[] name, bool dontBroadcast ) {
	int client = GetClientOfUserId( GetEventInt( event, "userid" ) )
	
	if( client != 0 && IsClientInGame( client ) && !IsFakeClient( client ) ) {
		CreateTimer( 0.5, AssignTeam, client )
	}
}

public Action AssignTeam( Handle timer, any client ) {
	if( IsClientInGame( client ) ) {
		int iCvar = GetConVarInt( Team )
		
		switch( iCvar ) {
			case 0 : {
				return Plugin_Handled
			}
			case 1 : {
				int iRed, iBlue;
				for(int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i))
						continue;

					int iTeam = GetClientTeam(i);
					if(iTeam == CS_TEAM_T)
						iRed++;
					else if(iTeam == CS_TEAM_CT)
						iBlue++;
				}
				if( iRed > iBlue )
				{
					ChangeClientTeam( client, 3 )
				}
				else
				if( iRed < iBlue )
				{
					ChangeClientTeam( client, 2 )
				}
				else
				if( iRed == iBlue )
				{
					ChangeClientTeam( client, 2 )
				}
							
			}
			
			case 2 : {
				ChangeClientTeam( client, 2 )
			}
			
			case 3 : {
				ChangeClientTeam( client, 3 )
			}
		}
	}
	
	return Plugin_Continue
}
