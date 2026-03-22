#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float Temperature = 2600.0;
const float Strength = 1.0;
const float LuminancePreservationFactor = 1.0;

// Compensation factor to counteract dimming (1.0 = no change, 1.05 = 5% boost)
const float BrightnessBoost = 1.05; 

vec3 colorTemperatureToRGB(const in float temperature) {
    mat3 m = (temperature <= 6500.0)
        ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
               vec3(0.0, 1669.5803561666639, 2575.2827530017594),
               vec3(1.0, 1.3302673723350029, 1.8993753891711275))
        : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
               vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
               vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));

    return mix(
        clamp(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2], 0.0, 1.0),
        vec3(1.0),
        smoothstep(1000.0, 0.0, temperature)
    );
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;

    // 1. Apply Blue Light Filter
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color *= mix(1.0, lum / max(lum, 1e-5), LuminancePreservationFactor);
    color = mix(color, color * colorTemperatureToRGB(Temperature), Strength);

    // 2. Optimized Grain (Centered Noise)
    // By subtracting 0.5, the noise ranges from -0.5 to 0.5. 
    // This makes some pixels darker and some brighter, maintaining average brightness.
    float grainStrength = 0.05; 
    float noise = (fract(sin(dot(v_texcoord, vec2(12.9898, 78.233))) * 43758.5453)) - 0.5;
    color += (noise * grainStrength);

    // 3. Brightness Compensation
    color *= BrightnessBoost;

    fragColor = vec4(color, pixColor.a);
}
