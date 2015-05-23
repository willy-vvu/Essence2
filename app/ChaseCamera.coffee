tempVector = new THREE.Vector3()
tempQuaternion = new THREE.Quaternion()
module.exports = class ChaseCamera extends THREE.Object3D
  constructor: ()->
    super
    @offset = new THREE.Vector3()
    @weights = new THREE.Vector3(0.95, 0.8, 0.8)
    @target = null

  update: ()->
    @target.updateMatrixWorld()
    tempQuaternion.setFromEuler(@target.rotation)
    @quaternion.slerp(tempQuaternion, 0.1)
    difference = tempVector.setFromMatrixPosition(@target.matrixWorld).sub(@position).multiplyScalar(-1)
    @position.sub(difference)
    
    # Convert to target space
    tempQuaternion.w *= -1
    difference.applyQuaternion(tempQuaternion)

    # Do some lerping
    difference.sub(@offset).multiply(@weights).add(@offset)

    # Convert back to world space
    tempQuaternion.w *= -1
    difference.applyQuaternion(tempQuaternion)

    @position.add(difference)