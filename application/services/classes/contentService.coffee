buzzlike.service 'contentService', (rpc, itemService, buffer, notificationCenter, $injector, actionsService, desktopService, operationsService, $filter, novaWizard, novaDesktop) ->

    contextMenu = null
    combService = null
    importContentService = null

    class classEntity extends itemService

        itemType: 'content'
        typeMarker: 'text/image/video/audio/folder/url/content/poll/file'

        contentTypes = ['text', 'image', 'audio', 'video', 'url', 'folder', 'poll', 'file']
        operationsService.setContentTypes contentTypes

        getContentTypes: -> contentTypes
        isContent: (item) -> item?.type in contentTypes

        initDeps: () ->
            contextMenu = $injector.get 'contextMenu'
            combService = $injector.get 'combService'
            importContentService = $injector.get 'importContentService'

        hasContentIds: (entity, ids) ->
            id = @getId entity

            storedEntity = @storage[id]
            for itemId in ids
                if itemId in storedEntity.contentIds
                    return true
            false

        init: () ->
            # Operations
            super()

            novaWizard.register 'text',
                type: 'simple'
                action: (data) =>
                    @create
                        type: 'text'
                        value: ""
                        name: $filter('timestampMask')(Date.now(),'DD ofMMMM, hh:mm')
                        projectId: data.projectId
                        combIds: if data.combId then [data.combId]
                        parent: data.parent
                    , (textItem) ->
                        novaDesktop.launchApp
                            app: 'novaTextEditApp'
                            item:
                                type: 'text'
                                id: textItem.id

            novaWizard.register 'folder',
                type: 'simple'
                action: (data) =>
                    @create
                        type: 'folder'
                        name: $filter('timestampMask')(Date.now(),'DD ofMMMM, hh:mm')
                        projectId: data.projectId
                        combIds: if data.combId then [data.combId]
                        parent: data.parent
                    , (folderItem) ->
                        true

            actionsService.registerParser @typeMarker, (item) ->
                types = ['content']
                types

            # !!!
            actionsService.registerAction
                sourceNumber: 1
                sourceType: 'content'
                phrase: 'show_novaInfo'
                check2: (data) =>
                    data.scope.flowBox?
                action: (data) =>
                    data.scope.flowBox.addFlowFrame
                        title: 'info'
                        directive: 'novaInfoFrame'
                        item:
                            id: data.item.id
                            type: data.item.type
                    , data.scope.flowFrame

            actionsService.registerAction
                sourceType: 'content'
                targetType: 'project'
                phrase: 'move_to_project'
                priority: 511
                check2: (data) =>
                    for item in data.items
                        if item.projectId != data.target.id
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        if item.projectId != data.target.id
                            @call 'moveToProject',
                                itemId: item.id
                                projectId: data.target.id

            actionsService.registerAction
                sourceType: 'folder'
                sourceNumber: 'many'
                phrase: 'merge'
                action: (data) =>
                    # cIds = []
                    # for item in data.items
                    #     for id in item.contentIds
                    #         cIds.push id if id not in cIds

                    @call 'mergeFolders', data.ids, (folder) =>
                        buffer.addItem @handleItem folder

            actionsService.registerAction
                phrase: 'new_poll'
                action: (data) =>
                    @create
                        type: 'poll'
                        # value: 'Новый опрос'
                    , (pollItem) ->
                        buffer.addItem pollItem
                        desktopService.launchApp 'pollEdit',
                            pollId: pollItem.id
                            center: true

            actionsService.registerAction
                category: "B"
                sourceType: "folder"
                phrase: "new_poll"
                priority: "66"
                restrict: "rightPanel"
                action: (data) =>
                    @create
                        type: 'poll'
                    , (poll) =>
                        for item in data.items
                            @addContentIds item, [poll.id]

                        desktopService.launchApp 'pollEdit',
                            pollId: poll.id

                        buffer.addItems [poll]

            actionsService.registerAction
                phrase: 'poll_from_text'
                sourceType: 'text'
                action: (data) =>
                    for item in data.items
                        @create
                            type: 'poll'
                            value: item.value
                        , (pollItem) ->
                            desktopService.launchApp 'pollEdit',
                                pollId: pollItem.id
                                center: true

            actionsService.registerAction
                phrase: 'url_from_text'
                sourceType: 'text'
                action: (data) =>
                    urlre = /(\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|!:,.;]*[\-A-Z0-9+&@#\/%=~_|])/ig;

                    for item in data.items
                        urls = item.value.match(urlre)
                        rpc.call 'import.query',
                            provider: 'picUrl'
                            forceUrl: true
                            urls: urls
                        , (urlItems) =>
                            for url in urlItems
                                delete url.id
                                @create url, (readyItem) ->
                                    buffer.addItem readyItem

            novaWizard.register 'contentBrowser',
                type: 'sequence'
                steps: [
                    id: 'project'
                    directive: 'novaWizardProjectPicker'
                    provide: 'projectId'
                ,
                    id: 'picker'
                    directive: 'novaWizardContentPicker'
                    provide: 'contentIds'
                    previewType: 'content'
                    noSkip: true
                    multi: true
                    customPrev: 'novaWizardApp_change_project'
                ]
                final: (data) =>
                    @getByIds data.contentIds, (items) ->
                        data.cb? items, data.contentIds

            novaWizard.register 'importContent',
                type: 'sequence'
                steps: [
                    id: 'import'
                    # directive: 'novaWizardCommunityPicker'
                    series: [
                        id: 'account'
                        directive: 'novaWizardAccountPicker'
                        variable: 'accountPublicId'
                        multi: false
                    ,
                        id: 'community'
                        directive: 'novaWizardCommunityPicker'
                        variable: 'communityId'
                    ,
                        id: 'importAlbum'
                        directive: 'novaWizardImportAlbumPicker'
                        variable: 'albumId'
                    ,
                        id: 'importContent'
                        directive: 'novaWizardImportContentPicker'
                        variable: 'importIds'
                        multi: true
                    ]
                    provide: 'importIds'
                    previewType: 'importContent'
                    multi: true
                ,
                    id: 'project'
                    directive: 'novaWizardProjectPicker'
                    provide: 'projectId'
                ,
                    id: 'final'
                    directive: 'novaWizardImportFinal'
                    customNext: 'novaWizardAction_import'
                ]
                final: (data) =>
                    resultItems = []
                    resultIds = []
                    for id in data.importIds
                        importContentService.import importContentService.storage[id],
                            projectId: data.projectId
                            parent: data.parent
                        , (item) ->
                            # data.cb? item
                            resultItems.push item
                            resultIds.push item.id
                            if resultItems.length == data.importIds.length
                                data.cb? resultItems, resultIds


    new classEntity()
