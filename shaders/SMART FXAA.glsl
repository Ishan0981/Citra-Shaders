//          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                  Version 2, December 2004

// Copyright (C) 2013 mudlord

// Everyone is permitted to copy and distribute verbatim or modified
// copies of this license document, and changing it is allowed as long
// as the name is changed.

//          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

//! mag_filter = linear
//! min_filter = linear

// 0. You just DO WHAT THE FUCK YOU WANT TO.

#define FXAA_REDUCE_MIN     (1.0/ 128.0)
#define FXAA_REDUCE_MUL     (1.0 / 8.0)
#define FXAA_SPAN_MAX       8.0
#define LUMA_CONSTANT 0.114

float3 applyFXAAHelper(float2 fragCoord, float2 offset, float2 inverseVP)
{
    return SampleLocation((fragCoord + offset) * inverseVP).xyz;
}

float4 applyFXAA(float2 fragCoord)
{
    float4 color;
    float2 inverseVP = GetInvResolution();

    float3 rgbM = applyFXAAHelper(fragCoord, float2(0.0, 0.0), inverseVP);

    float luma = dot(rgbM, float3(0.299, 0.587, LUMA_CONSTANT));

    float lumaNW = dot(applyFXAAHelper(fragCoord, float2(-1.0, -1.0), inverseVP), float3(0.299, 0.587, LUMA_CONSTANT));
    float lumaNE = dot(applyFXAAHelper(fragCoord, float2(1.0, -1.0), inverseVP), float3(0.299, 0.587, LUMA_CONSTANT));
    float lumaSW = dot(applyFXAAHelper(fragCoord, float2(-1.0, 1.0), inverseVP), float3(0.299, 0.587, LUMA_CONSTANT));
    float lumaSE = dot(applyFXAAHelper(fragCoord, float2(1.0, 1.0), inverseVP), float3(0.299, 0.587, LUMA_CONSTANT));

    float lumaMin = min(luma, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(luma, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    float2 dir = float2(-((lumaNW + lumaNE) - (lumaSW + lumaSE)), ((lumaNW + lumaSW) - (lumaNE + lumaSE)));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(float2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(float2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
                  dir * rcpDirMin)) * inverseVP;

    float3 rgbA = 0.5 * (applyFXAAHelper(fragCoord, dir * (1.0 / 3.0 - 0.5), inverseVP) +
                        applyFXAAHelper(fragCoord, dir * (2.0 / 3.0 - 0.5), inverseVP));
    float3 rgbB = rgbA * 0.5 + 0.25 * (applyFXAAHelper(fragCoord, dir * -0.5, inverseVP) +
                                      applyFXAAHelper(fragCoord, dir * 0.5, inverseVP));

    float lumaB = dot(rgbB, float3(0.299, 0.587, LUMA_CONSTANT));
    color = (lumaB < lumaMin || lumaB > lumaMax) ? float4(rgbA, 1.0) : float4(rgbB, 1.0);

    return color;
}




void main()
{
   SetOutput(applyFXAA(GetCoordinates() * GetResolution()));
  }

