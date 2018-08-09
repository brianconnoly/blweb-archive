buzzlike.service 'userService', (novaWizard, itemService, rpc, contextMenu, actionsService, updateService, account, projectService, taskService, postService, desktopService) ->

    class classEntity extends itemService

        itemType: 'user'

        init: ->
            super()

            novaWizard.register 'welcome',
                system: true
                type: 'sequence'
                steps: [
                    id: 'welcome' # Приветствуем вас в чудо-юде
                    directive: 'novaWizardWelcome'
                ,
                    id: 'license' # Оферта
                    directive: 'novaWizardWelcomeLicense'
                    provide: 'license_accepted'
                ,
                    id: 'personal' # Личные данные
                    directive: 'novaWizardWelcomePersonal'
                ,
                    id: 'migrating' # Перенос данных
                    directive: 'novaWizardWelcomeMigrating'
                    provide: 'complete'
                ,
                    id: 'final' # Готово
                    directive: 'novaWizardWelcomeFinal'
                ]

            userEditor = (user, project) ->
                if project.userId == user.id
                    return true
                for member in project.members
                    if member.userId == user.id
                        if member.role in ['mainEditor', 'editor']
                            return true
                        break
                false

            userMainEditor = (user, project) ->
                if project.userId == user.id
                    return true
                for member in project.members
                    if member.userId == user.id
                        if member.role == 'mainEditor'
                            return true
                        break
                false

            getUserRoles = (user, project) ->
                for member in project.members
                    if member.userId == user.id
                        return member.role
                null

            makeEntities = (items) ->
                for item in items
                    type: item.type
                    id: item.id

            actionsService.registerParser 'user', (item) ->
                if account.user.id == item.id
                    return ['userMe']
                else
                    return ['userNotMe']

            # Responsible executor
            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'task'
                sourceNumber: 1
                target: 'task'
                phrase: 'make_executor'
                check2: (data) ->
                    if data.target.executor == data.items[0].id
                        return false
                    true
                action: (data) ->
                    if data.target.id?
                        taskService.call 'setExecutor',
                            taskId: data.target.id
                            userId: data.items[0].id
                    else
                        data.target.executor = data.items[0].id

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'task'
                sourceNumber: 1
                target: 'task'
                phrase: 'remove_executor'
                check2: (data) ->
                    if data.target.executor == data.items[0].id
                        return true
                    false
                action: (data) ->
                    if data.target.id?
                        taskService.call 'removeExecutor',
                            taskId: data.target.id
                            # executor: '_null'
                    else
                        data.target.executor = null

            actionsService.registerAction
                sourceType: 'task'
                phrase: 'take_task'
                check2: (data) ->
                    notInTask = false
                    id = account.user.id
                    for task in data.items
                        if id not in task.users
                            notInTask = true

                    if !notInTask
                        return false

                    if data.target?.userId == account.user.id
                        return true

                    console.log data.context, data
                    if data.context?.type == 'project'
                        return userEditor account.user, data.context
                action: (data) =>
                    for id in data.ids
                        taskService.call 'addUsers',
                            taskId: id
                            users: [account.user.id]
                        , ->
                            true

            actionsService.registerAction
                sourceType: 'text'
                targetType: 'project/task'
                phrase: 'create_tasks_from_text'
                action: (data) ->
                    for item in data.items
                        taskService.create
                            name: item.name or item.value.substring 0, 300
                            description: item.value
                            status: 'created'
                            projectId: if data.target.type == 'project' then data.target.id else data.target.projectId
                            parent: if data.target.type == 'project' then null else data.target.id

            # Перетаскиваем пользователей на разные штуки
            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                targetType: 'postPanel'
                phrase: 'create_new_post_task'
                priority: 501
                action: (data) =>
                    postService.create
                        combId: data.target.comb.id
                    , (createdPost) =>
                        taskService.create
                            projectId: data.sourceContext.id
                            users: data.ids
                            status: 'created'
                            entities: [
                                id: createdPost.id
                                type: createdPost.type
                            ]
                            name: 'Сформировать пост'
                        , (createdTask) ->
                            desktopService.launchApp 'teamManager',
                                taskId: createdTask.id

            actionsService.registerAction
                sourceType: 'image'
                sourceNumber: 1
                targetType: 'user'
                phrase: 'set_avatar'
                check2: (data) -> data.target.id == account.user.id
                action: (data) =>
                    account.set
                        photo: data.item.thumbnail
                    , (user) =>
                        @handleItem user

            actionsService.registerAction
                sourceType: 'task'
                targetType: 'task/teamAdmin'
                phrase: 'put_tasks_into_task'
                action: (data) ->
                    cnt = 0
                    for task in data.items
                        taskService.call 'setParent',
                            taskId: task.id
                            parent: if data.target.type == 'task' then data.target.id else null
                        , ->

                            # taskService.save
                            #     id: task.id
                            #     parent: if data.target.type == 'task' then data.target.id else null
                            #     projectId: if data.target.type == 'task' then data.target.projectId else data.target.id
                            # , ->
                            cnt++
                            if cnt == data.items.length
                                updateService.triggerUpdate [
                                        type: 'task'
                                        projectId: if data.target.type == 'task' then data.target.projectId else data.target.id
                                ]
                            true

            actionsService.registerAction
                sourceType: 'taskAdmin'
                phrase: 'open_task_in_new_window'
                category: "A"
                action: (data) ->
                    for task in data.items
                        desktopService.launchApp 'teamManager',
                            taskId: task.id
                            # projectId: task.projectId

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                targetType: 'postPanel'
                phrase: 'create_comb_posts_task'
                priority: 502
                action: (data) =>
                    taskService.create
                        projectId: data.sourceContext.id
                        users: data.ids
                        status: 'created'
                        entities: [
                            id: data.target.comb.id
                            type: data.target.comb.type
                        ]
                        name: 'Сформировать посты в теме'
                    , (createdTask) ->
                        desktopService.launchApp 'teamManager',
                            task: createdTask

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                targetType: 'post'
                phrase: 'create_post_task'
                priority: 503
                action: (data) =>
                    taskService.create
                        projectId: data.sourceContext.id
                        users: data.ids
                        status: 'created'
                        entities: [
                            id: data.target.id
                            type: data.target.type
                        ]
                        name: 'Сформировать пост'
                    , (createdTask) ->
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            actionsService.registerAction
                targetType: 'comb'
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'create_comb_task'
                priority: 504
                action: (data) =>
                    taskService.create
                        projectId: data.sourceContext.id
                        users: data.ids
                        status: 'created'
                        entities: [
                            id: data.target.id
                            type: data.target.type
                        ]
                        name: 'Подготовить материалы'
                    , (createdTask) ->
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            # Перетаскивание на пользователей в оверлее команд
            actionsService.registerAction
                sourceType: 'content'
                targetType: 'user'
                contextType: 'task/project'
                phrase: 'create_content_task'
                priority: 505
                action: (data) =>
                    taskService.create
                        projectId: data.context.projectId or data.context.id
                        parent: if data.context.type == 'task' then data.context.id
                        name: 'Подготовить контент'
                        entities: makeEntities data.items
                        status: 'created'
                        users: [data.target.id]
                    , (createdTask) ->
                        # Open task editor
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            actionsService.registerAction
                sourceType: 'comb'
                targetType: 'user'
                contextType: 'task/project'
                phrase: 'create_comb_task'
                priority: 504
                action: (data) =>
                    taskService.create
                        projectId: data.context.projectId or data.context.id
                        parent: if data.context.type == 'task' then data.context.id
                        name: 'Подготовить комб' + if data.items.length > 1 then 'ы' else ''
                        entities: makeEntities data.items
                        status: 'created'
                        users: [data.target.id]
                    , (createdTask) ->
                        # Open task editor
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            actionsService.registerAction
                sourceType: 'post'
                targetType: 'user'
                contextType: 'task/project'
                phrase: 'create_post_task'
                priority: 503
                action: (data) =>
                    taskService.create
                        projectId: data.context.projectId or data.context.id
                        parent: if data.context.type == 'task' then data.context.id
                        name: 'Подготовить пост' + if data.items.length > 1 then 'ы' else ''
                        entities: makeEntities data.items
                        status: 'created'
                        users: [data.target.id]
                    , (createdTask) ->
                        # Open task editor
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            # Перетаскивание пользователей на контент в комбе
            actionsService.registerAction
                targetType: 'content'
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'create_content_task_in_comb'
                priority: 506
                action: (data) =>
                    taskName = "Новая задача"
                    switch data.target.type
                        when 'text'
                            taskName = "Написать текст"
                        when 'image'
                            taskName = 'Подготовить картинку'
                        when 'audio'
                            taskName = 'Подготовить аудиозапись'
                        when 'video'
                            taskName = 'Подготовить видео'
                        when 'url'
                            taskName = 'Подготовить ссылку'

                    taskService.create
                        projectId: data.sourceContext.id
                        users: data.ids
                        entities: [
                            id: data.target.id
                            type: data.target.type
                        ]
                        status: 'created'
                        name: taskName
                    , (createdTask) ->
                        # Open task editor
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id


            actionsService.registerAction
                targetType: 'user'
                sourceType: 'task'
                phrase: 'bind_tasks_to_user'
                priority: 507
                action: (data) =>
                    for task in data.items
                        taskService.call 'addUsers',
                            taskId: task.id
                            users: [data.target.id]
                        , -> true

            actionsService.registerAction
                sourceType: 'user'
                # sourceContext: 'project'
                targetType: 'task'
                phrase: 'team_member_bind_to_task'
                priority: 508
                check2: (data) ->
                    notInTask = false
                    for id in data.ids
                        if id not in data.target.users
                            notInTask = true
                            break

                    if !notInTask
                        return false

                    if data.target.userId == account.user.id
                        return true

                    if data.context?.type == 'project'
                        return userEditor account.user, data.context
                action: (data) =>
                    taskService.call 'addUsers',
                        taskId: data.target.id
                        users: data.ids
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                # sourceContext: 'project'
                targetType: 'task'
                phrase: 'team_member_create_subtask'
                priority: 510
                check2: (data) ->
                    if data.target.userId == account.user.id
                        return true

                    if data.context?.type == 'project'
                        userEditor account.user, data.context
                action: (data) =>
                    taskService.create
                        name: 'Новая задача'
                        description: ''
                        projectId: data.context?.id
                        parent: data.target.id
                        users: data.ids
                        status: 'created'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                targetType: 'project'
                phrase: 'team_member_create_task'
                priority: 511
                check: (ids, data, context) =>
                    userEditor account.user, context
                action: (data) =>
                    taskService.create
                        name: 'Новая задача'
                        description: ''
                        projectId: data.sourceContext.id
                        users: data.ids
                        status: 'created'
                    , (createdTask) ->
                        desktopService.launchApp 'teamManager',
                            taskId: createdTask.id

            actionsService.registerAction
                sourceType: 'user'
                sourceNumber: 1
                sourceContext: 'project'
                phrase: 'team_member_make_mainEditor'
                priority: 210
                check2: (data) ->
                    project = data.sourceContext

                    if !project?
                        return false

                    if project.userId != account.user.id
                        return false
                    if data.items[0].id == project.userId
                        return false
                    for user in project.members
                        if user.roles?.mainEditor == true
                            return false
                    true
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'mainEditor'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_make_editor'
                priority: 209
                check2: (data) ->
                    project = data.sourceContext

                    if project?.type != 'project'
                        return false

                    if data.items.length == 1 and data.items[0].id == account.user.id
                        return false
                    if data.items.length == 1 and data.items[0].id == project.userId
                        return false

                    userMainEditor account.user, project
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'editor'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_make_contentManager'
                priority: 208
                check2: (data) ->
                    project = data.sourceContext

                    if project?.type != 'project'
                        return false

                    if !userEditor account.user, project
                        return false

                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == project.userId
                            return false

                    if account.user.id == project.userId
                        return true

                    myRoles = getUserRoles account.user, project
                    for member in project.members
                        if member.userId in data.ids
                            if member.roles?.mainEditor
                                return false
                            if member.roles?.editor and myRoles != 'mainEditor'
                                return false
                    true
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'contentManager'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_make_timeManager'
                priority: 207
                check2: (data) ->
                    project = data.sourceContext

                    if !project?
                        return false

                    if !userEditor account.user, project
                        return false

                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == project.userId
                            return false

                    if account.user.id == project.userId
                        return true

                    myRoles = getUserRoles account.user, project
                    for member in project.members
                        if member.userId in data.ids
                            if member.roles?.mainEditor
                                return false
                            if member.roles?.editor and myRoles != 'mainEditor'
                                return false
                    true
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'timeManager'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_make_client'
                priority: 207
                check2: (data) ->
                    project = data.sourceContext

                    if !project?
                        return false

                    if !userEditor account.user, project
                        return false

                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == project.userId
                            return false

                    if account.user.id == project.userId
                        return true

                    myRoles = getUserRoles account.user, project
                    for member in project.members
                        if member.userId in data.ids
                            if member.roles?.mainEditor
                                return false
                            if member.roles?.editor and myRoles != 'mainEditor'
                                return false
                    true
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'client'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_make_postManager'
                priority: 206
                check2: (data) ->
                    project = data.sourceContext

                    if !project?
                        return false

                    if !userEditor account.user, project
                        return false

                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == project.userId
                            return false

                    if account.user.id == project.userId
                        return true

                    myRoles = getUserRoles account.user, project
                    for member in project.members
                        if member.userId in data.ids
                            if member.roles?.mainEditor
                                return false
                            if member.roles?.editor and myRoles != 'mainEditor'
                                return false
                    true
                action: (data) =>
                    projectService.call 'setMembersRole',
                        projectId: data.sourceContext.id
                        users: data.ids
                        role: 'postManager'
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_remove_roles'
                priority: 205
                check2: (data) ->
                    project = data.sourceContext

                    if !project?
                        return false

                    if !userEditor account.user, project
                        return false

                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == project.userId
                            return false

                    if account.user.id == project.userId
                        return true

                    myRoles = getUserRoles account.user, project
                    for member in project.members
                        if member.userId in data.ids
                            if member.roles?.mainEditor
                                return false
                            if member.roles?.editor and myRoles != 'mainEditor'
                                return false
                    true
                action: (data) =>
                    projectService.call 'removeRoles',
                        projectId: data.sourceContext.id
                        users: data.ids
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'task'
                phrase: 'remove_user_from_task'
                priority: 204
                check2: (data) ->
                    notInTask = true
                    for id in data.ids
                        if id in data.target.users
                            notInTask = false
                            break
                    if notInTask
                        return false

                    if data.target.userId == account.user.id
                        return true

                    if data.target.projectId?
                        project = projectService.getById data.target.projectId
                        if !project.type?
                            return false
                        userEditor account.user, project

                action: (data) =>
                    taskService.call 'removeUsers',
                        taskId: data.target.id
                        users: data.ids
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'user'
                sourceContext: 'project'
                phrase: 'team_member_remove'
                priority: 203
                check2: (data) ->
                    if data.items.length == 1
                        if data.items[0].id == account.user.id or data.items[0].id == data.sourceContext.userId
                            return false

                    userMainEditor account.user, data.sourceContext
                action: (data) =>
                    projectService.call 'removeMembers',
                        projectId: data.sourceContext.id
                        users: data.ids
                    , ->
                        true

            actionsService.registerAction
                sourceType: 'taskStarted'
                phrase: 'task_unstart'
                category: 'T'
                action: (data) ->
                    for item in data.items
                        taskService.call 'setStatus',
                            taskId: item.id
                            status: 'created'

            actionsService.registerAction
                sourceType: 'taskFinished'
                phrase: 'task_unfinish'
                category: 'T'
                action: (data) ->
                    for item in data.items
                        taskService.call 'setStatus',
                            taskId: item.id
                            status: 'started'

            actionsService.registerAction
                sourceType: 'taskFinished'
                phrase: 'task_accept'
                category: 'T'
                action: (data) ->
                    for item in data.items
                        taskService.call 'setStatus',
                            taskId: item.id
                            status: 'accepted'

            actionsService.registerAction
                sourceType: 'taskFinished'
                phrase: 'task_reject'
                category: 'T'
                action: (data) ->
                    for item in data.items
                        taskService.call 'setStatus',
                            taskId: item.id
                            status: 'rejected'

            actionsService.registerAction
                sourceType: 'taskAccepted'
                phrase: 'task_unaccept'
                category: 'T'
                action: (data) ->
                    for item in data.items
                        taskService.call 'setStatus',
                            taskId: item.id
                            status: 'finished'


    new classEntity()
