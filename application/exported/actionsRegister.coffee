buzzlike.service "actionsRegister", (novaDesktop,actionsService,combService,buffer,postService,contentService,desktopService,multiselect,scheduleService,notificationCenter,confirmBox,taskService,localization,ruleService,groupService,importContentService,importAlbumService) ->
    actionsService.registerAction
        category: "C"
        targetType: "comb"
        sourceType: "content"
        phrase: "remove_from_comb"
        priority: "27"
        restrict: "dragndrop"
        check2: (data) ->
            combService.hasContentIds data.target, data.ids
        action: (data) ->
            combService.removeContentIds data.target, data.ids
            buffer.addItems data.items
    actionsService.registerAction
        category: "B"
        targetType: "postPanel"
        sourceType: "content"
        sourceContext: "team"
        phrase: "create_post"
        priority: "68"
        action: (data) ->
            postService.create
                items: data.ids
                combId: data.target.comb.id
            , ->
                true
    actionsService.registerAction
        category: "A"
        targetType: "comb"
        sourceType: "team"
        phrase: "bind_team"
        priority: "200"
        action: (data) ->
            combService.call 'bindTeam',
                id: data.target.id
                teamId: data.items[0].id
    actionsService.registerAction
        category: "A"
        targetType: "comb"
        sourceType: "content"
        phrase: "add_to_comb"
        priority: "87"
        check2: (data) ->
            for item in data.items
                if data.target.contentIds[item.type]?.length > 0
                    if item.id not in data.target.contentIds[item.type]
                        return true
                else
                    return true
            false
        action: (data) ->
            combService.addContentIds data.target, data.ids
    actionsService.registerAction
        category: "A"
        targetType: "comb"
        sourceType: "content"
        phrase: "add_to_every_post"
        priority: "97"
        restrict: ""
        action: (data) ->
            combService.addToEveryPost
                combId: data.target.id
                ids: data.ids
    actionsService.registerAction
        category: "B"
        sourceType: "content"
        phrase: "new_comb"
        priority: "67"
        action: (data) ->
            combService.create
                items: data.ids
            , (comb) ->
                buffer.addItems [comb]
    actionsService.registerAction
        category: "B"
        sourceType: "content"
        phrase: "new_post"
        priority: "88"
        action: (data) ->
            postService.create
                items: data.ids
            , (post) ->
                buffer.addItems [post]
    actionsService.registerAction
        category: "B"
        targetType: "comb"
        sourceType: "content"
        phrase: "new_post_in_comb"
        priority: "99"
        action: (data) ->
            postService.create
                combId: data.target.id
                items: data.ids
            , (post) ->
                buffer.addItems [post]
    actionsService.registerAction
        category: "B"
        sourceType: "content"
        phrase: "new_post_swarm"
        priority: "96"
        action: (data) ->
            combService.swarm
                items: data.ids
            , (comb) ->
                buffer.addItems [comb]
    actionsService.registerAction
        category: "B"
        targetType: "comb"
        sourceType: "content"
        sourceNumber: "many"
        phrase: "new_post_swarm_in_comb"
        priority: "98"
        action: (data) ->
            combService.swarm
                combId: data.target.id
                items: data.ids
            , (comb) ->
                buffer.addItems [comb]
    actionsService.registerAction
        category: "D"
        sourceType: "comb"
        phrase: "duplicate"
        priority: "50"
        leaveItems: true
        action: (data) ->
            for id in data.ids
                combService.duplicate
                    id: id
                , (newComb) ->
                    buffer.addItems [newComb]
    actionsService.registerAction
        category: "A"
        sourceType: "comb"
        phrase: "pick_posts"
        priority: "62"
        action: (data) ->
            postIds = []

            for item in data.items
                postIds = postIds.concat item.postIds

            # Query all posts
            postService.query
                ids: postIds
            , (items) ->
                buffer.addItems items
    actionsService.registerAction
        category: "C"
        sourceType: "comb"
        phrase: "delete"
        priority: "-15"
        action: (data) ->
            combService.deleteByIds data.ids
    actionsService.registerAction
        category: "B"
        sourceType: "comb"
        phrase: "new_text"
        priority: "66"
        action: (data) ->
            contentService.create
                type: 'text'
                value: ""
            , (textItem) =>
                for item in data.items
                    combService.addContentIds item, [textItem.id]

                # textEditor.init textItem, {}
                desktopService.launchApp 'textEditor',
                    textId: textItem.id
    actionsService.registerAction
        category: "D"
        sourceType: "comb"
        phrase: "paste_post"
        priority: "44"
        check2: (data) ->
            if multiselect.state.buffer == null
                return false
            true
        action: (data) ->
            cIds = []
            post = multiselect.state.buffer

            for key,arr of post.contentIds
                for id in arr
                    cIds.push id

            for item in data.items
                postService.create
                    items: cIds
                    combId: item.id
    actionsService.registerAction
        category: "B"
        phrase: "new_comb"
        priority: "67"
        action: (data) ->
            combService.create {}, (newComb) ->
                buffer.addItems [newComb]
    actionsService.registerAction
        category: "B"
        sourceType: "placeholder"
        phrase: "new_comb"
        priority: "67"
        action: (data) ->
            combService.create {}, (newComb) ->
                for item in data.items
                    scheduleService.create
                        items: []
                        communityId: item.communityId
                        timestamp: item.timestamp
                        combId: newComb.id

                desktopService.launchApp 'combEdit',
                    combId: newComb.id
    actionsService.registerAction
        category: "A"
        sourceType: "folder"
        contextType: "rightPanel"
        phrase: "open_folder"
        priority: "86"
        only: "contextMenu"
        action: (data) ->
            desktopService.launchApp 'content',
                folderId: data.item.id
    actionsService.registerAction
        category: "C"
        sourceType: "content"
        phrase: "delete"
        priority: "25"
        action: (data) ->
            if data.target?.type == 'folder'
                contentService.removeContentIds data.target, data.ids

            if data.target?.type == 'comb'
                combService.removeContentIds data.target, data.ids

            # if folderView.state?.currentFolder?
            #     for item in data.items
            #         if item.type == 'folder'
            #             if item.id == folderView.state?.currentFolder.id
            #                 folderView.close()
            #                 break

            buffer.removeItems data.items

            contentService.deleteByIds data.ids, (result) ->
                if result == true
                    notificationCenter.addMessage
                        text: 126
    actionsService.registerAction
        category: "D"
        sourceType: "content"
        phrase: "duplicate"
        priority: "50"
        leaveItems: true
        check2: (data) ->
            for item in data.items
                if item.type in ['text','folder']
                    return true
            false
        action: (data) ->
            for item in data.items
                if item.type in ['text','folder']
                    contentService.duplicate item, (duplicate) ->
                        buffer.addItems [duplicate]
    actionsService.registerAction
        category: "A"
        targetType: "folder"
        sourceType: "content"
        phrase: "add_to_folder"
        priority: "85"
        check2: (data) ->
            for item in data.items
                if item.parent != data.target.id
                    return true
            false
        action: (data) ->
            contentService.addContentIds data.target, data.ids, (result) ->
                notificationCenter.addMessage
                    text: 39
    actionsService.registerAction
        category: "C"
        targetType: "folder"
        sourceType: "content"
        phrase: "remove_from_folder"
        priority: "26"
        leaveItems: true
        restrict: "dragndrop"
        check2: (data) ->
            for item in data.items
                if item.parent?
                    return true
            false
        action: (data) ->
            contentService.removeContentIds data.target, data.ids, (result) ->
                buffer.addItems data.items
                notificationCenter.addMessage
                    text: 41
    actionsService.registerAction
        category: "B"
        sourceType: "folder"
        phrase: "new_text"
        priority: "66"
        restrict: "rightPanel"
        action: (data) ->
            contentService.create
                type: 'text'
                value: ""
            , (text) =>
                for item in data.items
                    contentService.addContentIds item, [text.id]

                desktopService.launchApp 'textEditor',
                    textId: text.id

                buffer.addItems [text]
    actionsService.registerAction
        category: "B"
        phrase: "new_text"
        priority: "66"
        restrict: "rightPanel"
        action: (data) ->
            contentService.create
                type: 'text'
                value: ""
            , (text) =>
                desktopService.launchApp 'textEditor',
                    textId: text.id

                buffer.addItems [text]
    actionsService.registerAction
        category: "B"
        targetType: "content"
        sourceType: "content"
        sourceContext: "rightPanel"
        contextType: "rightPanel"
        phrase: "new_folder"
        only: "dragndrop"
        check2: (data) ->
            if data.target.type == 'folder'
                return false
            for item in data.items
                if item.type == 'folder'
                    return false
            true
        action: (data) ->
            ids = []
            ids.push data.target.id

            for id in data.ids
                ids.push id if id not in ids

            contentService.create
                type: 'folder'
                items: ids
                parent: data.items[0].parent
            , (newFolder) ->
                buffer.addItems [newFolder]
                buffer.removeItems [data.target]
    actionsService.registerAction
        category: "C"
        sourceType: "taskAdmin"
        phrase: "delete"
        action: (data) ->
            cnt = data.ids.length
            novaDesktop.launchApp
                app: 'novaOptionsListApp'
                noSave: true
                data:
                    realText: localization.translate('teamManager_confirm_task_delete') + ' ' + cnt + ' ' + localization.declensionPhrase(cnt, 'teamManager_confirm_task_delete_declension') + '?'
                    description: 'teamManager_confirm_task_delete_description'
                    onAccept: =>
                        taskService.deleteByIds data.ids, ->
                            true

            # confirmBox.init
            #     realText: localization.translate('teamManager_confirm_task_delete') + ' ' + cnt + ' ' + localization.declensionPhrase(cnt, 'teamManager_confirm_task_delete_declension') + '?'
            #     description: 'teamManager_confirm_task_delete_description'
            # , =>
            #     taskService.deleteByIds data.ids, ->
            #         true
            #     true
            # , ->
            #     true
    actionsService.registerAction
        category: "A"
        sourceType: "taskAdmin"
        sourceNumber: "many"
        phrase: "tasks_merge"
        priority: "500"
        check2: (data) ->
            team = data.item.teamId

            for item in data.items
                if item.teamId != team
                    return false

            true
        action: (data) ->
            userIds = []
            for item in data.items
                for userId in item.users
                    userIds.push userId if userId not in userIds

            taskService.create
                name: 'Объединенные задачи'
                users: userIds
                teamId: data.items[0].teamId
                parent: if data.target?.type == 'task' then data.target.id else data.item.parent
                status: 'created'
            , (newTask) =>

                for item in data.items
                    taskService.save
                        id: item.id
                        parent: newTask.id
                    , ->
                        true
    actionsService.registerAction
        sourceType: "activeDesktop"
        phrase: "change_wallpaper"
        action: (data) ->
            desktopService.launchApp 'settings',
                section: 'appearance'
    actionsService.registerAction
        category: "C"
        sourceType: "placeholder"
        phrase: "delete"
        action: (data) ->
            simpleDelete = false

            actions = [
                {
                    text: 'remove_one'
                    action: () ->
                        ruleService.removePlaceholders data.items
                        true
                },
                {
                    text: 'remove_chain'
                    action: () ->
                        for item in placeholders
                            item.cut = true
                        ruleService.removePlaceholders data.items, true
                        true
                }
            ]

            for item in data.items
                if item.ruleType == 'single'
                    simpleDelete = true

            if simpleDelete
                actions = [
                    {
                        text: 'remove_one'
                        action: () ->
                            ruleService.removePlaceholders data.items
                            true
                    }
                ]

            desktopService.launchApp 'optionsList',
                message: 'post_delete_question'
                options: actions
    actionsService.registerAction
        category: "B"
        sourceType: "myCommunity"
        phrase: "create_feedGroup"
        action: (data) ->
            newGroup =
                type: 'group'
                name: 'new_group'
                feeds: []

            for community in data.items
                newGroup.feeds.push
                    status: 'Writable'
                    communityId: community.id
                    statusAsInt: 1

            groupService.create newGroup
    actionsService.registerAction
        category: "B"
        sourceType: "importContent"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importContentService.import item, (imported) ->
                    buffer.addItem imported
    actionsService.registerAction
        category: "B"
        sourceType: "importContent"
        phrase: "import_to_folder"
        action: (data) ->
            date = new Date()
            contentService.create
                type: 'folder'
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (folder) ->
                for item in data.items
                    importContentService.import item, (imported) ->
                        contentService.addContentIds folder, [imported.id]
                buffer.addItem folder
    actionsService.registerAction
        category: "B"
        sourceType: "importAlbum"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importAlbumService.import item, (folder) ->
                    buffer.addItem folder
    actionsService.registerAction
        category: "B"
        sourceType: "importAlbum"
        sourceNumber: "many"
        phrase: "import_to_folder"
        action: (data) ->
            date = new Date()
            contentService.create
                type: 'folder'
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (folder) ->
                for item in data.items
                    importAlbumService.import item, (imported) ->
                        contentService.addContentIds folder, [imported.id]
                buffer.addItem folder
    actionsService.registerAction
        category: "B"
        sourceType: "importContent"
        phrase: "import_to_new_comb"
        action: (data) ->
            date = new Date()
            combService.create
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (comb) ->
                for item in data.items
                    importContentService.import item, (imported) ->
                        combService.addContentIds comb, [imported.id]
                buffer.addItem comb
    actionsService.registerAction
        category: "B"
        sourceType: "importAlbum"
        phrase: "import_to_new_comb"
        action: (data) ->
            date = new Date()
            combService.create
                name: if data.items.length == 1 then data.item.title else 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (comb) ->
                for item in data.items
                    importAlbumService.import item, (imported) ->
                        combService.addContentIds comb, [imported.id]
                buffer.addItem comb
    actionsService.registerAction
        category: "B"
        sourceType: "importContent"
        phrase: "import_to_new_post"
        action: (data) ->
            date = new Date()
            postService.create
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (post) ->
                for item in data.items
                    importContentService.import item, (imported) ->
                        postService.addContentIds post, [imported.id]
                buffer.addItem post
    actionsService.registerAction
        category: "B"
        sourceType: "importContent"
        sourceNumber: "many"
        phrase: "import_to_swarm"
        action: (data) ->
            date = new Date()
            combService.create
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (comb) ->
                for item in data.items
                    importContentService.import item, (imported) ->
                        postService.create
                            combId: comb.id
                            items: [imported.id]
                buffer.addItem comb
    actionsService.registerAction
        category: "A"
        targetType: "comb"
        sourceType: "importContent"
        phrase: "import_to_comb"
        action: (data) ->
            for item in data.items
                importContentService.import item, (imported) ->
                    combService.addContentIds data.target, [imported.id]
    actionsService.registerAction
        category: "A"
        targetType: "comb"
        sourceType: "importAlbum"
        phrase: "import_to_comb"
        action: (data) ->
            for item in data.items
                importAlbumService.import item, (imported) ->
                    combService.addContentIds data.target, [imported.id]
    actionsService.registerAction
        category: "A"
        targetType: "folder"
        sourceType: "importContent"
        phrase: "import_to_folder"
        action: (data) ->
            for item in data.items
                importContentService.import item, (imported) ->
                    contentService.addContentIds data.target, [imported.id]
    actionsService.registerAction
        category: "A"
        targetType: "folder"
        sourceType: "importAlbum"
        phrase: "import_to_folder"
        action: (data) ->
            for item in data.items
                importAlbumService.import item, (imported) ->
                    contentService.addContentIds data.target, [imported.id]
    actionsService.registerAction
        category: "B"
        targetType: "contentApp"
        sourceType: "importContent"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importContentService.import item
    actionsService.registerAction
        category: "B"
        targetType: "contentApp"
        sourceType: "importAlbum"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importAlbumService.import item
    actionsService.registerAction
        category: "B"
        targetType: "combsApp"
        sourceType: "importAlbum"
        phrase: "import_to_new_comb"
        action: (data) ->
            date = new Date()
            combService.create
                name: if data.items.length == 1 then data.item.title else 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (comb) ->
                for item in data.items
                    importAlbumService.import item, (imported) ->
                        combService.addContentIds comb, [imported.id]

    actionsService.registerAction
        category: "B"
        targetType: "combsApp"
        sourceType: "importContent"
        phrase: "import_to_new_comb"
        action: (data) ->
            date = new Date()
            combService.create
                name: 'Импорт ' + date.getDay() + '.' + (date.getMonth() + 1) + '.' + date.getFullYear()
            , (comb) ->
                for item in data.items
                    importContentService.import item, (imported) ->
                        combService.addContentIds comb, [imported.id]
    actionsService.registerAction
        category: "B"
        targetType: "rightPanel"
        sourceType: "importAlbum"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importAlbumService.import item, (folder) ->
                    buffer.addItem folder
    actionsService.registerAction
        category: "B"
        targetType: "rightPanel"
        sourceType: "importContent"
        phrase: "import"
        action: (data) ->
            for item in data.items
                importContentService.import item, (imported) ->
                    buffer.addItem imported
    actionsService.registerAction
        category: "B"
        targetType: "timeline/placeholder"
        sourceType: "importContent"
        phrase: "import_to_scheduled_post"
        action: (data) ->
            postService.create {}, (post) ->
                scheduleService.create
                    postId: post.id
                    communityId: data.target.communityId
                    timestamp: data.target.timestamp

                for item in data.items
                    importContentService.import item, (imported) ->
                        postService.addContentIds post, [imported.id]
    actionsService.registerAction
        category: "A"
        targetType: "post"
        sourceType: "importContent"
        phrase: "import_to_post"
        action: (data) ->
            for item in data.items
                importContentService.import item, (imported) ->
                    postService.addContentIds data.target, [imported.id]
    actionsService.registerAction
        category: "C"
        targetType: "task"
        sourceType: "content"
        phrase: "task_remove_bounded"
        restrict: "dragndrop"
        check2: (data) ->
            if data.target.entities.length == 0
                return false

            for id in data.ids
                for targetItem in data.target.entities
                    if id == targetItem.id
                        return true
            false
        action: (data) ->
            taskService.call 'removeEntity',
                taskId: data.target.id
                entityIds: data.ids
            , ->
                true
    actionsService.registerAction
        category: "B"
        sourceType: "content"
        phrase: "new_folder"
        priority: "64"
        action: (data) ->
            contentService.create
                type: 'folder'
                items: data.ids
                parent: data.items[0].parent
            , (newFolder) ->
                buffer.addItems [newFolder]
