module.exports = class APhysicalShader extends THREE.ShaderMaterial
  @LIGHT_POSITION: "normalize(vec3(0.6774711192265457, 0.6981397469246446, -0.2315896724336482))"
  @LIGHT_COLOR: "1.0 * vec3(1.0, 0.95, 0.84)"
  @vertexShader: """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambert;
    void main() {
      vNormal = (modelMatrix * vec4(normal, 0.0)).xyz;
      vWorldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

      vec3 lightDirection = #{APhysicalShader.LIGHT_POSITION};
      float lambertTop = dot(lightDirection, vNormal);
      lambertTop = lambertTop < 0.0? -0.01 * lambertTop: lambertTop;
      float lambertBottom = max(0.0, dot(lightDirection * vec3(1.0, -1.0, 1.0), vNormal));
      lambert = 0.8 * lambertTop + 0.1 * lambertBottom;
    }
    """
  @fragmentShader: """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambert;
    uniform vec3 color;
    #{require("shader/SkyShaderChunk")}
    void main() {
      vec3 lightDirection = #{APhysicalShader.LIGHT_POSITION};
      vec3 lightColor = #{APhysicalShader.LIGHT_COLOR};
      vec3 cameraView = normalize(vWorldPosition - cameraPosition);
      vec3 reflectedLight = reflect(-lightDirection, vNormal);
      float specular = 0.2 * pow(max(0.0, -dot(reflectedLight, cameraView)), 2.0);
      float fresnel = 0.2 * pow(1.0 - max(0.0, -dot(vNormal, cameraView)), 5.0);
      vec3 ambient = 0.02 * sky(vNormal);
      gl_FragColor = vec4(fresnel * color + lightColor * color * (specular + ambient + lambert), 1.0);
    }
    """
  constructor: ()->
    @color = new THREE.Color()
    super
    @vertexShader = APhysicalShader.vertexShader
    @fragmentShader = APhysicalShader.fragmentShader
    @uniforms = 
      color:
        type: "c"
        value: @color
