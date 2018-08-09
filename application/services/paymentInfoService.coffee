buzzlike.factory "paymentInfoService", ($state, account) ->

    status =
        sequence: null
        step: null
        accept: null # post/money
        agreed: false

    map =
        introPage: "introPage"
        postPage:
            allowArrows: true
            prevPage: "introPage"
            steps: 2
            final: () ->
                $state.go 'market'
                true
        moneyPage:
            allowArrows: true
            prevPage: "introPage"
            steps: 2
            final: () ->
                account.charge 600.00
        offerPage: 'offerPage'


    # sequence: по карте
    # step - шаг выбранного пути
    showPage = (sequence, step) ->
        status.sequence = sequence
        if step
            status.step = step
        else if map[status.sequence]?.steps
            status.step = 1
        else
            status.step = 0

        #setTimeout ->
        #    $(window).resize()
        #, 1
        true

    nextStep = ->
        status.step++
        status.step = 0 if !map[status.sequence]?.steps
        if status.step > map[status.sequence]?.steps
            status.step = map[status.sequence]?.steps
            map[status.sequence]?.final()
        true

    prevStep = ->
        status.step--
        status.step = 0 if !map[status.sequence]?.steps
        if status.step <= 0
            showPage map[status.sequence]?.prevPage
            status.step = 0
        true

    fetchData = ->
        true

    saveDate = ->
        true

    {
        status
        map
        showPage
        nextStep
        prevStep
    }