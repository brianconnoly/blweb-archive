buzzlike.factory "smartDate", ($compile, $rootScope, localStorageService) ->
    state =
        utc: 0

    ready = false
    readyCb = null

    getShiftTimeline = (timestamp) ->
        u = (state.utc - getLocalMaschineUTC())

        timestamp - (u*(1000*60*60))

    getShiftTimeBar = (timestamp) ->
        u = (state.utc - getLocalMaschineUTC())

        timestamp + (u*(1000*60*60))

    resetShiftTimeBar = (shiftTime) ->
        u = (state.utc - getLocalMaschineUTC())

        shiftTime - (u*(1000*60*60))

    setShiftTime = (utc_val) ->
        ready = true
        if !localStorageService.get 'user.timezone'
            setLocalMaschineUTC()
        else
            setUTC(utc_val)

        readyCb?()
        readyCb = null

    setUTC = (utc_val) ->
        state.utc = utc_val

    setLocalMaschineUTC = ->
        hoursDiffStdTime = getLocalMaschineUTC()
        setUTC(hoursDiffStdTime)
        hoursDiffStdTime

    getLocalMaschineUTC = ->
        rightNow = new Date()
        # date1    = new Date(rightNow.getFullYear(), rightNow.getMonth(), rightNow.getDate(), 0, 0, 0, 0)
        temp     = rightNow.toGMTString()
        date3    = new Date(temp.substring(0, temp.lastIndexOf(" ")-1))
        hoursDiffStdTime = (rightNow - date3) / (1000 * 60 * 60) | 0

    onReady = (cb) ->
        if ready
            cb?()
        else
            readyCb = cb

    {
        onReady

        setShiftTime
        getShiftTimeline

        getShiftTimeBar
        resetShiftTimeBar

        getLocalMaschineUTC
        state
        setLocalMaschineUTC
    }