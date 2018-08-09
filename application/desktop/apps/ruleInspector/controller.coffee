buzzlike.controller 'ruleInspectorCtrl', ($scope, localization, $rootScope, $filter, stateManager, desktopService, ruleService, inspectorService, account, scheduleService, multiselect, smartDate, groupService) ->

    $scope.session.expandedHeader = false

    $scope.stateTree.applyState
        'escape': $scope.closeApp

    # Получаем состояние сервиса
    $scope.status = inspectorStatus = inspectorService.status

    $scope.daysArray = [1,2,3,4,5,6,0]
    $scope.daysValues = {}

    localization.onLangLoaded ->
        for day in $scope.daysArray
            $scope.daysValues[day] = localization.translate(147+day)[1]

    $scope.$on '$destroy', ->
        $scope.closeInspector(true)
        
    # Закрываем инспектор
    $scope.closeInspector = ->
        inspectorService.closeInspector()
        true

    $scope.saveRule = saveRule = ->
        if inspectorStatus.currentRule?.id?
            if inspectorStatus.currentRule.timestampEnd - inspectorStatus.currentRule.timestampStart < 1 * MIN
                inspectorStatus.currentRule.timestampEnd = inspectorStatus.currentRule.timestampStart + (2 * MIN)

            process = $scope.progress.add()
            ruleService.save inspectorStatus.currentRule, ->
                $scope.progress.finish process
        true

    $scope.saveMulti = saveMulti = ->
        for placeholder in inspectorStatus.selectedPlaceholders
            do (placeholder) ->
                rule = placeholder.rule

                rule.dayMask = inspectorStatus.multiDayMask
                if inspectorStatus.multiEnd == true
                    rule.end = true

                    if !inspectorStatus.multiEndDay?
                        inspectorStatus.multiEndDay = rule.timestampStart + DAY * 7

                    rule.timestampEnd = inspectorStatus.multiEndDay

                if inspectorStatus.multiAd == true
                    rule.ad = inspectorStatus.multiAd

                process = $scope.progress.add()
                ruleService.save rule, ->
                    $scope.progress.finish process

    correctEndTime = ->
        if $scope.status.currentRule.timestampEnd == null
            if $scope.status.currentRule.ruleType == 'daily'
                $scope.status.currentRule.timestampEnd = $scope.status.currentRule.timestampStart + DAY * 7
            else if $scope.status.currentRule.ruleType == 'chain'
                $scope.status.currentRule.timestampEnd = $scope.status.currentRule.timestampStart + HOUR * 6

    $scope.getDayClass = (day) ->
       
        if inspectorStatus.currentRule?.id?
            mask = inspectorStatus.currentRule.dayMask
        else
            if !inspectorStatus.multiDayMask?
                return ""

            mask = inspectorStatus.multiDayMask

        classes = ""
        if mask[day] == true
            classes += 'active'

        if day == 0 
            return classes

        if day == 6
            if mask[6] == mask[0]
                classes += ' wideright'
            return classes

        if day < 7 and mask[day+1] == mask[day]
            classes += ' wideright'

        classes

    $scope.setPlan = (type) ->
        if type?
            inspectorService.status.selectedType = type

            activeRule = $scope.status.currentRule
            activeRule.ruleType = type
            correctEndTime()
            saveRule()

        true

    $scope.setMultiPlan = (type) ->
        inspectorService.setMultiType type

    $scope.selectDay = ($event, day) ->
        if inspectorStatus.currentRule?.id?
            mask = inspectorStatus.currentRule.dayMask
        else
            if !inspectorStatus.multiDayMask?
                return false
                
            mask = inspectorStatus.multiDayMask

        mask[day] = !mask[day]
        
        if inspectorStatus.currentRule?.id?
            saveRule()
        else
            saveMulti()

        true

    $scope.removeAll = ->
        desktopService.launchApp 'optionsList',
            message: 'inspector_removeAllQuestion'
            options: [
                {
                    text: 'inspector_removeAll'
                    action: ->
                        ruleService.removeByGroupId $scope.status.currentRule.groupId
                        $scope.closeInspector()
                }
            ]

    # Если изменились выбранные элементы
    $scope.$watch () ->
        multiselect.state.focusedHash
    , (nValue) ->
        # Меняем режим испектора если есть выбранные плейсхолдеры
        inspectorService.updateInspector()
    , true

    $scope.setFocusRule = ->
        placeholder = multiselect.getFocused()[0]
        multiselect.flush()
        angular.element($('.rule_'+placeholder.rule.id).first()).scope().showInspector()
        true

    $scope.focusDay = ->
        # elms = $('.placeholder_highlighted')

        # # inspectorService.status.selectedType = null
        # multiselect.flush()
        # date = getClearDataTimestamp(inspectorService.status.currentPlaceholder.timestamp)
        # for elm in elms
        #     elm_date = getClearDataTimestamp(angular.element(elm).scope().item.timestamp)
        #     if date == elm_date
        #         $(elm).addClass 'selected'
        #         multiselect.addToFocus angular.element(elm).scope().item

        groupRules = ruleService.byGroupId[inspectorService.status.currentPlaceholder.groupId]
        dateObj = new Date inspectorService.status.currentPlaceholder.timestamp

        startDay = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime()
        endDay = startDay + DAY

        groupService.getById inspectorService.status.currentPlaceholder.groupId, (groupItem) ->

            for rule in groupRules
                cnt = 0
                ts = 0


                while ts < endDay and (rule.end and ts < rule.timestampEnd)
                    pHolder = ruleService.getPlaceholder cnt, rule.id
                    cnt++
                    ts = pHolder.timestamp

                    if pHolder.timestamp > startDay and pHolder.timestamp < endDay
                        for feed in groupItem.feeds
                            pHolder.communityId = feed.communityId
                            multiselect.addToFocus pHolder

                    if rule.ruleType == 'single'
                        break

                    true

            elms = $('.placeholder')
            for elm in elms
                if multiselect.isFocused angular.element(elm).scope().item
                    $(elm).addClass 'selected'

