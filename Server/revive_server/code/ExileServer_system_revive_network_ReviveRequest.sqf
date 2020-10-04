private ["_sessionID", "_parameters", "_targetID", "_playerUID", "_revive", "_timeofLastRevive", "_direction", "_newUnit", "_ExileScore", "_ExileKills", "_ExileDeaths", "_clanID", "_ExileLocker", "_clanData", "_ExileIsBambi", "_ExileSessionID", "_weaponsItemsCargo", "_bambitimer", "_layer"];

_sessionID = _this select 0;
_parameters = _this select 1;

_target = objectFromnetId (_parameters select 0);

if(isNull _target)exitWith{};

_targetID = owner _target;
if(_targetID < 3)exitWith{};

_playerUID = getPlayerUID _target;
if(_playerUID isEqualTo '')exitWith{};

_revive = _target getVariable ['revive',-1];
if!(_revive isEqualTo -1)exitWith{};

_timeofLastRevive = missionNamespace getVariable [format ["%1:REVIVE", getPlayerUID _target], 0];
if(_timeofLastRevive > 0 and _timeofLastRevive + 300 > time) exitWith 
{
	[_sessionID, "toastRequest", ["ErrorTitleAndText", ["Revive", format ["You must wait %1 seconds before reviving this person!", (_timeofLastRevive + 300) - time]]]] call ExileServer_system_network_send_to;
};
missionNamespace setVariable [format ["%1:REVIVE", getPlayerUID _target], time];
_target setVariable ['revive','1'];

_pos = _target modelToWorld [0,0,0];
_direction = getDir _target;
_name = name _target

_newUnit = (createGroup independent) createUnit ['Exile_Unit_Player', [0,0,0], [], 0, 'CAN_COLLIDE'];
removeHeadgear _newUnit;

_ExileScore = _target getVariable ['ExileScore',0];
_ExileKills = _target getVariable ['ExileKills',0];
_ExileDeaths = _target getVariable ['ExileDeaths',0];
_clanID = _target getVariable ['ExileClanID',-1];
_ExileLocker = _target getVariable ['ExileLocker',0];
_clanData = _target getVariable ['ExileClanData',[]];
_ExileIsBambi = _target getVariable ['ExileIsBambi',false];
_ExileSessionID = _target getVariable ['ExileSessionID', -1];

_newUnit disableAI 'FSM';
_newUnit disableAI 'MOVE';
_newUnit disableAI 'AUTOTARGET';
_newUnit disableAI 'TARGET';
_newUnit disableAI 'CHECKVISIBLE';
_newUnit setName _name;
_newUnit setVariable ['ExileMoney', _target getVariable "ExileMoney", true]; 
_newUnit setVariable ['ExileScore', _ExileScore];
_newUnit setVariable ['ExileKills', _ExileKills];
_newUnit setVariable ['ExileDeaths', _ExileDeaths];
_newUnit setVariable ['ExileClanID', _clanID];
_newUnit setVariable ['ExileClanData', _clanData];
_newUnit setVariable ['ExileHunger', 100];
_newUnit setVariable ['ExileThirst', 100];
_newUnit setVariable ['ExileTemperature', 37];
_newUnit setVariable ['ExileWetness', 0];
_newUnit setVariable ['ExileAlcohol', 0]; 
_newUnit setVariable ['ExileName', _name]; 
_newUnit setVariable ['ExileOwnerUID', _playerUID]; 
_newUnit setVariable ['ExileIsBambi', _ExileIsBambi];
_newUnit setVariable ['ExileXM8IsOnline', false, true];
_newUnit setVariable ['ExileLocker', _ExileLocker, true];
_newUnit setVariable ['ExileSessionID', _ExileSessionID, true];
missionNamespace setVariable [format['ExileSessionPlayerObject%1', _ExileSessionID], _newUnit];
_newUnit addMPEventHandler ['MPKilled', {_this call ExileServer_object_player_event_onMpKilled}];
_newUnit call ExileServer_object_player_database_insert;

_newUnit setUnitLoadout (getUnitLoadout _target);

{
	_weaponsItemsCargo = (weaponsItemsCargo _x) select 0;
	{
		if(_x isEqualType '')then
		{
			_newUnit addweapon _x;
			_newUnit addPrimaryWeaponItem _x;
		}
		else
		{
			_newUnit addMagazine _x;
		};
	} forEach _weaponsItemsCargo;
	
	deleteVehicle _x;
} forEach ((getPosATLVisual _target) nearEntities ["weaponholdersimulated", 5]);

[
	[
		_newUnit,
		str _ExileScore,
		_ExileKills,
		_ExileDeaths,
		(getNumber (configFile >> 'CfgSettings' >> 'BambiSettings' >> 'protectionDuration')) * 60, 
		_clanData,
		_ExileIsBambi,
		_target,
		_newUnit
	],
	{
		params ['_newUnit','_ExileScore','_ExileKills','_ExileDeaths','_bambitimer','_clanData','_ExileIsBambi','_target','_newUnit'];
		_newUnit call ExileClient_object_player_initialize;
		ExileClientPlayerIsSpawned = true;
		ExileClientPlayerAttributesASecondAgo = 
		[
			ExileClientPlayerAttributes select 0,
			ExileClientPlayerAttributes select 1,
			ExileClientPlayerAttributes select 2,
			ExileClientPlayerAttributes select 3,
			ExileClientPlayerAttributes select 4,
			ExileClientPlayerAttributes select 5,
			ExileClientPlayerAttributes select 6
		];
		call ExileClient_object_player_initStamina;
		call ExileClient_system_rating_balance;
		false call ExileClient_gui_hud_showSurvivalInfo;
		ExileClientPlayerScore = parseNumber _ExileScore;
		ExileClientPlayerKills = _ExileKills;
		ExileClientPlayerDeaths = _ExileDeaths;

		_clanData call ExileClient_system_clan_network_updateClanInfoFull;
		if(count _clanData >= 6)then
		{
			if!(isNull (_clanData select 5))then
			{
				ExileClientPartyID = netid (_clanData select 5);
			};
		};
		if(isNil'ExileClientPartyID')then{ExileClientPartyID = -1;};
		if!(ExileClientPartyID isEqualTo -1)then
		{
			[player] joinSilent (groupFromNetId ExileClientPartyID);
		};

		if!(isNull ExileClientLastDiedPlayerObject)then
		{	
			[ExileClientLastDiedPlayerObject] joinSilent (createGroup independent);
		};
		if(_ExileIsBambi)then
		{
			[ExileClientEndBambiStateThread] call ExileClient_system_thread_removeTask;
			ExileClientPlayerBambiStateExpiresAt = time + _bambitimer; 
			true call ExileClient_gui_hud_toggleBambiIcon;
			ExileClientEndBambiStateThread = [_bambitimer, ExileClient_object_player_bambiStateEnd, [], true] call ExileClient_system_thread_addTask;
		};
		_layer = 'BIS_fnc_respawnCounter' call bis_fnc_rscLayer;
		_layer cutText ['', 'plain'];
		RscRespawnCounter_Custom = 0;
		if!(ExileClientBleedOutThread isEqualTo -1)then
		{
			[ExileClientBleedOutThread] call ExileClient_system_thread_removeTask;
			ExileClientBleedOutThread = -1;
		};
		cutText['', 'BLACK IN',3];
		titleText['', 'BLACK IN',3];
		true call ExileClient_gui_hud_toggle;
		ExileClientLoadedIn = true;
		showChat true;
		setGroupIconsVisible [true, true];
		if(userInputDisabled)then{disableUserInput false;};
		
		if(!isNull _target)then{ deleteVehicle _target; };
	}
] remoteExecCall ['call',_targetID,false];

_newUnit setPos _pos;
_newUnit setDir _direction;
_newUnit call ExileServer_object_player_database_update;
deleteVehicle _target;