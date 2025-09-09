#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include "orbit.au3"
#include "orbitrenderer.au3"
#include "..\Wickersoft_HTTP.au3"

;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")]
;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("0342P         2027 02  7.5678  0.051854  0.982949   27.6336   73.3228   11.6950  20240917   9.0  4.0  342P/SOHO                                                MPC101101    ")]
;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK24G030  2025 01 13.4284  0.093522  1.000010  108.1250  220.3373  116.8475  20240917   9.0  4.0  C/2024 G3 (ATLAS)                                        MPEC 2024-RQ6")]
;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK24S010  2024 10 28.4597  0.008313  1.000063   68.8091  347.1104  141.8851  20241001  15.5  4.0  C/2024 S1 (ATLAS)                                        MPEC 2024-T22")]
$ALL_ORBITS = get_interesting_orbits()

;Exit 

$width = 1200
$height = 800
$kmPerPixel = 1e6
$viewAz = 6 / 7 * 3.1415926535  ; A little off center to make the grid lines nice
$viewAlt = 7 / 18 * 3.1415926535 ; Looking 20 degrees down

_OrbitRenderer_Startup($width, $height)
$simOffsetSeconds = 0 ;_orbit_calcreftimeatdate("2024/12/17")

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", $width, $height, 192, 50)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUIRegisterMsg($WM_KEYDOWN, "IsPressed")

$hGraphicGui = _GDIPlus_GraphicsCreateFromHWND($Form1)

$LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $width / 2, $height / 2, $kmPerPixel)
$hImage = _OrbitRenderer_RenderOrbits($ALL_ORBITS, $simOffsetSeconds, $LABEL_FRAME)
_GDIPlus_GraphicsDrawImage($hGraphicGui, $hImage, 0, 0)

While 1
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            Exit
    EndSwitch


    ;$LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $width / 2, $height / 2, $kmPerPixel)
    ;$hImage = _OrbitRenderer_RenderOrbits($ALL_ORBITS, $simOffsetSeconds, $LABEL_FRAME)
    ;_GDIPlus_GraphicsDrawImage($hGraphicGui, $hImage, 0, 0)

    ;$viewAz += 0.01
    ;$simOffsetSeconds += 86400
WEnd



Func IsPressed($iMsg, $iwParam, $ilParam)
	;$iwParam = virtual-key code
	;$ilParam = Specifies the repeat count, scan code, extended-key flag, context code,
	;           previous key-state flag, and transition-state flag
	;ConsoleWrite(StringFormat("->WM_KEYDOWN Received (%s, %s, %s)\n", $iMsg, $iwParam, $ilParam))

	;If $bitmapqueue.count <= 0 Then Return

    $stepsize = 1 + _IsPressed(0x10) * 10
    

	Switch $ilParam
		case 0x41
			$viewAz -= 0.01 * $stepsize
		case 0x44
			$viewAz += 0.01 * $stepsize
		case 0x57
			$viewAlt += 0.01 * $stepsize
		case 0x53
			$viewAlt -= 0.01 * $stepsize
		case 0xbc
			$simOffsetSeconds -= 86400 * $stepsize
		case 0xbe
			$simOffsetSeconds += 86400 * $stepsize
        case 0xbb
			$kmPerPixel /= 1.05
		case 0xbd
			$kmPerPixel *= 1.05
            
            
        case Else
            
            ConsoleWrite($ilParam & @CRLF)

	EndSwitch

    $LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $width / 2, $height / 2, $kmPerPixel)
    $hImage = _OrbitRenderer_RenderOrbits($ALL_ORBITS, $simOffsetSeconds, $LABEL_FRAME)
    ;$ssp = _Orbit_CalcSecondsSincePeriapsisAtRefTime($ALL_ORBITS[0], $simOffsetSeconds)
    ;$ta = _Orbit_CalcHyperbolicTrueAnomaly($ALL_ORBITS[0], $ssp)
    ;ConsoleWrite($ta & @CRLF)
    _GDIPlus_GraphicsDrawImage($hGraphicGui, $hImage, 0, 0)
EndFunc   ;==>IsPressed



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
        If $orbit[12] < -1e7 Or $orbit[12] > 3e7 Then
            ;ConsoleWrite("-> (date) " & $objects[$i] & @CRLF)
            ContinueLoop
        EndIf
        
        if $orbit[1] > 1.5 Then
            ;ConsoleWrite("-> (radius " & $orbit[1] & ") " & $objects[$i] & @CRLF)
            ContinueLoop
        EndIf
        if $orbit[6] > 18 Then 
            ;ConsoleWrite("-> (magnitude " & $orbit[6] & ") " & $objects[$i] & @CRLF)
            ContinueLoop
        EndIf
        
        ; Simulate the comet and see if it actually becomes bright
        $maxmag = 0
        $minmag = 25
        For $refTime = -1e7 To 3e7 Step 100000
            $mag = _OrbitRenderer_CalcApparentMagnitudeAtRefTime($orbit, $refTime)
            If $mag > $maxmag Then $maxmag = $mag
            If $mag < $minmag Then $minmag = $mag
        Next

        If $minmag > 8 Then 
            ;ConsoleWrite("-> (sim) " & $objects[$i] & @CRLF)
            ContinueLoop
        EndIf
        
        ConsoleWrite("+> " & $objects[$i] & "    " & $minmag & @CRLF)
        ReDim $ORBITS[$numObjects + 1]
        $ORBITS[$numObjects] = $orbit
        $numObjects += 1
    Next

    Return $ORBITS
EndFunc   ;==>get_interesting_orbits
