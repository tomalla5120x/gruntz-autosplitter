# Gruntz Auto Splitter

This is the ASL script for LiveSplit for the game Gruntz v1.01. It features:
* automatic timer starting and splitting
* extracting the in-game timer
* detecting saving and loading (loadless time)

As of now the script is designed for single level runs only. The starting condition is when a level starts and the player's Gruntz start teleporting in. The splitting condition is the moment a Warpstone Grunt enters a fort. The script may be also configured to reset the timer every time a new level starts.

Details on the in-game and loadless times can be found below.

## Timing methods

LiveSplit timers can show two different types of times: the **real** time and the **game** time. Typically when an ASL script supports loadless/game time, they're shown in the **game** time slot in LiveSplit.

Since this script offers both loadless and game time they can't be shown in LiveSplit simultaneously as the game time slot in LiveSplit may be occupied by only one of them. That's why this ASL script operates in one of two modes: the **loadless timing method** and the **stats timing method**. The timing method can be set in the settings.

### Loadless timing method

In this mode the game time slot in LiveSplit will show the loadless time. The timer is paused when saving/quicksaving the game state (i.e. when the "saving/quicksaving" text is shown on the screen) and quickloading the level from withing the same level (the timer is paused when the fading animation starts and is resumed when the level starts playing). 

**Note**: other types of loading have not been tested and/or implemented and may not pause the timer. This includes: starting a new level, loading a new level from the main menu or transitioning between levels. **For that reason the loadless timer may not work properly for runs that span multiple levels.** It's perfectly fine for single level runs however.

### Stats timing method

In this mode the game time slot in LiveSplit will show the actual in-game time as it would be shown in the stats page at the end of the level. Here's how the game time operates in Gruntz:
* when loading a game state the game time is restored as well
* when you pause the game, open loading/saving windows or view help texts in levels, the game timer is paused
* the game time stops the moment you enter the fort with your Warpstone Grunt
* the game time resolution as it's stored in the memory of the game is up to a single millisecond. However the time on the stats screen rounds that time down to a nearest second. So for example if the game timer is 55.800ms when entering the fort, the time of "0:55" will be shown in the stats page.

### Separate component for game time

As explained above you can't use LiveSplit timers to track both loadless and in-game times. However the script offers a solution to show the in-game time in a separate text component independently of the actual timing method set. That way you can set the loadless timing method and still be able to track the in-game time. See below for further explanation of this method.

## Dynamic text components

The script may optionally display some information dynamically via text components in LiveSplit. In order to add such component edit the layout and add the "Information > Text" component. Open its settings and set the "Text" field for the Left Text to one of the predefined values below. The values are case insensitive and have to end with a colon.

Once you start the timer the script will detect such component and fill the right text with a custom value automatically.

### Game time

If you set the left text to **"Game time:"** the right text will be constantly updated with the actual in-game time with one millisecond precision just the way the game stores it in memory.

Advantages of this method are two-fold. Firstly it allows for viewing the real, loadless and game times simultaneously in a single instance of LiveSplit. It also offers the resolution that would be otherwise inaccesible via LiveSplit timer (which only tracks time up to tens of milliseconds).

There are a few caveats to this method however. Dynamically updating the value of the text component is more CPU intensive which theoretically may matter for slower computers. You also won't be able to split times according to the in-game timer since LiveSplit is not really aware of it - you may only split the real and loadless times.

### Script timing method

Setting the left text to **"Timing method:"** makes the right value show the current timing method of the script, i.e. either loadless or stats timing method. It's good for debugging purposes.

### Gruntz version

Setting the left text to **"Gruntz:"** will update the right text with the detected distribution of Gruntz executable, e.g. "v1.01 English" distribution.


## Installing

You can download LiveSplit at [https://livesplit.org/](https://livesplit.org/).

Currently this script is not uploaded to the Auto Splitter database and as such you have to set it up manually. Edit the layout and add the component "Control > Scriptable Auto Splitter". In the "Script Path" field enter the path to this ASL script.

By default the script is set to the loadless timing method. You can always change it in the script settings (the tooltips should be self-explanatory). The changes will take place once you start the LiveSplit timer.

If you want to have timers for both loadless and in-game time visible on screen, you have two options:
* set the script timing method to loadless and add a separate text component for the game time (see the "Dynamic text components" section earlier)
* or start up two instances of LiveSplit and have one instance configured to show the loadless time and the other to show the game time.

This GitHub repository contains the layout for single level speedruns you can use for reference. It has the script set to the loadless timing method and has a separate text component for the in-game time. Just remember to update the path to your ASL script.

## Compatibility

The script is compatible with Gruntz v1.01 only. Version v1.00 has some game breaking bugs and as such I didn't even bother testing the script for it. If you play the game just use the v1.01 patch.

The script calculates the MD5 hash of the Gruntz executable itself. Different distributions of Gruntz (e.g. for other languages) will have different MD5 hash values. If the script doesn't recognize the distribution it will issue a warning. This is just to make sure the script works as intended. If you believe that you have a legitimate distribution of Gruntz (perhaps in other language) which is not yet supported by the script let me know and I'll update it. If you get the warning it's still very likely the script will work just fine with your distribution - I expect the differences in the binary to be only in the resources section of the executable.

Lastly the script calculates MD5 hash of the USER32.DLL library. Detection of the quickloading feature heavily relies on the analysis of the callstack which in turn relies on the USER32.DLL library and its inner workings. Since I don't know how this library operates in different versions and on different Windows platforms I wanted to have some control over this at least for now. So the same applies here - if you happen to have a different USER32.DLL distribution and everything looks to be working just fine, let me know and again - I'll update the script.

You can always disable the warning pop-ups in the settings.