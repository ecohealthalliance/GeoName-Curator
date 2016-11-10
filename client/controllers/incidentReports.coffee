Incidents = require '/imports/collections/incidentReports.coffee'
ScatterPlot = require '/imports/charts/ScatterPlot.coffee'
Axes = require '/imports/charts/Axes.coffee'
RectMarker = require '/imports/charts/RectMarker.coffee'
tooltipTmpl = """
  <div class='row'>
    <div class='col-xs-12'>
      <span style='font-weight: bold;'>
        <%= obj.y %> <%= type %> (<%= obj.meta.location %>)</span>
      </span>
    </div>
  </div>
  <div class='row'>
    <div class='col-xs-12'>
      <span style='text-align: left; padding-left: 5px;'>
        from <%= obj.moment(obj.x).format('MMM Do YYYY') %>
        to <%= obj.moment(obj.w).format('MMM Do YYYY') %>
      </span>
    </div>
  </div>
"""

import { formatUrl } from '/imports/utils.coffee'


Template.incidentReports.onDestroyed ->
  if @plot
    @plot.destroy()
    @plot = null

Template.incidentReports.onCreated ->
  # iron router returns an array and not a cursor for data.incidents,
  # therefore we will setup a reactive cursor to use with the plot as an
  # instance variable.
  @incidents = Incidents.find({userEventId: @data.userEvent._id}, {sort: {date: -1}})

Template.incidentReports.onRendered ->
  @filters =
    notCumulative: (d) ->
      if typeof d.meta.cumulative == 'undefined' || d.meta.cumulative == false
        d
    cumulative: (d) ->
      if d.meta.cumulative
        d

  @plot = new ScatterPlot
    containerID: 'scatterPlot'
    svgContainerClass: 'scatterPlot-container'
    height: $('#event-incidents-table').parent().height()
    axes:
      # show grid lines
      grid: true
      x:
        title: 'Time'
        type: 'datetime'
      y:
        title: 'Count'
        type: 'numeric'
    tooltip:
      opacity: .8
      # function to render the tooltip
      template: (marker) ->
        marker.moment = moment # template reference for momentjs
        marker.type = marker.meta.type
        if marker.y != 1
          marker.type = "#{marker.type}s"
        # underscore compiled template
        tmpl = _.template(tooltipTmpl)
        # render the template from
        tmpl(marker)
    zoom: true
    # initially active filters
    filters:
      notCumulative: @filters.notCumulative

  # deboune how many consecutive calls to update the plot during reactive changes
  @updatePlot = _.debounce(_.bind(@plot.update, @plot), 300)

  @autorun =>
    # anytime the incidents cursur changes, refetch the data and format
    incidents = @incidents.fetch()
      .map (incident) ->
        RectMarker.createFromIncident(incident)
      .filter (incident) ->
        if incident
          incident
    # we have an existing plot, update plot with new data array
    if @plot instanceof ScatterPlot
      @updatePlot(incidents)
      return

Template.incidentReports.helpers
  formatUrl: formatUrl
  getSettings: ->
    fields = [
      {
        key: "count"
        label: "Incident"
        fn: (value, object, key) ->
          if object.cases
            return pluralize("case", object.cases)
          else if object.deaths
            return pluralize("death", object.deaths)
          else
            return object.specify
        sortFn: (value, object) ->
          0 + (object.deaths or 0) + (object.cases or 0)
      },
      {
        key: "locations"
        label: "Locations"
        fn: (value, object, key) ->
          if object.locations
            return $.map(object.locations, (element, index) ->
              return element.name
            ).toString()
          return ""
      },
      {
        key: 'dateRange'
        label: 'Date'
        fn: (value, object, key) ->
          dateFormat = 'M/D/YYYY'
          if object.dateRange?.type is 'day'
            if object.dateRange.cumulative
              return "Before " + moment(object.dateRange.end).format(dateFormat)
            else
              return moment(object.dateRange.start).format(dateFormat)
          else if object.dateRange?.type is 'precise'
            return moment(object.dateRange.start).format(dateFormat) + ' - '
            + moment(object.dateRange.end).format(dateFormat)
          return ''
        sortFn: (value, object) ->
          +new Date(object.dateRange.end)
      }
    ]

    fields.push
      key: 'expand'
      label: ''
      cellClass : 'action open-down'

    id: 'event-incidents-table'
    fields: fields
    showFilter: false
    showNavigationRowsPerPage: false
    showRowCount: false
    class: 'table event-incidents'
    rowClass: "event-incident"

Template.incidentReports.events
  'click #scatterPlot-toggleCumulative': (event, template) ->
    $target = $(event.currentTarget)
    $icon = $target.find('i.fa')
    if $target.hasClass('active')
      $target.removeClass('active')
      $icon.removeClass('fa-check-circle').addClass('fa-circle-o')
      template.plot.removeFilter('cumulative')
      template.plot.addFilter('notCumulative', template.filters.notCumulative)
      template.updatePlot()
    else
      $target.addClass('active')
      $icon.removeClass('fa-circle-o').addClass('fa-check-circle')
      template.plot.removeFilter('notCumulative')
      template.plot.addFilter('cumulative', template.filters.cumulative)
      template.updatePlot()

  'click #scatterPlot-resetZoom': (event, template) ->
    template.plot.resetZoom()

  'click #event-incidents-table th': (event, template) ->
    template.$('tr').removeClass('open')
    template.$('tr.details').remove()

  'click .reactive-table tbody tr.event-incident': (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest('tr')
    currentOpen = template.$('tr.details')
    closeRow = $parentRow.hasClass('open')
    if currentOpen
      template.$('tr').removeClass('open')
      currentOpen.remove()
    if not closeRow
      $parentRow.addClass('open').after $('<tr>').addClass('details')
      Blaze.renderWithData Template.incidentReport, @, $('tr.details')[0]

  'click .reactive-table tbody tr .edit': (event, template) ->
    templateData = template.data
    incident =
      articles: templateData.articles
      userEventId: templateData.userEvent._id
      edit: true
      incident: @
    Modal.show 'incidentModal', incident

  'click .reactive-table tbody tr .delete': (event, template) ->
    Modal.show 'incidentDeleteModal', @

  # Remove any open incident report details elements on pagination
  'click .next-page,
   click .prev-page,
   change .reactive-table-navigation .form-control': (event, template) ->
     template.$('tr.details').remove()
