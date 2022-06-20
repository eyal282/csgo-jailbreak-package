#if defined _JAILBREAK_included
 #endinput
#endif
#define _JAILBREAK_included

#define GANG_NULL ""
#define GANGID_NULL 0

#define RANK_NULL -1
#define RANK_MEMBER 0
#define RANK_ENFORCER 1
#define RANK_ADVISOR 2
#define RANK_MANAGER 3
#define RANK_COLEADER 4
#define RANK_LEADER 420

#define MODACTION_INVITE 0
#define MODACTION_KICK 1
#define MODACTION_PROMOTE 2
#define MODACTION_MOTD 3
#define MODACTION_UPGRADE 4
#define MODACTION_DISBAND 5

char Colors[][] = 
{
	"{NORMAL}", "{RED}", "{GREEN}", "{LIGHTGREEN}", "{OLIVE}", "{LIGHTRED}", "{GRAY}", "{YELLOW}", "{ORANGE}", "{BLUE}", "{PINK}"
};

char ColorEquivalents[][] =
{
	"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0C", "\x0E"
};

stock void UC_ReplyToCommand(int client, const char[] format, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[256];

	VFormat(buffer, sizeof(buffer), format, 3);
	for(int i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	ReplyToCommand(client, buffer);
}

stock void UC_PrintToChat(int client, const char[] format, any ...)
{
	SetGlobalTransTarget(client);
	
	char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	for(int i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	PrintToChat(client, buffer);
}

stock void UC_PrintToChatAll(const char[] format, any ...)
{	
	char buffer[256];
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		SetGlobalTransTarget(i);
		VFormat(buffer, sizeof(buffer), format, 2);
		
		UC_PrintToChat(i, buffer);
	}
}

stock void UC_StringToUpper(char[] buffer)
{
	int length = strlen(buffer);
	for(int i=0;i < length;i++)
		buffer[i] = CharToUpper(buffer[i]);
}

stock void UC_PrintToChatEyal(const char[] format, any...)
{
	char buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (IsFakeClient(i))
			continue;

		char steamid[64];
		GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));

		if (StrEqual(steamid, "STEAM_1:0:49508144"))
			UC_PrintToChat(i, buffer);
	}
}