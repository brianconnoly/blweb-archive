buzzlike.service 'postService', (novaWizard, novaDesktop, notificationCenter, confirmBox, taskService, desktopService, groupService, actionsService, account, ruleService, lotService, $injector, tableImport, inspectorService, smartDate, multiselect, itemService, rpc, buffer, contextMenu, scheduleService, contentService) ->

    class classEntity extends itemService

        itemType: 'post'

        requestService  = null

        constructor: () ->
            super()
            @byUgcId = {}
            @byCombId = {}

        initDeps: () ->
            requestService  = $injector.get 'requestService'

        getByCombId: (combId, cb) ->
            if !@byCombId[combId]?
                @byCombId[combId] = []
                @query
                    combId: combId
                , (result) ->
                    cb? @byCombId[combId]
            else
                cb? @byCombId[combId]
            @byCombId[combId]

        getByUgcId: (ugcId, cb) ->
            if !@byUgcId[ugcId]?
                @byUgcId[ugcId] = []
                @query
                    proposedTo: ugcId
                , (result) ->
                    cb? @byUgcId[ugcId]
            else
                cb? @byUgcId[ugcId]
            @byUgcId[ugcId]

        removeCache: (id) ->
            item = @storage[id]
            removeElementFromArray item, @byUgcId[item.proposedTo] if item?.proposedTo?
            removeElementFromArray item, @byCombId[item.combId] if item?.combId?
            super id

        handleItem: (item) ->
            stored = @storage[item.id]

            if stored?.blank != true and item.needWork == 'ready' and stored.needWork != 'ready'
                notificationCenter.addMessage
                    text: 'post_now_ready_to_be_sent'
                    item: stored

            stored = super item

            if stored.proposedTo? and @byUgcId[stored.proposedTo]?
                @byUgcId[stored.proposedTo].push stored if @byUgcId[stored.proposedTo].indexOf(stored) == -1

            if @byCombId[stored.combId]?
                @byCombId[stored.combId].push stored if @byCombId[stored.combId].indexOf(stored) == -1


        fetchMy: (cb) ->
            @query
                scheduled: false
                limit: 100
            , (items) ->
                cb? items

        unscheduleById: (postId, cb) ->
            rpc.call @itemType + '.unschedule', postId, (result) ->
                cb? result

        # Handlers

        init: () ->
            super()

            novaWizard.register 'post',
                type: 'simple'
                action: (data) =>
                    novaDesktop.launchApp
                        app: 'novaPostCreateApp'
                        data: data

            # novaWizard.register 'post',
            #     type: 'sequence'
            #     steps: [
            #         id: 'project'
            #         directive: 'novaWizardProjectPicker'
            #         provide: 'projectId'
            #         previewType: 'project'
            #     ,
            #         id: 'channel'
            #         # directive: 'novaWizardChannelPicker'
            #         # provide: 'communityIds'
            #         # multi: true
            #
            #         series: [
            #             id: 'channel'
            #             directive: 'novaWizardChannelPicker'
            #             variable: 'channelId'
            #             multi: false
            #         ,
            #             id: 'community'
            #             directive: 'novaWizardCommunityPicker'
            #             variable: 'communityIds'
            #             multi: true
            #         ]
            #         provide: 'communityIds'
            #         previewType: 'community'
            #         multi: true
            #     ,
            #         id: 'timestamp'
            #         directive: 'novaWizardTimePicker'
            #         provide: 'timestamp'
            #     ,
            #         id: 'text'
            #         directive: 'novaWizardTextWriter'
            #         provide: 'text'
            #         canSkip: true
            #     ,
            #         id: 'attachments'
            #         series: [
            #             id: 'content'
            #             directive: 'novaWizardContentPicker'
            #             variable: 'contentIds'
            #             multi: true
            #         ]
            #         provide: 'contentIds'
            #         previewType: 'content'
            #         multi: true
            #         canSkip: true
            #     ,
            #         id: 'final'
            #         directive: 'novaWizardPostFinal'
            #         customNext: 'novaWizardAction_create'
            #     ]
            #     final: (data) =>
            #         console.log 'POST SCHEDULE', data
            #         @create
            #             items: data.contentIds
            #             projectId: data.projectId
            #         , (post) ->
            #             for communityId in data.communityIds
            #                 scheduleService.create
            #                     postId: post.id
            #                     timestamp: data.timestamp
            #                     communityId: communityId
            #                     projectId: data.projectId

            actionsService.registerParser 'post', (item) ->
                if item.scheduled
                    return ['scheduledPost']
                else
                    return ['notScheduledPost']

            actionsService.registerParser 'timeline', (item) ->
                [item.socialNetwork + 'Timeline']

            actionsService.registerParser 'schedule', (item) ->
                [item.scheduleType + 'Schedule']

            setPostNeedWork = (postId, status) =>
                confirmBox.init
                    phrase: 'confirmBox_set_post_needWork_' + status
                    description: 'confirmBox_set_post_needWork_' + status + '_description'
                , () =>
                    # if status == 'ready'
                    #     rpc.call 'smartActions.acceptPostTasks', postId

                    # @save
                    #     id: postId
                    #     needWork: status
                    @call 'setNeedWork',
                        postId: postId
                        needWork: status

            # =================
            # Ready posts
            # ==================
            #
            # Posts
            #

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'set_needWork_inprogress'
                check2: (data) ->
                    for item in data.items
                        if item.needWork != 'inprogress'
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        setPostNeedWork item.id, 'inprogress'

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'set_needWork_ready'
                check2: (data) ->
                    for item in data.items
                        if item.needWork? and item.needWork != 'ready'
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        setPostNeedWork item.id, 'ready'

            #
            # Scheds
            #

            actionsService.registerAction
                sourceType: 'postSchedule'
                phrase: 'set_needWork_inprogress'
                check2: (data) =>
                    for item in data.items
                        post = @getById item.postId
                        if post.needWork != 'inprogress'
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        setPostNeedWork item.postId, 'inprogress'

            actionsService.registerAction
                sourceType: 'postSchedule'
                phrase: 'set_needWork_ready'
                check2: (data) =>
                    for item in data.items
                        post = @getById item.postId
                        if post.needWork? and post.needWork != 'ready'
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        setPostNeedWork item.postId, 'ready'

            #
            # ==================

            actionsService.registerAction
                sourceType: 'schedule'
                phrase: 'send_now'
                action: (data) ->
                    console.log data
                    for id in data.ids
                        scheduleService.sendNow id

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                phrase: 'view_send_log'
                check2: (data) ->
                    if window.event.altKey == true
                        return true
                    # localStorage['DEV_MODE'] == true
                    if account.user.roles?.Morpheus == true
                        return true
                action: (data) ->
                    desktopService.launchApp 'sendLogViewer',
                        scheduleId: data.item.id

            actionsService.registerAction
                targetType: 'image'
                sourceNumber: 1
                contextType: 'post'
                sourceType: 'text'
                only: 'dragndrop'
                phrase: 'add_image_description'
                action: (data) =>
                    data.context.picComments[data.target.id] = data.item.id

                    @save
                        id: data.context.id
                        picComments: data.context.picComments

            actionsService.registerAction
                category: "C"
                targetType: "task"
                sourceType: "content/post/comb"
                phrase: "task_bind_content"
                check2: (data) ->
                    if data.target.entities.length == 0
                        return true

                    hasNew = false
                    for src in data.items
                        for item in data.target.entities
                            if src.id != item.id
                                hasNew = true
                                break
                    hasNew

                action: (data) ->
                    entities = []
                    for item in data.items
                        entities.push
                            type: item.type
                            id: item.id

                    if data.target.id?
                        taskService.call 'addEntity',
                            taskId: data.target.id
                            entities: entities
                        , ->
                            true
                    else
                        for item in entities
                            found = false
                            for ent in data.target.entities
                                if ent.id == item.id
                                    found = true
                                    break
                            if !found
                                data.target.entities.push item

            actionsService.registerAction
                category: "C"
                contextType: "task"
                sourceType: "content/post/comb"
                phrase: "task_unbind_content"
                action: (data) ->
                    taskService.call 'removeEntity',
                        taskId: data.target.id
                        entityIds: data.ids
                    , ->
                        true

            # Действия с таймлайном
            actionsService.registerAction
                sourceType: 'placeholder'
                sourceNumber: 1
                targetType: 'timeline'
                phrase: 'move_placeholder'
                action: (data) =>
                    item = data.items[0]

                    if item.rule.type == 'single'
                        item.rule.timestampStart = smartDate.getShiftTimeline( data.target.timestamp )
                        item.rule.timestampEnd = smartDate.getShiftTimeline( data.target.timestamp ) + DAY
                        item.rule.groupId = data.target.groupId
                        item.rule.communityId = data.target.communityId

                        ruleService.save item.rule
                    else
                        newItem =
                            type: 'rule'
                            ruleType: 'single'
                            timestampStart: smartDate.getShiftTimeline( data.target.timestamp )
                            timestampEnd: smartDate.getShiftTimeline( data.target.timestamp ) + DAY
                            ad: item.rule.ad
                            interval: item.rule.interval
                            dayMask: item.rule.dayMask
                            groupId: data.target.groupId
                            communityId: data.target.communityId

                        ruleService.create newItem, (item) ->
                            true

                        ruleService.removePlaceholders [item]

            actionsService.registerAction
                sourceType: 'placeholder'
                sourceNumber: 1
                targetType: 'timeline'
                phrase: 'copy_placeholder'
                action: (data) =>
                    item = data.items[0]

                    newItem =
                        type: 'rule'
                        ruleType: 'single'
                        timestampStart: smartDate.getShiftTimeline( data.target.timestamp )
                        timestampEnd: smartDate.getShiftTimeline( data.target.timestamp ) + DAY
                        ad: item.rule.ad
                        interval: item.rule.interval
                        dayMask: item.rule.dayMask
                        groupId: data.target.groupId
                        communityId: data.target.communityId

                    ruleService.create newItem, (item) ->
                        true

            # Бросаем комб на время
            actionsService.registerAction
                sourceType: 'comb'
                sourceNumber: 1
                targetType: 'timeline/placeholder'
                phrase: 'plan_from_comb'
                priority: 70
                action: (data) =>
                    desktopService.launchApp 'postPicker',
                        communityId: data.target.communityId
                        timestamp: smartDate.getShiftTimeline( data.target.timestamp )
                        socialNetwork: data.target.socialNetwork
                        combId: data.item.id
                        placeholder: false
                        groupId: data.target.groupId
                    , data.e

            # Бросаем лот на время
            actionsService.registerAction
                sourceType: 'repostLot'
                sourceNumber: 1
                targetType: 'timeline/placeholder'
                phrase: 'create_repost_request'
                priority: 400
                action: (data) =>
                    desktopService.launchApp 'requestMaster',
                        lotId: data.item.id
                        timestamp: smartDate.getShiftTimeline( data.target.timestamp )
                        communityId: data.target.communityId

            # Действия с медиапланом
            # Бросаем контент
            actionsService.registerAction
                sourceType: 'content'
                targetType: 'placeholder/timeline'
                phrase: 'create_and_schedule_post'
                priority: 71
                action: (data) =>
                    scheduleService.create
                        scheduleType: 'post'
                        timestamp: data.target.timestamp
                        items: data.ids
                        communityId: data.target.communityId

            actionsService.registerAction
                sourceType: 'content'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'fill_mediaplan...'
                priority: 78
                action: (data) =>
                    desktopService.launchApp 'optionsList',
                        message:
                            phrase: 'posting_through_rule_or_time'
                            description: 'posting_through_rule_or_time_description'
                        options: [
                                text: 'posting_through_time'
                                action: () ->
                                    ruleService.fill
                                        communityId: data.target.communityId
                                        groupId: data.target.groupId
                                        timestamp: data.target.timestamp
                                        items: data.ids
                                    true
                            ,
                                text: 'posting_through_rule'
                                action: () ->
                                    ruleService.fill
                                        communityId: data.target.communityId
                                        groupId: data.target.groupId
                                        timestamp: data.target.timestamp
                                        items: data.ids
                                    true
                        ]

            actionsService.registerAction
                sourceType: 'content'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'fill_group_mediaplan...'
                priority: 79
                check: (ids, items, target) ->
                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    desktopService.launchApp 'optionsList',
                        message:
                            phrase: 'posting_through_rule_or_time'
                            description: 'posting_through_rule_or_time_description'
                        options: [
                                text: 'posting_through_time'
                                action: () ->
                                    ruleService.fill
                                        groupId: data.target.groupId
                                        timestamp: data.target.timestamp
                                        items: data.ids
                                        wholeGroup: data.target.groupId
                                    true
                            ,
                                text: 'posting_through_rule'
                                action: () ->
                                    ruleService.fill
                                        ruleId: data.target.rule.id
                                        timestamp: data.target.timestamp
                                        items: data.ids
                                        wholeGroup: data.target.groupId
                                    true
                        ]

            actionsService.registerAction
                sourceType: 'content'
                targetType: 'placeholder/timeline'
                phrase: 'create_whole_group'
                priority: 80
                check: (ids, items, target) ->
                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    scheduleService.create
                        scheduleType: 'post'
                        timestamp: data.target.timestamp
                        items: data.ids
                        groupId: data.target.groupId

            # Бросаем посты
            actionsService.registerAction
                sourceType: 'notScheduledPost'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'plan_here'
                priority: 43
                action: (data) =>
                    scheduleService.create
                        scheduleType: 'post'
                        timestamp: data.target.timestamp
                        postId: data.items[0].id
                        communityId: data.target.communityId

            actionsService.registerAction
                sourceType: 'notScheduledPost'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'clone_whole_group'
                priority: 47
                check: (ids, items, target) ->
                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    scheduleService.clonePost
                        postId: data.items[0].id
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp

            actionsService.registerAction
                sourceType: 'scheduledPost'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'create_repost'
                priority: 72
                check: (ids, items, target) ->
                    sched = scheduleService.getOriginalByPostId items[0].id
                    sched.communityId != target.communityId
                action: (data) =>
                    scheduleService.repost
                        postId: data.items[0].id
                        communityId: data.target.communityId
                        timestamp: data.target.timestamp

            actionsService.registerAction
                sourceType: 'scheduledPost'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'move_schedule'
                priority: 102
                action: (data) =>
                    sched = scheduleService.getOriginalByPostId data.item.id
                    scheduleService.save
                        id: sched.id
                        communityId: data.target.communityId
                        timestamp: data.target.timestamp

            actionsService.registerAction
                sourceType: 'notScheduledPost'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'fill_mediaplan_time'
                priority: 121
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp
                        postIds: data.ids

            actionsService.registerAction
                sourceType: 'notScheduledPost'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'fill_mediaplan_rule'
                priority: 120
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        ruleId: data.target.rule.id
                        timestamp: data.target.timestamp
                        postIds: data.ids

            # Действия с шедулами
            # Один
            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'move_schedule'
                priority: 102
                action: (data) =>
                    scheduleService.save
                        id: data.items[0].id
                        timestamp: data.target.timestamp
                        communityId: data.target.communityId

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'create_repost'
                priority: 72
                check: (ids, items, target) ->
                    items[0].communityId != target.communityId
                action: (data) =>
                    scheduleService.repost
                        postId: data.items[0].postId
                        timestamp: data.target.timestamp
                        communityId: data.target.communityId

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                targetType: 'placeholder/timeline'
                phrase: 'create_repost_whole_group'
                priority: 73
                check: (ids, items, target) ->
                    if items[0].communityId == target.communityId
                        return false

                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    group = groupService.getById data.target.groupId
                    for feed in group.feeds
                        scheduleService.repost
                            postId: data.items[0].postId
                            timestamp: data.target.timestamp
                            communityId: feed.communityId

            # Много
            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'move_schedules_mediaplan_time'
                priority: 103
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp
                        schedIds: data.ids

            actionsService.registerAction
                sourceType  :   'schedule'
                sourceNumber:   'many'
                targetType  :   'placeholder'
                phrase      :   'move_schedules_mediaplan_rule'
                priority    :   '104'
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        ruleId: data.target.rule.id
                        timestamp: data.target.timestamp
                        schedIds: data.ids

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'repost_mediaplan_time'
                priority: 74
                action: (data) =>
                    postIds = []
                    for item in data.items
                        postIds.push item.postId

                    ruleService.fill
                        communityId: data.target.communityId
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp
                        postIds: postIds
                        repost: true

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'repost_mediaplan_rule'
                priority: 75
                action: (data) =>
                    postIds = []
                    for item in data.items
                        postIds.push item.postId

                    ruleService.fill
                        communityId: data.target.communityId
                        ruleId: data.target.rule.id
                        timestamp: data.target.timestamp
                        postIds: postIds
                        repost: true

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'repost_mediaplan_time_whole_group'
                priority: 76
                check: (ids, items, target) ->
                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    postIds = []
                    for item in data.items
                        postIds.push item.postId

                    ruleService.fill
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp
                        postIds: postIds
                        repost: true
                        wholeGroup: groupId

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 'many'
                targetType: 'placeholder'
                phrase: 'repost_mediaplan_rule_whole_group'
                priority: 77
                check: (ids, items, target) ->
                    group = groupService.getById target.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    postIds = []
                    for item in data.items
                        postIds.push item.postId

                    ruleService.fill
                        ruleId: data.target.rule.id
                        timestamp: data.target.timestamp
                        postIds: postIds
                        repost: true
                        wholeGroup: groupId

            # Кидаем комб на плейсхолдер
            actionsService.registerAction
                sourceType: 'comb'
                sourceNumber: 1
                targetType: 'placeholder'
                phrase: 'comb_fill_mediaplan_time'
                priority: 122
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        groupId: data.target.groupId
                        timestamp: data.target.timestamp
                        combId: data.items[0].id

            actionsService.registerAction
                sourceType: 'comb'
                sourceNumber: 1
                targetType: 'placeholder'
                phrase: 'comb_fill_mediaplan_rule'
                priority: 123
                action: (data) =>
                    ruleService.fill
                        communityId: data.target.communityId
                        ruleId: data.target.rule.id
                        timestamp: data.target.timestamp
                        combId: data.items[0].id


            # Тащим пост на шедул
            actionsService.registerAction
                sourceType: 'post'
                sourceNumber: 1
                targetType: 'schedule'
                phrase: 'plan_instead'
                priority: 100
                action: (data) =>
                    firstPost = @getById data.target.postId
                    dragPost = data.items[0]

                    toDeleteIds = [data.target.id]
                    toSched = []

                    if !data.e.altKey
                        buffer.removeItem dragPost

                    toSched.push
                        type: 'schedule'
                        scheduleType: 'post'
                        postId: dragPost.id
                        timestamp: data.target.timestamp
                        communityId: data.target.communityId

                    if dragPost.scheduled == true
                        secondSched = scheduleService.getOriginalByPostId dragPost.id
                        toDeleteIds.push secondSched.id

                        toSched.push
                            type: 'schedule'
                            scheduleType: 'post'
                            postId: firstPost.id
                            timestamp: secondSched.timestamp
                            communityId: secondSched.communityId

                    scheduleService.deleteByIds toDeleteIds, (result) ->
                        scheduleService.create sched for sched in toSched
                        buffer.addItems [firstPost] if toSched.length < 2

                    return

            # Меняем шедулы местами
            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                targetType: 'schedule'
                phrase: 'switch_places'
                priority: 101
                action: (data) =>
                    firstPost = @getById data.target.postId
                    secondPost = @getById data.items[0].postId

                    firstSched =
                        type: 'schedule'
                        scheduleType: 'post'
                        postId: secondPost.id
                        timestamp: data.target.timestamp
                        communityId: data.target.communityId

                    secondSched =
                        type: 'schedule'
                        scheduleType: 'post'
                        postId: firstPost.id
                        timestamp: data.items[0].timestamp
                        communityId: data.items[0].communityId

                    # Delete old schedules
                    scheduleService.deleteByIds [data.target.id,data.items[0].id], (result) ->
                        scheduleService.create firstSched
                        scheduleService.create secondSched

                    return

            # Добавляем контент в пост через шедул
            actionsService.registerAction
                sourceType: 'content'
                targetType: 'schedule'
                phrase: 'add_to_post'
                priority: 140
                action: (data) =>
                    postItem = @getById data.target.postId
                    @addContentIds postItem, data.ids

            # Убираем
            actionsService.registerAction
                category: "C"
                targetType: "post"
                sourceType: "content"
                phrase: "remove_from_post"
                priority: "27"
                restrict: "dragndrop"
                check2: (data) =>
                    @hasContentIds data.target, data.ids
                action: (data) =>
                    if data.target.virtual
                        for item in data.items
                            removeElementFromArray item.id, data.target.contentIds[item.type]
                    else
                        @removeContentIds data.target, data.ids

            # Добавляем контент в пост
            actionsService.registerAction
                sourceType: 'content'
                targetType: 'post'
                phrase: 'add_to_post'
                restrict: 'contextMenu'
                priority: 140
                check2: (data) ->
                    if !data.target?.contentIds?
                        return false

                    for id in data.ids
                        found = false
                        for k,arr of data.target.contentIds
                            if id in arr
                                found = true
                                break
                        if !found
                            break

                    return !found
                action: (data) =>
                    if data.target.virtual
                        for item in data.items
                            data.target.contentIds[item.type].push item.id if item.id not in data.target.contentIds[item.type]
                    else
                        @addContentIds data.target, data.ids

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'new_text'
                priority: 66
                action: (data) =>
                    contentService.create
                        type: 'text'
                        value: ""
                    , (textItem) =>
                        for item in data.items
                            @addContentIds item, [textItem.id]

                        desktopService.launchApp 'textEditor',
                            textId: textItem.id

            actionsService.registerAction
                phrase: 'new_post'
                priority: 88
                action: (data) =>
                    @create {}, (newPost) ->
                        buffer.addItems [newPost]

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'unpublish_from_market'
                leaveItems: true
                priority: 30
                check: (ids, items, context) ->
                    for item in items
                        if item.onSale == true and item.userId == account.user.id
                            return true
                    false
                action: (data) =>
                    lotService.query
                        postId:
                            '$in': data.ids
                    , (items, total) ->
                        for item in items
                            lotService.unpublish item.id
                        true

            actionsService.registerAction
                sourceType: 'lot'
                phrase: 'unpublish_from_market'
                priority: 30
                leaveItems: true
                check: (ids, items, context) ->
                    for item in items
                        if item.userId == account.user.id and item.published == true
                            return true
                    false
                action: (data) =>
                    for id in data.ids
                        lotService.unpublish id
                    true

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'add_to_market'
                leaveItems: true
                priority: 42
                check: (ids, items, context) ->
                    for item in items
                        if item.userId == account.user.id and item.scheduled == true and item.onSale != true
                            return true
                        false
                action: (data) =>
                    first = true
                    for item in data.items
                        if item.onSale != true
                            scheduleService.getOriginalByPostId item.id, (schedule) ->
                                if schedule.userId != account.user.id
                                    return

                                lot =
                                    type: 'lot'
                                    price: 0
                                    minSubscribers: 1
                                    lotType: 'repost'
                                    postId: schedule.postId
                                    scheduleId: schedule.id

                                lotService.create lot, (newLot) ->
                                    if first == true
                                        first = false
                                        desktopService.launchApp 'lotManager',
                                            lotId: newLot.id

                    true

            actionsService.registerAction
                sourceType: 'post'
                phrase: 'unschedule'
                priority: 29
                check: (ids, items, context) ->
                    for item in items
                        if item.scheduled == true
                            return true
                    false
                action: (data) =>
                    for id in data.ids
                        @unscheduleById id

            actionsService.registerAction
                sourceType: 'schedule'
                phrase: 'unchedule'
                priority: 29
                action: (data) =>
                    postIds = []
                    for item in data.items
                        if item.postId not in postIds
                            postIds.push item.postId
                            @unscheduleById item.postId
                    true

            actionsService.registerAction
                sourceType: 'scheduledPost'
                phrase: 'remove_reposts'
                priority: 28
                action: (data) =>
                    for item in data.items
                        scheduleService.removeReposts item.id

            actionsService.registerAction
                sourceType: 'postSchedule'
                phrase: 'remove_reposts'
                priority: 28
                action: (data) =>
                    for item in data.items
                        scheduleService.removeReposts item.postId

            actionsService.registerAction
                sourceType: 'scheduledPost'
                sourceNumber: 'many'
                phrase: 'remove_scheduled'
                only: 'rightPanel'
                priority: 151
                action: (data) -> true

            actionsService.registerAction
                sourceType: 'notScheduledPost'
                sourceNumber: 'many'
                only: 'rightPanel'
                phrase: 'remove_not_scheduled'
                priority: 150
                action: (data) -> true

            actionsService.registerAction
                sourceType: 'schedule'
                sourceNumber: 1
                phrase: 'copy'
                priority: 48
                action: (data) =>
                    post = @getById data.items[0].postId
                    multiselect.copyItem post

            actionsService.registerAction
                sourceType: 'post'
                sourceNumber: 1
                phrase: 'copy'
                priority: 48
                action: (data) =>
                    multiselect.copyItem data.items[0]

            actionsService.registerAction
                sourceType: 'schedule'
                phrase: 'add_to_market'
                priority: 42
                check: (ids, items, context) ->
                    for item in items
                        if item.onSale != true
                            return true
                    false
                action: (data) =>
                    first = true
                    for item in data.items
                        lotService.create
                            type: 'lot'
                            lotType: 'repost'
                            postId: item.postId
                            scheduleId: item.id
                        , (newLot) ->
                            if first == true
                                first = false
                                desktopService.launchApp 'lotManager',
                                    lotId: newLot.id

            actionsService.registerAction
                sourceType: 'schedule'
                phrase: 'unpublish_from_market'
                leaveItems: true
                priority: 30
                check: (ids, items, context) ->
                    for item in items
                        if item.userId == account.user.id and item.onSale == true
                            return true
                    false
                action: (data) =>
                    postIds = []
                    for item in data.items
                        postIds.push item.postId if item.postId not in postIds

                    lotService.query
                        postId:
                            '$in': postIds
                    , (items, total) ->
                        for item in items
                            lotService.unpublish item.id
                        true


            # System actions
            actionsService.registerAction
                targetType: 'timelineApp'
                phrase: 'add_feed'
                priority: 63
                action: (data) ->
                    desktopService.launchApp 'addFeed'

            actionsService.registerAction
                sourceType: 'timeline/placeholder'
                phrase: 'new_post'
                priority: 88
                action: (data) =>
                    for item in data.items
                        scheduleService.create
                            items: []
                            communityId: item.communityId
                            timestamp: item.timestamp

            actionsService.registerAction
                sourceType: 'timeline'
                phrase: 'new_comb'
                priority: 67
                action: (data) =>
                    for item in data.items
                        scheduleService.create
                            items: []
                            groupId: item.groupId
                            timestamp: item.timestamp

            actionsService.registerAction
                sourceType: 'timeline/placeholder'
                phrase: 'paste_repost'
                priority: 46
                check: -> multiselect.state.buffer != null and multiselect.getBuffer().scheduled == true
                action: (data) =>
                    post = multiselect.getBuffer()
                    for item in data.items
                        scheduleService.repost
                            postId: post.id
                            communityId: item.communityId
                            timestamp: item.timestamp

            actionsService.registerAction
                sourceType: 'timeline/placeholder'
                sourceNumber: 1
                phrase: 'plan_here'
                priority: 43
                check: -> multiselect.state.buffer != null
                action: (data) =>
                    post = multiselect.getBuffer()
                    item = data.items[0]
                    scheduleService.getOriginalByPostId post.id, (sched) ->
                        if sched?
                            scheduleService.save
                                id: sched.id
                                communityId: item.communityId
                                timestamp: item.timestamp
                        else
                            scheduleService.create
                                communityId: item.communityId
                                timestamp: item.timestamp
                                postId: post.id

            actionsService.registerAction
                sourceType: 'timeline/placeholder'
                sourceNumber: 1
                phrase: 'copy_here'
                check: -> multiselect.state.buffer != null
                action: (data) =>
                    post = multiselect.getBuffer()
                    item = data.items[0]

                    @create
                        contentIds: post.contentIds
                        picComments: post.picComments
                        combId: post.combId
                    , (newPost) ->
                        scheduleService.create
                            communityId: item.communityId
                            timestamp: item.timestamp
                            postId: newPost.id


            actionsService.registerAction
                sourceType: 'timeline/placeholder'
                sourceNumber: 1
                phrase: 'copy_here_group'
                check2: (data) ->
                    if multiselect.state.buffer == null
                        return false
                    group = groupService.getById data.item.groupId
                    group.feeds?.length > 1
                action: (data) =>
                    post = multiselect.getBuffer()
                    item = data.items[0]

                    @create
                        contentIds: post.contentIds
                        picComments: post.picComments
                        combId: post.combId
                    , (newPost) ->
                        scheduleService.clonePost
                            postId: newPost.id
                            groupId: data.item.groupId
                            timestamp: data.item.timestamp


            actionsService.registerAction
                sourceType: 'timeline'
                sourceNumber: 1
                phrase: 'plan_post'
                priority: 69
                action: (data) ->
                    item = data.items[0]

                    desktopService.launchApp 'postPicker',
                        groupId: item.groupId
                        communityId: item.communityId
                        timestamp: smartDate.getShiftTimeline item.timestamp
                    , data.e
                    true

            actionsService.registerAction
                sourceType: 'timeline'
                sourceNumber: 1
                phrase: 'new_placeholder'
                priority: 65
                action: (data) ->
                    item = data.items[0]

                    ruleService.create
                        type: 'rule'
                        ruleType: 'single'
                        timestampStart: smartDate.getShiftTimeline item.timestamp
                        timestampEnd: null
                        ad: false
                        interval: 30
                        dayMask: [true,true,true,true,true,true,true]
                        communityId: item.communityId
                        groupId: item.groupId
                        end: false

            actionsService.registerAction
                sourceType: 'placeholder'
                sourceNumber: 1
                phrase: 'edit'
                priority: 51
                action: (data) =>
                    inspectorService.initInspector data.items[0]

            actionsService.registerAction
                sourceType: 'community'
                sourceNumber: 1
                phrase: 'import_csv'
                priority: 161
                action: (data) =>
                    desktopService.launchApp 'importXLS',
                        communityId: data.item.id

            actionsService.registerAction
                sourceType: 'community'
                sourceNumber: 1
                phrase: 'export_sheds'
                priority: 161
                action: (data) =>
                    desktopService.launchApp 'exportXLS',
                        communityId: data.item.id

            actionsService.registerAction
                sourceType: 'team'
                sourceNumber: 1
                targetType: 'group'
                phrase: 'bind_team_to_group'
                priority: 220
                action: (data) =>
                    groupService.call 'bindTeam',
                        id: data.target.id
                        teamId: data.item.id
                    , -> true

            actionsService.registerAction
                sourceType: 'placeholder'
                sourceNumber: 1
                phrase: 'plan_post'
                action: (data) =>
                    desktopService.launchApp 'postPicker',
                        communityId: data.items[0].communityId
                        timestamp: data.items[0].timestamp
                    , data.e

    new classEntity()
