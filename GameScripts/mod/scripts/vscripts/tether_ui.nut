global function TetherInstallerInit
global function TetherShowLoadDialog
global function TetherLaunchCmd

void function TetherLaunchCmd()
{
	print("Launching tether from console command...")
	LaunchTether()
}

void function TetherShowLoadDialog(string Title, string Description)
{
	CloseAllDialogs()
	DialogData dialogData
	dialogData.showSpinner = true
	dialogData.header = Title
	dialogData.message = Description

	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )

	OpenDialog( dialogData )

	print( "Displaying loading dialog: " + Title )
}

void function ReloadModsDialog(bool mightRequireReload)
{
	string message = "Reloading mods...\n"

	if (mightRequireReload)
	{
		message += "Some mods might only fully reload when re-joining the game";
	}
	TetherShowLoadDialog("Reloading", message)
}

bool function InLobby()
{
	return uiGlobal.loadedLevel == "mp_lobby"
}

bool function TetherInstallerUpdate()
{
	if (TetherCheckReloadMods())
	{
		ReloadModsDialog(!InLobby())
		if (InLobby())
		{
			SetConVarBool("tether_reload_map", true)
		}
		if (uiGlobal.loadedLevel == "")
		{
			ReloadMods()
		}
		else
		{
			ClientCommand("reload_mods")
		}
		WaitFrame()
		TetherInstallerInit()
		CloseAllDialogs()
		return false
	}

	string ConnectTarget = TetherCheckConnectServer()

	if (ConnectTarget != "")
	{
		TetherConnectToServer(ConnectTarget)
	}
	return true
}

void function TetherInstallerThread()
{
	if (GetConVarBool("tether_reload_map"))
	{
		ReloadModsDialog(!InLobby())
		ClientCommand("map " + uiGlobal.loadedLevel)
		SetConVarBool("tether_reload_map", false)
	}

	while (TetherInstallerUpdate())
	{
		wait 10
	}
}

void function TetherInstallerModSettings()
{
	ModSettings_AddModTitle("Tether integration")
	ModSettings_AddModCategory("#GENERAL")
	ModSettings_AddButton("Open Tether", LaunchTether)
	ModSettings_AddEnumSetting("tether_launch_on_startup", "Open on startup", ["No", "Yes"])
}

void function TetherInstallerInit()
{
	TetherInstallerModSettings()
	if (GetConVarBool("tether_launch_on_startup"))
	{
		LaunchTether()
	}
	thread TetherInstallerThread()
}