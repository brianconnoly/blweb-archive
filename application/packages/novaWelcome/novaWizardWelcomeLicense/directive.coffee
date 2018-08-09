
scope.acceptRules = !!scope.wizard.data.license_accepted

scope.rulesTrigger = ->
    if scope.acceptRules
        scope.wizard.pick
            id: true
    else
        scope.wizard.flushPick()
