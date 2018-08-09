*deps: ruleService
*scope: true

scope.daysArray = [1,2,3,4,5,6,0]

unreg = scope.$watch attrs.novaRuleItem, (nVal) ->
    if nVal?.dayMask?
        unreg()
        scope.rule = nVal
, true

scope.setTime = ->
    scope.rule.timestampStart = toMinutes(Date.now()) + 10 * MIN

scope.triggerDay = (day) ->
    if scope.rule.timestampStart == 0
        scope.setTime()
    scope.rule.dayMask[day] = !scope.rule.dayMask[day]
    if scope.rule.id?
        ruleService.save
            id: scope.rule.id
            type: scope.rule.type
            dayMask: scope.rule.dayMask

scope.saveRule = ->
    ruleService.save
        id: scope.rule.id
        type: scope.rule.type
        timestampStart: scope.rule.timestampStart
