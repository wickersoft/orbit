#include <Date.au3>

$SUN_MU = 1.32712e11

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
EndFunc   ;==>getPolarCoordsForTime

Func getPeriapsisDist($elm)
	Return Number(StringMid($elm, 31, 9))
EndFunc   ;==>getPeriapsisDist

Func getEccentricity($elm)
	Return Number(StringMid($elm, 42, 9))
EndFunc   ;==>getEccentricity

Func getArgOfPerihelion($elm)
	Return Number(StringMid($elm, 52, 9)) * 3.14159265359 / 180
EndFunc   ;==>getArgOfPerihelion

Func getLongOfAscNode($elm)
	Return Number(StringMid($elm, 62, 9)) * 3.14159265359 / 180
EndFunc   ;==>getLongOfAscNode

Func getInclination($elm)
	Return Number(StringMid($elm, 72, 9)) * 3.14159265359 / 180
EndFunc   ;==>getInclination

Func getObjectName($elm)
	Return StringMid($elm, 103, 56)
EndFunc   ;==>getObjectName

Func getPeriapsisTime($elm)
	$year = StringMid($elm, 15, 4)
	$month = StringMid($elm, 20, 2)
	$day = StringMid($elm, 23, 2)
	Return $year & "/" & $month & "/" & $day
EndFunc


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

Func calcAsymptoticTrueAnomaly($eccentricity)
	If $eccentricity <= 1 Then Return 3.14159265359
	Return ACos(-1 / $eccentricity)
EndFunc   ;==>calcAsymptoticTrueAnomaly

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
