*deps: projectService, novaBuffer, novaWizard, $filter, taskService, desktopService, actionsService, multiselect, rpc, itemService, postService, contentService, scheduleService, buffer, contextMenu

class classEntity extends itemService

    itemType: 'comb'

    isCombPost: (comb) ->
        if comb.postIds?.length != 1
            return false

        postId = comb.postIds[0]
        post = postService.getById postId
        for type of comb.contentIds
            for i in comb.contentIds[type]
                if post.contentIds?
                    if not (i in post.contentIds[type])
                        return false
        true

    swarm: (data, cb) ->
        rpc.call 'comb.swarm', data, (comb) ->
            cb? comb

    addToEveryPost: (data, cb) ->
        rpc.call 'comb.addToEveryPost', data, (result) ->
            cb? result

    init: () ->
        # Operations
        super()

        actionsService.registerAction
            sourceType: 'comb'
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
            sourceType: 'content'
            phrase: 'new_comb'
            targetType: 'combsApp'
            action: (data) =>
                @create
                    items: data.ids
                , (comb) ->
                    buffer.addItem comb

        actionsService.registerAction
            sourceType: 'content'
            phrase: 'new_post'
            targetType: 'combsApp'
            action: (data) =>
                postService.create
                    items: data.ids
                , (post) ->
                    buffer.addItem post

        actionsService.registerAction
            sourceType: 'content'
            sourceNumber: 'many'
            phrase: 'new_post_swarm'
            targetType: 'combsApp'
            action: (data) =>
                @swarm
                    items: data.ids
                , (comb) ->
                    buffer.addItems [comb]

        actionsService.registerAction
            sourceType: 'comb'
            sourceNumber: 1
            phrase: 'unbind_comb_team'
            check2: (data) ->
                data.item.teamId?
            action: (data) =>
                @.call 'unbindTeam', data.item.id


        actionsService.registerAction
            sourceType: 'comb'
            targetType: 'team/task'
            phrase: 'create_comb_posts_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                for comb in data.items
                    rpc.call 'smartActions.combPostsTask',
                        combId: comb.id
                        teamId: teamId
                        parent: taskId
                    , (res) ->
                        true

        actionsService.registerAction
            sourceType: 'comb'
            targetType: 'team/task'
            phrase: 'create_comb_task_content'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                for comb in data.items
                    taskService.create
                        name: 'Собрать материалы в теме ' + quoteIfExists comb.name
                        status: 'created'
                        parent: taskId
                        teamId: teamId
                        entities: [
                            type: 'comb'
                            id: comb.id
                        ]

        actionsService.registerAction
            sourceType: 'comb'
            targetType: 'team/task'
            phrase: 'create_comb_posts_fill_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                for comb in data.items
                    rpc.call 'smartActions.combPostsTask',
                        taskName: 'Наполнить посты темы'
                        combId: comb.id
                        teamId: teamId
                        parent: taskId
                    , (res) ->
                        true

        actionsService.registerAction
            sourceType: 'content'
            targetType: 'team/task'
            phrase: 'create_content_gather_similar_in_comb'
            category: 'T'
            check2: (data) ->
                if !data.target.id?
                    return false
                true
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                rpc.call 'smartActions.combSimilarTask',
                    items: data.ids
                    teamId: teamId
                    parent: taskId

        actionsService.registerAction
            sourceType: 'post'
            sourceNumber: 'many'
            targetType: 'team/task'
            phrase: 'create_posts_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                rpc.call 'smartActions.postsMultiTask',
                    postIds: data.ids
                    teamId: teamId
                    parent: taskId

        actionsService.registerAction
            sourceType: 'postSchedule'
            sourceNumber: 'many'
            targetType: 'team/task'
            phrase: 'create_posts_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                postIds = []
                for sched in data.items
                    postIds.push sched.postId

                rpc.call 'smartActions.postsMultiTask',
                    postIds: postIds
                    teamId: teamId
                    parent: taskId

        actionsService.registerAction
            sourceType: 'post'
            sourceNumber: 1
            targetType: 'team/task'
            phrase: 'create_posts_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                scheduleService.getOriginalByPostId data.item.id, (sched) ->
                    if sched?
                        taskName = "Подготовить пост на " + $filter('timestampMask')(sched.timestamp, "hh:mm DD.MM.YYYY")
                    else
                        taskName = "Подготовить пост"

                    taskService.create
                        name: taskName
                        parent: taskId
                        teamId: teamId
                        status: 'created'
                        entities: [
                            type: 'post'
                            id: data.item.id
                        ]

        actionsService.registerAction
            sourceType: 'postSchedule'
            sourceNumber: 1
            targetType: 'team/task'
            phrase: 'create_posts_ext_tasks'
            category: 'T'
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                taskName = "Подготовить пост на " + $filter('timestampMask')(data.item.timestamp, "hh:mm DD.MM.YYYY")

                taskService.create
                    name: taskName
                    parent: taskId
                    teamId: teamId
                    status: 'created'
                    entities: [
                        type: 'post'
                        id: data.item.postId
                    ]

        actionsService.registerAction
            sourceType: 'comb'
            sourceContext: 'project'
            phrase: 'pin_comb'
            check2: (data) ->
                if !data.sourceContext.modules?.combs?.pinned?
                    return true

                for id in data.ids
                    if id not in data.sourceContext.modules.combs.pinned
                        return true
                false
            action: (data) =>
                projectService.pushModuleData data.sourceContext.id, 'combs', 'pinned', data.ids

        actionsService.registerAction
            sourceType: 'comb'
            sourceContext: 'project'
            phrase: 'unpin_comb'
            check2: (data) ->
                console.log data
                if !data.sourceContext.modules?.combs?.pinned?
                    return false

                for id in data.ids
                    if id in data.sourceContext.modules.combs.pinned
                        return true
                false
            action: (data) =>
                projectService.pullModuleData data.sourceContext.id, 'combs', 'pinned', data.ids

        actionsService.registerAction
            sourceType: 'content'
            targetType: 'team/task'
            phrase: 'create_comb_content_posts_task'
            category: 'T'
            check2: (data) ->
                if !data.target.id?
                    return false
                true
            action: (data) ->
                teamId = if data.target.type == 'team' then data.target.id else data.target.teamId
                taskId = if data.target.type == 'task' then data.target.id else undefined

                rpc.call 'smartActions.combContentTask',
                    items: data.ids
                    teamId: teamId
                    parent: taskId

        novaWizard.register 'theme',
                type: 'sequence'
                steps: [
                    id: 'project'
                    directive: 'novaWizardProjectPicker'
                    provide: 'projectId'
                    previewType: 'project'
                ,
                    id: 'final'
                    directive: 'novaWizardThemeCreate'
                    customNext: 'novaWizardAction_create'
                ]
                final: (data) =>
                    @create
                        name: data.name
                        projectId: data.projectId
                    , (comb) ->
                        novaBuffer.addItems [comb]

        # contextMenu.registerAction
        #     state: 'inComb'
        #     type: 'content'
        #     name: 'addeverypostanddescription'
        #     check: (items) ->
        #         if items.length == 1
        #             if items[0].type == 'text'
        #                 return true
        #         false
        #     handler: @addContentEveryPostAndDescriptions

        # System

    # Handlers


    # addContentEveryPostAndDescriptions: (ids) =>
    #     @addToEveryPost
    #         combId: combEdit.state.currentComb.id
    #         ids: ids
    #         descriptions: true
    #     # for postId in combEdit.state.currentComb.postIds
    #     #     postService.addContentIds postId, ids

    #     'all'

new classEntity()
