extends Node2D

export(float) var nCollisionSeparationPadding = 6.0
export(float) var nCollisionRestitution = 0.25

func _physics_process(delta: float) -> void:
    if Engine.editor_hint:
        return

    var vPlanets = _GetOrbitingPlanets()
    if vPlanets.size() < 2:
        return

    var vAccelerations = {}
    for pPlanet in vPlanets:
        vAccelerations[pPlanet] = Vector2.ZERO

    for i in range(vPlanets.size()):
        for j in range(i + 1, vPlanets.size()):
            var pPlanetA = vPlanets[i]
            var pPlanetB = vPlanets[j]
            var vAccelOnA = pPlanetA.GetMutualGravityAcceleration(
                pPlanetB.global_position,
                pPlanetB.nPlanetMass,
                pPlanetB.nGravityRadius
            )
            var vAccelOnB = pPlanetB.GetMutualGravityAcceleration(
                pPlanetA.global_position,
                pPlanetA.nPlanetMass,
                pPlanetA.nGravityRadius
            )
            vAccelerations[pPlanetA] += vAccelOnA
            vAccelerations[pPlanetB] += vAccelOnB

    for pPlanet in vPlanets:
        pPlanet.vVelocity += vAccelerations[pPlanet] * delta
        pPlanet.global_position += pPlanet.vVelocity * delta

    _ResolvePlanetCollisions(vPlanets)

func _GetOrbitingPlanets() -> Array:
    var vPlanets = []
    for pChild in get_children():
        if pChild == null or not is_instance_valid(pChild):
            continue
        if not pChild.has_method("GetMutualGravityAcceleration"):
            continue
        if not pChild.bOrbitalMotion:
            continue
        vPlanets.append(pChild)
    return vPlanets

func _ResolvePlanetCollisions(vPlanets: Array) -> void:
    for i in range(vPlanets.size()):
        for j in range(i + 1, vPlanets.size()):
            var pPlanetA = vPlanets[i]
            var pPlanetB = vPlanets[j]
            var vDelta = pPlanetB.global_position - pPlanetA.global_position
            var nDist = vDelta.length()
            var nMinDist = pPlanetA.GetCollisionRadius() + pPlanetB.GetCollisionRadius() + nCollisionSeparationPadding
            if nDist >= nMinDist or nDist <= 0.001:
                continue

            var vNormal = vDelta / nDist
            var nOverlap = nMinDist - nDist
            var nMassA = max(pPlanetA.nPlanetMass, 1.0)
            var nMassB = max(pPlanetB.nPlanetMass, 1.0)
            var nTotalMass = nMassA + nMassB
            pPlanetA.global_position -= vNormal * nOverlap * (nMassB / nTotalMass)
            pPlanetB.global_position += vNormal * nOverlap * (nMassA / nTotalMass)

            var vRelativeVelocity = pPlanetB.vVelocity - pPlanetA.vVelocity
            var nRelativeNormal = vRelativeVelocity.dot(vNormal)
            if nRelativeNormal >= 0.0:
                continue

            var nInvMassSum = 1.0 / nMassA + 1.0 / nMassB
            var nImpulse = -(1.0 + nCollisionRestitution) * nRelativeNormal / nInvMassSum
            pPlanetA.vVelocity -= vNormal * nImpulse / nMassA
            pPlanetB.vVelocity += vNormal * nImpulse / nMassB

static func ApplyBinaryOrbitVelocity(pPlanetA, pPlanetB) -> void:
    if pPlanetA == null or pPlanetB == null:
        return
    if not is_instance_valid(pPlanetA) or not is_instance_valid(pPlanetB):
        return

    var vDelta = pPlanetB.global_position - pPlanetA.global_position
    var nSeparation = vDelta.length()
    if nSeparation <= 0.001:
        return

    var vDirection = vDelta / nSeparation
    var vTangent = Vector2(-vDirection.y, vDirection.x)
    var nMassA = max(pPlanetA.nPlanetMass, 1.0)
    var nMassB = max(pPlanetB.nPlanetMass, 1.0)
    var nSpeedA = sqrt(nMassB * nMassB / (nSeparation * (nMassA + nMassB)))
    var nSpeedB = sqrt(nMassA * nMassA / (nSeparation * (nMassA + nMassB)))
    pPlanetA.vVelocity = vTangent * nSpeedA
    pPlanetB.vVelocity = -vTangent * nSpeedB
    pPlanetA.bOrbitalMotion = true
    pPlanetB.bOrbitalMotion = true
