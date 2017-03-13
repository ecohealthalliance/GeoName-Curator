Template.incidentTable.events
  'mouseover .incident-table tbody tr': (event, instance) ->
    if not instance.data.scrollToAnnotations
      return
    $annotation = $("span[data-incident-id=#{@_id}]")
    $("span[data-incident-id]").removeClass('viewing')
    appHeaderHeight = $('header nav.navbar').outerHeight()
    detailsHeaderHeight = $('.curator-source-details-header').outerHeight()
    headerOffset = appHeaderHeight + detailsHeaderHeight
    containerScrollTop = $('.curator-source-details-copy').scrollTop()
    annotationTopOffset = $annotation.offset().top
    countainerVerticalMidpoint = $('.curator-source-details-copy').height() / 2
    totalOffset = annotationTopOffset - headerOffset
    # Distance of scroll based on postition of text container, scroll position
    # within the text container and the container's midpoint (to position the
    # annotation in the center of the container)
    scrollDistance =  totalOffset + containerScrollTop - countainerVerticalMidpoint
    $('.curator-source-details-copy').stop().animate
      scrollTop: scrollDistance
    , 500, -> $annotation.addClass('viewing')
