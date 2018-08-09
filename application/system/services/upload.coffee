buzzlike
    .factory 'uploadService', (novaWizard, account, notificationService, rpc, updateService, $rootScope, env, combService, contentService, notificationCenter, $http, httpWrapped, localization, socketService) ->
        maxUpload = 15 * 1024 * 1024

        # 5Mb
        jQuery.event.props.push('dataTransfer')

        # filetype = /((doc)|(xls)|(ppt)|(ai)|(svg)|(pdf)|(psd)|(vnd.adobe.photoshop)|(vnd.ms)|(vnd.openxmlformats))/gi
        imagetype = /image.*((png)|(gif)|(jpg)|(jpeg))/gi
        texttype = /text.*(plain)/gi

        # =================------+>
        # Perfect uploader
        # ==============---+>

        # Constants
        MAX_CONCURENT_UPLOAD = 3
        MAX_FILE_ATTEMPT = 3

        # Counters
        tasksInProgress = 0

        # Locals
        queue = []
        currentSeries = null

        # Recursive-lock
        timeoutHandler = null

        context = null
        whereCallback = null
        completeCallback = null

        # Upload callback
        tokenCallbacks = {}
        checkByToken = (token) ->
            if tokenCallbacks[token].uploaded >= tokenCallbacks[token].total
                contentService.getByIds tokenCallbacks[token].ids, (items) ->
                    tokenCallbacks[token].cb? items, tokenCallbacks[token].ids
                    delete tokenCallbacks[token]

        socketService.on 'tokenContentSaved', (data) ->
            if tokenCallbacks[data.token]?
                tokenCallbacks[data.token].uploaded++
                tokenCallbacks[data.token].ids.push data.id

                checkByToken data.token

        getFilesRecursive = (items, series, onFileAdd) ->
            for item in items

                if item.kind == 'file'
                    item = item.webkitGetAsEntry()

                if item.isFile
                    item.file (file) ->
                        series.total++
                        # New upload task
                        if file.size > maxUpload
                            series.large++

                        # if !file.type.match(imagetype) and !file.type.match(texttype) and !file.type.match(filetype)
                        #     series.wrong++

                        if file.size <= maxUpload #and ( file.type.match(imagetype) or file.type.match(texttype) or file.type.match(filetype) )
                            series.tasks.push
                                file: file
                                attempts: 0
                                complete: false
                                inProgress: false

                        onFileAdd()

                else if item.isDirectory
                    dir = item.createReader()
                    dir.readEntries (items) -> getFilesRecursive items, series, onFileAdd

        createSeries = (tO, cb) ->
            series =
                total: 0
                large: 0
                wrong: 0
                uploaded: 0
                tasks: []

            # Chrome browser
            if tO.items
                getFilesRecursive tO.items, series, () ->
                    if timeoutHandler != null
                        clearTimeout timeoutHandler

                    timeoutHandler = setTimeout ->
                        cb? series
                    , 500
            else if tO.files?

                for file in tO.files
                    series.total++

                    console.log file.type

                    if file.size > maxUpload
                        series.large++
                        continue

                    # if !file.type.match(imagetype) && !file.type.match(texttype) && !file.type.match(filetype)
                    #     series.wrong++
                    #     continue
                    series.tasks.push
                        file: file
                        attempts: 0
                        complete: false
                        inProgress: false

                cb? series

            else

                for file in tO.buffer
                    series.total++

                    # if !file.type.match(imagetype) && !file.type.match(texttype)
                    #     series.wrong++
                    #     continue
                    console.log '!!!',file.item
                    series.tasks.push
                        file: file.item # new Blob [file.blob], { "type" : file.item.type}
                        attempts: 0
                        complete: false
                        inProgress: false

                cb? series

            series

        nextSeries = ->
            if queue.length > 0
                currentSeries = queue.shift()
            else
                currentSeries = null
            checkSeries()

        checkSeries = ->
            if !currentSeries? then return

            complete = true

            for task in currentSeries.tasks
                if task.complete != true and task.attempts < MAX_FILE_ATTEMPT
                    complete = false

                    if task.inProgress == false
                        # Start new task
                        if tasksInProgress < MAX_CONCURENT_UPLOAD
                            startTask task

            if complete == true
                # Series complete
                showResult()
                nextSeries()

        showResult = (series) ->
            series = currentSeries

            notificationError = true

            message = series.uploaded + ' ' + localization.translate('global_from') + ' ' + series.total + ' ' + localization.translate('uploadService_uploaded')
            if series.wrong > 0
                message += '. ' + localization.translate('uploadService_of_them') + series.wrong + ' ' + localization.translate('uploadService_invalidformat_1')
            if series.large > 0
                message += '. ' + localization.translate('uploadService_of_them') + series.large + ' ' + localization.translate('uploadService_maxsize_2')

            if series.wrong == 0 and series.large == 0
                notificationError = false

            tokenCallbacks[series.token].total -= series.wrong + series.large
            checkByToken series.token

            if notificationError == true
                notificationCenter.addMessage
                    realText: message
                    error: notificationError

            url = series.url.split('/')
            token = url[url.length-1]

            notificationService.showNotificationByToken token

            if account.user.settings.takeUploadToRight == true
                notificationService.setTokenMax token, series.uploaded

        startTask = (task) ->
            task.inProgress = true
            tasksInProgress++

            doUpload task, (result) ->
                if result == false
                    # Not uploaded
                    if task.attempts < MAX_FILE_ATTEMPT
                        task.attempts++
                        startTask task
                        tasksInProgress--
                else
                    # Success
                    task.complete = true
                    task.inProgress = false
                    tasksInProgress--

                    currentSeries.uploaded++
                    checkSeries()

        doUpload = (task, cb) ->
            progress = notificationCenter.registerProgress()

            # Multiple Uploads
            xhr = null

            formDataImage = new FormData()
            # formDataImage.append 'image', task.file

            formDataImage.append 'image', task.file, 'image.' + task.file.type.split('/')[1]

            $.ajax
                cache: false
                contentType: false
                data: formDataImage
                processData: false
                crossDomain: true
                url:  currentSeries.url
                type: 'POST'
                xhr: () ->
                    xhr = jQuery.ajaxSettings.xhr()
                    if xhr.upload
                        xhr.upload.addEventListener 'progress', (e) ->
                            p = Math.floor(e.loaded / e.total * 100)
                            progress.value = p
                            notificationCenter.updateStatus progress
                            $rootScope.$applyAsync()
                        , false
                    xhr
                beforeSend: () ->
                    progress.value = 0
                    notificationCenter.updateStatus progress

                success: (res) ->
                    progress.value = 100
                    notificationCenter.updateStatus progress
                    cb true

                error: (e, st, err) ->
                    progress.value = 100
                    notificationCenter.updateStatus progress

                    cb false

        fireUpload = (series, cb) ->
            # Get upload url
            reqParams =
                count: series.tasks.length

            if context?
                reqParams.where = context

            rpc.call 'upload.request', reqParams, (result) ->

                urlParts = result.url.split '/'
                token = urlParts[urlParts.length - 1]

                series.token = token

                tokenCallbacks[token] =
                    cb: cb
                    total: series.tasks.length
                    uploaded: 0
                    ids: []

                series.url = result.url

                if currentSeries != null
                    notificationCenter.addMessage
                        realText: localization.translate('uploadFiles_filesqueue')
                        error: false
                else
                    nextSeries()

        requestUpload = (where, cb, ccb) ->
            context = null
            if cb?
                whereCallback = cb
            else
                whereCallback = null

            if ccb?
                completeCallback = ccb
            else
                completeCallback = null

            if where?.id?
                context =
                    type: where.type
                    id: where.id

            if where?.length > 0
                context = []
                for dest in where
                    context.push
                        type: dest.type
                        id: dest.id

            input = $('.uploadHelper input')
            input.click()

            true

        novaWizard.register 'upload',
            type: 'simple'
            action: (data) =>
                where = [
                    type: 'project'
                    id: data?.projectId or account.user.userProjectId
                ]
                if data.where?.length > 0
                    for wh in data.where
                        where.push wh
                requestUpload where, null, data.cb

        upload: (transferObject, cb) ->
            if account.user.roles?.Morpheus
                maxUpload = 1024 * 1024 * 1024

            # Get tasks
            createSeries transferObject, (series) ->
                queue.push series

                # if completeCallback?
                #     series.completeCallback = completeCallback

                if whereCallback?
                    whereCallback (where) ->
                        if where?.id?
                            context =
                                type: where.type
                                id: where.id

                        if where?.length > 0
                            context = []
                            for dest in where
                                context.push
                                    type: dest.type
                                    id: dest.id
                        fireUpload series, if typeof cb == 'function' then cb else completeCallback
                else
                    fireUpload series, if typeof cb == 'function' then cb else completeCallback

        requestUpload: requestUpload
