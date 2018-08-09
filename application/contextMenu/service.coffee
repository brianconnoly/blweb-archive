buzzlike.service 'contextMenu', ($rootScope, stateManager, smartDate, actionsService, complexMenu) ->

    status = 
        time: null
        cId: null
        gId: null
        active: false
        actions: []
        position:
            x: 0
            y: 0

    handlers = {}
    systemHandlers = {}

    contextState = 
        'noMenu': 'inherit'
        'hideRight': 'inherit'
        'escape': () ->
            hide()

    resetMenu = () ->
        status.active = false
        status.time = null
        status.cId = null
        status.gId = null
        status.actions.length = 0
        status.showPost = false

    show = (items, data) ->
        # resetMenu()
        # stateManager.applyState contextState
        # status.active = true
        # status.showPost = false

        # Prepare actions
        status.actions.length = 0
        status.context = data.target
        types = {}
        type = ''

        if items?[0]?.type in ['timeline','placeholder']
            status.showPost = true
            status.time = items[0].timestamp
        if data.target?.type in ['timeline','placeholder']
            status.showPost = true
            status.time = items[0].timestamp
        
        # actions = actionsService.getActions 
        #     source: items
        #     context: data.context
        #     sourceContext: data.sourceContext
        #     target: data.target or data.context
        #     actionsType: 'contextMenu'
            
        # for action in actions
        #     # if action.restrict != 'contextMenu'
        #     status.actions.push action

        itemsActions = actionsService.getActions 
            source: items
            context: data.context
            sourceContext: data.sourceContext
            target: data.target or data.context
            actionsType: 'contextMenu'
            
        if itemsActions.length > 0
            groups = {}
            list = []

            for action in itemsActions
                if !groups[action.category]?
                    groups[action.category] = 
                        type: 'actions' 
                        items: []

                groups[action.category].items.push 
                    phrase: action.phrase
                    action: action.action
                    priority: action.priority

            for k,actions of groups
                actions.items.sort (a,b) ->
                    if a.priority > b.priority
                        return -1
                    if a.priority < b.priority
                        return 1
                    0

            for k,actions of groups
                list.push actions

            complexMenu.show list,
                top: status.position.y
                left: status.position.x

        position status.position

    hide = () ->
        if status.active
            stateManager.goBack()

            status.active = false
            status.time = null
            status.cId = null
            status.gId = null
            status.actions.length = 0

    body = $('body')
    position = (pos) ->
        # hei = body.height()
        # wid = body.width()
        # menuHei = 36 * status.actions.length

        # if pos.y + menuHei > hei
        #     pos.y = hei - menuHei

        # if pos.x + 200 > wid
        #     pos.x = wid - 200

        status.position.x = pos.x
        status.position.y = pos.y

    # TODO: добавить приоритет для ранжирования элементов в списке
    registerAction = (data) ->
        types = data.type.split('/')

        for type in types
            if data.system? == true
                if !systemHandlers[type]?
                    systemHandlers[type] = []
                
                systemHandlers[type].push data
            else
                if !handlers[type]?
                    handlers[type] = []
                
                handlers[type].push data

    {   
        status

        show
        hide

        position

        registerAction
    }
