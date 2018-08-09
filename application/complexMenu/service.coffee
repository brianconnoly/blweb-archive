buzzlike.service 'complexMenu', (stateManager) ->

    class itemClass

        constructor: ->
            @showed = false
            @workarea = null

            true

        show: (@sections, @position, @object) ->
            if @state == true
                hide()
                # return

            # Prepare position
            workarea = $('#workarea') if !workarea?
            workareaWid = workarea.width()
            workareaHei = workarea.height()

            # Count length
            len = 0
            keys = @sections.length
            for section in @sections
                # keys++
                len += 10 + section.items.length * (18 + 6)

            if keys > 1
                len += (keys-1)*1

            if len > workareaHei
                @position.top = 0
                @position.height = workareaHei - 10
                len = workareaHei

            if @position.top + len > workareaHei
                @position.top = workareaHei - len

            if @position.left + 200 > workareaWid
                @position.left = 'auto'
                @position.right = 0

            @showed = true
            stateManager.applyState
                'escape': @hide
            true

        hide: =>
            if @showed != true
                return

            @showed = false
            stateManager.goBack true
            true
            
    new itemClass()