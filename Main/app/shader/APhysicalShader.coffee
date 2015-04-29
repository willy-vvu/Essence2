module.exports = class APhysicalShader extends THREE.ShaderMaterial
  @LIGHT_POSITION: "normalize(vec3(0.6774711192265457, 0.6981397469246446, -0.2315896724336482))"
  @LIGHT_COLOR: "1.0 * vec3(1.0, 0.95, 0.84)"
  constructor: ()->
    @color = new THREE.Color()
    super
    @vertexShader = """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambert;
    void main() {
      vNormal = normal;
      vWorldPosition = position;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

      vec3 lightDirection = #{APhysicalShader.LIGHT_POSITION};
      float lambertTop = max(0.0, dot(lightDirection, vNormal));
      float lambertBottom = 0.1 * max(0.0, dot(lightDirection * vec3(1.0, -1.0, 1.0), vNormal));
      lambert = lambertTop + lambertBottom;
    }
    """
    color = "vec3(#{@color.r}, #{@color.g}, #{@color.b})"
    @fragmentShader = """
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying float lambert;
    uniform vec3 color;
    #{require("shader/SkyShaderChunk")}
    #{require("shader/HDRChunk")}
    void main() {
      vec3 lightDirection = #{APhysicalShader.LIGHT_POSITION};
      vec3 lightColor = #{APhysicalShader.LIGHT_COLOR};
      vec3 color = #{color};
      vec3 cameraView = normalize(vWorldPosition - cameraPosition);
      vec3 reflectedLight = reflect(-lightDirection, vNormal);
      float specular = 0.2 * pow(max(0.0, -dot(reflectedLight, cameraView)), 2.0);
      float fresnel = 0.2 * pow(1.0 - max(0.0, -dot(vNormal, cameraView)), 5.0);
      vec3 ambient = 0.1 * sky(vNormal);
      gl_FragColor = vec4(toHDR(fresnel * color + lightColor * color * (specular + ambient + lambert)), 1.0);
    }
    """
