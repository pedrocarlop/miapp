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
    output.uv = float2((clip.x + 1.0) * 0.5, (clip.y + 1.0) * 0.5);
    return output;
}

float4 renderWaveFragment(FXVertexOut input, constant FXOverlayUniforms &uniforms) {
    float2 pixel = input.uv * uniforms.resolution;

    float dist = distance(pixel, uniforms.center);
    float radius = uniforms.progress * uniforms.maxRadius;
    float ring = smoothstepFx(radius, radius - uniforms.ringWidth, dist);

    float waveFade = 1.0 - smoothstepFx(0.78, 1.0, uniforms.progress);
    float grain = 0.92 + 0.08 * noise(pixel * 0.035 + uniforms.time * 0.1);
    float alpha = ring * waveFade * uniforms.alpha * grain;

    float3 baseColor = mix(float3(0.94, 0.83, 0.52), float3(1.0, 0.92, 0.68), uniforms.intensity);

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
    float axialDistance = fabs(projection - head);
    float bandHalfWidth = max(uniforms.params.x, 0.01);
    float band = 1.0 - smoothstepFx(bandHalfWidth, bandHalfWidth * 1.6, axialDistance);

    float inSegment = step(0.0, projection) * step(projection, axisLength);
    float perpendicularDistance = fabs(rel.x * direction.y - rel.y * direction.x);
    float coreThickness = max(uniforms.params.y, 0.2);
    float core = 1.0 - smoothstepFx(coreThickness, coreThickness + 1.0, perpendicularDistance);
    float glow = 1.0 - smoothstepFx(coreThickness * 4.0, coreThickness * 7.0, perpendicularDistance);

    float pulse = 0.9 + 0.1 * sin(uniforms.time * 22.0 + uniforms.progress * 5.0);
    float alpha = inSegment * band * (core * 0.92 + glow * 0.55) * uniforms.alpha * pulse;

    float3 color = mix(float3(0.98, 0.92, 0.70), float3(1.0, 0.99, 0.86), uniforms.intensity);
    color += glow * 0.08;

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
