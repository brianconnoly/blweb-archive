*deps: $compile, $rootScope

class novaZoom

    constructor: ->
        setTimeout => 
            @picker = $compile('<div class="novaZoomPicker"></div>')($rootScope.$new())
            $('body').append @picker
        , 0
        @currentValue = 0

    pick: (@currentControl) ->
        @currentValue = @currentControl.current
        @picker.addClass 'active'

    setValue: (val) ->
        @currentValue = val
        if @currentControl?
            @currentControl.onChange val

    hide: ->
        @currentControl = null
        @picker.removeClass 'active'
        true

new novaZoom()