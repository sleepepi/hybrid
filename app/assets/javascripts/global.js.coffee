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
    $(this).prop('checked', mode)
  )

@toggleCheckboxGroupParent = (index) ->
  mode = true
  $('.rule_group_'+index).each( () ->
    unless $(this).is(':checked')
      mode = false
  )
  $('.rule_group_'+index+'_parent').prop('checked',mode)

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
    $(this).prop('checked', true)
  )

@uncheckAllCategoricalValues = () ->
  elements = $('.categorical_values').each( () ->
    $(this).prop('checked', false)
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

@showContourModal = () ->
  $("#contour-backdrop, .contour-modal-wrapper").show()
  # $('html, body').animate({ scrollTop: $(".contour-modal-wrapper").offset().top - 40 }, 'fast');

@hideContourModal = () ->
  $("#contour-backdrop, .contour-modal-wrapper").hide()

@loadPeity = () ->
  $.each($('[data-object~="sparkline"]'), () ->
    $(this).show()
    if $(this).data('type') == 'box'
      minValue = undefined
      minValue = parseInt($(this).data('min')) unless isNaN(parseInt($(this).data('min')))
      maxValue = undefined
      maxValue = parseInt($(this).data('max')) unless isNaN(parseInt($(this).data('max')))

      $(this).sparkline($(this).data('values'),
        type: $(this).data('type')
        chartRangeMin: minValue
        chartRangeMax: maxValue
      )
    else if $(this).data('type') == 'pie'
      $(this).sparkline($(this).data('values'),
        type: $(this).data('type')
      )
  )

jQuery ->
  $("input[rel=tooltip]").tooltip()
  $("a[rel~=tooltip]").tooltip()

  $("#table_columns_search select, #table_columns_search input").change( () ->
    $.post($("#table_columns_search").attr("action"), $("#table_columns_search").serialize(), null, "script")
    showWaiting('#table_content', ' Loading Table Mappings', true)
    false
  )

  $("#source_rule_user_tokens").tokenInput(root_url + "users.json"
    crossDomain: false
    prePopulate: $("#source_rule_user_tokens").data("pre")
    theme: "facebook"
    preventDuplicates: true
  )

  # Show and hide a delete icon on mouseover and mouseout for query_concepts
  $(document)
    .on('mouseover', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/delete.png'))
    .on('mouseout', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/blank.png'))

  $(document)
    .on('mouseover', ".smudge", () -> $(this).attr('src', $(this).attr('src').replace(/(-(.*?))?.png/, '_g1.png')))
    .on('mouseout', ".smudge",  () -> $(this).attr('src', $(this).attr('src').replace(/(-(.*?))?_g1.png/, '.png')))

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
    .on('click', "#contour-backdrop", (e) ->
      hideContourModal() if e.target.id = "contour-backdrop"
    )
    .on('click', '[data-object~="show-contour-modal"]', () ->
      showContourModal()
      false
    )
    .on('click', '[data-object~="hide-contour-modal"]', () ->
      hideContourModal()
      false
    )
    .on('change', '.checkbox input:checkbox', () ->
      if $(this).is(':checked')
        $(this).parent().addClass('selected')
      else
        $(this).parent().removeClass('selected')
    )
