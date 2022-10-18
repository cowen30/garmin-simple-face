import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Global for 1hz
var do1hz = false;

class SimpleGarminFaceView extends WatchUi.WatchFace {

	var canDo1hz = false;
	var inLowPower = true;
	var screenWidth, screenHeight, centerX, centerY;
	var bgColor = Graphics.COLOR_BLACK;
	var timeColor = Graphics.COLOR_WHITE;
	var timeFont, timeHeight;

	function initialize() {
		WatchFace.initialize();
		// See if 1hz is possible
		do1hz = (Toybox.WatchUi.WatchFace has :onPartialUpdate);
		canDo1hz = do1hz;
	}

	// Load your resources here
	function onLayout(dc as Dc) as Void {
		// Learn about the screen
		screenWidth = dc.getWidth();
		centerX = screenWidth / 2;
		screenHeight = dc.getHeight();
		centerY = screenHeight / 2;
		setLayout(Rez.Layouts.WatchFace(dc));
	}

	// Called when this View is brought to the foreground. Restore
	// the state of this View and prepare it to be shown. This includes
	// loading resources into memory.
	function onShow() as Void {
	}

	// The magic...  onPartialUpdate()!
	function onPartialUpdate(dc as Dc) as Void {
		var timeFields = getTime();

		// If you change the false to true, you'll exceed the power budget after a couple minutes,
		// if you want to see how that works.
		doTime(dc, timeFields[0], timeFields[1], timeFields[2], timeFields[3], false);
	}

	// Update the view
	function onUpdate(dc as Dc) as Void {
		// If device can do 1hz, make sure to clear the clip in case you exceeded the
		// power limit but there's still a clip
		if (canDo1hz) {
			dc.clearClip();
		}

		dc.setColor(bgColor, bgColor);
		dc.clear();
		dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);

		// Get and show the current time
		var timeFields = getTime();

		var secString = null;
		if (!inLowPower || do1hz) {
			secString = timeFields[2];
		}

		doTime(dc, timeFields[0], timeFields[1], secString, timeFields[3], true); // Common with onPartialUpdate()

		var deviceStats = System.getSystemStats();

		// Get and draw battery percentage
		var batteryString = Lang.format("$1$%", [deviceStats.battery.format("%01d")]);
		dc.drawText(centerX, screenHeight * .1, Graphics.FONT_XTINY, batteryString, Graphics.TEXT_JUSTIFY_CENTER);

		var currentActivityInfo = ActivityMonitor.getInfo();

		// Get and draw steps
		var steps = currentActivityInfo.steps;
		dc.drawText(screenWidth * .35, screenHeight * .87, Graphics.FONT_XTINY, steps.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);

		// Only do the date if it's a full screen update
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var dateString = Lang.format("$1$, $2$ $3$, $4$", [today.day_of_week, today.month, today.day, today.year]);
		dc.drawText(centerX, screenHeight * .25, Graphics.FONT_SMALL, dateString, Graphics.TEXT_JUSTIFY_CENTER);

		var stepGoal = currentActivityInfo.stepGoal;

		var ringY = screenHeight * .75;

		var x1 = screenWidth * .35;
		var radiusOuter = screenWidth / 9;
		var radiusInner = screenWidth / 11;

		// var x2 = 13 * screenWidth / 20;
		// dc.drawCircle(x2, y, radiusOuter);
		// dc.drawCircle(x2, y, radiusInner);

		var stepsArcStart = 90;
		var stepsGoalPercent = steps.toFloat() / stepGoal;

		var stepsArcEnd = 89.9;

		if (stepsGoalPercent > 1.0) {
			stepsArcEnd = 90;
		} else if (stepsGoalPercent > 0.25) {
			stepsArcEnd = 360 - 360 * (stepsGoalPercent - 0.25);
		} else {
			stepsArcEnd = 89.9 - 360 * stepsGoalPercent;
		}

		var ringColor = (stepsGoalPercent >= 1.0) ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE;

		dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(1);

		dc.drawCircle(x1, ringY, radiusOuter);
		dc.drawCircle(x1, ringY, radiusInner);

		dc.setPenWidth(radiusOuter - radiusInner);
		var arcRadius = radiusInner + (radiusOuter - radiusInner) / 2 + 1;
		dc.drawArc(x1, ringY, arcRadius, Graphics.ARC_CLOCKWISE, stepsArcStart, stepsArcEnd);

		// Draw battery icon
		var batteryIcon = WatchUi.loadResource(Rez.Drawables.BatteryIcon);
		var batteryIconWidth = batteryIcon.getWidth();
		dc.drawBitmap(centerX - batteryIconWidth / 2, screenHeight * .03, batteryIcon);

		// Draw steps icon in center of ring
		var stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
		dc.drawBitmap(screenWidth * .31, screenHeight * .7, stepsIcon);
	}

	// Called when this View is removed from the screen. Save the
	// state of this View here. This includes freeing resources from
	// memory.
	function onHide() as Void {
	}

	// The user has just looked at their watch. Timers and animations may be started here.
	function onExitSleep() as Void {
		inLowPower = false;
		// If you're doing 1hz, there's no reason to do the Ui.reqestUpdate()
		// (see note below too)
		if (!do1hz) {
			WatchUi.requestUpdate();
		}
	}

	// Terminate any active timers and prepare for slow updates.
	function onEnterSleep() as Void {
		inLowPower = true;
		// And if you do it here, you may see "jittery seconds" when the watch face drops back to low power mode
		if (!do1hz) {
			WatchUi.requestUpdate();
		}
	}

	hidden function doTime(dc, hour, min, sec, ampm, isFull) { // Common function to display the time
		// Here is where real things happen.
		// If it's a full update, do everthing, but if it's a partial, use setClip

		var secondsFont = Graphics.FONT_MEDIUM;
		var secondsX = screenWidth * .82;
		var secondsY = screenHeight * .37;

		dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);

		if (isFull) {
			// Draw hour
			dc.drawText(screenWidth * .42, centerY, Graphics.FONT_NUMBER_HOT, hour, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
			// Draw divider
			dc.drawText(screenWidth * .45, centerY, Graphics.FONT_NUMBER_HOT, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
			// Draw minutes
			dc.drawText(screenWidth * .48, centerY, Graphics.FONT_NUMBER_HOT, min, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
			// Draw ampm
			dc.drawText(screenWidth * .82, centerY, Graphics.FONT_TINY, ampm, Graphics.TEXT_JUSTIFY_LEFT);
		} else {
			// Get the width and height of the seconds text
			var secondsDimensions = dc.getTextDimensions(sec, secondsFont);

			// Set the clip so it's just the seconds value.
			dc.setClip(secondsX, secondsY, secondsDimensions[0] + 1, secondsDimensions[1] + 1);
			dc.setColor(bgColor, bgColor);
			// Clear anything that might show through from the previous time
			dc.clear();
		}

		// Draw seconds
		dc.drawText(secondsX, secondsY, secondsFont, sec, Graphics.TEXT_JUSTIFY_LEFT);
    }

	hidden function getTime() {
		// Get the current time
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var deviceSettings = System.getDeviceSettings();

		var hour = today.hour;
		var ampmString = "";
		if (!deviceSettings.is24Hour) {
			ampmString = (hour < 12) ? "AM" : "PM"; // should use resource strings
			hour = hour % 12;
			if (hour == 0) {
				hour = 12;
			}
		}

		var hourString = Lang.format("$1$", [ hour.format("%2d") ]);
		var minString = Lang.format("$1$", [ today.min.format("%02d") ]);
		var secString = Lang.format("$1$", [ today.sec.format("%02d") ]);

		return [hourString, minString, secString, ampmString];
	}

}

// If you exceed the budget, you can see by how much, etc. The do1hz is used in onUpdate() and is key.
class SimpleGarminFaceDelegate extends WatchUi.WatchFaceDelegate {

	function initialize() {
		WatchFaceDelegate.initialize();
	}

    function onPowerBudgetExceeded(powerInfo) {
        System.println("Average execution time: " + powerInfo.executionTimeAverage);
        System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
        do1hz = false;
    }

}
