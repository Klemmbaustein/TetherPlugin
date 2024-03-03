global function TetherInstallerInit
global function TetherShowLoadDialog

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

void function TetherInstallerUpdate()
{
	if (TetherCheckReloadMods())
	{
		ReloadModsDialog(!InLobby())
		if (InLobby())
		{
			SetConVarBool("reload_map", true)
		}
		ReloadMods()
	}

	string ConnectTarget = TetherCheckConnectServer()

	if (ConnectTarget != "")
	{
		TetherConnectToServer(ConnectTarget)
	}
}

void function TetherInstallerThread()
{
	if (GetConVarBool("reload_map"))
	{
		WaitFrame()
		ReloadModsDialog(!InLobby())
		ClientCommand("map " + uiGlobal.loadedLevel)
		SetConVarBool("reload_map", false)
	}

	while (true)
	{
		TetherInstallerUpdate()
		WaitFrame()
	}
}

void function TetherInstallerInit()
{
	LaunchTether();

	thread TetherInstallerThread()
}