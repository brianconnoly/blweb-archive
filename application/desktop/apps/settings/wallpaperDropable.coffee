buzzlike.directive 'wallpaperDropable', (dragMaster, account) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        images = []
        new dragMaster.dropTarget element[0],
            enter: (elem, e) ->
                element.addClass('wallpaper-drop')
            leave: (elem) ->
                $(element).removeClass('wallpaper-drop')
            end: ->
                $(element).removeClass('wallpaper-drop')
            canAccept: (elem, e) ->
                images.length = 0
                for item in elem.dragObject.items
                    if item.type == 'image'
                        images.push item
                images.length > 0
            drop: (elem, e) ->
                # Add wallpapers to user settings
                for item in images
                    account.user.wallpapers.unshift item.id if item.id not in account.user.wallpapers
                if account.user.wallpapers.length > 10
                    account.user.wallpapers.length = 10

                # Set first wallpaper as current
                scope.setWallpaper account.user.wallpapers[0]

                # Save user settings
                process = scope.progress.add()
                account.set
                    wallpapers: account.user.wallpapers
                , ->
                    scope.progress.finish process

                scope.$apply()
        true