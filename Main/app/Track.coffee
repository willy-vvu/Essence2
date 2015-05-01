# This is actually a specialized class. Pull things out into a more generic class later.
ChaseCamera = require("ChaseCamera")
TrackSpline = require("TrackSpline")
Utils = require("Utils")
require("OBJLoader")
SkyShader = require "shader/SkyShader"
APhysicalShader = require "shader/APhysicalShader"
ToneMapShader = require "shader/ToneMapShader"
SeaShader = require "shader/SeaShader"

tempQuaternion = new THREE.Quaternion()
tempVector = new THREE.Vector3()
module.exports = class Track extends THREE.Scene
  constructor: (@game)->
    super
    @loaded = false
    @game.preloader.resetProgress()
    @game.preloader.register("models/Concept 2.obj")
    @game.preloader.register("models/Concept 2.curves.json")
    @game.preloader.register("models/Ship v3.obj")
    @game.preloader.status = ()=>
      #console.log("#{this.game.preloader.loaded} of #{this.game.preloader.total}")
    @game.preloader.done = ()=>
      #console.log("done")
      @init()
      @loaded = true
    @game.preloader.error = (error)=>
      console.log(error)
    @game.preloader.startAll()


  init: ()->
    dlight = new THREE.DirectionalLight(0xFFFFFF, 1.4)
    dlight.position.set(1, 1, -1)
    @add(dlight)
    dlight2 = new THREE.DirectionalLight(0xFFFFFF, 0.6)
    dlight2.position.set(1, -1, -1)
    @add(dlight2)
    @add(new THREE.AmbientLight(0x111111))

    @shipHolder = new THREE.Object3D()
    @add(@shipHolder)

    @camera = new THREE.PerspectiveCamera(60, @game.aspect, 2, 50000)
    @camera.logarithamicDepthBuffer = true

    @reflectionCamera = new THREE.PerspectiveCamera(60, @game.aspect, 2, 50000)
    @reflectionCamera.logarithamicDepthBuffer = true

    @add(@reflectionCamera)
    
    @reflectionTexture = new THREE.WebGLRenderTarget() # {type: THREE.FloatType}
    @reflectionTexture.setSize(1024, 1024)

    #@shipHolder.add(@camera)
    
    shipData = THREE.OBJLoader::parse(@game.preloader.get("models/Ship v3.obj"))
    ship = shipData
    @shipHolder.add(ship)
    ship.position.set(0, 1.2, 0)
    ship.rotation.y = Math.PI
    ship.children[0].material =
    ship.children[1].material = new THREE.MeshBasicMaterial(color: 0)
    ship.children[0].material.side =
    ship.children[1].material.side = THREE.DoubleSide
    ship.scale.multiplyScalar(0.8)

    @cameraHolder = new ChaseCamera()
    @cameraHolder.offset.set(0, 2.5, 1.5)
    @cameraHolder.target = @shipHolder
    @add(@cameraHolder)
    
    @cameraHolder.add(@camera)
    @camera.position.set(0, 0, 100)
    @controls = new THREE.OrbitControls(@camera)

    @addScene()


    #@shipHolder.position.set(0, 0, 0)

    splinePoints = TrackSpline.import(JSON.parse(@game.preloader.get("models/Concept 2.curves.json"))["TrackPath"])
    @trackSpline = new TrackSpline(splinePoints)
    @pos = 0
    @lateral = 0
    @lateralTarget = 0

    # @traverse (child)->
    #   if child instanceof THREE.Mesh and child.material?
    #     child.material = new THREE.MeshLambertMaterial(child.material)

    @finalToneMap = new ToneMapShader()

    document.body.addEventListener "keydown", (event)=>
      switch event.keyCode
        when 37
          @lateralTarget-=6
        when 39
          @lateralTarget+=6
        when 40
          @pos-=30
        when 38
          @pos+=30

    @time = 0

  update: ()->
    #@pos+=50/60
    factor = (@pos/800)%%1
    newPoint = tempVector.copy(@trackSpline.getNaturalSplinePoint(factor))
    direction = @trackSpline.getNaturalSplineDirection(newPoint, factor)
    euler = @trackSpline.getNaturalSplineFrame(direction, factor)
    if @pos%%1600 >= 800
      euler.z+=Math.PI
    #console.log direction
    #direction.multiplyScalar(-1).add(@shipHolder.position)
    tempQuaternion.setFromEuler(euler)
    @shipHolder.position.copy(newPoint)
    @lateralTarget = Utils.clamp(@lateralTarget, -6, 6)
    @lateral = Utils.lerp(@lateral, @lateralTarget, 0.2)
    tempVector.set(@lateral, 0, 0).applyQuaternion(tempQuaternion)
    @shipHolder.position.add(tempVector)
    @shipHolder.quaternion.slerp(tempQuaternion, 0.8)
    @cameraHolder.update()

    @time += 1/60

  render: ()->
    @cameraHolder.updateMatrixWorld()
    @camera.updateMatrixWorld()

    @renderReflection()

    @game.composer.reset()
    @game.composer.render(this, @camera)
    @game.composer.pass(@finalToneMap)
    @game.composer.toScreen()
    # @game.renderer.render(this, @camera)

  renderReflection: ()->
    tempVector.setFromMatrixPosition(@camera.matrixWorld)
    @reflectionCamera.position.copy(tempVector)
    @reflectionCamera.position.y *= -1
    # Reflect the quaternion
    @reflectionCamera.quaternion.setFromRotationMatrix(@camera.matrixWorld)
    @reflectionCamera.quaternion.x *= -1
    @reflectionCamera.quaternion.z *= -1

    @seaMesh.visible = false
    @game.renderer.render(this, @reflectionCamera, @reflectionTexture)
    @seaMesh.visible = true
    @seaMesh.material.uniforms.resolution.value.set(@game.width, @game.height)
    @seaMesh.material.uniforms.time.value = @time

  resize: ()->
    @camera.aspect = @game.aspect
    @camera.updateProjectionMatrix()
    @reflectionCamera.aspect = @game.aspect
    @reflectionCamera.updateProjectionMatrix()

  addScene: ()->
    scene = THREE.OBJLoader::parse(@game.preloader.get("models/Concept 2.obj"))
    
    groups = [
      "Static_Environment"
      "Track_Environment"
      "Track"
      "Sea"
    ]

    # Count total vertices
   
    counts = (0 for group in groups)
    scene.traverse (child)->
      if child instanceof THREE.Mesh
        index = groups.indexOf(child.material.name)
        if index >= 0
          counts[index] += child.geometry.attributes.position.array.length

    # Build merged geometry holders
    geometries = for count in counts
      geo = new THREE.BufferGeometry()
      geo.addAttribute("position", new THREE.BufferAttribute(new Float32Array(count), 3))
      geo.addAttribute("normal", new THREE.BufferAttribute(new Float32Array(count), 3))
      geo

    # Merge all geometry into the holders
    counts = (0 for group in groups)
    scene.traverse (child)->
      if child instanceof THREE.Mesh
        index = groups.indexOf(child.material.name)
        if index >= 0
          for i in [0...child.geometry.attributes.position.array.length]
            geometries[index].attributes.position.array[counts[index]] = child.geometry.attributes.position.array[i]
            geometries[index].attributes.normal.array[counts[index]] = child.geometry.attributes.normal.array[i]
            counts[index]++


    materials = [
      new APhysicalShader()
      new APhysicalShader()
      new APhysicalShader(color: 0xFF8C00)
      new SeaShader(reflectionTexture: @reflectionTexture)
    ]

    # Add them to the scene
    meshes = for i in [0...geometries.length]
      mesh = new THREE.Mesh(geometries[i], materials[i])
      @add(mesh)
      mesh

    @seaMesh = meshes[3]

    # Add sky
    sky = new THREE.Mesh(new THREE.BoxGeometry(40000, 40000, 40000), new SkyShader({side: THREE.BackSide}))
    @add(sky)
    #console.log geometries, scene