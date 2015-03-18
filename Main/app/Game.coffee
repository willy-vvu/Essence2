# Manages and renders the entire game, menus, and stages.
Track = require "Track"
Preloader = require "Preloader"
module.exports = class Game
  constructor: (@element) ->
    @renderer= new THREE.WebGLRenderer()
    @renderer.setClearColor(0x22aaff)
    @width = 0
    @height = 0
    @aspect = 0
    @preloader = new Preloader()
    @resize()
    @element.appendChild(@renderer.domElement)
    @track = window.track = new Track(this)

  render: ->
    if @track.loaded
      @track.update()
      @renderer.render(@track, @track.camera)

  resize: ->
    @width = @element.offsetWidth
    @height = @element.offsetHeight
    @aspect = if @height is 0 then 0 else @width / @height
    @renderer.setSize(@width, @height)
    if @track?
      @track.resize()