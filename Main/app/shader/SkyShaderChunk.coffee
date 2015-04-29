module.exports = """
vec3 sky(vec3 direction){
  float factor = abs(direction.y);
  factor = 1.0 - factor;
  factor *= factor;
  factor = 1.0 - factor;
  return vec3(0.4, 0.7, 1.0) * (1.0 - factor) +
    vec3(0.1, 0.4, 1.0) * factor;
}
"""
