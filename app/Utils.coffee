module.exports = class Utils
  @lerp: (a, b, factor)-> a * (1 - factor) + b * factor
  @clamp: (value, min, max)-> Math.min(Math.max(value, min), max)
  @map: (value1, min1, max1, min2, max2)-> if min1 is max1 then min2 else @lerp(min2, max2, (value1 - min1) / (max1 - min1))