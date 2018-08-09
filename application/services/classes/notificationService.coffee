buzzlike.service 'notificationService', (account, itemService, rpc, socketAuth, notificationCenter, socketService, $rootScope, buffer, contentService) ->

    class classEntity extends itemService

        itemType: 'notification'

        constructor: () ->
            super()

            @unread = {}
            @byToken = {}

            socketAuth.onAuth =>
                @fetchNew()

        handleItem: (item) ->
            saved = super item

            @unread[saved.id] = saved if saved.unread == true
            @byToken[saved.token] = saved if saved.token?

            if waitTokens.length > 0
                if saved.token? and saved.token in waitTokens
                    notificationCenter.addMessage saved
                    removeElementFromArray saved.token, waitTokens


            if account.user.settings.takeUploadToRight == true and saved.notificationType == 'upload'
                if tokenMax[saved.token]? and saved.ids.length >= tokenMax[saved.token]
                    takeToRigth saved.ids, saved.token

            saved

        # socketService.on 'push', (data) ->
        #     item = @handleItem data
        #     notificationCenter.addMessage item
        #     $rootScope.$apply()

        onCreate: (data) ->
            item = super data
            notificationCenter.addMessage item
            
        removeCache: (id) ->
            item = @storage[id]
            if @unread[item.id]? then delete @unread[item.id]
            if @byToken[saved.token]? then delete @byToken[saved.token]
            super id

        markRead: (id, cb) ->
            if @unread[id]? then delete @unread[id]
            @save 
                id: id,
                unread: false
            , cb

        markAllRead: (cb) -> 
            @call 'markAllRead', () =>
                emptyObject @unread

        fetchNew: (cb) ->
            @query 
                unread: true
            , (items, total) =>
                cb? items, total

        tokenMax = {}
        takeToRigth = (ids, token) ->
            delete tokenMax[token]
            items = contentService.getByIds ids, (items) ->
                buffer.addItems items

        setTokenMax: (token, max) ->
            if @byToken[token]?.ids?.length >= max
                # Take to right
                takeToRigth @byToken[token].ids, token
            else
                tokenMax[token] = max

        waitTokens = []
        showNotificationByToken: (token) ->
            if @byToken[token]?
                notificationCenter.addMessage @byToken[token]
            else
                waitTokens.push token
            # @query
            #     token: token
            # , (items, total) ->
            #     notificationCenter.addMessage items[0] if items[0]?

    new classEntity()
