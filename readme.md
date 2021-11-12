# Gruntz Auto Splitter

This is the ASL script for LiveSplit for the game Gruntz v1.01. Features:
* **timer automatically starts** when the player starts a new level, clicks through the "CLICK THE MOUSE BUTTON OR PRESS ANY KEY TO CONTINUE" message and player's Gruntz start teleporting in
* **timer automatically splits** when a Warpstone Grunt walks into the fort and the level ending sequence starts
* **timer automatically resets** when the player starts a new level
* **extraction of the in-game time** with a one millisecond precision
* **supports loadless time** - the timer pauses when saving, quicksaving and quickloading from within the level

## Quick installation

You can download LiveSplit at [https://livesplit.org/](https://livesplit.org/). I assume some basic knowledge on how LiveSplit works. Currently this script is not uploaded to the Auto Splitter database and as such you have to set it up manually as a part of the layout instead. In the future it should be available through through the splitting menu.

The description below is about setting up the layout to incorporate three timers at once: for the real time, real loadless time and in-game time. **You may as well just download the layout from the repository and use it as a reference**. Just remember to update the path to the ASL script in the script settings.

Setting up the layout from ground up:
1. Download the ASL script from this repository.
2. Edit the layout and add the "Control > Scriptable Auto Splitter" component.
3. Edit the settings of this component. Type in the correct path to the downloaded ASL script. Make sure options "Start", "Split" and "Reset" are all checked.
4. In the advanced settings section of the script make sure of the following options:
    * "Reset the timer on level start" should be **checked**
    * "Set the timer method according to the Current Timing Method" should be **unchecked**
    * "Set the script timing method to Loadless" should be **checked**
5. Add "Information > Text" component to the layout. Make sure you set its left text to: **"Game time:"** without quotation marks (note the colon at the end)
6. Add two timer components. Set one of them explicitly to track Real Time and the other to track Game Time.

As a result when you start the timer the first timer tracking the Real Time will be showing the real time, the second timer tracking the Game Time will be showing the real loadless time, and the right text of the text component will be automatically updated with the current in-game time.

Below is the detailed explanation of how the script works.

## Timing methods

LiveSplit timers can show two different types of times: the **Real Time** and the **Game Time**. Typically when an ASL script supports loadless time or in-game time they're shown in the **Game Time** slot in LiveSplit.

Since this script offers both loadless and in-game time they can't be shown in LiveSplit simultaneously this way as the Game Time slot in LiveSplit may be occupied by only one of them. That's why this ASL script operates in one of two modes: the **loadless timing method** mode and the **stats timing method** mode. The timing method specifies what type of time should be presented by the Game Time slot in LiveSplit.

### Loadless timing method

In this mode the Game Time slot in LiveSplit will show the loadless time. The timer is paused when saving/quicksaving the game state (i.e. when the "saving/quicksaving" text is shown on the screen) and quickloading the level from withing the same level (the timer is paused when the player presses F8 and is resumed when the level resumes playing). 

**Note**: keep in mind that other types of loading have not been tested and/or implemented and may not pause the timer. This includes: starting a new level, loading a new level from the main menu or transitioning between levels. **For that reason the loadless timer may not work properly for runs that span multiple levels.** It's perfectly fine for single level runs however.

### Stats timing method

In this mode the Game Time slot in LiveSplit will show the actual in-game time as it would be shown in the stats page at the end of the level. Here's the quick explanation how the in-game time operates in Gruntz:
* when loading a game state the in-game time is restored as well
* when you pause the game, open loading/saving/options/... windows or view help texts in levels, the in-game time is paused
* the in-game time stops the moment you enter the fort with a Warpstone Grunt
* the in-game time resolution as it's stored in the memory of the game is up to a single millisecond. However the time on the stats screen rounds that time down to a nearest second. So for example if the game timer is 55.800ms when entering the fort, the time of "0:55" will be shown in the stats page.

**Note**: as explained above you can't configure LiveSplit timers to track both loadless and in-game times. However the script offers a solution to show the in-game time in a separate text component independently of the actual timing method set. That way you can set the loadless timing method and still be able to track the in-game time. See below for further explanation of this method.

**Note**: LiveSplit timers show time only up to two digits after the period (i.e. up to 10 milliseconds). The in-game time however is stored in the game's memory with a 1 millisecond precision. In order to show the exact in-game time as it's stored in memory, show the in-game time in a separate text component.

## Dynamic text components

The script may optionally display some additional information dynamically via text components in LiveSplit. In order to add such component edit the layout and add the "Information > Text" component. Open its settings and set the "Text" field for the Left Text to one of the predefined values below. The values are case insensitive and have to end with a colon.

Once you start the timer the script will detect such component and act accordingly.

### Game time

If you set the left text to **"Game time:"** the right text will be constantly updated with the actual in-game time with one millisecond precision just the way the game stores it in memory.

The advantages of this method are two-fold. Firstly it allows for viewing the real, loadless and game times simultaneously in a single instance of LiveSplit. It also offers the resolution that would be otherwise inaccesible via LiveSplit timer (which only tracks time up to tens of milliseconds).

There are a few caveats to this method however. Dynamically updating the value of the text component this way is more CPU intensive which theoretically may matter for slower computers. You also won't be able to split times according to the in-game timer since LiveSplit is not really aware of it - you may only split the real and loadless times.

### Script timing method

Setting the left text to **"Timing method:"** makes the right value show the current timing method of the script, i.e. either loadless or stats timing method. It's good for debugging purposes.

### Gruntz version

Setting the left text to **"Gruntz:"** will update the right text with the detected distribution of Gruntz executable, e.g. "v1.01 English" distribution.

## Compatibility

The script is compatible with Gruntz v1.01 only. Version 1.00 has some game breaking bugs which may also affect speedrunning in a negative way and as such I didn't even bother testing the script for it. If you play the game just use the v1.01 patch and you're all set.

The script calculates the MD5 hash of the Gruntz executable itself. Different distributions of Gruntz (e.g. for other languages, no-cd versions etc.) will have different MD5 hash values. If the script doesn't recognize the distribution it will issue a warning. This is just to make sure the script works as intended. If you believe that you have a legitimate (and/or widely used) distribution of Gruntz (perhaps in other language) which is not yet supported by the script let me know and I'll update it. If you get the warning it's still very likely the script will work just fine with your distribution.

You can always disable the warning pop-ups in the settings.

## Troubleshooting

Do you believe the script is not working as it should? Or do you have a yet unknown distribution of Gruntz and you want the script to fully support it?

The first step would be viewing the debug logs. In order to do so download the Microsoft's DebugView application available here: https://docs.microsoft.com/en-us/sysinternals/downloads/debugview. Then follow these steps:
* set the DebugView to filter out everything but messages generated by LiveSplit process (that's in order not to clutter the logs with other unnecessary stuff and to hide some potentially sensitive information )
* close LiveSplit if you have it up and running
* start recording debug logs in DebugView
* open LiveSplit
* go to the settings of the ASL script and check the following option in the advanced settings section: "Generate additional debug messages"
* start the timer and play up to the moment where you think the script is malfunctioning
* stop recording debug messages in DebugView and save the logs to the file.

Now you have to get in touch with me, describe the problem and send me the generated logs. I'll see what I can do from there. You can find me at https://www.speedrun.com/, https://gooroosgruntz.proboards.com/ and the Gruntz Universe Discord server.