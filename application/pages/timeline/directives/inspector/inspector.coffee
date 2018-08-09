buzzlike.directive "inspector", (localization, $rootScope, $filter, stateManager, desktopService, ruleService, inspectorService, account, scheduleService, multiselect, smartDate) ->
    scope: true
    restrict: "C"
    template: templateCache['/pages/timeline/directives/inspector']
    link: (scope, element, attrs, ctrl) ->

        # Получаем состояние сервиса
        scope.status = inspectorStatus = inspectorService.status

        scope.daysArray = [1,2,3,4,5,6,0]
        scope.daysValues = {}

        localization.onLangLoaded ->
            for day in scope.daysArray
                scope.daysValues[day] = localization.translate(147+day)[1]

        # Закрываем инспектор
        scope.closeInspector = ->
            inspectorService.closeInspector()
            true

        scope.saveRule = saveRule = ->
            if inspectorStatus.currentRule?
                if inspectorStatus.currentRule.timestampEnd - inspectorStatus.currentRule.timestampStart < 1 * MIN
                    inspectorStatus.currentRule.timestampEnd = inspectorStatus.currentRule.timestampStart + (2 * MIN)

                ruleService.save inspectorStatus.currentRule
            true

        scope.saveMulti = saveMulti = ->
            for placeholder in inspectorStatus.selectedPlaceholders
                rule = placeholder.rule

                rule.dayMask = inspectorStatus.multiDayMask
                if inspectorStatus.multiEnd == true
                    rule.end = true

                    if !inspectorStatus.multiEndDay?
                        inspectorStatus.multiEndDay = rule.timestampStart + DAY * 7

                    rule.timestampEnd = inspectorStatus.multiEndDay

                if inspectorStatus.multiAd == true
                    rule.ad = inspectorStatus.multiAd

                ruleService.save rule

        correctEndTime = ->
            if scope.status.currentRule.timestampEnd == null
                if scope.status.currentRule.ruleType == 'daily'
                    scope.status.currentRule.timestampEnd = scope.status.currentRule.timestampStart + DAY * 7
                else if scope.status.currentRule.ruleType == 'chain'
                    scope.status.currentRule.timestampEnd = scope.status.currentRule.timestampStart + HOUR * 6

        scope.getDayClass = (day) ->
            if !inspectorStatus.showInspector
                return ""
            
            if inspectorStatus.currentRule?
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

        scope.setPlan = (type) ->
            if type?
                inspectorService.status.selectedType = type

                activeRule = scope.status.currentRule
                activeRule.ruleType = type
                correctEndTime()
                saveRule()

            true

        scope.setMultiPlan = (type) ->
            inspectorService.setMultiType type

        scope.selectDay = ($event, day) ->
            if inspectorStatus.currentRule?
                mask = inspectorStatus.currentRule.dayMask
            else
                if !inspectorStatus.multiDayMask?
                    return false
                    
                mask = inspectorStatus.multiDayMask

            mask[day] = !mask[day]
            
            if inspectorStatus.currentRule?
                saveRule()
            else
                saveMulti()

            true

        scope.removeAll = ->
            desktopService.launchApp 'optionsList',
                message:
                    'inspector_removeAllQuestion'
                options: [
                    {
                        text: 'inspector_removeAll'
                        action: ->
                            ruleService.removeByGroupId scope.status.currentRule.groupId
                            scope.closeInspector()
                    }
                ]

        # Если изменились выбранные элементы
        scope.$watch () ->
            multiselect.state.focusedHash
        , (nValue) ->
            # Меняем режим испектора если есть выбранные плейсхолдеры
            inspectorService.updateInspector()
        , true

        scope.setFocusRule = ->
            placeholder = multiselect.getFocused()[0]
            multiselect.flush()
            angular.element($('.rule_'+placeholder.rule.id).first()).scope().showInspector()
            true

        scope.focusDay = ->
            elms = $('.placeholder_highlighted')

            # inspectorService.status.selectedType = null
            multiselect.flush()
            date = getClearDataTimestamp(inspectorService.status.currentPlaceholder.timestamp)
            for elm in elms
                elm_date = getClearDataTimestamp(angular.element(elm).scope().item.timestamp)
                if date == elm_date
                    $(elm).addClass 'selected'
                    multiselect.addToFocus angular.element(elm).scope().item
