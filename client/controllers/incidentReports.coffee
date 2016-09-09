Template.incidentReports.helpers
  getSettings: ->
    fields = [
      {
        key: "count"
        label: "Incident"
        fn: (value, object, key) ->
          if object.cases
            return object.cases + " case" + (if object.cases isnt "1" then "s" else "")
          else if object.deaths
            return object.deaths + " death" + (if object.deaths isnt "1" then "s" else "")
          else
            return object.specify
      },
      {
        key: "locations"
        label: "Locations"
        fn: (value, object, key) ->
          if object.locations
            return $.map(object.locations, (element, index) ->
              return element.displayName
            ).toString()
          return ""
      },
      {
        key: "date"
        label: "Date"
        fn: (value, object, key) ->
          if object.date
            return moment(value).fromNow()
          return ""
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
