# A blender z-up spline from custom exported data.
Utils = require "Utils"
ArraySampler = require "ArraySampler"
bReturnVector = new THREE.Vector3()
bTempVector = new THREE.Vector3()
tempVector = new THREE.Vector3()
tempVector2 = new THREE.Vector3()
tempEuler = new THREE.Euler()

module.exports = class TrackSpline
  @import: (jsonData)->
    # Some quick JSON pre-processing
    for point in jsonData
      point.left = new THREE.Vector3(point.left[0], point.left[1], point.left[2])
      point.point = new THREE.Vector3(point.point[0], point.point[1], point.point[2])
      point.right = new THREE.Vector3(point.right[0], point.right[1], point.right[2])
    return jsonData
  @cubicBezierCore: (p1, p2, p3, p4, factor)->
    bReturnVector.set(0, 0, 0)
    bReturnVector.add(bTempVector.copy(p1).multiplyScalar((1 - factor) * (1 - factor) * (1 - factor)))
    bReturnVector.add(bTempVector.copy(p2).multiplyScalar(3 * factor * (1 - factor) * (1 - factor)))
    bReturnVector.add(bTempVector.copy(p3).multiplyScalar(3 * factor * factor * (1 - factor)))
    bReturnVector.add(bTempVector.copy(p4).multiplyScalar(factor * factor * factor))
    return bReturnVector
  @cubicBezier: (point1, point2, factor)->
    return TrackSpline.cubicBezierCore(point1.point, point1.right, point2.left, point2.point, factor)


  constructor: (@points)->
    @tilts = (point.tilt for point in @points)
    @generateNaturalMap()

  getSplineTilt: (factor)->
    index = @factorToIndex(factor)
    ArraySampler.get(@tilts, index)

  getNaturalSplineTilt: (factor)->
    @getSplineTilt(@inverseNaturalMap(factor))

  getSplinePoint: (factor)->
    index = @factorToIndex(factor)
    floor = Math.floor(index)
    if index is floor
      return @points[index].point
    else
      return TrackSpline.cubicBezier(@points[floor], @points[floor+1], index - floor)

  getNaturalSplinePoint: (factor)->
    @getSplinePoint(@inverseNaturalMap(factor))

  getNaturalSplineDirection: (existingPoint, existingFactor, delta = 0.001)->
    # Watch those references!
    existingFactor = Utils.clamp(existingFactor, 0, 1)
    tempVector.copy(existingPoint)
    # This'll create discontinuity around .5... better than around 0
    multiplier = if existingFactor<0.5 then 1 else -1
    nextVector = @getNaturalSplinePoint(existingFactor + multiplier * delta)
    nextVector.sub(tempVector).multiplyScalar(multiplier)
    return nextVector.normalize()

  getNaturalSplineFrame: (existingDirection, existingFactor)->
    existingFactor = Utils.clamp(existingFactor, 0, 1)
    tempEuler.set(
      Math.asin(existingDirection.y),
      Math.atan2(-existingDirection.x, -existingDirection.z),
      -@getNaturalSplineTilt(existingFactor), "YXZ")
    return tempEuler

  factorToIndex: (factor)->
    # Converts a 0-1 factor to an array index
    Utils.clamp(factor, 0, 1)*(@points.length-1)

  inverseNaturalMap: (naturalFactor)->
    # Uses the natural parameratization map to map a "spline distance" factor to 
    # a "spline time" factor using the natural mapping created in naturalParameratize()
    return ArraySampler.indexOf(@naturalMap, naturalFactor) / (@naturalMap.length - 1)

  generateNaturalMap: ()->
    @naturalMap = [0]
    # Creates an approximate mapping (reparamaterization) from "time" to spline distance*
    previousPoint = tempVector.copy(@getSplinePoint(0))
    currentPoint = tempVector2
    sum = 0
    for factor in [TrackSpline.NATURAL_RESOLTUION..1] by TrackSpline.NATURAL_RESOLTUION
      currentPoint.copy(@getSplinePoint(factor))
      sum += previousPoint.distanceTo(currentPoint)
      @naturalMap.push(sum)
      [previousPoint, currentPoint] = [currentPoint, previousPoint]

    for i in [0...@naturalMap.length]
      @naturalMap[i] /= sum

  @NATURAL_RESOLTUION: 0.002