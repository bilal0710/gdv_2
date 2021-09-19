
// -----------------------------------------------------------------------------
// Define the constant buffers.
// -----------------------------------------------------------------------------
cbuffer VSBuffer : register(b0) // Register the constant buffer on slot 0
{
	float4x4 g_ViewProjectionMatrix;
	float4x4 g_WorldMatrix;
};

cbuffer PSBuffer : register(b0) // Register the constant buffer on slot 0
{
	float4 g_Color;
};

// -----------------------------------------------------------------------------
// Define input and output data of the vertex shader.
// -----------------------------------------------------------------------------
struct VSInput
{
	float3 m_Position : POSITION;
	float4 m_Color : COLOR;
};

struct PSInput
{
	float4 m_Position : SV_POSITION;
	float4 m_Color : TEXCOORD0;
};

// -----------------------------------------------------------------------------
// Vertex Shader
// -----------------------------------------------------------------------------
PSInput VSShader(VSInput _Input)
{
	float4 WSPosition;

	PSInput Output = (PSInput) 0;

	// -------------------------------------------------------------------------------
	// Get the world space position.
	// -------------------------------------------------------------------------------
	WSPosition = mul(float4(_Input.m_Position, 1.0f), g_WorldMatrix);

	// -------------------------------------------------------------------------------
	// Get the clip space position.
	// -------------------------------------------------------------------------------
	Output.m_Position = mul(WSPosition, g_ViewProjectionMatrix);

	return Output;
}

// -----------------------------------------------------------------------------
// Pixel Shader
// -----------------------------------------------------------------------------
float4 PSShader(PSInput _Input) : SV_Target
{
	return g_Color;
}


