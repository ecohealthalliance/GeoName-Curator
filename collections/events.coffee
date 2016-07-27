Events = new Mongo.Collection "events"

@grid ?= {}
@grid.Events = Events

if Meteor.isServer
  ReactiveTable.publish "events", Events, {'eidVal': "1"}

  Meteor.publish "event", (eidID) ->
    Events.find({'eidID': eidID, 'eidVal': "1"})

  Meteor.publish "locations", ->
    Events.find({'eidVal': "1"}, {fields: {'locations.locationLatitude': 1, 'locations.locationLongitude': 1, eidID: 1, eventNameVal: 1, eidVal: 1, zoonoticVal: 1, eidCategoryVal: 1, eventTransmissionAnimalVal: 1}})

if Meteor.isClient
  italicize = (val) ->
    new Spacebars.SafeString "<i>#{val}</i>"

  italicizeGenusAndNextWord = (species, genus) ->
    speciesMinusGenus = species.split(genus)?[1]?.trim()
    words = speciesMinusGenus.split(/[,-\s]/g)
    speciesWithGenus = "#{genus} #{words[0]}"
    remainingWords = species.slice(speciesWithGenus.length)
    new Spacebars.SafeString "<i>#{speciesWithGenus}</i>#{remainingWords}"

  @grid.Events.formatVal = (key, val, object) ->
    if key in ['pathogenGenusVal', 'pathogenFamilyVal', 'pathogenOrderVal', 'pathogenClassVal']
      return italicize val
    else if key is 'pathogenSpeciesVal'
      pathogenType = object['pathogenTypeVal'].trim()
      genus = object['pathogenGenusVal'].trim()

      if genus and pathogenType isnt 'Virus'

        startsWithGenus = new RegExp "^#{genus}"

        if startsWithGenus.test val
          return italicizeGenusAndNextWord val, genus

      else
        # Enterovirus D, Parvovirus B19
        # but not GB virus C
        oneWordPlusLetterNumber = new RegExp "^[^,-\s]+\\s[A-Z][0-9]{0,2}$"
        
        # Sudan ebolavirus, Marburg marburgvirus
        # but not Tick-borne flavivirus or Australian bat lyssavirus
        oneWordPlusGenus = new RegExp "^[^,-\s]+\\s#{genus.toLowerCase()}$"

        if oneWordPlusLetterNumber.test(val.trim()) or oneWordPlusGenus.test(val.trim())
          return italicize val

    return val
