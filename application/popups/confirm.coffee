buzzlike.factory "confirmBox", (novaDesktop, desktopService, localization, socketService, $rootScope) ->

    init = (message, yesCb, noCb) ->
        yesCb = yesCb || -> true
        noCb = noCb || -> true

        options = [
            text: 143
            action: yesCb
        ,
            text: 144
            action: noCb
            class: 'cancel'
        ]

        desktopService.launchApp 'optionsList',
            message: message
            options: options
            newSettings:
                cancelButton: false

    active = false
    stack = []

    sessionHandler = null

    nextConfirm = () ->

        if stack.length < 1
            active = false
            return

        data = stack.pop()
        active = true

        options = [
            text: 'yes_to_all'
            check: -> stack.length > 0
            action: ->
                socketService.emit 'confirmAnswer',
                    id: data.id
                    answer: true

                for data in stack
                    socketService.emit 'confirmAnswer',
                        id: data.id
                        answer: true

                stack.length = 0
                nextConfirm()
        ,
            text: 143
            action: ->
                socketService.emit 'confirmAnswer',
                    id: data.id
                    answer: true

                nextConfirm()
        ,

            text: 79
            class: 'cancel'
            check: -> stack.length == 0
            action: ->
                socketService.emit 'confirmAnswer',
                    id: data.id
                    answer: false

                nextConfirm()
        ,
            text: 79
            class: 'cancel'
            check: -> stack.length > 0
            action: ->
                socketService.emit 'confirmAnswer',
                    id: data.id
                    answer: false

                for data in stack
                    socketService.emit 'confirmAnswer',
                        id: data.id
                        answer: false

                stack.length = 0
                nextConfirm()
        ]

        # sessionHandler = desktopService.launchApp 'novaOptionsList',
        #     message:
        #         phrase: data.message
        #         description: data.description
        #     options: options
        #     newSettings:
        #         cancelButton: false
        novaDesktop.launchApp
            app: 'novaOptionsListApp'
            noSave: true
            data:
                options: options
                text: data.message
                description: data.description
                # onAccept: =>
                #     groupService.delete
                #         id: scope.group.id
                #         type: scope.group.type
                #     , ->
                #         scope.flowBox.closeFlowFrame scope.flowFrame

        # optionsList.init

        # , options,
        #     cancelButton: false


    socketService.on 'confirmCall', (data) ->
        stack.push data
        if active == false
            nextConfirm()

        # console.log sessionHandler?.scope.$$childHead

        sessionHandler?.scope.$$childHead.checkOptions()
        $rootScope.$apply()

    {
        init
        close
    }

###
    elem = $(".confirmBox")
    container = elem.find ".message"
    text = {}

    cbYes = null
    cbNo = null

    confirmState =
        'enter': () ->
            agree()
            stateManager.goBack()
        'escape': () ->
            discard()
            stateManager.goBack()

    open = () ->
        if user.animPrefs.turbo
            elem.show()
        else
            elem.fadeIn()
        stateManager.applyState confirmState

    discard = () ->
        cbNo?()
        hide()

    agree = () ->
        cbYes?()
        hide()

    hide = () ->
        if user.animPrefs.turbo
            elem.hide()
        else
            elem.fadeOut()

    getText = (id) ->
        contentService.getContentById(id)

    init: (message, yesCb, noCb) ->
        blog 'init'
        phrase = message
        phrase_yes = localization.translate(143)
        phrase_no = localization.translate(144)

        if message.phrase?
            phrase = message.phrase
            phrase_yes = message.yes
            phrase_no = message.no

        elem = $(".confirmBox")
        container = elem.find ".message"
        container_yes = elem.find ".yes"
        container_no = elem.find ".no"

        container.html phrase
        container_yes.html phrase_yes
        container_no.html phrase_no

        open()

        cbYes = yesCb
        cbNo = noCb

    callYes: () ->
        blog 'yes'
        agree()
        stateManager.goBack()
        null

    callNo: () ->
        blog 'no'
        discard()
        stateManager.goBack()
        null

    close: ->
        elem.fadeOut()
        null
###

###
buzzlike.directive "confirmBox", (confirmBox, localization) ->
    restrict: "C"
    scope: true
    link: (scope, elem, attrs) ->

        scope.localization = localization

        scope.callYes = (e) ->
            e.preventDefault()
            e.stopPropagation()

            confirmBox.callYes()

        scope.callNo = (e) ->
            e.preventDefault()
            e.stopPropagation()

            confirmBox.callNo()

        $("body")
            .on "keydown.confirmButtons", (e) ->
                if e.which == 13 or e.which == 32 #enter
                    $(".confirmBox, .applyBox").find(".yes").css background: "rgba(0,255,0,0.4)"
                if e.which == 27 #esc
                    $(".confirmBox, .applyBox").find(".no").css background: "rgba(255,0,0,0.4)"
            .on "keyup", ->
                $(".confirmBox, .applyBox").find(".yes, .no").css background: ""


###
