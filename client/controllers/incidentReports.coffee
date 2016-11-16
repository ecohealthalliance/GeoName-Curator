import d3 from 'd3'
import Incidents from '/imports/collections/incidentReports.coffee'
import ScatterPlot from '/imports/charts/ScatterPlot.coffee'
import Axes from '/imports/charts/Axes.coffee'
import Group from '/imports/charts/Group.coffee'
import SegmentMarker from '/imports/charts/SegmentMarker.coffee'
import { formatUrl } from '/imports/utils.coffee'
import { pluralize } from '/imports/ui/helpers'

Template.incidentReports.onDestroyed ->
  if @plot
    @plot.destroy()
    @plot = null

Template.incidentReports.onCreated ->
  # iron router returns an array and not a cursor for data.incidents,
  # therefore we will setup a reactive cursor to use with the plot as an
  # instance variable.
  @incidents = Incidents.find({userEventId: @data.userEvent._id}, {sort: {'dateRange.end': 1}})
  # underscore template for the mouseover event of a group
  @tooltipTmpl = """
    <% if ('applyFilters' in obj) { %>
      <% _.each(obj.applyFilters(), function(node) { %>
        <div class='report'>
          <p>
            <i class='fa fa-circle <%= node.meta.type%>'></i>
            <span class='count'>
              <%= obj.pluralize(node.meta.type, node.y) %>
            </span>
            <span>(<%= node.meta.location %>)</span>
          </p>
          <% if (node.hasOwnProperty('w')) { %>
            <p>
              <span class='dates'>
                <%= obj.moment(node.x).format('MMM Do YYYY') %>
                - <%= obj.moment(node.w).format('MMM Do YYYY') %>
              </span>
            </p>
        </div>
        <% } %>
      <% }); %>
    <% } %>
  """

Template.incidentReports.onRendered ->
  @filters =
    notCumulative: (d) ->
      if typeof d.meta.cumulative == 'undefined' || d.meta.cumulative == false
        d
    cumulative: (d) ->
      if d.meta.cumulative
        d

  # compiled the template into the variable tmpl
  tmpl = _.template(@tooltipTmpl)

  @plot = new ScatterPlot
    containerID: 'scatterPlot'
    svgContainerClass: 'scatterPlot-container'
    height: $('#event-incidents-table').parent().height()
    axes:
      # show grid lines
      grid: true
      # use built-in domain bounds filter
      filter: true
      x:
        title: 'Time'
        type: 'datetime'
      y:
        title: 'Count'
        type: 'numeric'
    tooltip:
      opacity: 1
      # function to render the tooltip
      template: (group) ->
        # template reference for momentjs
        group.moment = moment
        # template reference for pluralize
        group.pluralize = pluralize
        # render the template from
        tmpl(group)
    zoom: true
    # initially active filters
    filters:
      notCumulative: @filters.notCumulative
    # group events
    group:
      # methods to be applied when a new group is created
      onEnter: () ->
        # bind mouseover/mouseout events to the plot tooltip
        @.group
          .on 'mouseover', () =>
            if @plot.tooltip
              @plot.tooltip.mouseover(@, d3.event.pageX, d3.event.pageY)
          .on 'mouseout', () =>
            if @plot.tooltip
              @plot.tooltip.mouseout()

  # deboune how many consecutive calls to update the plot during reactive changes
  @updatePlot = _.debounce(_.bind(@plot.update, @plot), 300)

  @autorun =>
    # anytime the incidents cursor changes, refetch the data and format
    segments = @incidents
      .fetch()
      .map (incident) =>
        SegmentMarker.createFromIncident(@plot, incident)
      .filter (incident) ->
        if incident
          return incident

    # each overlapping group will be a 'layer' on the plot. overlapping is when
    #   segments have same y value and any portion of line segment overlaps
    groups = SegmentMarker.groupOverlappingSegments(segments)

    # we have an existing plot, update plot with new data array
    if @plot instanceof ScatterPlot
      # we can pass an array of SegmentMarkers or a grouped set
      @updatePlot(groups)
      return

Template.incidentReports.helpers
  formatUrl: formatUrl
  getSettings: ->
    fields = [
      {
        key: 'count'
        label: 'Incident'
        fn: (value, object, key) ->
          if object.cases
            return pluralize('case', object.cases)
          else if object.deaths
            return pluralize('death', object.deaths)
          else
            return object.specify
        sortFn: (value, object) ->
          0 + (object.deaths or 0) + (object.cases or 0)
      }
      {
        key: 'locations'
        label: 'Locations'
        fn: (value, object, key) ->
          if object.locations
            $.map(object.locations, (element, index) ->
              element.name
            ).toString()
          else
            ''
      }
      {
        key: 'dateRange'
        label: 'Date'
        fn: (value, object, key) ->
          dateFormat = 'M/D/YYYY'
          if object.dateRange?.type is 'day'
            if object.dateRange.cumulative
              "Before " + moment(object.dateRange.end).format(dateFormat)
            else
              moment(object.dateRange.start).format(dateFormat)
          else if object.dateRange?.type is 'precise'
            "#{moment(object.dateRange.start).format(dateFormat)} -
              #{moment(object.dateRange.end).format(dateFormat)}"
          else
            ''
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
      template.plot.applyFilters()
    else
      $target.addClass('active')
      $icon.removeClass('fa-circle-o').addClass('fa-check-circle')
      template.plot.removeFilter('notCumulative')
      template.plot.addFilter('cumulative', template.filters.cumulative)
      template.plot.applyFilters()
    $(event.currentTarget).blur()

  'click #scatterPlot-resetZoom': (event, template) ->
    template.plot.resetZoom()
    $(event.currentTarget).blur()

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
    date = moment(@dateRange.start).format("MMM D, YYYY")
    location = @locations[0].name
    Modal.show 'deleteConfirmationModal',
      objNameToDelete: 'incident'
      objId: @_id
      displayName: "#{location} on #{date}"

  # Remove any open incident report details elements on pagination
  'click .next-page,
   click .prev-page,
   change .reactive-table-navigation .form-control': (event, template) ->
     template.$('tr.details').remove()
