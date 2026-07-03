// ============================================================
//  MeteoSportView.mc
//
//  Schermo: 260×260 px — centro: (130, 130)
//
//  LAYOUT VISIVO:
//
//  x:  0   55  85       130      175  205  260
//      │   │   │         │        │    │    │
//  y=0 ├───┴───┴─────────┴────────┴────┴────┤
//      │  [BT]  [ora_agg]  [città]     [PeP]│ ← FASCIA ALTA
//  y=40│                                    │
//      ├──────────┬──────────────┬───────────┤
//      │ icMeteo  │              │ icGradini │ ← RIGA 1 LAT.
//  y=65│ temp/per.│  ╔═══════╗  │ n.piani   │
//      │          │  ║  ORA  ║  │           │
//  y=90│          │  ║       ║  │           │
//      │          │  ║ DATA  ║  │           │
// y=105│ icPioggia│  ║       ║  │ icPassi   │ ← RIGA 2 LAT.
//      │ prob%    │  ║       ║  │ passi     │
// y=130│          │  ║  MIN  ║  │           │
//      │          │  ║       ║  │           │
// y=145│ icUmidita│  ╚═══════╝  │ icCalorie │ ← RIGA 3 LAT.
//      │ umid%    │              │ calorie   │
// y=170│          │              │           │
//      ├──────────┴──────────────┴───────────┤
//      │ [arcoAlba/Tram.]   [arcoMinAtt.]    │ ← FASCIA BASSA
// y=205│     icona+orario       icona+val    │
//      │          [════ BATTERIA ════]        │
// y=245│                                    │
//      └────────────────────────────────────┘
//
//00aaffff COLOR_BLUE
//ffaa00ff COLOR_YELLOW
// ============================================================

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Background;
import Toybox.SensorHistory;

class MeteoSportView extends WatchUi.WatchFace {


    // ── FONT (caricati lazy in onLayout) ────────────────────
    // FontOra  → 76-seg.fnt      : cifre grandi ora e minuti
    // FontOra2 → 14-dot.fnt      : mese nella data
    // FontOra3 → 16-dot.fnt      : numero giorno + città
    // FontOra4 → 14-dot-it.fnt   : giorno della settimana
    // FontOra5 → 12-dot-bold.fnt : ora aggiornamento + batteria
    var _myFont  as FontResource or Null = null;
    var _myFont2 as FontResource or Null = null;
    var _myFont3 as FontResource or Null = null;
    var _myFont4 as FontResource or Null = null;
    var _myFont5 as FontResource or Null = null;

    // ── SISTEMA ─────────────────────────────────────────────
    var _functionBackend as FunctionBackend or Null = null;

    // ── LOGO ────────────────────────────────────────────────
    var _iconPep as BitmapResource or Null = null;

    // ── ICONE GENERICA METEO ─────────────────────────────────────────
    var _iconaMeteo         as BitmapResource or Null = null;  // icona condizione meteo corrente
    
    // ── ICONE SISTEMA ───────────────────────────────────────
    var _iconBluOn  as BitmapResource or Null = null;          // bluetooth connesso
    var _iconBluOff as BitmapResource or Null = null;          // bluetooth disconnesso

    // ── ICONE ATTIVITÀ ──────────────────────────────────────
    var _iconGradini    as BitmapResource or Null = null;      // piani saliti
    var _iconFoot       as BitmapResource or Null = null;      // passi
    var _iconCalorie    as BitmapResource or Null = null;      // calorie
    var _iconMinAttivita as BitmapResource or Null = null;     // minuti attività


    // ── DATI METEO: alba / tramonto / città ─────────────────
    var _iconAlba           as BitmapResource or Null = null;  // icona alba
    var _iconTramonto       as BitmapResource or Null = null;  // icona tramonto
    var _iconVento          as BitmapResource or Null = null;  // icona vento (non attiva)
    var _iconCoperturaCielo as BitmapResource or Null = null;  // icona copertura cielo (non attiva)
    var _iconPercPioggia    as BitmapResource or Null = null;  // icona probabilità pioggia
    var _iconUmidita        as BitmapResource or Null = null;  // icona umidità
    var _iconUvIndex        as BitmapResource or Null = null;  // icona probabilità pioggia
    var _iconPioggia        as BitmapResource or Null = null;  // icona probabilità pioggia



    // ── DATI METEO: condizioni correnti ─────────────────────
    var _sunrise            as String or Null = null;  // formato "HH:MM"
    var _sunset             as String or Null = null;  // formato "HH:MM"
    var _city               as String or Null = null;  // nome città (max 8 char)    
    var _weatherTime        as String or Null = null;  // ora ultimo aggiornamento
    var _windValue          as String or Null = null;  // velocità vento (m/s)
    var _termValue          as String or Null = null;  // temperatura reale (°C)
    var _termPercepita      as String or Null = null;  // temperatura percepita (°C)
    var _copValue           as String or Null = null;  // copertura nuvolosa (%)
    var _humidityValue      as String or Null = null;  // umidità relativa (%)
    var _precipProbValue    as String or Null = null;  // probabilità pioggia (%)
    var _uvValue            as String or Null = null;  //indice UV
    var _precipValue        as String or Null = null;  // mm di pioggia effettiva

  // ── SCELTE UTENTE SULLE PROPERTIES ─────────────────────
    var _slotSx2            as Number or Null = null;  // slot scelto per colonna di sinistra , riga 2
    var _slotSx3            as Number or Null = null;  // slot scelto per colonna di sinistra , riga 3

    var _slotDx1            as Number or Null = null;  // slot scelto per colonna di destra , riga 1
    var _slotDx2            as Number or Null = null;  // slot scelto per colonna di destra , riga 2
    var _slotDx3            as Number or Null = null;  // slot scelto per colonna di destra , riga 3


    // ============================================================
    //  INIZIALIZZAZIONE
    // ============================================================

    function initialize() {
        WatchFace.initialize();
        _functionBackend = new FunctionBackend();
    }

    // Caricamento risorse: chiamato una sola volta al primo avvio.
    // Il pattern "if (x == null) { x = load... }" evita ricaricamenti
    // inutili se onLayout venisse chiamato più volte.
    function onLayout(dc as Dc) as Void {
        System.println(getTimestamp() + "MeteoSport.onLayout");

        // font
        if (_myFont  == null) { _myFont  = Application.loadResource(Rez.Fonts.FontOra)  as FontResource; }
        if (_myFont2 == null) { _myFont2 = Application.loadResource(Rez.Fonts.FontOra2) as FontResource; }
        if (_myFont3 == null) { _myFont3 = Application.loadResource(Rez.Fonts.FontOra3) as FontResource; }
        if (_myFont4 == null) { _myFont4 = Application.loadResource(Rez.Fonts.FontOra4) as FontResource; }
        if (_myFont5 == null) { _myFont5 = Application.loadResource(Rez.Fonts.FontOra5) as FontResource; }

        // icone sistema
        if (_iconBluOn  == null) { _iconBluOn  = Application.loadResource(Rez.Drawables.blueOn)  as BitmapResource; }
        if (_iconBluOff == null) { _iconBluOff = Application.loadResource(Rez.Drawables.blueOff) as BitmapResource; }
        if (_iconPep    == null) { _iconPep    = Application.loadResource(Rez.Drawables.Pep)      as BitmapResource; }

        // icone meteo
        if (_iconaMeteo         == null) { _iconaMeteo         = Application.loadResource(Rez.Drawables.wiNa)           as BitmapResource; }
        if (_iconAlba           == null) { _iconAlba           = Application.loadResource(Rez.Drawables.Alba)           as BitmapResource; }
        if (_iconTramonto       == null) { _iconTramonto       = Application.loadResource(Rez.Drawables.Tramonto)       as BitmapResource; }
        if (_iconCoperturaCielo == null) { _iconCoperturaCielo = Application.loadResource(Rez.Drawables.CoperturaCielo) as BitmapResource; }
        if (_iconVento          == null) { _iconVento          = Application.loadResource(Rez.Drawables.Vento)          as BitmapResource; }
        if (_iconUmidita        == null) { _iconUmidita        = Application.loadResource(Rez.Drawables.Umidita)        as BitmapResource; }
        if (_iconPercPioggia    == null) { _iconPercPioggia    = Application.loadResource(Rez.Drawables.PercPioggia)    as BitmapResource; }
        if (_iconUvIndex        == null) { _iconUvIndex    = Application.loadResource(Rez.Drawables.UvIndex)    as BitmapResource; }
        if (_iconPioggia        == null) { _iconPioggia    = Application.loadResource(Rez.Drawables.Pioggia)    as BitmapResource; }

        // icone attività
        if (_iconGradini     == null) { _iconGradini     = Application.loadResource(Rez.Drawables.Gradini)     as BitmapResource; }
        if (_iconFoot        == null) { _iconFoot        = Application.loadResource(Rez.Drawables.Foot)        as BitmapResource; }
        if (_iconCalorie     == null) { _iconCalorie     = Application.loadResource(Rez.Drawables.Calorie)     as BitmapResource; }
        if (_iconMinAttivita == null) { _iconMinAttivita = Application.loadResource(Rez.Drawables.MinAttivita) as BitmapResource; }

        // attiva il layout XML (include il drawable Background che pulisce lo schermo)
        
        setLayout(Rez.Layouts.WatchFace(dc));
    }


    // ============================================================
    //  FUNZIONI DI SISTEMA
    // ============================================================

    function onShow() as Void {

        leggiProprietaSlot();
        var coords = _functionBackend.getCoords();
        System.println(getTimestamp() + "MeteoSport.onShow: lat=" + (coords[0] as String) + " lon=" + (coords[1] as String));

        // ripristina i dati meteo dalla cache locale se disponibili
        var data = Application.Storage.getValue("meteo") as Dictionary?;
        if (data != null) {
            System.println(getTimestamp() + "MeteoSport.onShow: dati meteo in cache, ripristino");
            onMeteoReceived(data);
        } else {
            System.println(getTimestamp() + "MeteoSport.onShow: nessun dato in cache");
        }
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        System.println(getTimestamp() + "MeteoSport.onExitSleep");

        // salva le coordinate in storage per il BackgroundService
        var coords = _functionBackend.getCoords();
        Application.Storage.setValue("lat", coords[0] as String);
        Application.Storage.setValue("lon", coords[1] as String);

        // registra il timer da 30 min per il fetch meteo in background (se non già attivo)
        var registeredTime = Background.getTemporalEventRegisteredTime() as Time.Moment?;
        if (registeredTime != null) {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: timer già attivo");
        } else {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: registro timer 30 min");
            Background.registerForTemporalEvent(new Time.Duration(30 * 60));
        }

        // aggiorna i dati dalla cache all'uscita dalla modalità sleep
        var data = Application.Storage.getValue("meteo") as Dictionary?;
        if (data != null) {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: dati meteo in cache");
            onMeteoReceived(data);
        }
    }

    function onEnterSleep() as Void {
    }


    // ============================================================
    //  DISEGNO PRINCIPALE — onUpdate
    //  Chiamato ad ogni refresh del quadrante (circa 1 volta al minuto
    //  in modalità normale, più frequente in modalità attiva).
    // ============================================================

    function onUpdate(dc as Dc) as Void {

        // Disegna i drawable del layout XML (incluso Background che
        // chiama dc.clear() con BackgroundColor)
        View.onUpdate(dc);

        // ── COSTANTI GEOMETRIA CENTRALE ──────────────────────────
        // Il rettangolo arrotondato che delimita l'area ora/data
        // è centrato esattamente nel centro dello schermo (130,130)
        var rectW = 90;   // larghezza rettangolo centrale
        var rectH = 150;  // altezza  rettangolo centrale

        // ── COSTANTI FASCIA SINISTRA (meteo) ─────────────────────
        // Le icone sono ancorate a x=57; i testi escono a sinistra
        // dell'icona con un margine di 5 px
        var leftX    = 57;  // x ancora sinistra (bordo sinistro icone)
        var leftY    = 65;  // y prima riga (icona meteo)
        var leftOff  = 5;   // margine tra testo e bordo sinistro icona
        var rowGap   = 40;  // distanza verticale tra le righe sia a dx che a sx

        // ── COSTANTI FASCIA DESTRA (attività) ────────────────────
        // Le icone sono ancorate a x=178; i testi escono a destra
        // dell'icona con un margine di 5 px
        var rightX   = 178; // x ancora destra (bordo sinistro icone)
        var rightY   = 63;  // y prima riga (icona gradini)
        var rightOff = 5;   // margine tra bordo destro icona e testo
        var barLen   = 60;  // lunghezza barre di progresso attività

        // ── COSTANTI FASCIA BASSA (archi) ────────────────────────
        // Due archi circolari simmetrici rispetto al centro (x=130)
        var arcX      = 55;  // x centro arco alba/tramonto (sinistra)
        var arcY      = 205; // y comune ai due archi
        var arcLabel  = 14;  // offset scritta rispetto al centro arco


        // ── ORA / MINUTI / DATA ──────────────────────────────────
        // Le ore sono disegnate sopra il centro del rettangolo (y=90),
        // i minuti sotto (y=170), la data in mezzo (y=130)
        drawOra(dc, 130, 90, _myFont);
        drawMin(dc, 130, 170, _myFont);
        drawDataOrizz(dc, 130, 130, _myFont4, _myFont3, _myFont2);


        // ── GEOMETRIA CENTRALE ───────────────────────────────────
        // Rettangolo arrotondato decorativo che inquadra ora/data/min.
        // Centro (130,130) → angolo top-left: (130-45, 130-75) = (85,55)
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(130 - rectW / 2, 130 - rectH / 2, rectW, rectH, 20);


        // ── FASCIA ALTA ──────────────────────────────────────────

        // #A1 — ora ultimo aggiornamento meteo (centro alto, y=20)
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 20, _myFont5, _weatherTime,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // #A2 — nome città (centro, y=40)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 40, _myFont3, _city,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // #A3 — logo PeP (destra, centrato su y=40, x=202)
        if (_iconPep != null) {
            dc.drawBitmap(202 - _iconPep.getWidth() / 2,
                          40  - _iconPep.getHeight() / 2, _iconPep);
        }

        // #A4 — icona Bluetooth (sinistra, centrato su y=40, x=55)
        var btOn = System.getDeviceSettings().phoneConnected;
        if (btOn) {
            if (_iconBluOn != null) {
                dc.drawBitmap(55 - _iconBluOn.getWidth()  / 2,
                              40 - _iconBluOn.getHeight() / 2, _iconBluOn);
            }
        } else {
            if (_iconBluOff != null) {
                dc.drawBitmap(55 - _iconBluOff.getWidth()  / 2,
                              40 - _iconBluOff.getHeight() / 2, _iconBluOff);
            }
        }


        // ── FASCIA SINISTRA — METEO ──────────────────────────────
        // Tre righe verticali a sinistra del rettangolo centrale.
        // Ogni riga ha: icona a x=leftX, testo a sinistra dell'icona.
        // Riga 1: y=leftY (=65), Riga 2: y=leftY+rowGap (=105), Riga 3: y=leftY+2*rowGap (=145)

        // Riga 1 — icona meteo + temperatura reale + temperatura percepita
        if (_iconaMeteo != null) {
            dc.drawBitmap(leftX, leftY, _iconaMeteo);
        }
        // temperatura reale: allineata a sinistra dell'icona, sulla stessa y
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX - leftOff, leftY,
            Graphics.FONT_XTINY, _termValue,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_RIGHT);

        // temperatura percepita: colorata (giallo se >25°, blu altrimenti)
        // posizionata a metà altezza icona meteo (y = leftY + 5 + iconH/2)
        var tempNum = _termPercepita != null ? _termPercepita.toNumber() : 0;
        if (tempNum > 25) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(leftX - leftOff, leftY + 5 + _iconaMeteo.getHeight() / 2,
            Graphics.FONT_XTINY, tempNum + "°",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_RIGHT);

        // Riga 2 — icona probabilità pioggia + valore %
        //--------------------------------------------------------------------------------------------------------
        /*if (_iconPercPioggia != null) {
            dc.drawBitmap(leftX, leftY + rowGap, _iconPercPioggia);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX - leftOff,
            leftY + rowGap + _iconPercPioggia.getHeight() / 2,
            Graphics.FONT_SYSTEM_XTINY, _precipProbValue,
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_RIGHT);
        */
        //System.println("VALORE SCELTA " + _slotSx2);
        drawLeftColumn(dc,leftX,leftY + rowGap,leftOff,_slotSx2);
        //--------------------------------------------------------------------------------------------------------
        

        // Riga 3 — icona umidità + valore %
        /*if (_iconUmidita != null) {
            dc.drawBitmap(leftX, leftY + 2 * rowGap, _iconUmidita);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX - leftOff,
            leftY + 2 * rowGap + _iconUmidita.getHeight() / 2,
            Graphics.FONT_XTINY, _humidityValue,
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_RIGHT);

        System.println("VALORE SCELTA " + _slotSx2);*/
        drawLeftColumn(dc,leftX,leftY + 2 * rowGap,leftOff,_slotSx3);
        // ── FASCIA DESTRA — ATTIVITÀ ─────────────────────────────
        // Tre righe verticali a destra del rettangolo centrale.
        // Ogni riga ha: icona a x=rightX, testo a destra dell'icona,
        // barra di progresso sotto a y = rigaY + 28.
        // Riga 1: y=rightY (=63), Riga 2: y=rightY+rowGap (=103), Riga 3: y=rightY+2*rowGap (=143)

        // Riga 1 — gradini (piani saliti), obiettivo=10
        if (_iconGradini != null) {
            dc.drawBitmap(rightX, rightY, _iconGradini);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + _iconGradini.getWidth() + rightOff, rightY + 8,
            Graphics.FONT_XTINY, getFloors()["climbed"],
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_LEFT);
        // barra a trattini: y=rightY+28, lunghezza=barLen (=60), max=10 piani
        drawSegmentoProgressTrattini(dc, rightX, rightY + 28, barLen, 3,
            getFloors()["climbed"], 10,
            { "sfondo" => Graphics.COLOR_DK_GRAY, "fill" => Graphics.COLOR_BLUE,
              "segmenti" => 10, "gap" => 1 }, false);

        // Riga 2 — passi, obiettivo=10000
        if (_iconFoot != null) {
            dc.drawBitmap(rightX, rightY + rowGap, _iconFoot);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + _iconFoot.getWidth() + rightOff, rightY + rowGap + 8,
            Graphics.FONT_XTINY, getSteps(),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_LEFT);
        // barra piena: lunghezza=barLen+10 (=70), max=10000 passi
        drawSegmentoProgress(dc, rightX, rightY + rowGap + 28, barLen + 10, 3,
            getSteps(), 10000,
            { "sfondo" => Graphics.COLOR_DK_GRAY, "fill" => Graphics.COLOR_BLUE }, false);

        // Riga 3 — calorie, obiettivo=2000
        if (_iconCalorie != null) {
            dc.drawBitmap(rightX, rightY + 2 * rowGap, _iconCalorie);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + _iconCalorie.getWidth() + rightOff, rightY + 2 * rowGap + 8,
            Graphics.FONT_XTINY, getCalories(),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_LEFT);
        // barra piena: lunghezza=barLen (=60), max=2000 kcal
        drawSegmentoProgress(dc, rightX, rightY + 2 * rowGap + 28, barLen, 3,
            getCalories(), 2000,
            { "sfondo" => Graphics.COLOR_DK_GRAY, "fill" => Graphics.COLOR_BLUE }, false);


        // ── FASCIA BASSA — ARCO ALBA/TRAMONTO (sinistra) ─────────
        // Arco a punti centrato in (arcX=55, arcY=205).
        // Mostra il progresso della fase giorno/notte corrente.
        // I segmenti rappresentano ore (goal/60 punti).

        var info       = minutiMancantiEvento(_sunrise, _sunset);
        var minuti     = info["minuti"] as Number;   // minuti mancanti all'evento
        var goal       = info["goal"]   as Number;   // durata totale della fase (minuti)
        var evento     = info["evento"] as String;   // "alba" o "tramonto"
        var valoreDraw = goal - minuti;              // minuti già trascorsi (riempie l'arco)

        // alba → punti gialli su sfondo grigio; tramonto → punti grigi su sfondo giallo
        var colFill   = evento.equals("alba") ? Graphics.COLOR_YELLOW  : Graphics.COLOR_DK_GRAY;
        var colSfondo = evento.equals("alba") ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_YELLOW;

        drawCerchioAttivitaPunti(dc, arcX, arcY, valoreDraw, goal, 0, -90, false,
            { "raggio"      => 20,
              "raggioPunto" => 2,
              "segmenti"    => Math.ceil(goal.toFloat() / 60.0f).toNumber(),
              "sfondo"      => colFill,
              "fill"        => colSfondo });

        // icona e orario al centro dell'arco (offset di arcLabel=14 px in basso+destra)
        if (evento.equals("alba")) {
            if (_iconAlba != null) {
                dc.drawBitmap(arcX - _iconAlba.getWidth()  / 2,
                              arcY - _iconAlba.getHeight() / 2, _iconAlba);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(arcX + arcLabel, arcY + arcLabel,
                    Graphics.FONT_XTINY, _sunrise,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            if (_iconTramonto != null) {
                dc.drawBitmap(arcX - _iconTramonto.getWidth()  / 2,
                              arcY - _iconTramonto.getHeight() / 2, _iconTramonto);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(arcX + arcLabel, arcY + arcLabel,
                    Graphics.FONT_XTINY, _sunset,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }


        // ── FASCIA BASSA — ARCO MINUTI ATTIVITÀ (destra) ────────
        // Arco a trattini centrato in (260-arcX=205, arcY=205),
        // simmetrico all'arco alba/tramonto rispetto al centro (130).
        // Mostra i minuti di attività settimanali, obiettivo=300 min.

        var arcXDx = 130 + (130 - arcX); // = 205 (simmetrico rispetto a 130)

        drawCerchioAttivitaTrattini(dc, arcXDx, arcY,
            getActiveMinutesWeek(), 300, 180, 270, true,
            { "raggio" => 20, "spessore" => 4, "segmenti" => 8,
              "gap" => 4, "sfondo" => Graphics.COLOR_DK_GRAY,
              "fill" => Graphics.COLOR_BLUE });

        // icona e valore al centro dell'arco destro
        if (_iconAlba != null) {
            dc.drawBitmap(arcXDx - _iconMinAttivita.getWidth()  / 2,
                          arcY   - _iconMinAttivita.getHeight() / 2, _iconMinAttivita);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // testo allineato a destra del centro (usa 130+arcX come anchor destro)
            dc.drawText(130 + arcX, arcY + arcLabel,
                Graphics.FONT_XTINY, getActiveMinutesWeek(),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }


        // ── BATTERIA ─────────────────────────────────────────────
        // Disegnata in basso al centro (x=130, y=245)
        drawBatteria(dc, 130, 245, _myFont5);
    } //CHIUSURA onUpdate


    // ============================================================
    //  FUNZIONI DI DISEGNO
    // ============================================================

    // Disegna le ore nel formato 12h o 24h in base alle impostazioni di sistema.
    // Colore: giallo. Font: _myFont (76-seg.fnt, font grande segmentato).
    // x, y = centro del testo
    function drawOra(dc as Dc, x as Number, y as Number, font as FontResource) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) { hours = hours - 12; }
        }

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, hours.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Disegna i minuti. Colore: blu. Font: _myFont (76-seg.fnt).
    // x, y = centro del testo
    function drawMin(dc as Dc, x as Number, y as Number, font as FontResource) as Void {
        var clockTime = System.getClockTime();

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, clockTime.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Disegna la data in formato orizzontale: "Lu  15  Fe"
    // I tre elementi (giorno settimana | numero | mese) sono allineati
    // e centrati dinamicamente intorno a x usando le larghezze reali dei testi.
    // fontGiorno = _myFont4 (corsivo), fontNum = _myFont3 (grande), fontMese = _myFont2 (piccolo)
    function drawDataOrizz(dc as Dc, x as Number, y as Number,
                           fontGiorno as FontResource,
                           fontNum    as FontResource,
                           fontMese   as FontResource) as Void {

        var now  = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        var italianDays   = ["Do","Lu","Ma","Me","Gi","Ve","Sa"] as Array<String>;
        var italianMonths = ["Ge","Fe","Ma","Ap","Ma","Gi","Lu","Ag","Se","Ot","No","Di"] as Array<String>;

        var dowIndex = (info.day_of_week as Number) - 1;
        if (dowIndex < 0 || dowIndex > 6) { dowIndex = 0; }
        var monIndex = (info.month as Number) - 1;
        if (monIndex < 0 || monIndex > 11) { monIndex = 0; }

        var dayName  = italianDays[dowIndex];
        var dayNum   = info.day.format("%d");
        var monthStr = italianMonths[monIndex];
        var spacing  = 4;   // gap in pixel tra i tre elementi

        // calcola larghezze reali per centrare il blocco in modo preciso
        var wDayName  = dc.getTextDimensions(dayName,  fontGiorno)[0];
        var wDayNum   = dc.getTextDimensions(dayNum,   fontNum)[0];
        var wMonthStr = dc.getTextDimensions(monthStr, fontMese)[0];

        var totalW = wDayName + spacing + wDayNum + spacing + wMonthStr;
        var startX = x - totalW / 2;  // x di partenza per avere il blocco centrato su x

        // giorno settimana — grigio
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, fontGiorno, dayName,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // numero giorno — bianco (font più grande)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + wDayName + spacing, y, fontNum, dayNum,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // mese — grigio
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + wDayName + spacing + wDayNum + spacing, y, fontMese, monthStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Disegna l'indicatore batteria: rettangolo + riempimento + percentuale.
    // Il blocco è centrato orizzontalmente su cx.
    // Colori: verde >50%, giallo ≤50%, rosso ≤20%
    // font = _myFont5 (12-dot-bold.fnt)
    function drawBatteria(dc as Dc, cx as Number, cy as Number, font as FontResource) as Void {
        var batW  = 30;   // larghezza corpo batteria
        var batH  = 12;   // altezza corpo batteria

        var stats = System.getSystemStats();
        var level = stats.battery;
        var text  = level.format("%d") + "%";

        // calcola larghezza totale (corpo + polarità + spazio + testo)
        var textW  = dc.getTextWidthInPixels(text, font);
        var totalW = batW + 3 + 8 + textW;    // 3px polarità, 8px margine testo
        var batX   = cx - (totalW / 2);        // x angolo top-left corpo batteria
        var batY   = cy - (batH / 2);          // y angolo top-left corpo batteria

        var batColor = Graphics.COLOR_GREEN;
        if      (level <= 20) { batColor = Graphics.COLOR_RED;    }
        else if (level <= 50) { batColor = Graphics.COLOR_YELLOW; }

        // corpo batteria (rettangolo bianco)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(batX, batY, batW, batH, 2);

        // polarità (+) sul lato destro
        dc.fillRoundedRectangle(batX + batW, batY + 3, 3, 6, 1);

        // riempimento proporzionale al livello
        var fillW = ((batW - 4) * level / 100).toNumber();
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(batX + 2, batY + 2, fillW, batH - 4, 1);

        // percentuale testuale a destra del corpo + 8px margine
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(batX + batW + 3 + 8, cy, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ── BARRE DI PROGRESSO ───────────────────────────────────────

    // Barra orizzontale continua con bordi arrotondati.
    // xSinistra = x di partenza, cy = centro verticale della barra
    // lunghezza, spessore = dimensioni barra
    // valore/massimo = percentuale di riempimento
    // rtl = true → riempie da destra a sinistra
    function drawSegmentoProgress(dc as Dc, xSinistra as Number, cy as Number,
                                  lunghezza as Number, spessore as Number,
                                  valore as Number, massimo as Number,
                                  colori as Dictionary, rtl as Boolean) as Void {
        var x      = xSinistra;
        var y      = cy - spessore / 2;
        var raggio = spessore / 2;

        var perc = valore.toFloat() / massimo.toFloat();
        if (perc > 1.0f) { perc = 1.0f; }
        if (perc < 0.0f) { perc = 0.0f; }
        var fillW = (lunghezza * perc).toNumber();

        // sfondo (barra vuota)
        dc.setColor(colori["sfondo"], colori["sfondo"]);
        dc.fillRoundedRectangle(x, y, lunghezza, spessore, raggio);

        // riempimento
        if (fillW > 0) {
            dc.setColor(colori["fill"], colori["fill"]);
            if (rtl) {
                dc.fillRoundedRectangle(x + lunghezza - fillW, y, fillW, spessore, raggio);
            } else {
                dc.fillRoundedRectangle(x, y, fillW, spessore, raggio);
            }
        }
    }

    // Barra orizzontale a trattini separati.
    // colori["segmenti"] = numero di trattini
    // colori["gap"] = gap in pixel tra i trattini
    function drawSegmentoProgressTrattini(dc as Dc, xSinistra as Number, cy as Number,
                                          lunghezza as Number, spessore as Number,
                                          valore as Number, massimo as Number,
                                          colori as Dictionary, rtl as Boolean) as Void {
        var raggio    = spessore / 2;
        var y         = cy - spessore / 2;
        var nTrattini = colori["segmenti"] as Number;
        var gap       = colori["gap"]      as Number;

        var perc = valore.toFloat() / massimo.toFloat();
        if (perc > 1.0f) { perc = 1.0f; }
        if (perc < 0.0f) { perc = 0.0f; }

        var filledTrattini = (perc * nTrattini).toNumber();
        var totGap         = gap * (nTrattini - 1);
        var trattiniW      = (lunghezza - totGap) / nTrattini;

        for (var i = 0; i < nTrattini; i++) {
            var idx       = rtl ? (nTrattini - 1 - i) : i;
            var xTrattino = xSinistra + idx * (trattiniW + gap);
            var colore    = (i < filledTrattini) ? colori["fill"] : colori["sfondo"];
            dc.setColor(colore, colore);
            dc.fillRoundedRectangle(xTrattino, y, trattiniW, spessore, raggio);
        }
    }

    // ── ARCHI CIRCOLARI ──────────────────────────────────────────

    // Arco pieno con cappucci arrotondati alle estremità.
    // cfg: { "raggio", "spessore", "sfondo", "fill" }
    // starDeg/endDeg in gradi (0=destra, 90=su, 180=sinistra, 270=giù)
    // cw = true → senso orario
    function drawCerchioAttivita(dc as Dc, cx as Number, cy as Number,
                                 valore as Number, goal as Number,
                                 starDeg as Number, endDeg as Number,
                                 cw as Boolean, cfg as Dictionary) as Void {
        var totalDeg = calcolaArco(starDeg, endDeg, cw);
        var arcDir   = cw ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        var spessore = cfg["spessore"] as Number;
        var raggio   = cfg["raggio"]   as Number;
        var capR     = spessore / 2;

        var filled = valore.toFloat() * totalDeg / goal.toFloat();
        if (filled > totalDeg) { filled = totalDeg; }
        var endAngle = cw
            ? (starDeg - filled).toNumber()
            : (starDeg + filled).toNumber();

        // sfondo
        dc.setColor(cfg["sfondo"], Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(spessore);
        dc.drawArc(cx, cy, raggio, arcDir, starDeg, endDeg);

        var radStart = Math.toRadians(starDeg);
        dc.setColor(cfg["sfondo"], cfg["sfondo"]);
        dc.fillCircle((cx + raggio * Math.cos(radStart)).toNumber(),
                      (cy - raggio * Math.sin(radStart)).toNumber(), capR);
        var radEnd = Math.toRadians(endDeg);
        dc.fillCircle((cx + raggio * Math.cos(radEnd)).toNumber(),
                      (cy - raggio * Math.sin(radEnd)).toNumber(), capR);

        // riempimento (solo se abbastanza grande)
        if (filled > 3) {
            dc.setColor(cfg["fill"], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(spessore);
            dc.drawArc(cx, cy, raggio, arcDir, starDeg, endAngle);

            dc.setColor(cfg["fill"], cfg["fill"]);
            dc.fillCircle((cx + raggio * Math.cos(radStart)).toNumber(),
                          (cy - raggio * Math.sin(radStart)).toNumber(), capR);
            var radEndAngle = Math.toRadians(endAngle);
            dc.fillCircle((cx + raggio * Math.cos(radEndAngle)).toNumber(),
                          (cy - raggio * Math.sin(radEndAngle)).toNumber(), capR);
        }

        dc.setPenWidth(1);
    }

    // Arco con tacche perpendicolari (tick marks) alle posizioni dei segmenti.
    // cfg: { "raggio", "spessore", "segmenti", "lunghezza", "sfondo", "fill", "colTacca" }
    function drawCerchioAttivitaTacche(dc as Dc, cx as Number, cy as Number,
                                       valore as Number, goal as Number,
                                       starDeg as Number, endDeg as Number,
                                       cw as Boolean, cfg as Dictionary) as Void {
        var totalDeg  = cw ? starDeg - endDeg : endDeg - starDeg;
        if (totalDeg <= 0) { totalDeg = totalDeg + 360; }

        var arcDir    = cw ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        var spessore  = cfg["spessore"]  as Number;
        var raggio    = cfg["raggio"]    as Number;
        var nTacche   = cfg["segmenti"]  as Number;
        var lunghezza = cfg["lunghezza"] as Number;

        var perc = valore.toFloat() / goal.toFloat();
        if (perc > 1.0f) { perc = 1.0f; }
        if (perc < 0.0f) { perc = 0.0f; }
        var filledAngle = cw
            ? (starDeg - perc * totalDeg).toNumber()
            : (starDeg + perc * totalDeg).toNumber();

        dc.setColor(cfg["sfondo"], Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(spessore);
        dc.drawArc(cx, cy, raggio, arcDir, starDeg, endDeg);

        if (perc > 0.0f) {
            dc.setColor(cfg["fill"], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, raggio, arcDir, starDeg, filledAngle);
        }
        dc.setPenWidth(1);

        // tacche perpendicolari equidistanti
        var stepDeg = totalDeg.toFloat() / nTacche;
        for (var i = 0; i <= nTacche; i++) {
            var taccaDeg = cw
                ? (starDeg - i * stepDeg).toNumber()
                : (starDeg + i * stepDeg).toNumber();
            var rad  = Math.toRadians(taccaDeg);
            var cosA = Math.cos(rad);
            var sinA = Math.sin(rad);
            var r1 = raggio - lunghezza / 2;
            var r2 = raggio + lunghezza / 2;
            dc.setColor(cfg["colTacca"], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine((cx + r1 * cosA).toNumber(), (cy - r1 * sinA).toNumber(),
                        (cx + r2 * cosA).toNumber(), (cy - r2 * sinA).toNumber());
        }
    }

    // Arco a segmenti (trattini curvi) separati da gap angolari.
    // cfg: { "raggio", "spessore", "segmenti", "gap", "sfondo", "fill" }
    function drawCerchioAttivitaTrattini(dc as Dc, cx as Number, cy as Number,
                                         valore as Number, goal as Number,
                                         starDeg as Number, endDeg as Number,
                                         cw as Boolean, cfg as Dictionary) as Void {
        var totalDeg = cw ? starDeg - endDeg : endDeg - starDeg;
        if (totalDeg <= 0) { totalDeg = totalDeg + 360; }

        var arcDir   = cw ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        var spessore = cfg["spessore"] as Number;
        var raggio   = cfg["raggio"]   as Number;
        var nSeg     = cfg["segmenti"] as Number;
        var gapDeg   = cfg["gap"]      as Number;

        var segDeg = (totalDeg - nSeg * gapDeg).toFloat() / nSeg;

        var perc = valore.toFloat() / goal.toFloat();
        if (perc > 1.0f) { perc = 1.0f; }
        if (perc < 0.0f) { perc = 0.0f; }
        var filledSegs = (perc * nSeg).toNumber();

        dc.setPenWidth(spessore);
        for (var i = 0; i < nSeg; i++) {
            var segStart = cw
                ? (starDeg - i * (segDeg + gapDeg)).toNumber()
                : (starDeg + i * (segDeg + gapDeg)).toNumber();
            var segEnd = cw
                ? (segStart - segDeg).toNumber()
                : (segStart + segDeg).toNumber();
            var colore = (i < filledSegs) ? cfg["fill"] as Number : cfg["sfondo"] as Number;
            dc.setColor(colore, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, raggio, arcDir, segStart, segEnd);
        }
        dc.setPenWidth(1);
    }

    // Arco a cerchietti (punti) distribuiti lungo l'arco.
    // cfg: { "raggio", "raggioPunto", "segmenti", "sfondo", "fill" }
    function drawCerchioAttivitaPunti(dc as Dc, cx as Number, cy as Number,
                                      valore as Number, goal as Number,
                                      starDeg as Number, endDeg as Number,
                                      cw as Boolean, cfg as Dictionary) as Void {
        var totalDeg = cw ? starDeg - endDeg : endDeg - starDeg;
        if (totalDeg <= 0) { totalDeg = totalDeg + 360; }

        var nPunti = cfg["segmenti"]    as Number;
        var rPunto = cfg["raggioPunto"] as Number;
        var raggio = cfg["raggio"]      as Number;

        var perc = valore.toFloat() / goal.toFloat();
        if (perc > 1.0f) { perc = 1.0f; }
        if (perc < 0.0f) { perc = 0.0f; }
        var filledPunti = (perc * nPunti).toNumber();
        var stepDeg     = totalDeg.toFloat() / (nPunti - 1);

        for (var i = 0; i < nPunti; i++) {
            var puntoDeg = cw
                ? (starDeg - i * stepDeg).toNumber()
                : (starDeg + i * stepDeg).toNumber();
            var rad = Math.toRadians(puntoDeg);
            var px  = (cx + raggio * Math.cos(rad)).toNumber();
            var py  = (cy - raggio * Math.sin(rad)).toNumber();
            var colore = (i < filledPunti) ? cfg["fill"] as Number : cfg["sfondo"] as Number;
            dc.setColor(colore, colore);
            dc.fillCircle(px, py, rPunto);
        }
    }

    // Utiltà: calcola l'ampiezza angolare di un arco in gradi (sempre positiva).
    function calcolaArco(startDeg as Number, endDeg as Number, cw as Boolean) as Number {
        var arco;
        if (cw) {
            arco = startDeg - endDeg;
            if (arco <= 0) { arco = arco + 360; }
        } else {
            arco = endDeg - startDeg;
            if (arco <= 0) { arco = arco + 360; }
        }
        return arco;
    }

    // Calcola i minuti mancanti al prossimo evento (alba o tramonto)
    // e la durata totale della fase corrente.
    // sunrise/sunset sono stringhe in formato "HH:MM"
    // Ritorna: { "minuti" => N, "goal" => N, "evento" => "alba"|"tramonto" }
    function minutiMancantiEvento(sunrise as String?, sunset as String?) as Dictionary {
        if (sunrise == null || sunset == null) {
            return { "minuti" => 0, "goal" => 1440, "evento" => "n.d." };
        }

        var minAlba     = sunrise.substring(0, 2).toNumber() * 60 + sunrise.substring(3, 5).toNumber();
        var minTramonto = sunset.substring(0, 2).toNumber()  * 60 + sunset.substring(3, 5).toNumber();
        var minCorrente = System.getClockTime().hour * 60 + System.getClockTime().min;

        var diff;
        var goal;
        var evento;

        if (minCorrente < minAlba) {
            // notte: dopo mezzanotte, prima dell'alba
            diff   = minAlba - minCorrente;
            goal   = 1440 - minTramonto + minAlba;  // durata intera della notte
            evento = "alba";
        } else if (minCorrente < minTramonto) {
            // giorno: tra alba e tramonto
            diff   = minTramonto - minCorrente;
            goal   = minTramonto - minAlba;
            evento = "tramonto";
        } else {
            // sera: dopo il tramonto, prima di mezzanotte
            diff   = 1440 - minCorrente + minAlba;
            goal   = 1440 - minTramonto + minAlba;
            evento = "alba";
        }

        return { "minuti" => diff, "goal" => goal, "evento" => evento };
    }

    function drawCircleOutline(dc as Dc, x as Number, y as Number,
                               radius as Number, color as Number, penWidth as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);
        dc.drawCircle(x, y, radius);
    }

    function drawCircleFill(dc as Dc, x as Number, y as Number,
                            radius as Number, color as Number) as Void {
        dc.setColor(color, color);
        dc.fillCircle(x, y, radius);
    }



    function drawLeftColumn(dc       as Dc,
                            positionIconX    as Number,
                            positionIconY    as Number,
                            leftOffset as Number,
                            slotType as Number) as Void {

        var contenuto = getSlotContentSinistra(slotType); 
        // viene ritornato contenuto={ "icon" => _iconPercPioggia,    "text" => _precipProbValue }
        var icon = contenuto["icon"] as BitmapResource?;
        var text = contenuto["text"] as String?;

        System.println(getTimestamp() + "MeteoSport.drawLeftColumn" + text + "scelta:"+slotType);

        if (icon == null || text == null) { return; }

        // disegna icona
        dc.drawBitmap(positionIconX, positionIconY, icon);

        // disegna testo a sinistra dell'icona, centrato verticalmente
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(positionIconX-leftOffset, positionIconY + icon.getHeight() / 2,
            Graphics.FONT_SYSTEM_XTINY, text,
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_RIGHT);




    }
    // ============================================================
    //  DATI ATTIVITÀ UTENTE
    // ============================================================

    function getActiveMinutesWeek() as Number {
        var info       = ActivityMonitor.getInfo();
        var activeWeek = info.activeMinutesWeek;
        return activeWeek != null ? activeWeek.total : 0;
    }

    function getCalories() as Number {
        var info = ActivityMonitor.getInfo();
        return info.calories != null ? info.calories : 0;
    }

    function getActiveMinutes() as Number {
        var info   = ActivityMonitor.getInfo();
        var active = info.activeMinutesDay;
        if (active == null) { return 0; }
        return active.total;
    }

    function getSteps() as Number {
        var info  = ActivityMonitor.getInfo();
        var steps = info.steps;
        return steps != null ? steps : 0;
    }

    function getDistanceKm() as Float {
        var info = ActivityMonitor.getInfo();
        var dist = info.distance;
        if (dist == null) { return 0.0f; }
        return dist / 100000.0f;
    }

    function getFloors() as Dictionary {
        var info      = ActivityMonitor.getInfo();
        var climbed   = info.floorsClimbed   != null ? info.floorsClimbed   : 0;
        var descended = info.floorsDescended != null ? info.floorsDescended : 0;
        return { "climbed" => climbed, "descended" => descended };
    }

    function getBodyBattery() as Number {
        var iter   = SensorHistory.getBodyBatteryHistory({ :order => SensorHistory.ORDER_NEWEST_FIRST });
        var sample = iter.next();
        if (sample == null) { return 0; }
        var data = sample.data;
        return data != null ? data : 0;
    }

    function getBodyBatteryMidnight() as Number {
        var iter   = SensorHistory.getBodyBatteryHistory({
            :startTime => Time.today(),
            :order => SensorHistory.ORDER_OLDEST_FIRST
        });
        var sample = iter.next();
        if (sample == null) { return 0; }
        var data = sample.data;
        return data != null ? data : 0;
    }


    // ============================================================
    //  BACKEND METEO
    // ============================================================

    // Carica l'icona meteo corrispondente al codice WMO ricevuto dall'API.
    // Codici WMO: 0=sereno, 1-3=parzialmente nuvoloso, 45/48=nebbia,
    // 51-55=pioggerella, 61-65=pioggia, 71-75=neve, 80-82=rovesci,
    // 95=temporale. Tutti gli altri → icona "N/D"
    function loadWeatherIcon(code as Number?) as BitmapResource? {
        var iconId;
        if      (code == 0)  { iconId = Rez.Drawables.wiDaySunny;         }
        else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercast; }
        else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudy;        }
        else if (code == 3)  { iconId = Rez.Drawables.wiCloudy;           }
        else if (code == 45) { iconId = Rez.Drawables.wiDayFog;           }
        else if (code == 48) { iconId = Rez.Drawables.wiDayHaze;          }
        else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkle;      }
        else if (code == 53) { iconId = Rez.Drawables.wiSprinkle;         }
        else if (code == 55) { iconId = Rez.Drawables.wiRainMix;          }
        else if (code == 61) { iconId = Rez.Drawables.wiDayRain;          }
        else if (code == 63) { iconId = Rez.Drawables.wiRain;             }
        else if (code == 65) { iconId = Rez.Drawables.wiRainWind;         }
        else if (code == 71) { iconId = Rez.Drawables.wiDaySnow;          }
        else if (code == 73) { iconId = Rez.Drawables.wiSnow;             }
        else if (code == 75) { iconId = Rez.Drawables.wiSnowWind;         }
        else if (code == 80) { iconId = Rez.Drawables.wiDayShowers;       }
        else if (code == 81) { iconId = Rez.Drawables.wiShowers;          }
        else if (code == 82) { iconId = Rez.Drawables.wiStormShowers;     }
        else if (code == 95) { iconId = Rez.Drawables.wiThunderstorm;     }
        else                 { iconId = Rez.Drawables.wiNa;               }
        return Application.loadResource(iconId) as BitmapResource;
    }

    // Callback chiamato da BackgroundService quando arrivano nuovi dati meteo.
    // Aggiorna tutte le variabili meteo e richiede un refresh del quadrante.
    function onMeteoReceived(data as Dictionary?) as Void {
        System.println(getTimestamp() + "MeteoSport.onMeteoReceived");

        if (data == null) {
            System.println(getTimestamp() + "MeteoSport.onMeteoReceived: nessun dato");
            return;
        }

        // città: troncata a 8 char + "." se troppo lunga
        var raw = data.get("city") as String?;
        _city    = (raw != null && raw.length() > 10) ? raw.substring(0, 8) + "." : raw;
        _sunrise = extractTime(data.get("sunrise") as String?);
        _sunset  = extractTime(data.get("sunset")  as String?);

        var forecast = data.get("forecast") as Array?;
        if (forecast == null || forecast.size() == 0) {
            WatchUi.requestUpdate();
            return;
        }

        // legge la prima previsione (ora corrente)
        var e      = forecast[0] as Dictionary;
        var wcode  = e.get("weather_code")         as Number?;
        var temp0  = e.get("temperature")          as Number?;
        var perc0  = e.get("apparent_temperature") as Number?;
        var wind0  = e.get("wind_speed")           as Number?;
        var cloud0 = e.get("cloud_cover")          as Number?;
        var humidity0    = e.get("humidity")            as Number?;
        var precipProb0  = e.get("precip_probability")  as Number?;
        var uv0 = e.get("uv_index") as Float?;
       var precip0 = e.get("precipitation") as String?;




        System.println(getTimestamp() + "weather_code: " + wcode);

        _weatherTime     = extractTime(e.get("time") as String?);
        _termValue       = temp0  != null ? temp0.toString()  + "°"  : "n.d.";
        _termPercepita   = perc0  != null ? perc0.toString()  + "°"  : "n.d.";
        _windValue       = wind0  != null ? wind0.toString()  + "ms" : "n.d.";
        _copValue        = cloud0 != null ? cloud0.toString() + "%"  : "n.d.";
        _humidityValue   = humidity0   != null ? humidity0.toString()   + "%" : "n.d.";
        _precipProbValue = precipProb0 != null ? precipProb0.toString() + "%" : "n.d.";
        _uvValue = uv0 != null ? uv0.format("%.1f") : "n.d.";
        _precipValue = precip0 != null ? precip0 + "mm" : "n.d.";
        _iconaMeteo      = loadWeatherIcon(wcode);
        

        System.println(getTimestamp() + "iconaMeteo null: " + (_iconaMeteo == null));

        WatchUi.requestUpdate();
    }

    // Estrae "HH:MM" da una stringa datetime ISO tipo "2024-01-15T08:30:00"
    function extractTime(dt as String?) as String? {
        if (dt != null && dt.length() >= 16) { return dt.substring(11, 16); }
        return null;
    }


    // ============================================================
    //  BACKEND SISTEMA
    // ============================================================
    function leggiProprietaSlot() as Void {
        _slotSx2 = Application.Properties.getValue("SinistraRiga2") as Number;
        _slotSx3 = Application.Properties.getValue("SinistraRiga3") as Number;
        _slotDx1 = Application.Properties.getValue("DestraRiga1")   as Number;
        _slotDx2 = Application.Properties.getValue("DestraRiga2")   as Number;
        _slotDx3 = Application.Properties.getValue("DestraRiga3")   as Number;
    }



    // dato il numero scelto dall'utente restituisce icona e testo
    function getSlotContentSinistra(tipo as Number) as Dictionary {
        switch (tipo) {
            case 0: return { "icon" => _iconPercPioggia,    "text" => _precipProbValue };
            case 1: return { "icon" => _iconPioggia,        "text" => _precipValue };
            case 2: return { "icon" => _iconUmidita,        "text" => _humidityValue   };
            case 3: return { "icon" => _iconVento,          "text" => _windValue       };
            case 4: return { "icon" => _iconCoperturaCielo, "text" => _copValue        };
            case 5: return { "icon" => _iconUvIndex,        "text" => _uvValue         };
            default: return { "icon" => null,               "text" => null             };
        }
    }

}
