#include <sourcemod>

#define PLUGIN_VERSION "0.0.0-dev"

public Plugin:myinfo =
{
	name = "No Round End",
	author = "Danyas",
	description = "Block round end for CS:S v34",
	version = PLUGIN_VERSION,
	url = "https://github.com/fmu1337/blockroundend_v34_new"
}

new Handle:hIg, Handle:hSv, bool:bSync, bool:bOn, Address:pAddr, iOrg[3], iPat[3];

public OnPluginStart()
{
	decl Handle:gd, i, bool:w;
	HookConVarChange(hIg = CreateConVar("mp_ignore_round_win_conditions", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0), CV);
	HookConVarChange(hSv = CreateConVar("sv_noroundend", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0), CV);
	if ((gd = LoadGameConfigFile("noroundend.games")) == INVALID_HANDLE) SetFailState("noroundend: no gamedata");
	if (!_:(pAddr = GameConfGetAddress(gd, "CheckWinConditions"))) SetFailState("noroundend: no signature");
	CloseHandle(gd);
	w = FileExists("bin/server.dll");
	iPat[0] = w ? 0xC2 : 0xC3; iPat[1] = w ? 0x04 : 0; iPat[2] = 0;
	for (i = 0; i < 3; i++) iOrg[i] = LoadFromAddress(Address:(_:pAddr + i), NumberType_Int8) & 0xFF;
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
	decl i;
	bSync = true; SetConVarBool(hIg, e); SetConVarBool(hSv, e); bSync = false;
	if (e == bOn) return;
	for (i = 0; i < 3; i++) StoreToAddress(Address:(_:pAddr + i), e ? iPat[i] : iOrg[i], NumberType_Int8);
	PrintToServer("[noroundend] %s", (bOn = e) ? "on" : "off");
}
