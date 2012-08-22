# Global functions referenced from HTML
@increaseSelectedIndex = (element) ->
  num_options = $(element + ' option').size()
  element = $(element)
  next_index = 0
  if element.attr('selectedIndex') <= 0
    return false
  else
    next_index = element.attr('selectedIndex') - 1
  element.attr('selectedIndex', next_index)
  element.change()

@decreaseSelectedIndex = (element) ->
  num_options = $(element + ' option').size()
  element = $(element)
  next_index = 0
  if element.attr('selectedIndex') < num_options - 1
    next_index = element.attr('selectedIndex') + 1
  else
    return false
  element.attr('selectedIndex', next_index)
  element.change()

@toggleCheckboxGroup = (index) ->
  mode = $('.rule_group_'+index+'_parent').is(':checked');
  $('.rule_group_'+index).each( () ->
    if mode then $(this).attr('checked','checked') else $(this).removeAttr('checked')
  )

@toggleCheckboxGroupParent = (index) ->
  mode = true
  $('.rule_group_'+index).each( () ->
    unless $(this).is(':checked')
      mode = false
  )
  if mode then $('.rule_group_'+index+'_parent').attr('checked','checked') else $('.rule_group_'+index+'_parent').removeAttr('checked')

@markQueryConcept = (element, index) ->
  element = $(element)
  $('#selected_query_concept_id').val(index)
  $('#query_concept_selected').val(element.is(':checked'))
  $.post($("#mark_query_concepts_form").attr("action"), $("#mark_query_concepts_form").serialize(), null, "script")

@changeRightOperator = (element, index) ->
  element = $(element)
  $('#selected_right_operator_query_concept_id').val(index)
  $('#query_concept_right_operator').val(element.val())
  $.post($("#right_operator_query_concepts_form").attr("action"), $("#right_operator_query_concepts_form").serialize(), null, "script")

@switchOnTrueMouseOut = (index) ->
  element = $('#query_concept_' + index + '_rop_select')
  element.mouseout((e, handler) ->
    if isTrueMouseOut(e||window.event, this)
      $('#query_concept_' + index + '_rop_select').hide()
      $('#query_concept_' + index + '_rop_text').show()
  )

@checkAllCategoricalValues = () ->
  elements = $('.categorical_values').each( () ->
    $(this).attr('checked','checked')
  )

@uncheckAllCategoricalValues = () ->
  elements = $('.categorical_values').each( () ->
    $(this).removeAttr('checked')
  )
