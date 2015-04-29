module.exports = class PostProcess
  constructor: (@renderer)->
    @scene = new THREE.Scene()
    #@camera = new THREE.OrthographicCamera()
    #@scene.add()
  render: (input, material, output)->
