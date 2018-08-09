class novaAddMenu

    constructor: ->
        @showed = false
        @position = 
            left: 0
            bottom: 40

    launch: (position) ->
        for k,v of position
            @position[k] = v
        @showed = true

    hide: ->
        @showed = false

new novaAddMenu()