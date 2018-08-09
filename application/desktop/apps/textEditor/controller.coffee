buzzlike
    .controller 'textEditorCtrl', ($scope, desktopService, account, buffer, stateManager, localStorageService, contentService, operationsService) ->

        $scope.session.expandedHeader = false
        patchCode = account.user.id + getRandomInt(10000,99999) + Date.now()

        $scope.params =
            editedText: ""

        if $scope.session.textId?.length > 0
            process = $scope.progress.add()
            $scope.text = contentService.getById $scope.session.textId, (textItem) ->
                operationsService.setLastPatch textItem.id
                $scope.params.editedText = textItem.value
                # $scope.patches = operationsService.getPatches($scope.session.textId)
                textItem.patch = null
                $scope.progress.finish process
        else
            $scope.text =
                name: ''
                type: 'text'
                value: ''

        $scope.stateTree.applyState
            enter: 'default'
            'enter cmd': ->
                $scope.closeApp()
                
            delete: 'default'
            escape: $scope.closeApp

        $scope.onClose () ->
            $scope.textChanged()
            true

        # $scope.$watch 'patches', (nVal) ->
        #     if nVal?
        #         # console.log 'Patches', nVal
        #         for patch in nVal
        #             if patch.patchCode == patchCode
        #                 continue
        #             patches = dmp.patch_fromText(patch.value)
        #             # console.log patches, nVal, dmp.patch_apply(patches, $scope.params.editedText)
        #             $scope.params.editedText = dmp.patch_apply(patches, $scope.params.editedText)[0]
        #         operationsService.setLastPatch $scope.text.id
        # , true

        $scope.$watch 'text.value', (nVal) ->
            if nVal?
                $scope.params.editedText = nVal

        $scope.textChanged = ->
            if $scope.text?.id?
                process = $scope.progress.add()
                # $scope.text.value = $scope.params.editedText
                # $scope.text.patchCode = patchCode
                contentService.save 
                    id: $scope.text.id
                    value: $scope.params.editedText
                    type: 'text'
                , (res) ->
                    $scope.text.value = $scope.params.editedText
                    $scope.text.patch = null

                    if $scope.session.proposedPost?
                        rpc.call 
                            method: 'post.saveSuggestedPost'
                            data: $scope.session.proposedPost
                            anyway: ->
                                $scope.progress.finish process
                    else
                        $scope.progress.finish process

            else if $scope.params.editedText.length > 0 or $scope.text.name.length
                if $scope.text.value == $scope.params.editedText
                    return
                    
                $scope.text.value = $scope.params.editedText
                process = $scope.progress.add()
                contentService.create $scope.text, (textItem) ->
                    # $scope.patches = operationsService.getPatches(textItem.id)
                    # operationsService.setLastPatch $scope.text.id

                    $scope.text.patch = null
                    $scope.text = textItem
                    buffer.addItem textItem

                    $scope.session.textId = textItem.id
                    desktopService.saveState()
                    $scope.stateSaver.save()
                    $scope.progress.finish process

    .directive 'textEditorFocus', () ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            setTimeout ->
                $(element).focus()
            true