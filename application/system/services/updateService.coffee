buzzlike.service 'updateService', () ->

    updateHandler = null
    id = 0

    handlers = {}
    registerUpdateHandler = (handler) ->
        id++
        handlers[id] = handler
        updateHandler = handler
        id

    unRegisterUpdateHandler = (id) ->
        delete handlers[id]

    destroyUpdateHandler = (id) ->
        updateHandler = null

    delayedUpdate =
        items: []
        handler: null

    triggerUpdate = (items, action = 'update') ->
        for item in items
            delayedUpdate.items.push item

        if !delayedUpdate.handler
            delayedUpdate.handler = setTimeout () ->

                # for id,cb of updateHandlers
                #     cb? delayedUpdate.items

                result = {}
                _items = []
                for item in delayedUpdate.items
                    if !item?.type?
                        continue

                    if item.type in ['text','image','audio','video','url','folder','poll','file','content']
                        result['content'] = true

                    result[item.type] = true
                    _items.push item if item not in _items

                for k,handler of handlers
                    handler? result, action, _items

                delayedUpdate.items.length = 0
                delayedUpdate.handler = null

            , 600

    {
        registerUpdateHandler
        unRegisterUpdateHandler

        destroyUpdateHandler
        triggerUpdate
    }
