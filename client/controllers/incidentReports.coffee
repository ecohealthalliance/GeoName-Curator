ScatterPlot = require '/imports/charts/ScatterPlot.coffee'
RectMarker = require '/imports/charts/RectMarker.coffee'
tooltipTmpl = """
  <div class='row'>
    <div class='col-xs-12'>
      <span style='font-weight: bold;'>
        <%= obj.y %> <%= incidents %> (<%= obj.meta.location %>)</span>
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

Template.incidentReports.onDestroyed ->
  if @plot
    @plot.destroy()
    @plot = null

Template.incidentReports.onCreated ->
  incidents = @data.incidents
  Meteor.defer =>
    # format the data
    data = _.chain(incidents)
      .map((incident) ->
        RectMarker.createFromIncident(incident)
      ).filter((m) ->
        if typeof m != 'undefined'
          return m
      ).value()

    # build the plot
    @plot = new ScatterPlot({
      containerID: 'scatterPlot',
      svgContainerClass: 'scatterPlot-container',
      height: $('#event-incidents-table').height(),
      axes: {
        # show grid lines
        grid: true,
        x: {
          title: 'Time',
          type: 'datetime',
          minMax: [
            ScatterPlot.minDatetime(_.pluck(data, 'x')),
            ScatterPlot.maxDatetime(_.pluck(data, 'w')),
          ],
        },
        y: {
          title: 'Incidents',
          type: 'numeric',
          minMax: [
            0,
            ScatterPlot.maxNumeric(_.pluck(data, 'y')),
          ]
        }
      },
      tooltip: {
        opacity: .8
        # function to render the tooltip
        template: (marker) ->
          marker.moment = moment # template reference for momentjs
          marker.incidents = 'incidents'
          if marker.y <= 1
            marker.incidents = 'incident'
          # underscore compiled template
          tmpl = _.template(tooltipTmpl)
          # render the template from
          tmpl(marker)
      },
      zoom: true,
    })

    if data.length <= 0
      plot.showWarn('Not enough data.')
      return

    @plot.draw(data)

Template.incidentReports.helpers
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
        key: "dateRange"
        label: "Date"
        fn: (value, object, key) ->
          dateFormat = "M/D/YYYY"
          if object.dateRange?.type is "day"
            if object.dateRange.cumulative
              return "Before " + moment(object.dateRange.end).format(dateFormat)
            else
              return moment(object.dateRange.start).format(dateFormat)
          else if object.dateRange?.type is "precise"
            return moment(object.dateRange.start).format(dateFormat) + " - "
            + moment(object.dateRange.end).format(dateFormat)
          return ""
        sortFn: (value, object) ->
          +new Date(object.dateRange.end)
      },
      {
        key: "travelRelated"
        label: "Travel Related"
        fn: (value, object, key) ->
          if value
            return "Yes"
          return ""
      },
      {
        key: "species"
        label: "Species"
      }
    ]

    if Meteor.user()
      fields.push({
        key: "delete"
        label: ""
        cellClass: "remove-row"
      })

      fields.push({
        key: "Edit"
        label: ""
        cellClass: "edit-row"
      })

    fields.push({
      key: "expand"
      label: ""
      cellClass: "open-row"
    })

    return {
      id: 'event-incidents-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
    }

Template.incidentReports.events
  "click #event-incidents-table th": (event, template) ->
    template.$("tr").removeClass("details-open")
    template.$("tr.tr-details").remove()
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest("tr")
    currentOpen = template.$("tr.tr-details")
    if $target.closest(".remove-row").length
      if window.confirm("Are you sure you want to delete this incident report?")
        currentOpen.remove()
        Meteor.call("removeIncidentReport", @_id)
    else if $target.closest(".edit-row").length
      Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id, edit: true, incident: this})
    else if not $parentRow.hasClass("tr-details")
      closeRow = $parentRow.hasClass("details-open")
      if currentOpen
        template.$("tr").removeClass("details-open")
        currentOpen.remove()
      if not closeRow
        $tr = $("<tr>").addClass("tr-details").html(Blaze.toHTMLWithData(Template.incidentReport, this))
        $parentRow.addClass("details-open").after($tr)
