# This prototype is provided by the Mozilla foundation and
# is distributed under the MIT license.
# http://www.ibiblio.org/pub/Linux/LICENSES/mit.license

# if (!Array.prototype.map)
#   Array.prototype.map = (fun, thisp) ->
#     len = this.length
#     if (typeof fun != "function")
#       throw new TypeError()
#     res = new Array(len)
#     thisp = arguments[1]
#     # for (i = 0; i < len; i++)
#     for i in [0..len-1]
#       if (i in this)
#         res[i] = fun.call(thisp, this[i], i, this)
#     return res

# Custom HighChart Charts
@drawHighChartHistogramChart = (element_id, values, params, categories) ->
  counts = {}
  my_series = []
  i=0

  for key, value of values
    my_series.push(
      name: key
      data: value.map( (val) -> parseInt(val,10) )
    )

  if params['make_selection']
    sub_title = if typeof document.ontouchstart == 'undefined' then 'Click and drag in the plot area to select values' else 'Drag your finger over the plot to select values'
  else
    sub_title = if typeof document.ontouchstart == 'undefined' then 'Click and drag in the plot area to zoom in' else 'Drag your finger over the plot to zoom in'

  new Highcharts.Chart(
    chart:
      renderTo: element_id
      defaultSeriesType: 'spline'
      zoomType: 'x'
      events:
        selection: (event) ->
          if params['make_selection']
            low_range = Math.floor(event.xAxis[0].min)
            high_range = Math.ceil(event.xAxis[0].max)

            if(low_range < 0)
              low_range = 0
            if(high_range >= categories.length)
              high_range = categories.length - 1

            $("#query_concept_value").val(categories[low_range] + ':' + categories[high_range])
            $("#query_concept_value").change()
            $("#query_concept_value").effect("highlight", {}, 1000)
            false
    credits:
      enabled: false
    title:
      text: params['title']
    subtitle:
      text: sub_title
    tooltip:
      formatter: () ->
        '<b>' + this.y + '</b> ' + this.series.name + ' have a <b>' + params['title'] + '</b> of <b>' + this.x + '</b> ' + params['units']
    xAxis:
      categories: categories
      labels:
        step: Math.ceil(categories.length/12)
      minPadding: 0.05
      maxPadding: 0.05
      title:
        text: params['units']
    yAxis:
      maxPadding: 0
      minPadding: 0
      title:
        text: 'Count'
    series: my_series
    plotOptions:
      series:
        marker:
          radius: 2
  )

@drawHighChartPieChart = (element_id, values, params) ->
  total_count = 0
  my_data = []
  my_series = []

  source_count = 0
  source_index = 0

  for key, value of values
    source_count += 1

  donut_size = parseInt(75 / source_count)

  for key, value of values
    my_series.push(
      type: 'pie'
      size: (donut_size * (source_index + 1)) + "%"
      innerSize: (donut_size * source_index) + "%"
      name: params['title'] # key
      data: value
      dataLabels:
        enabled: (source_count == source_index + 1)
    )
    source_index += 1

    for index, h of value
      total_count = total_count + h['y']

  Highcharts.setOptions(
    colors: ['rgba(69, 114, 167, 1.0)', 'rgba(170, 70, 67, 1.0)', 'rgba(137, 165, 78, 1.0)', 'rgba(128, 105, 155, 1.0)', 'rgba(61, 150, 174, 1.0)', 'rgba(219, 132, 61, 1.0)', 'rgba(146, 168, 205, 1.0)', 'rgba(164, 125, 124, 1.0)', 'rgba(181, 202, 146, 1.0)']
                  # '#4572A7',                     '#AA4643',               '#89A54E',                '#80699B',                 '#3D96AE',                   '#DB843D',                   '#92A8CD',                   '#A47D7C',                  '#B5CA92'
  )

  new Highcharts.Chart(
    chart:
      renderTo: element_id
    credits:
      enabled: false
    title:
      text: params['title']
    plotArea:
      shadow: null
      borderWidth: null
      backgroundColor: null
    tooltip:
      formatter: () ->
        if total_count > 0
          return '<b>' + this.point.name + '</b>: ' + this.y + ' (' + (this.y / total_count * 100.0).toFixed(2) + '%)'
        else
          return '<b>' + this.point.name + '</b>: ' + this.y
    plotOptions:
      pie:
        allowPointSelect: true
        cursor: 'pointer'
        point:
          events:
            click: (event) ->
              if params['make_selection']
                el_id = "#value_ids_" + this.id
                if $(el_id).is(':checked')
                  $(el_id).prop('checked',false)
                else
                  $(el_id).prop('checked',true)
                $(el_id).change()
                false
    # legend:
    #   layout: 'vertical'
    #   style:
    #     left: 'auto'
    #     bottom: 'auto'
    #     right: '50px'
    #     top: '100px'
    series: my_series
  )
