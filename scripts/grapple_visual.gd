extends Reference

const O_CHAIN_DARK = Color(0.42, 0.46, 0.54, 0.95)
const O_CHAIN_LIGHT = Color(0.74, 0.78, 0.86, 0.95)
const O_ANCHOR_DARK = Color(0.55, 0.58, 0.66, 0.98)
const O_ANCHOR_LIGHT = Color(0.88, 0.9, 0.95, 0.98)

static func DrawChain(pCanvas, vFrom: Vector2, vTo: Vector2) -> void:
    var vSeg = vTo - vFrom
    var nLen = vSeg.length()
    if nLen <= 0.001:
        return

    var vDir = vSeg / nLen
    var vPerp = Vector2(-vDir.y, vDir.x)
    var nLinkSpacing = 11.0
    var nDist = 0.0
    var i = 0

    while nDist < nLen:
        var nBarLen = min(5.5, nLen - nDist)
        var vBarStart = vFrom + vDir * nDist
        var vBarEnd = vFrom + vDir * (nDist + nBarLen)
        pCanvas.draw_line(vBarStart, vBarEnd, O_CHAIN_LIGHT, 2.0, true)
        nDist += nBarLen

        if nDist >= nLen - 0.001:
            break

        var nGap = min(nLinkSpacing, nLen - nDist)
        var vLinkCenter = vFrom + vDir * (nDist + nGap * 0.5)
        var nTilt = 0.42 if i % 2 == 0 else -0.42
        var vTilt = vPerp.rotated(nTilt)
        pCanvas.draw_line(vLinkCenter - vTilt * 3.2, vLinkCenter + vTilt * 3.2, O_CHAIN_DARK, 3.0, true)
        pCanvas.draw_line(vLinkCenter - vDir * 2.2, vLinkCenter + vDir * 2.2, O_CHAIN_LIGHT, 1.5, true)
        nDist += nGap
        i += 1

static func DrawAnchorHead(pCanvas, vPos: Vector2, vTowardShip: Vector2, nScale: float = 1.0) -> void:
    var vUp = vTowardShip
    if vUp.length_squared() <= 0.001:
        vUp = Vector2.UP
    else:
        vUp = vUp.normalized()

    var vRight = Vector2(-vUp.y, vUp.x)
    var nS = max(0.6, nScale)
    var vRing = vPos + vUp * 6.0 * nS
    var vCross = vPos + vUp * 1.5 * nS
    var vTip = vPos - vUp * 2.0 * nS

    pCanvas.draw_circle(vRing, 3.0 * nS, O_ANCHOR_DARK)
    pCanvas.draw_arc(vRing, 3.0 * nS, 0.0, TAU, 14, O_ANCHOR_LIGHT, 1.5, true)
    pCanvas.draw_line(vRing, vCross, O_ANCHOR_LIGHT, 2.0, true)
    pCanvas.draw_line(vCross, vTip, O_ANCHOR_LIGHT, 2.0, true)
    pCanvas.draw_line(vTip, vTip + vRight * 7.0 * nS, O_ANCHOR_LIGHT, 2.5, true)
    pCanvas.draw_line(vTip, vTip - vRight * 7.0 * nS, O_ANCHOR_LIGHT, 2.5, true)
    pCanvas.draw_line(vCross + vRight * 5.0 * nS, vCross - vRight * 5.0 * nS, O_ANCHOR_DARK, 2.0, true)

    var vLeftHook = vTip + vRight * 5.5 * nS - vUp * 2.5 * nS
    var vRightHook = vTip - vRight * 5.5 * nS - vUp * 2.5 * nS
    pCanvas.draw_line(vTip + vRight * 7.0 * nS, vLeftHook, O_ANCHOR_LIGHT, 2.0, true)
    pCanvas.draw_line(vTip - vRight * 7.0 * nS, vRightHook, O_ANCHOR_LIGHT, 2.0, true)
