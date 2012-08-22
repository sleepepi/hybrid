jQuery ->
  steps = [
     { target: $('#source'), title: 'Step 1:', content: 'Type in and select a data source for your search!' }
     { target: $('#concept_search_term'), title: 'Step 2:', content: 'Specify search concepts here, or browse by clicking the folder icon!' }
     { target: $('#remove_concepts'), title: 'Step 3', content: 'Tool bar to modify your search!', my: 'left center', at: 'right center' }
     { target: $('#total_records_found_display'), title: 'Step 4:', content: 'View your results!', my: 'top left', at: 'bottom right' }
     { target: $('#add_dataset_tab'), title: 'Step 5:', content: 'Create and download datasets!', my: 'bottom center', at: 'top center' }
     { target: $('#add_report_tab'), title: 'Step 6:', content: 'Generate dynamic summary reports!', my: 'bottom center', at: 'top center' }
     { target: $('#query_file_types'), title: 'Step 7:', content: 'Download associated files!', my: 'top center', at: 'bottom center' }
  ]
  
  $('#playpause-img').data('showTipTimer', 0)
  
  $(document.body).qtip(
    id: 'step' # Give it an ID of ui-tooltip-step so we an identify it easily
    content:
      text: steps[0].content # Use first steps content...
      title:
        text: steps[0].title # ...and title
        button: true
    position:
      my: steps[0].my || 'top center'
      at: steps[0].at || 'bottom center'
      target: steps[0].target # Also use first steps position target...
      viewport: $(window) # ...and make sure it stays on-screen if possible
    show:
      event: false # Only show when show() is called manually
      ready: false # Also show on page load
    hide: false # Don't hide unless we call hide()
    events:
      render: (event, api) ->
        # Grab tooltip element
        tooltip = api.elements.tooltip;
        # Track the current step in the API
        api.step = 0;
        # Bind custom custom events we can fire to step forward/back
        tooltip.on('next prev play_first play_last', (event) ->
          # Increase/decrease step depending on the event fired
          switch event.type 
            when 'next'
              api.step += 1
            when 'play_first'
              api.step = 0
            when 'play_last'
              api.step = steps.length - 1
            else
              api.step -= 1
          
          if api.step >= steps.length - 1
            $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') != 0
          
          api.step = Math.min(steps.length - 1, Math.max(0, api.step))

          # Set new step properties
          current = steps[api.step]
          if(current)
            api.set('content.text', current.content)
            api.set('content.title.text', current.title)
            api.set('position.target', current.target)
            api.set('position.my', current.my || 'top center')
            api.set('position.at', current.at || 'bottom center')
        )
      hide: (event, api) ->
      #   # $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') == 0 and !$('#tutorial_buttons').is(':visible')
      #   $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') != 0 # and $('#tutorial_buttons').is(':visible')
      #   $('#tutorial_buttons').show('slide', { direction: 'right' }, 500)
      show: (event, api) ->
      #   $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') == 0 # and !$('#tutorial_buttons').is(':visible')
      #   # $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') != 0 and $('#tutorial_buttons').is(':visible')
      #   $('#tutorial_buttons').hide('slide', { direction: 'right' }, 500)
      toggle: (event, api) ->
        # $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') == 0 and $('#tutorial_link').is(':visible')
        # $('#playpause').triggerHandler('click') if $('#playpause-img').data('showTipTimer') != 0 and !$('#tutorial_link').is(':visible')
        # $('#tutorial_buttons').toggle('slide', { direction: 'right' }, 500, () -> $('#tutorial_link').toggle())
        show_later = true
        if $('#playpause-img').data('showTipTimer') == 0 and $('#tutorial_link').is(':visible')
          $('#playpause').triggerHandler('click')
          $('#tutorial_link').hide()
          show_later = false
        else if $('#playpause-img').data('showTipTimer') != 0 and !$('#tutorial_link').is(':visible')
          $('#playpause').triggerHandler('click')
          # $('#tutorial_link').show()
        # $('#tutorial_buttons').toggle('slide', { direction: 'right' }, 500, () -> $('#tutorial_link').show() if show_later)
        $('#tutorial_buttons').toggle('fade', { }, 500, () -> $('#tutorial_link').show() if show_later)
    style:
      classes: 'ui-tooltip-shadow ui-tooltip-green'
  ).qtip('render')
  
  # $('#ui-tooltip-step').qtip('render')
  # $('#ui-tooltip-step').qtip('toggle', false)
  
  # Setup the next/prev links
  $('#next, #prev, #play_first, #play_last').on('click', (event) ->
     $('#ui-tooltip-step').triggerHandler(this.id);
     event.preventDefault()
  )
  
  $('#playpause').on('click', (event) ->
    if $('#playpause-img').data('showTipTimer') != 0
      $('#playpause-img').attr('src', root_url + 'assets/icons/gentleface/playback_play_16.png')
      clearInterval(jQuery('#playpause-img').data('showTipTimer'))
      $('#playpause-img').data('showTipTimer', 0)
    else
      # $('#ui-tooltip-step').triggerHandler('next')
      $('#playpause-img').attr('src', root_url + 'assets/icons/gentleface/playback_pause_16.png')
      # $(document.body).qtip('show')
      $('#playpause-img').data('showTipTimer', setInterval("$('#ui-tooltip-step').triggerHandler('next')" , 3000));
    event.preventDefault()
  )
  
  # jQuery(base).data('showTipTimer', setInterval(function(){tt_locateBase(base);} , 3000));
  # 
  # clearInterval(jQuery(base).data('showTipTimer'));
  
  # $('#source')
  #   .qtip(
  #     content:
  #       text: 'Text'
  #       title:
  #         text: 'Step 1:'
  #         button: true
  #     position:
  #       my: 'top center' # Use the corner...
  #       at: 'bottom center' # ...and opposite corner
  #     show:
  #       event: false # Don't specify a show event...
  #       ready: true # ... but show the tooltip when ready
  #     hide: false # Don't specify a hide event either!
  #     style:
  #       classes: 'ui-tooltip-shadow'
  #   )