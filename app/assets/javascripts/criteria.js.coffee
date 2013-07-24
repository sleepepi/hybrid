@markCriterium = (element) ->
  params = {}
  params.search_id = $(element).data('search-id')
  params.criterium_id = $(element).data('criterium-id')
  params.selected = $(element).is(':checked')
  $.post( root_url + "criteria/mark_selected", params, null, "script" )

@selectCriteria = (value, mapping_id) ->
  checkboxes = $("input[name='values[]']").prop('checked', false).change()
  checkbox = $("input[name='values[]'][value='#{value}']")
  if checkbox.is(':checked') and $("#criterium_mapping_id_#{mapping_id}").is(':checked')
    checkbox.prop('checked',false)
  else
    checkbox.prop('checked',true)
  checkbox.change()
  radio = $("#criterium_mapping_id_#{mapping_id}")
  radio.prop('checked', true)
  radio.change()

jQuery ->
  $(document)
    .on('click', '[data-object~="mark_criterium"]', () ->
      markCriterium(this)
    )
    .on('click', '[data-object~="select-checkbox"]', () ->
      selectCriteria($(this).data('value'), $(this).data('mapping-id'))
      false
    )
    .on('mouseover', '[data-object="toggle-delete-link"]', () -> $($(this).data('target')).show())
    .on('mouseout', '[data-object="toggle-delete-link"]', () -> $($(this).data('target')).hide())
