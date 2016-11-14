Incidents = require '/imports/collections/incidentReports.coffee'
Articles = require '/imports/collections/articles.coffee'

import {formatUrl} from '/imports/utils.coffee'


Template.articles.onCreated ->
  @selectedSourceId = new ReactiveVar null

Template.articles.onRendered ->
  @$('#sourceFilter input').attr 'placeholder', 'Search sources'
  instance = @
  @autorun ->
    instance.selectedSourceId.get()
    Meteor.defer ->
      instance.$('[data-toggle=tooltip]').tooltip delay: show: '300'

Template.articles.helpers
  getSettings: ->
    fields = [
      {
        key: "title"
        label: "Title"
        fn: (value, object, key) ->
          # switching over to displaying the title in this column.  If that's not loaded in the DB show the URL.
          return object.title || value
      },
      {
        key: "addedDate"
        label: "Added"
        fn: (value, object, key) ->
          return moment(value).fromNow()
        sortFn: (value) ->
          value
      },
      {
        key: "publishDate"
        label: "Publication Date"
        fn: (value, object, key) ->
          if value
            return moment(value).format('MMM D, YYYY')
          return ""
        sortFn: (value) ->
          value
      }
    ]

    fields.push
      key: "expand"
      label: ""
      cellClass: "action open-right"

    id: 'event-sources-table'
    fields: fields
    showFilter: false
    showNavigationRowsPerPage: false
    showRowCount: false
    class: "table event-sources"
    filters: ["sourceFilter"]

  selectedSource: ->
    selectedId = Template.instance().selectedSourceId.get()
    if selectedId
      Articles.findOne selectedId

  incidentsForSource: (sourceUrl) ->
    Incidents.find({userEventId: Template.instance().data.userEvent._id, url: sourceUrl}).fetch()

  locationsForSource: (sourceUrl) ->
    locations = {}
    incidents = Incidents.find({userEventId: Template.instance().data.userEvent._id, url: sourceUrl}).forEach( (incident) ->
      for location in incident.locations
        locations[location.id] = location.name
    )
    _.flatten locations

  formatUrl: (url) ->
    formatUrl(url)

Template.articles.events
  'click #event-sources-table tbody tr': (event, instance) ->
    event.preventDefault()
    instance.selectedSourceId.set @_id
    $(event.currentTarget).parent().find('tr').removeClass 'open'
    $(event.currentTarget).addClass 'open'

  'click .open-source-form': (event, instance) ->
    Modal.show 'sourceModal', userEventId: instance.data.userEvent._id

  'click .delete-source': (event, instance) ->
    source = Articles.findOne instance.selectedSourceId.get()
    Modal.show 'deleteConfirmationModal',
      userEventId: instance.data.userEvent._id
      objNameToDelete: 'source'
      objId: source._id
      displayName: source.title
    instance.$(event.currentTarget).tooltip('destroy')

  'click .edit-source': (event, instance) ->
    source = Articles.findOne instance.selectedSourceId.get()
    source.edit = true
    Modal.show 'sourceModal', source
    instance.$(event.currentTarget).tooltip('destroy')

Template.articleSelect2.onRendered ->
  $input = @$('select')
  options = {}

  if @data.multiple
    options.multiple = true

  $input.select2(options)

  if @data.selected
    $input.val(@data.selected).trigger('change')
  $input.next('.select2-container').css('width', '100%')

Template.articleSelect2.onDestroyed ->
  templateInstance = Template.instance()
  templateInstance.$('#' + templateInstance.data.selectId).select2('destroy')
