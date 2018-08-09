buzzlike.controller 'helpCtrl', ($scope) ->

    $scope.session.expandedHeader = false

    $scope.stateTree.applyState
        'escape': $scope.stepBack

    $scope.currentStep =
        translateTitle: 'helpApp_title'

    $scope.stepStack = []
    $scope.stepStack.push $scope.currentStep

    defaultState = false

    $scope.catalog = [
            translateTitle: 'helpApp_general'
            icon: '/resources/images/desktop/dock/black/help.svg'
            expanded: defaultState
            pages: [
                    translateTitle: 'helpApp_general_about'
                    file: 'general/about-buzzlike'
                ,
                    translateTitle: 'helpApp_general_beforeStart'
                    file: 'general/before-start'
                ,
                    translateTitle: 'helpApp_general_payment'
                    file: 'general/payment'
                ,
                    translateTitle: 'helpApp_general_paymentByPost'
                    file: 'general/payment-by-post'
            ]
        ,
            translateTitle: 'helpApp_timeline'
            icon: '/resources/images/desktop/dock/black/timelines.svg'
            expanded: defaultState
            pages: [
                    translateTitle: 'helpApp_timeline_about'
                    file: 'channels/overview'
                ,
                    translateTitle: 'helpApp_timeline_addChannel'
                    file: 'channels/add-channel'
                ,
                    translateTitle: 'helpApp_timeline_editChannel'
                    file: 'channels/edit-channel'
                ,
                    translateTitle: 'helpApp_timeline_scale'
                    file: 'channels/scale'
            ]
        ,
            translateTitle: 'helpApp_themes'
            icon: '/resources/images/desktop/dock/black/themes.svg'
            expanded: defaultState
            pages: [
                    translateTitle: 'helpApp_themes_about'
                    file: 'themes'
                # ,
                #     translateTitle: 'helpApp_themes'
            ]
        # ,
        #     translateTitle: 'helpApp_themeEditor'
        #     icon: '/resources/images/desktop/dock/black/themes.svg'
        #     expanded: defaultState
        #     pages: [
        #             translateTitle: 'helpApp_themeEditor_about'
        #         ,
        #             translateTitle: 'helpApp_themeEditor'
        #     ]
        ,
            translateTitle: 'helpApp_content'
            icon: '/resources/images/desktop/dock/black/materials.svg'
            expanded: defaultState
            pages: [
                    translateTitle: 'helpApp_content_about'
                    file: 'materials'
                # ,
                #     translateTitle: 'helpApp_content'
            ]
        # ,
        #     translateTitle: 'helpApp_market'
        #     icon: '/resources/images/desktop/dock/black/market.svg'
        #     expanded: defaultState
        #     pages: [
        #             translateTitle: 'helpApp_market_about'
        #         ,
        #             translateTitle: 'helpApp_market'
        #     ]
    ]

    $scope.getSectionHeight = (section) ->
        if section.expanded == true
            return section.pages.length * 34
        0

    $scope.selectSection = (section, page) ->
        $scope.currentSection = section
        section.expanded = true
        $scope.stepStack.length = 1
        $scope.stepStack.push
            translateTitle: section.translateTitle

        if !page?
            page = section.pages[0]

        $scope.currentStep = page
        $scope.stepStack.push $scope.currentStep


    $scope.selectSection $scope.catalog[0]

    $scope.getHelpFile = ->
        if $scope.currentStep?.file?
            return "/resources/images/desktop/help/" + $scope.currentStep.file + "/help.svg"
        ""

    $scope.compact = false
    $scope.onResize (wid, hei) ->
        if wid >= 900
            $scope.compact = false
        else
            $scope.compact = true

    # 
    # Save state
    #

    $scope.stateSaver.add 'stepStack', ->
        # Saver
        stack: $scope.stepStack
        section: $scope.catalog.indexOf($scope.currentSection)
        page: $scope.currentSection?.pages.indexOf $scope.currentStep
    , (data) ->
        $scope.stepStack.length = 0
        # Loader
        for step in data.stack
            $scope.stepStack.push step

        $scope.currentSection = $scope.catalog[data.section*1]
        $scope.currentSection.expanded = true
        $scope.currentStep = $scope.currentSection?.pages[data.page*1]

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()