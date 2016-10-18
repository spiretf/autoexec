#pragma semicolon 1
#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "autoexec",
	author = "Icewind",
	description = "Automatically execute the right config for a map",
	version = "0.1",
	url = "https://spire.tf"
};

new StringMap:mapPrefixMap;
new StringMap:mapOverwriteMap;
new StringMap:mapTypeMap;
new StringMap:gameModeMap;

new Handle:CvarLeague = INVALID_HANDLE;
new Handle:CvarMode = INVALID_HANDLE;

public OnPluginStart() {
	mapPrefixMap = new StringMap();
	mapOverwriteMap = new StringMap();
	mapTypeMap = new StringMap();
	gameModeMap = new StringMap();

	CvarLeague = CreateConVar("sm_autoexec_league", "ugc", "league to execute the configs for (ugc or etf2l)", FCVAR_PROTECTED);
	CvarMode = CreateConVar("sm_autoexec_mode", "9v9", "gamemode to execute the config for (9v9, 6v6 or 4v4)", FCVAR_PROTECTED);

	RegServerCmd("sm_autoexec", AutoExec, "Execute the config for the current map and select league and gamemode");
	
	mapTypeMap.SetString("5cp", "standard");
	
	mapPrefixMap.SetString("pl_", "stopwatch");
	mapPrefixMap.SetString("cp_", "5cp");
	mapPrefixMap.SetString("kot", "koth");
	mapPrefixMap.SetString("ctf", "ctf");
	mapPrefixMap.SetString("ult", "ultiduo");
	
	mapOverwriteMap.SetString("cp_steel", "stopwatch");
	mapOverwriteMap.SetString("cp_gravelpit", "stopwatch");
	
	gameModeMap.SetString("9v9", "hl");
}

public OnMapStart() {
	decl String:config[128];
	GetConfig(config);
	
	ExecCFG(config);
}

public Action:AutoExec(args) {
	decl String:config[128];
	GetConfig(config);
	
	ExecCFG(config);
	return Plugin_Handled;
}

public GetConfig(String:config[128]) {
	decl String:mapType[32];
	decl String:league[8];
	decl String:gamemode[8];
	
	GetLeague(league);
	GetLeagueMapType(mapType, league);
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

public GetLeagueMapType(String:leagueMapType[32], String:league[8]) {
	decl String:mapType[32];
	GetMapType(mapType);

	if (strncmp("ugc", league, strlen(league)) == 0) {
		if (mapTypeMap.GetString(mapType, leagueMapType, sizeof(leagueMapType))) {
			return;
		}
	}
	leagueMapType = mapType;
}

public GetMapType(String:mapType[32]) {
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));

	if (mapOverwriteMap.GetString(map, mapType, sizeof(mapType))) {
		return;
	}
	
	decl String:prefix[4];
	strcopy(prefix, sizeof(prefix), map);
	
	if (mapPrefixMap.GetString(prefix, mapType, sizeof(mapType))) {
		return;
	}
	
	mapType = "5cp"; //fallback
	return;
}

public ExecCFG(String:cfg[128]) {
	decl String:command[256];
	Format(command, sizeof(command), "exec %s", cfg);
	ServerCommand(command, sizeof(command));
}
