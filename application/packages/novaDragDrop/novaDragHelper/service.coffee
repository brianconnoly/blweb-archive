*deps: $compile, $rootScope, localization

class dragHelper

    currentHighlighter = null
    showHighLighter: (elem) ->
        if currentHighlighter == elem
            return
        currentHighlighter = elem
        jElem = $ elem

        @highlighter.addClass 'visible'
        @highlighter.css
            transform: "translate3d(#{jElem.offset().left - 2}px, #{jElem.offset().top - 2}px, 0)"
            # top: jElem.offset().top - 2
            # left: jElem.offset().left - 2
            width: jElem.width() + 2
            height: jElem.height() + 2

    flushHighlighter: ->
        @highlighter.removeClass 'visible'
        currentHighlighter = null

    buildElement: ->
        @scope = $rootScope.$new()
        @scope.dragItems = []
        @scope.actions = []
        @scope.novaDragHelper = @

        @active = false

        @elem = $ '<div>',
            class: 'novaDragHelper'
        @body.append @elem

        @elem = $ $compile(@elem)(@scope)

    bindElement: (@elem, @scope) ->
        @scope.dragItems = []
        @scope.actions = []
        @scope.novaDragHelper = @

        @active = false

    constructor: ->
        # @body = $ 'body'
        # @buildElement()

        @highlighter = $ '<div>',
            class: 'novaDropHighlighter'
        @highSolo = true
        true

    setActions: (actions) ->
        @scope.actions.length = 0
        for action in actions
            @scope.actions.push action
        @scope.$apply()

    show: (items) ->

        if @highSolo
            $('.nova').append @highlighter
            @highSolo = false

        @active = true
        @scope.dragItems.length = 0
        @scope.actions.length = 0
        @scope.helperText = ""

        types = {}
        for item in items
            @scope.dragItems.push item
            types[item.type] = 0 if !types[item.type]
            types[item.type]++

        for k,v of types
            if @scope.helperText != ""
                @scope.helperText += ', '
            @scope.helperText += v + ' ' + localization.declensionPhrase(v, 'itemType_' + k + '_dec' )

        if @scope.dragItems.length > 5
            @scope.dragItems.length = 5
        @elem.addClass 'visible'
        @scope.$apply()

    activate: (e) ->
        # Close if no actions
        if @scope.actions.length == 0
            @hide()
        # Fire action if single
        else if @scope.actions.length == 1
            if @preAction?
                @preAction @scope.actions[0].action, e
            else
                @scope.actions[0].action e
            @hide()
        # Activate actions picker if more
        else
            @elem.addClass 'active'
        @scope.$apply()

    hide: (noApply = false) ->
        @active = false
        @elem
        .removeClass 'visible'
        .removeClass 'active'
        @scope.dragItems.length = 0
        @scope.actions.length = 0
        @scope.helperText = ""
        @preAction = null
        @highlighter.removeClass 'visible'
        @scope.$apply() if !noApply
        true

new dragHelper
