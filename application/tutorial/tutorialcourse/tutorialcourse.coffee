buzzlike.directive "tutorialcourse", ($rootScope, tutorialService, optionsList, account) ->
    restrict: "C"
    template: templateCache['/tutorial/tutorialcourse']
    link: (scope, element, attrs) ->
        scope.status = {}

        actions = [
            {
                text: 'textEditor_yes'
                action: ->
                    angular.element($('.tutorialcourse')).scope().cancelLesson()
            },
            {
                text: 'textEditor_no'
                action: ->
                    true
            }
        ]

        scope.$watch () ->
            tutorialService.status.show
        , (nValue) ->
            if nValue?
                if nValue
                    $('.tutorialcourse').show()
                    $(window).off 'click'
                    $(window).on 'click', cancelCourse
                else
                    $(window).off 'click'
                    $('.tutorialcourse').hide()
        , true

        scope.$watch () ->
            tutorialService.status
        , (nValue) ->
            if nValue?
                scope.status = nValue
        , true

        scope.prevLesson = () ->
            switchLesson('prev')

        scope.nextLesson = (handClick) ->
            if handClick? and scope.status.currentLesson.nextbutton == 'lock'
                return false
            switchLesson('next')

        scope.openOptionsList = ->
            optionsList.init 'tutorial_close', actions
            $rootScope.$apply()

        scope.cancelLesson = () ->
            # Если это последний шаг в курсе, то сохраняем его как пройденный
            if scope.status.currentLesson?
                if scope.status.last
                    scope.passCourse()
                else
                    if !scope.status.currentCourse.passed
                        scope.status.currentCourse.canceled = true

                    scope.status.show = false

                    $.ajax
                        url: 'http://tutorial.buzzlike.pro/back/cancelcourse'
                        type: 'POST'
                        data: { userid: account.user.userId, code: scope.status.currentCourse.code }
                        dataType: 'JSON'
                        success: (data) ->
                            true

                tutorialService.status.currentLesson = null
                tutorialService.status.currentCourse = null

        scope.passCourse = () ->
            scope.status.currentCourse.canceled = false
            scope.status.currentCourse.passed = true
            scope.status.show = false

            $.ajax
                url: 'http://tutorial.buzzlike.pro/back/passcourse'
                type: 'POST'
                data: { userid: account.user.userId, code: scope.status.currentCourse.code }
                dataType: 'JSON'
                success: (data) ->
                    tutorialService.status.currentLesson = null
                    tutorialService.status.currentCourse = null
                    true

        switchLesson = (where) ->

            if where == 'next'
                cur = 1
            else
                cur = -1

            for lesson,i in scope.status.currentCourse.lessons
                if lesson.code == scope.status.currentLesson.code
                    index = i+cur

                    if where == 'next'
                        lessonOfService = tutorialService.getNextLesson()
                    else
                        lessonOfService = tutorialService.getPrevLesson()

                    tutorialService.showLesson scope.status.currentCourse.code, lessonOfService.lesson.code, true

                    tutorialService.status.selectedStep = index+1
                    if index == 0
                        tutorialService.setTutorialStep 'first'
                    else if index == scope.status.currentCourse.lessons.length-1
                        tutorialService.setTutorialStep 'last'
                        tutorialService.hideArrows()
                    else
                        tutorialService.setTutorialStep 'middle'

                    break

        cancelCourse = (e) ->
            # if !$(e.target).hasClass('tutorialCourseTagForce') and $(e.target).parents('.tutorialCourseTagForce').length == 0 and !$(e.target).hasClass('option')
            #     if !$(e.target).hasClass(scope.status.currentLesson.code) and $(e.target).parents('.'+scope.status.currentLesson.code).length == 0
            #         if !$(e.target).hasClass(tutorialService.getNextLesson().lesson.code) and $(e.target).parents('.'+tutorialService.getNextLesson().lesson.code).length == 0
            #             optionsList.init 'tutorial_close', actions
            #             $rootScope.$apply()

            # if !$(e.target).hasClass('tutorialCourseTagForce') and $(e.target).parents('.tutorialCourseTagForce').length == 0
            #     if !$(e.target).hasClass('tutorialcourse') and $(e.target).parents('.tutorialcourse').length == 0 and !$(e.target).hasClass('option')
            #         if !$(e.target).hasClass(scope.status.currentLesson.code) and $(e.target).parents('.'+scope.status.currentLesson.code).length == 0
            #             if !$(e.target).hasClass(tutorialService.getPrevLesson().lesson.code) and $(e.target).parents('.'+tutorialService.getPrevLesson().lesson.code).length == 0
            #                 if !$(e.target).hasClass(tutorialService.getNextLesson().lesson.code) and $(e.target).parents('.'+tutorialService.getNextLesson().lesson.code).length == 0
            #                     optionsList.init 'tutorial_close', actions
            #                     $rootScope.$apply()

        init = ->
            $(window).on 'resize', tutorialService.setPosition

        init()
