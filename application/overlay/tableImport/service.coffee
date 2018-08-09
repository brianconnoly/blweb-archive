buzzlike.service 'tableImport', (env, operationsService, notificationCenter, $rootScope) ->

    state = 
        communityId: null

    open = (cId) ->
        if cId?
            state.communityId = cId
        else
            state.communityId = null

    close = ->
        true

    doAjax = (formData, progress, community) ->
        reqParams =
            count: 1

        if community == true
            reqParams.where =
                communityId: state.communityId

        rpc.call 'tableImport.request', reqParams, (result) ->

            $.ajax
                cache: false
                contentType: false
                data: formData
                processData: false
                # xhrFields:
                #     withCredentials: true
                crossDomain: true
                url: result.url
                type: 'POST'
                xhr: () ->
                    xhr = jQuery.ajaxSettings.xhr()
                    if xhr.upload
                        xhr.upload.addEventListener 'progress', (e) ->
                            p = Math.floor(e.loaded / e.total * 100)
                            progress.value = p
                            notificationCenter.updateStatus progress
                            $rootScope.$apply()
                        , false
                    xhr
                beforeSend: () ->
                    progress.value = 0
                    notificationCenter.updateStatus progress
                success: (res) ->                        
                    if res.operations? and res.operations.length > 0
                        operationsService.parseOperations res.operations
                    close()
                    notificationCenter.addMessage
                        text: 'import_csv_ok'
                    $rootScope.$apply()
                error: () ->
                    close()
                    notificationCenter.addMessage
                        text: 'import_csv_error'
                    $rootScope.$apply()

    uploadFull = (input) ->
        for file in input.files
            formData = new FormData()
            formData.append 'uploadedFile', file

        progress = notificationCenter.registerProgress()
        doAjax formData, progress, false

    uploadCommunity = (input) ->
        if state.communityId == null
            return

        for file in input.files
            formData = new FormData()
            formData.append 'uploadedFile', file

        progress = notificationCenter.registerProgress()
        doAjax formData, progress, true

    initiateUpload = (commId) ->
        if commId?
            state.communityId = commId
            $('#importCommunityHelper').click()
        else
            state.communityId = null
            $('#importFullHelper').click()
        true
    {   
        state

        open
        close

        uploadFull
        uploadCommunity
        initiateUpload
    }
