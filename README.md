# CarryHelper
An addon meant to help carry run organizers with distributing the gold.

## Features
1) Automatically add the specified amount of gold whenever a trade is initiated with the person in the run.

3) Tracking of people who you have traded with in a UI, so you do not lose track of it yourself.

![UI](https://imgur.com/zCyMujC.png)

3) Various debugging values in case something goes wrong.

![Debugging](https://imgur.com/ckz20lJ.png)

4) [Optional] Possibility to automatically accept the trade after the trade window is opened, saving you a click.

5) UI and other features automatically stop adding gold if everyone except you and the client have been successfully traded with (after a short period of time) or you leave the group.

6) Silly stats.

## Installation
Download the latest [release](https://github.com/AtSkvysh/CarryHelper/releases) or clone the repository and copy the folder into the right place as with any other addon.

## Commands
Use `/ch` in chat to access commands.

Use `/ch start <amount>` to start the tracker. For example, `/ch start 50000` will start the tracker for all the people currently in the group and sets 50k gold share per person.

Use `/ch end` to stop the tracker (this will drop all your tracked progress so far).

Use `/ch stats` to see various stats.

## Usage
The tracker can be started whenever you have the full group. Due to UI being present until it's removed, it is advised to start it *after* the clear. To ensure best results, cancel any trade requests received or sent *before* the tracker was started and avoid trading the client.

As the addon does not know who the client is, it will try to send the gold to them as well if traded with before everyone else.

The addon currently does not track if all of the gold was sent during the trade, it will only warn you if the total amount trader mismatches the expected value when all people have been traded with.

For your first run, enable debug and check that every step is carried out correctly. Check the settings for this and few other features.

## Disclaimer
The addon's in a still somewhat open beta - use at your own risk. Report any issues as well as suggesstions and feedback to me. The addon is incapable of magically stealing your gold, as you're always in charge of making the final call on all actions. However, improper usage might cause unexpected behaviour. If you run into any issues, stop the tracker, finish manually trading the gold and then report the error to me, describing the issues as best as possible.