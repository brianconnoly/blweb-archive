class StateTree

    constructor: ->
        @showed = false
        @stack = []
        @activeState = null

        @handler = null

    applyState: (state) ->
        if @activeState?
            @stack.push @activeState

        @activeState = state

    goBack: ->
        @activeState = @stack.pop()

StateTree
