#include <sourcemod>

#define PLUGIN_VERSION "0.0.0-dev"

public Plugin:myinfo =
{
	name = "No Round End",
	author = "Danyas",
	description = "Block round end for CS:S v34",
	version = PLUGIN_VERSION,
	url = "https://github.com/fmu1337/blockroundend_v34"
}

// CheckRoundTimeExpired и Windows-пролог CheckWinConditions — спасибо Reg1oxeN:
// https://hlmod.net/threads/no-round-end.68241/#post-657507
new Handle:hIg, Handle:hSv, bool:bSync, bool:bOn, Address:pAddr[2], iOrg[2][3], iLen[2] = {3, 1};
new iPat[2][3] = {{0x31, 0xC0, 0xC3}, {0xC3, 0, 0}};

public OnPluginStart()
{
	decl Handle:gd, i, n, String:k[2][24];
	HookConVarChange(hIg = CreateConVar("mp_ignore_round_win_conditions", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0), CV);
	HookConVarChange(hSv = CreateConVar("sv_noroundend", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0), CV);
	if ((gd = LoadGameConfigFile("noroundend.games")) == INVALID_HANDLE) SetFailState("noroundend: no gamedata");
	k[0] = "CheckWinConditions"; k[1] = "CheckRoundTimeExpired";
	for (n = 0; n < 2; n++)
	{
		if (!_:(pAddr[n] = GameConfGetAddress(gd, k[n]))) SetFailState("noroundend: no %s", k[n]);
		for (i = 0; i < iLen[n]; i++) iOrg[n][i] = LoadFromAddress(Address:(_:pAddr[n] + i), NumberType_Int8) & 0xFF;
	}
	CloseHandle(gd);
	Set(GetConVarBool(hIg) || GetConVarBool(hSv));
}

public OnConfigsExecuted()
{
	Set(GetConVarBool(hIg) || GetConVarBool(hSv));
}

public OnPluginEnd()
{
	Set(false);
}

public CV(Handle:c, const String:o[], const String:n[])
{
	if (!bSync) Set(GetConVarBool(c));
}

Set(bool:e)
{
	decl i, n;
	bSync = true; SetConVarBool(hIg, e); SetConVarBool(hSv, e); bSync = false;
	if (e == bOn) return;
	for (n = 0; n < 2; n++) for (i = 0; i < iLen[n]; i++) StoreToAddress(Address:(_:pAddr[n] + i), e ? iPat[n][i] : iOrg[n][i], NumberType_Int8);
	PrintToServer("[noroundend] %s", (bOn = e) ? "on" : "off");
}
