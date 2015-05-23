
module.exports = class APhysicalShader extends THREE.ShaderMaterial
  @LIGHT_POSITION_VECTOR: new THREE.Vector3(0.6774711192265457, 0.6981397469246446, -0.2315896724336482)
  @LIGHT_POSITION: "(vec3(#{APhysicalShader.LIGHT_POSITION_VECTOR.x},#{APhysicalShader.LIGHT_POSITION_VECTOR.y},#{APhysicalShader.LIGHT_POSITION_VECTOR.z}))"
  @LIGHT_COLOR: "1.0 * vec3(1.0, 0.95, 0.84)"
  @shadowMapHeaderFragment: """
    #ifdef SHADOWMAPS
    uniform mat4 shadowMatrices[SHADOWMAPS];
    uniform sampler2D shadowTextures[SHADOWMAPS];
    uniform mat3 shadowSizes[SHADOWMAPS];

    // Maps a between from min and max to 0 and 1
    #{require("shader/DepthShader").mapChunk}
    #{require("shader/DepthShader").unpackDepth}

    #endif
  """
  @shadowMapBodyFragment: """
    float directFactor = 1.0;
    #ifdef SHADOWMAPS
    for(int i = 0; i < SHADOWMAPS; i++){
      vec4 shadowPos = shadowMatrices[i] * vec4(vWorldPosition, 1.0);
      mat3 shadowSize = shadowSizes[i];
      if(shadowPos.x >= shadowSize[0][0] && shadowPos.x <= shadowSize[0][1] &&
         shadowPos.y >= shadowSize[1][0] && shadowPos.y <= shadowSize[1][1]){
        //gl_FragColor = vec4(shadowSize[0][2]/100.0);
        vec2 shadowTexturePosition = vec2(
          map(shadowPos.x, shadowSize[0][0], shadowSize[0][1]),
          map(shadowPos.y, shadowSize[1][0], shadowSize[1][1])
        );
        float depth = unpackDepth(texture2D(shadowTextures[i], shadowTexturePosition));
        if (depth < 1.0){
          depth = depth * (shadowSize[2][1] - shadowSize[2][0]) + shadowSize[2][0];
          if (depth <= -shadowPos.z - shadowSize[0][2]){
            //gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
            directFactor = 0.0;
          }
          else {
            //gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
          }
        }
        break;
      }
    }
    #endif
  """
  @vertexShader: """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambertTopFactor;
    varying float lambertBottomFactor;
    void main() {
      vNormal = (modelMatrix * vec4(normal, 0.0)).xyz;
      vWorldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
      vec3 lightVector = #{APhysicalShader.LIGHT_POSITION};
      lambertTopFactor = max(0.0, dot(lightVector, vNormal));
      lambertBottomFactor = max(0.0, dot(lightVector * vec3(1.0, -1.0, 1.0), vNormal));
    }
    """
  @fragmentShaderHeader: """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambertTopFactor;
    varying float lambertBottomFactor;
    uniform vec3 color;
    #{APhysicalShader.shadowMapHeaderFragment}
    
    #{require("shader/SkyShaderChunk")}
  """
  @fragmentShaderPre: """
      vec3 lightVector = #{APhysicalShader.LIGHT_POSITION};
      vec3 lightColor = #{APhysicalShader.LIGHT_COLOR};
      vec3 cameraViewVector = normalize(vWorldPosition - cameraPosition);
      vec3 reflectedVector = reflect(-lightVector, vNormal);
      float specularFactor = pow(max(0.0, -dot(reflectedVector, cameraViewVector)), 2.0);
      float fresnelFactor = pow(1.0 - max(0.0, -dot(vNormal, cameraViewVector)), 5.0);
      vec3 ambientColor = sky(vNormal);
      #{APhysicalShader.shadowMapBodyFragment}
  """
  @fragmentShaderBody: """
    gl_FragColor = vec4(
      (
        lightColor * (
          directFactor * (0.2 * specularFactor + lambertTopFactor) // Direct light
          + 0.05 * lambertBottomFactor // Bounce light
          + (0.1 * fresnelFactor) // Some fresnel
        )
        + ambientColor * 0.02
      ) * color
      , 1.0);
  """
  @fragmentShader: """
    #{APhysicalShader.fragmentShaderHeader}
    void main() {
      #{APhysicalShader.fragmentShaderPre}
      #{APhysicalShader.fragmentShaderBody}
    }
    """
  constructor: (options = {})->
    @color = new THREE.Color()
    @shadowCameras = []
    super

    @vertexShader = options.vertexShader or APhysicalShader.vertexShader
    @fragmentShader = options.fragmentShader or APhysicalShader.fragmentShader
    @uniforms.color =
        type: "c"
        value: @color

    if @shadowCameras.length > 0
      @fragmentShader = "#define SHADOWMAPS #{@shadowCameras.length}\n#{@fragmentShader}"
      @uniforms.shadowMatrices =
          type: "m4v"
          value: sc.matrixWorldInverse for sc in @shadowCameras
      @uniforms.shadowSizes =
          type: "m3v"
          value: sc.size for sc in @shadowCameras
      @uniforms.shadowTextures =
          type: "tv"
          value: sc.renderTarget for sc in @shadowCameras

    @defaultAttributeValues = undefined