# JavaScript Specific to Queries
jQuery ->
  $( "#query_form" ).submit()

  buildQuerySourceTypeahead()
  $("#selected_source_id").val('')

  buildQueryConceptTypeahead()
  $("#selected_concept_id").val('')

  $( "#query_concepts" )
    .sortable(
      axis: "y"
      stop: (event, ui) ->
        order = $(this).sortable('toArray').toString()
        $.post($("#query_concepts_form").attr("action"), "&order=#{order}", null, "script")
      cancel: 'span.errors_found, div.qc-cancel'
      helper: (event, draggable) ->
        "<div>"+draggable.children('[data-object~="query-draggable-helper"]').first().html()+"</div>"
    )

  $(document)
    .on('click', '[data-object~="folder-show-more"]', () ->
      $($(this).data('target')).show()
      $(this).hide()
      false
    )
    .on('click', '[data-object~="categorical-check-all"]', () ->
      checkAllCategoricalValues()
      false
    )
    .on('click', '[data-object~="categorical-uncheck-all"]', () ->
      uncheckAllCategoricalValues()
      false
    )
    .on('click', '[data-object~="operand-edit"]', () ->
      $('#query_concept_' + $(this).data('value') + '_rop_text').hide()
      $('#query_concept_' + $(this).data('value') + '_rop_select').show()
      false
    )
    .on('click', '[data-object~="operand-hide"]', () ->
      $('#query_concept_' + $(this).data('value') + '_rop_text').show()
      $('#query_concept_' + $(this).data('value') + '_rop_select').hide()
      false
    )

