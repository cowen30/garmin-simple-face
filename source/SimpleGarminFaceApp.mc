import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SimpleGarminFaceApp extends Application.AppBase {

	function initialize() {
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state as Dictionary?) as Void {
	}

	// onStop() is called when your application is exiting
	function onStop(state as Dictionary?) as Void {
	}

	// Return the initial view of your application here
	//Here, you'll see how I add the delegate for onPartialUpdate()
	function getInitialView() as Array<Views or InputDelegates>? {
		if (Toybox.WatchUi.WatchFace has :onPartialUpdate) {
			return [ new SimpleGarminFaceView(), new SimpleGarminFaceDelegate() ];
		} else {
			return [ new SimpleGarminFaceView() ];
		}
	}

}

function getApp() as SimpleGarminFaceApp {
	return Application.getApp() as SimpleGarminFaceApp;
}
