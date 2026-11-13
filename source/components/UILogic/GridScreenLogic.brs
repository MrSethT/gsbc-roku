' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

sub ShowGridScreen()
    m.GridScreen = CreateObject("roSGNode", "GridScreen")
    m.GridScreen.ObserveField("rowItemSelected", "OnGridScreenItemSelected")
    ShowScreen(m.GridScreen) ' show GridScreen
end sub

sub OnGridScreenItemSelected(event as Object)
    grid = event.GetRoSGNode()
    ' extract the row and column indexes of the item the user selected
    m.selectedIndex = event.GetData()
    ' the entire row from the RowList will be used by the Video node
    rowContent = grid.content.GetChild(m.selectedIndex[0])
    ShowDetailsScreen(rowContent, m.selectedIndex[1])
end sub

' Rebuilds the "Continue Watching" row (third row) from the saved bookmarks.
' The row lists the bookmarked sermons in feed order and is removed when there are none.
sub RefreshResumeRow()
    content = m.GridScreen.content
    if content = invalid
        return
    end if
    liveRow = content.GetChild(0) ' "Live"
    sermons = content.GetChild(1) ' "Recent Sermons"
    if liveRow = invalid or sermons = invalid
        return
    end if

    section = CreateObject("roRegistrySection", "bookmarks")
    row = CreateObject("roSGNode", "ContentNode")
    row.title = "Continue Watching"
    row.id = "resumeRow" ' lets the details screen offer "Remove from Continue Watching"
    ids = "" ' signature of the row: each sermon id and its bookmark position
    inFeed = {}
    for each item in sermons.GetChildren(-1, 0)
        if item.id <> ""
            inFeed[item.id] = true
            if section.Exists(item.id)
                position = section.Read(item.id)
                resumeItem = item.Clone(false)
                ' show the frame where the viewer left off
                resumeItem.hdPosterUrl = ThumbnailAtTime(resumeItem.hdPosterUrl, position)
                row.AppendChild(resumeItem)
                ids = ids + item.id + ":" + position + ","
            end if
        end if
    end for

    ' forget bookmarks for sermons that have dropped out of the feed
    pruned = false
    for each key in section.GetKeyList()
        if not inFeed.DoesExist(key)
            section.Delete(key)
            pruned = true
        end if
    end for
    if pruned
        section.Flush()
    end if

    if ids = m.resumeRowIds
        return ' nothing changed, so leave the grid (and its focus) alone
    end if
    m.resumeRowIds = ids

    ' Give the grid a brand-new root holding exactly Live, Recent Sermons and (if any) the new
    ' resume row. Rebuilding avoids a stale or duplicated row from editing the list in place,
    ' and leaves the old resume row intact for a details screen that is still showing it.
    newRoot = CreateObject("roSGNode", "ContentNode")
    newRoot.AppendChild(liveRow)
    newRoot.AppendChild(sermons)
    if row.GetChildCount() > 0
        newRoot.AppendChild(row)
    end if
    m.GridScreen.content = newRoot
end sub

' returns a Mux thumbnail URL with its time= parameter set to the given second
function ThumbnailAtTime(url as dynamic, seconds as string) as dynamic
    if GetInterface(url, "ifString") = invalid or url = ""
        return url
    end if
    regex = CreateObject("roRegex", "([?&])time=[^&]*", "")
    if regex.IsMatch(url)
        return regex.Replace(url, "\1time=" + seconds)
    end if
    separator = "?"
    if Instr(1, url, "?") > 0
        separator = "&"
    end if
    return url + separator + "time=" + seconds
end function
