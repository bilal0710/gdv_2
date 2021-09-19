
// -----------------------------------------------------------------------------
// Define the constant buffers.
// -----------------------------------------------------------------------------
cbuffer VSBuffer : register(b0)         // Register the constant buffer on slot 0
{
	float4x4 g_ViewProjectionMatrix;
	float4x4 g_WorldMatrix;
	float3   g_WSEyePosition;                   // we only know the billboard’s center position in world space, so we also need the camera’s vectors in world space.

};


// -----------------------------------------------------------------------------
// Texture variables.
// -----------------------------------------------------------------------------
Texture2D g_ColorMap : register(t0);            // Register the color map on texture slot 0

// -----------------------------------------------------------------------------
// Sampler variables.
// -----------------------------------------------------------------------------
sampler g_ColorMapSampler : register(s0);       // Register the sampler on sampler slot 0


// -----------------------------------------------------------------------------
// Define input and output data of the vertex shader.
// -----------------------------------------------------------------------------
struct VSInput
{
	float3 m_Position : POSITION;
	float2 m_TexCoord : TEXCOORD;
};

struct PSInput
{
	float4 m_Position : SV_POSITION;
	float2 m_TexCoord : TEXCOORD0;
};

// -----------------------------------------------------------------------------
// Vertex Shader
// -----------------------------------------------------------------------------
PSInput VSShader(VSInput _Input)
{
	float4 WSPosition;

	PSInput Output = (PSInput)0;

	// -------------------------------------------------------------------------------
	// Billboards are 2D elements incrusted in a 3D world
	// What’s different with billboards is that they are positionned at a specific location, but their orientation is automatically computed so that it always faces the camera.
	// -------------------------------------------------------------------------------


	// The y-base vector corresponds to { 0.0f, 1.0f, 0.0f }, since the billboard rotates only around the y-axis.

	float3  yBasisvektor = { 0.0f, 1.0f, 0.0f };
	yBasisvektor = normalize(yBasisvektor);

	// The z-base vector is aligned with the y-axis and facing the eye.

	float3  zBasisvektor = -g_WSEyePosition;
	zBasisvektor.y = 0.0f;
	zBasisvektor = normalize(zBasisvektor);

	// The x-base vector ist the cross product of two vectors y-base vector and z-base vector
	float3  xBasisvektor = cross(yBasisvektor, zBasisvektor);
	xBasisvektor = normalize(xBasisvektor);

	// Create a matrix from the three vectors to multiply by the specified point 
	float3x3 rotation = { xBasisvektor, yBasisvektor , zBasisvektor };

	// -------------------------------------------------------------------------------
	// Get the world space position.
	// -------------------------------------------------------------------------------
	float3 transform = mul(_Input.m_Position, rotation);
	WSPosition = mul(float4(transform, 1.0f), g_WorldMatrix);


	// -------------------------------------------------------------------------------
	// Get the clip space position.
	// -------------------------------------------------------------------------------


	Output.m_Position = mul(WSPosition, g_ViewProjectionMatrix);
	Output.m_TexCoord = _Input.m_TexCoord;

	return Output;
}

// -----------------------------------------------------------------------------
// Pixel Shader
// -----------------------------------------------------------------------------
float4 PSShader(PSInput _Input) : SV_Target
{
	return g_ColorMap.Sample(g_ColorMapSampler, _Input.m_TexCoord);
}


