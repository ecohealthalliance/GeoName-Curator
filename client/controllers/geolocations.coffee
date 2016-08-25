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

Template.locationList.events
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

  "click .remove-location": (event, template) ->
    if confirm("Do you want to delete the selected location?")
      Meteor.call("removeEventLocation", @_id)

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
