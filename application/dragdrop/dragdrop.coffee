buzzlike
    .factory 'dragMaster', ($parse, $rootScope, stateManager, multiselect, operationsService, notificationCenter, dropHelper) ->

        body = $('body')
        helperObj = null

        threshold =
            'x': 5
            'y': 5

        dragObject = null
        dragElem = null
        mouseDownAt = null

        currentDropTarget = null

        dragInProgress = false

        dragState =
            noMenu: 'inherit'
            'escape': () ->
                if dragObject?
                    dragObject.onDragEnd()

                    dragObject.onDragFail()

                    dragObject = null
                    dragElem = null

                $('.content-drop').removeClass 'content-drop'
                $('.drop-hover').removeClass 'drop-hover'

                __pholderHelper.detach()
                $('.sorting-hidden').removeClass('sorting-hidden')

                currentDropTarget = null
                dragInProgress = false
                removeDocumentEventHandlers()
                stateManager.goBack()

                dropHelper.flush()

        mouseDown = (e) ->
            if notificationCenter.status.progress
                clearJunk()
                return false

            e = fixEvent e
            if e.which != 1 or e.shiftKey then return

            mouseDownAt =
                x: e.pageX
                y: e.pageY
                element: this

            addDocumentEventHandlers()
            dropHelper.flush()

            true

        clearJunk = ->
            $('.helper-transparent').remove()

        mouseMove = (e) ->
            e = fixEvent e

            if mouseDownAt
                if Math.abs(mouseDownAt.x-e.pageX) < threshold.x and Math.abs(mouseDownAt.y-e.pageY) < threshold.y
                    return false

                elem = mouseDownAt.element
                if !elem.dragObject.canDrag(e) then return false

                dragObject = elem.dragObject
                dragElem = elem

                mouseOffset = getMouseOffset elem, mouseDownAt.x, mouseDownAt.y
                mouseDownAt = null

                dragObject.onDragStart mouseOffset, e

                dragInProgress = true
                stateManager.applyState dragState
                $rootScope.$apply()

            dragObject.onDragMove e.pageX, e.pageY

            newTarget = getCurrentTarget e

            newTarget?.onMove? dragElem, e

            if currentDropTarget != newTarget
                if currentDropTarget
                    currentDropTarget.onLeave dragElem

                if newTarget
                    newTarget.onEnter dragElem, e

                currentDropTarget = newTarget

            false

        mouseUp = (e) ->
            if !dragObject
                mouseDownAt = null
            else
                stateManager.goBack()
                dragObject.onDragEnd()

                if currentDropTarget?
                    currentDropTarget.accept dragElem, e
                    dragObject.onDragSuccess currentDropTarget
                else
                    dragObject.onDragFail()

                dragObject = null
                dragElem = null

            __pholderHelper.detach()
            $('.sorting-hidden').removeClass('sorting-hidden')

            currentDropTarget = null
            dragInProgress = false
            removeDocumentEventHandlers()

        getOffsetRect = (elem) ->
            box = elem.getBoundingClientRect()

            body = document.body
            docElem = document.documentElement

            scrollTop = window.pageYOffset || docElem.scrollTop || body.scrollTop
            scrollLeft = window.pageXOffset || docElem.scrollLeft || body.scrollLeft
            clientTop = docElem.clientTop || body.clientTop || 0
            clientLeft = docElem.clientLeft || body.clientLeft || 0
            top  = box.top +  scrollTop - clientTop
            left = box.left + scrollLeft - clientLeft

            top: Math.round(top)
            left: Math.round(left)

        getOffsetSum = (elem) ->
            top = 0
            left = 0
            while elem
                top = top + Math.floor(elem.offsetTop)
                left = left + Math.floor(elem.offsetLeft)
                elem = elem.offsetParent

            top: top
            left: left

        getOffset = (elem) ->
            if elem.getBoundingClientRect
                return getOffsetRect elem
            else
                return getOffsetSum elem

        getMouseOffset = (target, x, y) ->
            # docPos  = getOffset target

            # margin = $(target).margin()#.css("margin")

            'x': 0 # x - docPos.left + margin.left
            'y': 0 # y - docPos.top + margin.top

        getCurrentTarget = (e) ->
            if navigator.userAgent.match('MSIE') or navigator.userAgent.match('Gecko')
                x = e.clientX
                y = e.clientY
            else
                x = e.pageX
                y = e.pageY

            dragObject.hide()
            elem = document.elementFromPoint x, y
            dragObject.show()

            while elem
                if elem.dropTarget and elem.dropTarget.canAccept(dragElem, e)
                    return elem.dropTarget
                elem = elem.parentNode

            null

        addDocumentEventHandlers = () ->
            document.onmousemove = mouseMove
            document.onmouseup = mouseUp
            document.ondragstart = document.body.onselectstart = () -> false

        removeDocumentEventHandlers = () ->
            document.onmousemove = document.onmouseup = document.ondragstart = document.body.onselectstart = null

        makeDraggable = (element) ->
            element.onmousedown = mouseDown

        setDragObject: (obj) ->
            mouseDownAt.element = #obj
                'x': 0 #e.pageX
                'y': 0 #e.pageY
                'element': obj

        dragInProgress: () ->
            dragInProgress

        dragObject: (element, options) ->
            defaults =
                multi: false
                helper: false
                global: false
                pholder: false
                candrag: null
                start: null
                end: null
                drag: null
                success: null
                fail: null

            options = if options then $.extend defaults, options else defaults

            element.dragObject = @
            makeDraggable element

            @.dragEntity = element
            @.realElement = element
            @.offset = null

            if options.multi
                @.dragMulti = []
                @.items = []

            rememberPosition = null
            mouseOffset = null

            currentDroppable = null

            exParent = null
            helper = null

            bodyWid = null
            bodyHei = null

            @.canDrag = (e) ->
                if options.candrag?
                    options.candrag element, e
                else
                    true

            @.onDragStart = (offset, e) ->
                dropHelper.flush()
                helperObj = $('#dropHelper') 

                moveElement = element
                @.offset = offset

                bodyWid = $('body').width()
                bodyHei = $('body').height()

                if options.multi
                    toDrag = $('.selectableItem.selected', $(multiselect.state.context))

                    toDrag.each () ->
                        elem = $ @
                        helper = elem.clone()
                        helper.removeClass('selected')
                        helper.addClass('helper-transparent').addClass('inMove')
                        helper.appendTo body

                        s = helper[0].style
                        elem_scope = null
                        children_preview = elem.children('.itemPreview')[0]
                        if children_preview?
                            elem_scope = angular.element(children_preview).scope()

                            if elem_scope.sched?
                                type = elem_scope.sched.type
                                id = elem_scope.sched.id
                            else 
                                type = $(children_preview).attr('type')
                                id = elem_scope.id

                                if !type?
                                    if elem_scope.item?
                                        type = elem_scope.item.type
                                        id = elem_scope.item.id

                                if !id?
                                    id = $parse($(children_preview).attr('id'))(elem_scope)


                        else
                            elem_scope = angular.element(elem[0]).scope()
                            data = elem_scope.item
                            type = data.type
                            id = data.id

                        if type == 'placeholder'
                            entity = elem_scope.item
                        else
                            entity = operationsService.get type, id

                        element.dragObject.items.push entity
                        element.dragObject.dragMulti.push
                            elem: helper[0]
                            real: elem
                            item: entity
                            top: s.top
                            left: s.left
                            position: s.position
                            fromRight: elem.parents('.selectedPanel').length > 0
                            alt: e.altKey

                        s.position = 'absolute'

                else
                    if options.helper != false
                        if options.helper == 'clone'
                            helper = $(element).clone().addClass('inMove')
                        else
                            helper = options.helper($(element))
                        $(element).addClass('dragged')

                        helper.appendTo $(element).parent()
                        moveElement = helper[0]

                        @.dragEntity = helper[0]

                    s = moveElement.style

                    rememberPosition =
                        top: s.top
                        left: s.left
                        position: s.position
                        exTarget: currentDroppable

                    s.position = 'absolute'

                    if options.global
                        exParent = $(moveElement).parent()
                        $(moveElement).appendTo body

                mouseOffset = offset

                options.start? element, e

                if currentDroppable?
                    currentDroppable.onPick element

            @.hide = () ->
                if options.multi
                    for item in @.dragMulti
                        item.elem.style.display = 'none'
                else
                    @.dragEntity.style.display = 'none'

            @.show = () ->
                if options.multi
                    for item in @.dragMulti
                        item.elem.style.display = ''
                else
                    @.dragEntity.style.display = ''

            @.onDragMove = (x, y) ->
                if !helperObj? 
                    helperObj = $('#dropHelper') 

                helperWid = helperObj.width() + 20
                helperHei = helperObj.height() + 20

                if x > bodyWid - helperWid or y < helperHei
                    helperObj[0].style.top  = y - mouseOffset.y + 10 + 'px'
                    helperObj[0].style.right = bodyWid - x + mouseOffset.x - 4 + 'px'
                    helperObj[0].style.left = 'auto'
                    helperObj[0].style.bottom = 'auto'
                else
                    helperObj[0].style.bottom = bodyHei - y + mouseOffset.y + 'px'
                    helperObj[0].style.left = x - mouseOffset.x + 12 + 'px'
                    helperObj[0].style.right = 'auto'
                    helperObj[0].style.top = 'auto'

                if options.multi
                    cnt = 0
                    for item in @.dragMulti
                        item.elem.style.top  = y - mouseOffset.y + cnt + 'px'
                        item.elem.style.left = x - mouseOffset.x - cnt + 'px'
                        cnt+=10
                else
                    @.dragEntity.style.top =  y - mouseOffset.y + 'px'
                    @.dragEntity.style.left = x - mouseOffset.x + 'px'

                options.drag?()

            @.onDragEnd = () ->
                options.end?()

                currentDropTarget?.onEnd()

            @.onDragSuccess = (dropTarget) ->
                options.success?(dropTarget)
                currentDroppable = dropTarget

                if options.multi
                    for item in @.dragMulti
                        item.elem.remove()

                    @.dragMulti.length = 0
                    @.items.length = 0
                    $(element).removeClass('dragged')
                else
                    if options.helper
                        helper.remove()
                        $(element).removeClass('dragged')

            @.onDragFail = () ->
                if options.multi
                    for item in @.dragMulti
                        item.elem.remove()
                    @.dragMulti.length = 0
                    @.items.length = 0
                    $(element).removeClass('dragged')
                else
                    if options.helper
                        helper.remove()
                        $(element).removeClass('dragged')
                    else

                        $(element).appendTo exParent
                        exParent = null

                        s = element.style
                        s.top = rememberPosition.top
                        s.left = rememberPosition.left
                        s.position = rememberPosition.position

                    currentDroppable = rememberPosition.exTarget

                options.fail?()

            @.toString = () ->
                element.id

        dropTarget: (element, options) ->
            defaults =
                name : options.name

                canAccept: null
                drop: null

                enter: null
                move: null
                leave: null

            options = if options then $.extend defaults, options else defaults

            element.dropTarget = @

            @.canAccept = (dragObject, e) ->
                return if options.canAccept? then options.canAccept(dragObject, e) else true

            @.accept = (dragObject, e) ->
                #dragObject.hide()

                options.drop? dragObject, e
                @onLeave()

            @.onMove = (elem, e) ->
                options.move? elem, e

            @.onEnter = (elem, e) ->
                dropHelper.flush()
                options.enter? elem, e

            @.onLeave = (elem) ->
                dropHelper.flush()
                options.leave? elem

            @.onPick = (elem) ->
                # Picking element from droppable
                options.pick? elem

            @.toString = () ->
                element.id

            @.onEnd = () ->
                options.end?()
