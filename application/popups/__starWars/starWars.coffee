buzzlike.service 'starWars', (user, stateManager) ->

    state =
        textId: false

    starWarsState =
        noMenu: true
        hideRight: true
        'escape': () ->
            close()

    open = (textId) ->
        if user.animPrefs.turbo
            return
        state.textId = textId
        stateManager.applyState starWarsState
        true

    close = ->
        state.textId = false
        stateManager.goBack()
    {
        state

        open
        close
    }

buzzlike.directive 'starWars', (starWars, contentService) ->
    restrict: 'C'
    template: tC['/popups/starWars']
    link: (scope, element, attrs) ->
        elem = $ element
        scroller = elem.find('.scroller')
        #audio = elem.find('audio')
        audio = null

        scope.state = starWars.state
        scope.blocks = []
        scope.text = null

        handler = null

        scope.$watch ->
            starWars.state.textId
        , (nVal, oVal) ->
            if !nVal and !oVal
                return
            if nVal
                audio = new Audio()
                audio.src = '/audio/starwars.mp3'
                audio.autoplay = false
                audio.play()

                scope.blocks.length = 0
                contentService.getContentById nVal, (item) ->
                    scope.text = item
                    lines = item.value.split(/\r\n|\r|\n/g)

                    for line in lines
                        scope.blocks.push
                            value: line

                    setTimeout () ->
                        scroller.css
                            'top': -scroller.height()-500
                    , 100

                    handler = setTimeout () ->
                        starWars.close()
                        scope.$apply()
                    , 27 * SEC
                elem.fadeIn()
            else
                elem.fadeOut 400, () ->
                    audio.pause()
                    audio = null

                    scope.text = null
                    scroller.css
                        'top': '500px'

                if handler?
                    clearTimeout handler
                    handler = null
        true