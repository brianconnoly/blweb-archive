buzzlike
    .factory 'multiselect', (operationsService, ruleService, scheduleService) ->

        state =
            context: null
            focusedHash: []
            focusedCnt: 0
            selectingInProgress: false
            lastFocused: null
            startedRect: true
            buffer: null

        copyItem = (item) ->
            state.buffer = item
            true

        clearBuffer = () ->
            state.buffer = null

        getBuffer = () ->
            if state.buffer == null
                return false

            state.buffer

        getItemHash = (item) ->
            if item?
                hash = item.type
                hash += '%'
                hash += item.id

                if item.type == 'placeholder'
                    hash += '%' + item.rule.id + '%' + item.communityId

                hash

        addToFocus = (item) ->
            hash = getItemHash item

            state.focusedHash.push hash if hash not in state.focusedHash
            # if item.type == 'placeholder'
            #     $('.placeholder_'+item.rule.id + '_' + item.id).addClass('selected')

        toggleFocused = (item) ->
            hash = getItemHash item
            if hash in state.focusedHash
                removeElementFromArray hash, state.focusedHash
                # if item.type == 'placeholder'
                #     $('.placeholder_' + item.rule.id + '_' + item.id).removeClass('selected')
                return false
            else
                state.focusedHash.push hash
                # if item.type == 'placeholder'
                #     $('.placeholder_'+item.rule.id + '_' + item.id).addClass('selected')
                return true

        isFocused = (item) ->
            hash = getItemHash item

            if hash in state.focusedHash
                return true
            false

        getItemByHash = (hash) ->
            arr = hash.split '%'

            switch arr[0]
                when 'placeholder'
                    if arr[3] == 'undefined'
                        arr.length = 2
                    item = ruleService.getPlaceholder arr[1], arr[2], arr[3]
                else # when 'image', 'video', 'audio', 'text', 'folder', 'url', 'comb', 'post', 'lot', 'schedule', 'user', 'team'
                    item = operationsService.get arr[0], arr[1]
            item

        getFocused = () ->
            items = []
            for hash in state.focusedHash

                item = getItemByHash hash

                items.push item if item?

            items

        removeFromFocus = (item) ->
            hash = getItemHash item

            removeElementFromArray hash, state.focusedHash

            # if item.type == 'placeholder'
            #     $('.placeholder_' + item.rule.id + '_' + item.id).removeClass('selected')

        flush = (force) ->
            if force
                $('.selectableItem.selected').removeClass('selected')
            else
                $('.selectableItem.selected:not(.stuck)').removeClass('selected')

            state.focusedHash.length = 0
            state.focusedCnt = 0
            #state.context = null # not shure

        {
            state

            copyItem
            getBuffer
            clearBuffer

            getItemHash

            isFocused
            getFocused

            addToFocus
            removeFromFocus
            toggleFocused

            flush
        }

    .directive 'multiselect', (multiselect, $injector, operationsService) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $(element)

            if elem.hasClass('norect')
                return

            body = $('body')
            activeScroll = null
            cache = []
            recent = []
            recentItems = []
            selector_tmpl = $ '<div>',
                class: 'starcraft'
            selector = $()

            initialPos = {}

            elem.off '.multiselect'
            elem.on 'mousedown.multiselect', (e) ->
                if e.which != 1 || $(e.target).hasClass("scroll-right") || $(e.target).hasClass("scroll-bottom")
                    return

                if multiselect.state.context != element[0]
                    multiselect.state.context = element[0]
                    $('.selectableItem.selected', $('.workarea')).removeClass('selected')
                    multiselect.flush()

                activeScroll = $(".antiscroll.hover")
                selector = $('.starcraft', $('body'))
                if !selector[0]?
                    $('body').append selector_tmpl
                    selector = $('.starcraft', $('body'))

                e = fixEvent e
                initialPos =
                    x: e.pageX
                    y: e.pageY

                recent.length = 0
                recentItems.length = 0

                # Show selector
                selector.css
                    top: initialPos.y + 'px'
                    left: initialPos.x + 'px'
                    width: 0
                    height: 0

                selector.addClass 'visible'

                # Bind move event
                elem.on 'mousemove.multiselect', mousemove
                elem.on 'mouseup.multiselect', mouseup

                multiselect.state.selectingInProgress = true

                # cache objects
                list = elem.find '.selectableItem'
                cache = []
                list.each () ->
                    item = $(this)
                    offset = item.offset()

                    elem_scope = angular.element(@).scope()
                    children_preview = $(@).children('.itemPreview')[0]

                    if elem_scope.type? and elem_scope.id?
                        entity = operationsService.get elem_scope.type, elem_scope.id

                    else if children_preview?
                        elem_scope = angular.element(children_preview).scope()

                        if elem_scope.sched?
                            entity = elem_scope.sched
                        else
                            type = $(children_preview).attr('type')
                            id = elem_scope.id

                            if !type?
                                if elem_scope.item?
                                    type = elem_scope.item.type
                                    id = elem_scope.item.id

                            entity = operationsService.get type, id

                    else
                        elem_scope = angular.element(@).scope()
                        entity = elem_scope.item

                    cache.push
                        hash: multiselect.getItemHash entity
                        placeholder: elem_scope.item?.type == 'placeholder'
                        x1: offset.left
                        y1: offset.top
                        x2: offset.left + item.width()
                        y2: offset.top + item.height()
                        item: entity
                        elem: item

            mouseup = (e) ->
                if selector[0]?
                    selector.detach()
                    selector.removeClass 'visible'

                activeScroll?.addClass "show"
                $(".antiscroll.hover").addClass "show"
                # Unbind move event
                elem.off 'mousemove.multiselect'
                elem.off 'mouseup.multiselect'

                multiselect.state.selectingInProgress = false
                multiselect.state.startedRect = true

                # multiselect.selectVisible multiselect.state.context
                scope.$apply()

            mousemove = (e) ->
                if e.which == 0 then mouseup(e)
                activeScroll?.removeClass "show"
                e = fixEvent e
                boundingBox = {}

                if e.pageX >= initialPos.x
                    selector.css
                        width: e.pageX - initialPos.x
                        left: initialPos.x
                        right: 'auto'

                    boundingBox.x1 = initialPos.x
                    boundingBox.x2 = e.pageX
                else
                    selector.css
                        width: initialPos.x - e.pageX
                        left: 'auto'
                        right: body.width() - initialPos.x

                    boundingBox.x1 = e.pageX
                    boundingBox.x2 = initialPos.x

                if e.pageY >= initialPos.y
                    selector.css
                        top: initialPos.y
                        height: e.pageY - initialPos.y
                        bottom: 'auto'

                    boundingBox.y1 = initialPos.y
                    boundingBox.y2 = e.pageY
                else
                    selector.css
                        bottom: body.height() - initialPos.y
                        height: initialPos.y - e.pageY
                        top: 'auto'

                    boundingBox.y1 = e.pageY
                    boundingBox.y2 = initialPos.y

                checkSelected boundingBox

            getContext = (element) ->
                ctx = element.parents('.multiselect')
                if multiselect.state.context == ctx[0]
                    return false
                else
                    multiselect.state.context = ctx[0]
                    return true

            checkSelected = (bb) ->
                newSel = []
                selItems = []
                for item in cache
                    if bb.x2 > item.x1 and bb.x1 < item.x2 and bb.y2 > item.y1 and bb.y1 < item.y2
                        # if newSel.indexOf(item) < 0
                        #     newSel.push item

                        hash = multiselect.getItemHash item.item

                        if selItems.indexOf(hash) < 0
                            selItems.push hash
                            newSel.push item

                # Compare
                for item in newSel

                    # Залепа т.к. ID у не импортированных видео/аудио в поиске еще нет id: null
                    # проверка multiselect.toggleFocused item.item в этом случае не сработает
                    if !item.item.id?
                        item.item.id = Math.random()

                    hash = multiselect.getItemHash item.item

                    if recent.indexOf(item) < 0 and recentItems.indexOf(hash) < 0
                        toggleSelection item

                for item in recent

                    hash = multiselect.getItemHash item.item

                    if newSel.indexOf(item) < 0 and selItems.indexOf(hash) < 0
                        toggleSelection item

                recent = newSel
                recentItems = selItems
                #scope.$apply()

            toggleSelection = (item) ->
                if multiselect.toggleFocused item.item
                    item.elem.addClass('selected')
                    multiselect.state.lastFocused = item.elem
                else
                    item.elem.removeClass('selected')

            true

    .directive 'selectableItem', (complexMenu, appsService, $parse, dropHelper, dragMaster, postService, scheduleService, multiselect, touchHelper, operationsService, contextMenu) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            parent = $('.workarea')
            jElem = $ element

            selectedPanel = false
            if $(element).parents('.selectedPanel')[0]?
                parent = $(element).parents('.selectedPanel')[0]
                selectedPanel = true

            if attrs.type?
                scope.type = attrs.type

            if attrs.id?
                scope.id = attrs.id

            if attrs.type? and scope.id? and !scope.item?.id?
                type = 'content'
                if attrs.type?
                    type = attrs.type

                operationsService.get type, scope.id, (item) ->
                    scope.item = item


            scope.selectFunc = (e) ->
                # if scope.session? and appsService.activeSession != scope.session
                #     appsService.activate scope.session

                contextMenu.hide()
                complexMenu.hide()
                dropHelper.flush true

                if e.shiftKey then return true

                multiselect.state.startedRect = true

                elem = $ element
                cmd = (e.ctrlKey || e.metaKey) || touchHelper.state.multiselect

                ctx = elem.parents('.multiselect')

                if selectedPanel
                    multiselect.state.context = ctx[0]
                    $('.selectableItem.selected', $('.workarea')).removeClass('selected')

                    # multiselect.flush()

                if multiselect.state.context != ctx[0]
                    multiselect.flush()

                    multiselect.state.context = ctx[0]
                    $('.selectableItem.selected', ctx[0]).removeClass('selected')

                e.stopPropagation()
                e.preventDefault()

                $(':focus').blur()

                if !touchHelper.state.touch and e.which != 1 then return

                if !cmd and !elem.hasClass('selected')
                    $('.selectableItem.selected', ctx[0]).removeClass('selected')
                    multiselect.flush()

                    elem.addClass('selected')

                if cmd
                    elem.toggleClass('selected')

                if elem.hasClass 'selected'
                    if scope.item?
                        multiselect.state.lastFocused = element
                        multiselect.addToFocus scope.item
                    else
                        multiselect.state.lastFocused = element
                        multiselect.addToFocus
                            id: scope.id
                            type: attrs.type
                else
                    if scope.item?
                        multiselect.removeFromFocus scope.item
                    else
                        multiselect.removeFromFocus
                            id: scope.id
                            type: attrs.type
                if angular.element(elem.parents('.appLauncher')[0]).scope()?
                    appsService.activate angular.element(elem.parents('.appLauncher')[0]).scope()?.session, true
                scope.$apply()
                false

            jElem.on 'mousedown', scope.selectFunc

            if !element.hasClass('videoItemImport')
                draggedItem = null

                new dragMaster.dragObject element[0],
                    global: true
                    helper: 'clone'
                    multi: true
                    candrag: (dObj, e) ->
                        if $(element).hasClass('feedItem')
                            if scope.item.type == 'placeholder'
                                return true

                            # sched = scheduleService.getById scope.item.id
                            # if (sched.status == 'completed' or sched.status == 'error') and !e.altKey
                            #     return false

                            # community = angular.element($(element).parent()[0]).scope().$parent.item
                            # if community.socialNetwork == 'fb' and e.altKey
                            #     return false

                            return true

                        true
                    start: (dObj, e) ->
                        if attrs.context?
                            dObj.sourceContext = $parse(attrs.context)(scope)

                    end: () ->
                        if draggedItem
                            #delete draggedItem.collapsed
                            scope.$apply()


    .directive 'flushMousedown', (complexMenu, novaMenu) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            $(element).on 'mousedown', (e) ->
                e.stopPropagation()

                $('*').blur()

                name = $(e.target).prop("tagName")
                textWriting = name == 'TEXTAREA' or name == 'INPUT'

                if textWriting
                    return true

                novaMenu.hide()
                complexMenu.hide()

                e.preventDefault()


    .directive 'flushMultiselect', (complexMenu, multiselect, contextMenu, dropHelper, desktopService) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $ element
            elem.on 'mousedown', (e) ->
                desktopService.showMenu = false
                desktopService.subMenu = null
                if e.which != 3
                    contextMenu.hide()
                    complexMenu.hide()
                    dropHelper.flush true
                if !(e.ctrlKey || e.metaKey)
                    multiselect.state.lastFocused = null
                    multiselect.flush()
                    scope.$apply()
