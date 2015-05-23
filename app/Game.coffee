# Manages and renders the entire game, menus, and stages.
Track = require "Track"
Preloader = require "Preloader"
require("wagner/Wagner")
require("wagner/Wagner.base")
module.exports = class Game
  constructor: (@element) ->
    @renderer = new THREE.WebGLRenderer(autoClearColor: false)
    @renderer.setClearColor(0x000000, 0)
    @composer = new WAGNER.Composer(@renderer, type: THREE.FloatType, minFilter: THREE.NearestFilter, magFilter: THREE.NearestFilter)
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
      @track.render()

  resize: ->
    @width = @element.offsetWidth
    @height = @element.offsetHeight
    @aspect = if @height is 0 then 0 else @width / @height
    @renderer.setSize(@width, @height)
    @composer.setSize(@width, @height)
    if @track?
      @track.resize()