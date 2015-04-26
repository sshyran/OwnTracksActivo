OwnTracksActivo iOS 0.0 Release Notes
=====================================

## OwnTracksActivo 0.0.2
>Release date: 2015-04-26 for alpha testers only

A number of UI enhancements

[NEW] New colored layout #12
[FIX] Re-start after "Stop" now allows selection of job and task #11
[NEW] Eliminated "Pause" state. Just "Stop" and "Go" #10
[NEW] New OwnTracks Style Button Icons (Also used in log) #9
[NEW] Human readable task durations #8


## OwnTracksActivo 0.0.2
>Release date: 2015-04-23 for alpha testers only

Getting rid of the early days problems and inconveniences

[NEW] Use standard picker layout for jobs and tasks #7
[NEW] Eliminate Refresh button - picker lists are guaranteed to be up-to-date #6
[NEW] Limit the number of Log Entries introducing a "KeepDays": <number-of-days-to-keep" configuration value #5
[NEW] Add timestamp to payload to allow queued transmission #4
[NEW] The Navigation Bar Logo is now correctly sized and better visible #3
[NEW] Coloring of the Navigation Bar Logo indicates MQTT connection status. Tapping the icon gives a meaningfull summary of config parameters and error situation with the option to reconnect #2
[NEW] Integrated fabric.io/crashlytics --- just in case #1


## OwnTracksActivo 0.0.1
>Release date: 2015-04-22 for alpha testers only

The initial version is here:

[NEW] All new


Basic Features
==============

OwnTracksActivo

supports you writing your timesheet.

* It subscribes to job and task definitions from which you can select your next task.
* Then you may start or stop your task.
* A seconds counter shows you the amount of time allocated to the task.
* A log of your activities is shown on screen.
* Every activity is published to the server.
* Works based on MQTT protocol with an MQTT broker.
* To see current settings, hit the app icon.
* To modify settings, open an .otac configuration file (see sample in github) in the app.



