
// -----------------------------------------------------------------------------
// Define the constant buffers.
// -----------------------------------------------------------------------------
cbuffer VSBuffer : register(b0)         // Register the constant buffer on slot 0
{
	float4x4 g_ViewProjectionMatrix;
	float3   g_WSBillboardPosition;
	float3   g_WSEyePosition;                   // we only know the billboard’s center position in world space, so we also need the camera’s vectors in world space.
	float3   g_WSLightPosition;                 // Position of the light in world space (no light direction, so it is a point light)
};

cbuffer PSBuffer : register(b0)					// Register the constant buffer in the pixel constant buffer state on slot 0
{
	float4 g_AmbientLightColor;
	float4 g_DiffuseLightColor;
	float4 g_SpecularLightColor;
	float  g_SpecularExponent;
};

// -----------------------------------------------------------------------------
// Texture variables.
// -----------------------------------------------------------------------------
Texture2D g_ColorMap : register(t0);            // Register the color map on texture slot 0
Texture2D g_NormalMap		: register(t1);		// Register the normal map on texture slot 1


// -----------------------------------------------------------------------------
// Sampler variables.
// -----------------------------------------------------------------------------
sampler g_ColorMapSampler : register(s0);       // Register the sampler on sampler slot 0


// -----------------------------------------------------------------------------
// Define input and output data of the vertex shader.
// -----------------------------------------------------------------------------

//  Both the VertexInputType and PixelInputType now have a tangent and binormal vector for bump map calculations. 

struct VSInput
{
	float3 m_OSPosition		: POSITION;			// Object Space Position
	float3 m_OSTangent		: TANGENT;          // Object Space Tangent
	float3 m_OSBinormal		: BINORMAL;         // Object Space Binormal
	float3 m_OSNormal		: NORMAL;           // Object Space Normal
	float2 m_TexCoord       : TEXCOORD;
};

struct PSInput
{
	float4 m_CSPosition		: SV_POSITION;		// Clip Space Position
	float3 m_WSTangent		: TEXCOORD0;	    // World Space Tangent
	float3 m_WSBinormal		: TEXCOORD1;	    // World Space Binormal
	float3 m_WSNormal		: NORMAL;		    // World Space Normal
	float3 m_WSView         : TEXCOORD2;		// World Space View
	float3 m_WSLight        : TEXCOORD3;		// World Space Light
	float2 m_TexCoord		: TEXCOORD4;		// Actual Texture Coordinate
};

// -----------------------------------------------------------------------------
// Vertex Shader
// -----------------------------------------------------------------------------
PSInput VSShader(VSInput _Input)
{

	PSInput Output = (PSInput)0;

	// -------------------------------------------------------------------------------
	// Billboards are 2D elements incrusted in a 3D world
	// What’s different with billboards is that they are positionned at a specific location, but their orientation is automatically computed so that it always faces the camera.
	// -------------------------------------------------------------------------------


	// The y-basis vector corresponds to { 0.0f, 1.0f, 0.0f }, since the billboard rotates only around the y-axis.

	float3  yBasisVector = { 0.0f, 1.0f, 0.0f };
	yBasisVector = normalize(yBasisVector);

	//The z-basis vector is facing the eye (Camera) .

	float3  zBasisVector = g_WSBillboardPosition - g_WSEyePosition;

	zBasisVector.y = 0.0f;
	zBasisVector = normalize(zBasisVector);

	// The x-basis vector ist the cross product of two vectors y-base vector and z-base vector
	float3  xBasisVector = cross(yBasisVector, zBasisVector);
	xBasisVector = normalize(xBasisVector);

	// Create a matrix from the three vectors to multiply them for the camera rotation
	float3x3 rotationMatrix = { xBasisVector, yBasisVector , zBasisVector };

	// -------------------------------------------------------------------------------
	// Get the world space position.
	// -------------------------------------------------------------------------------
	float3 WSPosition = g_WSBillboardPosition + mul(_Input.m_OSPosition, rotationMatrix);



	// -------------------------------------------------------------------------------
	// Get the clip space position.
	// -------------------------------------------------------------------------------
	Output.m_CSPosition = mul(float4(WSPosition, 1.0f), g_ViewProjectionMatrix);

	// -------------------------------------------------------------------------------
	// The normal is still pointing straight out towards the viewer. 
	// the tangent and binormal however run across the surface of the polygon 
	// with the tangent going along the x - axis and the binormal going along the y - axis.
	// -------------------------------------------------------------------------------

	// Calculate the tangent, binormal and normal vector and then normalize the final value.
	Output.m_WSTangent = normalize(mul(_Input.m_OSTangent, rotationMatrix));
	Output.m_WSBinormal = normalize(mul(_Input.m_OSBinormal, rotationMatrix));
	Output.m_WSNormal = normalize(mul(_Input.m_OSNormal, rotationMatrix));

	// -------------------------------------------------------------------------------
	// Get camera and light directions in WS by subtrating their positions by the
	// current point position.
	// -------------------------------------------------------------------------------
	Output.m_WSView = g_WSEyePosition - WSPosition.xyz;
	Output.m_WSLight = g_WSLightPosition - WSPosition.xyz;

	// -------------------------------------------------------------------------------
	// Store the texture coordinates for the pixel shader.
	// -------------------------------------------------------------------------------
	Output.m_TexCoord = _Input.m_TexCoord;

	return Output;
}

// -----------------------------------------------------------------------------
// Pixel Shader
// -----------------------------------------------------------------------------
float4 PSShader(PSInput _Input) : SV_Target
{
	float3   WSTangent;
	float3   WSBinormal;
	float3   WSNormal;
	float3   TSNormal;
	float3x3 TS2WSMatrix;
	float3   WSView;
	float3   WSLight;
	float3   WSHalf;
	float4   Light;
	float4   AmbientLight;
	float4   DiffuseLight;
	float4   SpecularLight;

	// normalize all input values
	WSTangent = normalize(_Input.m_WSTangent);
	WSBinormal = normalize(_Input.m_WSBinormal);
	WSNormal = normalize(_Input.m_WSNormal);
	WSView = normalize(_Input.m_WSView);
	WSLight = normalize(_Input.m_WSLight);
	WSHalf = (WSView + WSLight) * 0.5f;

	TS2WSMatrix = float3x3(WSTangent, WSBinormal, WSNormal);

	// Expand the range of the normal value from (0, +1) to (-1, +1).
	TSNormal = g_NormalMap.Sample(g_ColorMapSampler, _Input.m_TexCoord).rgb * 2.0f - 1.0f;


	WSNormal = mul(TSNormal, TS2WSMatrix);
	WSNormal = normalize(WSNormal);


	// Calculate the amount of light on this pixel based on the bump map normal value.
	AmbientLight = g_AmbientLightColor;
	DiffuseLight = g_DiffuseLightColor * max(dot(WSNormal, WSLight), 0.0f);
	SpecularLight = g_SpecularLightColor * pow(max(dot(WSNormal, WSHalf), 0.0f), g_SpecularExponent);


	Light = AmbientLight + DiffuseLight + SpecularLight;

	// Combine the final bump light color with the texture color.
	return g_ColorMap.Sample(g_ColorMapSampler, _Input.m_TexCoord) * Light;
}


