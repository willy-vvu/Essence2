module.exports = class ToneMapShader extends THREE.ShaderMaterial
  constructor: ()->
    super
    @vertexShader = """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
    """
    @fragmentShader = """
    uniform sampler2D reflection;
    varying vec2 vUv;
    void main() {
      gl_FragColor = vec4(0.0, 0.0, 1.0);
    }
    """
    @uniforms = 
      reflection: 
        type: "t"
        value: null
