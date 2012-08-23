jQuery ->
  $('.bubble-all-orange').CreateBubblePopup(
    innerHtml: ''
    themeName: 'all-orange'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'top'
    align: 'center'
    selectable: true
    distance: '10px'
  )

  $('.bubble-orange').CreateBubblePopup(
    innerHtml: ''
    themeName: 'orange'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'top'
    align: 'center'
    selectable: false
    distance: '0px'
    divStyle:
      'margin-top': '-8px'
  )

  $('#source').SetBubblePopupInnerHtml('Type in a data source here and hit <span style="color:black;font-weight:bold">&lt;Enter&gt;</span>!', true)

  $("#concept_search_term").SetBubblePopupInnerHtml('Search for Age, Gender, Body Mass Index and hit <span style="color:black;font-weight:bold">&lt;Enter&gt;</span>!')

  $('.bubble-grey').CreateBubblePopup(
    innerHtml: ''
    themeName: 'orange'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'right'
    align: 'middle'
    distance: '0px'
  )

  $("#open_sources").SetBubblePopupInnerHtml('Click here to browse data sources!')

  $("#open_concepts").SetBubblePopupInnerHtml('Click here to browse concepts!')

  $("#add_dataset_tab").SetBubblePopupInnerHtml('Click to create a new dataset!')
  $("#add_report_tab").SetBubblePopupInnerHtml('Click to create a new report!')

  $('.bubble-azure').CreateBubblePopup(
    innerHtml: ''
    themeName: 'orange' #'azure'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'top'
    align: 'center'
    distance: '20px'
  )

  $("#select_all").SetBubblePopupInnerHtml('Select All Concepts')

  $("#select_none").SetBubblePopupInnerHtml('Deselect All Concepts')

  $("#increase_indent").SetBubblePopupInnerHtml('Increase Indent')

  $("#decrease_indent").SetBubblePopupInnerHtml('Decrease Indent')

  $("#undo").SetBubblePopupInnerHtml('Undo Last Change')

  $("#redo").SetBubblePopupInnerHtml('Redo Last Change')

  $("#expand_popup").SetBubblePopupInnerHtml('Expand the Popup')
  $("#collapse_popup").SetBubblePopupInnerHtml('Collapse the Popup')

  $('.bubble-green').CreateBubblePopup(
    innerHtml: ''
    themeName: 'green'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'top'
    align: 'center'
    distance: '20px'
  )

  $("#copy_concepts").SetBubblePopupInnerHtml('Copy Selected Concepts')

  $('.bubble-all-grey').CreateBubblePopup(
    innerHtml: ''
    themeName: 'all-grey'
    themePath: root_url + 'assets/jquerybubblepopup-theme/'
    position: 'top'
    align: 'center'
    distance: '20px'
  )

  $("#remove_concepts").SetBubblePopupInnerHtml('Remove Selected Concepts')



  $('.loader').on("ajax:before", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/contour/ajax-loader.gif')
  )

  $("#select_all").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/checkbox_checked_16.png')
  )

  $("#select_none").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/checkbox_unchecked_16.png')
  )

  $("#increase_indent").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/indent_increase_16.png')
  )

  $("#decrease_indent").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/indent_decrease_16.png')
  )

  # $("#undo, #redo").on("ajax:complete", (element, e) ->
  #   img_undo = $('#undo_img')
  #   img_redo = $('#redo_img')
  #   img_undo.attr('src', root_url + 'assets/' + img_undo.attr('data-img-'+img_undo.attr('data-img-state')))
  #   img_redo.attr('src', root_url + 'assets/' + img_redo.attr('data-img-'+img_redo.attr('data-img-state')))
  # )

  # $("#undo").on("ajax:complete", (element, e) ->
  #   img_el = $('#' + this.id + '_img')
  #   if img_el.attr('data-img-state') == 'disabled'
  #     img_el.attr('src', root_url + 'assets/' + img_el.attr('data-img-disabled'))
  #   else
  #     img_el.attr('src', root_url + 'assets/icons/gentleface/undo_16.png')
  # )
  #
  # $("#redo").on("ajax:complete", (element, e) ->
  #   img_el = $('#' + this.id + '_img')
  #   if img_el.attr('data-img-state') == 'disabled'
  #     img_el.attr('src', root_url + 'assets/' + img_el.attr('data-img-disabled'))
  #   else
  #     img_el.attr('src', root_url + 'assets/icons/gentleface/redo_16.png')
  # )

  $("#copy_concepts").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/clipboard_copy_16.png')
  )

  $("#remove_concepts").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/trash_16.png')
  )
