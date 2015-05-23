module.exports = class DepthShader extends THREE.ShaderMaterial
  @mapChunk: """
    float map(float a, float min, float max){
      return (a - min) / (max - min);
    }
  """
  @unpackDepth: """
    // Credits to THREE.js
    float unpackDepth( const in vec4 rgba_depth ) {

      const vec4 bit_shift = vec4( 1.0 / ( 256.0 * 256.0 * 256.0 ), 1.0 / ( 256.0 * 256.0 ), 1.0 / 256.0, 1.0 );
      float depth = dot( rgba_depth, bit_shift );
      return depth;

    }
  """
  @packDepth: """
    vec4 packDepth( const in float depth ) {

      const vec4 bit_shift = vec4( 256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0 );
      const vec4 bit_mask = vec4( 0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0 );
      vec4 res = mod( depth * bit_shift * vec4( 255 ), vec4( 256 ) ) / vec4( 255 );
      res -= res.xxyz * bit_mask;
      return res;

    }
  """
  @vertexShader: """
  varying vec4 vModelViewPosition;
  void main() {
    vModelViewPosition = modelViewMatrix * vec4( position, 1.0 );
    gl_Position = projectionMatrix * vModelViewPosition;
  }
  """
  @fragmentShader : """
  varying vec4 vModelViewPosition;
  uniform mat3 shadowSize;
  #{DepthShader.packDepth}
  #{DepthShader.mapChunk}
  void main() {
    float depth = map(-vModelViewPosition.z, shadowSize[2][0], shadowSize[2][1]);
    gl_FragColor = packDepth(depth);
  }
  """
  constructor: (options)->
    super
    @vertexShader = DepthShader.vertexShader
    @fragmentShader = DepthShader.fragmentShader
    @blending = THREE.NoBlending
    @uniforms.shadowSize =
        type: "m3"
        value: new THREE.Matrix3()

  useCamera: (shadowCamera)->
    @uniforms.shadowSize.value.copy(shadowCamera.size)
