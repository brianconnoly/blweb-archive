buzzlike
    .directive 'columnView', ($compile, resize) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            columnWidth = 174
            width = Math.floor( ( $('.screen.catalog').width() ) / columnWidth )

            elem = $ element
            sorted_list = []

            objects = {}

            updateList = ->
                sorted_list = []

                for own id of scope.subset.items
                    sorted_list.push scope.subset.items[id]

                sorted_list.sort byLastUpdate

                buildField()

            scope.$watch 'subset.items', updateList, true

            buildField = () ->
                sorted_len = sorted_list.length
                if sorted_list.length == 0
                    return

                lines = Math.floor(sorted_len/width)
                if lines < sorted_len/width then lines++
                if lines > 3 then lines = 3

                elem.css
                    'height': 66 + ( columnWidth * lines )

                elem.children('.absoluteContent').addClass('toDelete')

                for i in [0...width]
                    start = i*lines
                    items = sorted_list?.slice start, start + lines
                    if items.length == 0
                        continue

                    for item in items
                        id = item.id
                        obj = objects[id]

                        if !obj?
                            newscope = scope.$new()
                            #newscope.id = id
                            #newscope.type = attrs.itemType
                            newscope.item = item
                            template = '<li class="contextMenu selectableItem absoluteContent item editableItem droppableItem ios-nodelay tutorialCourseTagForce tl_contentitem" type="' + attrs.itemType + '">
                                            <div item="item" class="itemPreview ios-dblclick" ng-dblclick="itemClick(item, $event)" overlay="' + attrs.itemType + 'Page"></div>
                                        </li>'
                            el = $compile(template)(newscope)

                            obj =
                                elem: $ el
                            objects[item.id] = obj

                            element.append obj.elem
                            obj.elem.data 'id', item.id

                        obj.elem.removeClass 'toDelete'
                        obj.elem.css
                            'top': 40 + 12 + _j*174
                            'left': i*174

                elem.children('.toDelete').each () ->
                    delete objects[$(this).data('id')]
                    $(this).remove()

            resizeTimer = 0
            resizeFn = ->
                resizeTimer = 0
                width = Math.floor( ( $('.screen.catalog').width() ) / columnWidth )
                #new_width = Math.floor( ( $('.screen.catalog').width() ) / columnWidth )
                #screen_width = $('body').width()

                #if new_width != width
                #    width = new_width
                updateList()

            resize.registerCb ->
                clearTimeout resizeTimer if resizeTimer
                resizeTimer = setTimeout resizeFn, 400

            buildField()
            true


    .directive 'contentDeepView', ($compile, contentService, combService, multiselect, user, resize) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            # New brains
            elem = $ element
            area = $('.screen.deepview')

            scrolled = 0
            sections = []

            blockWidth = 174
            columnWidth = 174
            height = Math.floor( ( area.height() ) / blockWidth )
            width = Math.floor( ( area.width() ) / blockWidth )

            scope.leftArrowVisible = scope.rightArrowVisible = false

            rightLimit = area.width()
            # End New brains

            loaded = false
            fetchNumber = 300

            screen_width = $('.viewport3d').width()

            # Smart endlessness
            sorted_list = []

            objects = {}
            current = 0

            updateList = ->
                sorted_list = []

                for own id of scope.selectedCat?.items
                    sorted_list.push scope.selectedCat?.items[id]

                sorted_list.sort byLastUpdate
                scrollBy 0

            scope.$watch 'selectedCat', (prev, now) ->
                if !scope.selectedCat?
                    return false

                clear()
                #if prev.type == now?.type
                #    scr = scrolled
                #    scrolled = 0
                #    scrollBy scr
                updateList()
            , true

            clear = () ->
                elem.html ""

                for section in sections
                    for obj_id in section.list
                        if objects[obj_id]?
                            objects[obj_id].scope.$destroy()
                            objects[obj_id].elem.remove()

                    section.elem.remove()

                sections.length = 0

            addSection = (from, left, before) ->
                items = sorted_list?.slice from, from + height

                if items.length == 0
                    return false

                new_elem = $ "<ul class='section'></ul>"
                setLeft new_elem, left

                list = []

                for item in items
                    id = item.id
                    list.push id
                    obj = null #objects[id]
                    if !obj?
                        newscope = scope.$new()
                        newscope.item = item
                        template = '<li class="contextMenu absoluteContent item selectableItem editableItem droppableItem ios-nodelay tutorialCourseTagForce tl_contentitem" type="' + attrs.itemType + '">
                                        <div item="item" class="itemPreview" ng-dblclick="itemClick(item, $event)"></div>
                                    </li>'
                        el = $compile(template)(newscope)

                        obj =
                            scope: newscope
                            elem: $ el
                        objects[item.id] = obj

                    if multiselect.isFocused obj.scope.item
                        obj.elem.addClass('selected')
                    else
                        obj.elem.removeClass('selected')

                    obj.elem.appendTo new_elem

                new_section =
                    elem: new_elem
                    from: from
                    left: left
                    list: list

                if before
                    sections.unshift new_section
                    elem.prepend new_elem
                else
                    sections.push new_section
                    elem.append new_elem

                new_section

            getLeft = (elem) ->
                Math.floor $(elem).css("transform").split(",")[4]

            setLeft = (elem, val) ->
                $(elem).css
                    "transform": "translateX("+val+"px)"
                    "-webkit-transform": "translateX("+val+"px)"
                    "-moz-transform": "translateX("+val+"px)"

            loading = 0
            scrollBy = (value) ->
                maxRight = 0
                minLeft = screen_width * 1.2
                maxFrom = 0
                minFrom = getBigTimestamp()

                minDeltaCenter = 999999999

                if sections.length < width - 1
                    value = 0

                if sections[sections.length-1]?.left - Math.floor(value) < rightLimit - blockWidth - blockWidth - 10 and value > 0 #and sections.length > width
                    value = blockWidth + blockWidth + 10 + sections[sections.length-1]?.left - rightLimit

                if sections[0]?.left - Math.floor(value) > 10 # and value < 0
                    value = sections[0]?.left - 10

                if scrolled < 0 and value < 0 then scrolled = value = 0

                scrolled += value
                #blog scrolled, value, sections[sections.length-1], Object.keys(scope.selectedCat.items).length, screen_width

                allItems = if scope.selectedCat? then Object.keys(scope.selectedCat.items).length else 0
                lastSection = sections[sections.length-1]

                if scrolled > 0
                    scope.leftArrowVisible = true
                else
                    scope.leftArrowVisible = false

                if allItems - height < lastSection?.from and lastSection?.left < screen_width
                    scope.rightArrowVisible = false
                else
                    scope.rightArrowVisible = true



                toRemove = []
                #console.clear()
                for section in sections
                    section.left -= Math.floor value

                    # Check if remove
                    if section.left + blockWidth > screen_width * 2 or section.left < - screen_width
                        toRemove.push section
                        continue

                    setLeft section.elem, section.left

                    right = section.left + blockWidth
                    if right > maxRight
                        maxRight = right
                        maxFrom = section.from + height

                    if section.left < minLeft
                        minLeft = section.left
                        minFrom = section.from

                    if Math.abs( section.left ) < minDeltaCenter
                        minDeltaCenter = Math.abs( section.left )
                        current = section.from

                # Removing
                for section in toRemove
                    if sections.length > 1
                        for obj_id in section.list
                            if objects[obj_id]?
                                objects[obj_id].scope.$destroy()
                                objects[obj_id].elem.remove()

                        section.elem.remove()
                        index = sections.indexOf section
                        sections.splice index, 1

                if maxFrom == 0
                    maxFrom = current
                    maxRight = 0

                if minFrom == getBigTimestamp()
                    minFrom = current
                    minLeft = 0

                # Adding right
                new_section = true
                while maxRight < rightLimit and new_section
                    new_section = addSection maxFrom, maxRight
                    maxRight += blockWidth
                    maxFrom += height

                if !new_section and scope.selectedCat? and !loading
                    loading = setTimeout ->
                        loading = 0
                    , 1000
                    if attrs.itemType == 'comb'
                        combService.fetchCombsPageForCommunity scope.selectedCat.id, fetchNumber #height * width * 2
                    else
                        contentService.fetchContentPageForType scope.selectedCat.type, fetchNumber #height * width * 2


                # Adding left
                new_section = true
                if minLeft then while minLeft > 0 and new_section
                    minFrom -= height
                    minLeft -= blockWidth
                    new_section = addSection minFrom, minLeft, true

                if !new_section
                    left_stop = 0
                    for section in sections
                        section.left = left_stop
                        setLeft section.elem, left_stop
                        left_stop += blockWidth

            anim = {}

            animDefault = ->
                updateObject anim,
                    inProgress: false
                    #downTimeout: null
                    #upTimeout: null
                    interval: null
                    startTime: null
                    checkTime: null
                    speed: 100 #px per sec
                    maxSpeed: 2200 #px per sec
                    acceleration: 2500 #speed per sec
                    minDuration: 350
                    currentDirection: 0 #-1 - left, 1 - right
            animDefault()

            scopeUpdatingInterval = null

            scope.setAction = (e, direction) ->
                if e.which != 1 then return false
                if anim.inProgress then return false
                anim.inProgress = true
                anim.currentDirection = direction


                if anim.downTimeout
                    #blog "dbl"
                    clearTimeout anim.downTimeout
                    clearTimeout anim.upTimeout
                    anim.downTimeout = anim.upTimeout = 0
                    if direction == -1 then toStart() else toEnd()
                    return false

                anim.startTime = Date.now()
                anim.downTimeout = setTimeout ->
                    anim.downTimeout = 0
                    move direction
                    #blog "move start"
                , 200 #400

            move = (direction) ->
                #-1 - left, 1 - right
                anim.checkTime = Date.now()
                anim.speed = 100

                render =  ->
                    if anim.inProgress
                        dt = Date.now() - anim.checkTime

                        anim.checkTime += dt

                        if anim.speed < anim.maxSpeed
                            ds = anim.acceleration * dt / 1000
                            anim.speed += ds
                        #if anim.speed > anim.maxSpeed then anim.speed = anim.maxSpeed
                        if anim.speed > anim.maxSpeed then anim.acceleration = 500

                        dx = direction * anim.speed * dt / 1000
                        scrollBy dx
                        scope.$apply() # <- Если что-то тормозит, винить этого чувака

                        requestAnimFrame render

                render()

                false

            scope.stopMove = () ->
                anim.inProgress = false
                dt = Date.now() - anim.startTime

                if dt < anim.minDuration
                    dt = anim.minDuration - dt
                    dx = width * blockWidth * anim.currentDirection
                    if anim.downTimeout then anim.upTimeout = setTimeout ->
                        anim.downTimeout = anim.downTimeout = 0
                        easeMove dx, 500
                        #blog "up"
                    , 200 #300

                else
                    dt = 0
                setTimeout ->
                    #clearInterval anim.interval
                    clearInterval scopeUpdatingInterval

                    animDefault()
                , dt

            easeMove = (val, duration) ->
                #quadratic in-out ease v(t)
                startTime = Date.now()
                x0 = 0
                anim.inProgress = true
                render = () ->
                    dt = Date.now()-startTime
                    if dt>duration then dt = duration

                    x = Math.easeInOutQuad dt, 0, val, duration
                    dx = x - x0
                    x0 = x

                    scrollBy dx
                    #blog dt, dx, x, val

                    if dt>=duration
                        anim.inProgress = false
                        return false

                    requestAnimFrame render

                render()

            rememberScroll = 0 # когда скроллим в начало даблкликом, здесь запоминаем, откуда скроллили
            toStart = ->
                rememberScroll = scrolled
                easeMove -scrolled, 400

            toEnd = ->
                if rememberScroll
                    easeMove rememberScroll, 400
                    rememberScroll = 0




            scope.uploadContent = (e) ->
                target = $ e.target
                if target.hasClass('left-arrow') or target.hasClass('right-arrow')
                    return false
                $('.uploadHelper input').click()


            resizeTimer = 0
            resizeFn = ->
                resizeTimer = 0
                new_height = Math.floor ( ( $('.screen.deepview').height() ) / columnWidth )
                new_width = Math.floor( ( $('.screen.deepview').width() ) / columnWidth )
                screen_width = $('body').width()

                if new_height != height || new_width != width
                    height = new_height
                    width = new_width
                    clear()
                    updateList()
                    scrolled = 0

                scope.$apply()

            resize.registerCb () ->
                clearTimeout resizeTimer if resizeTimer
                resizeTimer = setTimeout resizeFn, 400

            elem.on 'mousewheel', (e, d, dx, dy) ->
                e.preventDefault()
                e.stopPropagation()
                #blog "MOUSEW", d, dx, dy
                scrollBy -d / 2  #come on, i'll show you some magic
                scope.$apply()
                false
            true


byLastUpdate = (a, b) ->
    if a.lastUpdated < b.lastUpdated
        return 1
    if a.lastUpdated > b.lastUpdated
        return -1

    if a.id < b.id
        return 1
    if a.id > b.id
        return -1
    return 0
