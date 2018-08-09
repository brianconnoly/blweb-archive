buzzlike
    .controller 'ugcManagerCtrl', (rpc, $scope, buffer, multiselect, account, desktopService, ugcService, communityService, updateService, postService, userService, smartDate, $filter) ->

        $scope.selectState = multiselect.state

        $scope.canOverrideLoader = ->
            account.user.roles.Morpheus or account.user.roles.ugcPRO

        #
        # User filter
        #
        $scope.userFilterUpdated = ->
            $scope.resetProposedList()
            $scope.fetchProposedPage()

        #
        # Date format optimizer
        #
        tsCache = {}
        $scope.getFormatedDate = (ts) ->
            if !ts?
                return ''

            ts = smartDate.getShiftTimeline(ts)
            if !tsCache[ts]?
                tsCache[ts] = $filter('timestampMask')(ts, 'DD MMM в hh:mm').toLowerCase()
            tsCache[ts]

        #
        # Tab switcher
        #
        $scope.itemHeight = 120
        $scope.currentFilter = 'created'
        $scope.setFilter = (filter) ->
            if $scope.currentFilter == filter
                return

            $scope.currentFilter = filter

            if filter == 'rating'
                $scope.proposed.length = 0
                $scope.itemHeight = 60
                $scope.proposedParams.usersFilter = ""
            else
                $scope.itemHeight = 120

            $scope.resetProposedList()
            $scope.fetchProposedPage()

            $scope.stateSaver.save()

        #
        # Actions
        #
        $scope.createCollector = ->
            desktopService.launchApp 'addFeed',
                api:
                    onAdd: (communities) ->
                        for comm in communities
                            link = ""
                            switch comm.communityType
                                when 'profile'
                                    link += 'id'
                                when 'group', 'page'
                                    link += 'club'
                                when 'event'
                                    link += 'event'

                            link += Math.abs comm.socialNetworkId*1

                            ugcService.create
                                communityId: comm.id
                                link: comm.screenName or link
                                userId: account.user.id
                                background: "54ec2cdbd05b30a9749bd527"
                                logo: "54ec2cdbd05b30a9749bd527"
                            , (item) ->
                                $scope.selectCollector item
                                $scope.showSettings = true

        $scope.acceptPost = (post, cb) ->
            ugcService.call 'acceptPost', post.id, cb
        $scope.acceptPosts = (e) ->
            focused = multiselect.getFocused()
            for post in focused
                if post.type == 'post'
                    $scope.acceptPost post

        $scope.rejectPost = (post) ->
            ugcService.call 'rejectPost', post.id
        $scope.rejectPosts = (e) ->
            focused = multiselect.getFocused()
            for post in focused
                if post.type == 'post'
                    $scope.rejectPost post

        $scope.takeToRight = (item) ->
            buffer.addItem item

        #
        # Collectors list
        #
        $scope.collectors = ugcService.storage
        ugcService.fetchMy (items) ->
            # console.log items, ugcService.storage

        #
        # Select collector
        #
        $scope.currentCollector = null
        $scope.ugcCommunity = null


        defaultSettings =
            logoLink: ""

            color1:
                r: 55
                g: 54
                b: 54
            color2:
                r: 247
                g: 146
                b: 30
            color3:
                r: 242
                g: 242
                b: 242

            blurBg: true
            blurRadius: "40"

            bgOverlay: true
            bgOverlayColor:
                r: 0
                g: 0
                b: 0
            bgOverlayOpacity: "20"
            
            editorBack: true
            editorBackColor:
                r: 255
                g: 255
                b: 255
            editorBackOpacity: "20"

            finalRatingPost: false
            finalRatingPostInterval: "7"
            finalRatingPostText: "ТОП 10 авторов на сегодня:"
            finalRatingPostDate: 0
            finalRatingPostImageId: null

            logoSubtitle: true
            logoSubtitleText: "Расскажите всем!"
            logoSubtitleColor:
                b: 0
                g: 0
                r: 0
            logoSubtitleFont: "19"

            popupButtonText: "Ок"

            popupHeader: true
            popupHeaderText: "Спасибо"

            popupImage: false
            popupImageId: null

            popupMessage: true
            popupMessageText: "После одобрения и публикаций вам будут начисляться баллы в "

            ratingHeaderSwitch: true
            ratingHeader: "Рейтинг"

            ratingHeaderImage: false
            ratingHeaderImageId: null
            
            ratingHeaderText: false
            ratingHeaderTextValue: "Лучшие авторы нашего сообщества"
            ratingHeaderTextColor:
                b: 0
                g: 0
                r: 0
            ratingHeaderTextFont: "43"
            
            ratingItemName: "Баллы"

            textareaPlaceholder: "Напишите текст"
            uploadButtonText: "Добавьте изображения"

            scheduleInterval: 10
            overrideFaq: true

        $scope.lastPlanned = Date.now()
        $scope.selectCollector = (item) ->
            if $scope.currentCollector == item
                return

            $scope.lastPlanned = toMinutes Date.now() + (2 * MIN)

            ugcService.call 'checkSuggested', item.id, (res) ->
                true

            $scope.currentCollector = item
            $scope.ugcCommunity = communityService.getById item.communityId

            # Prepare settings
            changed = false
            for k,v of defaultSettings
                if !item.settings[k]?
                    item.settings[k] = v
                    changed = true

            $scope.saveSettings()

            $scope.currentFilter = 'created'

            $scope.resetProposedList()
            $scope.fetchProposedPage()
            true

        $scope.$watch 'currentCollector.deleted', (nVal) ->
            if nVal == true
                $scope.currentCollector = null
                $scope.showSettings = false

        #
        # Collector settings
        #
        $scope.currentSettingsItem = 'general'
        $scope.showSettings = false
        $scope.removeLogo = ->
            ugcService.save
                id: $scope.currentCollector.id
                logo: "_null"
        $scope.removeBack = ->
            ugcService.save
                id: $scope.currentCollector.id
                background: "_null"
        $scope.removeTeam = ->
            ugcService.save
                id: $scope.currentCollector.id
                teamId: "_null"
        $scope.removePopupImage = ->
            $scope.currentCollector.settings.popupImageId = null
            $scope.saveSettings()
        $scope.removeRatingImage = ->
            $scope.currentCollector.settings.ratingHeaderImageId = null
            $scope.saveSettings()
        $scope.removeFinalImage = ->
            $scope.currentCollector.settings.finalRatingPostImageId = null
            $scope.saveSettings()
        $scope.removeLoaderImage = ->
            $scope.currentCollector.settings.loaderImageId = null
            $scope.saveSettings()
        $scope.removeFaqText = ->
            $scope.currentCollector.settings.faqTextId = null
            $scope.saveSettings()
        $scope.saveSettings = ->
            # Correct post date
            if $scope.currentCollector.settings.finalRatingPost == true
                if $scope.currentCollector.settings.finalRatingPostDate < Date.now() + 2 * MIN
                    $scope.currentCollector.settings.finalRatingPostDate = toMinutes(Date.now() + 2 * MIN)

            process = $scope.progress.add()
            ugcService.save
                id: $scope.currentCollector.id
                settings: $scope.currentCollector.settings
            , ->
                $scope.progress.finish process
        $scope.getRGB = (color) ->
            "rgb(#{color.r},#{color.g},#{color.b})"
        #
        # Proposeds lazy loading
        #
        $scope.proposed = []
        $scope.proposedFilter = (item) ->
            $scope.currentFilter == item.proposeStatus

        $scope.proposedParams = 
            usersFilter: ""
            pageSize: 0
            page: 50
            total: 0
            isLoading: false
            reloadOnStart: false

        $scope.resetProposedList = ->
            $scope.proposedParams.pageSize = Math.ceil( ($scope.session.size.height - 100) / $scope.itemHeight ) * 2
            $scope.proposedParams.page = 0
            # $scope.proposed.length = 0
            $scope.proposedParams.total = 0
            $scope.proposedParams.isLoading = false
            $scope.proposedParams.reloadOnStart = false

        $scope.fetchProposedPage = () ->
            if $scope.proposedParams.isLoading == true
                return 

            $scope.proposedParams.isLoading = true
            proposedsProcess = $scope.progress.add()

            if $scope.currentFilter != 'rating'
                postService.query
                    proposedTo: $scope.currentCollector.id
                    proposeStatus: $scope.currentFilter

                    limit: $scope.proposedParams.pageSize
                    page: $scope.proposedParams.page

                    sortBy: 'created'
                    sortType: 'desc'
                , processQueryResult proposedsProcess
            else
                # userService.query
                #     ugcId: $scope.currentCollector.id

                #     name: $scope.proposedParams.usersFilter

                #     limit: $scope.proposedParams.pageSize
                #     page: $scope.proposedParams.page

                #     sortBy: 'ugc.$.place'
                #     sortType: 'asc'
                # , processQueryResult proposedsProcess
                rpc.call 'ugc.queryUsers',
                    ugcId: $scope.currentCollector.id

                    name: $scope.proposedParams.usersFilter
                    limit: $scope.proposedParams.pageSize
                    page: $scope.proposedParams.page
                , (result) ->
                    processQueryResult(proposedsProcess) result.items, result.total


        processQueryResult = (process) ->
            (items, total) ->
                if $scope.proposedParams.page == 0
                    $scope.proposed.length = 0

                $scope.proposedParams.page++
                $scope.proposedParams.total = total

                $scope.progress.finish process

                for item in items
                    $scope.proposed.push item if item not in $scope.proposed

                $scope.proposedParams.isLoading = false

        # fetchPage()

        updateId = updateService.registerUpdateHandler (data) ->
            if data['post']? # or data['user']
                if $scope.proposedParams.page < 2 or $scope.proposedScrollValue < 300
                    $scope.resetProposedList()
                    $scope.fetchProposedPage()
                else
                    $scope.proposedParams.reloadOnStart = true

        $scope.$on '$destroy', ->
            updateService.unRegisterUpdateHandler updateId

        # 
        # Save state
        #

        $scope.stateSaver.add 'stepStack', ->
            # Saver
            currentCollector: $scope.currentCollector?.id
            currentFilter: $scope.currentFilter
        , (data) ->
            ugcService.getById data.currentCollector, (item) ->
                if item?.id?
                    $scope.selectCollector item

                $scope.setFilter data.currentFilter

        $scope.$watch 'currentCollector', (nVal) ->
            $scope.stateSaver.save()

        true