/*
** RolePlay new include.
*/

#if defined _RolePlay_included
 #endinput
#endif

#pragma dynamic 131072 

#include <fpvm_interface>
#include <afk_manager>
#include <sdktools>
#include <clientprefs>

#define _RolePlay_included

#define MAX_INTEGER 2147483647

#define PREFIX " \x05[WePlay]\x01"
#define MENU_PREFIX "[WePlay]"

//#define PREFIX " \x05[Swift-IL]\x01"
//#define MENU_PREFIX "[Swift-IL]"

// This is the economy location.
#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/WePlayRP-Economy/master/Economy/updatefile.txt"
//#define UPDATE_URL "https://raw.githubusercontent.com/itssharon12/WePlayRP-Economy/master/Economy/updatefile.txt"

//#define EXPLevel(%1)	( (%1+2) * ((%1+2) - 1) / 2 * 500)

#define PRIORITY_ASSISTBOUNTY 1
#define PRIORITY_THIEF 2
#define PRIORITY_HITMAN 3
#define PRIORITY_LAWYER 4
#define PRIORITY_MEDIC 5

#define BOUNTY_KARMA 1400
#define HPC_KARMA 1200
#define ARREST_KARMA 800


#define KARMA_PER_KILL 400
#define KARMA_PER_SILENT_KILL 250

#define KARMA_PER_STEAL 200
#define KARMA_PER_WEAPON_STEAL 300
#define KARMA_PER_FAILED_STEAL 30

#define KARMA_PER_INFECT 150
#define KARMA_PER_FAILED_INFECT 50

#define KARMA_LOSS_TIME_REASON "Natural Karma Loss by Time"
#define KARMA_LOSS_LAWYER_REASON "Karma Loss by Lawyer"
#define KARMA_KILL_REASON "Kill"
#define KARMA_STEAL_REASON "Steal"
#define KARMA_INFECT_REASON "Infect"
#define KARMA_GAMBLE_REASON "Gamble"
#define KARMA_JACKPOT_REASON "Jackpot"
#define KARMA_TRESPASS_REASON "Trespass"

#define KARMA_MIN 400
#define KARMA_MAX 1400

#define GANG_NULL ""

#define RANK_NULL -1
#define RANK_MEMBER 0
#define RANK_OFFICER 1
#define RANK_ADMIN 2
#define RANK_MANAGER 3
#define RANK_COLEADER 4
#define RANK_LEADER 420

enum cashType
{
	POCKET_CASH = 0,
	BANK_CASH
}

#define START_CASH 50000


/**
* Checks if player is immune to taxes to and from other players.

* @return					true if player is immune to taxes, false otherwise.
*/
native bool RP_IsClientTaxesDisabled(int client);

/**
* Checks if client is high management, as appears in addons/sourcemod/configs/high_management.ini
*
* @param client				client index.

* @return					true if client is high management, false otherwise.
*/
native bool IsHighManagement(int client);

/**
* Get client cash amount
*
* @param client				client.
* @param cashtype			cash type.
* @return cash amount.
*/
native int GetClientCash(int client, int cash_type);

/**
* Set client cash amount
*
* @param client				client.
* @param cashType			cashType.
* @param cash				cash.
*/
native void SetClientCash(int client, int cashtype, int amount);

/**
* Give client cash.
*
* @param client 			client.
* @param cashType			cashType.
* @param amount				amount of cash to give
* @param TaxPercent			Tax Percent to actually apply, if you only want to tax the profit of an action like Drug Dealer who also pays.

* @return					amount of cash after gang tax, if no gang, equal to @param amount
*/
native int GiveClientCash(int client, int cashtype, int amount, Float:TaxPercent=100.0);

/**
* Give AuthId cash.
*
* @param AuthId 			AuthId as can be found in GetClientAuthId(client, AuthId_Engine, AuthId).
* @param amount				amount of cash to give.

* @return					-1 on a rare occasion where client is in game and not loaded, 0 on success on the AuthId
* @return					if the AuthId is found in-game, returns client index instead
*/

native int GiveAuthIdCash(const String:AuthId[], int amount);

/**
* Give client cash without giving a share to his gang
*
* @param client 			client.
* @param cashType			cashType.
* @param amount				amount of cash to give

* @return					amount of cash after gang tax, if no gang, equal to @param amount
*/
native int GiveClientCashNoGangTax(int client, int cashtype, int amount);

/**
* Called when the eco trie was set up completely. Can call by a root admin's command as well, and if it does, the previous tries are all invalidated.
*

* @noreturn
*/
forward void RP_OnEcoLoaded();

/**
* Gets the trie for the economy key.
*
* @param Key 				Key for which to find the trie.

* @return					Handle for the trie of the economy key, or INVALID_HANDLE if the key does not exist within the economy trie.
* @note						Never free this trie via CloseHandle under any circumstance.

*/
native Handle RP_GetEcoTrie(const String:Key[]);

/**
* Creates item.
*
* @param ItemName			ItemName.
* @param ItemShortName		ItemShortName.
* @return item index.
*/
native int RP_CreateItem(const char[] ItemName, const char[] ItemShortName);

/**
* Get item id from item short name
* 
* @param ItemShortName		ItemShortName.

* @return					item index
*/

native int RP_GetItemId(const char[] ItemShortName);

/** 
* Creates category.
*
* @param CategoryName		CategoryName
* @return category id.
*/
native int RP_AddCategory(const char[] CategoryName);

/**
* Get item category for item id.
* 
* @param item				item index.

* @return					categoryid
*/

native int RP_GetItemCategory(int item);

/**
* Changes the item category
*
* @param item				item id.
* @param category			category.
* @noreturn
*/
native void RP_SetItemCategory(int item, int category);

/**
* Give client item
*
* @param client				client index.
* @param item				item index.
* @return					true if client is loaded from database ( and item is deleted ), false otherwise.
*/
native bool RP_GiveItem(int client, int item);

/**
* Give client more than one item
*
* @param client				client index.
* @param item				item index.
* @param count				amount of the item to give.
* @return					true if client is loaded from database ( and item is deleted ), false otherwise.
*/
native bool RP_GiveSeveralItems(int client, int item, int count);

/**
* Removes client item
*
* @param client				client index.
* @param item				item index.
* @return					true if client is loaded from database ( and item is deleted ), false otherwise.
*/
native bool RP_DeleteItem(int client, int item);

/** 
* Return category id for the category name.
*
* @param client				client index.
* @param item				item index.
* @return categoryid		category index.
*/
native int RP_GetCategoryByName(const char[] categoryName);

/**
* Create NPC
*
* @param modelpath			model path
* @param shortname			short name
* @return npcid				npc id
*/
native int RP_CreateNPC(const char[] szModel, const char[] szShortName);

/**
* Create a new job
*
* @param szJobName			job name
* @param szJobShortName		job short name.
* @param maxlevel			job maximum level.
* @return int				job id
*/
native int RP_CreateJob(const char[] szJobName, const char[] szJobShortName, int maxlevel);

/**
* Advance client with exp
*
* @param client				client index.
* @param job				job index.
* @param exp				exp amount
* @noreturn
*/
native void RP_AddClientEXP(int client, int job, int exp);

/**
* Get Client job.
*
* @param client				client index.
* @return job
*/
native int RP_GetClientJob(int client);

/**
* Get Client Job Bank
*
* @param client				client index.
*
* @noreturn
*/
native int RP_GetClientJobBank(int client);


/**
* Get Client job level, if client is VIP the level is increased by one.
*
* @param client				client index.
* @param job				job index.	
* @return job
*/
native int RP_GetClientLevel(int client, int job);

/**
* Get Client true job level, without increasing the level if client is VIP.
*
* @param client				client index.
* @param job				job index.	
* @return job
*/
native int RP_GetClientTrueLevel(int client, int job);

/**
* Get Client job exp.
*
* @param client				client index.
* @param job				job index.	
* @return job
*/
native int RP_GetClientEXP(int client, int job);

/**
* Get Client job of the day and exp left.
*
* @param client				client index.
* @param job				job index.
* @param expLeft			amount of bonus exp the player can get from playing in the job of the day.

* @noreturn
*/
native void RP_GetClientJOTD(int client, int &job, int &expLeft);

/**
* Adds bonus exp left to client's current JOTD.
*
* @param client				client index.
* @param exp				bonus exp left to add.

* @noreturn
*/
native void RP_AddJOTDExp(int client, int exp);

/**
* Count player items for specific item index.
* 
* @param client				client index.
* @param item				item index.
* @return count
*/
native int RP_CountPlayerItems(int client, int item);

/**
* Assuming "client" is the hitman, returns the player that "client" must kill as a hitman.
* 
* @param client				client index.

* @return 					victim client index. "victim" being the player the "client" must kill to finish his job.
*/
native int RP_GetClientHitmanVictim(int client);

/**
* Assuming "client" a player, returns the hitman player that tries to kill "client" to finish his job.
* 
* @param client				client index.

* @return 					attacker client index. "attacker" being the player that must kill "client" to finish his job.
*/

native int RP_GetClientHitmanAttacker(int client);

/**
* Dismisses a client as a cop, and turns him into a hitman without respawning him. Intended use is the cop turns bounty. 
* 
* @param client				client index.
* @noreturn
*
* @note						The native only sets the parameter that handle weapons, and changes to hitman.
*							It does not check if the client actually police.
*/

native void RP_DismissAsCop(int client);

/**
* On use npc
*
* @param client				client index.
* @param id					npc id.
* @param entity				entity index.
*/
forward void OnUseNPC(int client, int id, int entity);

/**
* On client change job.
*
* @param client				client index.
* @param job				job index.
* @param oldjob				job index of old job.
* @param ok					change ok to false to cancel the job change.
* @noreturn
*
* @notes					Order of calls: OnClientChangeJob ---> UpdateJobStats ---> OnClientChangeJobPost
* @notes					job index of -1 indicates no job
* @notes					Called upon disconnect. IsClientInGame can return false if job == -1
* @notes					MVP Count is yet to be changed here. Look for UpdateJobStats if you need to alter it.
* @notes					Knife Model is yet to be reset here. Look for UpdateJobStats if you need to add it.
*/


forward void OnClientChangeJob(int client, int job, int oldjob, bool &ok);

/*
* Called when you should give someone his weapons / player model for his job.
*
* @param client				client index.
* @param job				job index.
* @return					True if weapons are given after one frame, false otherwise.
*							This is used to decide if to swap to knife next frame or after two frames. 
*
* @notes					Order of calls: OnClientChangeJob ---> UpdateJobStats ---> OnClientChangeJobPost
* @notes					job index of -1 indicates no job
* @notes					Called upon disconnect. IsClientInGame can return false if job == -1
* @notes					MVP Count is already changed here. Useful for the Thief job if you want to hide the true level of the player
* @notes					Called after knife model is reset to the player.
* @notes					Called after the client's max health is set to 100. Safe to use for changing max health.
*/
forward bool UpdateJobStats(int client, int job);

/**
* On client change job post.
*
* @param client				client index.
* @param job				job index.
* @param oldjob				job index of old job. If respawn is true, this is the same as @param job.
* @param respawn			true if this is called due to respawn.
* @noreturn
*
* @notes					Order of calls: OnClientChangeJob ---> UpdateJobStats ---> OnClientChangeJobPost
* @notes					job index of -1 indicates no job
* @notes					Called upon disconnect. IsClientInGame can return false if job == -1
* @notes					Called after knife model is reset to the player.
* @notes					Called during respawn.
*/

forward void OnClientChangeJobPost(int client, int job, int oldjob, bool:respawn);

/**
* On client earn job exp
*
* @param client				client index.
* @param job				job index.
* @param originalEXP		Amount of EXP the player initially earned before any plugin interference.
* @param exp				exp to give the player.
* @noreturn
*
* @notes					originalEXP is still multiplied by 1.5 if the player is VIP,
							This forward is used by the plugin that created this forward.
* @notes					Don't use this forward to null exp gain. Create another forward of "OnClientShouldEarnJobEXP"...
							... Because the JOTD plugin already deduces exp left in its plugin
*/

forward void OnClientEarnJobEXP(int client, int job, int originalEXP, int &exp);


/* 
* On item used rp 
*
* @param client				client index.
* @param item				item index.
*
* @return 					Plugin_Continue to let the item be consumed. Plugin_Handled or Plugin_Stop to keep the item in inventory
*/
forward Action OnItemUsed(int client, int item);

/* 
* Called after an item was used, and the plugin gave the item to the client. 
*
* @param client				client index.
* @param item				item index.
* @noreturn
*
* @notes						as of the creation of this forward, it is used exclusively to limit special items to once per spawn.
*/
forward void OnItemUsedPost(int client, int item);

/* 
* Called when player spawns or changes job to thief and needs a fake identity.
*
* @param client				thief's client index.
* @param JobShortName		Short Name of the job the Thief plugin wants to give out the identity ( example: TH, DRUD, MED, HM )
* @param FakeLevel			By reference level of the fake job
* @param LevelName			By reference String of the name of the job ( example: Junkie, Cartel, First Aid, Council Member ) to the list of item IDs that the client has had retrieved.
* @param Model			By reference String of the model of the job ( For SetEntityModel )

* @return					Plugin_Changed if you edited FakeLevel, LevelName and Model.
							If you edit and don't return Plugin_Changed then everything may break.
*/
forward Action Thief_RequestIdentity(int client, const char[] JobShortName, int &FakeLevel, char LevelName[32], char Model[PLATFORM_MAX_PATH]);

/* 
* Called when list of victim's items are retrieved.
*
* @param client				thief's client index.
* @param target				victim of theft's client index.
* @param items				By reference handle to the list of item IDs that the client has had retrieved.
* @noreturn
*/
forward void Thief_OnItemsSteal(client, target, &Handle:items);

/**
* On player interact menu
*
* @param client				client who interacted.
* @param target				client who interacted with.
* @param &menu				menu pointer.
* @param priority			priority being made.

* @noreturn
*/
forward void RP_OnPlayerMenu(int client, int target, Menu &menu, int priority);

/** on player pressed interact menu.
*
* @param client				client index.
* @param target				target player index.
* @param info				menu item info
* @noreturn
*/
forward void RP_OnMenuPressed(int client, int target, const char[] info);

/**
* On player open phone menu
*
* @param client				client who opened phone menu.
* @param &menu				menu pointer.
* @param priority			priority being made.

* @noreturn
*/
forward void RP_OnPhoneMenu(int client, Menu &menu, int priority);

/** on player pressed interact menu.
*
* @param client				client index.
* @param info				menu item info
* @noreturn
*/
forward void RP_OnPhoneMenuPressed(int client, const char[] info);

/** 
* Called each minute passed.
*
* @param client			client index.
* @noreturn
*/
forward void OnMinutePassed(int client);

/** 
* Called each time a client loads / reloads his gang information
*
* @param client			client index.
* @param gang			gang unique index.
* @noreturn
*
*
* @note					gang unique index can be -1 if client doesn't have a gang. This forward can be called several times in the client's connecting session.
*/

forward void On_Player_Loaded_Gang(int client, int gang);

/** 
* Called when a client is kicked from his gang. Called when:
*			 												1. an authority kicks the client.
*															2. the client leaves the gang.
*															3. the client joins the server and the gang was found deleted.
*
* @param client			client index.
* @param GangTag		Gang Tag
* @noreturn
*
*
*/

forward void On_Player_Kicked_From_Gang(int client, const char[] GangTag);

/** 
* Called when a gang's shield percent has been loaded
*
* @param GangTag		Gang Tag
* @param ShieldPercent	Percent of decrease to chance to break into house.
* @noreturn
*
*
* @note					Can be called a lot of times in a kinda short period of time, don't use over expensive functions.
*/
forward void On_Gang_Shield_Loaded(const char[] GangTag, int ShieldPercent);

/** 
* Called when a gang has been disbanded
*
* @param GangTag		Gang Tag
*
* @noreturn
*
*
* @note					This is called before removing all members from their gang.
*						Using "for(int i=1;i <= MaxClients;i++)" and Get_User_Gang_Tag let you find all members that are going to lose their gang.
*/
forward void On_Gang_Disbanded(const char[] GangTag);

/** 
* Called after a player is arrested ( RP_IsClientInJail(victim) is true ).
*
* @param client			arrested client index.
* @param attacker		arresting officer's client index
* @param karma			amount of karma the arrested client had during the arrest.
*
* @noreturn
*/
forward void RP_OnClientArrestedPost(int victim, int attacker, int karma);

/** 
* Called after a player's jail status is changed.
*
* @param client			client whose jail status has changed
*
* @noreturn
*
* @note					Use RP_IsClientInJail or RP_IsClientInAdminJail to determine jail status.
* @note					Forward is called for both admin jail and police jail.
*/
forward void RP_OnClientJailStatusPost(int client);

/**
* Called after a player was teleported to jail for whatever reason.
*
* @param client			client that was teleported to jail.
*
* @noreturn
*
* @note 				Use RP_IsClientInJail or RP_IsClientInAdminJail to determine jail status.
*/
forward void RP_OnClientTeleportToJail(int client);


/** 
* Called after a player is healed by a medic.
*
* @param client			healed client index.
* @param healer			healing medic client index.
* @param iMedicJob		Job index of medic for RP_AddClientEXP.
*
* @noreturn
*/
forward void RP_OnMedicHealedPost(int client, int healer, int iMedicJob);

/*
* Send item to client menu
* @param client				client index.
* @param player				player index.
* @noreturn
*/
native void RP_SendItem(int client, int player);

/*
* Change client karma.
*
* @param client				client index.
* @param amount				karma amount.
* @param bounty				give / take bounty status based on if the player has enough karma afterwards
* @param Reason				Reason for the karma change. If not set, plugins cannot stop the karma from being given
* @noreturn
*/
native void RP_AddKarma(int client, int amount, bool bounty, String:Reason[]);

/*
* Change client karma.
*
* @param client				client index.
* @param amount				karma amount.
* @param bounty				give / take bounty status based on if the player has enough karma afterwards
* @noreturn
*/
native void RP_SetKarma(int client, int amount, bool bounty);

/* Get client karma.
*
* @param client				client index.
* @return karma.
*/
native int RP_GetKarma(int client);

/**
* Checks whether a client should see the list of bounty players in PrintHintText.
* Disallowing to see the message is useful if the user needs to see another message.
*
* @param client				client index.

* @return					Plugin_Continue or Plugin_Changed to let the bounty message be shown to the player
*							Plugin_Handled or Plugin_Stop to hide the message.
*
* @notes					This is called before the karma is given to the client, if you want to calculate
*							new karma if no other plugin changes it, use RP_GetKarma(client) + karma
*/

forward Action RolePlay_ShouldSeeBountyMessage(int client);


/**
* On client karma value changed
*
* @param client				client index.
* @param karma				karma to be added to the client.
* @param Reason				Reason for karma change.
* @param data				Additional data to use ( KARMA_KILL_REASON uses victim client index for example )
* @return					Plugin_Continue or Plugin_Changed to let the karma or new karma to be added,
*							Plugin_Handled or Plugin_Stop to stop the karma change
*
* @notes					This is called before the karma is given to the client, if you want to calculate
*							new karma if no other plugin changes it, use RP_GetKarma(client) + karma
*/

forward Action RolePlay_OnKarmaChanged(int client, int &karma, char[] Reason, any &data);

/**
* On client karma value changed post
*
* @param client				client index.
* @param karma				karma to be added to the client.
* @param totalKarma			total karma of the client.
* @param Reason				Reason for karma change.
* @param data				Additional data to use ( KARMA_KILL_REASON uses victim client index for example )
* @noreturn
*
* @notes					This is called after the karma is given to the client. 
*							Use RP_GetKarma(client) to get the client's total karma.
*/

forward void RolePlay_OnKarmaChangedPost(int client, int karma, int totalKarma, char[] Reason, any data);

/**
* Called right before a client is given bounty status.
*
* @param client				client index.
*
* @return					Plugin_Handled or higher to prevent bounty from being given to the player.
*/

forward Action RolePlay_OnBountySet(int client);


/**
* Update karma in scoreboard
*
* @param client				client index.
* @noreturn
*/
native void RP_UpdateScoreBoard_Karma(int client);

/**
* Get client job name.
*
* @param client 			client index.
* @param buffer 			buffer to copy the job shortname to.
* @param len				buffer length
* @noreturn
*
*
* @notes					A job's short name is saved into the database,
							meaning it's the least likely to change out of the others.
*/
native void RP_GetClientJobShortName(int client, char[] buffer, int len);

/**
* Get client job name.
*
* @param client 			client index.
* @param buffer 			buffer to copy the job name to.
* @param len				buffer length
* @noreturn
*/
native void RP_GetClientJobName(int client, char[] buffer, int len);

/**
* Set client in jail. 
*
* @param client				client index.
* @noreturn 
*/ 
native void RP_JailClient(int client);

/**
* free client from the jail
* 
* @param client				client index.
* @noreturn
*/
native void RP_UnJailClient(int client);

/**
* Is client in jail?
* 
* @param client				client index.
* @return					true if client is in either jail or admin jail, false otherwise.
*/
native bool RP_IsClientInJail(int client);

/**
* Set client in admin jail. 
*
* @param client				client index.
* @param time				amount of time to jail the client for.
* @param Reason				Admin's reason to send the client into jail
* @param AdminName			Name of admin.
* @param AdminAuthId		Steam ID of admin.
* @noreturn 
*/ 
native void RP_AdminJailClient(int client, int time, const char[] Reason, const char[] AdminName, const char[] AdminAuthId);

/**
* free client from the admin jail
* 
* @param client				client index.
* @noreturn
*/
native void RP_AdminUnJailClient(int client);

/**
* Set client in admin jail as the AuthId
*
* @param AuthId				AuthId to punish
* @param time				amount of time to jail the client for.
* @param Reason				Admin's reason to send the client into jail
* @param AdminName			Name of admin.
* @param AdminAuthId		Steam ID of admin.
* @noreturn
*
* @note						If the client owning the Auth Id is in game, he will be properly sent to jail.
*/ 
native void RP_AdminJailSteamId(const char[] AuthId, int time, const char[] Reason, const char[] AdminName, const char[] AdminAuthId);

/**
* free client from the admin jail as the AuthId
* 
* @param AuthId				AuthId to remove punishment from.
* @noreturn
*
* @note						If the client owning the Auth Id is in game, he will be properly released from jail.
*/
native void RP_AdminUnJailSteamId(const char[] AuthId);

/**
* Is client in admin jail?
* 
* @param client				client index.
* @return					true if client is in admin jail, false otherwise.
*/
native bool RP_IsClientInAdminJail(int client);

/**
* Tries to teleport the client to jail if he is in jail
* 
* @param client				client index.
* @noreturn
*
* @notes					Used when player is teleported to the world without a spawn, like leaving admin room.
*/
native void RP_TryTeleportToJail(int client);

/**
* Set client own job name (could by effected by the job level name)
*
* @param client				client index.
* @param jobname			job name.
* @noreturn
*/
native void RP_SetClientJobName(int client, const char[] newname);

/** 
* Get job name
*
* @param job				job index.
* @param buffer				buffer
* @param length				buffer size.
* @return					true if job index is valid, false otherwise.
*
* @notes					To iterate all jobs: 
*							new job = 0;
*							while(RP_GetJobName(job++, buffer, len))
*/
native bool RP_GetJobName(int job, char[] buffer, int len);

/** 
* Get job name
*
* @param job				job index.
* @param buffer				buffer
* @param length				buffer size.
* @return					true if job index is valid, false otherwise.
*
* @notes					To iterate all jobs: 
*							new job = 0;
*							while(RP_GetJobShortName(job++, buffer, len))
*/
native bool RP_GetJobShortName(int job, char[] buffer, int len);

/** 
* Find job index by name
*
* @param szJobName			job name

* @return					job index or -1 if not found.
*/
native bool RP_FindJobByName(const char[] szJobName);

/** 
* Find job index by name
*
* @param szJobShortName		job short name

* @return					job index or -1 if not found.
*/
native bool RP_FindJobByShortName(const char[] szJobShortName);
/**
* Get random item from client inventory.
*
* @param client				client index.
* @return -1 if no items were found or item id
*/
native int RP_GetRandomItem(int client);

/**
* Get random item from client inventory by category index
*
* @param client				client index.
* @param category				category index.

* @return -1 if no items were found or item id
*/

native int RP_GetRandomItemByCategory(int client, int category);

/**
* Get an ArrayList containing all items the client has.
*
* @param client					client index.

* @return								ArrayList. Must be closed with CloseHandle

*/

native ArrayList RP_GetClientItems(client);

/**
* Get an ArrayList containing all items the client has in a category.
*
* @param client					client index.
* @param category				category index.

* @return								ArrayList. Must be closed with CloseHandle

*/

native ArrayList RP_GetClientItemsByCategory(client, category);

/**
* Get item name for item id.
* 
* @param item				item index.
* @param buffer				string buffer.
* @param len				string len.
* @noreturn
*/
native void RP_GetItemName(int item, char[] buffer, int len);

/**
* Get client combined count of grams by all drug types
*
* @param client				client index.
* @return					total grams the client has.
*/
native int RP_GetTotalGrams(int client);

/**
* Resets client grams
*
* @param client				client index.

* @return					amount of money the drugs are worth.
*/
native int RP_ResetGrams(int client);

/** 
* Remove player bounty
*
* @param client			client index.
* @noreturn
*/
native bool RP_RemovePlayerBounty(int client);

/** 
* Gives player bounty status if he has enough karma ( BOUNTY_KARMA constant )
*
* @param client			client index.
* @noreturn
*/
native bool RP_GivePlayerBounty(int client);

/**
* Change client job.
*
* @param client			client index.
* @param job			job index.
* @noreturn
*/
native void RP_SetClientJob(int client, int job);

/**
* Called when a player dies and should drop coins.
*
* @param client			client index
*
* @return				Plugin_Continue to make him drop coins. Plugin_Handled or Plugin_Stop to prevent coin drop ( keeps pocket cash ).
*/
forward Action RP_ShouldClientDropCoins(int client);

/**
* Called when a player typed kill in console.
*
* @param client			client index
*
* @return				Plugin_Continue to allow suicide after 6 seconds. Plugin_Handled or Plugin_Stop to prevent suicide.
*/
forward Action RP_OnPlayerSuiciding(int client);

/**
* Is player suiciding
*
* @param client			client index
* @return		
*/

native bool RP_IsPlayerSuiciding(int client);

/**
* Stops player from suiciding
*
* @param client			client index
* @return		
*/
native void RP_StopPlayerSuiciding(int client);

/**
* Is player inside no kill zone
*
* @param client
* @return true if player is inside no kill zone, false otherwise

* @note			Always returns true if a player is in GM Mode.
*/

native bool IsClientNoKillZone(int client);

/**
* Is player GM with super ears mode enabled.
*
* @param client
* @return true if player is a GM with super ears enabled, false otherwise

*/

native bool IsClientSuperEars(int client);

/**
* Is player inside admins rooms
*
* @param client
* @return true if player is inside one of the admin rooms, false otherwise
*/

native bool IsPlayerInAdminRoom(int client);

/**
* Get the admin room the player is in.
*
* @param client
* @return admin room player is inside, from 0 to n. Returns -1 if player is not in admin room.
*/

native bool GetPlayerAdminRoom(int client);

/**
* Get's the client's call slot, or -1 if not in a call.
*
* @param client
* @return client's call slot, or -1 if not in a call.
*
* @note If RP_IsClientInRP returns false, this will return -1 automatically.
*/

native int RP_GetClientCallSlot(int client);

/**
* Is player inside a duel
*
* @param client
* @return true if player is inside no kill zone, false otherwise
*/

native bool RP_IsUserInDuel(int client);

/**
* Is player inside the arena ( !ja )
*
* @param client
* @return true if player is in the arena, false otherwise
*/

native bool RP_IsUserInArena(int client);

/**
* Is player inside an event ( !je )
*
* @param client
* @return true if player is in an event, false otherwise
*/

native bool RP_IsUserInEvent(int client);

/**
* Is player inside the normal roleplay
*
* @param client
* @return true if player is actually able to RP, false otherwise.

* @notes	Returns true if client is in Arena, Duel, Admin Room, doesn't return true for No Kill Zone.
*/
stock bool RP_IsClientInRP(int client)
{
	return !RP_IsUserInArena(client) && !RP_IsUserInDuel(client) && !IsPlayerInAdminRoom(client) && !AFKM_IsClientAFK(client) && !RP_IsUserInEvent(client);
}

/**
* Checks if two clients are from the same gang
* 
* @param client				client index.
* @param otherClient		other client index.
*
* @return 					true if clients are from the same gang, false otherwise.
*
*
* @notes					If client == otherClient, returns true if client has a gang, false otherwise. This means the native becomes IsClientInGang()
*/

native int Are_Users_Same_Gang(int client, int otherClient);

/**
* Returns unique gang index
* 
* @param client				client index.

* @return 					unique gang index
*/

native int Get_User_Gang(int client);

/**
* Returns client's gang tax in percents ( 0 to 100 )
* 
* @param client				client index.

* @return 					Tax which members have to pay to the gang per cash gain.
*/
native int Get_User_Gang_Tax(int client);

/**
* Returns gang status of client.
* 
* @param client				client index.

* @return 					gang status of client, by the RANK_* defines
*/

native int Is_User_Gang(int client);

/**
* Returns amount of cash in client's gang bank.
* 
* @param gangIndex			gang unique index.

* @return 					cash in gang bank
*/

native int Get_User_GangBank(int gangIndex);

/**
* Sets amount of cash in client's gang bank.
* 
* @param gangIndex			gang unique index.
* @param amount				amount of cash.

* @noreturn
*/

native void Set_User_GangBank(int gangIndex, int amount);

/**
* Increases amount of cash in client's gang bank without touching the client's total donations towards the gang
* 
* @param gangIndex			gang unique index.
* @param amount				amount of cash.

* @noreturn
*/

native void Add_User_GangBank(int gangIndex, int amount);

/**
* Increases amount of cash in client's gang bank without touching the client's total donations towards the gang
* 
* @param GangTag			Tag of the gang to add cash
* @param amount				amount of cash.

* @noreturn
*/
native void Add_GangBank(const String:GangTag[], int amount);

/**
* Increases amount of cash the client was known to donate towards the gang without touching the amount of money inside the gang's bank
* 
* @param gangIndex			gang unique index.
* @param amount				amount of cash.

* @noreturn
*/

native void Add_User_Gang_Donations(int gangIndex, int amount);

/**
* Gets a gang's tag by client index
* 
* @param client				client index
* @param g_Tag				buffer to put the tag in
* @param len				length of the buffer

* @noreturn
*/

native void Get_User_Gang_Tag(int client, char[] g_Tag, len);
/**
* Gets a gang's name by client index
* 
* @param client				client index
* @param g_Name				buffer to put the name in
* @param len				length of the buffer

* @noreturn
*/

native void Get_User_Gang_Name(int client, char[] g_Name, len);

/**
* Checks if given client has access to manage the gang's door ( buy or sell )
* 
* @param client				client index to test gang access

* @return					true if client has access to manage the gang's door. False otherwise.
*/

native bool Is_User_Manage_Gang_Door(int client);

/**
* Checks if given client has access to give keys to the gang's door
* 
* @param client				client index to test gang access

* @return					true if client has access to give keys to the gang's door. False otherwise.
*/

native bool Is_User_Gang_Give_Keys(int client);

/**
* Gets client's luck bonus percents as defined by his gang's luck perk( example: 2, 4, 6, 8, 10 percents... )
* 
* @param client				client index

* @return					luck bonus as percents, or 0 if not in a gang.
*/
native int Get_User_Luck_Bonus(int client);

/**
* Returns whether or not a player is banned from CT.
* 
* @param client				client index.
* @return					True if CT Banned, false otherwise.
*/
native bool IsPlayerBannedFromCT(int client);

/**
* Returns unix timestamp for when the player's CT ban will expire
* 
* @param client				client index.
* @return					Unix timestamp
*/
native int GetPlayerBanCTUnix(int client);

/**
* Returns client's time played in minutes
* 
* @param client				client index.
* @return					Minutes played in the game
*/
native int GetTimePlayed(int client);

/**
* Returns whether or a player is frozen by a cop.
* 
* @param client				client index.
* @return					true if player is cuffed, false otherwise
*/
native bool RP_IsClientCuffed(int client);

/**
* Makes a blank attempt to remove a freeze by a cop. Used by duels and arena when they start.
* 
* @param client				client index.
* @noreturn
*/
native void RP_TryUncuffClient(int client);

/**
* Gets the amount of minutes a player needs in general to become police. 
*
* @return					Time it takes for any player to become police.
*/
native int RP_GetMinutesToBecomePolice();

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
			

		char steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
			PrintToChat(i, buffer);
	}
}


stock PrintToChatEyalDelay(const String:format[], any:...)
{
	static ExtraTime;
	
	ExtraTime += 0.1;
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);

	new Handle:DP = INVALID_HANDLE;
	

	CreateDataTimer(0.1 + ExtraTime, _include_Timer_PrintToChatEyalDelay, DP, TIMER_FLAG_NO_MAPCHANGE);
	
	WritePackString(DP, buffer);
}

public Action:_include_Timer_PrintToChatEyalDelay(Handle:hTimer, Handle:DP)
{
	ResetPack(DP);
	
	new String:buffer[291];
	
	ReadPackString(DP, buffer, sizeof(buffer));
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;

		char steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
		{
			PrintToChat(i, buffer);
		}
	}
}

stock PrintToConsoleEyal(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			

		char steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
			PrintToConsole(i, buffer);
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
stock bool IsWeekend()
{
	char szDay[MAX_NAME_LENGTH];
	FormatTime(szDay, sizeof(szDay), "%A");
	
	if(StrEqual(szDay, "Friday") || StrEqual(szDay, "Saturday"))
		return true;
		
	return false;
}


stock void RolePlayLog(char[] log, any...)
{
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), log, 2);

	static char logPath[PLATFORM_MAX_PATH];
	
	if(strlen(logPath) < 1)
	{
		FormatTime(logPath, sizeof(logPath), "%Y%m%d", GetTime());
		BuildPath(Path_SM, logPath, sizeof(logPath), "logs/RolePlay_%s.log", logPath);
	}
	
	LogToFileEx(logPath, buffer);
}


stock void RolePlayAdminLog(char[] log, any...)
{
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), log, 2);

	static char logPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/RolePlayAdmin.log");
	
	LogToFileEx(logPath, buffer);
}

stock float CheckDistance(int entity1, int entity2)
{
	if(IsValidEdict(entity1) && IsValidEdict(entity2))
	{
		float origin1[3];
		GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", origin1);
	
		float origin2[3];
		GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", origin2);
	
		return GetVectorDistance(origin1, origin2);
	}
	
	else return 99999.0;
}
stock LoadDirOfModels(String:dirofmodels[])
{
	new String:path[256];
	new FileType:type;
	new String:FileAfter[256];
	new Handle:dir = OpenDirectory(dirofmodels, false, "GAME");
	if (!dir)
	{
		return;
	}
	while (ReadDirEntry(dir, path, 256, type))
	{
		if (type == FileType:2)
		{
			FormatEx(FileAfter, 256, "%s/%s", dirofmodels, path);
			AddFileToDownloadsTable(FileAfter);
		}
	}
	CloseHandle(dir);
	dir = INVALID_HANDLE;
	return;
}

stock void RemoveAllWeapons(int client, Handle NoRemoveList = null)
{
	new size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(size == 0)
		return;
		
	for(new i=0;i < size;i++)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(weapon == -1)
			continue;
		
		new String:Classname[64];
		GetEdictClassname(weapon, Classname, sizeof(Classname));
		
		new bool:shouldRemove = true;
		
		if(NoRemoveList != null)
		{
			for(new a=0;a < GetArraySize(NoRemoveList);a++)
			{
				new String:ListClassname[64];
				GetArrayString(NoRemoveList, a, ListClassname, sizeof(ListClassname));
				
				if(StrEqual(Classname, ListClassname))
				{
					shouldRemove = false;
				}
			}
		}
		if(shouldRemove)
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
}

stock bool IsWeaponUSP(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 61;
}

stock bool IsWeaponMP5(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 23;
}

stock void SetClientArmor(int client, int amount)
{		
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
}

stock void SetClientHelmet(int client, bool helmet)
{
	SetEntProp(client, Prop_Send, "m_bHasHelmet", helmet);
}

stock int RP_GetClientTotalLevels(int client)
{
	int job = 0;
	
	int TotalLevels = 0;
	
	char dummy_value[1];
	while(RP_GetJobName(job, dummy_value, sizeof(dummy_value)))
	{
		TotalLevels += RP_GetClientLevel(client, job);
		
		job++;
	}
	
	return TotalLevels;
}
/*

PlayIL:

0 to 1: 500
1 to 2: 1500
2 to 3: 3000
3 to 4: 5000
4 to 5: 7500

WePlay:

0 to 1: 750
1 to 2: 4250
2 to 3: 15000
3 to 4: 30000
4 to 5: 100000

@notes WePlay's new exp system never resets your exp when you level up.
@notes This chart evaluates the exp differences as if it actually resets your exp every level.
*/

stock CalculateEXPForNextLevel(currentLevel)
{
		/*
	switch(currentLevel)
	{
		case 0: return 750;
		case 1: return 5000;
		case 2: return 21500;
		case 3: return 61500;
		case 4: return 161500;
		
		default: return 1000000;
	}
	*/
	
	switch(currentLevel)
	{
		case 0: return 500;
		case 1: return 1500;
		case 2: return 3000;
		case 3: return 5000;
		case 4: return 10000;
		case 5: return 20000;
		case 6: return 35000;
		case 7: return 50000;
		case 8: return 75000;
		case 9: return 100000;
		
		default: return 1000000;
	}
}

stock CalculateBankForNextLevel(currentLevel)
{
	/*
	switch(currentLevel)
	{
		case 0: return 50000;
		case 1: return 150000;
		case 2: return 200000;
		case 3: return 250000;
		case 4: return 500000;
		default: return 1000000;
	}
	*/
	
	switch(currentLevel)
	{
		case 0: return 25000;
		case 1: return 50000;
		case 2: return 75000;
		case 3: return 100000;
		case 4: return 150000;
		case 5: return 200000;
		case 6: return 300000;
		case 7: return 400000;
		case 8: return 500000;
		case 9: return 750000;
		default: return 1000000;
	}
}


stock bool IsClientRevolverPref(int client)
{	
	Handle hCookie = FindClientCookie("RP_RevolverPref");
	
	if(hCookie == INVALID_HANDLE)
		return false;
		
	char strRevolverPref[11];
	GetClientCookie(client, hCookie, strRevolverPref, sizeof(strRevolverPref));
	
	if(strRevolverPref[0] == EOS)
		return false;
	
	return view_as<bool>(StringToInt(strRevolverPref));
}

stock RP_GivePlayerItem(client, const String:Classname[])
{
	_RP_RemoveWeaponByClassname(client, Classname);
	
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, client);
	WritePackString(DP, Classname);
	
	RequestFrame(_RP_Frame_GivePlayerItem, DP);
}

public _RP_Frame_GivePlayerItem(Handle:DP)
{
	ResetPack(DP);
	
	new client = ReadPackCell(DP);
	
	new String:Classname[64];
	
	ReadPackString(DP, Classname, sizeof(Classname));
	
	CloseHandle(DP);
	
	if(!IsClientInGame(client)) // In a single frame a client index can be invalidated, never replaced.
		return;
	
	
	if(StrEqual(Classname, "weapon_deagle") && IsClientRevolverPref(client))
		GivePlayerItem(client, "weapon_revolver");
	
	else
		GivePlayerItem(client, Classname);
}

stock _RP_RemoveWeaponByClassname(client, const String:Classname[])
{
	new size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(size == 0)
		return;
		
	for(new i=0;i < size;i++)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(weapon == -1)
			continue;
		
		new String:iClassname[64];
		GetEdictClassname(weapon, iClassname, sizeof(iClassname));
		
		
		if(StrEqual(Classname, iClassname))
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
}


stock FindEntityByTargetname(startEnt, const String:TargetName[], bool:caseSensitive, bool:Contains) // Same as FindEntityByClassname with sensitivity and contain features
{
	new entCount = GetEntityCount();
	
	new String:EntTargetName[64];
	
	for(new i=startEnt+1;i < entCount;i++)
	{
		if(!IsValidEntity(i))
			continue;
		
		else if(!IsValidEdict(i))
			continue;
		
		GetEntPropString(i, Prop_Data, "m_iName", EntTargetName, sizeof(EntTargetName));
		
		if((StrEqual(EntTargetName, TargetName, caseSensitive) && !Contains) || (StrContains(EntTargetName, TargetName, caseSensitive) != -1 && Contains))
			return i;
	}
	
	return -1;
} 

stock int GetPlayerCount(Team=-1)
{
	int count;
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) == Team)
			count++;
			
		else if(Team == -1 && ( GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT ))
			count++;
	}
	
	return count;
}

stock bool IsPlayer(entity)
{
	if(entity < 1)
		return false;
		
	else if(entity > MaxClients)
		return false;
		
	return true;
}

/**
* returns true if either:
*							1. client1 is a hitman with a job on client2
*							2. client2 is a hitman with a job on client1
*
* @param client				client index.

* @return					true if client is high management, false otherwise.
*/
stock bool AreClientsHitmanRelated(int client1, int client2)
{
	return RP_GetClientHitmanVictim(client1) == client2 || RP_GetClientHitmanVictim(client2) == client1;
}

stock void StringToVector(const char[] input, float buffer[3])
{
	char format[64];
	FormatEx(format, sizeof(format), input);
	
	ReplaceString(format, sizeof(format), ",", " ");
	
	ReplaceString(format, sizeof(format), "  ", " "); // This in total turns ", " into " "
	
	char xyz[3][11];
	ExplodeString(format, " ", xyz, sizeof(xyz), sizeof(xyz[]), false);
	
	buffer[0] = StringToFloat(xyz[0]);
	buffer[1] = StringToFloat(xyz[1]);
	buffer[2] = StringToFloat(xyz[2]);
}

stock bool IsEmptyVector(const float Vector[3])
{
	return Vector[0] == 0.0 && Vector[1] == 0.0 && Vector[2] == 0.0;
}

stock SetEntityMaxHealth(client, amount)
{
	SetEntProp(client, Prop_Data, "m_iMaxHealth", amount);
}

stock GetEntityMaxHealth(client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

stock void StringToRGB(const char[] input, int buffer[3])
{
	char format[16];
	FormatEx(format, sizeof(format), input);
	
	ReplaceString(format, sizeof(format), ",", " ");
	
	ReplaceString(format, sizeof(format), "  ", " ");
	
	char xyz[3][4];
	ExplodeString(format, " ", xyz, sizeof(xyz), sizeof(xyz[]), false);
	
	buffer[0] = StringToInt(xyz[0]);
	buffer[1] = StringToInt(xyz[1]);
	buffer[2] = StringToInt(xyz[2]);
}

#if !defined _updater_included
/**
 * @brief Reloads a plugin.
 *
 * @param plugin	Plugin Handle (INVALID_HANDLE uses the calling plugin).
 * @noreturn
 */
stock ReloadPlugin(Handle:plugin=INVALID_HANDLE)
{
	decl String:filename[64];
	GetPluginFilename(plugin, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}
#endif


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
	FormatEx(Path, sizeof(Path), "scripts/sound_never_prefetch.txt"); // LMAOOOO. Total bullshit file name
	
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