# Samples from an array of values in various ways.
Utils = require "Utils"
module.exports = class ArraySampler
  @get: (array, index)->
    # Linearly interpolates between array values, given fractional indices
    if array.length < 1
      return 0
    index = Utils.clamp(index, 0, array.length - 1)
    floor = Math.floor(index)
    if index is floor
      return array[index]
    else
      return Utils.lerp(array[floor], array[floor + 1], index - floor)

  @indexOf: (array, value)->
    # Given an array of ascending values, find the index (or fractional index) of the given value
    if array.length < 1
      return 0
    # Too small?
    if value <= array[0]
      return 0
    # Start searching
    for i in [1...array.length]
      if array[i] is value
        return i
      else if array[i] > value
        return Utils.map(value, array[i-1], array[i], i-1, i)
    # Too large?
    return array.length - 1

  @remap: (array1, array2, value1)->
    # Maps the value found in array1 to one in array2 of the same size.
    return @get(array2, @indexOf(array1, value1))