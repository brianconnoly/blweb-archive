*deps: updateService, userService, streamItemService, $compile
*replace: true

elem = $ element
scope.empty = false

unreg = scope.$watch 'streamParentItem.type', (nVal) ->
    if nVal?
        unreg()
        streamItemService.getLastMessage scope.streamParentItem.id, (item) ->
            if !item?
                scope.empty = true
            else
                scope.empty = false
                addMessage item

scope.active = false
currentScope = null
currentElem = null

queue = []
inProgress = false
first = true

generateMessage = (streamItem, first = false)->
    newScope = scope.$new()
    newScope.user = userService.getById streamItem.userId
    newScope.streamItem = streamItem
    newScope.capitalize = true
    newScope.parentId = scope.streamParentItem.id

    newScope.onLoad = ->
        currentElem?.addClass 'hideUp'
        msgElem.removeClass 'new'

        exElem = currentElem
        exScope = currentScope
        currentElem = msgElem
        currentScope = newScope

        setTimeout ->
            exScope?.$destroy()
            exElem?.remove()
        , 500

        if queue.length > 0
            setTimeout ->
                generateMessage queue.shift()
            , 2000
        else
            inProgress = false

    msgElem = $ '<div>',
        class: if first then 'novaStreamLastMessage' else 'novaStreamLastMessage new'

    elem.append msgElem
    msgElem = $ $compile(msgElem)(newScope)

    console.log 'STREAM INDICATOR', elem.hasClass 'active'
    scope.heightChanged?()

addMessage = (streamItem) ->
    scope.empty = false
    if first
        elem.addClass 'active'
        elem.parent().addClass 'active'

    if inProgress == true
        queue.push streamItem
    else
        inProgress = true
        scope.active = true

        generateMessage streamItem, first

    first = false


updateId = updateService.registerUpdateHandler (data, action, items) ->
    # console.log data,action,items
    if action in ['update','create']
        if data['streamItem']?
            affected = []
            for item in items
                if item.type != 'streamItem' or item.parents?.length < 1
                    continue

                for parent in item.parents
                    if parent?.id == scope.streamParentItem.id
                        addMessage item
                        break

            scope.$applyAsync()

            # if affected.length > 0
                # for item in

scope.$on '$destroy', ->
    updateService.unRegisterUpdateHandler updateId

scope.launchStreamFrame = ->
    if scope.flowFrame?
        scope.flowFrame.flowBox.addFlowFrame
            title: 'task'
            directive: 'novaStreamFrame'
            item: scope.streamParentItem
        , scope.flowFrame
    else
        scope.flow.addFrame
            title: 'task'
            directive: 'novaStreamFrame'
            item: scope.streamParentItem
