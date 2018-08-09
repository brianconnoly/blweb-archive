buzzlike.service 'desktopState', (taskService, contextMenu, desktopService, multiselect, stateManager, scheduleService, buffer, $injector, contentService, $rootScope, combService, postService, uploadService) ->

    lastRect = 
        x1: 0
        y1: 0
        elem: false

    # defaultState =
    stateManager.registerState 'desktop',
        'enter': ->
            items = multiselect.getFocused()

            for item in items
                if item.type == 'schedule'
                    buffer.addItem postService.getById item.postId
                else
                    buffer.addItem item

            $rootScope.$apply()

        'escape cmd': () ->
            buffer.clearCurrentPocket()
            $rootScope.$apply()

        'D cmd': () ->
            $(multiselect.state.context).find('.selectableItem').removeClass('selected')
            multiselect.flush()
            $rootScope.$apply()

        'A cmd': () ->
            context_elem = multiselect.state.context
            multiselect.flush()

            if !context_elem?
                context = $('.workarea')
            else
                context = $ context_elem

            elems = context.find('.selectableItem')
            elems.each () ->
                $(@).addClass('selected')
                item = angular.element(@).scope().item

                multiselect.addToFocus item

            $rootScope.$apply()

        'U cmd': (where) ->
            # input = $('.uploadHelper input')
            # input.click()
            if !where?
                where = []

            # If something selected in right panel, ignore 'where'
            if $(multiselect.state.context).hasClass('pocket') and multiselect.state.focusedHash.length > 0
                where = multiselect.getFocused()

            pHolders = []
            for item in where
                if item.type == 'placeholder'
                    pHolders.push item

            if pHolders.length > 0
                # Remove placeholders from where
                for pHolder in pHolders
                    removeElementFromArray pHolder, where

                uploadService.requestUpload where, (cb) ->
                    seq = new Sequence
                        name: 'Prepare upload destination'

                    seq.addStep
                        name: 'Create comb'
                        var: 'combItem'
                        action: (next) ->
                            combService.create {}, next

                    seq.addStep
                        name: 'Create and schedule post for every placeholder'
                        check: -> pHolders.length > 0
                        iterator: (step) -> step pHolder for pHolder in pHolders
                        action: (next, retry, pHolder) ->
                            postService.create 
                                combId: seq.combItem.id
                            , (postItem) ->
                                scheduleService.create
                                    postId: postItem.id
                                    communityId: pHolder.communityId
                                    timestamp: pHolder.timestamp
                                , (schedItem) ->
                                    where.push postItem if postItem.id?
                                    next postItem

                    seq.fire (result) ->
                        cb where
            else 
                uploadService.requestUpload where

        'V cmd': (where) ->

            if createTextLock
                return false

            createTextLock = true
            if handler?
                clearTimeout handler
            handler = setTimeout () ->
                createTextLock = false
                handler = null
            , 1000

            # If something selected in right panel, ignore 'where'
            if $(multiselect.state.context).hasClass('pocket') and multiselect.state.focusedHash.length > 0
                where = multiselect.getFocused()

            selectText = true
            contentService.create
                type: 'text' 
                value: ''
            , (text) ->
                buffer.addItems [text]

                desktopService.launchApp 'textEditor',
                    textId: text.id
                    startPosition: 'center'

                pHolders = []

                if where?.length > 0
                    for item in where
                        switch item.type
                            when 'folder'
                                contentService.addContentIds item, [text.id]
                            when 'comb'
                                combService.addContentIds item, [text.id]
                            when 'schedule'
                                postService.addContentIds item.postId, [text.id]
                            when 'post'
                                postService.addContentIds item.id, [text.id]
                            when 'placeholder'
                                pHolders.push item
                            when 'task'
                                taskService.call 'addEntity',
                                    taskId: item.id
                                    entities: [
                                        type: 'text'
                                        id: text.id
                                    ]
                                , ->
                                    true

                if pHolders.length > 0
                    seq = new Sequence
                        name: 'Create posts with text'

                    seq.addStep
                        name: 'Create comb'
                        var: 'combItem'
                        action: (next) ->
                            combService.create 
                                items: [text.id]
                            , next

                    seq.addStep
                        name: 'Schedule post'
                        iterator: (step) -> step placeholder for placeholder in pHolders
                        action: (next, retry, placeholder) ->
                            scheduleService.create 
                                items: [text.id]
                                combId: seq.combItem.id
                                communityId: placeholder.communityId
                                timestamp: placeholder.timestamp
                            , next

                    seq.fire (result) ->
                        true

        'I cmd': () ->
            desktopService.launchApp 'socialImport'
            $rootScope.$apply()
        # '49 cmd': () ->
        #     $('.page_timeline').trigger('click')
        #     $rootScope.$apply()
        # '50 cmd': () ->
        #     $('.page_combs').trigger('click')
        #     $rootScope.$apply()
        # '51 cmd': () ->
        #     $('.page_content').trigger('click')
        #     $rootScope.$apply()
        # '52 cmd': () ->
        #     $('.page_market').trigger('click')
        #     $rootScope.$apply()
        'F cmd': () ->
            desktopService.launchApp 'searchMedia'
            $rootScope.$apply()

        'Tilda': () ->
            angular.element($('#blMenu')[0]).scope().menuClick()
            $rootScope.$apply()

        'right': () ->
            lastRect = moveSelect getRight, true
            true

        'right shift': () ->
            moveSelect getRight, true, true
            true

        'left': () ->
            lastRect = moveSelect getLeft, true
            true

        'left shift': () ->
            moveSelect getLeft, true, true
            true

        'up': () ->
            lastRect = moveSelect getUp, true
            true

        'up shift': () ->
            moveSelect getUp, true, true
            true

        'down': () ->
            lastRect = moveSelect getDown, true
            true

        'down shift': () ->
            moveSelect getDown, true, true
            true

        'right cmd': () ->
            lastRect = moveSelect getRight
            true
        'left cmd': () ->
            lastRect = moveSelect getLeft
            true
        'up cmd': () ->
            lastRect = moveSelect getUp
            true
        'down cmd': () ->
            lastRect = moveSelect getDown
            true
        'space': () ->
            angular.element(multiselect.state.lastFocused).scope().editAction $ multiselect.state.lastFocused
            true

    moveSelect = (closestFunc, flush, cmd) ->
        if flush then multiselect.flush(true)
        cached = cacheSelectable()
        
        lastX = 0
        lastY = 0
        lastFocused = multiselect.state.lastFocused
        if lastFocused?
            item = $ lastFocused
            offset = item.offset()

            if offset?
                lastX = offset.left
                lastY = offset.top

        if !cmd or multiselect.state.startedRect == true
            lastRect = 
                x1: 0
                y1: 0
                elem: false

            multiselect.state.startedRect = false

        if !lastRect.elem
            lastRect = 
                x1: lastX
                y1: lastY
                elem: item

        closest = closestFunc(cached, lastX, lastY)

        if closest?
            multiselect.state.lastFocused = closest.elem

            if cmd
                for cach in cached
                    
                    leftX = if lastRect.x1 < closest.x1 then lastRect.x1 else closest.x1
                    leftY = if lastRect.y1 < closest.y1 then lastRect.y1 else closest.y1
                    wid = Math.abs lastRect.x1 - closest.x1
                    hei = Math.abs lastRect.y1 - closest.y1

                    if cach.x1 >= leftX and 
                        cach.x1 <= leftX + wid and
                        cach.y1 >= leftY and
                        cach.y1 <= leftY + hei
                            multiselect.addToFocus cach.item
                            cach.elem.addClass 'selected'
            else
                multiselect.addToFocus closest.item
                closest.elem.addClass 'selected'

            return closest

        else
            if lastFocused?
                multiselect.addToFocus angular.element(lastFocused).scope().item
                lastFocused.addClass 'selected'

                return {
                    x1: lastX
                    y1: lastY
                    elem: lastFocused
                }

        {
            x1: 0
            y1: 0
            elem: false
        }

    getRight = (cached, lastX, lastY) ->
        closest = 
            minX: 0
            minY: 0
            item: null

        for cach in cached
            if cach.x1 <= lastX
                continue

            if stateManager.stateTree?.activeState?.name == 'timeline'
                if cach.y1 != lastY
                    continue

            distX = cach.x1 - lastX
            distY = Math.abs(lastY - cach.y1)

            if closest.item == null or distY < closest.minY
                closest.item = cach
                closest.minY = distY
                closest.minX = distX

            if distY == closest.minY and distX < closest.minX
                closest.item = cach
                closest.minY = distY
                closest.minX = distX
        closest.item

    getLeft = (cached, lastX, lastY) ->
        closest = 
            minX: 0
            minY: 0
            item: null

        for cach in cached
            if cach.x1 >= lastX
                continue

            if stateManager.stateTree?.activeState?.name == 'timeline'
                if cach.y1 != lastY
                    continue

            distX = lastX - cach.x1
            distY = Math.abs(lastY - cach.y1)

            if closest.item == null or distY < closest.minY
                closest.item = cach
                closest.minY = distY
                closest.minX = distX

            if distY == closest.minY and distX < closest.minX
                closest.item = cach
                closest.minY = distY
                closest.minX = distX
        closest.item

    getUp = (cached, lastX, lastY) ->
        closest = 
            minX: 0
            minY: 0
            item: null

        for cach in cached
            if cach.y1 >= lastY
                continue

            distY = lastY - cach.y1
            distX = Math.abs(lastX - cach.x1)

            if closest.item == null or distX < closest.minX
                closest.item = cach
                closest.minX = distX
                closest.minY = distY

            if distX == closest.minX and distY < closest.minY
                closest.item = cach
                closest.minX = distX
                closest.minY = distY
        closest.item

    getDown = (cached, lastX, lastY) ->
        closest = 
            minX: 0
            minY: 0
            item: null

        for cach in cached
            if cach.y1 <= lastY
                continue

            distY = cach.y1 - lastY
            distX = Math.abs(lastX - cach.x1)

            if closest.item == null or distX < closest.minX
                closest.item = cach
                closest.minX = distX
                closest.minY = distY

            if distX == closest.minX and distY < closest.minY
                closest.item = cach
                closest.minX = distX
                closest.minY = distY
        closest.item

    cacheSelectable = () ->
        # cache objects
        context = multiselect.state.context
        if !context?
            context = $('.multiselect')[0]

        elem = $ context

        list = elem.find '.selectableItem'
        cache = []
        list.each () ->
            item = $(this)
            offset = item.offset()
            itemScope = angular.element(@).scope()
            if itemScope.item.type == 'placeholder'
                entity = itemScope.item
            else
                entity = itemScope.item
                #entity = operationsService.get data.type, data.id
                
            cache.push
                hash: multiselect.getItemHash entity
                placeholder: itemScope.item.type == 'placeholder'
                x1: offset.left
                y1: offset.top
                x2: offset.left + item.width()
                y2: offset.top + item.height()
                item: entity
                elem: item
        cache

    # stateManager.setDefaultState defaultState