jQuery ->
  window.$report_name_input = $( "#report_name")

  # modal dialog init: custom buttons and a "close" callback reseting the form inside
  window.$new_report_dialog = $( "#new_report_dialog" ).dialog(
      autoOpen: false
      modal: true
      buttons:
        "Create Report": () ->
          $.post($("#new_report_form").attr("action"), $("#new_report_form").serialize(), null, "script")
          $( this ).dialog( "close" )
        Cancel: () -> $( this ).dialog( "close" )
      open: () ->
        window.$report_name_input.focus()
      close: () ->
        $form[ 0 ].reset()
  )

  # addTab form: calls addTab function on submit and closes the dialog
  $form = $( "form", window.$new_report_dialog ).submit( () ->
    window.$new_report_dialog.dialog( "close" )
    false
  )

  # addTab button: just opens the dialog
  $(document).on('click', "#add_report_tab", () -> window.$new_report_dialog.dialog( "open" ) )
