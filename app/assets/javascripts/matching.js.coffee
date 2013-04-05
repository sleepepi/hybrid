# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document)
    .on('click', '[data-object~="variable_add"]', () ->
      $.post(root_url + 'matching/add_variable', $("#matching-form").serialize(), null, "script")
      false
    )
    .on('click', '[data-object~="criteria_add"]', () ->
      $.post(root_url + 'matching/add_criteria', $("#matching-form").serialize(), null, "script")
      false
    )
    .on('change', '[data-object~="matching-form-option"]', () ->
      showWaiting("#matching", "", true)
      $("#matching-form").submit()
    )
    .on('click', '[data-object~="refresh-matches"]', () ->
      showWaiting("#matching", "", true)
      $("#matching-form").submit()
      false
    )
    .on('click', '[data-object~="remove-matching-group"]', () ->
      $(this).closest('[data-object~="remove-matching-group-parent"]').remove()
      showWaiting("#matching", "", true)
      $("#matching-form").submit()
      false
    )
