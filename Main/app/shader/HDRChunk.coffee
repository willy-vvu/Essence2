module.exports = """
float toHDR(float n){
  return 1.0 - 0.2 / (0.2 + n);
}
float fromHDR(float n){
  return 0.2 / (1.0 - n) - 0.2;
}
vec3 toHDR(vec3 color){
  return color;//vec3(toHDR(color.x), toHDR(color.y), toHDR(color.z));
}
vec3 fromHDR(vec3 color){
  return color;//vec3(fromHDR(color.x), fromHDR(color.y), fromHDR(color.z));
}
"""