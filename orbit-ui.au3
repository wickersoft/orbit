#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include "orbit.au3"
#include "orbitrenderer.au3"
#include "..\Wickersoft_HTTP.au3"

Global $MPC_TEXT = ""

;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")]
;$ALL_ORBITS = get_interesting_orbits2("C/2025 A6")
;Dim $ALL_ORBITS = [ _Orbit_FromMPCElements("    CK23A030  2024 10 14.0000  0.836348  0.475520  302.4140   71.4315  2.046711  20240702   8.0  3.2  Europa Clipper                                           MPEC 2024-MB8")]
$ALL_ORBITS = get_interesting_orbits("C/2025 A6")
_ArrayAdd($ALL_ORBITS, get_orbit_from_mpc("3I/ATLAS"), Default, Default, Default, 1)
;_ArrayAdd($ALL_ORBITS, horizons_orbit_for_object("europa clipper"), Default, Default, Default, 1)

_ArrayAdd($ALL_ORBITS, $ORBIT_MARS, Default, Default, Default, 1)
_ArrayAdd($ALL_ORBITS, $ORBIT_JUPITER, Default, Default, Default, 1)

Global $width = 600, $height = 448 ; Kohl's
;Global $width = 1200, $height = 800 ; Other
$simOffsetSeconds = 0 ;_orbit_calcreftimeatdate("2024/12/17")

Dim $perspective = [1.22173047636111, 2.432793703, 300, 224, 734450.980084772, $simOffsetSeconds]
$kmPerPixel = $perspective[4]
$viewAz = $perspective[1]  ; A little off center to make the grid lines nice
$viewAlt = $perspective[0] ; Looking 20 degrees down

_OrbitRenderer_Startup($width, $height)

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
			ClipPut("Dim $perspective = [" & $viewAlt & ", " & $viewAz & ", " & $width / 2 & ", " & $height / 2 & ", " & $kmPerPixel & ", $simOffsetSeconds]")
            ;ClipPut("$kmPerPixel = " & $kmPerPixel & @CRLF & "$viewAz = " & $viewAz & @CRLF & "$viewAlt = " & $viewAlt)
            Exit
    EndSwitch
WEnd



Func IsPressed($iMsg, $iwParam, $ilParam)
    ;$iwParam = virtual-key code
    ;$ilParam = Specifies the repeat count, scan code, extended-key flag, context code,
    ;           previous key-state flag, and transition-state flag
    ConsoleWrite(StringFormat("->WM_KEYDOWN Received (%s, %s, %s)\n", $iMsg, $iwParam, $ilParam))

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
    _GDIPlus_GraphicsDrawImage($hGraphicGui, $hImage, 0, 0)
EndFunc   ;==>IsPressed

_OrbitRenderer_Shutdown()


Func horizons_orbit_for_object($objectDesignation)
    $ephem = horizons_ephemeris_for_object($objectDesignation)
    $orbit = _Orbit_FromHorizonsEphemeris($ephem[0])
    $orbit[8] = $ephem[1]
    Return $orbit
EndFunc

Func horizons_ephemeris_for_object($objectDesignation)
    $http = _https("ssd.jpl.nasa.gov", "/api/horizons_support.api?sstr=" & $objectDesignation & "&time-span=1&www=1")
    $idLookup = BinaryToString($http[0])
    
    $object_name = stringextract($idLookup, '"name":"', '"')
    $object_id = stringextract($idLookup, '"id":"', '"')
    $object_kind = stringextract($idLookup, '"kind":"', '"')
    
    ;ConsoleWrite("Designation: " & $object_name & "  id: " & $object_id & @CRLF)
    
    If $object_kind = "SB" Then $object_id = "'DES=" & $object_id & "';"
    ;ConsoleWrite("-> Object is of kind 'small body'" & @CRLF)
    
    
    $startDate = stringreplace(_NowCalcDate(), "/", "-")
    $stopDate = stringreplace(_DateAdd("d", 1, _NowCalcDate()), "/", "-")
    
    $formData = '------geckoformboundary3adf8f70d6226f587f5514841d01791a' & @crlf & _
                'Content-Disposition: form-data; name="www"' & @crlf & _
                @crlf & _
                '1' & @crlf & _
                '------geckoformboundary3adf8f70d6226f587f5514841d01791a' & @crlf & _
                'Content-Disposition: form-data; name="format"' & @crlf & _
                '' & @crlf & _
                'json' & @crlf & _
                '------geckoformboundary3adf8f70d6226f587f5514841d01791a' & @crlf & _
                'Content-Disposition: form-data; name="input"' & @crlf & _
                '' & @crlf & _
                '!$$SOF' & @crlf & _
                'MAKE_EPHEM=YES' & @crlf & _
                'COMMAND=' & $object_id & @crlf & _
                'EPHEM_TYPE=ELEMENTS' & @crlf & _
                "CENTER='500@10'" & @crlf & _
                "START_TIME='" & $startDate & "'" & @crlf & _
                "STOP_TIME='" & $stopDate & "'" & @crlf & _
                "STEP_SIZE='1 DAYS'" & @crlf & _
                "REF_SYSTEM='ICRF'" & @crlf & _
                "REF_PLANE='ECLIPTIC'" & @crlf & _
                "CAL_TYPE='M'" & @crlf & _
                "OUT_UNITS='AU-D'" & @crlf & _
                "ELM_LABELS='YES'" & @crlf & _
                "TP_TYPE='RELATIVE'" & @crlf & _
                "CSV_FORMAT='NO'" & @crlf & _
                "OBJ_DATA='YES'" & @crlf & _
                "" & @crlf & _
                "------geckoformboundary3adf8f70d6226f587f5514841d01791a--" & @crlf
                
    ;ConsoleWrite($formData & @CRLF)
    
    $http = _https("ssd.jpl.nasa.gov", "api/horizons_file.api", $formData, "", "", "multipart/form-data; boundary=----geckoformboundary3adf8f70d6226f587f5514841d01791a")
    $ephemeris = StringReplace(BinaryToString($http[0]), "\n", @LF)
    
    ;ConsoleWrite($ephemeris & @CRLF)
    Dim $result = [$ephemeris, $object_name]
    return $result
EndFunc

Func get_interesting_orbits($search = "")
    Dim $ORBITS[0]
    If $MPC_TEXT = "" Then
        $http = _https("www.minorplanetcenter.net", "iau/MPCORB/CometEls.txt")
        $MPC_TEXT = BinaryToString($http[0])
    EndIf
    $objects = StringSplit($MPC_TEXT, @LF, 1)
    $numObjects = 0
    For $i = 1 To $objects[0]
        $orbit = _Orbit_FromMPCElements($objects[$i])

		If $search <> "" And StringInStr($objects[$i], $search) Then
			ConsoleWrite("+> " & $objects[$i] & @CRLF)
			ReDim $ORBITS[$numObjects + 1]
			$ORBITS[$numObjects] = $orbit
			$numObjects += 1
			ContinueLoop
		EndIf
        
        If $orbit[8] = "323P/SOHO" Then ContinueLoop

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

        If $minmag > 6 Then
            ;ConsoleWrite("-> (sim) " & $objects[$i] & @CRLF)
            ContinueLoop
        EndIf

        ConsoleWrite("+> " & $objects[$i] & "    " & $minmag & @CRLF)
        ReDim $ORBITS[$numObjects + 1]
        $ORBITS[$numObjects] = $orbit
        $numObjects += 1
    Next

    Return $ORBITS
EndFunc   ;==>get_interesting_orbits2

Func get_orbit_from_mpc($search = "")
    If $MPC_TEXT = "" Then
        $http = _https("www.minorplanetcenter.net", "iau/MPCORB/CometEls.txt")
        $MPC_TEXT = BinaryToString($http[0])
    EndIf
    $objects = StringSplit($MPC_TEXT, @LF, 1)
    $numObjects = 0
    For $i = 1 To $objects[0]
		If $search <> "" And StringInStr($objects[$i], $search) Then 
            ConsoleWrite("+> " & $objects[$i] & @CRLF)
            Return _Orbit_FromMPCElements($objects[$i])
        EndIf
    Next

    Dim $null_orbit[20]
    Return $null_orbit
EndFunc   ;==>get_interesting_orbits2