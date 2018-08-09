buzzlike.service 'resize', ($rootScope) ->

    status = 
        width: window.innerWidth
        height: window.innerHeight

    innerCnt = 0
    callbacks = {}

    showedPanels =
        right: false
        left: false

    # Регистрируем коллбек
    # Если хотим его потом отключать, используем идентификатор и unregisterCb
    registerCb = (cb, id) ->
        if !id?
            id = 'inner_' + innerCnt
            innerCnt++

        callbacks[id] = cb

        width = status.width

        #if showedPanels.right
        #    width -= rightPanelWidth
        #
        #if showedPanels.left
        #    width -= leftPanelWidth

        cb width, status.height, showedPanels
        id

    unregisterCb = (id) ->
        delete callbacks[id] if callbacks[id]?

    setRightPanel = (showed) ->
        if showedPanels.right != showed
            showedPanels.right = showed
            updateCallbacks()

    setLeftPanel = (showed) ->
        if showedPanels.left != showed
            showedPanels.left = showed
            updateCallbacks()

    updateCallbacks = () ->
        width = status.width

        #if showedPanels.right
        #    width -= rightPanelWidth
        #
        #if showedPanels.left
        #    width -= leftPanelWidth

        for key,cb of callbacks
            cb width, status.height, showedPanels

    # $(window).on 'resize', (e) ->
    #     status.width = window.innerWidth
    #     status.height = window.innerHeight

    #     updateCallbacks()

    #     $rootScope.$apply()

    trigger = () ->
        updateCallbacks()

    {
        status
        showedPanels

        trigger

        registerCb
        unregisterCb

        setRightPanel
        setLeftPanel
    }
