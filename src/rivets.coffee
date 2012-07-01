#     rivets.js
#     version : 0.1.4
#     author : Michael Richards
#     license : MIT

# The Rivets namespace.
Rivets = {}

# A single binding between a model attribute and a DOM element.
class Rivets.Binding
  # All information about the binding is passed into the constructor; the DOM
  # element, the type of binding, the context object and the keypath at which to
  # listed to for changes.
  constructor: (@el, @type, @context, @keypath) ->
    @routine = Rivets.bindings[@type] || attributeBinding @type

  # Sets a value for this binding. Basically just runs the routine on the
  # element with a suplied value.
  set: (value = null) =>
    @routine @el, value || Rivets.config.adapter.read @context, @keypath

  # Subscribes to the context object for changes on the specific keypath.
  # Conditionally also does the inverse and listens to the element for changes
  # to propogate back to the context object.
  bind: =>
    @set() if Rivets.config.preloadData
    Rivets.config.adapter.subscribe @context, @keypath, (value) => @set value

    if @type in bidirectionals
      @el.addEventListener 'change', (el) =>
        Rivets.config.adapter.publish @context, @keypath, getInputValue el

# Returns the current input value for the specified element.
getInputValue = (el) ->
  switch el.type
    when 'text', 'textarea', 'password', 'select-one' then el.value
    when 'checkbox', 'radio' then el.checked

# Returns an attribute binding routine for the specified attribute. This is what
# `registerBinding` falls back to when there is no routine for the binding type.
attributeBinding = (attr) -> (el, value) ->
  if value then el.setAttribute attr, value else el.removeAttribute attr

# Returns a state binding routine for the specified attribute. Can optionally be
# negatively evaluated. This is used to build a lot of the core state binding
# routines.
stateBinding = (attr, inverse = false) -> (el, value) ->
  binding = attributeBinding(attr)
  binding el, if inverse is !value then attr else false

# Bindings that should also be observed for changes on the DOM element in order
# to propogate those changes back to the model object.
bidirectionals = ['value', 'checked', 'unchecked', 'selected', 'unselected']

# Core binding routines.
Rivets.bindings =
  checked:
    stateBinding 'checked'
  selected:
    stateBinding 'selected'
  disabled:
    stateBinding 'disabled'
  unchecked:
    stateBinding 'checked', true
  unselected:
    stateBinding 'selected', true
  enabled:
    stateBinding 'disabled', true
  text: (el, value) ->
    el.innerText = value or ''
  html: (el, value) ->
    el.innerHTML = value or ''
  value: (el, value) ->
    el.value = value
  show: (el, value) ->
    el.style.display = if value then '' else 'none'
  hide: (el, value) ->
    el.style.display = if value then 'none' else ''

# Default configuration.
Rivets.config =
  preloadData: true

# The rivets module. This is the public interface that gets exported.
rivets =
  # Used to set configuration options and the adapter interface.
  configure: (options={}) ->
    for property, value of options
      Rivets.config[property] = value

  # Registers a new binding routine function that can be used immediately in the
  # view. This is what is used to add custom data bindings.
  register: (routine, routineFunction) ->
    Rivets.bindings[routine] = routineFunction

  # Binds a set of context objects to the specified DOM element.
  bind: (el, contexts = {}) ->
    bindings = []

    for node in el.getElementsByTagName '*'
      for attribute in node.attributes
        if /^data-/.test attribute.name
          type = attribute.name.replace 'data-', ''
          path = attribute.value.split '.'
          context = path.shift()
          keypath = path.join '.'
          bindings.push new Rivets.Binding node, type, contexts[context], keypath

    binding.bind() for binding in bindings
    bindings.length

# Exports rivets for both CommonJS and the browser.
if module?
  module.exports = rivets
else
  @rivets = rivets