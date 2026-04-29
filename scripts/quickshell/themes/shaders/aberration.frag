#version 440

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float aberration;  // chromatic aberration strength in UV space (e.g. 0.010)
    float distortion;  // barrel lens distortion (e.g. 0.04), set 0 to disable
};

layout(binding = 1) uniform sampler2D source;

// Barrel/pincushion distortion — makes the glass feel like a convex lens
vec2 lensDistort(vec2 uv, float k) {
    vec2  d  = uv - 0.5;
    float r2 = dot(d, d);
    return uv + d * r2 * k;
}

void main() {
    // 1. Lens distortion
    vec2 uv = (distortion > 0.0) ? lensDistort(qt_TexCoord0, distortion)
                                  : qt_TexCoord0;

    // 2. Radial direction and quadratic edge falloff
    vec2  fromCenter = uv - vec2(0.5);
    float dist       = length(fromCenter);
    vec2  dir        = fromCenter / (dist + 0.0001);
    float edge       = dist * dist * 4.0;  // zero at centre, ~1 at corners

    // 3. RGB channel separation — R pushed outward, B pulled inward, G stays
    float strength = aberration * edge;
    vec2  uvR = clamp(uv + dir * strength,        vec2(0.0), vec2(1.0));
    vec2  uvG = clamp(uv,                          vec2(0.0), vec2(1.0));
    vec2  uvB = clamp(uv - dir * strength * 0.65, vec2(0.0), vec2(1.0));

    float r = texture(source, uvR).r;
    float g = texture(source, uvG).g;
    float b = texture(source, uvB).b;
    float a = texture(source, uvG).a;

    // 4. Prismatic iridescence at extreme edges — the complementary-colour bleed
    //    that appears when light splits through thick glass at glancing angles
    float prism = smoothstep(0.28, 0.50, dist) * 0.07;
    r += prism * (1.0 - b) * 0.4;
    b += prism * (1.0 - r) * 0.25;

    fragColor = vec4(r, g, b, a) * qt_Opacity;
}
