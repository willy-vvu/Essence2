# This is actually a specialized class. Pull things out into a more generic class later.
TrackSpline = require "TrackSpline"
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

    scene.add(new THREE.AmbientLight(0x999999))

    @shipHolder = new THREE.Object3D()
    @add(@shipHolder)

    @camera = new THREE.PerspectiveCamera(45, @game.aspect, 4, 1000)
    #@shipHolder.add(@camera)
    
    shipData = THREE.ObjectLoader::parse(JSON.parse(@game.preloader.get("models/Ship v3.json")))
    ship = shipData
    @shipHolder.add(ship)
    ship.position.set(0, 1.5, 0)
    ship.scale.z = -1

    cameraHolder = new THREE.Object3D()
    cameraHolder.position.set(0, 3.5, 0)
    @shipHolder.add(cameraHolder)
    cameraHolder.add(@camera)
    @camera.position.set(0, 0, 10)
    #@camera.position.set(0,3.5,10)
    @controls = new THREE.OrbitControls(@camera)

    #@shipHolder.position.set(0, 0, 0)

    splinePoints = TrackSpline.import(JSON.parse(@game.preloader.get("models/Concept 2.curves.json"))["TrackPath"])
    @trackSpline = new TrackSpline(splinePoints)
    @time = 0

  update: ()->
    @time+=0.001
    factor = @time%1
    newPoint = @shipHolder.position.copy(@trackSpline.getNaturalSplinePoint(factor))
    direction = @trackSpline.getNaturalSplineDirection(newPoint, factor)
    euler = @trackSpline.getNaturalSplineFrame(direction, factor)
    if @time%2 >= 1
      euler.z+=Math.PI
    #console.log direction
    #direction.multiplyScalar(-1).add(@shipHolder.position)
    @shipHolder.rotation.copy(euler)
  resize: ()->
    @camera.aspect = @game.aspect
    @camera.updateProjectionMatrix()