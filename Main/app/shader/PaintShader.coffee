APhysicalShader = require("shader/APhysicalShader")
module.exports = class PaintShader extends THREE.ShaderMaterial
  @fragmentShader : """
  varying vec3 vNormal;
  varying vec3 vWorldPosition;
  varying float lambert;
  uniform vec3 color;
  uniform samplerCube envmap;
  #{require("shader/SkyShaderChunk")}
  void main() {
    vec3 lightDirection = #{APhysicalShader.LIGHT_POSITION};
    vec3 lightColor = #{APhysicalShader.LIGHT_COLOR};
    vec3 cameraView = normalize(vWorldPosition - cameraPosition);
    vec3 reflectedLight = reflect(-lightDirection, vNormal);
    float fresnel = 0.2 * pow(1.0 - max(0.0, -dot(vNormal, cameraView)), 2.0);
    vec3 specular = lightColor * 0.5 * pow(max(0.0, -dot(reflectedLight, cameraView)), 50.0);
    vec3 ambient = 0.02 * sky(vNormal);
    vec3 reflectedColor = textureCube(envmap, reflect(cameraView, vNormal)).xyz;
    gl_FragColor = vec4(specular + fresnel * reflectedColor + lightColor * color * (ambient + lambert), 1.0);
  }
  """
  constructor: (options)->
    @color = new THREE.Color()
    super
    @vertexShader = APhysicalShader.vertexShader
    @fragmentShader = PaintShader.fragmentShader
    # A variant of the APhysical
    @uniforms = 
      color:
        type: "c"
        value: @color
      envmap:
        type: "t"
        value: options.envmap
