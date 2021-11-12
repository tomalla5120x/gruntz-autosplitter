// 
// ASL script for Gruntz
//
// Author: Tomalla ( http://datashenanigans.pl )
// Script version: 1.1.0 (2021.11.11)
//
// The script operates in two modes which make the LiveSplit's Game Time be interpreted differently:
//  * in the "STATS TIME" timing method the LiveSplit's Game Time reflects the actual in-game timer from within the game.
//    It's the exact same time which will be visible on the stats page at the end of the level.
//  * in the "LOADLESS TIME" timing method the LiveSplit's Game Time reflects the loadless real time.
//    In practice the real time is paused only when the level is loading or saving.
//
// Changelog:
//
// 1.1.0 (2021.11.11)
//   * complete overhaul of the loadless timer logic
//   + added hash for Gruntz: v1.01 English NO-CD
//
// 1.0.0 (2021.10.21)
//   * initial commit
//

state("GRUNTZ")
{
	uint IsPausedFlag: 0x2464C4, 0xC;
	bool IsPressAnyKeyPrompt: 0x2464C4, 0x2c, 0x4F8;
	bool IsToolbarEnabled: 0x2464C4, 0x68, 0x400;
	string100 StateMangledName: 0x2464C4, 0x2C, 0x0, -4, 0xC, 0x8;

	int GameTime: 0x2464E0;
	int GameTimeStarted: 0x2464C4, 0x2C, 0x3F4, 0x38;
	int GameTimePaused: 0x2464C4, 0x2C, 0x1CC;
	int GameTimeStatsPage: 0x2464C4, 0x7C, 0x10; // final in-game time for viewing in the stats page, saved upon entering the fortress

	// CWinApp->m_nWaitCursorCount
	// used for detecting the saving and quicksaving routine
	int WaitCursorCount: 0x2461A0;

	bool IsLevelLoading: 0x2464C4, 0x2C, 0x484;

	// list of status messages at the top-left of the screen
	int StatusMessagesCount: 0x2464C4, 0x5C, 0xC;
	uint StatusMessagesHead: 0x2464C4, 0x5C, 0x4;
}

startup
{
	vars.ScriptVersion = "1.1.0";

	vars.GruntzDescription = "";
	vars.ComponentGameTime = null;
	vars.ComponentTimingMethod = null;
	vars.ComponentGruntz = null;

	vars.HashesGruntz = new Dictionary<string, string> {
		{"199d4613e4587e1d720623dc11569e4d", "v1.01 english"},
		{"a61c4d418440b28e7668fb3c2f4f6e09", "v1.01 english no-cd"}
	};

	// game states mangled RTTI names
	vars.StatePlay = ".?AVCPlay@@"; // playing the level (+ the loading screen)
	vars.StateBooty = ".?AVCBootyState@@"; // stats page
	vars.StateMenu = ".?AVCMenuState@@"; // main menu
	vars.StateHelp = ".?AVCHelpState@@"; // help menu screen

	// used for saving the game time when transitioning between states
	// like entering the help screen or transitioning to the next level
	vars.GameTimeSaved = null;

	// used for detecting the loading sequence
	vars.IsLoadingSequence = false;
	vars.LoadWatchGameTime = null;

	vars.TimingMethodLoadless = 0;
	vars.TimingMethodStats = 1;
	vars.TimingMethod = vars.TimingMethodLoadless;

	vars.IsDebugMessages = false;

	vars.ShowWarning = (Action<string>) delegate(string message) {
		MessageBox.Show(message, "LiveSplit | Gruntz", MessageBoxButtons.OK, MessageBoxIcon.Warning);
	};

	vars.ShowError = (Action<string>) delegate(string message) {
		MessageBox.Show(message, "LiveSplit | Gruntz", MessageBoxButtons.OK, MessageBoxIcon.Error);
	};

	vars.GetGameTime = (Func<dynamic, int>) delegate(dynamic state) {
		// if the the level has not yet started we show zero as the game time
		if( state.IsPressAnyKeyPrompt )
			return( 0 );

		// if the stats page time has already been established we use that instead
		if( state.GameTimeStatsPage > 0 )
			return(state.GameTimeStatsPage);
			
		// here's the breakdown of how the in-game timer actually works
		// GameTime is the global in-game timer which starts the moment the level finishes loading and starts "ticking"
		// GameTime ticks ALWAYS. The only exceptions are WinAPI windows opened like saving/loading form or settings
		// GameTimeStarted is the GameTime where the gameplay of the level actually started. It's when the player confirms the "Click any key to continue..." prompt and player's Gruntz begin teleporting in.
		// GameTimePaused is the GameTime at which the player explicitly pauses the game and the message "GAME PAUSED" shows up on the screen. As a reminder: the GameTime is still ticking
		// once the game is unpaused the GameTime value is overwritten with the value saved in GameTimePaused and thus "snaps back" into the correct value.
		// once the Warpstone Grunt enters the fortress, GameTimeStatsPage is initialized with the GameTime - GameTimeStarted value and that's the exact value that's shows on the stats page
		int time;

		// if we don't check for the pause flag the game timer would go on as usual
		// and snap back into saved time upon unpausing
		if( (state.IsPausedFlag & 0x1) == 1 )
			time = state.GameTimePaused;
		else
			time = state.GameTime;

		time -= state.GameTimeStarted;

		return( Math.Max(time, 0) );
	};

	vars.GetMD5Hash = (Func<string, string>) delegate(string filePath) {
		using (var md5 = System.Security.Cryptography.MD5.Create())
		using (var stream = File.OpenRead(filePath))
		{
			byte[] bytes = md5.ComputeHash(stream);
			StringBuilder stringBuilder = new StringBuilder();
			for (int i = 0; i < bytes.Length; i++)
				stringBuilder.Append(bytes[i].ToString("x2"));

			return( stringBuilder.ToString() );
		}
	};

	vars.RefreshComponents = (Action) delegate {
		vars.ComponentGameTime = null;
		vars.ComponentTimingMethod = null;
		vars.ComponentGruntz = null;

		foreach (dynamic component in timer.Layout.Components)
		{
			if( component.GetType().Name != "TextComponent" )
				continue;

			string caption = component.Settings.Text1.ToLower();

			if( caption == "game time:" )
				vars.ComponentGameTime = component;
			else if( caption == "timing method:" )
				vars.ComponentTimingMethod = component;
			else if( caption == "gruntz:" )
				vars.ComponentGruntz = component;
		}

		if( vars.ComponentGruntz != null )
			vars.ComponentGruntz.Settings.Text2 = vars.GruntzDescription;
	};

	// the settings instance in the startup action is of SettingsBuilder class instead of SettingsReader and as such does not allow for reading settings at this stage
	// that's why we extract the settings reading functionality using reflection
	Func<string, bool> querySetting = null;

	foreach(var field in settings.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance))
		if( field.FieldType.Name == "ASLSettings" )
		{
			object settingsInstance = field.GetValue(settings);
			MethodInfo methodInfo = field.FieldType.GetMethod("GetSettingValue");

			if(methodInfo != null)
			{
				querySetting = delegate(string key) {
					object result = methodInfo.Invoke(settingsInstance, new object[] {key});
					if( result != null && result is bool )
						return (bool)result;
					print("Error reading the setting: " + key + ". Value returned is: " + (result == null ? "null": result.ToString()));
					return false;
				};
			}

			break;
		}

	if( querySetting == null )
		vars.ShowError("Error retrieving the settings reader. Some functionalities of the AutoSplitter script may not work properly.\n\nIf you see this message, let me know know because that means that we have to fix the script.");

	// timer callbacks
    vars.OnStart = (EventHandler) delegate(object sender, EventArgs e) {
		if( querySetting != null )
		{
			// initializing the timing method
			if( querySetting("TimingMethodSync") )
				vars.TimingMethod = (timer.CurrentTimingMethod == TimingMethod.GameTime ? vars.TimingMethodStats : vars.TimingMethodLoadless);
			else
				vars.TimingMethod = (querySetting("TimingMethodLoadless") ? vars.TimingMethodLoadless : vars.TimingMethodStats);
			
			vars.RefreshComponents();

			if( vars.ComponentTimingMethod != null )
				vars.ComponentTimingMethod.Settings.Text2 = (vars.TimingMethod == vars.TimingMethodLoadless ? "Loadless Time" : "Stats Time");

			vars.IsDebugMessages = querySetting("DebugMessages");
		}
	};

	timer.OnStart += vars.OnStart;

	// settings
	settings.Add("ResetOnLoad", true, "Reset the timer on level start");
	settings.SetToolTip("ResetOnLoad", "If checked the timer will be automatically reset when the level is first loaded. Handy on individual level runs but has to be disabled with full game playthroughs in mind.");

	settings.Add("TimingMethodSync", false, "Set the timing method automatically according to the Current Timing Method");
	settings.SetToolTip("TimingMethodSync", "If the Current Timing Method in LiveSplit is set to Game Time the script timing method is set to Stats Time. If it is set to Real Time the Loadless Time timing method will be used instead.");

	settings.Add("TimingMethodLoadless", true, "Set the script timing method to Loadless");
	settings.SetToolTip("TimingMethodLoadless", "If checked the script timing method is set to Loadless Time. Otherwise it's Stats Time. Note: the option is ignored if the timing method is set automatically.");

	settings.Add("IgnoreVersion", false, "Ignore the game version & distribution check");
	settings.SetToolTip("IgnoreVersion", "If checked no warning messages will be issued if an unknown game version will be encountered.");

	settings.Add("DebugMessages", false, "Generate additional debug messages");
	settings.SetToolTip("DebugMessages", "Makes the script dump data about the current state of the game accessible via DebugView.");
}

shutdown
{
    timer.OnStart -= vars.OnStart;
}

init
{
	if( !settings["IgnoreVersion"] )
	{
		var moduleGruntz = modules.First();

		if( moduleGruntz == null )
		{
			vars.ShowWarning("Couldn't verify the game version.\nThe AutoSplitter script may not run properly.");
			print("[WARNING] Couldn't find the game module");
		} else
		{
			var versionInfo = moduleGruntz.FileVersionInfo;

			if( versionInfo.FileMajorPart != 1
				|| versionInfo.FileMinorPart != 0
				|| versionInfo.FileBuildPart != 1
				|| versionInfo.FilePrivatePart != 77 )
			{
				string currentVersion = versionInfo.FileMajorPart.ToString() + "." + versionInfo.FileMinorPart.ToString() + "." + versionInfo.FileBuildPart.ToString() + "." + versionInfo.FilePrivatePart.ToString();
				vars.ShowWarning("Expected game version 1.0.1.77, found: " + currentVersion + ".\nThe AutoSplitter script may not run properly.");
				print("[WARNING] Unknown Gruntz version: " + currentVersion);
			} else
			{
				// calculating the MD5 hash for the executable
				string hash = vars.GetMD5Hash(moduleGruntz.FileName);
					
				if( vars.HashesGruntz.ContainsKey(hash) )
				{
					vars.GruntzDescription = vars.HashesGruntz[hash];
					print("[INFO] Detected Gruntz release: " + vars.GruntzDescription + " (" + hash + ")");
				} else
				{
					vars.ShowWarning("The AutoSplitter script didn't recognize the version of your Gruntz executable. It is still very likely it will work, we just don't know about it yet.\n\n"
						+ "Please let us know about this executable and we will update the script with the new version of the game!");
					vars.GruntzDescription = "unknown";
					print("[WARNING] Unknown Gruntz MD5 hash: " + hash);
				}

				vars.RefreshComponents();
			}
		}
	}
}

update
{
	// the game time is still ticking when in the help/booty screen
	// that's why we save it for these states
	if(	old.StateMangledName == vars.StatePlay && (current.StateMangledName == vars.StateHelp || current.StateMangledName == vars.StateBooty) )
		vars.GameTimeSaved = vars.GetGameTime(old);
	else if( old.StateMangledName == vars.StateMenu && current.StateMangledName == vars.StateHelp )
	{
		// the help menu can be triggered from the main menu as well
		// we don't want any time to be shown there
		vars.GameTimeSaved = 0;
	}

	// analyzing the status messages in the top-left part of the screen
	// once the quickloading sequence is initiated by the player, the game adds the "Game Quickloaded successfully." string into the message stack
	List<string> statusMessages = new List<string>();

	if( !vars.IsLoadingSequence && current.StatusMessagesCount > 0 )
	{
		const int messageLengthMax = 100;
		const string pattern = "Game Quickloaded successfully.";

		statusMessages = new List<string>(current.StatusMessagesCount);

		for(IntPtr addressNode = (IntPtr)current.StatusMessagesHead; addressNode != (IntPtr)0x0; addressNode = (IntPtr)memory.ReadValue<uint>(addressNode))
		{
			IntPtr addressMessageStruct = (IntPtr)memory.ReadValue<uint>(addressNode + 0x8);
			IntPtr addressMessage = (IntPtr)memory.ReadValue<uint>(addressMessageStruct + 0x8);

			string message;
			bool isSuccess = memory.ReadString(addressMessage, ReadStringType.ASCII, messageLengthMax, out message);

			if( isSuccess && message == pattern )
			{
				vars.IsLoadingSequence = true;

				if( !vars.IsDebugMessages )
					break;
			}

			statusMessages.Add(message);
		}
	}

	// when the level is being loaded, the change of the IsLevelLoading memory field correlates with actually restoring the saved game time
	// after the game time is set we store it and watch for any changes
	// once the game time starts ticking it would signify the loading sequence is over
	if( old.IsLevelLoading && !current.IsLevelLoading )
	{
		vars.LoadWatchGameTime = current.GameTime;
	} else if( vars.LoadWatchGameTime != null && current.GameTime > vars.LoadWatchGameTime + 3 )
	{
		// during my tests I've found out that the game time might sometimes "flinch" by a millisecond even though the level would not finish loading
		// for that reason we wait additional 3ms
		// considering the update actions get called 60 times per second (once almost 17ms) and the fact the LiveSplit tracks time only to hundreds of ms it should be noticeable
		vars.LoadWatchGameTime = null;
		vars.IsLoadingSequence = false;
	}

	// debugging output in case something doesn't work
	if( vars.IsDebugMessages )
	{
		string logLine = "";

		object[] values = {
			vars.ScriptVersion,
			current.StateMangledName,
			current.IsPausedFlag,
			current.IsPressAnyKeyPrompt,
			current.IsLevelLoading,
			current.IsToolbarEnabled,
			current.GameTime,
			current.GameTimeStarted,
			current.GameTimeStatsPage,
			current.GameTimePaused,
			current.WaitCursorCount,
			current.StatusMessagesCount,
			"0x" + current.StatusMessagesHead.ToString("X8"),
			String.Join("|", statusMessages),
			vars.IsLoadingSequence,
			vars.LoadWatchGameTime,
			vars.GameTimeSaved
		};

		foreach(object obj in values)
		{
			logLine += ";";

			if( obj == null )
				logLine += "null";
			else if( obj is bool )
				logLine += ((bool)obj ? "true" : "false");
			else if( obj is string )
				logLine += obj;
			else
				logLine += Convert.ToString(obj);
		}

		print(logLine);
	}
}

reset
{
	return( settings["ResetOnLoad"] && current.StateMangledName == vars.StatePlay && current.IsPressAnyKeyPrompt );
}

start
{
	if( old.StateMangledName == vars.StatePlay
		&& current.StateMangledName == vars.StatePlay
		&& old.IsPressAnyKeyPrompt
		&& !current.IsPressAnyKeyPrompt )	
	{
		return( true );
	}
}

split
{
	if( old.StateMangledName == vars.StatePlay
		&& current.StateMangledName == vars.StatePlay
		&& old.IsToolbarEnabled
		&& !current.IsToolbarEnabled )
	{
		return( true );
	}
}

isLoading
{
	if( vars.TimingMethod == vars.TimingMethodStats )
	{
		// for the game time timing method we want to turn off the LiveSplit time approximation mechanisms to avoid fluctuating time
		// the LiveSplit's game time will be synced manually in the gameTime action anyways
		return( true );
	}

	if( current.StateMangledName != vars.StatePlay )
	{
		// we only take the CPlay state under consideration when looking for the loading sequence
		return( false );
	}

	// experimentally I've found that only saving and quicksaving uses the waiting cursor
	return( vars.IsLoadingSequence || (current.WaitCursorCount > 0) );
}

gameTime
{
	TimeSpan timeSpan;
	
	if( current.StateMangledName == vars.StateHelp || current.StateMangledName == vars.StateBooty)
	{
		// for help/booty states use the saved time instead
		if( vars.GameTimeSaved == null )
			timeSpan = TimeSpan.Zero;
		else
			timeSpan = TimeSpan.FromMilliseconds(vars.GameTimeSaved);
	} else if( current.StateMangledName != vars.StatePlay )
	{
		// in any other state there's no concept of game time so we show zero
		timeSpan = TimeSpan.Zero;
	} else
	{
		timeSpan = TimeSpan.FromMilliseconds(vars.GetGameTime(current));
	}

	if( vars.ComponentGameTime != null )
		vars.ComponentGameTime.Settings.Text2 = timeSpan.ToString(@"hh\:mm\:ss\.fff");

	if( vars.TimingMethod == vars.TimingMethodLoadless )
	{
		// for the loadless time timing method we want LiveSplit to sync the game time with the real timer
		// if we would return a TimeSpan object here, the isLoading action will never affect the LiveSplit's game time timer
		return( null );
	}

	return( timeSpan );
}