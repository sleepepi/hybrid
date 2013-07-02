@checkAllChoices = () ->
  elements = $('.choices').each( () ->
    $(this).prop('checked', true)
    $(this).change()
  )

@uncheckAllChoices = () ->
  elements = $('.choices').each( () ->
    $(this).prop('checked', false)
    $(this).change()
  )

@formatConceptResult = (concept) ->
  markup = ""
  markup = "<span class='muted'>" unless concept.commonly_used
  markup += concept.text
  markup += "</span>" unless concept.commonly_used
  markup

@buildQueryConceptTypeahead = () ->
  $("#variable_search").select2(
    placeholder: "Select a variable"
    minimumInputLength: 1
    width: 'resolve'
    initSelection: (element, callback) ->
      callback([])
    ajax:
      url: root_url + "queries/#{$('#variable_search').data('query-id')}/autocomplete"
      dataType: 'json'
      data: (term, page) -> { search: term }
      results: (data, page) -> # parse the results into the format expected by Select2.
          return results: data
    formatResult: formatConceptResult
  ).on("change", (e) ->
    if $("#variable_search").val() != ""
      $("#variable_search").select2("val", "")
      params = {}
      params.query_id = $(this).data('query-id')
      params.variable_id = e.val
      showWaiting('#concept_folders', 'Loading', false)
      $.post(root_url + "query_concepts", params, null, "script")
  )

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
      checkAllChoices()
      false
    )
    .on('click', '[data-object~="categorical-uncheck-all"]', () ->
      uncheckAllChoices()
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

