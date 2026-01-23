' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    ' request the content feed from the API
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.RetainBodyOnError(true)
    xfer.AddHeader("contentType", "application/json; charset=utf-8")
    xfer.SetURL("https://www.ganttstreetbaptist.org/WebMethods/Media.asmx/GetSermonVideoListJSON?thumbnailWidth=305&thumbnailHeight=172")
    rsp = xfer.GetToString()
    rootChildren = []
    rows = {}

    ' parse the feed and build a tree of ContentNodes to populate the GridView
    json = ParseJson(rsp)

    'live
    row = {}
    row.title = "Live"
    row.children = []
    live = GetLiveData(json)
    row.children.push(live)
    rootChildren.Push(row)

    if json <> invalid
        row = {}
        row.title = "Recent Sermons"
        row.children = []
        for each item in json ' parse items and push them to row
            if item.Live = false 
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
    end if
end sub

function GetItemData(video as object) as object
    item = {}
    ' populate some standard content metadata fields to be displayed on the GridScreen
    ' https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
    item.description =  video.Description
    item.hdPosterURL = video.MuxThumbnailUrl
    item.title = video.Title
    if(video.Date <> invalid)
        AMPM = " PM"
        if (video.AM)
            AMPM = " AM"
        end if
        item.releaseDate = ParseDate(video.Date).AsDateString("long-date") + AMPM
    end if
    item.id = video.MP3_uid
    'if video.content <> invalid
    ' populate length of content to be displayed on the GridScreen
    item.length = invalid
    item.playStart = video.VideoStartSeconds
    ' populate meta-data for playback
    item.url = "https://stream.mux.com/" + video.CloudId + ".m3u8"
    item.streamFormat = "hls"
    item.mediaType = "shortFormVideos"
    'end if
    return item
end function

function GetLiveData(json) as object
    itemData = {}
    found = false
    
    for each item in json ' parse items and push them to row
        if item.Live = true and not found 
            itemData = GetItemData(item)
        end if
    end for

    ' populate some standard content metadata fields to be displayed on the GridScreen
    ' https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
    itemData.description = ""
    itemData.title = "GSBC Livestream"
    itemData.live = true
    'item.releaseDate = video.releaseDate
    itemData.id = -1
    itemData.releaseDate = CreateObject("roDateTime")
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