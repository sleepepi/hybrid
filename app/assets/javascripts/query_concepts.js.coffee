@markQueryConcept = (element) ->
  params = {}
  params.search_id = $(element).data('search-id')
  params.query_concept_id = $(element).data('query-concept-id')
  params.selected = $(element).is(':checked')
  $.post( root_url + "query_concepts/mark_selected", params, null, "script" )

jQuery ->
  $(document)
    .on('click', '[data-object~="mark_query_concept"]', () ->
      markQueryConcept(this)
    )
    .on('click', '[data-object~="select-checkbox"]', () ->
      checkbox = $("input[name='values[]'][value='#{$(this).data('value')}']")
      if checkbox.is(':checked')
        checkbox.prop('checked',false)
      else
        checkbox.prop('checked',true)
      checkbox.change()
      false
    )
    .on('mouseover', '[data-object="toggle-delete-link"]', () -> $($(this).data('target')).show())
    .on('mouseout', '[data-object="toggle-delete-link"]', () -> $($(this).data('target')).hide())
