buzzlike.factory 'stateManager', ($rootScope, multiselect, $injector) ->

    states = {}
    currentState = null
    currentTree = null

    stack = []
    root = null

    createTextLock = false
    handler = null

    folderView = null
    combEdit = null

    appsService = null

    $rootScope.keymodes =
        shift: false
        alt: false
        cmd: false

    callAction = (key, modifier, repeat, e) ->
        if !states[root]? and !currentState? and !currentTree? then return false

        key = key

        for k,v of modifier
            if v then key += ' ' + k

        if currentTree?.activeState?[key]?

            if currentTree.activeState[key] == 'default'
                return false

            result = currentTree.activeState[key]? repeat, states[root]?[key], e
            return result != false

        else if currentState?[key]?

            if currentState[key] == 'default'
                return false

            currentState[key]? repeat
            return true

        else if states[root]?[key]?

            states[root][key]?(repeat)
            return true

        else if defaultState?[key]?

            defaultState[key]?(repeat)
            return true

        return false

    holdKeys = {}

    $(document).on 'keydown', (e) ->
        mod =
            shift: e.shiftKey
            alt: e.altKey
            cmd: isCmd e

        $rootScope.keymodes = mod

        prevent = false

        name = $(e.target).prop("tagName")
        textWriting = name == 'TEXTAREA' or name == 'INPUT'
        contenteditable = $(e.target).attr('contenteditable') || false
        forceDefault = $(e.target).attr('forcedefault') || false

        if e.keyCode == 13 and !forceDefault
            prevent = callAction 'enter', mod, null, e

        if e.keyCode == 32 and !textWriting and !contenteditable
            prevent = callAction 'space', mod
            if !prevent
                prevent = callAction 'enter', mod

        if e.keyCode == 27
            prevent = callAction 'escape', mod

        if (e.keyCode == 8 or e.keyCode == 46) and !textWriting and !contenteditable
            prevent = callAction 'delete', mod
            prevent = true

        if e.keyCode == 68 and !textWriting and !contenteditable
            prevent = callAction 'D', mod

        if e.keyCode == 65 and !textWriting and !contenteditable
            prevent = callAction 'A', mod

        if e.keyCode == 37 and !textWriting and !contenteditable # left arrow
            prevent = callAction 'left', mod, holdKeys['left']
            holdKeys['left'] = true

        if e.keyCode == 39 and !textWriting and !contenteditable # right arrow
            prevent = callAction 'right', mod, holdKeys['right']
            holdKeys['right'] = true

        if e.keyCode == 38 and !textWriting and !contenteditable # up arrow
            prevent = callAction 'up', mod

        if e.keyCode == 40 and !textWriting and !contenteditable # down arrow
            prevent = callAction 'down', mod

        if e.keyCode == 73 # cmd + u : upload
            prevent = callAction 'I', mod

        if e.keyCode == 78
            prevent = callAction 'N', mod

        if e.keyCode == 85 # cmd + u : upload
            prevent = callAction 'U', mod

        if e.keyCode == 67 # cmd + c : copy
            prevent = callAction 'C', mod

        if e.keyCode == 86 and !textWriting and !contenteditable # cmd + t : create text
            prevent = callAction 'V', mod

        if e.keyCode == 49 or e.keyCode == 50 or e.keyCode == 51 # cmd+1, cmd+2, cmd+3 - timeline,combs,content
            prevent = callAction e.keyCode, mod

        if e.keyCode == 70 # cmd+f - open media import
            prevent = callAction 'F', mod

        if (e.keyCode == 192 or e.keyCode == 221) and !textWriting and !contenteditable # tilda
            prevent = callAction 'Tilda', mod

        if prevent
            e.preventDefault()
            e.stopPropagation()
            $rootScope.$apply()
            return false

    $(document).on 'keyup', (e) ->
        mod =
            shift: e.shiftKey
            alt: e.altKey
            cmd: isCmd e
            up: true

        $rootScope.keymodes = mod

        prevent = false

        name = $(e.target).prop("tagName")

        textWriting = name == 'TEXTAREA' or name == 'INPUT'
        contenteditable = $(e.target).attr('contenteditable') || false

        if e.keyCode == 37 and !textWriting and !contenteditable # left arrow
            holdKeys['left'] = false
            prevent = callAction 'left', mod

        if e.keyCode == 39 and !textWriting and !contenteditable # right arrow
            holdKeys['right'] = false
            prevent = callAction 'right', mod

        if e.keyCode == 38 and !textWriting and !contenteditable # up arrow
            prevent = callAction 'up', mod

        if e.keyCode == 40 and !textWriting and !contenteditable # down arrow
            prevent = callAction 'down', mod

        if prevent
            e.preventDefault()
            e.stopPropagation()
            $rootScope.$apply()

    callEscape = () ->
        callAction 'escape'

    registerState = (name, state) ->
        states[name] = state
        true

    putOnTop = (state) ->
        if state == currentState then return

        if state in stack
            removeElementFromArray state, stack
            stack.push currentState
            currentState = state

    applyState = (state) ->
        if state == currentState then return

        # if !appsService?
        #     appsService = $injector.get 'appsService'

        # appsService.flushActive()

        if currentState?.name == 'notificationState'
            faderClick()

        if currentState?
            if state.child == true
                for k,prop of currentState
                    state[k] = prop if !state[k]?
            stack.push currentState
        currentState = state

    setState = (state) ->
        if state == currentState then return
        stack.length = 0
        currentState = state
        stack.push currentState
    flushState = ->
        stack.length = 0
        currentState = null

    getContext = () -> currentState?.context

    goState = (name) ->
        root = name
        stack.length = 0
        currentState = null # states[name] if states[name]?
        resetState()

    goRoot = () ->
        goState root if root?

    goBack = (noDeselect) ->
        if currentState?
            currentState = stack.pop()
        else if currentTree?
            currentTree.goBack()

        resetState(noDeselect)

    faderClick = () ->
        if currentState['fader']?
            currentState['fader']()
            return true
        else
            callAction 'escape', {}

    resetState = (noDeselect) ->
        if !noDeselect?
            $('.selected.selectableItem', $('.workarea')).removeClass('selected')
            multiselect.flush()

        $('.starcraft', $('body')).remove()

    defaultState = {}
    setDefaultState = (state) -> defaultState = state

    setTree = (tree) ->
        currentTree = tree

    clearTree = ->
        currentTree = null

    {
        setDefaultState
        registerState
        applyState

        getCurrentState: -> currentState

        callEscape
        callAction
        faderClick

        putOnTop

        goState
        goBack
        goRoot

        getContext

        setTree
        clearTree

        setState
        flushState
    }
