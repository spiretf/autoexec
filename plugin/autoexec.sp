#pragma semicolon 1
#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "autoexec",
	author = "Icewind",
	description = "Automatically execute the right config for a map",
	version = "0.2",
	url = "https://spire.tf"
};

new StringMap:mapPrefixMap;
new StringMap:mapOverwriteMap;
new StringMap:mapTypeMap;
new StringMap:gameModeMap;
new StringMap:configOverwriteMap;

new Handle:CvarLeague = INVALID_HANDLE;
new Handle:CvarMode = INVALID_HANDLE;

public OnPluginStart() {
	mapPrefixMap = new StringMap();
	mapOverwriteMap = new StringMap();
	mapTypeMap = new StringMap();
	gameModeMap = new StringMap();
	configOverwriteMap = new StringMap();

	CvarLeague = CreateConVar("sm_autoexec_league", "ugc", "league to execute the configs for (ugc or etf2l)", FCVAR_PROTECTED);
	CvarMode = CreateConVar("sm_autoexec_mode", "9v9", "gamemode to execute the config for (9v9, 6v6 or 4v4)", FCVAR_PROTECTED);

	RegServerCmd("sm_autoexec", AutoExec, "Execute the config for the current map and select league and gamemode");
	RegServerCmd("sm_getexec", GetExec, "Get the name of the config for a specific map");
	
	mapTypeMap.SetString("5cp", "standard");
	
	mapPrefixMap.SetString("pl_", "stopwatch");
	mapPrefixMap.SetString("cp_", "5cp");
	mapPrefixMap.SetString("koth_", "koth");
	mapPrefixMap.SetString("ctf_", "ctf");

	configOverwriteMap.SetString("ultiduo_", "etf2l_ultiduo");
	configOverwriteMap.SetString("bball_", "etf2l_bball");
	configOverwriteMap.SetString("ctf_bball", "etf2l_bball");
	
	mapOverwriteMap.SetString("cp_steel", "stopwatch");
	mapOverwriteMap.SetString("cp_gravelpit", "stopwatch");
	mapOverwriteMap.SetString("cp_hadal", "stopwatch");
	
	gameModeMap.SetString("9v9", "hl");
}

public OnMapStart() {
	decl String:config[128];
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	GetConfig(map, config);
	
	ExecCFG(config);
}

public Action:GetExec(args) {
	new String:map[128];
	GetCmdArg(1, map, sizeof(map));
	decl String:config[128];
	GetConfig(map, config);

	PrintToChatAll("Config: %s", config);
	return Plugin_Handled;
}

public Action:AutoExec(args) {
	decl String:config[128];
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	GetConfig(map, config);
	
	ExecCFG(config);
	return Plugin_Handled;
}

public PrefixSearch(StringMap:map, String:query[128], String:result[128]) {
	new StringMapSnapshot:keys = map.Snapshot();
	decl String:key[16];
	new length = keys.Length;
	bool found = false;
	for (new i = 0; i < length; i++) {
		keys.GetKey(i, key, sizeof(key));
		if (strncmp(key, query, strlen(key)) == 0) {
			found = true;
			map.GetString(key, result, sizeof(result));
			break;
		}
	}

	CloseHandle(keys);
	return found;
}

public GetConfig(String:map[128], String:config[128]) {
	decl String:mapType[128];
	decl String:league[8];
	decl String:gamemode[8];

	if (PrefixSearch(configOverwriteMap, map, config)) {
		return;
	}
	
	GetLeague(league);
	GetLeagueMapType(map, mapType, league);
	GetGameMode(gamemode, league);

	Format(config, sizeof(config), "%s_%s_%s", league, gamemode, mapType);
}

public GetLeague(String:league[8]) {
	GetConVarString(CvarLeague, league, sizeof(league));
}

public GetGameMode(String:leagueGamemode[8], String:league[8]) {
	decl String:gamemode[8];
	GetConVarString(CvarMode, gamemode, sizeof(gamemode));
	
	if (strncmp("ugc", league, strlen(league)) == 0) {
		if (gameModeMap.GetString(gamemode, leagueGamemode, sizeof(leagueGamemode))) {
			return;
		}
	}
	leagueGamemode = gamemode;
}

public GetLeagueMapType(String:map[128], String:leagueMapType[128], String:league[8]) {
	decl String:mapType[128];
	GetMapType(map, mapType);

	if (strncmp("ugc", league, strlen(league)) == 0) {
		if (mapTypeMap.GetString(mapType, leagueMapType, sizeof(leagueMapType))) {
			return;
		}
	}
	leagueMapType = mapType;
}

public GetMapType(String:map[128], String:mapType[128]) {
	if (PrefixSearch(mapOverwriteMap, map, mapType)) {
		return;
	}

	if (!PrefixSearch(mapPrefixMap, map, mapType)) {
		mapType = "5cp"; //fallback
	}
	return;
}

public ExecCFG(String:cfg[128]) {
	decl String:command[256];
	Format(command, sizeof(command), "exec %s", cfg);
	ServerCommand(command, sizeof(command));
}
