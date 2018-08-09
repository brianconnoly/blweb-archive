*deps: $compile
*template: null

elem = $ element

currentStepId = -1
currentStep = null

generated = []
nextStep = ->
    currentStepId++
    currentStep = step = scope.wizard.currentStep.series[currentStepId]

    if !currentStep?
        # Last step
        currentStepId--
        return

    newScope = scope.$new()
    newScope.step = step
    newScope.id = currentStepId
    newScope.nextStep = () ->
        if newScope.id < scope.wizard.currentStep.series.length - 1
            if newScope.id + 1 < generated.length
                for i in [newScope.id + 1...generated.length]
                    generated[i].scope.$destroy()
                    generated[i].elem.remove()

            for i in [0...newScope.id]
                generated[i].elem
                .css 'margin-top', (newScope.id-i) * -100
                .removeClass 'lastFixed'

            generated.length = newScope.id + 1
            currentStepId = newScope.id

            nextStep()


    newScope.pick = (item) ->
        if newScope.id < scope.wizard.currentStep.series.length - 1
            newElem
            .addClass 'fixed'
            .addClass 'lastFixed'
            .css 'margin-top', 0
            newScope.picked = true

        if step.multi
            if !scope.wizard.data[step.variable]?.length?
                scope.wizard.data[step.variable] = []
            if item.id in scope.wizard.data[step.variable]
                removeElementFromArray item.id, scope.wizard.data[step.variable]
                if scope.wizard.data[step.variable].length == 0
                    newScope.flush()
            else
                scope.wizard.data[step.variable].push item.id
        else
            if scope.wizard.data[step.variable] != item.id
                scope.wizard.data[step.variable] = item.id
            else
                newScope.flush()

        newScope.nextStep()

    newScope.flush = ->
        if step.multi
            if !scope.wizard.data[step.variable]?.length?
                scope.wizard.data[step.variable] = []

            scope.wizard.data[step.variable].length = 0
        else
            scope.wizard.data[step.variable] = null

        for i in [0...newScope.id]
            generated[i].elem
            .css 'margin-top', (newScope.id-i-1) * -100
            .removeClass 'lastFixed'

        newElem.addClass 'lastFixed'

        if newScope.id + 1 < generated.length
            for i in [newScope.id + 1...generated.length]
                generated[i].scope.$destroy()
                generated[i].elem.remove()
            newScope.picked = false
            newElem.removeClass 'fixed'
            if newScope.id > 0
                newElem.css 'margin-top', '100px'
        true

    newScope.isPicked = (item) ->
        # if newScope.id + 1 == generated.length # Last step
        #     return scope.wizard.isPicked item

        if step.multi
            if scope.wizard.data[step.variable]?.length?
                return item.id in scope.wizard.data[step.variable]
            return false
        else
            scope.wizard.data[step.variable] == item.id

    newElem = $ '<div>',
        class: currentStep.directive + ' novaWizardSeriesPicker'

    if newScope.id > 0
        newElem.css 'margin-top', '100px'
    elem.append newElem
    newElem = $compile(newElem)(newScope)

    generated.push
        scope: newScope
        elem: newElem

    if scope.wizard.data[step.variable]
        if newScope.id < scope.wizard.currentStep.series.length - 1
            newElem
            .addClass 'fixed'
            .addClass 'lastFixed'
            .css 'margin-top', 0
            newScope.picked = true
        nextStep()

nextStep()

# scope.isPicked = (item, variable) ->
#     if scope.wizard.data[variable]?.length?
#         return item.id in scope.wizard.data[variable]
#     item.id == scope.wizard.data[variable]
