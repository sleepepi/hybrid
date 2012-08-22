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
            event.preventDefault()
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
                  $(el_id).removeAttr('checked')
                  $(el_id).parent().effect("highlight", {color:'#ff9999'}, 1000)
                else
                  $(el_id).attr('checked','checked')
                  $(el_id).parent().effect("highlight", {color:'#99ff99'}, 1000)
                event.preventDefault()
    # legend: {
    #   layout: 'vertical',
    #   style: {
    #     left: 'auto',
    #     bottom: 'auto',
    #     right: '50px',
    #     top: '100px'
    #   }
    # },
    series: my_series
  )

# @drawHighChartScatterChart = (element_id, values, params) ->
#   myXPlotBands = [];
#   myYPlotBands = [];
# 
#   two_colors = ['rgba(0, 0, 0, 0)', 'rgba(68, 170, 213, 0.1)'];
# 
#   faded_colors = ['rgba(69, 114, 167, 0.5)', 'rgba(170, 70, 67, 0.5)', 'rgba(137, 165, 78, 0.5)', 'rgba(128, 105, 155, 0.5)', 'rgba(61, 150, 174, 0.5)', 'rgba(219, 132, 61, 0.5)', 'rgba(146, 168, 205, 0.5)', 'rgba(164, 125, 124, 0.5)', 'rgba(181, 202, 146, 0.5)'];
#                     # '#4572A7',                     '#AA4643',               '#89A54E',                '#80699B',                 '#3D96AE',                   '#DB843D',                   '#92A8CD',                   '#A47D7C',                  '#B5CA92'  
# 
#   index = 0;
# 
#   for (index = 0; index < params['xPlotBands'].length; ++index) {
#     item = params['xPlotBands'][index];
#     band_color = two_colors[(index % two_colors.size())];
#     band_text = item;
# 
#     if(item.indexOf("#") >= 0){
#       band_text = item.substring(item.indexOf("#")+1);
#     }
# 
#     myXPlotBands.push({
#                  from: index,
#                  to: index+1,
#                  color: band_color,
#                  label: {
#                     text: band_text
#                  }
#               });
#   }
# 
#   for (index = 0; index < params['yPlotBands'].length; ++index) {
#     item = params['yPlotBands'][index];
#     band_color = two_colors[(index % two_colors.size())];
#     band_text = item;
# 
#     if(item.indexOf("#") >= 0){
#       band_text = item.substring(item.indexOf("#")+1);
#     }
# 
#     myYPlotBands.push({
#                  from: index,
#                  to: index+1,
#                  color: band_color,
#                  label: {
#                     text: band_text,
#                     verticalAlign: 'middle'
#                  }
#               });
#   }
# 
#   Highcharts.setOptions({colors: faded_colors});
# 
#   new Highcharts.Chart({
#         chart: {
#            renderTo: element_id, 
#            defaultSeriesType: 'scatter',
#            zoomType: 'xy'
#         },
#         credits: {
#           enabled: false
#         },
#         title: {
#            text: params['title']
#         },
#         # subtitle: {
#         #    text: 'Source: Heinz  2003'
#         # },
#         xAxis: {
#            title: {
#               enabled: true,
#               text: params['title_x']
#            },
#            labels: {
#              enabled: params['xAxisLabelsEnabled']
#            },
#            startOnTick: true,
#            endOnTick: true,
#            showLastLabel: true,
#            plotBands: myXPlotBands
#         },
#         yAxis: {
#            title: {
#               text: params['title_y']
#            },
#            labels: {
#              enabled: params['yAxisLabelsEnabled']
#            },
#            plotBands: myYPlotBands
# 
#            # [{ # Light air
#            #             from: 0.3,
#            #             to: 1.5,
#            #             color: 'rgba(68, 170, 213, 0.1)',
#            #             label: {
#            #                text: 'Light air',
#            #                style: {
#            #                   color: Highcharts.theme.textColor || '#606060'
#            #                }
#            #             }
#            #          }, { # Light breeze
#            #             from: 1.5,
#            #             to: 3.3,
#            #             color: 'rgba(0, 0, 0, 0)',
#            #             label: {
#            #                text: 'Light breeze',
#            #                style: {
#            #                   color: Highcharts.theme.textColor || '#606060'
#            #                }
#            #             }
#            #          }]
# 
#         },
#         tooltip: {
#            formatter: function() {
#                       if(params['title_z'] != '' && params['title_z'] != null && this.z != null){
#                         if(!params['xAxisLabelsEnabled'] && !params['yAxisLabelsEnabled']){
#                           return '';
#                         }else if(!params['xAxisLabelsEnabled']){
#                           return this.y + ' ' + params['title_y'] + ' ' + this.z + ' ' + params['title_z'];
#                         }else if(!params['yAxisLabelsEnabled']){
#                           return this.x + ' ' + params['title_x'] + ' ' + this.z + ' ' + params['title_z'];
#                         }else{
#                           return this.x + ' ' + params['title_x'] + ', ' + this.y + ' ' + params['title_y'] + ' ' + this.z + ' ' + params['title_z'];
#                         }
# 
#                       }else{
#                         if(!params['xAxisLabelsEnabled'] && !params['yAxisLabelsEnabled']){
#                           return '';
#                         }else if(!params['xAxisLabelsEnabled']){
#                           return this.y + ' ' + params['title_y'];
#                         }else if(!params['yAxisLabelsEnabled']){
#                           return this.x + ' ' + params['title_x'];
#                         }else{
#                           return this.x + ' ' + params['title_x'] + ', ' + this.y + ' ' + params['title_y'];
#                         }
#                       }
#            }
#         },
#         # legend: {
#         #    layout: 'vertical',
#         #    # align: 'left',
#         #    # verticalAlign: 'top',
#         #    # x: 100,
#         #    # y: 70,
#         #    # floating: true,
#         #    backgroundColor: '#FFFFFF',
#         #    borderWidth: 1
#         # },
#         plotOptions: {
#            scatter: {
#               marker: {
#                  radius: 5,
#                  states: {
#                     hover: {
#                        enabled: true,
#                        lineColor: 'rgb(100,100,100)'
#                     }
#                  }
#               },
#               states: {
#                  hover: {
#                     marker: {
#                        enabled: false
#                     }
#                  }
#               }
#            }
#         },
#         series: values
#         # [{
#         #    name: 'Female',
#         #    color: 'rgba(223, 83, 83, .5)',
#         #    data: 
#            # [[161.2, 51.6], [167.5, 59.0], [159.5, 49.2], [157.0, 63.0], [155.8, 53.6], 
#            #    [176.5, 71.8], [164.4, 55.5], [160.7, 48.6], [174.0, 66.4], [163.8, 67.3]]
# 
#         # }
#         # , {
#         #    name: 'Male',
#         #    color: 'rgba(119, 152, 191, .5)',
#         #    data: [[174.0, 65.6], [175.3, 71.8], [193.5, 80.7], [186.5, 72.6], [187.2, 78.8], 
#         #       [180.3, 83.2], [180.3, 83.2]]
# 
#         # }
#         # ]
#      });
