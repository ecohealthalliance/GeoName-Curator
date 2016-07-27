references = =>
  @grid.References

Template.references.helpers
  getReferences: ->
    references().getReferences(@event.eidID)
