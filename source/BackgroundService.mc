// ============================================================
// BackgroundService.mc
// Ultima revisione: 2026-06-07
//
// RESPONSABILITÀ:
//   Esegue la chiamata HTTP all'API meteo in background
//   (schedulata ogni 15 min da onExitSleep nella View).
//   Salva la risposta in Storage → la View la legge all'onShow.
//
// FLUSSO:
//   Garmin timer scatta
//     → onTemporalEvent()
//       → fetchMeteo()            legge lat/lon da Storage
//         → makeWebRequest()      chiamata HTTP
//           → _onResponse()       salva dati in Storage
//             → Background.exit() passa dati alla View
//
// COSTANTI CONFIGURABILI:
//   URL_PROD   — endpoint di produzione
//   URL_LOCAL  — endpoint locale per sviluppo (commentato)
//   KEY_*      — chiavi Storage condivise con la View
// ============================================================

import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// ── getTimestamp ──────────────────────────────────────────────
// Funzione globale condivisa tra tutti i file del progetto.
// Il tag (:background) la rende disponibile anche al processo
// background senza doverla duplicare altrove.
(:background)
function getTimestamp() as String {
    var now = System.getClockTime();
    var ms  = System.getTimer() % 1000;
    return "[" + now.hour.format("%02d") + ":" +
           now.min.format("%02d")  + ":" +
           now.sec.format("%02d")  + "." +
           ms.format("%03d") + "] ";
}


(:background)
class BackgroundService extends System.ServiceDelegate {

    // ── Costanti ─────────────────────────────────────────────
    static const URL_PROD  as String = "https://meteo-garmin-worker.massimiliano-ranaldi.workers.dev";
    // static const URL_LOCAL as String = "http://localhost:8787";  // sviluppo locale

    static const DEFAULT_LAT as String = "45.46";   // fallback Milano
    static const DEFAULT_LON as String = "9.19";
    static const FAKE_COORD  as String = "180.00";

    // ── Chiavi Storage (devono coincidere con quelle della View) ──
    static const KEY_LAT   as String = "lat";
    static const KEY_LON   as String = "lon";
    static const KEY_METEO as String = "meteo";

    function initialize() {
        ServiceDelegate.initialize();
    }

    // ── onTemporalEvent ───────────────────────────────────────
    // Chiamato da Garmin quando scatta il timer registrato con
    // Background.registerForTemporalEvent() nella View.
    function onTemporalEvent() as Void {
        System.println("BackgroundService.onTemporalEvent");
        fetchMeteo();
    }

    // ── onBackgroundData ──────────────────────────────────────
    // Chiamato quando il Background Service restituisce dati alla View.
    // Attualmente la View legge direttamente da Storage in onShow/onExitSleep.
    function onBackgroundData(data as Application.PersistableType) as Void {
        System.println("BackgroundService.onBackgroundData");
    }

    // ── fetchMeteo ────────────────────────────────────────────
    // Legge le coordinate da Storage e lancia la chiamata HTTP.
    // Se le coordinate non sono disponibili usa il fallback Milano.
    function fetchMeteo() as Void {
        var lat = _sanitizeCoord(Application.Storage.getValue(KEY_LAT) as String?, DEFAULT_LAT);
        var lon = _sanitizeCoord(Application.Storage.getValue(KEY_LON) as String?, DEFAULT_LON);

        var url = URL_PROD + "?lat=" + lat + "&lon=" + lon;
        System.println("BackgroundService.fetchMeteo: " + url);

        var options = {
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:_onResponse));
    }

    // ── _onResponse ───────────────────────────────────────────
    // Callback HTTP: salva i dati in Storage e chiude il servizio.
    function _onResponse(responseCode as Number, data as Dictionary?) as Void {
        System.println("BackgroundService._onResponse: HTTP " + responseCode);
        System.println("BackgroundService._onResponse: data is null: " + (data == null));

        if (responseCode == 200 && data != null) {
            System.println("BackgroundService._onResponse: OK, città: " + data.get("city"));
            Application.Storage.setValue(KEY_METEO, data);
        } else {
            System.println("BackgroundService._onResponse: errore, dati non aggiornati");
        }

        // Passa i dati alla View (o null in caso di errore)
        Background.exit(data);
    }

    // ── _sanitizeCoord ────────────────────────────────────────
    // Restituisce il fallback se la coordinata è null o fake (simulatore).
    function _sanitizeCoord(coord as String?, fallback as String) as String {
        if (coord == null || coord.equals(FAKE_COORD)) {
            return fallback;
        }
        return coord;
    }
}
