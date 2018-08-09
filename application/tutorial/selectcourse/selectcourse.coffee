buzzlike.directive "selectcourse", ($rootScope, tutorialService, stateManager) ->
    restrict: "C"
    template: templateCache['/tutorial/selectcourse']
    link: (scope, element, attrs) ->
        scope.courseList = []
        builded = false

        tutorialState =
            'escape': () ->
                scope.hideCourseList()
                stateManager.goBack()

        scope.$watch () ->
            tutorialService.status.courses
        , (nValue) ->
            if nValue? and !builded
                buildCourseList()
                builded = true
        , true

        buildCourseList = () ->
            scope.courseList = []
            for course in tutorialService.status.courses
                course.show = false
                scope.courseList.push course

        scope.init = ->
            stateManager.applyState tutorialState

        scope.hideCourseList = ->
            $('.selectcourse').remove()
            true

        scope.toggleCourse = (course) ->
            if !course.locked
                for courseItem in tutorialService.status.courses
                    courseItem.show = false

                course.show = true

        scope.openCourse = (course) ->
            tutorialService.showLesson course.code, null, true
            scope.hideCourseList()

        scope.init()