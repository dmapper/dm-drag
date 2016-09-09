#options
options =
  right: 25

module.exports = class DmDrag
  name: 'dm-drag'

  #Async init function
  initDrag: ->

    _arguments = arguments
    process.nextTick =>
      @_initDrag.apply this, _arguments

  _initDrag: (@baseEl, @parentSelector, @fullWidth) ->

    return unless @baseEl
    @dom.on 'mousedown', @baseEl, @_focus.bind( @ )

  _focus: (e) ->
    mouseY = e.clientY
    mouseX = e.clientX

    width = @fullWidth and @baseEl.getBoundingClientRect()?.width || options.right

    #Calculate
    return if mouseX > @baseEl.getBoundingClientRect().left + width

    #Get the moving element and calculated him position in the array
    @currentEl = e.target.closest(@parentSelector)
    return if !@currentEl and @baseEl is @currentEl
    @startElPosition = @currentEl.dataset.order

    #Add class for the current element
    @currentEl.classList.add '-moved'

    #Calculated element position relative to the mouse cursor
    @startY = @currentEl.getBoundingClientRect().top
    @currentSpacer = @currentEl.getBoundingClientRect().height / 2

    #Star move position for the current element
    @currentEl.style.top = "#{mouseY - @startY + @currentSpacer}px"

    #Add events from mouseup and mousemove
    window.addEventListener 'mousemove', @_move, false
    window.addEventListener 'mouseup', @_drop, false

  _move: (e) =>
    event.preventDefault()
    mouseY = e.clientY
    focusEl = e.target.closest(@parentSelector)
    lastChild = null

    #add new class if user create mousemove event below base element
    if mouseY > @baseEl.getBoundingClientRect().bottom
      lastChild = @baseEl.querySelector("#{@parentSelector}:last-child")
      lastChild.classList.add '-last'

    return unless focusEl
    @currentEl.style.top = "#{mouseY - @startY + @currentSpacer}px"

    return if @currentEl in [focusEl, lastChild]
    #Add class for the focuse elements and remove class for the siblings
    for selector in focusEl.parentNode.getElementsByTagName('*')
      selector.classList.remove '-focused'
      selector.classList.remove '-last'

    focusEl.classList.add '-focused'

  #Function will clear all events if happened the mouseup event and drop element in the
  #current position in array
  _drop: (e) =>

    focusEl = e.target.closest(@parentSelector)

    topBorder = @baseEl.getBoundingClientRect().top > e.clientY
    bottomBorder = @baseEl.getBoundingClientRect().bottom < e.clientY
    endElPosition = false

    #calculated position if user create mouseup event inside base element
    if focusEl
      #Get the drop element position and put element in drop position
      focusElPosition = focusEl.dataset.order
      endElPosition = if @startElPosition < focusElPosition then focusElPosition - 1 else focusElPosition

    #calculated position if user create mouseup event higher base element
    endElPosition = 0 if topBorder

    #calculated position if user create mouseup event below base element
    endElPosition = @model.get('scopeModel').length - 1 if bottomBorder

    # If value of 'emitter' attribute is truthy emit 'change' event with
    # previous and new position as arguments, otherwise move elements in the
    # model array
    if endElPosition or endElPosition is 0
      if @getAttribute('emitter')
        @emit 'change', @startElPosition, endElPosition
      else
        @model.move 'scopeModel', @startElPosition, endElPosition

    #Remove class from the current element
    @currentEl.classList.remove '-moved'
    for selector in @baseEl.getElementsByTagName('*')
      selector.classList.remove '-focused'
      selector.classList.remove '-last'

    @currentEl.style.top = ''

    #Remove all events
    window.removeEventListener 'mousemove', @_move, false
    window.removeEventListener 'mouseup', @_drop, false
