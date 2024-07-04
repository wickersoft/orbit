#include <Array.au3>
#include <GDIPlus.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <Wickersoft_HTTP.au3>
#include <Wickersoft_FBAPI.au3>

#include <Orbit\Orbit.au3>
#include <Orbit\OrbitRenderer.au3>

Global Const $SMART_AP_IP = "192.168.178.236"

_GDIPlus_Startup()
_fbhttp_set_credentials("http", "dennis:dennis", $SMART_AP_IP & ":50443", "1.0.0")


;$http = _https("www.minorplanetcenter.net", "iau/MPCORB/CometEls.txt")
;$txt = BinaryToString($http[0])
;$objects = StringSplit($txt, @LF, 1)
; Draw observations scatter plot
;For $i = 1 To $objects[0]
	;ConsoleWrite($objects[$i] & @CRLF)
;	$orbit = _Orbit_FromMPCElements($objects[$i])
;	If $orbit[12] > 0 And $orbit[12] < 9e7 And $orbit[1] < 1 And $orbit[6] < 10 Then ConsoleWrite($objects[$i] & @CRLF)
;Next
;post_light_curve()

$orbit = _Orbit_FromMPCElements("    CK24G030  2025 01 13.4265  0.093502  1.000012  108.1232  220.3292  116.8529  20240703   9.0  4.0  C/2024 G3 (ATLAS)                                        MPEC 2024-MB8")

$textfile_name = StringRegExpReplace(StringStripWS(StringRegExpReplace($orbit[8], "\(.+\)", ""), 3), "[/ ]", "_") & ".txt"
ConsoleWrite($textfile_name & @CRLF)
$http = _https("www.minorplanetcenter.net", "tmp2/" & $textfile_name)
$txt = BinaryToString($http[0])
$observations = StringSplit($txt, @LF, 1)
ConsoleWrite("MPC has " & $observations[0] & " observations" & @CRLF)


_OrbitRenderer_Startup(600, 448)
$hImage = _OrbitRenderer_RenderLightCurve($orbit, $observations, 0, 0, 0, 0)
_GDIPlus_ImageSaveToFile($hImage, @desktopdir & "\lightcurve.png")
_OrbitRenderer_Shutdown()







Func post_light_curve()
	;drawLabelContent(600, 448, "drawLightCurve", "    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")
	drawLabelContent(600, 448, "drawLightCurve", "    CK24G030  2025 01 13.4265  0.093502  1.000012  108.1232  220.3292  116.8529  20240703   9.0  4.0  C/2024 G3 (ATLAS)                                        MPEC 2024-MB8")
EndFunc   ;==>post_light_curve

Func post_orbit()
	drawLabelContent(600, 448, "drawOrbits", "    CK23A030  2024 09 27.7405  0.391423  1.000093  308.4925   21.5596  139.1109  20240702   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-MB8")
EndFunc   ;==>post_orbit


Func drawLightCurve($hGraphic, $hBlackBrush, $hRedBrush, $hWhiteBrush, $hYellowBrush, $iwidth, $iheight, $data)
	_OrbitRenderer_Startup($iwidth, $iheight)
	$orbit = _Orbit_FromMPCElements($data)

	$textfile_name = StringRegExpReplace(StringStripWS(StringRegExpReplace($orbit[8], "\(.+\)", ""), 3), "[/ ]", "_") & ".txt"
	ConsoleWrite($textfile_name & @CRLF)
	$http = _https("www.minorplanetcenter.net", "tmp2/" & $textfile_name)
	$txt = BinaryToString($http[0])
	$observations = StringSplit($txt, @LF, 1)

	$hImage = _OrbitRenderer_RenderLightCurve($orbit, $observations, 0, 0, 0, 0)
	_GDIPlus_GraphicsDrawImage($hGraphic, $hImage, 0, 0)
EndFunc   ;==>drawLightCurve







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

Func drawLabelContent($iwidth, $iheight, $draw_func, $data)
	$hBitmap = _WinAPI_CreateBitmap($iwidth, $iheight, 1, 32)
	$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	$hGraphic = _GDIPlus_ImageGetGraphicsContext($hImage)
	$hWhiteBrush = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
	$hBlackBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
	$hRedBrush = _GDIPlus_BrushCreateSolid(0xFFFF0000)
	$hYellowBrush = _GDIPlus_BrushCreateSolid(0xFFFFFF00)
	_GDIPlus_GraphicsFillRect($hGraphic, 0, 0, $iwidth, $iheight, $hWhiteBrush)

	Call($draw_func, $hGraphic, $hBlackBrush, $hRedBrush, $hWhiteBrush, $hYellowBrush, $iwidth, $iheight, $data)

	$sImgCLSID = _GDIPlus_EncodersGetCLSID("PNG")
	$tGUID = _WinAPI_GUIDFromString($sImgCLSID)
	$pStream = _WinAPI_CreateStreamOnHGlobal() ;create stream
	_GDIPlus_ImageSaveToFile($hImage, @DesktopDir & "\debug.png")
	_GDIPlus_ImageSaveToStream($hImage, $pStream, DllStructGetPtr($tGUID)) ;save the bitmap in JPG format in memory
	$hData = _WinAPI_GetHGlobalFromStream($pStream)
	$iMemSize = _MemGlobalSize($hData)
	$pData = _MemGlobalLock($hData)
	$tData = DllStructCreate('byte[' & $iMemSize & ']', $pData)
	$bData = DllStructGetData($tData, 1)
	_GDIPlus_GraphicsDispose($hGraphic)
	_WinAPI_DeleteObject($hBitmap)
	_GDIPlus_ImageDispose($hImage)
	_GDIPlus_BrushDispose($hWhiteBrush)
	_GDIPlus_BrushDispose($hBlackBrush)
	_GDIPlus_BrushDispose($hRedBrush)
	_WinAPI_ReleaseStream($pStream) ;http://msdn.microsoft.com/en-us/library/windows/desktop/ms221473(v=vs.85).aspx
	_MemGlobalFree($hData)
	$img = base64($bData, True, True)
	Return $img
EndFunc   ;==>drawLabelContent
