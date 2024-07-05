#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include "orbit.au3"
#include "orbitrenderer.au3"
#include "..\Wickersoft_HTTP.au3"

;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")]

Dim $perspective = [7 / 18 * 3.1415926535, -1 / 7 * 3.1415926535, 600 / 2, 448 / 2, 1e6, 0]
$ALL_ORBITS = get_interesting_orbits()

$width = 1200
$height = 800
$kmPerPixel = 1e6
$viewAz = -1 / 7 * 3.1415926535  ; A little off center to make the grid lines nice
$viewAlt = 7 / 18 * 3.1415926535 ; Looking 20 degrees down

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", $width, $height, 192, 50)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

_OrbitRenderer_Startup($width, $height)
$hGraphicGui = _GDIPlus_GraphicsCreateFromHWND($Form1)

$simOffsetSeconds = 0
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

	EndSwitch


	$LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $width / 2, $height / 2, $kmPerPixel)
    $hImage = _OrbitRenderer_RenderOrbits($ALL_ORBITS, $simOffsetSeconds, $LABEL_FRAME)
    _GDIPlus_GraphicsDrawImage($hGraphicGui, $hImage, 0, 0)

    ;$viewAz += 0.01
	$simOffsetSeconds += 86400
WEnd

_OrbitRenderer_Shutdown()


Func get_interesting_orbits()
	Dim $ORBITS[0]
	$http = _https("www.minorplanetcenter.net", "iau/MPCORB/CometEls.txt")
	$txt = BinaryToString($http[0])
	$objects = StringSplit($txt, @LF, 1)
	$numObjects = 0
	For $i = 1 To $objects[0]
		$orbit = _Orbit_FromMPCElements($objects[$i])

		; If perihelion date or radius don't look good we move on
		If $orbit[12] < -1e7 Or $orbit[12] > 3e7 Or $orbit[1] > 1.5 Or $orbit[6] > 10 Then ContinueLoop

		; Simulate the comet and see if it actually becomes bright
		$maxmag = 0
		$minmag = 25
		For $refTime = -1e6 to 3e7 step 100000
			$mag = _OrbitRenderer_CalcApparentMagnitudeAtRefTime($orbit, $refTime)
			If $mag > $maxmag then $maxmag = $mag
			If $mag < $minmag then $minmag = $mag
		Next

		If $minmag > 8 then ContinueLoop

		ConsoleWrite($objects[$i] & "    " & $minmag & @CRLF)
		ReDim $ORBITS[$numObjects + 1]
		$ORBITS[$numObjects] = $orbit
		$numObjects += 1
	Next

	Return $ORBITS
EndFunc   ;==>post_interesting_orbits