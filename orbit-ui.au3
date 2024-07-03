#include <Array.au3>
#include <GDIPlus.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <..\Wickersoft_HTTP.au3>
#include <..\Wickersoft_FBAPI.au3>

#include "orbit.au3"

Global Const $SMART_AP_IP = "192.168.178.236"

_GDIPlus_Startup()
_fbhttp_set_credentials("http", "dennis:dennis", $SMART_AP_IP & ":50443", "1.0.0")

$resolution = 900
$kmPerPixel = 2e9 / $resolution



;Dim $LABEL_FRAME[8] = [-1, 0, 0, 0.8 * $resolution, 0, -0.7, 0.7, 0.4 * $resolution]
;Dim $LABEL_FRAME[8] = [-1, 0, 0, 0.8 * $resolution, 0, 0, 1, 0.4 * $resolution]

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", $resolution, 0.8 * $resolution, 192, 50)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$hGraphicGui = _GDIPlus_GraphicsCreateFromHWND($Form1)
$hBitmap = _WinAPI_CreateBitmap($resolution, 0.8 * $resolution, 1, 32)
$himage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
$hGraphic = _GDIPlus_ImageGetGraphicsContext($himage)
$hWhiteBrush = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
$hBlackBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
$hRedBrush = _GDIPlus_BrushCreateSolid(0xFFFF0000)
$hYellowBrush = _GDIPlus_BrushCreateSolid(0xFFFFFF00)
$hPenRed = _GDIPlus_PenCreate(0xFFFF9090, 3)
$hPenBlack = _GDIPlus_PenCreate(0xFF000000, 3)
$hPenDGray = _GDIPlus_PenCreate(0xFF808080, 1)
$hPenLGray = _GDIPlus_PenCreate(0xFFE0E0E0, 1)

$i = -3.141 / 7

$simOffsetSeconds = -8640000.0
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch


	Dim $LABEL_FRAME[8] = [-Cos($i), 0, -Sin($i), 0.5 * $resolution, -0.7 * Sin($i), -0.7, 0.7 * Cos($i), 0.4 * $resolution]
	;Dim $LABEL_FRAME[8] = [1, 0, 0, 0.5 * $resolution, 0, sin($i), Cos($i), 0.4 * $resolution]
	render($resolution, 0.8 * $resolution, $simOffsetSeconds)
	$i += 0.01
	$simOffsetSeconds += 100000
WEnd

_GDIPlus_GraphicsDispose($hGraphic)
_WinAPI_DeleteObject($hBitmap)
_GDIPlus_ImageDispose($himage)
_GDIPlus_BrushDispose($hWhiteBrush)
_GDIPlus_BrushDispose($hBlackBrush)
_GDIPlus_BrushDispose($hRedBrush)

Func render($iwidth, $iheight, $simOffsetSeconds)
	$time = TimerInit()

	_GDIPlus_GraphicsClear($hGraphic, 0xFFFFFFFF)

	drawBase($iwidth, $iheight)
	ConsoleWrite("Base: " & TimerDiff($time) & "ms" & @CRLF)

	$time = TimerInit()
	$orbElms = "0003D         2025 06 26.2215  0.823006  0.767472  192.2857  276.1865    7.8876  20240629  11.0  6.0  3D/Biela                                                  76, 1135"
	drawOrbit($iwidth, $iheight, $orbElms, $simOffsetSeconds)
	ConsoleWrite("Biela: " & TimerDiff($time) & "ms" & @CRLF)

	$time = TimerInit()
	$orbElms = "0109P         1992 12 19.8047  0.979463  0.962634  153.2308  139.5093  113.3770  20240629   4.0  6.0  109P/Swift-Tuttle                                        105,  420"
	;drawOrbit($iwidth, $iheight, $orbElms)
	;ConsoleWrite("Tuttle: " & TimerDiff($time) & "ms" & @CRLF)

	$time = TimerInit()
	$orbElms = "0109P         2024 03 21.0000  1.000000  0.000000  180.0000    0.0000    0.0000  20240629   4.0  6.0  Earth                                                    105,  420"
	drawOrbit($iwidth, $iheight, $orbElms, $simOffsetSeconds)
	ConsoleWrite("Earth: " & TimerDiff($time) & "ms" & @CRLF)

	_GDIPlus_GraphicsDrawImage($hGraphicGui, $himage, 0, 0)
EndFunc   ;==>render

Func drawBase($iwidth, $iheight)
	For $i = -20 To 20
		Dim $gridCoords1[3] = [$i * 1.5e8, 0, -3e9]
		Dim $gridCoords2[3] = [$i * 1.5e8, 0, 3e9]
		$pixel1 = projectToCanvasCoords($gridCoords1, $LABEL_FRAME)
		$pixel2 = projectToCanvasCoords($gridCoords2, $LABEL_FRAME)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel1[0], $pixel1[1], $pixel2[0], $pixel2[1], $hPenLGray)
	Next
	For $i = -20 To 20
		Dim $gridCoords1[3] = [-3e9, 0, $i * 1.5e8]
		Dim $gridCoords2[3] = [3e9, 0, $i * 1.5e8]
		$pixel1 = projectToCanvasCoords($gridCoords1, $LABEL_FRAME)
		$pixel2 = projectToCanvasCoords($gridCoords2, $LABEL_FRAME)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel1[0], $pixel1[1], $pixel2[0], $pixel2[1], $hPenLGray)
	Next

	Dim $cartesian[3] = [0, 0, 0]
	$pixel = projectToCanvasCoords($cartesian, $LABEL_FRAME)
	_GDIPlus_GraphicsFillEllipse($hGraphic, $pixel[0] - 2, $pixel[1] - 2, 4, 4, $hBlackBrush)
EndFunc   ;==>drawBase

Func drawOrbit($iwidth, $iheight, $orbElms, $simOffsetSeconds)
	Dim $NEAR_TIME_STEPS[25] = [0, 1, 2, 3, 4, 5, 6, 7, 14, 21, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 730, 1095]
	$eccentricity = getEccentricity($orbElms)
	$periapsisDistAU = getPeriapsisDist($orbElms)
	$argOfPerihelion = getArgOfPerihelion($orbElms)
	$longOfAscNode = getLongOfAscNode($orbElms)
	$inclination = getInclination($orbElms)
	$objectName = getObjectName($orbElms)
	$specAngMom = calcSpecificAngMomentum($eccentricity, $periapsisDistAU)
	$periapsisTime = getPeriapsisTime($orbElms)
	$timeToPeriapsis = _DateDiff("s", $periapsisTime, _DateAdd("s", $simOffsetSeconds, _NowCalcDate()))

	;msgbox(0, "", $periapsisTime & @CRLF & _NowCalcDate() & @CRLF & $timeToPeriapsis)

	For $time = 0 To 24
		$polar = getPolarCoordsForTime($eccentricity, $periapsisDistAU, $timeToPeriapsis + $NEAR_TIME_STEPS[$time] * 86400)
		$cartesian = calcCartesianCoords($polar[1], $polar[0], $argOfPerihelion, $inclination, $longOfAscNode)
		$pixel_new = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		$cartesian[1] = 0
		$pixel_flat = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel_new[0], $pixel_new[1], $pixel_flat[0], $pixel_flat[1], $hPenDGray)
		$polar = getPolarCoordsForTime($eccentricity, $periapsisDistAU, $timeToPeriapsis - $NEAR_TIME_STEPS[$time] * 86400)
		$cartesian = calcCartesianCoords($polar[1], $polar[0], $argOfPerihelion, $inclination, $longOfAscNode)
		$pixel_new = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		$cartesian[1] = 0
		$pixel_flat = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel_new[0], $pixel_new[1], $pixel_flat[0], $pixel_flat[1], $hPenDGray)
	Next

	$asymptoticTrueAnomaly = calcAsymptoticTrueAnomaly($eccentricity)
	$radius = calcOrbitRadiusKm(-$asymptoticTrueAnomaly, $specAngMom, $eccentricity)
	$cartesian = calcCartesianCoords(-$asymptoticTrueAnomaly, $radius, $argOfPerihelion, $inclination, $longOfAscNode)
	$pixel = projectToCanvasCoords($cartesian, $LABEL_FRAME)
	$cartesian[1] = 0
	$pixel_flat = projectToCanvasCoords($cartesian, $LABEL_FRAME)
	For $trueAnomaly = -$asymptoticTrueAnomaly To $asymptoticTrueAnomaly * 1.01 Step 0.05
		$radius = calcOrbitRadiusKm($trueAnomaly, $specAngMom, $eccentricity)
		$cartesian = calcCartesianCoords($trueAnomaly, $radius, $argOfPerihelion, $inclination, $longOfAscNode)
		$pixel_new = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		$cartesian[1] = 0
		$pixel_flat_new = projectToCanvasCoords($cartesian, $LABEL_FRAME)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel[0], $pixel[1], $pixel_new[0], $pixel_new[1], $hPenRed)
		_GDIPlus_GraphicsDrawLine($hGraphic, $pixel_flat[0], $pixel_flat[1], $pixel_flat_new[0], $pixel_flat_new[1], $hPenLGray)
		;ConsoleWrite($pixel_new[0] & "  " & $pixel_new[1] & "  " & $trueAnomaly & "  " & cos($trueAnomaly) &  @CRLF)
		$pixel_flat = $pixel_flat_new
		$pixel = $pixel_new
	Next

	$polar = getPolarCoordsForTime($eccentricity, $periapsisDistAU, $timeToPeriapsis)
	$cartesian = calcCartesianCoords($polar[1], $polar[0], $argOfPerihelion, $inclination, $longOfAscNode)
	$pixel = projectToCanvasCoords($cartesian, $LABEL_FRAME)
	_GDIPlus_GraphicsFillEllipse($hGraphic, $pixel[0] - 3, $pixel[1] - 3, 6, 6, $hRedBrush)
	_GDIPlus_GraphicsDrawStringExEx($hGraphic, $objectName, $pixel[0] - 60, $pixel[1] - 20, 400, 100, $hRedBrush)
EndFunc   ;==>drawOrbit

Func getCanvasCoordinates()
EndFunc   ;==>getCanvasCoordinates

Func projectToCanvasCoords($cartesian, $perspectiveTransform)
	Dim $pixel[2]
	$cartesian[0] /= $kmPerPixel
	$cartesian[1] /= $kmPerPixel
	$cartesian[2] /= $kmPerPixel
	$pixel[0] = Floor($perspectiveTransform[0] * $cartesian[0] + $perspectiveTransform[1] * $cartesian[1] + $perspectiveTransform[2] * $cartesian[2] + $perspectiveTransform[3])
	$pixel[1] = Floor($perspectiveTransform[4] * $cartesian[0] + $perspectiveTransform[5] * $cartesian[1] + $perspectiveTransform[6] * $cartesian[2] + $perspectiveTransform[7])

	Return $pixel
EndFunc   ;==>projectToCanvasCoords

Func getComets($nResults)
	$http = _http("aerith.net", "comet/weekly/current.html")
	$html = BinaryToString($http[0])

	$cmtable = stringextract($html, '<TABLE BGCOLOR="#EFFFEE" BORDER=1 CELLPADDING=10 CELLSPACING=0><TR><TD>', "</TD></TR></TABLE>")
	$cmitems = stringextractall($cmtable, "<H2><IMG SRC=", "</TD></TR>")
	Dim $comets[$nResults][5]
	For $i = 0 To $nResults - 1
		$item = $cmitems[$i]
		;$textmag = StringRegExp($item, "[0-9][0-9]?\.?[0-9] mag (?U)(.+)(\(.+\))?\.", 4)
		$table = stringextract($item, "<PRE>", "</PRE>")
		$table = StringRegExpReplace($table, "\h+", ";")
		$lines = StringSplit($table, @LF, 1)
		$l = StringSplit($lines[$lines[0] - 1], ";")
		$comets[$i][0] = stringextract($cmitems[$i], '.html">', "</A>") ; Comet name
		$comets[$i][1] = $l[10] ; m1
		$comets[$i][2] = $l[1] & " " & $l[2] ; Obs. Date
		;$comets[$i][3] = "http://aerith.net/comet" & StringStripWS(stringextract($item, '<A HREF="..', '">'), 7)
		;$comets[$i][4] = StringStripWS(stringextract($item, "<P>", "</P>"), 7) ; Description
		ConsoleWrite($comets[$i][0] & ": " & $comets[$i][1] & @CRLF) ; & " # " & $textmag[0] & @CRLF)
		;for $k in $textmag
		;    _arraydisplay($k)
		;Next
	Next
	Return $comets
EndFunc   ;==>getComets

Func _GDIPlus_GraphicsDrawStringExEx($hGraphic, $sString, $iX0, $iY0, $iX1, $iY1, $hBrush, $sFont = "Arial", $iFontSize = 12, $iFontStyle = 0, $iStringFormat = 0)
	$hFormat = _GDIPlus_StringFormatCreate($iStringFormat)
	$hFamily = _GDIPlus_FontFamilyCreate($sFont)
	$hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $iFontStyle)
	$tLayout = _GDIPlus_RectFCreate($iX0, $iY0, $iX1, $iY1)

	_GDIPlus_GraphicsDrawStringEx($hGraphic, $sString, $hFont, $tLayout, $hFormat, $hBrush)

	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
EndFunc   ;==>_GDIPlus_GraphicsDrawStringExEx