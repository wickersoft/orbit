#include-once
#include <Array.au3>
#include <GDIPlus.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "orbit.au3"

Global $_ORBITRENDERER_HBITMAP, $_ORBITRENDERER_HIMAGE, $_ORBITRENDERER_HGRAPHIC, $_ORBITRENDERER_HWHITEBRUSH, $_ORBITRENDERER_HBLACKBRUSH, $_ORBITRENDERER_HREDBRUSH, $_ORBITRENDERER_HYELLOWBRUSH, $_ORBITRENDERER_HPENRED, $_ORBITRENDERER_HPENPALERED, $_ORBITRENDERER_HPENBLACK, $_ORBITRENDERER_HPENDGRAY, $_ORBITRENDERER_HPENLGRAY, $_ORBITRENDERER_IWIDTH, $_ORBITRENDERER_IHEIGHT
$ORBIT_EARTH = _Orbit_FromMPCElements("0109P         2024 03 21.0000  1.000000  0.000000  180.0000    0.0000    0.0000  20240629   4.0  6.0  Earth                                                    105,  420")

Func _OrbitRenderer_Startup($width, $height)
    _GDIPlus_Startup()
    $_ORBITRENDERER_IWIDTH = $width
    $_ORBITRENDERER_IHEIGHT = $height
    $_ORBITRENDERER_HBITMAP = _WinAPI_CreateBitmap($width, $height, 1, 32)
    $_ORBITRENDERER_HIMAGE = _GDIPlus_BitmapCreateFromHBITMAP($_ORBITRENDERER_HBITMAP)
    $_ORBITRENDERER_HGRAPHIC = _GDIPlus_ImageGetGraphicsContext($_ORBITRENDERER_HIMAGE)
    $_ORBITRENDERER_HWHITEBRUSH = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
    $_ORBITRENDERER_HBLACKBRUSH = _GDIPlus_BrushCreateSolid(0xFF000000)
    $_ORBITRENDERER_HREDBRUSH = _GDIPlus_BrushCreateSolid(0xFFFF0000)
    $_ORBITRENDERER_HYELLOWBRUSH = _GDIPlus_BrushCreateSolid(0xFFFFFF00)
    $_ORBITRENDERER_HPENRED = _GDIPlus_PenCreate(0xFFFF0000, 3)
    $_ORBITRENDERER_HPENPALERED = _GDIPlus_PenCreate(0xFFFFA0A0, 3)
    $_ORBITRENDERER_HPENBLACK = _GDIPlus_PenCreate(0xFF000000, 3)
    $_ORBITRENDERER_HPENDGRAY = _GDIPlus_PenCreate(0xFF707070, 1)
    $_ORBITRENDERER_HPENLGRAY = _GDIPlus_PenCreate(0xFF989898, 1)
EndFunc   ;==>_OrbitRenderer_Startup

Func _OrbitRenderer_Shutdown()
    _GDIPlus_GraphicsDispose($_ORBITRENDERER_HGRAPHIC)
    _WinAPI_DeleteObject($_ORBITRENDERER_HBITMAP)
    _GDIPlus_ImageDispose($_ORBITRENDERER_HIMAGE)
    _GDIPlus_BrushDispose($_ORBITRENDERER_HWHITEBRUSH)
    _GDIPlus_BrushDispose($_ORBITRENDERER_HBLACKBRUSH)
    _GDIPlus_BrushDispose($_ORBITRENDERER_HREDBRUSH)
    _GDIPlus_BrushDispose($_ORBITRENDERER_HYELLOWBRUSH)
    _GDIPlus_PenDispose($_ORBITRENDERER_HPENRED)
    _GDIPlus_PenDispose($_ORBITRENDERER_HPENPALERED)
    _GDIPlus_PenDispose($_ORBITRENDERER_HPENBLACK)
    _GDIPlus_PenDispose($_ORBITRENDERER_HPENDGRAY)
    _GDIPlus_PenDispose($_ORBITRENDERER_HPENLGRAY)
EndFunc   ;==>_OrbitRenderer_Shutdown

Func _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $sun_x, $sun_y, $kmPerPixel)
    Dim $perspective[8] = [-Cos($viewAz) / $kmPerPixel, 0 / $kmPerPixel, -Sin($viewAz) / $kmPerPixel, $sun_x, _
             -Cos($viewAlt) * Sin($viewAz) / $kmPerPixel, -Sin($viewAlt) / $kmPerPixel, Cos($viewAlt) * Cos($viewAz) / $kmPerPixel, $sun_y]
    Return $perspective
EndFunc   ;==>_OrbitRenderer_GenerateAltAzPerspectiveMatrix

Func _OrbitRenderer_RenderLightCurve(ByRef $orbit, ByRef $observations, $startDay, $endDay, $brightestMag, $darkestMag)
    _GDIPlus_GraphicsClear($_ORBITRENDERER_HGRAPHIC, 0xFFFFFFFF)
    $_NOW_DATE = _NowCalcDate()

    $mag = 25

    For $i = 1 To 25
        _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, 0, 25 * $i, $_ORBITRENDERER_IWIDTH, 25 * $i, $_ORBITRENDERER_HPENLGRAY)
        _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, $i, 2, 25 * $i - 16, 20, 20, $_ORBITRENDERER_HBLACKBRUSH, "Arial", 8)
    Next

    _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, 0, 25 * 5, $_ORBITRENDERER_IWIDTH, 25 * 5, $_ORBITRENDERER_HPENDGRAY)
    _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $_ORBITRENDERER_IWIDTH / 3, 0, $_ORBITRENDERER_IWIDTH / 3, $_ORBITRENDERER_IHEIGHT, $_ORBITRENDERER_HPENDGRAY)

    ; Draw observations scatter plot
    For $i = 1 To $observations[0]
        $d = StringReplace(StringMid($observations[$i], 16, 10), " ", "/")
        $mag = StringMid($observations[$i], 66, 4)
        ;if StringMid($observations[$i], 71, 1) <> "G" then ContinueLoop
        If Not StringRegExp($mag, "[0-9\.]+") Then ContinueLoop
        $mag = Number($mag)
        $days = _DateDiff("d", $_NOW_DATE, $d)
        ;ConsoleWrite($d & ": " & $days & " " & $mag & @CRLF)
        _GDIPlus_GraphicsFillRect($_ORBITRENDERER_HGRAPHIC, $_ORBITRENDERER_IWIDTH / 3 + 2 * $days, 25 * $mag, 1, 1, $_ORBITRENDERER_HBLACKBRUSH)
    Next


    ; Draw calendar lines
    $_THIS_MONTH_DATE = @YEAR & "/" & @MON & "/01"
    For $i = -4 To 8
        $days = _DateDiff("d", $_NOW_DATE, _DateAdd("M", $i, $_THIS_MONTH_DATE))
        _GDIPlus_GraphicsFillRect($_ORBITRENDERER_HGRAPHIC, $_ORBITRENDERER_IWIDTH / 3 + 2 * $days, 25 * 5 - 5, 1, 10, $_ORBITRENDERER_HBLACKBRUSH)
    Next


    ; Draw predicted light curve
    $mag = 25
    For $i = 0 To $_ORBITRENDERER_IWIDTH - 1 Step 2
        $d = _DateAdd("d", ($i - $_ORBITRENDERER_IWIDTH / 3) / 2, $_NOW_DATE)
        $mag_new = _OrbitRenderer_CalcApparentMagnitudeAtDate($orbit, $d)

        _GDIPlus_GraphicsFillRect($_ORBITRENDERER_HGRAPHIC, $i - 1, 25 * $mag_new, 2, 3, $_ORBITRENDERER_HREDBRUSH)
        $mag = $mag_new
    Next

    ; Draw vertical line at perihelion
    $days = _DateDiff("d", $_NOW_DATE, $orbit[0])
    _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, 2 * $days + $_ORBITRENDERER_IWIDTH / 3, 0, 2 * $days + $_ORBITRENDERER_IWIDTH / 3, $_ORBITRENDERER_IHEIGHT, $_ORBITRENDERER_HPENLGRAY)
    _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, "Perihelion: " & $orbit[0], 2 * $days + $_ORBITRENDERER_IWIDTH / 3 + 2, 17 * 25 + 5, 200, 100, $_ORBITRENDERER_HBLACKBRUSH, "Arial", 8)

    ; Title
    _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, $orbit[8], $_ORBITRENDERER_IWIDTH / 3 + 2, 0, 400, 100, $_ORBITRENDERER_HBLACKBRUSH, "Arial", 12, 1)

    Return $_ORBITRENDERER_HIMAGE
EndFunc   ;==>_OrbitRenderer_RenderLightCurve

Func _OrbitRenderer_CalcApparentMagnitudeAtDate($orbit, $date)
    $refTime = _Orbit_CalcRefTimeAtDate($date)
    Return _OrbitRenderer_CalcApparentMagnitudeAtRefTime($orbit, $refTime)
EndFunc   ;==>_OrbitRenderer_CalcApparentMagnitudeAtDate

Func _OrbitRenderer_CalcApparentMagnitudeAtRefTime($orbit, $refTime)
    $polarC = _Orbit_CalcPolarCoordsAtRefTime($orbit, $refTime)
    $cartesianC = _Orbit_CalcCartesianCoordsAtPolarCoords($orbit, $polarC)
    $cartesianE = _Orbit_CalcCartesianCoordsAtRefTime($ORBIT_EARTH, $refTime)
    $earthDist = Sqrt(($cartesianE[0] - $cartesianC[0]) ^ 2 + ($cartesianE[1] - $cartesianC[1]) ^ 2 + ($cartesianE[2] - $cartesianC[2]) ^ 2)

    $mag = _Orbit_CalcApparentMagnitude($orbit, $polarC[0], $earthDist)
    Return $mag
EndFunc   ;==>_OrbitRenderer_CalcApparentMagnitudeAtRefTime

Func _OrbitRenderer_RenderOrbits(ByRef $orbitsToRender, $simOffsetSeconds, ByRef $perspective)
    _GDIPlus_GraphicsClear($_ORBITRENDERER_HGRAPHIC, 0xFFFFFFFF)

    _OrbitRenderer_DrawBase($perspective)
    For $o In $orbitsToRender
        _OrbitRenderer_DrawOrbit($o, $simOffsetSeconds, $perspective)
    Next
    _OrbitRenderer_DrawOrbit($ORBIT_EARTH, $simOffsetSeconds, $perspective, $_ORBITRENDERER_HPENBLACK, $_ORBITRENDERER_HPENBLACK)

    _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, _DateAdd("s", $simOffsetSeconds, $_ORBIT_REFERENCE_DATE), $_ORBITRENDERER_IWIDTH - 90, $_ORBITRENDERER_IHEIGHT - 20, 100, 20, $_ORBITRENDERER_HBLACKBRUSH, "Arial", 10)

    Return $_ORBITRENDERER_HIMAGE
EndFunc   ;==>_OrbitRenderer_RenderOrbits

Func _OrbitRenderer_DrawBase($perspective)
    For $i = -20 To 20
        Dim $gridCoords1[3] = [$i * 1.5e8, 0, -3e9]
        Dim $gridCoords2[3] = [$i * 1.5e8, 0, 3e9]
        $pixel1 = _OrbitRenderer_ProjectToGraphicCoords($gridCoords1, $perspective)
        $pixel2 = _OrbitRenderer_ProjectToGraphicCoords($gridCoords2, $perspective)
        _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel1[0], $pixel1[1], $pixel2[0], $pixel2[1], $_ORBITRENDERER_HPENLGRAY)
    Next
    For $i = -20 To 20
        Dim $gridCoords1[3] = [-3e9, 0, $i * 1.5e8]
        Dim $gridCoords2[3] = [3e9, 0, $i * 1.5e8]
        $pixel1 = _OrbitRenderer_ProjectToGraphicCoords($gridCoords1, $perspective)
        $pixel2 = _OrbitRenderer_ProjectToGraphicCoords($gridCoords2, $perspective)
        _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel1[0], $pixel1[1], $pixel2[0], $pixel2[1], $_ORBITRENDERER_HPENLGRAY)
    Next

    Dim $cartesian[3] = [0, 0, 0]
    $pixel = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
    _GDIPlus_GraphicsFillEllipse($_ORBITRENDERER_HGRAPHIC, $pixel[0] - 2, $pixel[1] - 2, 4, 4, $_ORBITRENDERER_HBLACKBRUSH)
EndFunc   ;==>_OrbitRenderer_DrawBase

Func _OrbitRenderer_DrawOrbit($orbit, $simOffsetSeconds, $perspective, $hPenAbove = $_ORBITRENDERER_HPENRED, $hPenBelow = $_ORBITRENDERER_HPENPALERED)
    ; Draw out-of-ecliptic "Supporting lines"
    Dim $NEAR_TIME_STEPS = [0, 2, 4, 7, 14, 21, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 730, 1095]
    For $time = 0 To UBound($NEAR_TIME_STEPS) - 1
        $cartesian = _Orbit_CalcCartesianCoordsAtRefTime($orbit, $simOffsetSeconds - $NEAR_TIME_STEPS[$time] * 86400)
        $pixel_new = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)

        If $cartesian[1] > 0 Then
            $cartesian[1] = 0
            $pixel_flat = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
            _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel_new[0], $pixel_new[1], $pixel_flat[0], $pixel_flat[1], $_ORBITRENDERER_HPENDGRAY)
        EndIf

        $cartesian = _Orbit_CalcCartesianCoordsAtRefTime($orbit, $simOffsetSeconds + $NEAR_TIME_STEPS[$time] * 86400)
        $pixel_new = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
        If $cartesian[1] > 0 Then
            $cartesian[1] = 0
            $pixel_flat = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
            _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel_new[0], $pixel_new[1], $pixel_flat[0], $pixel_flat[1], $_ORBITRENDERER_HPENDGRAY)
        EndIf
    Next

    ; Draw Orbit and "supporting" projection into ecliptic
    $cartesian = _Orbit_CalcCartesianCoordsAtTrueAnomaly($orbit, -$orbit[11])
    $pixel = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
    $cartesian[1] = 0
    $pixel_flat = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
    For $trueAnomaly = -$orbit[11] To $orbit[11] * 1.01 Step 0.05
        $cartesian = _Orbit_CalcCartesianCoordsAtTrueAnomaly($orbit, $trueAnomaly)
        $pixel_new = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
        $elevation = $cartesian[1]
        $cartesian[1] = 0
        $pixel_flat_new = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
        _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel_flat[0], $pixel_flat[1], $pixel_flat_new[0], $pixel_flat_new[1], $_ORBITRENDERER_HPENLGRAY)
        If $elevation > 0 Then
            _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel[0], $pixel[1], $pixel_new[0], $pixel_new[1], $hPenAbove)
        Else
            _GDIPlus_GraphicsDrawLine($_ORBITRENDERER_HGRAPHIC, $pixel[0], $pixel[1], $pixel_new[0], $pixel_new[1], $hPenBelow)
        EndIf
        $pixel_flat = $pixel_flat_new
        $pixel = $pixel_new
    Next

    $cartesian = _Orbit_CalcCartesianCoordsAtRefTime($orbit, $simOffsetSeconds)
    $pixel = _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
    _GDIPlus_GraphicsFillEllipse($_ORBITRENDERER_HGRAPHIC, $pixel[0] - 3, $pixel[1] - 3, 6, 6, $_ORBITRENDERER_HREDBRUSH)
    _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, $orbit[8], $pixel[0] - 60, $pixel[1] - 20, 400, 100, $_ORBITRENDERER_HREDBRUSH)
EndFunc   ;==>_OrbitRenderer_DrawOrbit

Func _OrbitRenderer_ProjectToGraphicCoords($cartesian, $perspective)
    Dim $pixel[2] = [Floor($perspective[0] * $cartesian[0] + $perspective[1] * $cartesian[1] + $perspective[2] * $cartesian[2] + $perspective[3]), _
            Floor($perspective[4] * $cartesian[0] + $perspective[5] * $cartesian[1] + $perspective[6] * $cartesian[2] + $perspective[7])]
    Return $pixel
EndFunc   ;==>_OrbitRenderer_ProjectToGraphicCoords

Func _OrbitRenderer_GraphicsDrawStringExEx($_ORBITRENDERER_HGRAPHIC, $sString, $iX0, $iY0, $iX1, $iY1, $hBrush, $sFont = "Arial", $iFontSize = 12, $iFontStyle = 0, $iStringFormat = 0)
    $hFormat = _GDIPlus_StringFormatCreate($iStringFormat)
    $hFamily = _GDIPlus_FontFamilyCreate($sFont)
    $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $iFontStyle)
    $tLayout = _GDIPlus_RectFCreate($iX0, $iY0, $iX1, $iY1)

    _GDIPlus_GraphicsDrawStringEx($_ORBITRENDERER_HGRAPHIC, $sString, $hFont, $tLayout, $hFormat, $hBrush)

    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontFamilyDispose($hFamily)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc   ;==>_OrbitRenderer_GraphicsDrawStringExEx
