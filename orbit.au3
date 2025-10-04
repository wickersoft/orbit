#include-once
#include <Date.au3>
#include <StringConstants.au3>

$SUN_MU = 1.32712e11
$_ORBIT_REFERENCE_DATE = _NowCalcDate() ; Arbitrary reference date for coordinated time frame

Func _Orbit_FromMPCElements($MPCElements)
    Dim $Orbit[20]

    ; Parsed out of String
    $Orbit[0] = getPeriapsisTime($MPCElements)                                          ; Date of Periapsis
    $Orbit[1] = Number(StringMid($MPCElements, 31, 9))                                  ; Periapsis Distance (AU)
    $Orbit[2] = Number(StringMid($MPCElements, 42, 9))                                  ; Eccentricity
    $Orbit[3] = Number(StringMid($MPCElements, 52, 9)) * 3.14159265359 / 180            ; Argument of Periapsis (radians)
    $Orbit[4] = Number(StringMid($MPCElements, 62, 9)) * 3.14159265359 / 180            ; Longitude of ascending node (radians)
    $Orbit[5] = Number(StringMid($MPCElements, 72, 9)) * 3.14159265359 / 180            ; Inclination (radians)
    $Orbit[6] = Number(StringMid($MPCElements, 92, 4))                                  ; Absolute magnitude
    $Orbit[7] = Number(StringMid($MPCElements, 97, 4))                                  ; Slope parameter
    $Orbit[8] = StringStripWS(StringMid($MPCElements, 103, 56),  $STR_STRIPTRAILING)    ; Designation

    ; Calculated for convenience and speed
    $Orbit[9] = _Orbit_CalcSpecificAngMomentum($Orbit)                                  ; Specific angular momentum
    $Orbit[10] = _Orbit_CalcMeanMotion($Orbit)                                          ; Mean angular motion
    $Orbit[11] = _Orbit_CalcAsymptoticTrueAnomaly($Orbit)                               ; Asymptotic True Anomaly (pi for non-hyperbolic)
    $Orbit[12] = _Orbit_CalcRefTimeAtDate($Orbit[0])                                    ; Seconds from reference time to periapsis

    Return $Orbit
EndFunc   ;==>_Orbit_FromMPCElements


; ========  PARSED FROM CONFIG ========


Func getPeriapsisTime($MPCElements)
    $year = StringMid($MPCElements, 15, 4)
    $month = StringMid($MPCElements, 20, 2)
    $day = Number(StringMid($MPCElements, 23, 2))
    If $day < 10 Then $day = "0" & $day
    Return $year & "/" & $month & "/" & $day
EndFunc   ;==>getPeriapsisTime


; ========  CACHED AFTER PARSING ======


Func _Orbit_CalcSpecificAngMomentum(ByRef $Orbit)
    Return Sqrt(($Orbit[2] + 1) * ($Orbit[1] * 1.5e8 * $SUN_MU))
EndFunc   ;==>_Orbit_CalcSpecificAngMomentum

Func _Orbit_CalcMeanMotion(ByRef $Orbit)
    If $Orbit[2] > 1 Then
        Return _Orbit_CalcHyperbolicMeanMotion($Orbit)
    ElseIf $Orbit[2] < 1 Then
        Return _Orbit_CalcEllipticalMeanMotion($Orbit)
    Else
        Return _Orbit_CalcParabolicMeanMotion($Orbit)
    EndIf
EndFunc   ;==>_Orbit_CalcMeanMotion

Func _Orbit_CalcAsymptoticTrueAnomaly(ByRef $Orbit)
    If $Orbit[2] <= 1 Then Return 3.14159265359
    Return ACos(-1 / $Orbit[2])
EndFunc   ;==>_Orbit_CalcAsymptoticTrueAnomaly


; ========== AVAILABLE CALCULATIONS  =============


#cs

FROM:       TO: DATE    REFTIME SEC.SINCE.PERI  TRUE.ANOMALY    POLAR   CARTESIAN   RADIUS  SPEED
DATE            *       YES     ind1            ind2            ind2    ind3
REFTIME                 *       YES                             ind2    ind2
SEC.SINCE.PERI                  *               YES             ind1    ind2
TRUE.ANOMALY                                    *                       ind1        YES
POLAR                                                           *       YES
CARTESIAN                                                               *
RADIUS                                                                              *       YES
SPEED                                                                                       *

#ce


; ========== DIRECT CALCULATIONS ===========


Func _Orbit_CalcRefTimeAtDate($time = _NowCalcDate())
    $refTime = _DateDiff("s", $_ORBIT_REFERENCE_DATE, $time)
    If $refTime = 0 Then $refTime = -_DateDiff("s", $time, $_ORBIT_REFERENCE_DATE)
    Return $refTime
EndFunc   ;==>_Orbit_CalcRefTimeAtDate

Func _Orbit_CalcMeanAnomalyAtDate(ByRef $Orbit, $time = _NowCalcDate())
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtDate($Orbit, $time)
    $meanAnomaly = $Orbit[10] * $SecondsSincePeriapsis
    Return $meanAnomaly
EndFunc   ;==>_Orbit_CalcMeanAnomalyAtDate

Func _Orbit_CalcMeanAnomalyAtRefTime(ByRef $Orbit, $refTime)
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtRefTime($Orbit, $refTime)
    $meanAnomaly = $Orbit[10] * $SecondsSincePeriapsis
    Return $meanAnomaly
EndFunc

Func _Orbit_CalcSecondsSincePeriapsisAtRefTime(ByRef $Orbit, $refTime)
    Return $refTime - $Orbit[12]
EndFunc   ;==>_Orbit_CalcSecondsSincePeriapsisAtRefTime

Func _Orbit_CalcSpeedAtDistanceKm(ByRef $Orbit, $distanceKm)
    Return $Orbit[9] / $distanceKm
EndFunc   ;==>_Orbit_CalcSpeedAtDistanceKm

Func _Orbit_CalcOrbitRadiusKmAtTrueAnomaly(ByRef $Orbit, $trueAnomaly)
    Return $Orbit[9] ^ 2 / $SUN_MU / (1 + $Orbit[2] * Cos($trueAnomaly))
EndFunc   ;==>_Orbit_CalcOrbitRadiusKmAtTrueAnomaly

Func _Orbit_CalcTrueAnomalyAtSecondsSincePeriapsis(ByRef $Orbit, $SecondsSincePeriapsis)
    If $Orbit[2] > 1 Then
        Return _Orbit_CalcHyperbolicTrueAnomaly($Orbit, $SecondsSincePeriapsis)
    ElseIf $Orbit[2] < 1 Then
        Return _Orbit_CalcEllipticalTrueAnomaly($Orbit, $SecondsSincePeriapsis)
    Else
        Return _Orbit_CalcParabolicTrueAnomaly($Orbit, $SecondsSincePeriapsis)
    EndIf
EndFunc   ;==>_Orbit_CalcTrueAnomalyAtSecondsSincePeriapsis

Func _Orbit_CalcCartesianCoordsAtPolarCoords(ByRef $Orbit, $polar)
    Dim $cartesian[3] = [0, 0, 0]

    ; _Orbit_Calcualte in-plane coordinates and argument of periapsis
    $cartesian[0] = Cos($polar[1] + $Orbit[3]) * $polar[0]
    $cartesian[1] = 0
    $cartesian[2] = Sin($polar[1] + $Orbit[3]) * $polar[0]

    ; Apply inclination
    $cartesian[1] = Sin($Orbit[5]) * $cartesian[2]
    $cartesian[2] = Cos($Orbit[5]) * $cartesian[2]

    ; Apply longitude of ascending node
    $x = -Cos($Orbit[4]) * $cartesian[0] + Sin($Orbit[4]) * $cartesian[2]
    $z = -Cos($Orbit[4]) * $cartesian[2] - Sin($Orbit[4]) * $cartesian[0]

    $cartesian[0] = $x
    $cartesian[2] = $z

    Return $cartesian
EndFunc   ;==>_Orbit_CalcCartesianCoordsAtPolarCoords


;  ELLIPTICAL ORBITS


Func _Orbit_CalcEllSemiMajorAxis(ByRef $Orbit)
    If $Orbit[2] >= 1 Then Return -1
    $semiMajorAxis = $Orbit[9] ^ 2 / ($SUN_MU * (1 - $Orbit[2] ^ 2))
    Return $semiMajorAxis
EndFunc   ;==>_Orbit_CalcEllSemiMajorAxis

Func _Orbit_CalcEllOrbitalPeriod(ByRef $Orbit)
    If $Orbit[2] >= 1 Then Return -1
    $semiMajorAxis = _Orbit_CalcEllSemiMajorAxis($Orbit)
    $orbitalPeriod = 2 * 3.14159265359 / Sqrt($SUN_MU) * $semiMajorAxis ^ (3 / 2)
    Return $orbitalPeriod
EndFunc   ;==>_Orbit_CalcEllOrbitalPeriod

Func _Orbit_CalcEllipticalMeanMotion(ByRef $Orbit)
    $semiMajorAxis = _Orbit_CalcEllSemiMajorAxis($Orbit)
    $ellMeanMotion = Sqrt($SUN_MU) / $semiMajorAxis ^ (3 / 2)
    Return $ellMeanMotion
EndFunc   ;==>_Orbit_CalcEllipticalMeanMotion

Func _Orbit_CalcEllEccentricAnomaly(ByRef $Orbit, $SecondsSincePeriapsis)
    $meanAnomaly = $Orbit[10] * $SecondsSincePeriapsis

    ; Normalize mean anomaly so the solver converges faster
    $num_excess_pi = ($meanAnomaly + 3.14159265359) / (2 * 3.14159265359)
    $num_excess_pi = Floor($num_excess_pi)
    $meanAnomaly -= 2 * $num_excess_pi * 3.14159265359

    $E = 0

    For $i = 0 To 25
        ;ConsoleWrite("E" & $i & ": " & $E & @CRLF)
        $ex = $E - $Orbit[2] * Sin($E) - $meanAnomaly ; Kepler
        $exdx = 1 - $Orbit[2] * Cos($E) ; Kepler_d_dF
        ;ConsoleWrite(" ex: " & $ex & @CRLF)
        ;ConsoleWrite(" exdx: " & $exdx & @CRLF)

        If Abs($ex / $exdx) < 1E-6 Then ExitLoop
        $E = $E - $ex / $exdx

        If $E > 4 Then $E = 4
        If $E < -4 Then $E = -4

    Next

    ;ConsoleWrite("Final E: " & $E & @CRLF)
    Return $E
EndFunc   ;==>_Orbit_CalcEllEccentricAnomaly

Func _Orbit_CalcEllipticalTrueAnomaly(ByRef $Orbit, $SecondsSincePeriapsis)
    $ellEccAnomaly = _Orbit_CalcEllEccentricAnomaly($Orbit, $SecondsSincePeriapsis)
    Return 2 * ATan(Sqrt((1 + $Orbit[2]) / (1 - $Orbit[2])) * Tan($ellEccAnomaly / 2))
EndFunc   ;==>_Orbit_CalcEllipticalTrueAnomaly


; PARABOLIC ORBITS


Func _Orbit_CalcParabolicMeanMotion(ByRef $Orbit)
    Return $SUN_MU ^ 2 / $Orbit[9] ^ 3
EndFunc   ;==>_Orbit_CalcParabolicMeanMotion

Func _Orbit_CalcParabolicTrueAnomaly(ByRef $Orbit, $SecondsSincePeriapsis)
    $meanAnomaly = $Orbit[10] * $SecondsSincePeriapsis
    $z = (3 * $meanAnomaly + Sqrt(1 + (3 * $meanAnomaly) ^ 2)) ^ (1 / 3)
    Return 2 * ATan($z - 1 / $z)
EndFunc   ;==>_Orbit_CalcParabolicTrueAnomaly


; HYPERBOLIC ORBITS


Func _Orbit_CalcHyperbolicMeanMotion(ByRef $Orbit)
    Return ($SUN_MU ^ 2 / $Orbit[9] ^ 3) * ($Orbit[2] ^ 2 - 1) ^ (3 / 2)
EndFunc   ;==>_Orbit_CalcHyperbolicMeanMotion

Func _Orbit_CalcHypEccentricAnomaly(ByRef $Orbit, $SecondsSincePeriapsis)
    $meanAnomaly = $Orbit[10] * $SecondsSincePeriapsis

    ;ConsoleWrite("Initial M: " & $meanAnomaly & @CRLF)
    If $meanAnomaly < 0 Then
        $F = -1
    Else
        $F = 1
    EndIf

    For $i = 0 To 25
        ;ConsoleWrite("F" & $i & ": " & $F & @CRLF)
        $fx = $Orbit[2] * sinh($F) - $F - $meanAnomaly ; Kepler
        $fxdx = $Orbit[2] * cosh($F) - 1 ; Kepler_d_dF
        ;ConsoleWrite(" fx: " & $fx & @CRLF)
        ;ConsoleWrite(" fxdx: " & $fxdx & @CRLF)
        ;ConsoleWrite("  " & $Orbit[2] & " * " & cosh($F) & " - 1" & @CRLF)
        ;ConsoleWrite("    " & $F & @CRLF)
        If Abs($fx / $fxdx) < 1E-8 Then ExitLoop
        $F = $F - $fx / $fxdx ; Newton my beloved
    Next
    ;ConsoleWrite("Final F: " & $F & @CRLF)
    Return SetExtended($i, $F)
EndFunc   ;==>_Orbit_CalcHypEccentricAnomaly

Func _Orbit_CalcHyperbolicTrueAnomaly(ByRef $Orbit, $SecondsSincePeriapsis)
    $hypEccAnomaly = _Orbit_CalcHypEccentricAnomaly($Orbit, $SecondsSincePeriapsis)
    $nu = (2 * ATan(Sqrt(($Orbit[2] + 1) / ($Orbit[2] - 1)) * tanh($hypEccAnomaly / 2)))
    Return $nu
EndFunc   ;==>_Orbit_CalcHyperbolicTrueAnomaly

Func _Orbit_CalcApparentMagnitude(ByRef $Orbit, $sunDistanceKm, $earthDistanceKm)
    Return $Orbit[6] + 5 * Log10($earthDistanceKm / 1.5e8) + 2.5 * $Orbit[7] * Log10($sunDistanceKm / 1.5e8)
EndFunc   ;==>_Orbit_CalcApparentMagnitude

Func Log10($fNb)
    Return Log($fNb) / Log(10) ; 10 is the base
EndFunc   ;==>Log10

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


; ========= INDIRECT 1 DEGREE =============


Func _Orbit_CalcSecondsSincePeriapsisAtDate(ByRef $Orbit, $time = _NowCalcDate())
    $refTime = _Orbit_CalcRefTimeAtDate($time)
    Return _Orbit_CalcSecondsSincePeriapsisAtRefTime($Orbit, $refTime)
EndFunc   ;==>_Orbit_CalcSecondsSincePeriapsisAtDate

Func _Orbit_CalcPolarCoordsAtSecondsSincePeriapsis(ByRef $Orbit, $SecondsSincePeriapsis)
    Dim $polar[2]

    $trueAnomaly = _Orbit_CalcTrueAnomalyAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
    $radius = _Orbit_CalcOrbitRadiusKmAtTrueAnomaly($Orbit, $trueAnomaly)

    $polar[0] = $radius
    $polar[1] = $trueAnomaly

    Return $polar
EndFunc   ;==>_Orbit_CalcPolarCoordsAtSecondsSincePeriapsis

Func _Orbit_CalcCartesianCoordsAtTrueAnomaly(ByRef $Orbit, $trueAnomaly)
    Dim $polar[2] = [_Orbit_CalcOrbitRadiusKmAtTrueAnomaly($Orbit, $trueAnomaly), $trueAnomaly]
    Return _Orbit_CalcCartesianCoordsAtPolarCoords($Orbit, $polar)
EndFunc   ;==>_Orbit_CalcCartesianCoordsAtTrueAnomaly


; ========== INDIRECT 2 DEGREES ==========


Func _Orbit_CalcPolarCoordsAtRefTime(ByRef $Orbit, $refTime)
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtRefTime($Orbit, $refTime)
    Return _Orbit_CalcPolarCoordsAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
EndFunc   ;==>_Orbit_CalcPolarCoordsAtRefTime

Func _Orbit_CalcTrueAnomalyAtDate(ByRef $Orbit, $time = _NowCalcDate())
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtDate($Orbit, $time)
    Return _Orbit_CalcTrueAnomalyAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
EndFunc   ;==>_Orbit_CalcTrueAnomalyAtDate

Func _Orbit_CalcPolarCoordsAtDate(ByRef $Orbit, $time = _NowCalcDate())
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtDate($Orbit, $time)
    Return _Orbit_CalcPolarCoordsAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
EndFunc   ;==>_Orbit_CalcPolarCoordsAtDate

Func _Orbit_CalcCartesianCoordsAtRefTime(ByRef $Orbit, $refTime)
    $SecondsSincePeriapsis = _Orbit_CalcSecondsSincePeriapsisAtRefTime($Orbit, $refTime)
    Return _Orbit_CalcCartesianCoordsAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
EndFunc   ;==>_Orbit_CalcCartesianCoordsAtRefTime

Func _Orbit_CalcCartesianCoordsAtSecondsSincePeriapsis(ByRef $Orbit, $SecondsSincePeriapsis)
    $trueAnomaly = _Orbit_CalcTrueAnomalyAtSecondsSincePeriapsis($Orbit, $SecondsSincePeriapsis)
    Return _Orbit_CalcCartesianCoordsAtTrueAnomaly($Orbit, $trueAnomaly)
EndFunc   ;==>_Orbit_CalcCartesianCoordsAtSecondsSincePeriapsis


; ========== INDIRECT 3 DEGREES ==========


Func _Orbit_CalcCartesianCoordsAtDate(ByRef $Orbit, $time = _NowCalcDate())
    $trueAnomaly = _Orbit_CalcTrueAnomalyAtDate($Orbit, $time)
    Return _Orbit_CalcCartesianCoordsAtTrueAnomaly($Orbit, $trueAnomaly)
EndFunc   ;==>_Orbit_CalcCartesianCoordsAtDate
