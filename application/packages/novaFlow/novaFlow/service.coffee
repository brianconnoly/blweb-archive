*deps: $compile, stateManager, novaStateTree

_minFrameWid = 320

class novaFlow

    applyStateTree: (stateTree) ->
        @currentStateTree = stateTree
        stateManager.setTree @currentStateTree

    constructor: (@element, @scope) ->
        @currentStateTree = null
        @flowBoxesContainer = @element.children '.flowBoxes'
        @flowTabsContainer = @element.children '.frameTabs'
        @flowBoxes = []

        @scope.stateSaver.register 'flow',
            save: =>
                toSave = []
                for flowBox in @flowBoxes
                    box =
                        active: flowBox.active
                        frames: []
                        pinned: flowBox.pinned
                    for frame in flowBox.flowFrames
                        box.frames.push
                            active: frame.active
                            data: frame.data
                            params: frame.params
                            pinned: frame.pinned
                    toSave.push box
                toSave
            load: (data) =>
                for box in data by -1
                    flowBox = @addFlowBox
                        active: box.active
                    , true
                    flowBox.pinned = box.pinned
                    flowBox.active = box.active
                    lastFrame = null
                    for frame in box.frames
                        lastFrame = flowBox.addFlowFrame frame.params, lastFrame
                        lastFrame.pinned = frame.pinned
                        lastFrame.active = frame.active
                @recountFrames true

    # State saving
    saveState: ->
        @scope.stateSaver.save 'flow'

    activate: (frame, box) ->
        for flowBox in @flowBoxes
            flowBox.deactivate() if flowBox != box
        box.activate frame
        @currentCode = box.code
        @saveState()

    closeFlowBox: (box) ->
        box.destroy()
        removeElementFromArray box, @flowBoxes
        @currentCode = null
        @saveState()
        @recountFrames true

    addFlowBox: (params, start = false) ->
        if start
            box = new novaFlowBox @, params
            @flowBoxes.unshift box
        else
            lastId = 0
            if params?.pinned
                if !params.position?
                    params.position = @flowBoxes.length - 1
                    for flowBox,i in @flowBoxes
                        if flowBox.pinned == true
                            params.position = i-1
                            break
                box = new novaFlowBox @, params
                @flowBoxes.splice params.position+1, 0, box
            else
                box = new novaFlowBox @, params
                @flowBoxes.push box
        @saveState()
        box

    addFrame: (frame, after, noFlush = false) ->
        if frame.code?
            for flowBox in @flowBoxes
                if flowBox.code == frame.code
                    @activate flowBox.flowFrames[0], flowBox
                    return

        if @flowBoxes.length < 1
            @addFlowBox
                code: frame.code
        if @flowBoxes[0].pinned or noFlush
            @addFlowBox
                code: frame.code
            , true
        frame = @flowBoxes[0].addFlowFrame frame
        # @activate frame, @flowBoxes[0]
        @saveState()
        @recountFrames()

    addFrameBoxes: (frames, after) ->
        if @flowBoxes.length < 1
            @addFlowBox()
        toRemove = []
        for box in @flowBoxes
            if !box.pinned
                toRemove.push box

        for box in toRemove
            box.destroy()
            removeElementFromArray box, @flowBoxes

        for frame in frames
            @addFlowBox {}, true
            @flowBoxes[0].addFlowFrame frame
        @saveState()
        @recountFrames()

    recountFrames: (final = false) ->
        @width = areaWid = @element.width()
        flowBoxes = @flowBoxes.length

        spaceRemain = areaWid

        data =
            totalWeight: 0
            minBefore: 0
            minAfter: 0
            maxBefore: 0
            maxAfter: 0
            active: null
            beforeCnt: {}
            afterCnt: {}

        foundActive = false
        activeId = null
        for flowBox,i in @flowBoxes
            data.totalWeight += flowBox.flowFrames.length

            for cnt in [0...@flowBoxes.length]
                if cnt <= i
                    if !data.afterCnt[cnt]?
                        data.afterCnt[cnt] = 0
                    data.afterCnt[cnt] += flowBox.flowFrames.length
                if cnt >= i
                    if !data.beforeCnt[cnt]?
                        data.beforeCnt[cnt] = 0
                    data.beforeCnt[cnt] += flowBox.flowFrames.length

            if flowBox.active == true
                foundActive = true
                activeId = i
                data.active = flowBox

            if foundActive or (!foundActive and i == @flowBoxes.length-1)
                data.minAfter += _minFrameWid #* flowBox.flowFrames.length
                data.maxAfter += flowBox.maxWidth if data.maxAfter != -1
                if !(flowBox.maxWidth > 0) then data.maxAfter = -1
            else
                data.minBefore += _minFrameWid #* flowBox.flowFrames.length
                data.maxBefore += flowBox.maxWidth if data.maxBefore != -1
                if !(flowBox.maxWidth > 0) then data.maxBefore = -1

        if !data.active
            activeId = @flowBoxes.length-1
            data.active = @flowBoxes[activeId]

        flowBoxWid = areaWid / @flowBoxes.length # data.totalWeight | 0
        flowBoxWid = Math.floor flowBoxWid
        realFlowBoxWidth = flowBoxWid
        if flowBoxWid < _minFrameWid
            flowBoxWid = _minFrameWid

        tabWid = (areaWid - 70) / @flowBoxes.length

        # Put active on left edge
        remain = areaWid #@width #- 321
        left = 0
        tabLast = 0
        # Start from active till the end
        if data.minAfter > remain
            for flowBox,i in @flowBoxes
                if i >= activeId
                    # If last
                    if i == @flowBoxes.length - 1
                        flowBoxWid = areaWid - (flowBoxWid * (@flowBoxes.length - 1))
                        if flowBoxWid < _minFrameWid
                            flowBoxWid = _minFrameWid
                    wid = flowBox.setWidth flowBoxWid
                    remain -= wid
                    flowBox.setLeft left
                    left += wid
                else
                    flowBox.hide()
                flowBox.recountFrames false, tabLast, tabWid
                tabLast += tabWid
        else
            # From start to active and till the end
            if data.minBefore + data.minAfter > remain
                left = remain
                tabLast = areaWid - 70 - tabWid
                for flowBox,i in @flowBoxes by -1
                    if remain > 0
                        # If last
                        if i == 0
                            flowBoxWid = areaWid - (flowBoxWid * (@flowBoxes.length - 1))
                            if flowBoxWid < _minFrameWid
                                flowBoxWid = _minFrameWid
                        wid = flowBox.setWidth flowBoxWid
                        remain -= wid
                        left -= wid
                        if left < 0
                            left = 0
                        flowBox.setRight left

                    else
                        flowBox.hide()
                    flowBox.recountFrames false, tabLast, tabWid
                    tabLast -= tabWid
            else
                for flowBox,i in @flowBoxes
                    # If last
                    if i == @flowBoxes.length - 1
                        flowBoxWid = areaWid - left #(flowBoxWid * (@flowBoxes.length - 1))
                        if flowBoxWid < _minFrameWid
                            flowBoxWid = _minFrameWid

                    setWid = flowBoxWid #realFlowBoxWidth * flowBox.flowFrames.length
                    # if i == @flowBoxes.length - 2
                    #     setWid = remain - flowBoxWid

                    wid = flowBox.setWidth setWid
                    if wid < areaWid - left and i == @flowBoxes.length - 1
                        flowBox._last = true
                        flowBox.element.addClass 'last'
                    else if flowBox._last
                        flowBox._last = false
                        flowBox.element.removeClass 'last'
                    remain -= wid
                    flowBox.setLeft left
                    left += wid

                    flowBox.recountFrames false, tabLast, tabWid
                    tabLast += tabWid

        tabLeft = 0
        tabWid = Math.floor tabWid
        for flowBox,i in @flowBoxes
            if flowBox.flowFrames.length == 1
                flowFrame = flowBox.flowFrames[0]
                wid = 180
                if wid > tabWid
                    wid = tabWid
                if tabLeft < flowBox.left + flowFrame.left
                    tabLeft = flowBox.left + flowFrame.left
                if tabLeft + wid > tabWid * (i + 1)
                    tabLeft = tabWid * (i + 1) - wid
                tabLeft = 0 if tabLeft < 0
                flowFrame.setTabParams tabLeft, wid
                tabLeft += wid
            else
                bigWid = 180
                backWid = 180
                ntWid = tabWid
                if tabLeft < flowBox.left and tabWid - flowBox.left + (tabWid*i) > bigWid + 20
                    tabLeft = flowBox.left
                    ntWid = tabWid - flowBox.left + tabLeft
                if bigWid > ntWid - 20
                    bigWid = ntWid - 20
                if bigWid * flowBox.flowFrames.length > ntWid
                    backWid = (ntWid - bigWid) / (flowBox.flowFrames.length - 1)
                foundActive = false
                for flowFrame,j in flowBox.flowFrames
                    wid = backWid
                    if flowFrame.active == true
                        wid = bigWid
                        foundActive = true
                    zIndex = null
                    if foundActive
                        zIndex = flowBox.flowFrames.length - j
                    if bigWid == backWid and tabLeft < flowBox.left + flowFrame.left
                        tabLeft = flowBox.left + flowFrame.left
                    if tabLeft + wid > ntWid * (i + 1)
                        tabLeft = ntWid * (i + 1) - wid
                    tabLeft = 0 if tabLeft < 0
                    flowFrame.setTabParams tabLeft, wid, zIndex
                    tabLeft += wid
                    # Cut 20px if there are more semiHidden after active
                    if bigWid != backWid and flowFrame.active == true and j != flowBox.flowFrames.length - 1
                        tabLeft -= 20

        if final
            @recountFramesFinal()

    recountFramesFinal: ->
        for flowBox in @flowBoxes
            flowBox.recountFramesFinal()

class novaFlowBox

    constructor: (@flow, params) ->
        # Assign params
        for k,v of params
            @[k] = v

        @width = _minFrameWid
        @flowFrames = []

        @element = $ '<div>',
            class: 'novaFlowBox'

        if params?.pinned == true
            $(@flow.flowBoxesContainer.children()[params.position]).after @element
        else
            @flow.flowBoxesContainer.prepend @element
        @scope = @flow.scope.$new()
        @scope.flowBox = @
        $compile(@element)(@scope)

    activate: (frame) ->
        @active = true
        for flowFrame in @flowFrames
            if frame != flowFrame
                flowFrame.deactivate()
            else
                flowFrame.activate()
        @flow.recountFrames true
        @flow.saveState()

    deactivate: ->
        @active = false
        # for frame in @flowFrames
        #     frame.deactivate()

    pin: (frame) ->
        frame.pinned = true

        # @recountFrames true

        index = @flowFrames.indexOf frame
        if index == 0
            @pinned = true
        # if index > 0
        else
            boxIndex = @flow.flowBoxes.indexOf @
            newBox = @flow.addFlowBox
                pinned: true
                position: boxIndex
            for i in [index...@flowFrames.length]
                flowFrame = @flowFrames[i]
                # removeElementFromArray flowFrame, @flowFrames
                newBox.putFlowFrame flowFrame
            @flowFrames.length = index

        if @flowFrames.length == 0
            @flow.closeFlowBox @

        @flow.recountFrames true
        @flow.saveState()

    recountMaxWid: ->
        @maxWidth = 0
        for frame in @flowFrames
            if frame.maxWidth?
                @maxWidth += frame.maxWidth
            else
                @maxWidth = 0
                break

    setLeft: (@left) ->
        @element
        .css 'transform', "translate3d(#{@left}px, 0,0)"
        .removeClass 'back'
        if @right
            @element.removeClass 'right'
            .css 'right', 'auto'
            @right = false

    setRight: (@left) ->
        if @right != true
            @right = true
            @element.addClass 'right'


        @element
        # .css 'right', @rightCoord
        .css 'transform', "translate3d(#{@left}px, 0,0)"
        .removeClass 'back'

    hide: () ->
        @element.addClass 'back'

    setWidth: (@width) ->
        @recountMaxWid()
        if @maxWidth > 0 and @width > @maxWidth
            @width = @maxWidth
        @element.css 'width', @width
        @width

    destroy: () ->
        for frame in @flowFrames
            frame.destroy()
        @flowFrames.length = 0

        @scope.$destroy()
        @element.remove()

    closeFlowFrame: (frame) ->
        # frame.destroy()
        index = @flowFrames.indexOf frame
        console.log index, @flowFrames, frame
        for i in [index...@flowFrames.length]
            console.log i, @flowFrames[i]
            @flowFrames[i].destroy()
        @flowFrames.length = index
        # removeElementFromArray frame, @flowFrames

        if @flowFrames.length == 0
            @flow.closeFlowBox @
        else
            if frame.active == true
                if index > 0
                    @activate @flowFrames[index-1]

        @recountMaxWid()
        @flow.recountFrames true
        @flow.saveState()

    putFlowFrame: (frame) ->
        @flowFrames.push frame
        @recountMaxWid()
        frame.flowBox = @
        frame.scope.flowBox = @
        frame.element.appendTo @element
        @flow.saveState()
        frame

    addFlowFrame: (frame, afterFrame) ->
        newFrame = new novaFlowFrame @, frame
        if afterFrame?
            id = @flowFrames.indexOf afterFrame
            if id+1 < @flowFrames.length
                for i in [id+1...@flowFrames.length]
                    @flowFrames[i].destroy()
                @flowFrames.length = id + 1
        else
            toDelete = []
            for _frame in @flowFrames
                if _frame.pinned != true
                    _frame.destroy()
                    toDelete.push _frame
            removeElementFromArray _frame, @flowFrames for _frame in toDelete
            @code = newFrame.code or null
        @flowFrames.push newFrame
        @recountMaxWid()
        # @flow.recountFrames true
        @flow.activate newFrame, @
        @flow.saveState()
        newFrame

    recountFrames: (final = false, tabLast, tabWid) ->
        frames = @flowFrames.length

        flowFrameWid = @width / frames | 0
        flowFrameWid = Math.floor flowFrameWid
        if flowFrameWid < _minFrameWid
            flowFrameWid = _minFrameWid
        spaceRemain = @width

        # Analyse
        data =
            minBefore: 0
            maxBefore: 0
            minAfter: 0
            maxAfter: 0
            active: null

        foundActive = false
        activeId = 0
        for flowFrame,i in @flowFrames
            if flowFrame.active == true
                foundActive = true
                activeId = i
                data.active = flowFrame

            if foundActive or (!foundActive and i == @flowFrames.length-1)
                data.minAfter += _minFrameWid
                data.maxAfter += flowFrame.maxWidth if data.maxAfter != -1
                if !(flowFrame.maxWidth > 0) then data.maxAfter = -1
            else
                data.minBefore += _minFrameWid
                data.maxBefore += flowFrame.maxWidth if data.maxBefore != -1
                if !(flowFrame.maxWidth > 0) then data.maxBefore = -1

        if !data.active
            activeId = @flowFrames.length-1
            data.active = @flowFrames[activeId]

        # Put active on left edge
        tabsHeadersWidth = 0

        remain = @width #- 321
        left = 0
        boxLeft = @left | 0
        if @right
            boxLeft = @flow.width - @width - @rightCoord

        if !data.active.maxWidth? or data.active.maxWidth >= @width
            for flowFrame in @flowFrames
                if flowFrame.active
                    flowFrame.setWidth @width
                    flowFrame.setLeft 0
                else
                    flowFrame.hide()
        else

            if data.minAfter > remain
                for flowFrame,i in @flowFrames
                    if i >= activeId
                        if i == @flowFrames.length - 1
                            flowFrameWid = @width - (flowFrameWid * (@flowFrames.length - 1))
                            flowFrameWid = _minFrameWid if flowFrameWid < _minFrameWid
                        wid = flowFrame.setWidth flowFrameWid
                        remain -= wid
                        flowFrame.setLeft left
                        left += wid
                    else
                        flowFrame.hide()

            else
                # From start to active and till the end
                if data.minBefore + data.minAfter > remain
                    left = remain
                    for flowFrame,i in @flowFrames by -1
                        if remain > 0
                            if i == 0
                                flowFrameWid = @width - (flowFrameWid * (@flowFrames.length - 1))
                                flowFrameWid = _minFrameWid if flowFrameWid < _minFrameWid
                            wid = flowFrame.setWidth flowFrameWid
                            remain -= wid
                            left -= wid
                            if left < 0
                                left = 0
                            if left > 0
                                flowFrame.setRight left
                            else
                                flowFrame.setLeft left

                        else
                            flowFrame.hide()

                else
                    tabRight = tabWid + tabLast
                    for flowFrame,i in @flowFrames
                        if i == @flowFrames.length - 1
                            flowFrameWid = @width - (flowFrameWid * (@flowFrames.length - 1))
                            flowFrameWid = _minFrameWid if flowFrameWid < _minFrameWid
                        setWid = flowFrameWid #realFlowBoxWidth * flowFrame.flowFrames.length
                        if i == @flowFrames.length - 2
                            setWid = remain - flowFrameWid

                        wid = flowFrame.setWidth setWid
                        remain -= wid
                        flowFrame.setLeft left

                        left += wid

        # if data.minAfter > remain
        #     for flowFrame,i in @flowFrames
        #         if i <= activeId
        #             wid = flowFrame.setWidth flowFrameWid
        #             remain -= wid
        #             flowFrame.setLeft left
        #             if boxLeft + left > tabLast
        #                 tabLast = boxLeft + left
        #             flowFrame.setTabParams tabLast, 80
        #             console.log 'Set tab', tabLast
        #             tabLast += 180
        #             tabsHeadersWidth += 180
        #             left += wid
        #         else
        #             remain -= _minFrameWid
        #             flowFrame.setLeft left
        #             if boxLeft + left > tabLast
        #                 tabLast = boxLeft + left
        #             flowFrame.setTabParams tabLast, 80
        #             console.log 'Set tab', tabLast
        #             tabLast += 180
        #             tabsHeadersWidth += 180
        #             left += _minFrameWid
        # else
        #     # Fit all from left
        #     if data.maxAfter >= 0 and data.maxBefore >= 0 and data.minAfter + data.minBefore <= @width
        #         left = 0
        #         for flowFrame in @flowFrames
        #             flowFrame.setLeft left
        #             if boxLeft + left > tabLast
        #                 tabLast = boxLeft + left
        #             flowFrame.setTabParams tabLast, 80
        #             console.log 'Set tab', tabLast
        #             tabLast += 180
        #             tabsHeadersWidth += 180
        #             left += flowFrame.setWidth flowFrameWid
        #     else
        #         right = 0
        #         for flowFrame,i in @flowFrames by -1
        #             if remain >= _minFrameWid #if i >= activeId
        #                 wid = flowFrame.setWidth flowFrameWid
        #                 remain -= wid
        #                 flowFrame.setRight right # remain
        #                 right += wid
        #                 if boxLeft + @width - right > tabLast
        #                     tabLast = boxLeft + @width - right
        #                 flowFrame.setTabParams tabLast, 80
        #                 console.log 'Set tab', tabLast
        #                 tabLast += 180
        #                 tabsHeadersWidth += 180
        #             else
        #                 flowFrame.setLeft 0
        #                 if boxLeft > tabLast
        #                     tabLast = boxLeft + @width - right
        #                 flowFrame.setTabParams tabLast, 80
        #                 console.log 'Set tab', tabLast
        #                 tabLast += 180
        #                 tabsHeadersWidth += 180
                        # flowFrame.setTabParams boxLeft, 80


        # for flowFrame,i in @flowFrames
        #     if i == @flowFrames.length-1
        #         factWid = flowFrame.setWidth spaceRemain
        #     else
        #         factWid = flowFrame.setWidth flowFrameWid
        #     spaceRemain -= factWid

        if final
            @recountFramesFinal()

        tabsHeadersWidth

    recountFramesFinal: ->
        for flowFrame in @flowFrames
            flowFrame.scope.handleResizeEnd?()

class novaFlowFrame

    constructor: (@flowBox, @params) ->
        # @maxWidth = 0
        # Assign params
        for k,v of @params
            @[k] = v

        # Create element
        @element = $ '<div>',
            class: 'novaFlowFrame noDrag ' + @directive

        @flowBox.element.append @element
        @scope = @flowBox.flow.scope.$new()
        @scope.flowFrame = @
        @scope.flowBox = @flowBox
        @scope.stateTree = new novaStateTree()
        @flowBox.flow.applyStateTree @scope.stateTree
        @element = $ $compile(@element)(@scope)

        @element.on 'mousedown', =>
            @flowBox.flow.activate @, @flowBox

        # Create tab
        @tabElement = $ '<div>',
            class: 'novaFlowFrameTab'

        @flowBox.flow.flowTabsContainer.append @tabElement
        @tabElement = $ $compile(@tabElement)(@scope)

        @tabElement.on 'mousedown', =>
            @flowBox.flow.activate @, @flowBox

    activate: ->
        @active = true
        @element.addClass 'active'
        @flowBox.flow.applyStateTree @scope.stateTree
        @scope?.onActivate?()

    deactivate: ->
        @active = false
        @element.removeClass 'active'

    setWidth: (@width) ->
        if @width > @maxWidth
            @width = @maxWidth
        @element.css 'width', @width
        @scope.handleResize?()
        @width

    setTabParams: (@tabLeft, @tabWid, @zIndex = 'auto') ->
        @tabElement.css
            'transform': "translate3d(#{@tabLeft}px, 0,0)"
            'width': @tabWid + 'px'
            'z-index': @zIndex

        if @tabWid < 130
            @tabElement.addClass 'noActions'
        else
            @tabElement.removeClass 'noActions'

    setLeft: (@left) ->
        @element.css 'transform', "translate3d(#{@left}px, 0,0)"
        if @back == true
            @back = false
            @element.removeClass 'back'

        if @right == true
            @right = false
            @element.removeClass 'right'


    hide: () ->
        @back = true
        @element.addClass 'back'

    putBackRight: (right = 0) ->
        @back = true
        @element.addClass 'back'
        @setRight right

    setRight: (@left) ->
        if @right != true
            @right = true
            @element.addClass 'right'
        if @back == true
            @back = false
            @element.removeClass 'back'

        @element.css
            'transform': "translate3d(#{@left}px, 0,0)"

    destroy: ->
        @scope.$destroy()
        @element.remove()
        @tabElement.remove()

novaFlow
