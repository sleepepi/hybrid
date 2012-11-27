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

@buildMappingTypeahead = (column, source_id) ->
  $('[data-object~="mapping-typeahead"]').typeaheadmap(
    source: (query, process) ->
      return $.get(root_url + 'mappings/typeahead', { source_id: source_id, search: query }, (data) -> return process(data); );
    listener: (k,v) ->
      $("#new_concept_id").val(k)
      $("#new_column").val(column)
      $("#new_mapping_form").submit()
    #,"key": "id", "value": "value"
  )

@buildQuerySourceTypeahead = () ->
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
      $("#selected_source_id").val(e.val)
      $("#source").select2("val", "")
      $("#sources_form").submit()
  )

@formatConceptResult = (concept) ->
  markup = ""
  markup = "<span class='muted'>" unless concept.commonly_used
  markup += concept.text
  markup += "</span>" unless concept.commonly_used
  markup

@buildQueryConceptTypeahead = () ->
  $("#concept_search_term").select2(
    placeholder: "Search for a concept, i.e. Age, Gender"
    minimumInputLength: 1
    width: 'resolve'
    initSelection: (element, callback) ->
      callback([])
    ajax:
      url: root_url + "concepts"
      dataType: 'json'
      data: (term, page) -> { search: term, autocomplete: 'true', query_id: $('#concept_search_term').data('query-id') }
      results: (data, page) -> # parse the results into the format expected by Select2.
          return results: data
    formatResult: formatConceptResult
  ).on("change", (e) ->
    if $("#concept_search_term").val() != ""
      $("#selected_concept_id").val(e.val)
      $("#concept_search_term").select2("val", "")
      $("#search_form").submit()
  )

@buildReportConceptTypeahead = () ->
  $("#report_concept_search_term").select2(
    placeholder: "Search for a concept, i.e. Age, Gender"
    minimumInputLength: 1
    width: 'resolve'
    initSelection: (element, callback) ->
      callback([])
    ajax:
      url: root_url + "concepts"
      dataType: 'json'
      data: (term, page) -> { search: term, autocomplete: 'true', query_id: $('#report_concept_search_term').data('query-id') }
      results: (data, page) -> # parse the results into the format expected by Select2.
          return results: data
    formatResult: formatConceptResult
  ).on("change", (e) ->
    if $("#report_concept_search_term").val() != ""
      $("#selected_report_concept_id").val(e.val)
      $("#report_concept_search_term").select2("val", "")
      $("#report_concept_search_form").submit()
  )

jQuery ->
  $("input[rel=tooltip]").tooltip()
  $("a[rel~=tooltip]").tooltip()

  $(document)
    .on('click', '[data-object~="submit"]', () ->
      $($(this).data('target')).submit()
      false
    )
    .on('click', '[data-object~="toggle"]', () ->
      $($(this).data('target')).toggle()
      false
    )
    .on('click', '[data-object~="modal-show"]', () ->
      $($(this).data('target')).modal( dynamic: true )
      false
    )

  # $('[data-object~="typeaheadmap"]').each( () ->
  #   $this = $(this)
  #   $this.typeaheadmap( source: $this.data('source'), "key": "key", "value": "value" )
  # )
