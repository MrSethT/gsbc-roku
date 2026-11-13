' returns AA mapping each supported deep-link mediaType to the item mediaType it plays
function GetSupportedMediaTypes() as object
    return {
        "live": "live"
        ' prerecorded sermons, deep linked by MP3_uid. Roku Search sends tvSpecial, because the
        ' search feed lists sermons as that type (shortForm is limited to 15 minutes)
        "shortFormVideo": "shortFormVideo"
        "tvSpecial": "shortFormVideo"
    }
end function

sub OnInputDeepLinking(event as object) ' invoked in case of "roInputEvent"
    args = event.getData()
    if args <> invalid and ValidateDeepLink(args) ' validate deep link arguments
        if m.GridScreen.content = invalid
            m.top.launchArgs = args ' still loading: OnMainContentLoaded performs the deep link
        else
            DeepLink(m.GridScreen.content, args.mediaType, args.contentId) ' Perform deep linking
        end if
    end if
end sub

' check if deep link arguments are valid
function ValidateDeepLink(args as object) as boolean
    mediaType = args.mediaType
    contentId = args.contentId
    types = GetSupportedMediaTypes()
    return mediaType <> invalid and contentId <> invalid and types[mediaType] <> invalid
end function

' Perform deep linking; returns true if playback was started
function DeepLink(content as object, mediaType as string, contentId as string) as boolean
    itemType = GetSupportedMediaTypes()[mediaType]
    if itemType = invalid
        return false
    end if
    if itemType = "shortFormVideo" and contentId = "-1"
        ' "-1" means the latest sermon (the feed is newest first)
        playableItem = FindFirstByMediaType(content, itemType)
    else
        playableItem = FindNodeById(content, contentId) ' find content for deep linking by contentId
    end if
    ' check if chosen item has appropriate mediaType
    if playableItem = invalid or playableItem.mediaType <> itemType
        return false
    end if

    ClearScreenStack() ' remove all screen from screen stack except GridScreen
    ' the video player runs in playlist mode, so play just this item as a one-item playlist
    playlist = CreateObject("roSGNode", "ContentNode")
    playlist.live = playableItem.live ' lets ShowVideoScreen recognize the livestream
    playlist.AppendChild(playableItem.Clone(false))
    ShowVideoScreen(playlist, 0) ' resumes from the bookmark if there is one, with no prompt
    return true
end function

' returns the first item (in grid order) with the given mediaType, or invalid
function FindFirstByMediaType(content as object, mediaType as string) as object
    for each row in content.GetChildren(-1, 0)
        for each item in row.GetChildren(-1, 0)
            if item.mediaType = mediaType
                return item
            end if
        end for
    end for
    return invalid
end function
