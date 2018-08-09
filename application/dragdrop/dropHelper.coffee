buzzlike.service 'dropHelper', (localization, stateManager, $filter, buffer, $rootScope) ->

    class dropHelper

        constructor: () ->
            @fromBuffer = false
            @timeHelper = null
            @status = 
                currentAction: ""

            @dict = {}

            $('body').on 'keydown.dropHelper', (e) =>
                if @status.activated and e.which == 27
                    @flush true

        flush: (force = false) ->
            if !force and @status.activated == true
                return

            @status.activated == false
            @status.currentAction = ""
            @status.actions = []
            @dict = {}

            $('#dropHelperText').empty()
            $('#dropHelper').css 'display', 'none'

            true

        setAction: (action, e) ->
            if typeof action == 'object'
                @dict = action
                @processKeys e
            else
                @status.currentAction = action

                $('#dropHelperText').html localization.translate('dropHelper_' + @status.currentAction)
                $('#dropHelper').css 'display', if @status.currentAction.length > 0 then 'block' else 'none'

        setTime: (time) ->
            @status.time = time
            
            if !@timeHelper?
                @timeHelper = $('#helperTimeInfo')

            @timeHelper.css 'display', 'block'

            @timeHelper.children('.time').html $filter('timestampMask')(time, 'time')
            @timeHelper.children('.date').html $filter('timestampMask')(time, 'DD ofMMMM YYYY')

        show: (actions, time) ->
            @status.actions = actions
            @status.activated = false

            if time?
                @setTime time
            else if @status.time?
                delete @status.time
                @timeHelper?.css 'display', 'none'

            @timeHelper = $('#helperTimeInfo')
            
            fakeHelper = $('#dropHelperText')
            fakeHelper.empty()
            for action in actions
                fakeHelper.append $ '<div>',
                    class: 'action'
                    html: localization.translate action.phrase

            $('#dropHelper').css 'display', if @status.actions.length > 0 then 'block' else 'none'
            $rootScope.$apply()

        activate: (e, rightPanel) ->
            @fromBuffer = rightPanel or false

            if @status.actions?.length < 1
                return
            
            if @status.actions.length == 1
                items = @status.actions[0].action(e)
                if !e.altKey and rightPanel and @status.actions[0].leaveItems != true
                    buffer.removeItems items
                return

            # @status.actions.push
            #     phrase: 'dropHelper_close'
            #     action: (e) -> true

            @status.activated = true
            $('#dropHelperText').empty()



    new dropHelper()