#include <Date.au3>

$SUN_MU = 1.32712e11

;testEllipticalCode()


Func getPolarCoordsForTime($eccentricity, $periapsisDistAU, $secondsFromPeriapsis)
    Dim $polar[2]
    $specAngMom = calcSpecificAngMomentum($eccentricity, $periapsisDistAU)

    Local $trueAnomaly
    If $eccentricity > 1 Then
        $trueAnomaly = calcHyperbolicTrueAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
    ElseIf $eccentricity < 1 Then
        $trueAnomaly = calcEllipticalTrueAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
    Else
        $trueAnomaly = calcParabolicTrueAnomaly($specAngMom, $secondsFromPeriapsis)
    EndIf

    $radius = calcOrbitRadiusKm($trueAnomaly, $specAngMom, $eccentricity)

    $polar[0] = $radius
    $polar[1] = $trueAnomaly

    Return $polar
EndFunc


Func testHyperbolicCode()
	$orbElms = "    CK23A030  2024 09 27.7403  0.391426  1.000095  308.4921   21.5596  139.1111  20020101   8.0  3.2  C/2023 A3 (Tsuchinshan-ATLAS)                            MPEC 2024-M41"

	$eccentricity = getEccentricity($orbElms)
	$periapsisDist = getPeriapsisDist($orbElms)

	$specAngMom = calcSpecificAngMomentum($eccentricity, $periapsisDist)

	ConsoleWrite("Periapsis radius: " & $periapsisDist & "AU" & @CRLF)
	ConsoleWrite("Eccentricity: " & $eccentricity & @CRLF)
	ConsoleWrite("Specific angular momentum: " & $specAngMom & "km^2/s" & @CRLF)
	ConsoleWrite("Asymptotic true anomaly: " & calcAsymptoticTrueAnomaly($eccentricity) * 180 / 3.14159 & "°" & @CRLF)
	ConsoleWrite("Speed at periapsis: " & calcPeriapsisVelocity($specAngMom, $periapsisDist) & "km/s" & @CRLF)
	ConsoleWrite("90 degree radius2: " & calcOrbitRadiusKm(90, $specAngMom, $eccentricity) & "Km" & @CRLF)

	For $i = 0 To 30
		;$meanHypAnomaly = calcHyperbolicMeanAnomaly($specAngMom, $eccentricity, $specAngMom, $eccentricity, 86400 * $i)
		;$eccAnomaly = calcHypEccentricAnomaly($specAngMom, $eccentricity, 86400 * $i)
		$trueAnomaly = calcHyperbolicTrueAnomaly($specAngMom, $eccentricity, 86400 * $i)
		;ConsoleWrite(" Mean anomaly after " & $i & "d: " & $meanHypAnomaly& @CRLF)
		;ConsoleWrite(" Ecc. anomaly after " & $i & "d: " & $eccAnomaly & @CRLF)
		ConsoleWrite(" True anomaly after " & $i & "d: " & $trueAnomaly & @CRLF)
	Next
EndFunc   ;==>testHyperbolicCode


Func testEllipticalCode()
	;$orbElms = "0109P         1992 12 19.8047  0.979463  0.962634  153.2308  139.5093  113.3770  20240629   4.0  6.0  109P/Swift-Tuttle                                        105,  420"
	$orbElms = "0109P         1992 12 19.8047  1.000000  0.000000  153.2308  139.5093  113.3770  20240629   4.0  6.0  109P/Swift-Tuttle                                        105,  420"

	$eccentricity = getEccentricity($orbElms)
	$periapsisDistAU = getPeriapsisDist($orbElms)

	$specAngMom = calcSpecificAngMomentum($eccentricity, $periapsisDistAU)

	ConsoleWrite("Periapsis radius: " & $periapsisDistAU & "AU" & @CRLF)
	ConsoleWrite("Eccentricity: " & $eccentricity & @CRLF)
	ConsoleWrite("Specific angular momentum: " & $specAngMom & "km^2/s" & @CRLF)
	ConsoleWrite("Speed at periapsis: " & calcPeriapsisVelocity($specAngMom, $periapsisDistAU) & "km/s" & @CRLF)
	ConsoleWrite("90 degree radius2: " & calcOrbitRadiusKm(90, $specAngMom, $eccentricity) & "Km" & @CRLF)

	For $i = 0 To 30
		;$meanHypAnomaly = calcHyperbolicMeanAnomaly($specAngMom, $eccentricity, $specAngMom, $eccentricity, 86400 * $i)
		;$eccAnomaly = calcHypEccentricAnomaly($specAngMom, $eccentricity, 86400 * $i)
		$trueAnomaly = calcEllipticalTrueAnomaly($specAngMom, $eccentricity, 86400 * $i)
		;ConsoleWrite(" Mean anomaly after " & $i & "d: " & $meanHypAnomaly& @CRLF)
		;ConsoleWrite(" Ecc. anomaly after " & $i & "d: " & $eccAnomaly & @CRLF)
		ConsoleWrite(" True anomaly after " & $i & "d: " & $trueAnomaly & @CRLF)
	Next
EndFunc   ;==>testEllipticalCode



Func getPeriapsisDist($elm)
	Return Number(StringMid($elm, 31, 9))
EndFunc   ;==>getPeriapsisDist

Func getEccentricity($elm)
	Return Number(StringMid($elm, 42, 9))
EndFunc   ;==>getEccentricity

; ========== UNIVERSAL ===========

Func calcSpecificAngMomentum($eccentricity, $periapsisDistAU)
	Return Sqrt(($eccentricity + 1) * ($periapsisDistAU * 1.5e8 * $SUN_MU))
EndFunc   ;==>calcSpecificAngMomentum

Func calcPeriapsisVelocity($specAngMom, $periapsisDistAU)
	Return $specAngMom / $periapsisDistAU / 1.5e8
EndFunc   ;==>calcPeriapsisVelocity

Func calcOrbitRadiusKm($trueAnomaly, $specAngMom, $eccentricity)
	Return $specAngMom ^ 2 / $SUN_MU / (1 + $eccentricity * Cos($trueAnomaly))
EndFunc   ;==>calcOrbitRadiusKm

Func calcCartesianCoords($trueAnomaly, $distance, $argOfPeriapsis, $inclination, $longOfAscNode)
	Dim $cartesian[3] = [0, 0, 0]

	; Calcualte in-plane coordinates and argument of periapsis
	$cartesian[0] = Cos($trueAnomaly + $argOfPeriapsis) * $distance
	$cartesian[1] = 0
	$cartesian[2] = Sin($trueAnomaly + $argOfPeriapsis) * $distance

	; Apply inclination
	$cartesian[1] = Sin($inclination) * $cartesian[2]
	$cartesian[2] = Cos($inclination) * $cartesian[2]

	; Apply longitude of ascending node
	$x = Cos($argOfPeriapsis) * $cartesian[0] - Sin($argOfPeriapsis) * $cartesian[2]
	$z = Cos($argOfPeriapsis) * $cartesian[2] + Sin($argOfPeriapsis) * $cartesian[0]

	$cartesian[0] = $x
	$cartesian[2] = $z

	Return $cartesian
EndFunc   ;==>calcCartesianCoords

; =========== ELLIPTICAL ==========


Func calcEllipticalMeanAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$semiMajorAxis = $specAngMom ^ 2 / ($SUN_MU * (1 - $eccentricity^2))
    ;ConsoleWrite("Semi-major axis: " & $semiMajorAxis & "Km" & @CRLF)

	$orbitalPeriod = 2 * 3.14159265359 / Sqrt($SUN_MU) * $semiMajorAxis ^ (3 / 2)
	$ellMeanAnomaly = 2 * 3.14159265359 * $secondsFromPeriapsis / $orbitalPeriod
    ;ConsoleWrite("Me: " & $ellMeanAnomaly & @CRLF)

    return $ellMeanAnomaly
EndFunc   ;==>calcEllipticalMeanAnomaly

Func calcEllEccentricAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$ellMeanAnomaly = calcEllipticalMeanAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)

	$E = 3.14159

	For $i = 0 To 20
		;ConsoleWrite("E" & $i & ": " & $E & @CRLF)
		$ex = $E - $eccentricity * Sin($E) - $ellMeanAnomaly ; Kepler
		$exdx = 1 - $eccentricity * Cos($E) ; Kepler_d_dF
		$E = $E - $ex / $exdx
	Next

	;ConsoleWrite("Final E: " & $E & @CRLF)
	Return $E
EndFunc   ;==>calcEllEccentricAnomaly


Func calcEllipticalTrueAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$ellEccAnomaly = calcEllEccentricAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	Return 2 * ATan(Sqrt((1 + $eccentricity) / (1 - $eccentricity)) * Tan($ellEccAnomaly / 2))
EndFunc   ;==>calcEllipticalTrueAnomaly


; ========== PARABOLIC ============


Func calcParabolicMeanAnomaly($specAngMom, $secondsFromPeriapsis)
	Return $SUN_MU^2 / $specAngMom^3 * $secondsFromPeriapsis
EndFunc   ;==>calcEllipticalMeanAnomaly

Func calcParabolicTrueAnomaly($specAngMom, $secondsFromPeriapsis)
    $paraMeanAnomaly = calcParabolicMeanAnomaly($specAngMom, $secondsFromPeriapsis)
	$z = (3*$paraMeanAnomaly + sqrt(1 + (3*$paraMeanAnomaly)^2))^(1/3)
	Return 2 * ATan($z - 1/$z)
EndFunc   ;==>calcEllipticalTrueAnomaly


; ========== HYPERBOLIC ===========

Func calcHyperbolicMeanAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	Return ($SUN_MU ^ 2 / $specAngMom ^ 3) * ($eccentricity ^ 2 - 1) ^ (3 / 2) * $secondsFromPeriapsis
EndFunc   ;==>calcHyperbolicMeanAnomaly

Func calcHypEccentricAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$meanHypAnomaly = calcHyperbolicMeanAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)

	$F = 3.14159

	For $i = 0 To 100
		;ConsoleWrite("F" & $i & ": " & $F & @CRLF)
		$fx = $eccentricity * sinh($F) - $F - $meanHypAnomaly ; Kepler
		$fxdx = $eccentricity * cosh($F) - 1 ; Kepler_d_dF
		$F = $F - $fx / $fxdx ; Newton my beloved
	Next

	;ConsoleWrite("Final F: " & $F & @CRLF)
	Return $F
EndFunc   ;==>calcHypEccentricAnomaly

Func calcHyperbolicTrueAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$hypEccAnomaly = calcHypEccentricAnomaly($specAngMom, $eccentricity, $secondsFromPeriapsis)
	$nu = (2 * ATan(Sqrt(($eccentricity + 1) / ($eccentricity - 1)) * tanh($hypEccAnomaly / 2)))
	;If $nu < 0 Then $nu += 3.14159265359
	Return $nu
EndFunc   ;==>calcHyperbolicTrueAnomaly

Func calcAsymptoticTrueAnomaly($eccentricity)
	Return ACos(-1 / $eccentricity)
EndFunc   ;==>calcAsymptoticTrueAnomaly

Func sinh($x)
	$E = 2.7182818284590452353602
	Return ($E ^ $x - $E ^ (-$x)) / 2
EndFunc   ;==>sinh

Func cosh($x)
	$E = 2.7182818284590452353602
	Return ($E ^ $x + $E ^ (-$x)) / 2
EndFunc   ;==>cosh

Func tanh($x)
	Return sinh($x) / cosh($x)
EndFunc   ;==>tanh
