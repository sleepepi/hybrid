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

@buildSearchSourceTypeahead = () ->
  $("#source").select2(
    placeholder: "Select a data source"
    width: 'resolve'
    initSelection: (element, callback) ->
      callback([])
    ajax:
      url: root_url + "sources"
      dataType: 'json'
      data: (term, page) -> { search: term, autocomplete: 'true' }
      results: (data, page) -> # parse the results into the format expected by Select2.
          return results: data
  ).on("change", (e) ->
    if $("#source").val() != ""
      $("#source").select2("val", "")
      params = {}
      params.search_id = $(this).data('search-id')
      params.query_source = {}
      params.query_source.source_id = e.val
      showWaiting('#query_sources', 'Loading Sources', false)
      $.post(root_url + "query_sources", params, null, "script")
  )

@buildQueryConceptTypeahead = () ->
  $("#variable_search").select2(
    placeholder: "Select a variable"
    minimumInputLength: 1
    width: 'resolve'
    initSelection: (element, callback) ->
      callback([])
    ajax:
      url: root_url + "searches/#{$('#variable_search').data('search-id')}/autocomplete"
      dataType: 'json'
      data: (term, page) -> { search: term }
      results: (data, page) -> # parse the results into the format expected by Select2.
          return results: data
    formatResult: formatConceptResult
  ).on("change", (e) ->
    if $("#variable_search").val() != ""
      $("#variable_search").select2("val", "")
      params = {}
      params.search_id = $(this).data('search-id')
      params.variable_id = e.val
      showWaiting('#concept_folders', 'Loading', false)
      $.post(root_url + "query_concepts", params, null, "script")
  )

@submitSearchName = () ->
  $.post(root_url + "searches/#{$("#search_name").data('search-id')}", "_method=patch" + "&" + $("#search_name").serialize(), null, "script")

@cancelSearchNameEdit = () ->
  $.get(root_url + "searches/#{$("#search_name").data('search-id')}", null, null, "script")

jQuery ->
  $( "#search_form" ).submit()

  buildSearchSourceTypeahead()
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
    .on('click', '[data-object~="save_search_name"]', () ->
      submitSearchName()
      false
    )
    .on("keyup", "#search_name", (event) ->
      if event.which == 13
        submitSearchName()
      else if event.which == 27
        cancelSearchNameEdit()
    )

