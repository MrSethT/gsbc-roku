' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    ' parse the feed and build a tree of ContentNodes to populate the GridView
    json = FetchFeed()
    if json = invalid
        m.top.loadFailed = true ' observer (see OnMainContentFailed) tells the viewer
        return
    end if

    rootChildren = []

    'live
    row = {}
    row.title = "Live"
    row.children = []
    live = GetLiveData(json)
    row.children.push(live)
    rootChildren.Push(row)

    row = {}
    row.title = "Recent Sermons"
    row.children = []
    for each item in json ' parse items and push them to row
        if IsValidVideo(item) and item.Live = false
            itemData = GetItemData(item)
            row.children.Push(itemData)
        end if
    end for
    rootChildren.Push(row)

    ' set up a root ContentNode to represent rowList on the GridScreen
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({
        children: rootChildren
    }, true)
    ' populate content field with root content node.
    ' Observer(see OnMainContentLoaded in MainScene.brs) is invoked at that moment
    m.top.content = contentNode
end sub

' returns the parsed feed array, or invalid if it can't be retrieved
function FetchFeed() as object
    maxAttempts = 3
    for attempt = 1 to maxAttempts
        body = RequestFeed()
        if body <> ""
            json = ParseJson(body)
            if GetInterface(json, "ifArray") <> invalid
                return json
            end if
        end if
        if attempt < maxAttempts
            Sleep(2000)
        end if
    end for
    return invalid
end function

' returns the response body, or "" on a failed or timed out request
function RequestFeed() as string
    timeoutMs = 15000
    port = CreateObject("roMessagePort")
    xfer = CreateObject("roURLTransfer")
    xfer.SetMessagePort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.RetainBodyOnError(true)
    xfer.AddHeader("Accept", "application/json")
    xfer.SetURL("https://www.ganttstreetbaptist.org/WebMethods/Media.asmx/GetSermonVideoListJSON?thumbnailWidth=305&thumbnailHeight=172")

    if xfer.AsyncGetToString()
        msg = Wait(timeoutMs, port)
        if type(msg) = "roUrlEvent"
            if msg.GetResponseCode() = 200
                return msg.GetString()
            end if
        else
            xfer.AsyncCancel()
        end if
    end if
    return ""
end function

' a record needs these fields to be listed and played; anything else is skipped
function IsValidVideo(video as dynamic) as boolean
    if GetInterface(video, "ifAssociativeArray") = invalid
        return false
    end if
    if GetInterface(video.Live, "ifBoolean") = invalid
        return false
    end if
    return GetInterface(video.CloudId, "ifString") <> invalid and video.CloudId <> ""
end function

function GetItemData(video as object) as object
    item = {}
    ' populate some standard content metadata fields to be displayed on the GridScreen
    ' https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
    item.description =  video.Description
    item.hdPosterURL = video.MuxThumbnailUrl
    item.title = video.Title
    if GetInterface(video.Date, "ifString") <> invalid
        AMPM = " PM"
        if GetInterface(video.AM, "ifBoolean") <> invalid and video.AM
            AMPM = " AM"
        end if
        item.releaseDate = ParseDate(video.Date).AsDateString("long-date") + AMPM
    end if
    if GetInterface(video.MP3_uid, "ifToStr") <> invalid
        item.id = video.MP3_uid.ToStr() ' ContentNode ids are strings
    end if
    'if video.content <> invalid
    ' populate length of content to be displayed on the GridScreen
    item.length = invalid
    item.playStart = video.VideoStartSeconds
    ' populate meta-data for playback
    item.url = "https://stream.mux.com/" + video.CloudId + ".m3u8"
    item.streamFormat = "hls"
    item.mediaType = "shortFormVideo" ' Roku's deep-link media type for these videos
    'end if
    return item
end function

function GetLiveData(json) as object
    itemData = {}
    found = false
    
    for each item in json ' parse items and push them to row
        if IsValidVideo(item) and item.Live = true and not found
            itemData = GetItemData(item)
        end if
    end for

    ' populate some standard content metadata fields to be displayed on the GridScreen
    ' https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
    itemData.description = ""
    itemData.title = "GSBC Livestream"
    itemData.live = true
    'item.releaseDate = video.releaseDate
    itemData.id = "-1" ' matched by deep links (contentId=-1); ContentNode ids are strings
    itemData.releaseDate = "" ' string field; the live tile shows no date
    ' populate length of content to be displayed on the GridScreen
    itemData.length = invalid
    ' populate meta-data for playback
    itemData.streamFormat = "hls"
    itemData.mediaType = "live"
    return itemData
end function

function ParseDate(dateString as string) as object
    date = CreateObject("roDateTime")
    '/Date(1657090800000)/
    'string of text and last 4 '0'
    date.FromSeconds(StrToI(Mid(dateString, 7, Len(dateString) - (6 + 5))))
    return date
end function