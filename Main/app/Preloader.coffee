module.exports = class Preloader
  constructor: ->
    @loaded = 0
    @total = 0
    @fileMap = {}
    @done = null
    @status = null
    @error = null

  register: (path)->
    unless path of @fileMap
      @fileMap[path] = null
      @total++

  resetProgress: ()->
    @loaded = 0
    @total = 0

  startAll: ()->
    @status.call(this)
    for path of @fileMap when not @fileMap[path]?
      do (path)=>
        $.ajax(path, dataType: "text").done (data)=>
          @loaded++
          @fileMap[path] = data
          @status.call(this)
          if @loaded is @total
            @done.call(this)
        .error (obj, error)=>
          @error.call(this, error)

  get: (path)->
    return @fileMap[path]