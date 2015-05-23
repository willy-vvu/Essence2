APhysicalShader = require("shader/APhysicalShader")
module.exports = class PaintShader extends APhysicalShader
  @fragmentShaderHeader: """
    #{APhysicalShader.fragmentShaderHeader}
    uniform samplerCube envmap;
  """
  @fragmentShaderPre: """
    #{APhysicalShader.fragmentShaderPre}
    vec3 reflectedColor = textureCube(envmap, reflect(cameraViewVector, vNormal)).xyz;
  """
  @fragmentShaderBody: """
    gl_FragColor = vec4(
      (
        lightColor * (
          directFactor * (0.2 * specularFactor + 1.0) * lambertTopFactor // Direct light
          + 0.05 * lambertBottomFactor // Bounce light
        )
        + ambientColor * 0.2
      ) * color
      + 0.3 * (reflectedColor * fresnelFactor) // Some fresnel
      , 1.0);
  """
  @fragmentShader: """
    #{PaintShader.fragmentShaderHeader}
    void main() {
      #{PaintShader.fragmentShaderPre}
      #{PaintShader.fragmentShaderBody}
    }
  """
  constructor: (options)->
    options.vertexShader = APhysicalShader.vertexShader
    options.fragmentShader = PaintShader.fragmentShader
    super
    @uniforms.envmap =
        type: "t"
        value: options.envmap
