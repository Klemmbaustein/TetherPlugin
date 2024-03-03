global function TetherConnectToServer

void function TetherConnectToServer(string serverUid)
{
	thread TetherConnectToServerThread(serverUid)
}

void function TetherConnectToServerThread(string serverUid)
{
	float time = Time()

	while (3 > Time())
	{
		WaitFrame()
	}
	
	print("Received request to join server " + serverUid)

	TetherShowLoadDialog("#CONNECTING", "#DIALOG_AUTHENTICATING_MASTERSERVER");

	while ( GetConVarInt( "ns_has_agreed_to_send_token" ) != NS_AGREED_TO_SEND_TOKEN || time + 15.0 > Time() )
	{
		if ( ( NSIsMasterServerAuthenticated() && IsStryderAuthenticated() ) || GetConVarBool( "ns_auth_allow_insecure" ) )
			break
			
		WaitFrame()
	}

	connectToServer(serverUid)

}

void function connectToServer(string Uid)
{
	if (GetConVarInt("ns_has_agreed_to_send_token") != 1)
	{
		//DisplayErrorDialog("You haven't agreed to send your origin token. Please enable it in the mod menu and retry.")
		return
	}

	TetherShowLoadDialog("#CONNECTING", "Connecting to server...");

	NSRequestServerList()

	while ( NSIsRequestingServerList() )
	{
		print( "Waiting for NSIsRequestingServerList()" )
		WaitFrame() 
	}
	
	int TargetID
	
	bool FoundServer = false
	int i = 0
	ServerInfo server

	foreach ( s in NSGetGameServers() )
	{
		if (s.id == Uid)
		{
			TargetID = i
			server = s
			FoundServer = true
		}
		i++
	}

	if (!FoundServer)
	{
		print( "Could not find server with UUID " + Uid )
		return
	}

	foreach ( RequiredModInfo mod in server.requiredMods )
	{
		print(mod.name)
		if ( !NSGetModNames().contains( mod.name ) )
		{
			DialogData dialogData
			dialogData.header = "#ERROR"
			dialogData.message = format( "Missing mod \"%s\" v%s", mod.name, mod.version )
			dialogData.image = $"ui/menu/common/dialog_error"

			#if PC_PROG
				AddDialogButton( dialogData, "#DISMISS" )

				AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
			#endif // PC_PROG
			AddDialogFooter( dialogData, "#B_BUTTON_DISMISS_RUI" )

			OpenDialog( dialogData )

			return
		}
		else
		{
			// this uses semver https://semver.org
			array<string> serverModVersion = split( mod.name, "." )
			array<string> clientModVersion = split( NSGetModVersionByModName( mod.name ), "." )

			bool semverFail = false
			// if server has invalid semver don't bother checking
			if ( serverModVersion.len() == 3 )
			{
				// bad client semver
				if ( clientModVersion.len() != serverModVersion.len() )
					semverFail = true
				// major version, don't think we should need to check other versions
				else if ( clientModVersion[ 0 ] != serverModVersion[ 0 ] )
					semverFail = true
			}

			if ( semverFail )
			{
				DialogData dialogData
				dialogData.header = "#ERROR"
				dialogData.message = format( "Server has mod \"%s\" v%s while we have v%s", mod.name, mod.version, NSGetModVersionByModName( mod.name ) )
				dialogData.image = $"ui/menu/common/dialog_error"

				#if PC_PROG
					AddDialogButton( dialogData, "#DISMISS" )

					AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
				#endif // PC_PROG
				AddDialogFooter( dialogData, "#B_BUTTON_DISMISS_RUI" )

				OpenDialog( dialogData )

				return
			}
		}
	}

	NSTryAuthWithServer( TargetID, "" )

	while ( NSIsAuthenticatingWithServer() )
	{
		WaitFrame()
	}

	bool modsChanged = false

	if ( NSWasAuthSuccessful() )
	{
		foreach ( string modName in NSGetModNames() )
		{
			if ( NSIsModRequiredOnClient( modName ) && NSIsModEnabled( modName ) )
			{
				// find the mod name in the list of server required mods
				bool found = false
				foreach ( RequiredModInfo mod in server.requiredMods )
				{
					if (mod.name == modName)
					{
						found = true
						break
					}
				}
				// if we didnt find the mod name, disable the mod
				if (!found)
				{
					modsChanged = true
					NSSetModEnabled( modName, false )
				}
			}
		}

		// enable all RequiredOnClient mods that are required by the server and are currently disabled
		foreach ( RequiredModInfo mod in server.requiredMods )
		{
			if ( NSIsModRequiredOnClient( mod.name ) && !NSIsModEnabled( mod.name ))
			{
				modsChanged = true
				NSSetModEnabled( mod.name, true )
			}
		}

		// only actually reload if we need to since the uiscript reset on reload lags hard
		if ( modsChanged )
			ReloadMods()

		TriggerConnectToServerCallbacks( server )
		NSConnectToAuthedServer()
	}
	else
	{
		string reason = NSGetAuthFailReason()
		//DisplayErrorDialog(reason)
	}
}

bool function IsStryderAuthenticated()
{
	return GetConVarInt( "mp_allowed" ) != -1
}