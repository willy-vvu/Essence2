module.exports = class SkyShader extends THREE.ShaderMaterial
  @vertexShader: """
  varying vec3 vWorldPosition;
  void main() {
    vWorldPosition = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
  }
  """
  @fragmentShader: """
  varying vec3 vWorldPosition;
  #{require("shader/SkyShaderChunk")}
  void main() {
    vec3 direction = normalize(vWorldPosition - cameraPosition);
    gl_FragColor = vec4(sky(direction), 1.0);
  }
  """
  constructor: ()->
    super
    @vertexShader = SkyShader.vertexShader
    @fragmentShader = SkyShader.fragmentShader
      #gl_FragColor = vec4( direction * 0.5 + 0.5, 1.0 );