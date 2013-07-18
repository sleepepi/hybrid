@markQueryConcept = (element) ->
  params = {}
  params.query_id = $(element).data('query-id')
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
