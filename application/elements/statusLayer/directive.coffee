buzzlike.directive 'statusLayer', ($parse, localization) ->
    restrict: 'C'
    template: tC['/elements/statusLayer']
    link: (scope, element, attrs) ->
        elem = $ element
        sched = $ elem.parents('.feedItem')[0]
        spinner = elem.find '.spinner'
        comment = $ elem.find('.comment')[0]
        sendProgress = $ elem.find('.sendProgress')[0]

        # debugElm = $ elem.find('.debug')[0]
        # debug = (val) -> debugElm.html val

        scope.sched = scope.$parent.$parent.sched
        scope.currentStatus = scope.sched.status

        lastStatus = scope.sched.status
        scope.$watch 'sched.status', (nVal, oVal) ->
            if nVal in ['pending','ready','completed','error']
                elem.addClass 'visible'

            if nVal == oVal and nVal in ['planned','completed']
                switch nVal
                    when 'planned'
                        steps[0]()
                    when 'completed'
                        elem.addClass 'permCompleted'
                        if scope.sched.stats.length > 0
                            elem.addClass 'showStats'
                        # smartGoStep 4
                        steps[4]()
            else
                switch nVal
                    when 'pending'
                        smartGoStep 1
                    when 'ready'
                        smartGoStep 3
                    when 'completed'
                        smartGoStep 4
                    when 'error'
                        showError()

            lastStatus = nVal
        , true

        showError = ->
            elem.addClass 'error'
            spinner.addClass('hide').remove()
            setText 'error'

        # ====================================
        # Step mechanics helpers
        # ====================================
        setText = (text) ->
            scope.currentStatus = text
            localization.onLangLoaded ->
                comment.html localization.translate 'timelineApp_schedule_status'+scope.currentStatus

        filled = 0 # 1(half) 2(full)
        progressHandler = null
        setSpinnerProgress = (progress, cb) ->
            # debug progress + ' ' + filled
            if progress == 100
                if filled < 1
                    clearTimeout progressHandler if progressHandler?
                    spinner.addClass 'halfFull'
                    progressHandler = setTimeout ->
                        spinner.addClass 'full'
                        filled = 2
                        progressHandler = setTimeout ->
                            cb? true
                        , 200
                    , 100
                else
                    spinner.addClass 'full'
                    filled = 2
                    progressHandler = setTimeout ->
                        cb? true
                    , 200
                return

            if progress > 50
                if filled < 1
                    clearTimeout progressHandler if progressHandler?
                    spinner.addClass 'halfProgress'
                    progressHandler = setTimeout ->
                        spinner.addClass 'halfFull'
                        progressHandler = setTimeout ->
                            filled = 1
                            spinner.addClass 'almostDone'
                            cb? true
                        , 100
                    , 15 * SEC
                return

            if progress == 0
                clearTimeout progressHandler if progressHandler?
                spinner.addClass 'fullSpeed'
                spinner.removeClass 'halfFull'
                spinner.removeClass 'halfProgress'
                spinner.removeClass 'full'
                spinner.removeClass 'almostDone'
                progressHandler = setTimeout ->
                    spinner.removeClass 'fullSpeed'
                    cb? true
                , 100
                filled = 0


        # ====================================
        # Step mechanics
        # ====================================
        currentStep = 0
        steps = [
            # planned
            (cb) ->
                spinner.detach()
                setText 'planned'
                cb? true
        ,
            # pending
            (cb) ->
                sendProgress.append spinner
                setText 'pending'
                setTimeout ->
                    # spinner.addClass 'pending'
                    setSpinnerProgress 80
                    cb true
                , 100
        ,
            # ready
            (cb) ->
                # spinner.removeClass 'pending'
                # spinner.addClass 'full'
                setSpinnerProgress 100, ->

                    if scope.sched.timestamp - Date.now() > 5 * SEC
                        setText 'ready'
                        # hide spinner
                        spinner.addClass 'hide'
                        setTimeout ->
                            elem.addClass 'completed'
                            # spinner.removeClass 'full'
                            setSpinnerProgress 0

                            setTimeout ->
                                elem.removeClass 'completed'
                                spinner.removeClass 'hide'
                                setTimeout ->
                                    setText 'sending'
                                    cb true
                                , 200
                            , scope.sched.timestamp - Date.now() - 5 * SEC

                        , 200
                        
                    else
                        setSpinnerProgress 0, ->
                            setTimeout ->
                                cb true
                            , 200
                    
        ,
            # sending
            (cb) ->
                setText 'sending'
                # spinner.addClass 'ready'
                setSpinnerProgress 80
                cb true
        ,
            # Completed
            (cb) ->
                setText 'completed'

                setSpinnerProgress 100, ->
                    spinner.addClass 'hide'

                    setTimeout ->
                        elem.addClass 'completed'

                        setTimeout ->
                            spinner.remove()
                            cb? true
                        , 200
                    , 200

                    if scope.sched.stats.length > 0
                        elem.addClass 'showStats'
                    else
                        unreg = scope.$watch 'sched.stats', (nVal) ->
                            if nVal.length > 0
                                unreg()
                                elem.removeClass 'permCompleted'
                                elem.addClass 'showStats'
                        , true

        ]
        destinationStep = currentStep
        stepsRunning = false

        smartGoStep = (step, cb) ->
            if step > destinationStep
                destinationStep = step

            if !stepsRunning
                goStep ->
                    cb? true

        goStep = (cb) ->
            if currentStep < destinationStep
                currentStep++
                steps[currentStep] ->
                    goStep cb
            else
                cb true


        # ====================================
        # Render helpers
        # ====================================

        scope.makeDiff = (val) -> Math.abs(Math.ceil val * 100) + '%'

        simpleCache = {}
        scope.simpleNumber = (number) ->
            if simpleCache[number]?
                return simpleCache[number]

            if number >= 1000000
                simpleCache[number] = Math.round(number / 1000000) + 'm'
            
            else if number >= 1000
                simpleCache[number] = Math.round(number / 1000) + 'k'
            else 
                simpleCache[number] = number | 0

            return simpleCache[number]
        true