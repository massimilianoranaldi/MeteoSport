// ============================================================
// FunctionBackend.mc
// Ultima revisione: 2026-06-07
//
// RESPONSABILITÀ:
//   Recupero e persistenza delle coordinate GPS.
//   Non dipende dalla View né dal BackgroundService.
//
// LOGICA COORDINATE (priorità decrescente):
//   1. GPS attivo con fix valido
//   2. Ultime coordinate salvate in Storage (es. da sessione precedente)
//   3. Coordinate di default (Milano) — solo al primo avvio assoluto
//
// COSTANTI CONFIGURABILI:
//   DEFAULT_LAT / DEFAULT_LON  — città di fallback
//   FAKE_COORD                 — coordinata da escludere (simulatore)
// ============================================================

import Toybox.Position;
import Toybox.System;
import Toybox.Lang;
import Toybox.Application;

class FunctionBackend {

    // ── Costanti ─────────────────────────────────────────────
    static const DEFAULT_LAT as String = "45.46";
    static const DEFAULT_LON as String = "9.19";
    static const FAKE_COORD  as String = "180.00";

    static const KEY_LAST_LAT as String = "lastLat";
    static const KEY_LAST_LON as String = "lastLon";

    function initialize() {}

    // ── getCoords ─────────────────────────────────────────────
    // Restituisce [lat, lon] come Array<String>.
    // Effetti collaterali: salva le coordinate GPS valide in Storage.
    function getCoords() as Array<String> {
        System.println(getTimestamp() + "FunctionBackend.getCoords: inizio");

        // 1. Prova il GPS attivo
        var gpsCoords = _getCoordsFromGps();
        if (gpsCoords != null) {
            _saveCoords(gpsCoords[0], gpsCoords[1]);
            return gpsCoords;
        }

        // 2. Prova le ultime coordinate salvate
        var savedCoords = _getCoordsFromStorage();
        if (savedCoords != null) {
            return savedCoords;
        }

        // 3. Fallback default
        System.println(getTimestamp() + "FunctionBackend.getCoords: fallback default " + DEFAULT_LAT + "," + DEFAULT_LON);
        return [DEFAULT_LAT, DEFAULT_LON];
    }

    // ── _getCoordsFromGps ─────────────────────────────────────
    // Restituisce le coordinate GPS se disponibili e valide, null altrimenti.
    function _getCoordsFromGps() as Array<String>? {
        var info = Position.getInfo();

        if (info == null || info.position == null ||
            info.accuracy == Position.QUALITY_NOT_AVAILABLE) {
            System.println(getTimestamp() + "FunctionBackend._getCoordsFromGps: GPS non disponibile");
            return null;
        }

        var coords = info.position.toDegrees() as Array<Double>;
        var lat    = coords[0].format("%.2f");
        var lon    = coords[1].format("%.2f");

        // Scarta le coordinate fake del simulatore
        if (lat.equals(FAKE_COORD) || lon.equals(FAKE_COORD)) {
            System.println(getTimestamp() + "FunctionBackend._getCoordsFromGps: coordinate simulatore scartate");
            return null;
        }

        System.println(getTimestamp() + "FunctionBackend._getCoordsFromGps: fix lat=" + lat + " lon=" + lon + " acc=" + info.accuracy);
        return [lat, lon];
    }

    // ── _getCoordsFromStorage ─────────────────────────────────
    // Restituisce le ultime coordinate salvate in Storage, null se assenti.
    function _getCoordsFromStorage() as Array<String>? {
        var lat = Application.Storage.getValue(KEY_LAST_LAT) as String?;
        var lon = Application.Storage.getValue(KEY_LAST_LON) as String?;

        if (lat == null || lon == null) {
            System.println(getTimestamp() + "FunctionBackend._getCoordsFromStorage: nessuna coordinata salvata");
            return null;
        }

        System.println(getTimestamp() + "FunctionBackend._getCoordsFromStorage: lat=" + lat + " lon=" + lon);
        return [lat, lon];
    }

    // ── _saveCoords ───────────────────────────────────────────
    // Persiste le coordinate in Storage per uso futuro senza GPS.
    function _saveCoords(lat as String, lon as String) as Void {
        Application.Storage.setValue(KEY_LAST_LAT, lat);
        Application.Storage.setValue(KEY_LAST_LON, lon);
        System.println(getTimestamp() + "FunctionBackend._saveCoords: salvate lat=" + lat + " lon=" + lon);
    }
}
