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

    // ── COLORI GRAFICI ───────────────────────────────────────
    var _coloreOre                as Number = ColorPalette.GIALLO;
    var _coloreMinuti             as Number = ColorPalette.CIANO;
    var _coloreRettangolo         as Number = ColorPalette.CIANO;
    var _coloreSfondoBarreArchi   as Number = ColorPalette.GRIGIO_SCURO;
    var _coloreFillBarra1         as Number = ColorPalette.CIANO;
    var _coloreFillBarra2         as Number = ColorPalette.CIANO;
    var _coloreFillBarra3         as Number = ColorPalette.CIANO;
    var _coloreFillAlbaArcoSx     as Number = ColorPalette.GIALLO;
    var _coloreFillTramontoArcoSx as Number = ColorPalette.ARANCIONE;
    var _coloreFillArcoDx         as Number = ColorPalette.VERDE;
    var _coloreFontParametri      as Number = ColorPalette.BIANCO;
    var _coloreFontOraMeteo       as Number = ColorPalette.GRIGIO_CHIARO;
    var _coloreFontCitta          as Number = ColorPalette.BIANCO;
    var _coloreFontGiorno         as Number = ColorPalette.BIANCO;
    var _coloreFontCalendario     as Number = ColorPalette.GRIGIO_CHIARO;

    // ── TEMA ────────────────────────────────────────────────
    var _temaCorrente as Number = 0;
    var _lastWcode    as Number = -1;
    var _tipoIconaMeteo as Number = 1; // 1 default colorata, 0 monocromatica, altrimenti leggo dalle properties

    // ── COLORI ICONE PER POSIZIONE ───────────────────────────
    // Valori: ColorPalette.ICONA_CIANO / GIALLO / LIME / ROSA / BIANCO
    var _coloreIconaMeteo    as Number = ColorPalette.ICONA_CIANO; // s1  — icona meteo principale
    var _coloreIconaSlotSx2  as Number = ColorPalette.ICONA_CIANO; // s2  — slot sinistra riga 2
    var _coloreIconaSlotSx3  as Number = ColorPalette.ICONA_CIANO; // s3  — slot sinistra riga 3
    var _coloreIconaSlotDx1  as Number = ColorPalette.ICONA_CIANO; // d1  — slot destra riga 1
    var _coloreIconaSlotDx2  as Number = ColorPalette.ICONA_CIANO; // d2  — slot destra riga 2
    var _coloreIconaSlotDx3  as Number = ColorPalette.ICONA_CIANO; // d3  — slot destra riga 3
    var _coloreIconaArcoDx   as Number = ColorPalette.ICONA_CIANO; // arcodx  — arco destro (min attività)
    var _coloreIconaAlba     as Number = ColorPalette.ICONA_CIANO; // arcosx1 — icona alba
    var _coloreIconaTramonto as Number = ColorPalette.ICONA_CIANO; // arcosx2 — icona tramonto

    // ── FONT ────────────────────────────────────────────────
    var _myFont  as FontResource or Null = null;
    var _myFont2 as FontResource or Null = null;
    var _myFont3 as FontResource or Null = null;
    var _myFont4 as FontResource or Null = null;
    var _myFont5 as FontResource or Null = null;

    // ── SISTEMA ─────────────────────────────────────────────
    var _functionBackend as FunctionBackend or Null = null;
    var _iconPep         as BitmapResource or Null = null;
    var _iconBluOn       as BitmapResource or Null = null;
    var _iconBluOff      as BitmapResource or Null = null;

    // ── ICONE PER POSIZIONE ──────────────────────────────────
    var _iconaMeteo   as BitmapResource or Null = null; // s1  — meteo principale
    var _iconSlotSx2  as BitmapResource or Null = null; // s2  — slot sinistra riga 2
    var _iconSlotSx3  as BitmapResource or Null = null; // s3  — slot sinistra riga 3
    var _iconSlotDx1  as BitmapResource or Null = null; // d1  — slot destra riga 1
    var _iconSlotDx2  as BitmapResource or Null = null; // d2  — slot destra riga 2
    var _iconSlotDx3  as BitmapResource or Null = null; // d3  — slot destra riga 3
    var _iconMinAttivita as BitmapResource or Null = null; // arcodx — min attività
    var _iconAlba        as BitmapResource or Null = null; // arcosx1 — alba
    var _iconTramonto    as BitmapResource or Null = null; // arcosx2 — tramonto

    // ── DATI METEO ──────────────────────────────────────────
    var _sunrise         as String or Null = null;
    var _sunset          as String or Null = null;
    var _city            as String or Null = null;
    var _weatherTime     as String or Null = null;
    var _windValue       as String or Null = null;
    var _termValue       as String or Null = null;
    var _termPercepita   as String or Null = null;
    var _copValue        as String or Null = null;
    var _humidityValue   as String or Null = null;
    var _precipProbValue as String or Null = null;
    var _uvValue         as String or Null = null;
    var _precipValue     as String or Null = null;

    // ── SLOT ────────────────────────────────────────────────
    var _slotSx2 as Number or Null = null;
    var _slotSx3 as Number or Null = null;
    var _slotDx1 as Number or Null = null;
    var _slotDx2 as Number or Null = null;
    var _slotDx3 as Number or Null = null;

    // ── GOAL ────────────────────────────────────────────────
    var _goalPassi   as Number = 10000;
    var _goalCalorie as Number = 500;
    var _goalGradini as Number = 10;

    // ── GOAL ────────────────────────────────────────────────
    var _colorBatteryHigh  as Number = ColorPalette.VERDE; 
    var _colorBatteryMedium as Number = ColorPalette.GIALLO;
    var _colorBatteryLow as Number = ColorPalette.ROSSO; 

    // ============================================================
    //  INIZIALIZZAZIONE
    // ============================================================

    function initialize() {
        WatchFace.initialize();
        _functionBackend = new FunctionBackend();
    }

    function onLayout(dc as Dc) as Void {
        System.println(getTimestamp() + "MeteoSport.onLayout");

        if (_myFont  == null) { _myFont  = Application.loadResource(Rez.Fonts.FontOra)  as FontResource; }
        if (_myFont2 == null) { _myFont2 = Application.loadResource(Rez.Fonts.FontOra2) as FontResource; }
        if (_myFont3 == null) { _myFont3 = Application.loadResource(Rez.Fonts.FontOra3) as FontResource; }
        if (_myFont4 == null) { _myFont4 = Application.loadResource(Rez.Fonts.FontOra4) as FontResource; }
        if (_myFont5 == null) { _myFont5 = Application.loadResource(Rez.Fonts.FontOra5) as FontResource; }

        if (_iconBluOn  == null) { _iconBluOn  = Application.loadResource(Rez.Drawables.blueOn)  as BitmapResource; }
        if (_iconBluOff == null) { _iconBluOff = Application.loadResource(Rez.Drawables.blueOff) as BitmapResource; }
        if (_iconPep    == null) { _iconPep    = Application.loadResource(Rez.Drawables.Pep)      as BitmapResource; }

        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // ============================================================
    //  FUNZIONI DI SISTEMA
    // ============================================================

    function onShow() as Void {
        leggiProprietaSlot();
        _reloadIcone();

        var coords = _functionBackend.getCoords();
        System.println(getTimestamp() + "MeteoSport.onShow: lat=" + (coords[0] as String) + " lon=" + (coords[1] as String));

        var data = Application.Storage.getValue("meteo") as Dictionary?;
        if (data != null) {
            System.println(getTimestamp() + "MeteoSport.onShow: dati meteo in cache, ripristino");
            onMeteoReceived(data);
        } else {
            System.println(getTimestamp() + "MeteoSport.onShow: nessun dato in cache");
        }
    }

    function onHide() as Void {}

    function onExitSleep() as Void {
        System.println(getTimestamp() + "MeteoSport.onExitSleep");

        var coords = _functionBackend.getCoords();
        Application.Storage.setValue("lat", coords[0] as String);
        Application.Storage.setValue("lon", coords[1] as String);

        var registeredTime = Background.getTemporalEventRegisteredTime() as Time.Moment?;
        if (registeredTime != null) {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: timer già attivo");
        } else {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: registro timer 30 min");
            Background.registerForTemporalEvent(new Time.Duration(30 * 60));
        }

        var data = Application.Storage.getValue("meteo") as Dictionary?;
        if (data != null) {
            System.println(getTimestamp() + "MeteoSport.onExitSleep: dati meteo in cache");
            onMeteoReceived(data);
        }
    }

    function onEnterSleep() as Void {}

    // ============================================================
    //  RICARICA ICONE PER POSIZIONE E COLORE
    // ============================================================

    function _reloadIcone() as Void {
        // s1 — icona meteo principale (gestita da loadWeatherIcon)
        _iconaMeteo = loadWeatherIcon(_lastWcode);

        // s2/s3 — slot sinistra: carica in base al tipo di slot e al colore della posizione
        _iconSlotSx2 = _loadIconSlotSinistra(_slotSx2, _coloreIconaSlotSx2);
        _iconSlotSx3 = _loadIconSlotSinistra(_slotSx3, _coloreIconaSlotSx3);

        // d1/d2/d3 — slot destra: carica in base al tipo di slot e al colore della posizione
        _iconSlotDx1 = _loadIconSlotDestra(_slotDx1, _coloreIconaSlotDx1);
        _iconSlotDx2 = _loadIconSlotDestra(_slotDx2, _coloreIconaSlotDx2);
        _iconSlotDx3 = _loadIconSlotDestra(_slotDx3, _coloreIconaSlotDx3);

        // arcosx1 — icona alba
        _iconAlba = loadIconaPerColore(_coloreIconaAlba,
            Rez.Drawables.AlbaCiano, Rez.Drawables.AlbaGiallo,
            Rez.Drawables.AlbaLime,  Rez.Drawables.AlbaRosa,
            Rez.Drawables.AlbaBianco);

        // arcosx2 — icona tramonto
        _iconTramonto = loadIconaPerColore(_coloreIconaTramonto,
            Rez.Drawables.TramontoCiano, Rez.Drawables.TramontoGiallo,
            Rez.Drawables.TramontoLime,  Rez.Drawables.TramontoRosa,
            Rez.Drawables.TramontoBianco);

        // arcodx — icona minuti attività
        _iconMinAttivita = loadIconaPerColore(_coloreIconaArcoDx,
            Rez.Drawables.MinAttivitaCiano, Rez.Drawables.MinAttivitaGiallo,
            Rez.Drawables.MinAttivitaLime,  Rez.Drawables.MinAttivitaRosa,
            Rez.Drawables.MinAttivitaBianco);
    }

    // Carica l'icona per uno slot sinistra dato il tipo e il colore della posizione
    function _loadIconSlotSinistra(slotType as Number, colore as Number) as BitmapResource? {
        switch (slotType) {
            case 0: return loadIconaPerColore(colore,
                Rez.Drawables.PercPioggiaCiano, Rez.Drawables.PercPioggiaGiallo,
                Rez.Drawables.PercPioggiaLime,  Rez.Drawables.PercPioggiaRosa,
                Rez.Drawables.PercPioggiaBianco);
            case 1: return loadIconaPerColore(colore,
                Rez.Drawables.PioggiaCiano, Rez.Drawables.PioggiaGiallo,
                Rez.Drawables.PioggiaLime,  Rez.Drawables.PioggiaRosa,
                Rez.Drawables.PioggiaBianco);
            case 2: return loadIconaPerColore(colore,
                Rez.Drawables.UmiditaCiano, Rez.Drawables.UmiditaGiallo,
                Rez.Drawables.UmiditaLime,  Rez.Drawables.UmiditaRosa,
                Rez.Drawables.UmiditaBianco);
            case 3: return loadIconaPerColore(colore,
                Rez.Drawables.VentoCiano, Rez.Drawables.VentoGiallo,
                Rez.Drawables.VentoLime,  Rez.Drawables.VentoRosa,
                Rez.Drawables.VentoBianco);
            case 4: return loadIconaPerColore(colore,
                Rez.Drawables.CoperturaCieloCiano, Rez.Drawables.CoperturaCieloGiallo,
                Rez.Drawables.CoperturaCieloLime,  Rez.Drawables.CoperturaCieloRosa,
                Rez.Drawables.CoperturaCieloBianco);
            case 5: return loadIconaPerColore(colore,
                Rez.Drawables.UvIndexCiano, Rez.Drawables.UvIndexGiallo,
                Rez.Drawables.UvIndexLime,  Rez.Drawables.UvIndexRosa,
                Rez.Drawables.UvIndexBianco);
            default: return null;
        }
    }

    // Carica l'icona per uno slot destra dato il tipo e il colore della posizione
    function _loadIconSlotDestra(slotType as Number, colore as Number) as BitmapResource? {
        switch (slotType) {
            case 0: return loadIconaPerColore(colore,
                Rez.Drawables.CalorieCiano, Rez.Drawables.CalorieGiallo,
                Rez.Drawables.CalorieLime,  Rez.Drawables.CalorieRosa,
                Rez.Drawables.CalorieBianco);
            case 1: return loadIconaPerColore(colore,
                Rez.Drawables.FootCiano, Rez.Drawables.FootGiallo,
                Rez.Drawables.FootLime,  Rez.Drawables.FootRosa,
                Rez.Drawables.FootBianco);
            case 2: return loadIconaPerColore(colore,
                Rez.Drawables.GradiniCiano, Rez.Drawables.GradiniGiallo,
                Rez.Drawables.GradiniLime,  Rez.Drawables.GradiniRosa,
                Rez.Drawables.GradiniBianco);
            case 3: return loadIconaPerColore(colore,
                Rez.Drawables.BodyBatteryCiano, Rez.Drawables.BodyBatteryGiallo,
                Rez.Drawables.BodyBatteryLime,  Rez.Drawables.BodyBatteryRosa,
                Rez.Drawables.BodyBatteryBianco);
            default: return null;
        }
    }

    // ============================================================
    //  DISEGNO PRINCIPALE — onUpdate
    // ============================================================

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var rectW    = 90;
        var rectH    = 150;
        var leftX    = 57;
        var leftY    = 65;
        var leftOff  = 5;
        var rowGap   = 40;
        var rightX   = 178;
        var rightY   = 63;
        var rightOff = 5;
        var barLen   = 60;
        var arcX     = 55;
        var arcY     = 205;
        var arcLabel = 14;

        drawOra(dc, 130, 90, _myFont);
        drawMin(dc, 130, 170, _myFont);
        drawDataOrizz(dc, 130, 130, _myFont4, _myFont3, _myFont2);

        dc.setColor(_coloreRettangolo, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(130 - rectW / 2, 130 - rectH / 2, rectW, rectH, 20);

        // fascia alta
        dc.setColor(_coloreFontOraMeteo, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 20, _myFont5, _weatherTime,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(_coloreFontCitta, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 40, _myFont3, _city,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_iconPep != null) {
            dc.drawBitmap(202 - _iconPep.getWidth() / 2,
                          40  - _iconPep.getHeight() / 2, _iconPep);
        }

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

        // s1 — icona meteo + temperature
        if (_iconaMeteo != null) {
            dc.drawBitmap(leftX, leftY, _iconaMeteo);
        }
        dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX - leftOff, leftY,
            Graphics.FONT_XTINY, _termValue,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_RIGHT);

        var tempNum = _termPercepita != null ? _termPercepita.toNumber() : 0;
        if (tempNum > 25) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(leftX - leftOff, leftY + 5 + _iconaMeteo.getHeight() / 2,
            Graphics.FONT_XTINY, tempNum + "°",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_RIGHT);

        // s2/s3 — slot sinistra
        drawLeftColumn(dc, leftX, leftY + rowGap,     leftOff, _slotSx2, _iconSlotSx2);
        drawLeftColumn(dc, leftX, leftY + 2 * rowGap, leftOff, _slotSx3, _iconSlotSx3);

        // d1/d2/d3 — slot destra
        drawRigthColumn(dc, rightX, rightY,              rightOff, _slotDx1, barLen,    1, _iconSlotDx1);
        drawRigthColumn(dc, rightX, rightY + rowGap,     rightOff, _slotDx2, barLen+10, 2, _iconSlotDx2);
        drawRigthColumn(dc, rightX, rightY + 2 * rowGap, rightOff, _slotDx3, barLen,   3, _iconSlotDx3);

        // arcosx — alba/tramonto
        var info       = minutiMancantiEvento(_sunrise, _sunset);
        var minuti     = info["minuti"] as Number;
        var goal       = info["goal"]   as Number;
        var evento     = info["evento"] as String;
        var valoreDraw = goal - minuti;

        var colFill   = evento.equals("alba") ? _coloreFillAlbaArcoSx   : _coloreSfondoBarreArchi;
        var colSfondo = evento.equals("alba") ? _coloreSfondoBarreArchi  : _coloreFillTramontoArcoSx;

        drawCerchioAttivitaPunti(dc, arcX, arcY, valoreDraw, goal, 0, -90, false,
            { "raggio"      => 20,
              "raggioPunto" => 2,
              "segmenti"    => Math.ceil(goal.toFloat() / 60.0f).toNumber(),
              "sfondo"      => colFill,
              "fill"        => colSfondo });

        if (evento.equals("alba")) {
            if (_iconAlba != null) {
                dc.drawBitmap(arcX - _iconAlba.getWidth()  / 2,
                              arcY - _iconAlba.getHeight() / 2, _iconAlba);
                dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
                dc.drawText(arcX + arcLabel, arcY + arcLabel,
                    Graphics.FONT_XTINY, _sunrise,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            if (_iconTramonto != null) {
                dc.drawBitmap(arcX - _iconTramonto.getWidth()  / 2,
                              arcY - _iconTramonto.getHeight() / 2, _iconTramonto);
                dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
                dc.drawText(arcX + arcLabel, arcY + arcLabel,
                    Graphics.FONT_XTINY, _sunset,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // arcodx — minuti attività
        var arcXDx = 130 + (130 - arcX);

        drawCerchioAttivitaTrattini(dc, arcXDx, arcY,
            getActiveMinutesWeek(), 300, 180, 270, true,
            { "raggio" => 20, "spessore" => 4, "segmenti" => 8,
              "gap" => 4, "sfondo" => _coloreSfondoBarreArchi,
              "fill" => _coloreFillArcoDx });

        if (_iconMinAttivita != null) {
            dc.drawBitmap(arcXDx - _iconMinAttivita.getWidth()  / 2,
                          arcY   - _iconMinAttivita.getHeight() / 2, _iconMinAttivita);
            dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
            dc.drawText(130 + arcX, arcY + arcLabel,
                Graphics.FONT_XTINY, getActiveMinutesWeek(),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        drawBatteria(dc, 130, 245, _myFont5);
    }

    // ============================================================
    //  FUNZIONI DI DISEGNO
    // ============================================================

    function drawOra(dc as Dc, x as Number, y as Number, font as FontResource) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) { hours = hours - 12; }
        }
        dc.setColor(_coloreOre, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, hours.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawMin(dc as Dc, x as Number, y as Number, font as FontResource) as Void {
        var clockTime = System.getClockTime();
        dc.setColor(_coloreMinuti, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, clockTime.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

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
        var spacing  = 4;

        var wDayName  = dc.getTextDimensions(dayName,  fontGiorno)[0];
        var wDayNum   = dc.getTextDimensions(dayNum,   fontNum)[0];
        var wMonthStr = dc.getTextDimensions(monthStr, fontMese)[0];

        var totalW = wDayName + spacing + wDayNum + spacing + wMonthStr;
        var startX = x - totalW / 2;

        dc.setColor(_coloreFontCalendario, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, fontGiorno, dayName,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(_coloreFontGiorno, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + wDayName + spacing, y, fontNum, dayNum,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(_coloreFontCalendario, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + wDayName + spacing + wDayNum + spacing, y, fontMese, monthStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawBatteria(dc as Dc, cx as Number, cy as Number, font as FontResource) as Void {
        var batW  = 30;
        var batH  = 12;
        var stats = System.getSystemStats();
        var level = stats.battery;
        var text  = level.format("%d") + "%";

        var textW  = dc.getTextWidthInPixels(text, font);
        var totalW = batW + 3 + 8 + textW;
        var batX   = cx - (totalW / 2);
        var batY   = cy - (batH / 2);

        var batColor = _colorBatteryHigh;
        if      (level <= 20) { batColor = _colorBatteryLow;    }
        else if (level <= 50) { batColor = _colorBatteryMedium; }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(batX, batY, batW, batH, 2);
        dc.fillRoundedRectangle(batX + batW, batY + 3, 3, 6, 1);

        var fillW = ((batW - 4) * level / 100).toNumber();
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(batX + 2, batY + 2, fillW, batH - 4, 1);

        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(batX + batW + 3 + 8, cy, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ── BARRE DI PROGRESSO ───────────────────────────────────────

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

        dc.setColor(colori["sfondo"], colori["sfondo"]);
        dc.fillRoundedRectangle(x, y, lunghezza, spessore, raggio);

        if (fillW > 0) {
            dc.setColor(colori["fill"], colori["fill"]);
            if (rtl) {
                dc.fillRoundedRectangle(x + lunghezza - fillW, y, fillW, spessore, raggio);
            } else {
                dc.fillRoundedRectangle(x, y, fillW, spessore, raggio);
            }
        }
    }

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

        var stepDeg = totalDeg.toFloat() / nTacche;
        for (var i = 0; i <= nTacche; i++) {
            var taccaDeg = cw
                ? (starDeg - i * stepDeg).toNumber()
                : (starDeg + i * stepDeg).toNumber();
            var rad  = Math.toRadians(taccaDeg);
            var cosA = Math.cos(rad);
            var sinA = Math.sin(rad);
            var r1   = raggio - lunghezza / 2;
            var r2   = raggio + lunghezza / 2;
            dc.setColor(cfg["colTacca"], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine((cx + r1 * cosA).toNumber(), (cy - r1 * sinA).toNumber(),
                        (cx + r2 * cosA).toNumber(), (cy - r2 * sinA).toNumber());
        }
    }

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
        var offset      = stepDeg / 2.0f;

        for (var i = 0; i < nPunti; i++) {
            var puntoDeg = cw
                ? (starDeg - offset - i * stepDeg).toNumber()
                : (starDeg + offset + i * stepDeg).toNumber();
            var rad = Math.toRadians(puntoDeg);
            var px  = (cx + raggio * Math.cos(rad)).toNumber();
            var py  = (cy - raggio * Math.sin(rad)).toNumber();
            var colore = (i < filledPunti) ? cfg["fill"] as Number : cfg["sfondo"] as Number;
            dc.setColor(colore, colore);
            dc.fillCircle(px, py, rPunto);
        }
    }

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
            diff   = minAlba - minCorrente;
            goal   = 1440 - minTramonto + minAlba;
            evento = "alba";
        } else if (minCorrente < minTramonto) {
            diff   = minTramonto - minCorrente;
            goal   = minTramonto - minAlba;
            evento = "tramonto";
        } else {
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

    // Disegna colonna sinistra — icona pre-caricata passata come parametro
    function drawLeftColumn(dc as Dc, positionIconX as Number, positionIconY as Number,
                            leftOffset as Number, slotType as Number,
                            iconPreloaded as BitmapResource?) as Void {
        var contenuto = getSlotContentSinistra(slotType, iconPreloaded);
        var icon = contenuto["icon"] as BitmapResource?;
        var text = contenuto["text"] as String?;

        System.println(getTimestamp() + "MeteoSport.drawLeftColumn " + text + " scelta:" + slotType);

        if (icon == null || text == null) { return; }

        dc.drawBitmap(positionIconX, positionIconY, icon);
        dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
        dc.drawText(positionIconX - leftOffset, positionIconY + icon.getHeight() / 2,
            Graphics.FONT_SYSTEM_XTINY, text,
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Disegna colonna destra — icona pre-caricata passata come parametro
    function drawRigthColumn(dc as Dc, positionIconX as Number, positionIconY as Number,
                             rightOff as Number, slotType as Number,
                             barLen as Number, riga as Number,
                             iconPreloaded as BitmapResource?) as Void {
        var contenuto = getSlotContentDestra(slotType, iconPreloaded);
        var icon = contenuto["icon"] as BitmapResource?;
        var text = contenuto["text"] as Number?;
        var goal = contenuto["goal"] as Number?;
        var rtl  = false;
        var fill = null;

        System.println(getTimestamp() + "MeteoSport.drawRightColumn " + text + " scelta:" + slotType);

        if (icon == null || text == null) { return; }

        dc.drawBitmap(positionIconX, positionIconY, icon);
        dc.setColor(_coloreFontParametri, Graphics.COLOR_TRANSPARENT);
        dc.drawText(positionIconX + icon.getWidth() + rightOff, positionIconY + 8,
            Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_LEFT);

        if (riga == 1) {
            fill = _coloreFillBarra1;
        } else if (riga == 2) {
            fill = _coloreFillBarra2;
        } else {
            fill = _coloreFillBarra3;
        }

        if (goal <= 10) {
            drawSegmentoProgressTrattini(dc, positionIconX, positionIconY + 28, barLen, 3,
                text, goal,
                { "sfondo" => _coloreSfondoBarreArchi, "fill" => fill,
                  "segmenti" => goal, "gap" => 1 }, rtl);
        } else {
            drawSegmentoProgress(dc, positionIconX, positionIconY + 28, barLen, 3,
                text, goal,
                { "sfondo" => _coloreSfondoBarreArchi, "fill" => fill }, rtl);
        }
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
        var iter = SensorHistory.getBodyBatteryHistory({
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

    function loadWeatherIcon(code as Number?) as BitmapResource? {
        var iconId = Rez.Drawables.wiNaCiano;
        var colore = _coloreIconaMeteo;

    // ── ICONE GOOGLE COLORATE ────────────────────────────────
    if (_tipoIconaMeteo == 1) {
        if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyColored;         }
        else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastColored; }
        else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyColored;        }
        else if (code == 3)  { iconId = Rez.Drawables.wiCloudyColored;           }
        else if (code == 45) { iconId = Rez.Drawables.wiDayFogColored;           }
        else if (code == 48) { iconId = Rez.Drawables.wiDayHazeColored;          }
        else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleColored;      }
        else if (code == 53) { iconId = Rez.Drawables.wiSprinkleColored;         }
        else if (code == 55) { iconId = Rez.Drawables.wiRainMixColored;          }
        else if (code == 61) { iconId = Rez.Drawables.wiDayRainColored;          }
        else if (code == 63) { iconId = Rez.Drawables.wiRainColored;             }
        else if (code == 65) { iconId = Rez.Drawables.wiRainWindColored;         }
        else if (code == 71) { iconId = Rez.Drawables.wiDaySnowColored;          }
        else if (code == 73) { iconId = Rez.Drawables.wiSnowColored;             }
        else if (code == 75) { iconId = Rez.Drawables.wiSnowWindColored;         }
        else if (code == 80) { iconId = Rez.Drawables.wiDayShowersColored;       }
        else if (code == 81) { iconId = Rez.Drawables.wiShowersColored;          }
        else if (code == 82) { iconId = Rez.Drawables.wiStormShowersColored;     }
        else if (code == 95) { iconId = Rez.Drawables.wiThunderstormColored;     }
        else                 { iconId = Rez.Drawables.wiNaCiano;                 }
        return Application.loadResource(iconId) as BitmapResource;
    }

        if (colore == ColorPalette.ICONA_GIALLO) {
            if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyGiallo;         }
            else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastGiallo; }
            else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyGiallo;        }
            else if (code == 3)  { iconId = Rez.Drawables.wiCloudyGiallo;           }
            else if (code == 45) { iconId = Rez.Drawables.wiDayFogGiallo;           }
            else if (code == 48) { iconId = Rez.Drawables.wiDayHazeGiallo;          }
            else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleGiallo;      }
            else if (code == 53) { iconId = Rez.Drawables.wiSprinkleGiallo;         }
            else if (code == 55) { iconId = Rez.Drawables.wiRainMixGiallo;          }
            else if (code == 61) { iconId = Rez.Drawables.wiDayRainGiallo;          }
            else if (code == 63) { iconId = Rez.Drawables.wiRainGiallo;             }
            else if (code == 65) { iconId = Rez.Drawables.wiRainWindGiallo;         }
            else if (code == 71) { iconId = Rez.Drawables.wiDaySnowGiallo;          }
            else if (code == 73) { iconId = Rez.Drawables.wiSnowGiallo;             }
            else if (code == 75) { iconId = Rez.Drawables.wiSnowWindGiallo;         }
            else if (code == 80) { iconId = Rez.Drawables.wiDayShowersGiallo;       }
            else if (code == 81) { iconId = Rez.Drawables.wiShowersGiallo;          }
            else if (code == 82) { iconId = Rez.Drawables.wiStormShowersGiallo;     }
            else if (code == 95) { iconId = Rez.Drawables.wiThunderstormGiallo;     }
            else                 { iconId = Rez.Drawables.wiNaGiallo;               }

        } else if (colore == ColorPalette.ICONA_LIME) {
            if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyLime;         }
            else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastLime; }
            else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyLime;        }
            else if (code == 3)  { iconId = Rez.Drawables.wiCloudyLime;           }
            else if (code == 45) { iconId = Rez.Drawables.wiDayFogLime;           }
            else if (code == 48) { iconId = Rez.Drawables.wiDayHazeLime;          }
            else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleLime;      }
            else if (code == 53) { iconId = Rez.Drawables.wiSprinkleLime;         }
            else if (code == 55) { iconId = Rez.Drawables.wiRainMixLime;          }
            else if (code == 61) { iconId = Rez.Drawables.wiDayRainLime;          }
            else if (code == 63) { iconId = Rez.Drawables.wiRainLime;             }
            else if (code == 65) { iconId = Rez.Drawables.wiRainWindLime;         }
            else if (code == 71) { iconId = Rez.Drawables.wiDaySnowLime;          }
            else if (code == 73) { iconId = Rez.Drawables.wiSnowLime;             }
            else if (code == 75) { iconId = Rez.Drawables.wiSnowWindLime;         }
            else if (code == 80) { iconId = Rez.Drawables.wiDayShowersLime;       }
            else if (code == 81) { iconId = Rez.Drawables.wiShowersLime;          }
            else if (code == 82) { iconId = Rez.Drawables.wiStormShowersLime;     }
            else if (code == 95) { iconId = Rez.Drawables.wiThunderstormLime;     }
            else                 { iconId = Rez.Drawables.wiNaLime;               }

        } else if (colore == ColorPalette.ICONA_ROSA) {
            if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyRosa;         }
            else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastRosa; }
            else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyRosa;        }
            else if (code == 3)  { iconId = Rez.Drawables.wiCloudyRosa;           }
            else if (code == 45) { iconId = Rez.Drawables.wiDayFogRosa;           }
            else if (code == 48) { iconId = Rez.Drawables.wiDayHazeRosa;          }
            else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleRosa;      }
            else if (code == 53) { iconId = Rez.Drawables.wiSprinkleRosa;         }
            else if (code == 55) { iconId = Rez.Drawables.wiRainMixRosa;          }
            else if (code == 61) { iconId = Rez.Drawables.wiDayRainRosa;          }
            else if (code == 63) { iconId = Rez.Drawables.wiRainRosa;             }
            else if (code == 65) { iconId = Rez.Drawables.wiRainWindRosa;         }
            else if (code == 71) { iconId = Rez.Drawables.wiDaySnowRosa;          }
            else if (code == 73) { iconId = Rez.Drawables.wiSnowRosa;             }
            else if (code == 75) { iconId = Rez.Drawables.wiSnowWindRosa;         }
            else if (code == 80) { iconId = Rez.Drawables.wiDayShowersRosa;       }
            else if (code == 81) { iconId = Rez.Drawables.wiShowersRosa;          }
            else if (code == 82) { iconId = Rez.Drawables.wiStormShowersRosa;     }
            else if (code == 95) { iconId = Rez.Drawables.wiThunderstormRosa;     }
            else                 { iconId = Rez.Drawables.wiNaRosa;               }

        } else if (colore == ColorPalette.ICONA_BIANCO) {
            if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyBianco;         }
            else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastBianco; }
            else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyBianco;        }
            else if (code == 3)  { iconId = Rez.Drawables.wiCloudyBianco;           }
            else if (code == 45) { iconId = Rez.Drawables.wiDayFogBianco;           }
            else if (code == 48) { iconId = Rez.Drawables.wiDayHazeBianco;          }
            else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleBianco;      }
            else if (code == 53) { iconId = Rez.Drawables.wiSprinkleBianco;         }
            else if (code == 55) { iconId = Rez.Drawables.wiRainMixBianco;          }
            else if (code == 61) { iconId = Rez.Drawables.wiDayRainBianco;          }
            else if (code == 63) { iconId = Rez.Drawables.wiRainBianco;             }
            else if (code == 65) { iconId = Rez.Drawables.wiRainWindBianco;         }
            else if (code == 71) { iconId = Rez.Drawables.wiDaySnowBianco;          }
            else if (code == 73) { iconId = Rez.Drawables.wiSnowBianco;             }
            else if (code == 75) { iconId = Rez.Drawables.wiSnowWindBianco;         }
            else if (code == 80) { iconId = Rez.Drawables.wiDayShowersBianco;       }
            else if (code == 81) { iconId = Rez.Drawables.wiShowersBianco;          }
            else if (code == 82) { iconId = Rez.Drawables.wiStormShowersBianco;     }
            else if (code == 95) { iconId = Rez.Drawables.wiThunderstormBianco;     }
            else                 { iconId = Rez.Drawables.wiNaBianco;               }

        } else {
            // ICONA_CIANO (default)
            if      (code == 0)  { iconId = Rez.Drawables.wiDaySunnyCiano;         }
    else if (code == 1)  { iconId = Rez.Drawables.wiDaySunnyOvercastCiano; }
    else if (code == 2)  { iconId = Rez.Drawables.wiDayCloudyCiano;        }
    else if (code == 3)  { iconId = Rez.Drawables.wiCloudyCiano;           }
    else if (code == 45) { iconId = Rez.Drawables.wiDayFogCiano;           }
    else if (code == 48) { iconId = Rez.Drawables.wiDayHazeCiano;          }
    else if (code == 51) { iconId = Rez.Drawables.wiDaySprinkleCiano;      }
    else if (code == 53) { iconId = Rez.Drawables.wiSprinkleCiano;         }
    else if (code == 55) { iconId = Rez.Drawables.wiRainMixCiano;          }
    else if (code == 61) { iconId = Rez.Drawables.wiDayRainCiano;          }
    else if (code == 63) { iconId = Rez.Drawables.wiRainCiano;             }
    else if (code == 65) { iconId = Rez.Drawables.wiRainWindCiano;         }
    else if (code == 71) { iconId = Rez.Drawables.wiDaySnowCiano;          }
    else if (code == 73) { iconId = Rez.Drawables.wiSnowCiano;             }
    else if (code == 75) { iconId = Rez.Drawables.wiSnowWindCiano;         }
    else if (code == 80) { iconId = Rez.Drawables.wiDayShowersCiano;       }
    else if (code == 81) { iconId = Rez.Drawables.wiShowersCiano;          }
    else if (code == 82) { iconId = Rez.Drawables.wiStormShowersCiano;     }
    else if (code == 95) { iconId = Rez.Drawables.wiThunderstormCiano;     }
    else                 { iconId = Rez.Drawables.wiNaCiano;               }
        }

        return Application.loadResource(iconId) as BitmapResource;
    }

    function onMeteoReceived(data as Dictionary?) as Void {
        System.println(getTimestamp() + "MeteoSport.onMeteoReceived");

        if (data == null) {
            System.println(getTimestamp() + "MeteoSport.onMeteoReceived: nessun dato");
            return;
        }

        var raw = data.get("city") as String?;
        _city    = (raw != null && raw.length() > 10) ? raw.substring(0, 8) + "." : raw;
        _sunrise = extractTime(data.get("sunrise") as String?);
        _sunset  = extractTime(data.get("sunset")  as String?);

        var forecast = data.get("forecast") as Array?;
        if (forecast == null || forecast.size() == 0) {
            WatchUi.requestUpdate();
            return;
        }

        var e           = forecast[0] as Dictionary;
        var wcode       = e.get("weather_code")         as Number?;
        var temp0       = e.get("temperature")          as Number?;
        var perc0       = e.get("apparent_temperature") as Number?;
        var wind0       = e.get("wind_speed")           as Number?;
        var cloud0      = e.get("cloud_cover")          as Number?;
        var humidity0   = e.get("humidity")             as Number?;
        var precipProb0 = e.get("precip_probability")   as Number?;
        var uv0         = e.get("uv_index")             as Float?;
        var precip0     = e.get("precipitation")        as String?;

        _lastWcode = wcode != null ? wcode : -1;

        System.println(getTimestamp() + "weather_code: " + wcode);

        _weatherTime     = extractTime(e.get("time") as String?);
        _termValue       = temp0      != null ? temp0.toString()      + "°"  : "n.d.";
        _termPercepita   = perc0      != null ? perc0.toString()      + "°"  : "n.d.";
        _windValue       = wind0      != null ? wind0.toString()      + "ms" : "n.d.";
        _copValue        = cloud0     != null ? cloud0.toString()     + "%"  : "n.d.";
        _humidityValue   = humidity0  != null ? humidity0.toString()  + "%"  : "n.d.";
        _precipProbValue = precipProb0 != null ? precipProb0.toString() + "%" : "n.d.";
        _uvValue         = uv0        != null ? uv0.format("%.1f")         : "n.d.";
        _precipValue     = precip0    != null ? precip0 + "mm"             : "n.d.";
        _iconaMeteo      = loadWeatherIcon(wcode);

        System.println(getTimestamp() + "iconaMeteo null: " + (_iconaMeteo == null));

        WatchUi.requestUpdate();
    }

    function extractTime(dt as String?) as String? {
        if (dt != null && dt.length() >= 16) { return dt.substring(11, 16); }
        return null;
    }

    // ============================================================
    //  BACKEND SISTEMA
    // ============================================================

    function leggiProprietaSlot() as Void {
        // parametri slot
        _slotSx2 = Application.Properties.getValue("SinistraRiga2") as Number;
        _slotSx3 = Application.Properties.getValue("SinistraRiga3") as Number;
        _slotDx1 = Application.Properties.getValue("DestraRiga1")   as Number;
        _slotDx2 = Application.Properties.getValue("DestraRiga2")   as Number;
        _slotDx3 = Application.Properties.getValue("DestraRiga3")   as Number;

        // goal
        _goalPassi   = Application.Properties.getValue("GoalPassi")   as Number;
        _goalCalorie = Application.Properties.getValue("GoalCalorie") as Number;
        _goalGradini = Application.Properties.getValue("GoalGradini") as Number;

        // tema
        _temaCorrente = Application.Properties.getValue("temaIcone") as Number;

        if (_temaCorrente == 0) { //DEFAULT
            // ── TEMA CIANO (default) — legge le singole property ──────────
            _coloreOre                = Application.Properties.getValue("coloreOre")                as Number;
            _coloreMinuti             = Application.Properties.getValue("coloreMinuti")             as Number;
            _coloreRettangolo         = Application.Properties.getValue("coloreRettangolo")         as Number;
            _coloreSfondoBarreArchi   = Application.Properties.getValue("coloreSfondoBarreArchi")   as Number;
            _coloreFillBarra1         = Application.Properties.getValue("coloreFillBarra1")         as Number;
            _coloreFillBarra2         = Application.Properties.getValue("coloreFillBarra2")         as Number;
            _coloreFillBarra3         = Application.Properties.getValue("coloreFillBarra3")         as Number;
            _coloreFillAlbaArcoSx     = Application.Properties.getValue("coloreFillAlbaArcoSx")     as Number;
            _coloreFillTramontoArcoSx = Application.Properties.getValue("coloreFillTramontoArcoSx") as Number;
            _coloreFillArcoDx         = Application.Properties.getValue("coloreFillArcoDx")         as Number;
            _coloreFontParametri      = Application.Properties.getValue("coloreFontParametri")      as Number;
            _coloreFontOraMeteo       = Application.Properties.getValue("coloreFontOraMeteo")       as Number;
            _coloreFontCitta          = Application.Properties.getValue("coloreFontCitta")          as Number;
            _coloreFontGiorno         = Application.Properties.getValue("coloreFontGiorno")         as Number;
            _coloreFontCalendario     = Application.Properties.getValue("coloreFontCalendario")     as Number;
           
            
             // Gestione icona METEO
            _tipoIconaMeteo = 1; // sempre colorata viene ignorata la riga di default sotto perchè loadWeatherIcon esce subito
            // ...colori grafici...
            _coloreIconaMeteo = ColorPalette.ICONA_CIANO; //viene ignorata e 
           
            
             // colori icone — tutte ciano (default)
            _coloreIconaSlotSx2  = ColorPalette.ICONA_CIANO;
            _coloreIconaSlotSx3  = ColorPalette.ICONA_CIANO;
            _coloreIconaSlotDx1  = ColorPalette.ICONA_CIANO;
            _coloreIconaSlotDx2  = ColorPalette.ICONA_CIANO;
            _coloreIconaSlotDx3  = ColorPalette.ICONA_CIANO;
            _coloreIconaArcoDx   = ColorPalette.ICONA_CIANO;
            _coloreIconaAlba     = ColorPalette.ICONA_CIANO;
            _coloreIconaTramonto = ColorPalette.ICONA_CIANO;

            
            //battery
            _colorBatteryHigh     = ColorPalette.VERDE;
            _colorBatteryMedium  = ColorPalette.GIALLO;
            _colorBatteryLow  = ColorPalette.ROSSO;

        } else if (_temaCorrente == 1) {
            // ── TEMA SUMMER ───────────────────────────────────────────────
            _tipoIconaMeteo = Application.Properties.getValue("tipoIconaMeteo") as Number; // sempre colorata viene ignorata la riga di default sotto perchè loadWeatherIcon esce subito            
            _coloreOre                = 0xFFFFAA;
            _coloreMinuti             = 0xFFAA00;
            _coloreRettangolo         = 0xFFFF00;
            _coloreFillBarra1         = 0xFFFF00;
            _coloreFillBarra2         = 0xFFFF00;
            _coloreFillBarra3         = 0xFFFF00;
            _coloreFillAlbaArcoSx     = 0xFFFF55;
            _coloreFillTramontoArcoSx = 0xFFFF00;
            _coloreFillArcoDx         = 0xFFFF00;
            //_coloreSfondoBarreArchi   = 0x555555;

            _coloreSfondoBarreArchi = 0xFF5500;

            _coloreFontParametri      = 0xFFFFFF;
            _coloreFontOraMeteo       = 0xFFFFFF;
            _coloreFontCitta          = 0xFFFFAA;
            _coloreFontGiorno         = 0xFFFFFF;
            _coloreFontCalendario     = 0xFFFFFF;
            // colori icone per posizione — personalizza qui
            
            _coloreIconaMeteo    = ColorPalette.ICONA_BIANCO;  // s1  icona meteo

            _coloreIconaSlotSx2  = ColorPalette.ICONA_GIALLO;   // s2  neutro
            _coloreIconaSlotSx3  = ColorPalette.ICONA_GIALLO;   // s3  neutro
            _coloreIconaSlotDx1  = ColorPalette.ICONA_GIALLO;  // d1
            _coloreIconaSlotDx2  = ColorPalette.ICONA_GIALLO;  // d2
            _coloreIconaSlotDx3  = ColorPalette.ICONA_GIALLO;  // d3
            _coloreIconaArcoDx   = ColorPalette.ICONA_GIALLO;  // arcodx  min attività
            _coloreIconaAlba     = ColorPalette.ICONA_GIALLO;  // arcosx1 alba
            _coloreIconaTramonto = ColorPalette.ICONA_BIANCO;  // arcosx2 tramonto

            //battery
            _colorBatteryHigh     = 0xFFFF00;
            _colorBatteryMedium  = 0xFFAA00;
            _colorBatteryLow  = 0xFF0000;            
 
        } else if (_temaCorrente == 2) { 
            // ── TEMA MARINE ─────────────────────────────────────────────────
            _tipoIconaMeteo = Application.Properties.getValue("tipoIconaMeteo") as Number; // sempre colorata viene ignorata la riga di default sotto perchè loadWeatherIcon esce subito
            _coloreOre                = 0x00FFFF;
            _coloreMinuti             = 0xFFFFFF;
            _coloreRettangolo         = 0x00FFFF;
            _coloreFillBarra1         = 0x00FFFF;
            _coloreFillBarra2         = 0x00FFFF;
            _coloreFillBarra3         = 0x00FFFF;
            _coloreFillAlbaArcoSx     = 0x00FFFF;
            _coloreFillTramontoArcoSx = 0xFFFFFF;
            _coloreFillArcoDx         = 0x00FFFF;
            _coloreSfondoBarreArchi   = 0x0000AA;
            _coloreFontParametri      = 0xFFFFFF;
            _coloreFontOraMeteo       = 0xFFFFFF;
            _coloreFontCitta          = 0x55FFFF;
            _coloreFontGiorno         = 0xFFFFFF;
            _coloreFontCalendario     = 0xFFFFFF;
            
            // Gestione icona METEO
            
            // ...colori grafici...
            _coloreIconaMeteo = ColorPalette.ICONA_BIANCO; //viene ignorata e 
            
            // colori icone per posizione — personalizza qui
            
            _coloreIconaSlotSx2  = ColorPalette.ICONA_CIANO;  // s2  neutro
            _coloreIconaSlotSx3  = ColorPalette.ICONA_CIANO;  // s3  neutro
            _coloreIconaSlotDx1  = ColorPalette.ICONA_CIANO;  // d1
            _coloreIconaSlotDx2  = ColorPalette.ICONA_CIANO;  // d2
            _coloreIconaSlotDx3  = ColorPalette.ICONA_CIANO;  // d3
            _coloreIconaArcoDx   = ColorPalette.ICONA_CIANO;  // arcodx  min attività
            _coloreIconaAlba     = ColorPalette.ICONA_BIANCO; // arcosx1 alba — giallo per sole
            _coloreIconaTramonto = ColorPalette.ICONA_CIANO;  // arcosx2 tramonto
            //battery
            _colorBatteryHigh     = 0x00AAFF;
            _colorBatteryMedium  = 0x00FFFF;
            _colorBatteryLow  = 0xFFFFFF;

        } else if (_temaCorrente == 3) {
            // ── TEMA ROSA ─────────────────────────────────────────────────
            _tipoIconaMeteo = Application.Properties.getValue("tipoIconaMeteo") as Number; // sempre colorata viene ignorata la riga di default sotto perchè loadWeatherIcon esce subito
            _coloreRettangolo = 0xFF0055;
            _coloreOre = 0xFFFFFF;
            _coloreMinuti = 0xFF0055;
            _coloreFillBarra1 = 0xFF55FF;
            _coloreFillBarra2 = 0xFF55FF;
            _coloreFillBarra3 = 0xFF55FF;
            _coloreFillAlbaArcoSx = 0xFF55FF;
            _coloreFillTramontoArcoSx = 0xFF55FF;
            _coloreIconaTramonto = ColorPalette.ICONA_BIANCO;
            _coloreIconaAlba = ColorPalette.ICONA_ROSA;
            _coloreFillArcoDx = 0xFF55FF;
            _coloreIconaArcoDx = ColorPalette.ICONA_ROSA;
            _coloreSfondoBarreArchi  = 0xAA00FF;
            _coloreFontGiorno = 0xFFFFFF;
            _coloreFontParametri = 0xFFAAFF;
            _coloreFontOraMeteo = 0xFFAAFF;
            _coloreFontCalendario = 0xFFFFFF;
            _coloreFontCitta = 0xFF55AA;
            _coloreIconaMeteo = ColorPalette.ICONA_BIANCO;
            _coloreIconaSlotSx2 = ColorPalette.ICONA_ROSA;
            _coloreIconaSlotSx3 = ColorPalette.ICONA_ROSA;
            _coloreIconaSlotDx1 = ColorPalette.ICONA_ROSA;
            _coloreIconaSlotDx2 = ColorPalette.ICONA_ROSA;
            _coloreIconaSlotDx3 = ColorPalette.ICONA_ROSA;
            _colorBatteryHigh = 0xFF0055;
            _colorBatteryMedium = 0xFF00FF;
            _colorBatteryLow = 0xFFAAFF;


        } else if (_temaCorrente == 4) {
            // ── TEMA FOREST ───────────────────────────────────────────────
            _tipoIconaMeteo = Application.Properties.getValue("tipoIconaMeteo") as Number; // sempre colorata viene ignorata la riga di default sotto perchè loadWeatherIcon esce subito
            _coloreRettangolo = 0x55FF00;
            _coloreOre = 0xFFFFFF;	
            _coloreMinuti = 0x00FFAA;




            _coloreFillBarra1 = 0x55FF00;
            _coloreFillBarra2 = 0x55FF00;
            _coloreFillBarra3 = 0x55FF00;
            _coloreFillAlbaArcoSx = 0x00FFAA;
            _coloreFillTramontoArcoSx = 0x00FFAA;
            _coloreIconaTramonto = ColorPalette.ICONA_BIANCO;
            _coloreIconaAlba = ColorPalette.ICONA_LIME;
            _coloreFillArcoDx = 0x00FFAA;
            _coloreIconaArcoDx = ColorPalette.ICONA_LIME;
            _coloreSfondoBarreArchi= 0x555500;
            _coloreFontGiorno = 0x55FFAA;
            _coloreFontParametri = 0xFFFFFF;
            _coloreFontOraMeteo = 0xAAAA55;
            _coloreFontCalendario = 0x55FFAA;
            _coloreFontCitta = 0x00FF00;
            _coloreIconaMeteo = ColorPalette.ICONA_BIANCO;
            _coloreIconaSlotSx2 = ColorPalette.ICONA_LIME;
            _coloreIconaSlotSx3 = ColorPalette.ICONA_LIME;
            _coloreIconaSlotDx1 = ColorPalette.ICONA_LIME;
            _coloreIconaSlotDx2 = ColorPalette.ICONA_LIME;
            _coloreIconaSlotDx3 = ColorPalette.ICONA_LIME;
            _colorBatteryHigh = 0x00FF00;
            _colorBatteryMedium = 0xAAFF00;
            _colorBatteryLow = 0xAAFFAA;

        }
    }

    // Ritorna icona e testo per lo slot sinistra
    // L'icona è pre-caricata per posizione e passata come parametro
    function getSlotContentSinistra(tipo as Number, icona as BitmapResource?) as Dictionary {
        switch (tipo) {
            case 0: return { "icon" => icona, "text" => _precipProbValue };
            case 1: return { "icon" => icona, "text" => _precipValue     };
            case 2: return { "icon" => icona, "text" => _humidityValue   };
            case 3: return { "icon" => icona, "text" => _windValue       };
            case 4: return { "icon" => icona, "text" => _copValue        };
            case 5: return { "icon" => icona, "text" => _uvValue         };
            default: return { "icon" => null, "text" => null                 };
        }
    }

    // Ritorna icona, testo e goal per lo slot destra
    function getSlotContentDestra(tipo as Number, icona as BitmapResource?) as Dictionary {
        switch (tipo) {
            case 0: return { "icon" => icona, "text" => getCalories(),                "goal" => _goalCalorie };
            case 1: return { "icon" => icona, "text" => getSteps(),                   "goal" => _goalPassi   };
            case 2: return { "icon" => icona, "text" => getFloors()["climbed"],        "goal" => _goalGradini };
            case 3: return { "icon" => icona, "text" => getBodyBattery().format("%d"), "goal" => 100          };
            default: return { "icon" => null, "text" => null,                          "goal" => null         };
        }
    }

    // Carica l'icona corrispondente al colore della posizione
    function loadIconaPerColore(colore as Number,
                                ciano  as ResourceId, giallo as ResourceId,
                                lime   as ResourceId, rosa   as ResourceId,
                                bianco as ResourceId) as BitmapResource {
        switch (colore) {
            case ColorPalette.ICONA_GIALLO: return Application.loadResource(giallo)  as BitmapResource;
            case ColorPalette.ICONA_LIME:   return Application.loadResource(lime)    as BitmapResource;
            case ColorPalette.ICONA_ROSA:   return Application.loadResource(rosa)    as BitmapResource;
            case ColorPalette.ICONA_BIANCO: return Application.loadResource(bianco)  as BitmapResource;
            default:                        return Application.loadResource(ciano)   as BitmapResource;
        }
    }

}
