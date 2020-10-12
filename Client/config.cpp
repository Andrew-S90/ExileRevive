class CfgNetworkMessages
{
	class ReviveRequest
	{
		module = "system_revive";
		parameters[] = {"STRING"};
	};
};	

//**********


			class Revive: ExileAbstractAction
			{
				title = "Revive Player";
				condition = "player distance ExileClientInteractionObject < 3 and !(alive ExileClientInteractionObject) and (magazines player find 'Exile_Item_Defibrillator' >= 0)";
				action = "['ReviveRequest', [netId ExileClientInteractionObject]] call ExileClient_system_network_send;";
			};