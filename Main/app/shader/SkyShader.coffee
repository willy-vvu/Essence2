module.exports = class SkyShader extends THREE.ShaderMaterial
  constructor: ()->
    super
    @vertexShader = """
    varying vec3 vWorldPosition;
    void main() {
      vWorldPosition = position;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
    """
    @fragmentShader = """
    varying vec3 vWorldPosition;
    void main() {
      vec3 direction = normalize(vWorldPosition - cameraPosition);
      gl_FragColor = vec4( direction * 0.5 + 0.5, 1.0 );
    }
    """