local g = import 'grafonnet/grafana.libsonnet';
local pieChartPanel = import 'piechart_panel.libsonnet';
local timeSeries = import 'timeseries_panel.libsonnet';

{
  _config:: error 'must provide _config',

  dashboardSchema(title,
                  description,
                  uid,
                  time_from,
                  refresh,
                  schemaVersion,
                  tags,
                  timezone)::
    g.dashboard.new(title=title,
                    description=description,
                    uid=uid,
                    time_from=time_from,
                    refresh=refresh,
                    schemaVersion=schemaVersion,
                    tags=tags,
                    timezone=timezone),

  graphPanelSchema(aliasColors,
                   title,
                   description,
                   nullPointMode,
                   stack,
                   formatY1,
                   formatY2,
                   labelY1,
                   labelY2,
                   min,
                   fill,
                   datasource,
                   legend_alignAsTable=false,
                   legend_avg=false,
                   legend_min=false,
                   legend_max=false,
                   legend_current=false,
                   legend_values=false)::
    g.graphPanel.new(aliasColors=aliasColors,
                     title=title,
                     description=description,
                     nullPointMode=nullPointMode,
                     stack=stack,
                     formatY1=formatY1,
                     formatY2=formatY2,
                     labelY1=labelY1,
                     labelY2=labelY2,
                     min=min,
                     fill=fill,
                     datasource=datasource,
                     legend_alignAsTable=legend_alignAsTable,
                     legend_avg=legend_avg,
                     legend_min=legend_min,
                     legend_max=legend_max,
                     legend_current=legend_current,
                     legend_values=legend_values),


  addTargetSchema(
    expr,
    legendFormat='',
    format='time_series',
    intervalFactor=1,
    instant=null,
    datasource=null,
    step=null,
    interval=null,
    range=null,
    hide=null,
    metric=null,
    aggregation=null,
    alias=null,
    decimals=null,
    displayAliasType=null,
    displayType=null,
    displayValueWithAlias=null,
    units=null,
    valueHandler=null,
    warn=null,
    crit=null,
    exemplar=null,
  )::
    g.prometheus.target(expr=expr,
                        legendFormat=legendFormat,
                        format=format,
                        intervalFactor=intervalFactor,
                        instant=instant,
                        datasource=datasource) + {
      [if step != null then 'step']: step,
      [if interval != null then 'interval']: interval,
      [if range != null then 'range']: range,
      [if hide != null then 'hide']: hide,
      [if metric != null then 'metric']: metric,
      [if aggregation != null then 'aggregation']: aggregation,
      [if alias != null then 'alias']: alias,
      [if decimals != null then 'decimals']: decimals,
      [if displayAliasType != null then 'displayAliasType']: displayAliasType,
      [if displayType != null then 'displayType']: displayType,
      [if displayValueWithAlias != null then 'displayValueWithAlias']: displayValueWithAlias,
      [if units != null then 'units']: units,
      [if valueHandler != null then 'valueHandler']: valueHandler,
      [if warn != null then 'warn']: warn,
      [if crit != null then 'crit']: crit,
      [if exemplar != null then 'exemplar']: exemplar,
    },

  addTemplateSchema(name,
                    datasource,
                    query,
                    refresh,
                    includeAll,
                    sort,
                    label,
                    regex,
                    hide='',
                    multi=false,
                    allValues=null,
                    current=null)::
    g.template.new(name=name,
                   datasource=datasource,
                   query=query,
                   refresh=refresh,
                   includeAll=includeAll,
                   sort=sort,
                   label=label,
                   regex=regex,
                   hide=hide,
                   multi=multi,
                   allValues=allValues,
                   current=current),

  addAnnotationSchema(builtIn,
                      datasource,
                      enable,
                      hide,
                      iconColor,
                      name,
                      type)::
    g.annotation.datasource(builtIn=builtIn,
                            datasource=datasource,
                            enable=enable,
                            hide=hide,
                            iconColor=iconColor,
                            name=name,
                            type=type),

  addRowSchema(
    collapse,
    showTitle,
    title,
    collapsed=null
  )::
    g.row.new(collapse=collapse, showTitle=showTitle, title=title) + {
      [if collapsed != null then 'collapsed']: collapsed,
    },

  addSingleStatSchema(colors,
                      datasource,
                      format,
                      title,
                      description,
                      valueName,
                      colorValue,
                      gaugeMaxValue,
                      gaugeShow,
                      sparklineShow,
                      thresholds)::
    g.singlestat.new(colors=colors,
                     datasource=datasource,
                     format=format,
                     title=title,
                     description=description,
                     valueName=valueName,
                     colorValue=colorValue,
                     gaugeMaxValue=gaugeMaxValue,
                     gaugeShow=gaugeShow,
                     sparklineShow=sparklineShow,
                     thresholds=thresholds),

  addPieChartSchema(aliasColors,
                    datasource,
                    description,
                    legendType,
                    pieType,
                    title,
                    valueName)::
    g.pieChartPanel.new(aliasColors=aliasColors,
                        datasource=datasource,
                        description=description,
                        legendType=legendType,
                        pieType=pieType,
                        title=title,
                        valueName=valueName),

  addStyle(alias,
           colorMode,
           colors,
           dateFormat,
           decimals,
           mappingType,
           pattern,
           thresholds,
           type,
           unit,
           valueMaps)::
    {
      alias: alias,
      colorMode: colorMode,
      colors: colors,
      dateFormat: dateFormat,
      decimals: decimals,
      mappingType: mappingType,
      pattern: pattern,
      thresholds: thresholds,
      type: type,
      unit: unit,
      valueMaps: valueMaps,
    },

  matchers()::
    local clusterMatcher = '%s=~"$cluster"' % $._config.clusterLabel;
    {
      // Common labels
      matchers: (if $._config.showMultiCluster then clusterMatcher + ', ' else ''),
    },


  addClusterTemplate()::
    $.addTemplateSchema(
      'cluster',
      '$datasource',
      'label_values(ceph_health_status, %s)' % $._config.clusterLabel,
      1,
      false,
      1,
      'cluster',
      '(.*)',
      if !$._config.showMultiCluster then 'variable' else '',
      multi=false,
      allValues=null,
    ),

  overviewStyle(alias,
                pattern,
                type,
                unit,
                colorMode=null,
                thresholds=[],
                valueMaps=[])::
    $.addStyle(alias,
               colorMode,
               [
                 'rgba(245, 54, 54, 0.9)',
                 'rgba(237, 129, 40, 0.89)',
                 'rgba(50, 172, 45, 0.97)',
               ],
               'YYYY-MM-DD HH:mm:ss',
               2,
               1,
               pattern,
               thresholds,
               type,
               unit,
               valueMaps),

  simpleGraphPanel(alias,
                   title,
                   description,
                   formatY1,
                   labelY1,
                   min,
                   expr,
                   legendFormat,
                   x,
                   y,
                   w,
                   h)::
    $.graphPanelSchema(alias,
                       title,
                       description,
                       'null',
                       false,
                       formatY1,
                       'short',
                       labelY1,
                       null,
                       min,
                       1,
                       '$datasource')
    .addTargets(
      [$.addTargetSchema(expr, legendFormat)]
    ) + { type: 'timeseries' } + { fieldConfig: { defaults: { unit: formatY1, custom: { fillOpacity: 8, showPoints: 'never' } } } } + { gridPos: { x: x, y: y, w: w, h: h } },

  simpleSingleStatPanel(format,
                        title,
                        description,
                        valueName,
                        expr,
                        instant,
                        targetFormat,
                        x,
                        y,
                        w,
                        h)::
    $.addSingleStatSchema(['#299c46', 'rgba(237, 129, 40, 0.89)', '#d44a3a'],
                          '$datasource',
                          format,
                          title,
                          description,
                          valueName,
                          false,
                          100,
                          false,
                          false,
                          '')
    .addTarget($.addTargetSchema(expr, '', targetFormat, 1, instant)) + {
      gridPos: { x: x, y: y, w: w, h: h },
    },
  gaugeSingleStatPanel(format,
                       title,
                       description,
                       valueName,
                       colorValue,
                       gaugeMaxValue,
                       gaugeShow,
                       sparkLineShow,
                       thresholds,
                       expr,
                       targetFormat,
                       x,
                       y,
                       w,
                       h)::
    $.addSingleStatSchema(['#299c46', 'rgba(237, 129, 40, 0.89)', '#d44a3a'],
                          '$datasource',
                          format,
                          title,
                          description,
                          valueName,
                          colorValue,
                          gaugeMaxValue,
                          gaugeShow,
                          sparkLineShow,
                          thresholds)
    .addTarget($.addTargetSchema(expr, '', targetFormat)) + { gridPos: { x:
      x, y: y, w: w, h: h } },

  simplePieChart(alias, description, title)::
    $.addPieChartSchema(alias,
                        '$datasource',
                        description,
                        'Under graph',
                        'pie',
                        title,
                        'current'),

  addStatPanel(
    title,
    description='',
    transparent=false,
    datasource=null,
    color={},
    unit='none',
    overrides=[],
    gridPosition={},
    colorMode='none',
    graphMode='none',
    justifyMode='auto',
    orientation='horizontal',
    textMode='auto',
    reducerFunction='lastNotNull',
    pluginVersion='9.1.3',
    decimals=0,
    interval=null,
    maxDataPoints=null,
    thresholdsMode='absolute',
    rootColorMode=null,
    rootColors=null,
    cornerRadius=null,
    flipCard=null,
    flipTime=null,
    fontFormat=null,
    displayName=null,
    isAutoScrollOnOverflow=null,
    isGrayOnNoData=null,
    isHideAlertsOnDisable=null,
    isIgnoreOKColors=null,
  )::
    g.statPanel.new(
      title=title,
      description=description,
      transparent=transparent,
      datasource=datasource,
      unit=unit,
      colorMode=colorMode,
      graphMode=graphMode,
      justifyMode=justifyMode,
      orientation=orientation,
      textMode=textMode,
      reducerFunction=reducerFunction,
      pluginVersion=pluginVersion,
      decimals=decimals,
      thresholdsMode=thresholdsMode,
    ) + {
      [if interval != null then 'interval']: interval,
      [if maxDataPoints != null then 'maxDataPoints']: maxDataPoints,
      [if gridPosition != {} then 'gridPos']: gridPosition,
      [if rootColorMode != null then 'colorMode']: rootColorMode,
      [if rootColors != {} then 'colors']: rootColors,
      [if cornerRadius != null then 'cornerRadius']: cornerRadius,
      [if flipCard != null then 'flipCard']: flipCard,
      [if flipTime != null then 'flipTime']: flipTime,
      [if fontFormat != null then 'fontFormat']: fontFormat,
      [if displayName != null then 'displayName']: displayName,
      [if isAutoScrollOnOverflow != null then 'isAutoScrollOnOverflow']: isAutoScrollOnOverflow,
      [if isGrayOnNoData != null then 'isGrayOnNoData']: isGrayOnNoData,
      [if isHideAlertsOnDisable != null then 'isHideAlertsOnDisable']: isHideAlertsOnDisable,
      [if isIgnoreOKColors != null then 'isIgnoreOKColors']: isIgnoreOKColors,
    },

  addAlertListPanel(
    title,
    datasource=null,
    gridPosition={},
    alertInstanceLabelFilter=null,
    alertName=null,
    dashboardAlerts=null,
    groupBy=null,
    groupMode=null,
    maxItems=null,
    sortOrder=null,
    stateFilter=null,
    viewMode='list'
  )::
    g.alertlist.new(
      title=title,
      datasource=datasource,
    ) + {
      gridPos: gridPosition,
      options: {
        [if alertInstanceLabelFilter != null then 'alertInstanceLabelFilter']: alertInstanceLabelFilter,
        [if alertName != null then 'alertName']: alertName,
        [if dashboardAlerts != null then 'dashboardAlerts']: dashboardAlerts,
        [if groupBy != null then 'groupBy']: groupBy,
        [if groupMode != null then 'groupMode']: groupMode,
        [if maxItems != null then 'maxItems']: maxItems,
        [if sortOrder != null then 'sortOrder']: sortOrder,
        [if stateFilter != null then 'stateFilter']: stateFilter,
        viewMode: viewMode,
      },
    },

  addCustomTemplate(name='',
                    query='',
                    current='',
                    valuelabels={},
                    refresh=0,
                    label='Interval',
                    auto_count=10,
                    auto_min='2m',
                    options=[],
                    auto=null)::
    g.template.interval(name=name,
                        query=query,
                        current=current,
                        label=label,
                        auto_count=auto_count,
                        auto_min=auto_min,) + {
      options: options,
      refresh: refresh,
      valuelabels: valuelabels,
      [if auto != null then 'auto']: auto,
    },

  addGaugePanel(title='',
                description='',
                transparent=false,
                datasource='$datasource',
                gridPosition={},
                pluginVersion='9.1.3',
                unit='percentunit',
                instant=false,
                reducerFunction='lastNotNull',
                steps=[],
                max=1,
                min=0,
                maxDataPoints=100,
                interval='1m')::
    g.gaugePanel.new(title=title,
                     description=description,
                     transparent=transparent,
                     datasource=datasource,
                     pluginVersion=pluginVersion,
                     unit=unit,
                     reducerFunction=reducerFunction,
                     max=max,
                     min=min) + {
      gridPos: gridPosition,
      maxDataPoints: maxDataPoints,
      interval: interval,
    },

  addBarGaugePanel(title='',
                   description='',
                   datasource='${DS_PROMETHEUS}',
                   gridPosition={},
                   unit='percentunit',
                   thresholds={})::
    g.barGaugePanel.new(title, description, datasource, unit, thresholds) + {
      gridPos: gridPosition,
    },

  addTableExtended(
    title='',
    datasource=null,
    description=null,
    sort=null,
    styles='',
    transform=null,
    pluginVersion='9.1.3',
    options=null,
    gridPosition={},
    custom=null,
    decimals=null,
    thresholds=null,
    unit=null,
    overrides=[],
    color=null
  )::
    g.tablePanel.new(datasource=datasource,
                     description=description,
                     sort=sort,
                     styles=styles,
                     title=title,
                     transform=transform) + {
      pluginVersion: pluginVersion,
      gridPos: gridPosition,
      [if options != null then 'options']: options,
      fieldConfig+: {
        defaults+: {
          [if custom != null then 'custom']: custom,
          [if decimals != null then 'decimals']: decimals,
          [if thresholds != null then 'thresholds']: thresholds,
          [if unit != null then 'unit']: unit,
          [if color != null then 'color']: color,

        },
        overrides: overrides,
      },
    },
  timeSeriesPanel(
    title='',
    datasource=null,
    gridPosition={},
    colorMode='palette-classic',
    axisCenteredZero=false,
    axisColorMode='text',
    axisLabel='',
    axisPlacement='auto',
    barAlignment=0,
    drawStyle='line',
    fillOpacity=0,
    gradientMode='none',
    lineInterpolation='linear',
    lineWidth=0,
    pointSize=0,
    scaleDistributionType='linear',
    showPoints='',
    spanNulls=false,
    stackingGroup='A',
    stackingMode='none',
    thresholdsStyleMode='off',
    decimals=null,
    thresholdsMode='absolute',
    unit='none',
    tooltip={ mode: 'multi', sort: 'none' },
    pluginVersion='9.1.3',
    displayMode='list',
    placement='bottom',
    showLegend=true,
    interval=null,
    min=null,
    scaleDistributionLog=null,
    sortBy=null,
    sortDesc=null,
  )::
    timeSeries.new(
      title=title,
      gridPos=gridPosition,
      datasource=datasource,
      colorMode=colorMode,
      axisCenteredZero=axisCenteredZero,
      axisColorMode=axisColorMode,
      axisLabel=axisLabel,
      axisPlacement=axisPlacement,
      barAlignment=barAlignment,
      drawStyle=drawStyle,
      fillOpacity=fillOpacity,
      gradientMode=gradientMode,
      lineInterpolation=lineInterpolation,
      lineWidth=lineWidth,
      pointSize=pointSize,
      scaleDistributionType=scaleDistributionType,
      showPoints=showPoints,
      spanNulls=spanNulls,
      stackingGroup=stackingGroup,
      stackingMode=stackingMode,
      thresholdsStyleMode=thresholdsStyleMode,
      decimals=decimals,
      thresholdsMode=thresholdsMode,
      unit=unit,
      displayMode=displayMode,
      placement=placement,
      showLegend=showLegend,
      tooltip=tooltip,
      min=min,
      scaleDistributionLog=scaleDistributionLog,
      sortBy=sortBy,
      sortDesc=sortDesc,
    ) + {
      pluginVersion: pluginVersion,
      [if interval != null then 'interval']: interval,
    },

  pieChartPanel(
    title,
    description='',
    datasource=null,
    gridPos={},
    displayMode='table',
    placement='bottom',
    showLegend=true,
    displayLabels=[],
    tooltip={},
    pieType='pie',
    values=[],
    colorMode='auto',
    overrides=[],
    reduceOptions={},
  )::
    pieChartPanel.new(
      title,
      description=description,
      datasource=datasource,
      gridPos=gridPos,
      displayMode=displayMode,
      placement=placement,
      showLegend=showLegend,
      displayLabels=displayLabels,
      tooltip=tooltip,
      pieType=pieType,
      values=values,
      colorMode=colorMode,
      overrides=overrides,
      reduceOptions=reduceOptions,
    ),

  heatMapPanel(
    title='',
    datasource=null,
    gridPosition={},
    colorMode='spectrum',
    cardColor='#b4ff00',
    colorScale='sqrt',
    colorScheme='interpolateOranges',
    colorExponent=0.5,
    pluginVersion='9.1.3',
    dataFormat='timeseries',
    hideFrom={ legend: false, tooltip: false, viz: false },
    scaleDistributionType='linear',
    legendShow=false,
    optionsCalculate=false,
    optionsCalculation={
      yBuckets: {
        mode: 'count',
        scale: { log: 2, type: 'log' },
        value: '1',
      },
    },
    optionsCellGap=2,
    optionsCellValues={},
    optionsColor={},
    optionsExemplars={},
    optionsFilterValues={},
    optionsLegend={},
    optionsRowFrame={},
    optionsShowValue='never',
    optionsToolTip={},
    optionsYAxis={},
    xBucketSize=null,
    yAxisDecimals=null,
    yAxisFormat='short',
    yAxisLogBase=1,
    yAxisMin=null,
    yAxisMax=null,
    yAxisShow=true,
    yAxisSplitFactor=1,
    yBucketSize=null,
    yBucketBound='auto'
  )
  :: g.heatmapPanel.new(
    title=title,
    datasource=datasource,
    color_mode=colorMode,
    color_cardColor=cardColor,
    color_colorScale=colorScale,
    color_colorScheme=colorScheme,
    color_exponent=colorExponent,
    legend_show=legendShow,
    xBucketSize=xBucketSize,
    yAxis_decimals=yAxisDecimals,
    yAxis_format=yAxisFormat,
    yAxis_logBase=yAxisLogBase,
    yAxis_min=yAxisMin,
    yAxis_max=yAxisMax,
    yAxis_show=yAxisShow,
    yAxis_splitFactor=yAxisSplitFactor,
    yBucketSize=yBucketSize,
    yBucketBound=yBucketBound
  ) + {
    gridPos: gridPosition,
    pluginVersion: pluginVersion,
    color+: {
      colorScheme: colorScheme,
    },
    fieldConfig: {
      defaults: {
        custom: {
          hideFrom: hideFrom,
          scaleDistribution: {
            type: scaleDistributionType,
          },
        },
      },
    },
    options: {
      calculate: optionsCalculate,
      calculation: optionsCalculation,
      cellGap: optionsCellGap,
      cellValues: optionsCellValues,
      color: optionsColor,
      exemplars: optionsExemplars,
      filterValues: optionsFilterValues,
      legend: optionsLegend,
      rowsFrame: optionsRowFrame,
      showValue: optionsShowValue,
      tooltip: optionsToolTip,
      yAxis: optionsYAxis,
    },
  },
}
