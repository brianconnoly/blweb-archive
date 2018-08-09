buzzlike.service 'comboboxService', (stateManager) ->
    state =
        opened: false
        position: {}  #inline CSS object
        value: null
        list: []
        cb: null


    showList = (data) ->
        updateObject state, data

        stateManager.applyState
            'noMenu': 'inherit'
            'hideRight': 'inherit'
            'escape': ->
                state.opened = false
                stateManager.goBack()


    {
        state

        showList
    }
