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
    float ringOuter = smoothstepFx(radius + ringWidth * 0.45, radius - ringWidth, dist);
    float ringInner = smoothstepFx(radius - ringWidth * 0.22, radius - ringWidth * 1.32, dist);
    float ringTail = smoothstepFx(radius + ringWidth * 1.24, radius + ringWidth * 0.16, dist);
    float ring = ringOuter * 0.72 + ringInner * 0.33 + ringTail * 0.2;

    float waveFade = (1.0 - smoothstepFx(0.72, 1.0, uniforms.progress));
    float radialPhase = dist * 0.085 - uniforms.time * 8.6;
    float shimmer = 0.86 + 0.14 * sin(radialPhase + uniforms.progress * 5.2);
    float grain = 0.88 + 0.12 * noise((pixel - uniforms.center) * 0.045 + uniforms.time * 0.22);
    float alpha = ring * waveFade * uniforms.alpha * shimmer * grain;

    float chroma = 0.5 + 0.5 * sin(radialPhase * 0.76 + uniforms.intensity * 2.4);
    float3 warm = mix(float3(0.94, 0.83, 0.52), float3(1.0, 0.92, 0.68), uniforms.intensity);
    float3 cool = mix(float3(0.62, 0.90, 1.0), float3(0.72, 0.96, 1.0), uniforms.intensity);
    float3 baseColor = mix(warm, cool, chroma * 0.11);

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

float4 resolveAlphaFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    if (uniforms.effectKind < 0.5) {
        return renderWaveFragment(input, uniforms);
    }
    if (uniforms.effectKind < 1.5) {
        return renderScanlineFragment(input, uniforms);
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
