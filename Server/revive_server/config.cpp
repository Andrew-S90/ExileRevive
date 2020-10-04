class CfgPatches
{
	class revive_server
	{
		requiredVersion = 0.1;
		requiredAddons[] = {"exile_server_config"};
		units[] = {};
		weapons[] = {};
		magazines[] = {};
		ammo[] = {};
	};
};
class CfgFunctions
{
	class revive_server
	{
		class Bootstrap
		{
			file = "revive_server\bootstrap";
			class preInit
			{
				preInit = 1;
			};
			class postInit
			{
				postInit = 1;
			};
		};
	};
};