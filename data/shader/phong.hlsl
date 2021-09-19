
cbuffer VSConstants : register(b0)
{
    float4x4 g_WorldMatrix;
    float4x4 g_ViewProjectionMatrix;
    float3 g_WSLightPosition; // => float4
    float3 g_WSViewPosition; // => float4
};
cbuffer PSConstants : register(b0)
{
    float3 g_AmbientIntensity; // Light Properties      => float4   
    float3 g_DiffuseIntensity; // Light Properties      => float4
    float3 g_SpecularIntensity; // Light Properties      => float4
    float3 g_AmbientReflection; // Material Properties   => float4
    float3 g_DiffuseReflection; // Material Properties   => float4
    float3 g_SpecularReflection; // Material Properties   => float4
    float g_SpecularExponent; // Material Properties   => float4
};

struct VSInput
{
    float3 m_OSPosition : OSPOSITION;
    float3 m_OSNormal : OSNORMAL;
};

struct PSInput
{
    float2 m_CSPosition : SV_POSITION;
    float3 m_WSNormal : TEXCOORD0;
    float3 m_WSLightDir : TEXCOORD1;
    float3 m_WSViewDir : TEXCOORD2;
};

PSInput VSPhongMain(VSInput _Input)
{
    float4 WSPosition = mul(float4(_Input.m_OSPosition, 1.0f), g_WorldMatrix);
    float4 CSPosition = mul(WSPosition, g_ViewProjectionMatrix);

    float3 WSNormal = mul(_Input.m_OSNormal, (float3x3) g_WorldMatrix);

    float3 WSLightDir = g_WSLightPosition - WSPosition;
    float3 WSViewDir = g_WSViewPosition - WSPosition;

    PSInput Result;

    Result.m_CSPosition = CSPosition;
    Result.m_WSNormal = WSNormal;
    Result.m_WSLightDir = WSLightDir;
    Result.m_WSViewDir = WSViewDir;

    return Result;
}

float4 PSPhongMain(PSInput _Input) : SV_TARGET
{
    float3 WSNormal = normalize(_Input.m_WSNormal);
    float3 WSLightDir = normalize(_Input.m_WSLightDir);
    float3 WSViewDir = normalize(_Input.m_WSViewDir);
    float3 WSHalfDir = normalize(WSLightDir + WSViewDir);

    float3 Ambient = g_AmbientIntensity * g_AmbientReflection;
    float3 Diffuse = g_DiffuseIntensity * g_DiffuseReflection * max(dot(m_WSNormal, WSLightDir), 0.0f);
    float3 Specular = g_SpecularIntensity * g_SpecularReflection * pow(max(dot(m_WSNormal, WSHalfDir), 0.0f), g_SpecularExponent);

    float3 Light = Ambient + Diffuse + Specular;

    return float4(Light, 1.0f);
}