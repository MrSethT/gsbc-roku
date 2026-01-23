function GetSupportedMediaTypes() as object ' returns AA with supported media types
    return {
        "live": "live"
    }
end function

sub OnInputDeepLinking(event as object) ' invoked in case of "roInputEvent"
    args = event.getData()
    if args <> invalid and ValidateDeepLink(args) ' validate deep link arguments
        DeepLink(m.GridScreen.content, args.mediaType, args.contentId) ' Perform deep linking
    end if
end sub

' check if deep link arguments are valid
function ValidateDeepLink(args as object) as boolean
    mediaType = args.mediaType
    contentId = args.contentId
    types = GetSupportedMediaTypes()
    return mediaType <> invalid and contentId <> invalid and types[mediaType] <> invalid
end function

' Perform deep linking
sub DeepLink(content as object, mediaType as string, contentId as string)
    playableItem = FindNodeById(content, contentId) ' find content for deep linking by contentId
    types = GetSupportedMediaTypes()
    ' check if chosen item has appropriate mediaType
    if playableItem <> invalid and playableItem.mediaType = types[mediaType]
        'only doing live for now
        ClearScreenStack() ' remove all screen from screen stack except GridScreen
        ' looking for appropriate handler for provided mediaType
        if mediaType = "live"
            HandleLiveMediaType(playableItem)
        end if
    end if
end sub

' Handler for "live" type
sub HandleLiveMediaType(content as Object)
    ShowVideoScreen(content, 0)
end sub

sub PrepareDetailsScreen(content as object)
    ' create DetailsScreen to be shown when user navigate from Video player
    ' it will contain info about played content
    m.deepLinkDetailsScreen = CreateObject("roSGNode", "DetailsScreen")
    m.deepLinkDetailsScreen.content = content
    m.deepLinkDetailsScreen.ObserveField("visible", "OnDeepLinkDetailsScreenVisibilityChanged")
    m.deepLinkDetailsScreen.ObserveField("buttonSelected", "OnDeepLinkDetailsScreenButtonSelected")
    AddScreen(m.deepLinkDetailsScreen) ' adds DetailsScreen to screen stack but don't show it
end sub

sub OnDeepLinkDetailsScreenVisibilityChanged(event as object) ' invoked when DetailsScreen or EpisodesScreen "visible" field is changed
    visible = event.GetData()
    screen = event.GetRoSGNode()
    if visible = false and IsScreenInScreenStack(screen) = false
        content = screen.content
        if content <> invalid
            ' jump to appropriate tile on GridScreen
            m.GridScreen.jumpToRowItem = [content.homeRowIndex, content.homeItemIndex]
            ' Invalidate deepLinkDetailsScreen if user press "Back" button on DetailsScreen
            if m.deepLinkDetailsScreen <> invalid
                m.deepLinkDetailsScreen = invalid
            end if
        end if
    end if
end sub

sub OnDeepLinkDetailsScreenButtonSelected(event as object) ' invoked when button is  pressed on DetailsScreen
    buttonIndex = event.getData() ' index of selected button
    details = event.GetRoSGNode()
    button = details.buttons.getChild(buttonIndex)
    content = m.deepLinkDetailsScreen.content.clone(true)
    ' Start playback from the beginning if user select play button
    if button.id = "play"
        content.bookmarkPosition = 0
    end if
    StartPlayback(content) ' show last played video
end sub
