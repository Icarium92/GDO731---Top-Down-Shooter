// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Distant Lands/Cozy/URP/Stylized Clouds (COZY Desktop)"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

		Cull Front
		AlphaToMask Off

		Stencil
		{
			Ref 221
			Comp Always
			Pass Zero
			Fail Keep
			ZFail Keep
		}

		HLSLINCLUDE
		#pragma target 3.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 120108


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 normalizeResult40_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord3.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord4;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = FinalCloudColor325_g348.xyz;
				float Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				float AlphaClipThreshold = Clipping208_g348;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.positionCS.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 120108


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile _ DOTS_INSTANCING_ON

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.normalOS );

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 normalizeResult40_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord2.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				

				float Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				float AlphaClipThreshold = Clipping208_g348;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.positionCS.xyz, unity_LODFade.x );
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

            #pragma multi_compile_instancing
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _ALPHATEST_ON 1
            #define ASE_SRP_VERSION 120108


            #pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 normalizeResult40_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord2.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				

				float Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				float AlphaClipThreshold = Clipping208_g348;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.positionCS.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _ALPHATEST_ON 1
            #define ASE_SRP_VERSION 120108


            #pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord1.xyz = ase_worldPos;
				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 normalizeResult40_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				

				surfaceDescription.Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				surfaceDescription.AlphaClipThreshold = Clipping208_g348;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _ALPHATEST_ON 1
            #define ASE_SRP_VERSION 120108


            #pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord1.xyz = ase_worldPos;
				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 normalizeResult40_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				

				surfaceDescription.Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				surfaceDescription.AlphaClipThreshold = Clipping208_g348;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

            #pragma multi_compile_instancing
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _ALPHATEST_ON 1
            #define ASE_SRP_VERSION 120108


            #pragma multi_compile _ DOTS_INSTANCING_ON

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 CZY_CloudColor;
			float CZY_FilterSaturation;
			float CZY_FilterValue;
			float4 CZY_FilterColor;
			float4 CZY_CloudFilterColor;
			float4 CZY_CloudHighlightColor;
			float4 CZY_SunFilterColor;
			float CZY_WindSpeed;
			float CZY_MainCloudScale;
			float CZY_CumulusCoverageMultiplier;
			float3 CZY_SunDirection;
			half CZY_SunFlareFalloff;
			float3 CZY_MoonDirection;
			half CZY_CloudMoonFalloff;
			float4 CZY_CloudMoonColor;
			float CZY_DetailScale;
			float CZY_DetailAmount;
			float CZY_BorderHeight;
			float CZY_BorderVariation;
			float CZY_BorderEffect;
			float3 CZY_StormDirection;
			float CZY_NimbusHeight;
			float CZY_NimbusMultiplier;
			float CZY_NimbusVariation;
			sampler2D CZY_ChemtrailsTexture;
			float CZY_ChemtrailsMoveSpeed;
			float CZY_ChemtrailsMultiplier;
			sampler2D CZY_CirrusTexture;
			float CZY_CirrusMoveSpeed;
			float CZY_CirrusMultiplier;
			float CZY_ClippingThreshold;
			float4 CZY_AltoCloudColor;
			sampler2D CZY_AltocumulusTexture;
			float2 CZY_AltocumulusWindSpeed;
			float CZY_AltocumulusScale;
			float CZY_AltocumulusMultiplier;
			sampler2D CZY_CirrostratusTexture;
			float CZY_CirrostratusMoveSpeed;
			float CZY_CirrostratusMultiplier;
			float _UnderwaterRenderingEnabled;
			float _FullySubmerged;
			sampler2D _UnderwaterMask;


			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
					float2 voronoihash81_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi81_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash81_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash88_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi88_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash88_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash200_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi200_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash200_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return (F2 + F1) * 0.5;
					}
			
					float2 voronoihash232_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi232_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash232_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash84_g348( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi84_g348( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash84_g348( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float HLSL20_g352( bool enabled, bool submerged, float textureSample )
			{
				if(enabled)
				{
					if(submerged) return 1.0;
					else return textureSample;
				}
				else
				{
					return 0.0;
				}
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord2.xyz = ase_worldPos;
				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

				o.positionCS = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 hsvTorgb2_g349 = RGBToHSV( CZY_CloudColor.rgb );
				float3 hsvTorgb3_g349 = HSVToRGB( float3(hsvTorgb2_g349.x,saturate( ( hsvTorgb2_g349.y + CZY_FilterSaturation ) ),( hsvTorgb2_g349.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g349 = ( float4( hsvTorgb3_g349 , 0.0 ) * CZY_FilterColor );
				float4 CloudColor41_g348 = ( temp_output_10_0_g349 * CZY_CloudFilterColor );
				float3 hsvTorgb2_g353 = RGBToHSV( CZY_CloudHighlightColor.rgb );
				float3 hsvTorgb3_g353 = HSVToRGB( float3(hsvTorgb2_g353.x,saturate( ( hsvTorgb2_g353.y + CZY_FilterSaturation ) ),( hsvTorgb2_g353.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g353 = ( float4( hsvTorgb3_g353 , 0.0 ) * CZY_FilterColor );
				float4 CloudHighlightColor55_g348 = ( temp_output_10_0_g353 * CZY_SunFilterColor );
				float2 texCoord31_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 Pos33_g348 = texCoord31_g348;
				float mulTime29_g348 = _TimeParameters.x * ( 0.001 * CZY_WindSpeed );
				float TIme30_g348 = mulTime29_g348;
				float simplePerlin2D409_g348 = snoise( ( Pos33_g348 + ( TIme30_g348 * float2( 0.2,-0.4 ) ) )*( 100.0 / CZY_MainCloudScale ) );
				simplePerlin2D409_g348 = simplePerlin2D409_g348*0.5 + 0.5;
				float SimpleCloudDensity153_g348 = simplePerlin2D409_g348;
				float time81_g348 = 0.0;
				float2 voronoiSmoothId81_g348 = 0;
				float2 temp_output_94_0_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) );
				float2 coords81_g348 = temp_output_94_0_g348 * ( 140.0 / CZY_MainCloudScale );
				float2 id81_g348 = 0;
				float2 uv81_g348 = 0;
				float voroi81_g348 = voronoi81_g348( coords81_g348, time81_g348, id81_g348, uv81_g348, 0, voronoiSmoothId81_g348 );
				float time88_g348 = 0.0;
				float2 voronoiSmoothId88_g348 = 0;
				float2 coords88_g348 = temp_output_94_0_g348 * ( 500.0 / CZY_MainCloudScale );
				float2 id88_g348 = 0;
				float2 uv88_g348 = 0;
				float voroi88_g348 = voronoi88_g348( coords88_g348, time88_g348, id88_g348, uv88_g348, 0, voronoiSmoothId88_g348 );
				float2 appendResult95_g348 = (float2(voroi81_g348 , voroi88_g348));
				float2 VoroDetails109_g348 = appendResult95_g348;
				float CumulusCoverage34_g348 = CZY_CumulusCoverageMultiplier;
				float ComplexCloudDensity141_g348 = (0.0 + (min( SimpleCloudDensity153_g348 , ( 1.0 - VoroDetails109_g348.x ) ) - ( 1.0 - CumulusCoverage34_g348 )) * (1.0 - 0.0) / (1.0 - ( 1.0 - CumulusCoverage34_g348 )));
				float4 lerpResult315_g348 = lerp( CloudHighlightColor55_g348 , CloudColor41_g348 , saturate( (2.0 + (ComplexCloudDensity141_g348 - 0.0) * (0.7 - 2.0) / (1.0 - 0.0)) ));
				float3 ase_worldPos = IN.ase_texcoord2.xyz;
				float3 normalizeResult40_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult42_g348 = dot( normalizeResult40_g348 , CZY_SunDirection );
				float temp_output_49_0_g348 = abs( (dotResult42_g348*0.5 + 0.5) );
				half LightMask56_g348 = saturate( pow( temp_output_49_0_g348 , CZY_SunFlareFalloff ) );
				float time200_g348 = 0.0;
				float2 voronoiSmoothId200_g348 = 0;
				float mulTime163_g348 = _TimeParameters.x * 0.003;
				float2 coords200_g348 = (Pos33_g348*1.0 + ( float2( 1,-2 ) * mulTime163_g348 )) * 10.0;
				float2 id200_g348 = 0;
				float2 uv200_g348 = 0;
				float voroi200_g348 = voronoi200_g348( coords200_g348, time200_g348, id200_g348, uv200_g348, 0, voronoiSmoothId200_g348 );
				float time232_g348 = ( 10.0 * mulTime163_g348 );
				float2 voronoiSmoothId232_g348 = 0;
				float2 coords232_g348 = IN.ase_texcoord1.xy * 10.0;
				float2 id232_g348 = 0;
				float2 uv232_g348 = 0;
				float voroi232_g348 = voronoi232_g348( coords232_g348, time232_g348, id232_g348, uv232_g348, 0, voronoiSmoothId232_g348 );
				float temp_output_242_0_g348 = ( ( ( 1.0 - 0.0 ) - (1.0 + (voroi200_g348 - 0.0) * (-0.5 - 1.0) / (1.0 - 0.0)) ) - voroi232_g348 );
				float AltoCumulusPlacement376_g348 = temp_output_242_0_g348;
				float CloudThicknessDetails286_g348 = ( VoroDetails109_g348.y * saturate( ( AltoCumulusPlacement376_g348 - 0.26 ) ) );
				float3 normalizeResult43_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float dotResult46_g348 = dot( normalizeResult43_g348 , CZY_MoonDirection );
				half MoonlightMask57_g348 = saturate( pow( abs( (dotResult46_g348*0.5 + 0.5) ) , CZY_CloudMoonFalloff ) );
				float3 hsvTorgb2_g350 = RGBToHSV( CZY_CloudMoonColor.rgb );
				float3 hsvTorgb3_g350 = HSVToRGB( float3(hsvTorgb2_g350.x,saturate( ( hsvTorgb2_g350.y + CZY_FilterSaturation ) ),( hsvTorgb2_g350.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g350 = ( float4( hsvTorgb3_g350 , 0.0 ) * CZY_FilterColor );
				float4 MoonlightColor60_g348 = ( temp_output_10_0_g350 * CZY_CloudFilterColor );
				float4 lerpResult338_g348 = lerp( ( lerpResult315_g348 + ( LightMask56_g348 * CloudHighlightColor55_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) + ( MoonlightMask57_g348 * MoonlightColor60_g348 * ( 1.0 - CloudThicknessDetails286_g348 ) ) ) , ( CloudColor41_g348 * float4( 0.5660378,0.5660378,0.5660378,0 ) ) , CloudThicknessDetails286_g348);
				float time84_g348 = 0.0;
				float2 voronoiSmoothId84_g348 = 0;
				float2 coords84_g348 = ( Pos33_g348 + ( TIme30_g348 * float2( 0.3,0.2 ) ) ) * ( 100.0 / CZY_DetailScale );
				float2 id84_g348 = 0;
				float2 uv84_g348 = 0;
				float fade84_g348 = 0.5;
				float voroi84_g348 = 0;
				float rest84_g348 = 0;
				for( int it84_g348 = 0; it84_g348 <3; it84_g348++ ){
				voroi84_g348 += fade84_g348 * voronoi84_g348( coords84_g348, time84_g348, id84_g348, uv84_g348, 0,voronoiSmoothId84_g348 );
				rest84_g348 += fade84_g348;
				coords84_g348 *= 2;
				fade84_g348 *= 0.5;
				}//Voronoi84_g348
				voroi84_g348 /= rest84_g348;
				float temp_output_173_0_g348 = ( (0.0 + (( 1.0 - voroi84_g348 ) - 0.3) * (0.5 - 0.0) / (1.0 - 0.3)) * 0.1 * CZY_DetailAmount );
				float DetailedClouds252_g348 = saturate( ( ComplexCloudDensity141_g348 + temp_output_173_0_g348 ) );
				float CloudDetail179_g348 = temp_output_173_0_g348;
				float2 texCoord79_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_161_0_g348 = ( texCoord79_g348 - float2( 0.5,0.5 ) );
				float dotResult212_g348 = dot( temp_output_161_0_g348 , temp_output_161_0_g348 );
				float BorderHeight154_g348 = ( 1.0 - CZY_BorderHeight );
				float temp_output_151_0_g348 = ( -2.0 * ( 1.0 - CZY_BorderVariation ) );
				float clampResult247_g348 = clamp( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( BorderHeight154_g348 * temp_output_151_0_g348 ) + (dotResult212_g348 - 0.0) * (( temp_output_151_0_g348 * -4.0 ) - ( BorderHeight154_g348 * temp_output_151_0_g348 )) / (0.5 - 0.0)) ) ) * 10.0 * CZY_BorderEffect ) , -1.0 , 1.0 );
				float BorderLightTransport278_g348 = clampResult247_g348;
				float3 normalizeResult116_g348 = normalize( ( ase_worldPos - _WorldSpaceCameraPos ) );
				float3 normalizeResult146_g348 = normalize( CZY_StormDirection );
				float dotResult150_g348 = dot( normalizeResult116_g348 , normalizeResult146_g348 );
				float2 texCoord98_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_124_0_g348 = ( texCoord98_g348 - float2( 0.5,0.5 ) );
				float dotResult125_g348 = dot( temp_output_124_0_g348 , temp_output_124_0_g348 );
				float temp_output_140_0_g348 = ( -2.0 * ( 1.0 - ( CZY_NimbusVariation * 0.9 ) ) );
				float NimbusLightTransport269_g348 = saturate( ( ( ( CloudDetail179_g348 + SimpleCloudDensity153_g348 ) * saturate( (( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 ) + (( dotResult150_g348 + ( CZY_NimbusHeight * 4.0 * dotResult125_g348 ) ) - 0.5) * (( temp_output_140_0_g348 * -4.0 ) - ( ( 1.0 - CZY_NimbusMultiplier ) * temp_output_140_0_g348 )) / (7.0 - 0.5)) ) ) * 10.0 ) );
				float mulTime104_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D143_g348 = snoise( (Pos33_g348*1.0 + mulTime104_g348)*2.0 );
				float mulTime93_g348 = _TimeParameters.x * CZY_ChemtrailsMoveSpeed;
				float cos97_g348 = cos( ( mulTime93_g348 * 0.01 ) );
				float sin97_g348 = sin( ( mulTime93_g348 * 0.01 ) );
				float2 rotator97_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos97_g348 , -sin97_g348 , sin97_g348 , cos97_g348 )) + float2( 0.5,0.5 );
				float cos131_g348 = cos( ( mulTime93_g348 * -0.02 ) );
				float sin131_g348 = sin( ( mulTime93_g348 * -0.02 ) );
				float2 rotator131_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos131_g348 , -sin131_g348 , sin131_g348 , cos131_g348 )) + float2( 0.5,0.5 );
				float mulTime107_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D147_g348 = snoise( (Pos33_g348*1.0 + mulTime107_g348)*4.0 );
				float4 ChemtrailsPattern210_g348 = ( ( saturate( simplePerlin2D143_g348 ) * tex2D( CZY_ChemtrailsTexture, (rotator97_g348*0.5 + 0.0) ) ) + ( tex2D( CZY_ChemtrailsTexture, rotator131_g348 ) * saturate( simplePerlin2D147_g348 ) ) );
				float2 texCoord139_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_162_0_g348 = ( texCoord139_g348 - float2( 0.5,0.5 ) );
				float dotResult207_g348 = dot( temp_output_162_0_g348 , temp_output_162_0_g348 );
				float ChemtrailsFinal248_g348 = ( ( ChemtrailsPattern210_g348 * saturate( (0.4 + (dotResult207_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - ( CZY_ChemtrailsMultiplier * 0.5 ) ) ? 1.0 : 0.0 );
				float mulTime80_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D126_g348 = snoise( (Pos33_g348*1.0 + mulTime80_g348)*2.0 );
				float mulTime75_g348 = _TimeParameters.x * CZY_CirrusMoveSpeed;
				float cos101_g348 = cos( ( mulTime75_g348 * 0.01 ) );
				float sin101_g348 = sin( ( mulTime75_g348 * 0.01 ) );
				float2 rotator101_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos101_g348 , -sin101_g348 , sin101_g348 , cos101_g348 )) + float2( 0.5,0.5 );
				float cos112_g348 = cos( ( mulTime75_g348 * -0.02 ) );
				float sin112_g348 = sin( ( mulTime75_g348 * -0.02 ) );
				float2 rotator112_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos112_g348 , -sin112_g348 , sin112_g348 , cos112_g348 )) + float2( 0.5,0.5 );
				float mulTime135_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D122_g348 = snoise( (Pos33_g348*1.0 + mulTime135_g348) );
				simplePerlin2D122_g348 = simplePerlin2D122_g348*0.5 + 0.5;
				float4 CirrusPattern137_g348 = ( ( saturate( simplePerlin2D126_g348 ) * tex2D( CZY_CirrusTexture, (rotator101_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrusTexture, (rotator112_g348*1.0 + 0.0) ) * saturate( simplePerlin2D122_g348 ) ) );
				float2 texCoord134_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_164_0_g348 = ( texCoord134_g348 - float2( 0.5,0.5 ) );
				float dotResult157_g348 = dot( temp_output_164_0_g348 , temp_output_164_0_g348 );
				float4 temp_output_217_0_g348 = ( CirrusPattern137_g348 * saturate( (0.0 + (dotResult157_g348 - 0.0) * (2.0 - 0.0) / (0.2 - 0.0)) ) );
				float Clipping208_g348 = CZY_ClippingThreshold;
				float CirrusAlpha250_g348 = ( ( temp_output_217_0_g348 * ( CZY_CirrusMultiplier * 10.0 ) ).r > Clipping208_g348 ? 1.0 : 0.0 );
				float SimpleRadiance268_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + NimbusLightTransport269_g348 + ChemtrailsFinal248_g348 + CirrusAlpha250_g348 ) );
				float4 lerpResult342_g348 = lerp( CloudColor41_g348 , lerpResult338_g348 , ( 1.0 - SimpleRadiance268_g348 ));
				float CloudbreakLightDir426_g348 = saturate( pow( temp_output_49_0_g348 , ( CZY_SunFlareFalloff * 0.5 ) ) );
				float lerpResult316_g348 = lerp( -0.4 , 1.0 , ( saturate( ( ComplexCloudDensity141_g348 - 0.0 ) ) * CloudDetail179_g348 * CloudbreakLightDir426_g348 ));
				float SunThroughClouds399_g348 = saturate( lerpResult316_g348 );
				float3 hsvTorgb2_g351 = RGBToHSV( CZY_AltoCloudColor.rgb );
				float3 hsvTorgb3_g351 = HSVToRGB( float3(hsvTorgb2_g351.x,saturate( ( hsvTorgb2_g351.y + CZY_FilterSaturation ) ),( hsvTorgb2_g351.z + CZY_FilterValue )) );
				float4 temp_output_10_0_g351 = ( float4( hsvTorgb3_g351 , 0.0 ) * CZY_FilterColor );
				float4 CirrusCustomLightColor350_g348 = ( CloudColor41_g348 * ( temp_output_10_0_g351 * CZY_CloudFilterColor ) );
				float temp_output_391_0_g348 = ( AltoCumulusPlacement376_g348 * (0.0 + (tex2D( CZY_AltocumulusTexture, ((Pos33_g348*1.0 + ( CZY_AltocumulusWindSpeed * TIme30_g348 ))*( 1.0 / CZY_AltocumulusScale ) + 0.0) ).r - 0.0) * (1.0 - 0.0) / (0.2 - 0.0)) * CZY_AltocumulusMultiplier );
				float AltoCumulusLightTransport393_g348 = temp_output_391_0_g348;
				float ACCustomLightsClipping387_g348 = ( AltoCumulusLightTransport393_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float mulTime193_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D224_g348 = snoise( (Pos33_g348*1.0 + mulTime193_g348)*2.0 );
				float mulTime178_g348 = _TimeParameters.x * CZY_CirrostratusMoveSpeed;
				float cos138_g348 = cos( ( mulTime178_g348 * 0.01 ) );
				float sin138_g348 = sin( ( mulTime178_g348 * 0.01 ) );
				float2 rotator138_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos138_g348 , -sin138_g348 , sin138_g348 , cos138_g348 )) + float2( 0.5,0.5 );
				float cos198_g348 = cos( ( mulTime178_g348 * -0.02 ) );
				float sin198_g348 = sin( ( mulTime178_g348 * -0.02 ) );
				float2 rotator198_g348 = mul( Pos33_g348 - float2( 0.5,0.5 ) , float2x2( cos198_g348 , -sin198_g348 , sin198_g348 , cos198_g348 )) + float2( 0.5,0.5 );
				float mulTime184_g348 = _TimeParameters.x * 0.01;
				float simplePerlin2D216_g348 = snoise( (Pos33_g348*10.0 + mulTime184_g348)*4.0 );
				float4 CirrostratPattern261_g348 = ( ( saturate( simplePerlin2D224_g348 ) * tex2D( CZY_CirrostratusTexture, (rotator138_g348*1.5 + 0.75) ) ) + ( tex2D( CZY_CirrostratusTexture, (rotator198_g348*1.5 + 0.75) ) * saturate( simplePerlin2D216_g348 ) ) );
				float2 texCoord234_g348 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_243_0_g348 = ( texCoord234_g348 - float2( 0.5,0.5 ) );
				float dotResult238_g348 = dot( temp_output_243_0_g348 , temp_output_243_0_g348 );
				float clampResult264_g348 = clamp( ( CZY_CirrostratusMultiplier * 0.5 ) , 0.0 , 0.98 );
				float CirrostratLightTransport281_g348 = ( ( CirrostratPattern261_g348 * saturate( (0.4 + (dotResult238_g348 - 0.0) * (2.0 - 0.4) / (0.1 - 0.0)) ) ).r > ( 1.0 - clampResult264_g348 ) ? 1.0 : 0.0 );
				float CSCustomLightsClipping309_g348 = ( CirrostratLightTransport281_g348 * ( SimpleRadiance268_g348 > Clipping208_g348 ? 0.0 : 1.0 ) );
				float CustomRadiance340_g348 = saturate( ( ACCustomLightsClipping387_g348 + CSCustomLightsClipping309_g348 ) );
				float4 lerpResult331_g348 = lerp( ( lerpResult342_g348 + SunThroughClouds399_g348 ) , CirrusCustomLightColor350_g348 , CustomRadiance340_g348);
				float FinalAlpha375_g348 = saturate( ( DetailedClouds252_g348 + BorderLightTransport278_g348 + AltoCumulusLightTransport393_g348 + ChemtrailsFinal248_g348 + CirrostratLightTransport281_g348 + CirrusAlpha250_g348 + NimbusLightTransport269_g348 ) );
				float4 appendResult420_g348 = (float4((lerpResult331_g348).rgb , FinalAlpha375_g348));
				float4 FinalCloudColor325_g348 = appendResult420_g348;
				bool enabled20_g352 =(bool)_UnderwaterRenderingEnabled;
				bool submerged20_g352 =(bool)_FullySubmerged;
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float textureSample20_g352 = tex2Dlod( _UnderwaterMask, float4( ase_screenPosNorm.xy, 0, 0.0) ).r;
				float localHLSL20_g352 = HLSL20_g352( enabled20_g352 , submerged20_g352 , textureSample20_g352 );
				

				surfaceDescription.Alpha = ( ( (FinalCloudColor325_g348).w * ( 1.0 - localHLSL20_g352 ) ) > Clipping208_g348 ? 1.0 : 0.0 );
				surfaceDescription.AlphaClipThreshold = Clipping208_g348;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.positionCS.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "EmptyShaderGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19303
Node;AmplifyShaderEditor.FunctionNode;871;-3776,-688;Inherit;False;Stylized Clouds (Desktop);0;;348;b8040dba3255391449edffa0921d9c37;0;0;3;FLOAT4;0;FLOAT;414;FLOAT;415
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;803;-678.2959,-671.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;802;-678.2959,-671.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;801;-678.2959,-671.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;804;-677.2959,-599.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;805;-677.2959,-599.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;806;-677.2959,-599.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;807;-677.2959,-599.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;808;-677.2959,-599.1561;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;799;-3024,-880;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;800;-3424,-688;Float;False;True;-1;2;EmptyShaderGUI;0;13;Distant Lands/Cozy/URP/Stylized Clouds (COZY Desktop);2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;1;False;;False;False;False;False;False;False;False;False;True;True;True;221;False;;255;False;;255;False;;7;False;;2;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;21;Surface;1;638295390293297003;  Blend;0;0;Two Sided;2;638295390676621873;Forward Only;1;638295390392913430;Cast Shadows;1;0;  Use Shadow Threshold;0;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;True;True;False;False;True;True;True;False;False;;False;0
WireConnection;800;2;871;0
WireConnection;800;3;871;414
WireConnection;800;4;871;415
ASEEND*/
//CHKSM=DACFD86A3EC4702D10CDD14D58B12D57863B9FB0