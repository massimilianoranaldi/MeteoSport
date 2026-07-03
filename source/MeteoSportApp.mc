import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
(:background)
class MeteoSportApp extends Application.AppBase {

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
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new MeteoSportView() ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {

        var view = WatchUi.getCurrentView()[0] as MeteoSportView;
        view.leggiProprietaSlot();  // ← rilegge i nuovi valori
        WatchUi.requestUpdate();    // ← ridisegna il quadrante


        
    }

        // ← Necessario per registrare il BackgroundService
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

}

function getApp() as MeteoSportApp {
    return Application.getApp() as MeteoSportApp;
}