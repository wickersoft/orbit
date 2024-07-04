#include <Array.au3>
#include <GDIPlus.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <..\Wickersoft_HTTP.au3>
#include <..\Wickersoft_FBAPI.au3>
#include <..\drawlabelcontent_test.au3>
#include <Orbit.au3>
#include <OrbitRenderer.au3>

;post_light_curve()
post_interesting_orbits()

Func post_light_curve()
	;drawLabelContent(600, 448, "drawLightCurve", "    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")
	drawLabelContent(600, 448, "drawLightCurve", "0021P         2025 03 25.3453  1.008991  0.711131  172.9214  195.3374   32.0516  20240703   9.0  6.0  21P/Giacobini-Zinner                                     MPEC 2024-LE0")
EndFunc   ;==>post_light_curve

Func post_interesting_orbits()
    Dim $renderedObjects[0]
    $http = _https("www.minorplanetcenter.net", "iau/MPCORB/CometEls.txt")
    $txt = BinaryToString($http[0])
    $objects = StringSplit($txt, @LF, 1)
    $numObjects = 0
    For $i = 1 To $objects[0]
        $orbit = _Orbit_FromMPCElements($objects[$i])
        If $orbit[12] > -1e7 And $orbit[12] < 3e7 And $orbit[1] < 1.5 And $orbit[6] < 10 Then 
            ConsoleWrite($objects[$i] & "    " & $orbit[12] & @CRLF)
            ReDim $renderedObjects[$numObjects + 1]
            $renderedObjects[$numObjects] = $objects[$i]
            $numObjects += 1
        EndIf
    Next
    
    Dim $perspective = [7 / 18 * 3.1415926535, -1 / 7 * 3.1415926535, 600 / 2, 448 / 2, 1e6, 0]    
    Dim $data = [$perspective, $renderedObjects]
	drawLabelContent(600, 448, "drawOrbits", $data)
EndFunc   ;==>post_orbit

Func drawLightCurve($hGraphic, $hBlackBrush, $hRedBrush, $hWhiteBrush, $hYellowBrush, $iwidth, $iheight, $data)
	$orbit = _Orbit_FromMPCElements($data)

	$catalog_num = StringStripWS(StringRegExpReplace($orbit[8], "\(.+\)", ""), 3)
	$url_name = StringReplace($catalog_num, "/", "%2F")
	$url_name = StringReplace($url_name, " ", "+")
	$http = _https("www.minorplanetcenter.net", "db_search/show_object?object_id=" & $url_name)

	$textfile_name = StringRegExpReplace($catalog_num, "[/ ]", "_") & ".txt"
	$http = _https("www.minorplanetcenter.net", "tmp2/" & $textfile_name)
	$txt = BinaryToString($http[0])
	$observations = StringSplit($txt, @LF, 1)
	ConsoleWrite("MPC has " & $observations[0] & " observations" & @CRLF)

	_OrbitRenderer_Startup($iwidth, $iheight)
	$hImage = _OrbitRenderer_RenderLightCurve($orbit, $observations, 0, 0, 0, 0)
	_GDIPlus_GraphicsDrawImage($hGraphic, $hImage, 0, 0)
	_OrbitRenderer_Shutdown()
EndFunc   ;==>drawLightCurve


Func drawOrbits($hGraphic, $hBlackBrush, $hRedBrush, $hWhiteBrush, $hYellowBrush, $iwidth, $iheight, $data)
	$renderMeta = $data[0]
	$objects = $data[1]
    For $i = 0 To UBound($objects) - 1
		$objects[$i] = _Orbit_FromMPCElements($objects[$i])
	Next
    
	$LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($renderMeta[0], $renderMeta[1], $renderMeta[2], $renderMeta[3], $renderMeta[4])
	_OrbitRenderer_Startup($iwidth, $iheight)
    $hImage = _OrbitRenderer_RenderOrbits($objects, $renderMeta[5], $LABEL_FRAME)
    _GDIPlus_GraphicsDrawImage($hGraphic, $hImage, 0, 0)
	_OrbitRenderer_Shutdown()
EndFunc   ;==>drawOrbits
