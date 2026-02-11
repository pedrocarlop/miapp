/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/MetalFXShaderSource.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: MetalFXShaderSource,FXVertexOut FXOverlayUniforms
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

import Foundation

enum MetalFXShaderSource {
    static let source = """
#include <metal_stdlib>
using namespace metal;

struct FXVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct FXOverlayUniforms {
    float2 resolution;
    float2 center;
    float progress;
    float maxRadius;
    float ringWidth;
    float alpha;
    float intensity;
    float debugEnabled;
    float2 pathStart;
    float2 pathEnd;
    float4 bounds;
    float time;
    float effectKind;
    float2 params;
};

float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 34.45);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float smoothstepFx(float edge0, float edge1, float value) {
    float delta = edge1 - edge0;
    if (fabs(delta) < 1e-5) {
        return value >= edge0 ? 1.0 : 0.0;
    }

    float t = clamp((value - edge0) / delta, 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

float easeOutCubic(float value) {
    float t = clamp(value, 0.0, 1.0);
    float oneMinusT = 1.0 - t;
    return 1.0 - oneMinusT * oneMinusT * oneMinusT;
}

float distanceToSegment(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float denominator = max(dot(ab, ab), 1e-6);
    float t = clamp(dot(p - a, ab) / denominator, 0.0, 1.0);
    float2 projection = a + ab * t;
    return distance(p, projection);
}

float debugBoundsMask(float2 pixel, float4 bounds) {
    float left = 1.0 - smoothstepFx(0.0, 1.25, fabs(pixel.x - bounds.x));
    float right = 1.0 - smoothstepFx(0.0, 1.25, fabs(pixel.x - (bounds.x + bounds.z)));
    float top = 1.0 - smoothstepFx(0.0, 1.25, fabs(pixel.y - bounds.y));
    float bottom = 1.0 - smoothstepFx(0.0, 1.25, fabs(pixel.y - (bounds.y + bounds.w)));

    bool inside = pixel.x >= bounds.x && pixel.x <= bounds.x + bounds.z
        && pixel.y >= bounds.y && pixel.y <= bounds.y + bounds.w;
    return inside ? max(max(left, right), max(top, bottom)) : 0.0;
}

vertex FXVertexOut vertex_passthrough(uint vertexID [[vertex_id]]) {
    constexpr float2 clipSpaceVertices[6] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(-1.0, 1.0),
        float2(1.0, -1.0),
        float2(1.0, 1.0)
    };

    FXVertexOut output;
    float2 clip = clipSpaceVertices[vertexID];
    output.position = float4(clip, 0.0, 1.0);
    output.uv = float2((clip.x + 1.0) * 0.5, 1.0 - (clip.y + 1.0) * 0.5);
    return output;
}

float4 renderWaveFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    float2 pixel = input.uv * uniforms.resolution;

    float dist = distance(pixel, uniforms.center);
    float radius = uniforms.progress * uniforms.maxRadius;
    float ringWidth = max(uniforms.ringWidth, 1.0);
    float ringOuter = smoothstepFx(radius + ringWidth * 0.38, radius - ringWidth * 0.98, dist);
    float ringInner = smoothstepFx(radius - ringWidth * 0.18, radius - ringWidth * 1.36, dist);
    float ringTail = smoothstepFx(radius + ringWidth * 1.12, radius + ringWidth * 0.10, dist);
    float ring = ringOuter * 0.74 + ringInner * 0.34 + ringTail * 0.24;

    float secondaryRadius = radius * 0.62;
    float secondaryWidth = ringWidth * 0.7;
    float secondaryRingOuter = smoothstepFx(
        secondaryRadius + secondaryWidth * 0.74,
        secondaryRadius - secondaryWidth * 0.9,
        dist
    );
    float secondaryRingInner = smoothstepFx(
        secondaryRadius - secondaryWidth * 0.20,
        secondaryRadius - secondaryWidth * 1.28,
        dist
    );
    float secondaryRing = (secondaryRingOuter * 0.7 + secondaryRingInner * 0.3)
        * (1.0 - smoothstepFx(0.36, 0.92, uniforms.progress));

    float waveFade = (1.0 - smoothstepFx(0.82, 1.0, uniforms.progress));
    float radialPhase = dist * 0.085 - uniforms.time * 8.6;
    float shimmer = 0.92 + 0.08 * sin(radialPhase + uniforms.progress * 5.2);
    float grain = 0.94 + 0.06 * noise((pixel - uniforms.center) * 0.045 + uniforms.time * 0.22);

    float coreFlash = exp(-dist / max(16.0, ringWidth * 2.9))
        * (1.0 - smoothstepFx(0.0, 0.42, uniforms.progress));
    float halo = exp(-dist / max(44.0, uniforms.maxRadius * 0.60))
        * (1.0 - smoothstepFx(0.24, 1.0, uniforms.progress));

    float rippleMask = ring + secondaryRing * 0.42 + coreFlash * 0.42 + halo * 0.2;
    float alpha = rippleMask * waveFade * uniforms.alpha * shimmer * grain;

    float chroma = 0.5 + 0.5 * sin(radialPhase * 0.78 + uniforms.intensity * 2.5 + coreFlash * 2.6);
    float3 orangeCore = mix(float3(0.98, 0.56, 0.12), float3(1.0, 0.66, 0.20), uniforms.intensity);
    float3 orangeGlow = mix(float3(0.90, 0.34, 0.08), float3(0.98, 0.44, 0.12), uniforms.intensity);
    float3 amberHighlight = mix(float3(1.0, 0.78, 0.40), float3(1.0, 0.86, 0.54), uniforms.intensity);
    float3 baseColor = mix(orangeGlow, orangeCore, 0.64 + chroma * 0.18);
    baseColor = mix(baseColor, amberHighlight, 0.10 + chroma * 0.2 + coreFlash * 0.12);

    if (uniforms.debugEnabled > 0.5) {
        float centerMark = 1.0 - smoothstepFx(0.0, 4.0, distance(pixel, uniforms.center));
        float pathMark = 1.0 - smoothstepFx(0.0, 1.8, distanceToSegment(pixel, uniforms.pathStart, uniforms.pathEnd));
        float boundsMark = debugBoundsMask(pixel, uniforms.bounds);

        baseColor = mix(baseColor, float3(0.12, 0.96, 0.68), centerMark);
        baseColor = mix(baseColor, float3(0.92, 0.30, 0.98), pathMark * 0.8);
        baseColor = mix(baseColor, float3(0.24, 0.64, 1.0), boundsMark * 0.85);
        alpha = max(alpha, max(centerMark * 0.55, max(pathMark * 0.4, boundsMark * 0.42)));
    }

    return float4(baseColor, alpha);
}

float4 renderScanlineFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    float2 pixel = input.uv * uniforms.resolution;
    float2 axis = uniforms.pathEnd - uniforms.pathStart;
    float axisLength = max(length(axis), 1e-4);
    float2 direction = axis / axisLength;
    float2 rel = pixel - uniforms.pathStart;

    float projection = dot(rel, direction);
    float head = uniforms.progress * axisLength;
    float axialOffset = projection - head;
    float trailLength = max(uniforms.params.x, 1.0);
    float behind = max(-axialOffset, 0.0);
    float ahead = max(axialOffset, 0.0);

    float headMask = 1.0 - smoothstepFx(0.0, trailLength * 0.2, fabs(axialOffset));
    float trailMask = (1.0 - smoothstepFx(0.0, trailLength, behind)) * step(0.0, behind);
    float leadMask = (1.0 - smoothstepFx(0.0, trailLength * 0.24, ahead)) * step(0.0, ahead);
    float axialMask = max(headMask, trailMask * 0.82 + leadMask * 0.2);

    float inSegment = step(0.0, projection) * step(projection, axisLength);
    float signedPerpendicularDistance = rel.x * direction.y - rel.y * direction.x;
    float perpendicularDistance = fabs(signedPerpendicularDistance);
    float coreThickness = max(uniforms.params.y, 0.2);
    float core = 1.0 - smoothstepFx(coreThickness, coreThickness + 0.85, perpendicularDistance);
    float glow = 1.0 - smoothstepFx(coreThickness * 3.4, coreThickness * 6.1, perpendicularDistance);
    float edgeGlow = 1.0 - smoothstepFx(coreThickness * 1.7, coreThickness * 3.2, perpendicularDistance);

    float pulse = 0.95 + 0.05 * sin(uniforms.time * 20.0 + uniforms.progress * 6.0);
    float grain = 0.9 + 0.1 * noise(pixel * 0.065 + uniforms.time * 0.9);
    float alpha = inSegment * axialMask * (core * 0.9 + glow * 0.48) * uniforms.alpha * pulse * grain;

    float3 color = mix(float3(0.98, 0.92, 0.70), float3(1.0, 0.99, 0.86), uniforms.intensity);
    float side = smoothstepFx(-1.0, 1.0, signedPerpendicularDistance);
    float3 fringeA = float3(0.96, 0.80, 1.0);
    float3 fringeB = float3(0.72, 1.0, 0.93);
    float3 fringeColor = mix(fringeA, fringeB, side);
    color += glow * 0.06 + headMask * 0.08;
    color = mix(color, fringeColor, edgeGlow * 0.12 * uniforms.intensity);

    if (uniforms.debugEnabled > 0.5) {
        float centerMark = 1.0 - smoothstepFx(0.0, 4.0, distance(pixel, uniforms.center));
        float pathMark = 1.0 - smoothstepFx(0.0, 1.8, distanceToSegment(pixel, uniforms.pathStart, uniforms.pathEnd));
        float boundsMark = debugBoundsMask(pixel, uniforms.bounds);
        color = mix(color, float3(0.12, 0.96, 0.68), centerMark);
        color = mix(color, float3(0.92, 0.30, 0.98), pathMark * 0.8);
        color = mix(color, float3(0.24, 0.64, 1.0), boundsMark * 0.85);
        alpha = max(alpha, max(centerMark * 0.55, max(pathMark * 0.4, boundsMark * 0.42)));
    }

    return float4(color, alpha);
}

float3 confettiPalette(float value) {
    float r = 0.58 + 0.42 * sin(6.2831853 * (value + 0.02));
    float g = 0.56 + 0.44 * sin(6.2831853 * (value + 0.36));
    float b = 0.58 + 0.42 * sin(6.2831853 * (value + 0.67));
    return clamp(float3(r, g, b), 0.18, 1.0);
}

float4 renderParticlesFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    float2 pixel = input.uv * uniforms.resolution;
    float2 axis = uniforms.pathEnd - uniforms.pathStart;
    float axisLength = max(length(axis), 1e-4);
    float2 direction = axis / axisLength;
    float2 orthogonal = float2(-direction.y, direction.x);

    float progress = clamp(uniforms.progress, 0.0, 1.0);
    float localRadius = max(uniforms.maxRadius, 1.0);
    float shellRadius = localRadius * (0.28 + 0.92 * progress);
    float farMask = 1.0 - smoothstepFx(shellRadius + 40.0, shellRadius + 120.0, distance(pixel, uniforms.center));
    if (farMask <= 0.0001) {
        return float4(0.0);
    }

    int particleCount = int(clamp(round(uniforms.params.x), 6.0, 64.0));
    float speedScale = max(uniforms.params.y, 0.25);
    float confettiMode = step(2.5, uniforms.effectKind);

    float3 colorAccum = float3(0.0);
    float alphaAccum = 0.0;

    for (int index = 0; index < 64; index++) {
        if (index >= particleCount) {
            break;
        }

        float id = float(index);
        float seedA = hash(float2(id * 0.173 + uniforms.center.x * 0.011, uniforms.center.y * 0.013 + uniforms.time * 0.017));
        float seedB = hash(float2(id * 0.367 + uniforms.center.y * 0.009, uniforms.center.x * 0.015 + uniforms.time * 0.029));
        float seedC = hash(float2(id * 0.613 + uniforms.pathStart.x * 0.006, uniforms.pathEnd.y * 0.007 + uniforms.time * 0.013));
        float seedD = hash(float2(id * 0.809 + uniforms.pathEnd.x * 0.005, uniforms.pathStart.y * 0.011 + uniforms.time * 0.031));

        float spawnDelayWord = seedB * 0.12;
        float spawnDelayConfetti = seedB * 0.24;
        float spawnDelay = mix(spawnDelayWord, spawnDelayConfetti, confettiMode);
        float spawnGate = smoothstepFx(spawnDelay, spawnDelay + 0.04, progress);
        float releaseStartWord = 0.78 + seedC * 0.18;
        float releaseStartConfetti = 0.84 + seedC * 0.14;
        float releaseStart = mix(releaseStartWord, releaseStartConfetti, confettiMode);
        float decayGate = 1.0 - smoothstepFx(releaseStart, 1.0, progress);
        float life = spawnGate * decayGate;
        if (life <= 0.0001) {
            continue;
        }

        float baseAngle = atan2(direction.y, direction.x);
        float spread = 0.55 + seedB * 0.75;
        float angleWord = baseAngle + (seedA * 2.0 - 1.0) * spread;
        float angleConfetti = seedA * 6.2831853;
        float angle = mix(angleWord, angleConfetti, confettiMode);
        float2 dir = float2(cos(angle), sin(angle));

        float speed = localRadius * (0.34 + seedC * 0.74) * speedScale;
        float radialTravel = speed * progress;
        float2 position = uniforms.center + dir * radialTravel;

        float lateralWord = (seedD - 0.5) * 16.0;
        float lateralConfetti = (seedD - 0.5) * 4.0;
        float lateralOffset = mix(lateralWord, lateralConfetti, confettiMode);
        position += orthogonal * lateralOffset;
        position.y += confettiMode * progress * progress * (16.0 + seedD * 28.0);

        float sizeWord = mix(2.4, 4.8, seedB);
        float sizeConfetti = mix(2.8, 5.4, seedB);
        float size = mix(sizeWord, sizeConfetti, confettiMode);
        size *= (0.85 + uniforms.intensity * 0.55);
        float shrinkWord = 1.0 - progress * 0.42;
        float shrinkConfetti = 1.0 - progress * 0.24;
        size *= max(0.3, mix(shrinkWord, shrinkConfetti, confettiMode));

        float2 delta = pixel - position;
        float distToParticle = length(delta);
        float core = exp(-distToParticle * distToParticle / max(3.0, size * size));

        float2 tailDirection = normalize(-dir + float2(1e-4, 1e-4));
        float axial = dot(delta, tailDirection);
        float side = abs(dot(delta, float2(-tailDirection.y, tailDirection.x)));
        float tailLength = size * mix(2.2, 1.4, confettiMode);
        float tailMask = step(0.0, axial);
        float tail = exp(-axial / max(1.0, tailLength))
            * exp(-side * side / max(1.0, size * size * 1.8))
            * tailMask
            * (1.0 - confettiMode * 0.55);

        float contribution = (core + tail * 0.52) * life;
        alphaAccum += contribution;

        float3 warmA = mix(float3(1.0, 0.68, 0.22), float3(1.0, 0.85, 0.46), seedD);
        float3 warmB = mix(float3(1.0, 0.52, 0.16), float3(1.0, 0.72, 0.28), seedB);
        float3 sparkColor = mix(warmA, warmB, 0.45 + 0.4 * seedC);
        float3 confettiColor = confettiPalette(fract(seedA + seedB * 0.73 + progress * 0.12));
        float3 particleColor = mix(sparkColor, confettiColor, confettiMode);
        colorAccum += particleColor * contribution;
    }

    float normalizedAlpha = min(alphaAccum * uniforms.alpha * farMask, 1.0);
    if (normalizedAlpha <= 0.0001) {
        return float4(0.0);
    }

    float3 color = colorAccum / max(alphaAccum, 1e-4);
    float centerGlow = exp(-distance(pixel, uniforms.center) / max(14.0, localRadius * 0.24))
        * (1.0 - smoothstepFx(0.0, 0.45, progress));
    float3 centerGlowColor = mix(float3(1.0, 0.66, 0.26), float3(1.0, 0.86, 0.52), uniforms.intensity);
    color += centerGlowColor * centerGlow * (1.0 - confettiMode) * 0.42;
    normalizedAlpha = min(normalizedAlpha + centerGlow * uniforms.alpha * (1.0 - confettiMode) * 0.16, 1.0);

    if (uniforms.debugEnabled > 0.5) {
        float centerMark = 1.0 - smoothstepFx(0.0, 4.0, distance(pixel, uniforms.center));
        float pathMark = 1.0 - smoothstepFx(0.0, 1.8, distanceToSegment(pixel, uniforms.pathStart, uniforms.pathEnd));
        float boundsMark = debugBoundsMask(pixel, uniforms.bounds);
        color = mix(color, float3(0.12, 0.96, 0.68), centerMark);
        color = mix(color, float3(0.92, 0.30, 0.98), pathMark * 0.8);
        color = mix(color, float3(0.24, 0.64, 1.0), boundsMark * 0.85);
        normalizedAlpha = max(normalizedAlpha, max(centerMark * 0.55, max(pathMark * 0.4, boundsMark * 0.42)));
    }

    return float4(color, normalizedAlpha);
}

float4 resolveAlphaFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    if (uniforms.effectKind < 0.5) {
        return renderWaveFragment(input, uniforms);
    }
    if (uniforms.effectKind < 1.5) {
        return renderScanlineFragment(input, uniforms);
    }
    if (uniforms.effectKind < 3.5) {
        return renderParticlesFragment(input, uniforms);
    }
    return float4(0.0);
}

fragment float4 fragment_alpha(
    FXVertexOut input [[stage_in]],
    constant FXOverlayUniforms &uniforms [[buffer(0)]]
) {
    return resolveAlphaFragment(input, uniforms);
}

fragment float4 fragment_additive(
    FXVertexOut input [[stage_in]],
    constant FXOverlayUniforms &uniforms [[buffer(0)]]
) {
    float4 color = resolveAlphaFragment(input, uniforms);
    return float4(color.rgb * color.a, color.a);
}
"""
}
