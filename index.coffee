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

  _initDrag: (@baseEl, @parentSelector) ->

    return unless @baseEl
    @dom.on 'mousedown', @baseEl, @_focus.bind( @ )

  _focus: (e) ->
    mouseY = e.clientY
    mouseX = e.clientX

    #Calculate
    return if mouseX > @baseEl.getBoundingClientRect().left + options.right

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
    @baseEl.addEventListener 'mousemove', @_move, false
    window.addEventListener 'mouseup', @_drop, false

  _move: (e) =>
    event.preventDefault()
    mouseY = e.clientY
    focusEl = e.target.closest(@parentSelector)
    return unless focusEl
    @currentEl.style.top = "#{mouseY - @startY + @currentSpacer}px"

    #Add class for the focuse elements and remove class for the siblings
    for selector in focusEl.parentNode.getElementsByTagName('*')
      selector.classList.remove '-focused'

    focusEl.classList.add '-focused'

  #Function will clear all events if happened the mouseup event and drop element in the
  #current position in array
  _drop: (e) =>

    focusEl = e.target.closest(@parentSelector)
    return unless focusEl
    #Get the drop element position and put element in drop position
    focusElPosition = focusEl.dataset.order
    endElPosition = if @startElPosition < focusElPosition then focusElPosition - 1 else focusElPosition
    @model.move 'scopeModel', @startElPosition, endElPosition

    #Remove class from the current element
    @currentEl.classList.remove '-moved'
    for selector in focusEl.parentNode.getElementsByTagName('*')
      selector.classList.remove '-focused'
    @currentEl.style.top = ''

    #Remove all events
    @baseEl.removeEventListener 'mousemove', @_move, false
    window.removeEventListener 'mouseup', @_drop, false
