# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document)
    .on('click', '[data-object~="variable_add"]', () ->
      $.post(root_url + 'matching/add_variable', $("#matching-form").serialize(), null, "script")
      false
    )
    .on('change', '[data-object~="matching-form-option"]', () ->
      $("#matching-form").submit()
    )
