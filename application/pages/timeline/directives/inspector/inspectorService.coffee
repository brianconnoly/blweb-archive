buzzlike.service 'inspectorService', (desktopService, groupService, $rootScope, multiselect, stateManager, ruleService, $filter) ->
    status =
        showInspector: false

        currentRule: null
        currentPlaceholder: null
        intervals: []
        
        multiEdit: false
        multiType: null
        multiAd: false
        multiDayMask: null
        multiEnd: false
        multiEndDay: [true,true,true,true,true,true,true]

        selected: false
        selectedType: null
        inspectorClicked: null
        selectedPlaceholders: []

    handlers = $()
    startHandler = $ '<div class="time-picker left" ></div>'
    endHandler   = $ '<div class="time-picker right"></div>'
    handlers = $.merge(handlers, startHandler)
    handlers = $.merge(handlers, endHandler)

    selected = []

    inspectorSession = null

    inspectorState =
        'escape': ->
            closeInspector()

    highlightRule = (ruleId) ->
        $('.rule_' + ruleId).addClass('placeholder_highlighted')

    initInspector = (item, e) ->
        # status.showInspector = true
        if !inspectorSession?.scope? 
            inspectorSession = desktopService.launchApp 'ruleInspector', null, e, true

        status.currentPlaceholder = item
        status.currentRule = item.rule
        stateManager.applyState inspectorState

        # Clear highlight
        $('.placeholder_highlighted').removeClass('placeholder_highlighted')

        focused = multiselect.getFocused()

        # Выбрали определенное правило, нажали иконку в углу
        # при пустом мультиселекте
        if focused.length == 0 or !multiselect.isFocused(item)
            # Очищаем селект если были выбраны сторонние ячейки
            multiselect.flush()

            # Устанавливаем состояние сервиса
            status.multiEdit = false

            # Подсвечиваем все ячейки выбранного правила
            highlightRule item.rule.id
            return

        else if focused.length == 1 and multiselect.isFocused(item)
            # Очищаем селект если были выбраны сторонние ячейки
            multiselect.flush()

            # Устанавливаем состояние сервиса
            status.multiEdit = false

            # Подсвечиваем все ячейки выбранного правила
            highlightRule item.rule.id
        else
            updateInspector()

    setMultiType = (type) ->
        status.multiType = type
        newRules = []

        # Получаем максимальную конечную дату
        start = 0
        maxTimestampEnd = 0
        for placeholder in status.selectedPlaceholders
            start = placeholder.timestamp
            if placeholder.rule.timestampEnd > maxTimestampEnd
                maxTimestampEnd = placeholder.rule.timestampEnd

        if type == 'daily'
            maxTimestampEnd = start + ( 7 * DAY )

        multiselect.flush()

        ruleService.removePlaceholders status.selectedPlaceholders

        processed = []

        for placeholder in status.selectedPlaceholders
            code = placeholder.rule.id + '_' + placeholder.id + '_' + placeholder.rule.groupId
            if code in processed
                continue
            processed.push code

            item =
                type: 'rule'
                ruleType: type
                groupId: placeholder.rule.groupId
                timestampStart: placeholder.timestamp
                timestampEnd: maxTimestampEnd
                ad: status.multieditAd || false
                interval: 30
                dayMask: status.multiDayMask || [true,true,true,true,true,true,true]
                communityId: placeholder.rule.communityId
                end: if maxTimestampEnd == 0 then false else true

            #newRules.push item
            ruleService.create item, (createdItem) ->
                group = groupService.getById placeholder.rule.groupId

                for feed in group.feeds
                    placeholder = ruleService.getPlaceholder 0, createdItem.id, feed.communityId
                    multiselect.addToFocus placeholder if placeholder?

    closeInspector = () ->
        # Clear highlight
        $('.placeholder_highlighted').removeClass('placeholder_highlighted')
        stateManager.goBack()
        inspectorSession.scope.closeApp()
        inspectorSession = null
        reset()

    updateInspector = () ->
        if !inspectorSession?.scope?
            return false

        focused = multiselect.getFocused()
        status.selectedPlaceholders.length = 0

        if focused.length == 0
            return

        # Clear highlight
        $('.placeholder_highlighted').removeClass('placeholder_highlighted')

        if focused.length == 1 and focused[0].rule?.ruleType == 'single'
            #multiselect.flush()

            status.multiEdit = false
            status.currentRule = focused[0].rule

            highlightRule focused[0].rule.id
            return

        if focused.length > 0
            # Clear highlight
            $('.placeholder_highlighted').removeClass('placeholder_highlighted')

            status.multiEdit = true
            status.currentRule = null
            status.multiDayMask = [true,true,true,true,true,true,true]
            status.multiEnd = true
            status.multiAd = true

            onlySingle = true
            onlyDaily = true


            endExample = null

            for item in focused
                if item.rule?
                    if item.rule.ruleType != 'daily'
                        onlyDaily = false
                    if item.rule.ruleType != 'single'
                        onlySingle = false

                    status.selectedPlaceholders.push item

                    if item.rule.ad != true
                        status.multiAd = false

                    if item.rule.ruleType == 'daily'
                        for day,i in item.rule.dayMask
                            if !day
                                status.multiDayMask[i] = false

                    if endExample == null and item.rule.timestampEnd?
                        endExample = item.rule.timestampEnd

                    if item.rule.end == false or item.rule.timestampEnd != endExample
                        status.multiEnd = false

            if endExample != null
                status.multiEndDay = endExample

            if onlySingle
                status.multiType = 'single'
            else if onlyDaily
                status.multiType = 'daily'
            else
                status.multiType = null

            if status.selectedPlaceholders.length == 0
                status.multiType = null

            #status.inspectorClicked = Math.random()

    setMultiEdit = (multiEditVal) ->
        $rootScope.multiedit =
            dayMask: [true,true,true,true,true,true,true]

        status.multiEdit = multiEditVal

    setHandlers = () ->
        handlers
            .off("mousedown")
            .on "mousedown", (e) ->
                e.stopPropagation()
                elem = $ this

                parent = elem.parents '.intervals'
                intervalToPaste = elem.parent()
                left = elem.offset().left
                realLeft = parseInt elem.css "left"

                elem.css({left: left}).addClass("active").appendTo parent
                setEvents(elem, intervalToPaste, e.pageX, left, realLeft)

                e.preventDefault()

    setEvents = (elem, intervalToPaste, mouseBeforeDrag, leftBeforeDrag, realLeft) ->
        realLeft = realLeft || 0
        realTime = null

        $(document).off(".timepicker")
        $(document)
            .on "mousemove.timepicker", (e) ->
                now = justMinutes(new Date())

                for i in status.intervals
                    left = e.pageX

                    if i.left <= left and  i.left+i.width >= left
                        if elem.hasClass("left") then classOffset = 30 else classOffset = 0
                        left -= i.left
                        realTime = i.realTime[left]

                        nT = Math.round(realTime / 5)
                        realTime = nT * 5

                        #blocker
                        if realTime < now+15 then realTime = now+15

                        #paste memory position and feed
                        realLeft = i.realCoord[realTime] - classOffset
                        intervalToPaste = i

                        break

                intervalToPaste.left = intervalToPaste.left || 0
                elem.css {left: realLeft+intervalToPaste.left}

            .on "mouseup.timepicker", () ->
                $(document).off(".timepicker")
                elem.css({left: realLeft}).removeClass("active").appendTo(intervalToPaste.element || intervalToPaste)

                rule = status.currentRule.rule

                if elem.hasClass("left")
                    rule.timestampStart = realTime*MIN if realTime
                    #status.currentRule.humanStartTime = $filter("timestampMask")(rule.timestampStart, "hh:mm")
                    if rule.timestampStart + 5*MIN > rule.timestampEnd
                        rule.timestampEnd = rule.timestampStart + 5*MIN

                else if elem.hasClass("right")
                    rule.timestampEnd = realTime*MIN if realTime
                    #status.currentRule.humanEndTime = $filter("timestampMask")(rule.timestampEnd, "hh:mm")
                    if rule.timestampEnd < rule.timestampStart + 5*MIN
                        rule.timestampStart = rule.timestampEnd - 5*MIN
                #blog status.currentRule, $filter("timestampMask")(rule.timestampStart, "DD.MM-hh:mm"), $filter("timestampMask")(rule.timestampEnd, "DD.MM-hh:mm"), $filter("timestampMask")(realTime*MIN, "hh:mm")

                #$rootScope.$apply()
                scrollTo realTime*MIN


    appendHandlers = (intervals) ->
        status.intervals = intervals if intervals
        rule = status.currentRule?.rule
        #blog $filter("timestampMask")(rule.timestampStart, "DD.MM-hh:mm"), $filter("timestampMask")(rule.timestampEnd, "DD.MM-hh:mm")
        handlers.css("display", "none")

        if !rule or rule.ruleType!='chain' then return true

        for i in status.intervals
            if rule.timestampStart >= i.from and rule.timestampStart < i.to
                time = justMinutes rule.timestampStart
                coord = i.realCoord[time]

                startHandler.css({left: coord-30, display: "block"}).appendTo(i.element)

            if rule.timestampEnd >= i.from and rule.timestampEnd < i.to
                time = justMinutes rule.timestampEnd
                coord = i.realCoord[time]

                endHandler.css({left: coord, display: "block"}).appendTo(i.element)

        setHandlers()

    setRule = (data) ->
        status.currentRule = data.rule
        status.intervals = data.intervals

        appendHandlers()
        true

    reset = () ->
        status.showInspector = false
        status.currentRule = null
        handlers.css("display", "none")

    scrollTo = (ts) ->
        angular.element(status.intervals[0].element).scope().$parent.jumpTime(ts)
        appendHandlers()
        true

    {
        status

        setRule
        reset
        setHandlers
        appendHandlers

        setMultiEdit
        setMultiType

        selected
        scrollTo

        initInspector
        closeInspector
        
        updateInspector
    }