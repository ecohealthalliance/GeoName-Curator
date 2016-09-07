Template.articles.helpers
  getSettings: ->
    fields = [
      {
        key: "url"
        label: "Title"
        fn: (value, object, key) ->
          return value
      },
      {
        key: "addedDate"
        label: "Added"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
      {
        key: "publishDate"
        label: "Publication Date"
        fn: (value, object, key) ->
          return moment(value).format('MMM D, YYYY')
      }
    ]

    fields.push({
      key: "expand"
      label: ""
      cellClass: "open-row-right"
    })

    return {
      id: 'event-sources-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
      filters: ["sourceFilter"]
    }

Template.articles.events
  "click .open-source-form": (event, template) ->
    Modal.show("sourceModal", {userEventId: template.data.userEvent._id})

Template.articleSelect2.onRendered ->
  $input = @$("select")
  options = {}

  if @data.multiple
    options.multiple = true

  $input.select2(options)

  if @data.selected
    $input.val(@data.selected).trigger("change")
  $input.next(".select2-container").css("width", "100%")

Template.articleSelect2.onDestroyed ->
  templateInstance = Template.instance()
  templateInstance.$("#" + templateInstance.data.selectId).select2("destroy")
