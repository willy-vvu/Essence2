# This is actually a specialized class. Pull things out into a more generic class later.
ChaseCamera = require "ChaseCamera"
TrackSpline = require "TrackSpline"
Utils = require "Utils"
tempQuaternion = new THREE.Quaternion()
tempVector = new THREE.Vector3()
module.exports = class Track extends THREE.Scene
  constructor: (@game)->
    super
    @loaded = false
    @game.preloader.resetProgress()
    @game.preloader.register("models/Concept 2.json")
    @game.preloader.register("models/Concept 2.curves.json")
    @game.preloader.register("models/Ship v3.json")
    @game.preloader.status = ()=>
        console.log("#{this.game.preloader.loaded} of #{this.game.preloader.total}")
    @game.preloader.done = ()=>
        console.log("done")
        @init()
        @loaded = true
    @game.preloader.error = (error)=>
        console.log(error)
    @game.preloader.startAll()


  init: ()->
    scene = THREE.ObjectLoader::parse(JSON.parse(@game.preloader.get("models/Concept 2.json")))
    @children = scene.children
    track.children[0].rotation.set(-Math.PI/2, 0, 0)

    @traverse (child)->
      if child.name is "Plane"
        child.children[0].material.color = 0x224466

    dlight = new THREE.DirectionalLight(0xFFFFFF, 1.5)
    dlight.position.set(1, 1, -1)
    scene.add(dlight)
    scene.add(new THREE.AmbientLight(0x333333))

    @shipHolder = new THREE.Object3D()
    @add(@shipHolder)

    @camera = new THREE.PerspectiveCamera(60, @game.aspect, 3, 1000)
    #@shipHolder.add(@camera)
    
    shipData = THREE.ObjectLoader::parse(JSON.parse(@game.preloader.get("models/Ship v3.json")))
    ship = shipData
    @shipHolder.add(ship)
    ship.position.set(0, 1.2, 0)
    ship.rotation.y = Math.PI
    ship.children[0].material.side =
    ship.children[1].material.side = THREE.DoubleSide
    ship.scale.multiplyScalar(0.8)

    @cameraHolder = new ChaseCamera()
    @cameraHolder.offset.set(0, 3.5, 6)
    @cameraHolder.target = @shipHolder
    @add(@cameraHolder)
    
    @cameraHolder.add(@camera)
    @camera.position.set(0, 0, .1)
    #@camera.position.set(0,3.5,10)
    @controls = new THREE.OrbitControls(@camera)

    #@shipHolder.position.set(0, 0, 0)

    splinePoints = TrackSpline.import(JSON.parse(@game.preloader.get("models/Concept 2.curves.json"))["TrackPath"])
    @trackSpline = new TrackSpline(splinePoints)
    @pos = 0
    @lateral = 0
    @lateralTarget = 0

    @traverse (child)->
      if child instanceof THREE.Mesh and child.material?
        child.material = new THREE.MeshLambertMaterial(child.material)

    document.body.addEventListener "keydown", (event)=>
      switch event.keyCode
        when 37
          @lateralTarget-=6
        when 39
          @lateralTarget+=6


  update: ()->
    @pos+=50/60
    factor = (@pos/800)%1
    newPoint = tempVector.copy(@trackSpline.getNaturalSplinePoint(factor))
    direction = @trackSpline.getNaturalSplineDirection(newPoint, factor)
    euler = @trackSpline.getNaturalSplineFrame(direction, factor)
    if @pos%1600 >= 800
      euler.z+=Math.PI
    #console.log direction
    #direction.multiplyScalar(-1).add(@shipHolder.position)
    tempQuaternion.setFromEuler(euler)
    @shipHolder.position.copy(newPoint)
    @lateralTarget = Utils.clamp(@lateralTarget, -6, 6)
    @lateral = Utils.lerp(@lateral, @lateralTarget, 0.1)
    tempVector.set(@lateral, 0, 0).applyQuaternion(tempQuaternion)
    @shipHolder.position.add(tempVector)
    @shipHolder.quaternion.slerp(tempQuaternion, 0.8)
    @cameraHolder.update()

  resize: ()->
    @camera.aspect = @game.aspect
    @camera.updateProjectionMatrix()
