#include <sourcemod>
#include <sdktools>

#define semicolon 1
#define newdecls  required

public Plugin myinfo =
{
	name        = "JailBreak Config",
	author      = "Eyal282",
	description = "Basic JailBreak Config",
	version     = "1.0",
	url         = ""
};

enum struct enCvarList
{
	char name[64];
	char value[256];
}

// Cvar, Value
enCvarList cvarList[] = {
	{"sm_vote_delay",          "0"         },
	{ "uc_party_mode",         "0"         },
	{ "mp_autokick",           "0"         },
	{ "mp_freezetime",         "0"         },
	{ "mp_friendlyfire",       "0"         },
	{ "mp_timelimit",          "60"        },
	{ "mp_teamcashawards",     "0"         },
	{ "mp_startmoney",         "0"         },
	{ "mp_solid_teammates",    "1"         },
	{ "mp_roundtime",          "15"        },
	{ "mp_warmuptime",         "0"         },
	{ "mp_do_warmup_period",   "0" },

	{ "sv_full_alltalk",       "1"         },
	{ "sv_alltalk",            "1"         },

 // Airaccelerate is the ability to turn backwards or sideways mid-air.
	{ "sv_airaccelerate",      "2147483647"},

 // Removes stamina penalty. Otherwise bunnyhopping would reach lower heights ( also would have caused no footsteps on landing )
	{ "sv_staminamax",         "0"         },

 // Semi automatic bunnyhopping. For auto bhop, enables better speeds.
	{ "sv_enablebunnyhopping", "1"         },

 // These two remove the money hud.
	{ "mp_playercashawards",   "0"         },
	{ "mp_teamcashawards",     "0"         }
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	if(GameRules_GetProp("m_bWarmupPeriod"))
	{
		ServerCommand("mp_warmup_end");
	}
}
public void OnMapStart()
{
	for(float i=0.0;i < 5.0;i += 0.2)
	{
		CreateTimer(i, Timer_ExecuteConfig, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ExecuteConfig(Handle hTimer)
{
	for (int i = 0; i < sizeof(cvarList); i++)
	{
		ConVar convar = FindConVar(cvarList[i].name);
		if (convar != null)
		{
			SetConVarString(convar, cvarList[i].value);
		}
	}
}
