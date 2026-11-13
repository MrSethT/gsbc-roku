' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

function ShowDetailsScreen(content as Object, selectedItem as Integer) as Object
    ' create new instance of details screen
    detailsScreen = CreateObject("roSGNode", "DetailsScreen")
    detailsScreen.content = content
    detailsScreen.jumpToItem = selectedItem ' set index of item which should be focused
    detailsScreen.ObserveField("visible", "OnDetailsScreenVisibilityChanged")
    detailsScreen.ObserveField("buttonSelected", "OnButtonSelected")
    ShowScreen(detailsScreen)
    return detailsScreen
end function

sub OnButtonSelected(event) ' invoked when button in DetailsScreen is pressed
    details = event.GetRoSGNode()
    content = details.content
    buttonIndex = event.getData() ' index of selected button
    selectedItem = details.itemFocused
    if buttonIndex = 0 ' "Play": starts at the bookmark, or else the sermon's start time
        ShowVideoScreen(content, selectedItem)
    else if buttonIndex = 1 ' "Play from Beginning": starts at 0:00, ignoring both
        ShowVideoScreen(content, selectedItem, true)
    else if buttonIndex = 2 and content.id = "resumeRow" ' "Remove from Continue Watching"
        item = content.GetChild(selectedItem)
        if item <> invalid and item.id <> ""
            section = CreateObject("roRegistrySection", "bookmarks")
            section.Delete(item.id)
            section.Flush()
        end if
        RefreshResumeRow() ' rebuild the row first so focus lands on a row that still exists
        CloseScreen(details) ' back to the grid
    end if
end sub

sub OnDetailsScreenVisibilityChanged(event as Object) ' invoked when DetailsScreen "visible" field is changed
    visible = event.GetData()
    detailsScreen = event.GetRoSGNode()
    ' update GridScreen's focus when navigate back from DetailsScreen
    if visible = false
        rowIndex = m.selectedIndex[0]
        itemIndex = detailsScreen.itemFocused
        ' the "Continue Watching" row can shrink or disappear while a video plays
        row = invalid
        if m.GridScreen.content <> invalid
            row = m.GridScreen.content.GetChild(rowIndex)
        end if
        if row = invalid
            rowIndex = 1 ' fall back to "Recent Sermons"
            itemIndex = 0
        else if itemIndex >= row.GetChildCount()
            itemIndex = row.GetChildCount() - 1
        end if
        m.GridScreen.jumpToRowItem = [rowIndex, itemIndex]
    end if
end sub