buzzlike.directive 'lazyTasks', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element
        body = elem.parents('.leftPanel')
        elem.on 'mousewheel', (e) ->
            scope.$parent.tasksScrollValue = elem[0].scrollTop
            # console.log elem[0].scrollTop, scope.taskParams.pageSize * (scope.taskParams.page), scope.taskParams
            if scope.taskParams.isLoading == true 
                return

            if elem[0].scrollTop == 0 and scope.taskParams.reloadOnStart == true
                scope.taskParams.reloadOnStart = false
                scope.resetTaskList()
                scope.fetchTasksPage()
                scope.$apply()

            else if scope.taskParams.pageSize * (scope.taskParams.page) < scope.taskParams.total
                if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
                    scope.fetchTasksPage()
                    scope.$apply()