buzzlike
    .directive "asyncUpload", (env, $rootScope, uploadService) ->
        restrict: 'C'
        link: ($scope, element, attrs) ->

            elem = $(element[0])
            fader = elem.find('.uploadFader')
            rFader = fader.children('.realFader')

            if !window.FileReader?
                return false

            elem
                .bind 'dragenter', (e) ->
                    if e.dataTransfer.types.indexOf("Files") < 0
                        return false

                    fader.removeClass("wrong-files")

                    types = getFileList e.dataTransfer
                    if types != false
                        # if $.isEmptyObject types
                            # you shall not pass
                            # fader.addClass("wrong-files")
                        # else

                        fader.find('.block.active').removeClass 'active'

                        if types.png
                            fader.find('.block.png').addClass('active')
                        if types.jpg
                            fader.find('.block.jpg').addClass('active')
                        if types.gif
                            fader.find('.block.gif').addClass('active')
                        if types.text
                            fader.find('.block.text').addClass('active')

                    $(this).addClass("uploadActive")

            rFader
                .bind 'dragleave', (e) ->
                    elem.removeClass("uploadActive")

                .bind 'dragover', (e) ->
                    e.stopPropagation()
                    e.preventDefault()

                .bind 'drop', (e) ->
                    elem.removeClass("uploadActive")
                    if e.dataTransfer.types.indexOf("Files") < 0 or fader.hasClass("wrong-files")
                        return false

                    e.stopPropagation()
                    e.preventDefault()

                    uploadService.upload e.dataTransfer

                    $scope.$apply()

            getFileList = (transferObject) ->
                if transferObject.items
                    result = {}
                    for item in transferObject.items
                        if item.type == '' then result.folder = true

                        if item.type == 'image/png' then result.png = true
                        if item.type == 'image/jpeg' then result.jpg = true
                        if item.type == 'image/gif' then result.gif = true
                        if item.type == 'text/plain' then result.text = true

                    return result

                return false
