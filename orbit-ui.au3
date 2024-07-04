#include <Array.au3>
#include <GDIPlus.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <..\Wickersoft_HTTP.au3>
#include "orbit.au3"
#include "orbitrenderer.au3"

$ORBIT_TSUCHINSHAN = _Orbit_FromMPCElements("    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")
$ORBIT_ATLAS = _Orbit_FromMPCElements("    CK24G030  2025 01 13.4265  0.093502  1.000012  108.1232  220.3292  116.8529  20240703   9.0  4.0  C/2024 G3 (ATLAS)                                        MPEC 2024-MB8")
$ORBIT_WIERZCHOS = _Orbit_FromMPCElements("    CK24E010  2026 01 20.7399  0.565276  1.000019  243.6550  108.1078   75.2342  20240703   7.0  4.0  C/2024 E1 (Wierzchos)                                    MPEC 2024-M41")
$ORBIT_MACHHOLZ = _Orbit_FromMPCElements("0141P      b  2026 04 15.2237  0.807348  0.735812  241.7800  153.6144   13.9864  20240703   9.0  4.0  141P-B/Machholz                                          MPC 24216")
$ORBIT_SWIFT_TUTTLE = _Orbit_FromMPCElements("0109P         1992 12 19.8047  0.979463  0.962634  153.2308  139.5093  113.3770  20240629   4.0  6.0  109P/Swift-Tuttle                                        105,  420")
$ORBIT_BIELA = _Orbit_FromMPCElements("0003D         2025 06 26.2215  0.823006  0.767472  192.2857  276.1865    7.8876  20240629  11.0  6.0  3D/Biela                                                  76, 1135")

Dim $ALL_ORBITS = [$ORBIT_TSUCHINSHAN, $ORBIT_ATLAS, $ORBIT_WIERZCHOS, $ORBIT_MACHHOLZ, $ORBIT_SWIFT_TUTTLE, $ORBIT_BIELA] 

$width = 600
$height = 400
$kmPerPixel = 1e6
_OrbitRenderer_Startup($width, $height)

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", $width, $height, 192, 50)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

$hGraphicGui = _GDIPlus_GraphicsCreateFromHWND($Form1)
$viewAz = -1 / 7 * 3.1415926535
$viewAlt = 7 / 18 * 3.1415926535
$simOffsetSeconds = 0

$LABEL_FRAME = _OrbitRenderer_GenerateAltAzPerspectiveMatrix($viewAlt, $viewAz, $width / 2, $height / 2, $kmPerPixel)
$hImage = _OrbitRenderer_RenderOrbits($ALL_ORBITS, $simOffsetSeconds, $LABEL_FRAME)

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
	$simOffsetSeconds += 100000
WEnd

_OrbitRenderer_Shutdown()