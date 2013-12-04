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

@changeRightOperator = (element, index) ->
  element = $(element)
  $('#selected_right_operator_criterium_id').val(index)
  $('#criterium_right_operator').val(element.val())
  $.post($("#right_operator_criteria_form").attr("action"), $("#right_operator_criteria_form").serialize(), null, "script")

@switchOnTrueMouseOut = (index) ->
  element = $('#criterium_' + index + '_rop_select')
  element.mouseout((e, handler) ->
    if isTrueMouseOut(e||window.event, this)
      $('#criterium_' + index + '_rop_select').hide()
      $('#criterium_' + index + '_rop_text').show()
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
      data: (term, page) -> { search: term, autocomplete: 'true', search_id: $('#report_concept_search_term').data('search-id') }
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

@color_radio_group = (group_name) ->
  $(":radio[name='" + group_name + "']").each( (index, element) ->
    if $(element).prop('checked')
      $(element).parent().addClass('selected')
    else
      $(element).parent().removeClass('selected')
  )

@ready = () ->
  contourReady()
  $("input[rel=tooltip]").tooltip()
  $("a[rel~=tooltip]").tooltip()
  $("#table_columns_search select, #table_columns_search input").change( () ->
    $.get($("#table_columns_search").attr("action"), $("#table_columns_search").serialize(), null, "script")
    showWaiting('#table_content', ' Loading Table Mappings', true)
    false
  )
  loadRulesReady()
  loadSearchReady()

$(document).ready(ready)
$(document).on('page:load', ready)

jQuery ->
  # Show and hide a delete icon on mouseover and mouseout for criteria
  $(document)
    .on('mouseover', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/delete.png'))
    .on('mouseout', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/blank.png'))

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
    .on('change', '.radio input:radio', () ->
      group_name = $(this).attr('name')
      color_radio_group(group_name)
    )
