' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

sub ShowVideoScreen(rowContent as object, selectedItem as integer)
    StopPlaybackTracking() ' a deep link can replace a video that is still playing
    m.videoPlayer = CreateObject("roSGNode", "Video") ' create new instance of video node for each playback

    'MUX
    m.mux = CreateObject("roSGNode", "MuxTask")
    m.mux.setField("video", m.videoPlayer)

    muxConfig = {
        property_key: "p46a3pkjcpkb3v1esa7rn72od",
    }

    m.mux.setField("config", muxConfig)
    m.mux.control = "RUN"
    'END MUX

    if(m.selectedIndex = invalid)
        m.selectedIndex = []
        m.selectedIndex.push(0)
        m.selectedIndex.push(0)
    end if

    m.selectedIndex[1] = selectedItem
    isLive = false

    ' we can't set index of content which should start firstly in playlist mode.
    ' for cases when user select second, third etc. item in the row we use the following workaround
    if selectedItem <> 0 ' check if user select any but first item of the row
        numOfChildren = rowContent.GetChildCount() ' get number of row items
        ' populate children array only with  items started from selected one.
        ' example: row has 3 items. user select second one so we must take just second and third items.
        children = rowContent.GetChildren(numOfChildren - selectedItem, selectedItem)
        childrenClone = []
        ' go through each item of children array and clone them.
        for each child in children
            ' we need to clone item node because it will be damaged in case of video node content invalidation
            childrenClone.Push(child.Clone(false))
        end for
        ' create new parent node for our cloned items
        rowNode = CreateObject("roSGNode", "ContentNode")
        rowNode.Update({ children: childrenClone }, true)
        m.videoPlayer.content = rowNode ' set node with children to video node content
    else
        ' if playback must start from first item we clone all row node
        m.videoPlayer.content = rowContent.Clone(true)
        ' the Live row when chosen from the grid, or the live item itself from a deep link
        if(rowContent.TITLE = "Live" or rowContent.live = true)
            isLive = true
        end if
    end if

    m.isLivePlayback = isLive

    if(isLive)
        m.timer = CreateObject("roSGNode", "Timer")
        m.timer.repeat = true
        m.timer.duration = 60
        m.timer.observeField("fire", "timer_fire")
        m.timer.control = "start"
    end if

    m.videoPlayer.contentIsPlaylist = true ' enable video playlist (a sequence of videos to be played)
    ShowScreen(m.videoPlayer) ' show video screen
    m.videoPlayer.control = "play" ' start playback

    'm.videoPlayer.PlayStart(rowContent.children[selectedItem].streamStartTimeOffset)
    m.videoPlayer.ObserveField("state", "OnVideoPlayerStateChange")
    m.videoPlayer.ObserveField("visible", "OnVideoVisibleChange")
end sub

sub OnVideoPlayerStateChange() ' invoked when video state is changed
    state = m.videoPlayer.state

    ' a deep-link launch counts as complete once playback starts or ends without playing
    if m.waitForPlaybackBeacon = true and (state = "playing" or state = "error" or state = "stopped" or state = "finished")
        SignalLaunchComplete()
    end if

    ' Google Analytics engagement time only accrues while a video is actually playing
    if state = "playing"
        SetAnalyticsEngagement(true)
    else if state <> "buffering"
        SetAnalyticsEngagement(false)
    end if

    ' close video screen in case of error or end of playback
    if state = "error" or state = "finished"
        StopPlaybackTracking()
        CloseScreen(m.videoPlayer)
        if state = "error"
            ShowPlaybackErrorDialog()
        end if
    else if state = "stopped"
        StopPlaybackTracking()
    end if
end sub

sub SetAnalyticsEngagement(active as boolean)
    if m.global.analytics <> invalid
        m.global.analytics.callFunc("setEngagementActive", active)
    end if
end sub

sub ShowPlaybackErrorDialog()
    if m.isLivePlayback = true
        ShowMessageDialog("We're Not Live Right Now", "The livestream isn't on the air at the moment. Please check back during our next service, or watch a recent sermon.", "OK", "CloseMessageDialog")
    else
        ShowMessageDialog("Video Unavailable", "This video couldn't be played. Please try again later.", "OK", "CloseMessageDialog")
    end if
end sub

' Stops the live heartbeat and retires the Mux task for the current playback. Safe to call repeatedly.
sub StopPlaybackTracking()
    if m.timer <> invalid
        m.timer.control = "stop"
        m.timer = invalid
    end if

    if m.mux <> invalid
        if m.finishedMuxTasks = invalid
            m.finishedMuxTasks = []
        end if
        m.finishedMuxTasks.Push(m.mux)
        m.mux = invalid

        ' Mux sends queued events every 5 seconds and drops them on exit, so outlast one send
        if m.muxExitTimer = invalid
            m.muxExitTimer = CreateObject("roSGNode", "Timer")
            m.muxExitTimer.repeat = false
            m.muxExitTimer.duration = 6
            m.muxExitTimer.ObserveField("fire", "OnMuxExitTimerFire")
        end if
        m.muxExitTimer.control = "start"
    end if
end sub

sub OnMuxExitTimerFire()
    for each task in m.finishedMuxTasks
        task.exit = true
    end for
    m.finishedMuxTasks = []
end sub

sub timer_fire(event as object)
    ?"timer_fire"

    value = "h" + Right("0" + CreateObject("roDateTime").getHours().toStr(), 2)
    
    'G4
    if m.global.analytics  <> invalid
         m.global.analytics.callFunc("logEvent", "Thump", {
                "event_category": "Heartbeat",
                "event_label": "Roku",
                "value": value,
                "page_title": "Roku"
            })
    end if
    
end sub

sub OnVideoVisibleChange() ' invoked when video node visibility is changed
    if m.videoPlayer.visible = false and m.top.visible = true
        ' the index of the video in the video playlist that is currently playing.
        currentIndex = m.videoPlayer.contentIndex
        m.videoPlayer.control = "stop" ' stop playback
        'clear video player content, for proper start of next video player
        m.videoPlayer.content = invalid
        screen = GetCurrentScreen()
        if m.top.dialog = invalid ' an open error dialog must keep focus
            screen.SetFocus(true) ' return focus to grid screen
        end if
        ' navigate to the last played item
        screen.jumpToItem = currentIndex + m.selectedIndex[1]
    end if
end sub