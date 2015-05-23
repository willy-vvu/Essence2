DepthShader = require("shader/DepthShader")
APhysicalShader = require("shader/APhysicalShader")
depthShader = new DepthShader()
module.exports = class ShadowCamera extends THREE.OrthographicCamera
  constructor: (left, right, top, bottom, near, far, options)->
    super
    @renderer = options.renderer
    @scene = options.scene
    @renderTarget = options.renderTarget
    @size = new THREE.Matrix3()
    @bias = options.bias or 0
    @updateSize()

  updateSize: ()->
    @size.set(@left, @bottom, @near, @right, @top, @far, @bias, 0, 0)

  renderShadowmap: (debug)->
    depthShader.useCamera(this)
    @scene.overrideMaterial = depthShader
    @renderer.setClearColor(0xffffff, 1.0)
    if debug
      @renderer.render(@scene, this)
    else
      @renderer.render(@scene, this, @renderTarget)
    @scene.overrideMaterial = null