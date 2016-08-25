formatLocation = require '/imports/formatLocation.coffee'

Template.location.onCreated ->
  @editSourcesState = new ReactiveVar(false)
  @index = 0

Template.location.helpers
  isEditingSources: () ->
    return Template.instance().editSourcesState.get()
  articleSelectId: () ->
    return "articles-" + Template.instance().data._id
  selectedArticles: () ->
    urls = []
    for article in Template.instance().data.sourceArticles
      urls.push(article.articleId)
    return urls
  allArticles: () ->
    return grid.Articles.find({userEventId: Template.instance().data.userEventId}).fetch()
  formatDate: (date) ->
    return moment(date).format("MMM D, YYYY")

Template.location.events
  "click .proMedLink": (event, template) ->
    anchorNode = event.currentTarget
    url = anchorNode.getAttribute 'uri'
    if url
      $('#proMedIFrame').attr('src', url)
      $('#proMedURL').attr('href', url)
      $('#proMedURL').text(url)
      $('#proMedModal').modal("show")
  "click .edit-sources, click .cancel-edit-sources": (event, template) ->
    template.editSourcesState.set(not template.editSourcesState.get())
  "click .save-edit-sources": (event, template) ->
    $articlesInput = $("#articles-" + template.data._id)
    articles = []
    for option in $articlesInput.select2("data")
      articles.push({
        articleId: option.id,
        url: option.text
      })
    if articles.length
      Meteor.call("updateLocationArticles", template.data._id, articles, (error, result) ->
        if not error
          template.editSourcesState.set(false)
      )
    else
      toastr.error('The location must have at least one source article')
      $articlesInput.select2("open")

Template.locationList.onCreated ->
  @locationView = false

Template.locationList.helpers
  getSettings: ->
    fields = [
      {
        key: "displayName"
        label: "Title"
        fn: (value, object, key) ->
          return formatLocation(
            name: object.displayName
            admin1Name: object.subdivision
            countryName: object.countryName
          )
      },
      {
        key: "addedDate"
        label: "Added"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
    ]

    if Meteor.user()
      fields.push({
        key: "delete"
        label: ""
        cellClass: "remove-row"
      })

    fields.push({
        key: "expand"
        label: ""
        cellClass: "open-row"
    })

    return {
      id: 'event-locations-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
    }

Template.locationList.events
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    if $target.closest(".remove-row").length
      if confirm("Do you want to delete the selected location?")
        Meteor.call("removeEventLocation", @_id)
    else
      $parentRow = $target.parents("tr")
      if not $parentRow.hasClass("location-details")
        currentLocationView = template.locationView
        closeRow = $parentRow.hasClass("details-open")
        if currentLocationView
          template.$("tr").removeClass("details-open")
          template.$("tr.location-details").remove()
          Blaze.remove(currentLocationView)
          template.locationView = false
        if not closeRow
          $tr = $("<tr>").addClass("location-details")
          $parentRow.addClass("details-open").after($tr)
          template.locationView = Blaze.renderWithData(Template.location, {location: this}, $tr[0])

  "click #add-location": (event, template) ->
    $loc = $("#location-select2")
    $art = $("#article-select2")
    allLocations = []
    allArticles = []

    for option in $loc.select2("data")
      allLocations.push(
        geonameId: option.item.id
        name: option.item.name
        displayName: option.item.name
        countryName: option.item.countryName
        subdivision: option.item.admin1Name
        latitude: option.item.latitude
        longitude: option.item.longitude
        articles: allArticles
      )

    for option in $art.select2("data")
      allArticles.push({
        articleId: option.id,
        url: option.text
      })

    unless allLocations.length
      toastr.error('Please select a location')
      $loc.focus()
      return

    unless allArticles.length
      toastr.error("Please select at least one article that references the location")
      $art.focus()
      return

    Meteor.call("addEventLocations", template.data.userEvent._id, allArticles, allLocations, (error, result) ->
      if not error
        $loc.select2("val", "")
        $art.select2("val", "")
    )

Template.locationModal.helpers
  locationOptionText: (location) ->
    return formatLocation(
      name: location.displayName
      admin1Name: location.subdivision
      countryName: location.countryName
    )

Template.locationModal.events
  "click #add-suggestions": (event, template) ->
    geonameIds = []
    allLocations = []
    $("#suggested-locations-form").find("input:checked").each(() ->
      geonameIds.push($(this).val())
    )

    for loc in @suggestedLocations
      if geonameIds.indexOf(loc.geonameId) isnt -1
        allLocations.push(loc)

    if allLocations.length
      Meteor.call("addEventLocations", @userEventId, [@article], allLocations, (error, result) ->
        Modal.hide(template)
      )
    else
      Modal.hide(template)
