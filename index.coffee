# options
DEFAULT_OPTIONS =
  right: 25

module.exports = class DmDraggable
  name: 'dm-draggable'

  # Async init function
  initDrag: (options) ->
    {
      @baseEl,
      @parentSelector,
      @fullWidth,
      @disablePreventDefaultOnFocus
    } = options
    process.nextTick =>
      @_initDrag()

  _initDrag: ->
    return unless @baseEl
    @dom.on 'mousedown', @baseEl, @_focus.bind( @ )
    @dom.on 'touchstart', @baseEl, @_focus.bind( @ )

  _focus: (e) ->
    e.preventDefault() unless @disablePreventDefaultOnFocus
    { _event, mouseX, mouseY } = @_getEventData e

    {
      width: baseElWidth
      left: baseElLeft
    } = @baseEl.getBoundingClientRect() or {}
    width = @fullWidth and baseElWidth or DEFAULT_OPTIONS.right

    # Calculate
    return if mouseX > baseElLeft + width

    # Get the moving element and calculate his position in the array
    @currentEl = _event.target.closest @parentSelector
    return if !@currentEl and @baseEl is @currentEl
    @startElPosition = @currentEl.dataset.order

    # Add class for the current element
    @currentEl.classList.add '-moved'

    # Calculated element position relative to the mouse cursor
    {
      height: currentElHeight
      top: currentElTop
    } = @currentEl.getBoundingClientRect() or {}
    @startY = currentElTop
    @currentSpacer = currentElHeight / 2

    # Star move position for the current element
    @currentEl.style.top = "#{ mouseY - @startY + @currentSpacer }px"

    # Add listeners for mouseup and mousemove
    window.addEventListener 'mousemove', @_move, false
    window.addEventListener 'mouseup', @_drop, false

    # Add listeners for touchend and touchmove
    window.addEventListener 'touchmove', @_move, false
    window.addEventListener 'touchend', @_drop, false

  _move: (e) =>
    e.preventDefault()
    { _event, mouseX, mouseY } = @_getEventData e

    focusEl = @_getFocusElement mouseX, mouseY

    lastChild = null

    # add new class if user create mousemove event below base element
    if mouseY > @baseEl.getBoundingClientRect().bottom
      lastChild = @baseEl.querySelector("#{ @parentSelector }:last-child")
      lastChild.classList.add '-last'

    return unless focusEl
    @currentEl.style.top = "#{ mouseY - @startY + @currentSpacer }px"

    return if @currentEl in [focusEl, lastChild]
    # Add class for the focuse elements and remove class for the siblings
    for selector in focusEl.parentNode.getElementsByTagName('*')
      selector.classList.remove '-focused'
      selector.classList.remove '-last'

    focusEl.classList.add '-focused'

  # Function will clear all events if happened the mouseup event and drop
  # element in the current position in array
  _drop: (e) =>
    { _event, mouseX, mouseY } = @_getEventData e

    focusEl = @_getFocusElement mouseX, mouseY

    {
      top: baseElTop
      bottom: baseElBottom
    } = @baseEl.getBoundingClientRect() or {}

    topBorder = baseElTop > mouseY
    bottomBorder = baseElBottom < mouseY
    endElPosition = false

    # Calculate position if user creates mouseup event inside base element
    if focusEl
      # Get the drop element position and put element in drop position
      focusElPosition = focusEl.dataset.order
      endElPosition = if @startElPosition < focusElPosition
        focusElPosition - 1
      else
        focusElPosition

    # Calculate position if user creates mouseup event above base element
    endElPosition = 0 if topBorder

    # Calculate position if user creates mouseup event below base element
    endElPosition = @model.get('scopeModel').length - 1 if bottomBorder

    # If value of 'emitter' attribute is truthy emit 'change' event with
    # previous and new position as arguments, otherwise move elements in the
    # model array
    if endElPosition or endElPosition is 0
      if @getAttribute('emitter')
        @emit 'change', @startElPosition, endElPosition
      else
        @model.move 'scopeModel', @startElPosition, endElPosition

    # Remove class from the current element
    @currentEl.classList.remove '-moved'
    for selector in @baseEl.getElementsByTagName('*')
      selector.classList.remove '-focused'
      selector.classList.remove '-last'

    @currentEl.style.top = ''

    # Remove all listeners
    window.removeEventListener 'mousemove', @_move, false
    window.removeEventListener 'touchmove', @_move, false
    window.removeEventListener 'mouseup', @_drop, false
    window.removeEventListener 'touchend', @_drop, false

  _getEventData: (e) ->
    touchEventObj = e.changedTouches?[0]
    _event = touchEventObj or e

    mouseY = _event.clientY
    mouseX = _event.clientX

    { _event, mouseX, mouseY }

  _getFocusElement: (mouseX, mouseY) ->
    document.elementFromPoint(mouseX, mouseY)?.closest @parentSelector
