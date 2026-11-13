' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of detailsScreen
function Init()
    ' observe "visible" so we can know when DetailsScreen change visibility
    m.top.ObserveField("visible", "OnVisibleChange")
    ' observe "itemFocused" so we can know when another item gets in focus
    m.top.ObserveField("itemFocused", "OnItemFocusedChanged")
    ' save a references to the DetailsScreen child components in the m variable
    ' so we can access them easily from other functions
    m.buttons = m.top.FindNode("buttons")
    m.poster = m.top.FindNode("poster")
    m.description = m.top.FindNode("descriptionLabel")
    m.timeLabel = m.top.FindNode("timeLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.releaseLabel = m.top.FindNode("releaseLabel")

    SetButtons(["Play"]) ' the list is finalized per item in SetDetailsContent
end function

' Sets the buttons list. Index 0 is always "Play"; when present, index 1 is "Play from Beginning"
' and index 2 is "Remove from Continue Watching" (handled by OnButtonSelected in DetailsScreenLogic.brs).
sub SetButtons(titles as object)
    signature = titles.Join("|")
    if signature = m.buttonSignature
        return ' unchanged: keep the list (and its focus) as it is
    end if
    m.buttonSignature = signature
    result = []
    for each button in titles
        result.Push({ title: button })
    end for
    m.buttons.content = ContentListToSimpleNode(result)

    ' keep the title and description clear of the buttons (each is 48 tall with 10 between)
    infoY = titles.Count() * 58 + 12
    if infoY < 108
        infoY = 108
    end if
    m.top.FindNode("infoGroup").translation = [0, infoY]
end sub

sub OnVisibleChange() ' invoked when DetailsScreen visibility is changed
    ' set focus for buttons list when DetailsScreen become visible
    if m.top.visible = true
        m.buttons.SetFocus(true)
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

' Populate content details information
sub SetDetailsContent(content as object)
    if content = invalid
        return
    end if
    ' the livestream has no beginning to go back to
    if content.live = true
        SetButtons(["Play"])
    else if m.top.content <> invalid and m.top.content.id = "resumeRow" ' opened from "Continue Watching"
        SetButtons(["Play", "Play from Beginning", "Remove from Continue Watching"])
    else
        SetButtons(["Play", "Play from Beginning"])
    end if
    m.description.text = content.description ' set description of content
    m.poster.uri = content.hdPosterUrl ' set url of content poster
    if(content.length > 0)
        m.timeLabel.text = GetTime(content.length) ' set length of content
    end if
    m.titleLabel.text = content.title ' set title of content
    if(content.releaseDate <> "")
        m.releaseLabel.text = content.releaseDate ' set release date of content
    end if
end sub

sub OnJumpToItem() ' invoked when jumpToItem field is populated
    content = m.top.content
    ' check if jumpToItem field has valid value
    ' it should be set within interval from 0 to content.Getchildcount()
    if content <> invalid and m.top.jumpToItem >= 0 and content.GetChildCount() > m.top.jumpToItem
        m.top.itemFocused = m.top.jumpToItem
    end if
end sub

sub OnItemFocusedChanged(event as object)' invoked when another item is focused
    focusedItem = event.GetData() ' get position of focused item
    if (getInterface(m.top.content, "roSGNode") = invalid)
        content = m.top.content.GetChild(focusedItem) ' get metadata of focused item
    else
        content = m.top.content
    end if
    SetDetailsContent(content) ' populate DetailsScreen with item metadata
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        currentItem = m.top.itemFocused ' position of currently focused item
        ' handle "left" button keypress
        if key = "left"
            ' navigate to the left item in case of "left" keypress
            m.top.jumpToItem = currentItem - 1
            result = true
            ' handle "right" button keypress
        else if key = "right"
            ' navigate to the right item in case of "right" keypress
            m.top.jumpToItem = currentItem + 1
            result = true
        end if
    end if
    return result
end function