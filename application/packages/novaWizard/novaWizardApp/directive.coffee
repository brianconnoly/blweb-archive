*deps: novaWizard, $compile

elem = $ element
body = elem.children '.wizardBody'

scope.noMaximize()
scope.session.noItem = true
scope.session.size =
    width: 600
    height: 500
scope.session.startPosition = 'center'

class novaWizardSequence

    constructor: (@id, @data = {}) ->
        @picked = null
        @stepId = -1
        @wizard = novaWizard.wizardsData[@id]
        # setTimeout =>
        #     @nextStep()
        # , 0

    applyStep: (step) ->
        @currentStep = step

        # Clear prev step data
        if @stepScope?
            @stepScope.$destroy()
            @stepElem?.remove?()

        # Make new scope
        @stepScope = scope.$new()
        @stepScope.data = @data

        # if step.provide? and @data[step.provide]?
        #     @pick
        #         id: @data[step.provide]

        if @currentStep.directive
            @stepElem = $ '<div>',
                class: @currentStep.directive
        else if @currentStep.series?.length > 0
            @stepElem = $ '<div>',
                class: 'novaWizardSeries'

        body.append @stepElem
        @stepElem = $ $compile(@stepElem)(@stepScope)

    nextStep: () ->
        @stepId++
        step = @wizard.steps[@stepId]
        # @picked = null

        # Check if reached end
        if !step?
            @wizard.final? @data
            scope.closeApp()
            return

        # Check if we can skip
        if step.noSkip != true and step.provide?
            if @data[step.provide]?
                @nextStep()
                return

        @applyStep step

    canGoPrev: ->
        @stepId > 0

    canGoNext: ->
        if @stepId >= @wizard.steps?.length
            return false

        if @currentStep.canSkip == true
            return true

        if @currentStep.provide?
            if @currentStep.multi
                return @data[@currentStep.provide]?.length > 0
            return @data[@currentStep.provide]?

        true

    pickItem: (item) ->
        if @currentStep.multi != true
            @picked.length = 0
        @picked.push item

    pick: (item) ->
        if @currentStep.multi == true
            if !@data[@currentStep.provide]?.length?
                @data[@currentStep.provide] = []

            if item.id in @data[@currentStep.provide]
                removeElementFromArray item.id, @data[@currentStep.provide]
            else
                @data[@currentStep.provide].push item.id
        else
            @data[@currentStep.provide] = item.id

    flushPick: ->
        if @currentStep.provide?
            if @data[@currentStep.provide]?.length?
                @data[@currentStep.provide].length = 0
            else
                @data[@currentStep.provide] = null

    removePicked: (item) ->
        removeElementFromArray item.id, @data[@currentStep.provide]

    isPicked: (item) ->
        if @currentStep.multi
            if !@data[@currentStep.provide]?.length?
                return false
            return item.id in @data[@currentStep.provide]
        else
            @data[@currentStep.provide] == item.id

    goNext: () ->
        if !@canGoNext()
            return
        # @stepScope.itemSelected?()
        @nextStep()
        true

    goStep: (id) ->
        for step,i in @wizard.steps
            if step.id == id
                @stepId = i
                @applyStep step

    getNext: () ->
        @currentStep.customNext or 'novaWizardApp_goNext'

    getPrev: () ->
        @currentStep.customPrev or 'novaWizardApp_goPrev'

    goPrev: () ->
        if !@canGoPrev()
            return
        @stepId--
        @applyStep @wizard.steps[@stepId]
        true

if !scope.session.wizardId?
    setTimeout ->
        scope.closeApp()
    , 0
    return

scope.wizard = new novaWizardSequence scope.session.wizardId, scope.session.data
scope.wizard.nextStep()

# TODO:
# StateSaver save scope.session.data and wizardId
# Maybe pass wizardId instread of full object. Better for saving state. Lessa data.
