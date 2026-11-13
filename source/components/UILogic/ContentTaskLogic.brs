' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainScene.xml using relative path.

sub RunContentTask()
    m.contentTask = CreateObject("roSGNode", "MainLoaderTask") ' create task for feed retrieving
    ' observe content so we can know when feed content will be parsed
    m.contentTask.ObserveField("content", "OnMainContentLoaded")
    m.contentTask.ObserveField("loadFailed", "OnMainContentFailed")
    m.contentTask.control = "run" ' GetContent(see MainLoaderTask.brs) method is executed
    m.loadingIndicator.visible = true ' show loading indicator while content is loading
end sub

sub OnMainContentFailed() ' invoked when the feed could not be retrieved
    m.loadingIndicator.visible = false
    ' a dialog before the home page is usable: Roku excludes its time from launch measurement
    if m.launchBeaconSent <> true and m.launchDialogOpen <> true
        m.launchDialogOpen = true
        m.top.SignalBeacon("AppDialogInitiate")
    end if
    ShowMessageDialog("Unable to Load Videos", "We couldn't reach GSBC right now. Please check your internet connection and try again.", "Try Again", "OnRetryContentLoad")
end sub

sub OnRetryContentLoad()
    CloseMessageDialog()
    RunContentTask()
end sub

sub OnMainContentLoaded() ' invoked when content is ready to be used
    m.GridScreen.SetFocus(true) ' set focus to GridScreen
    m.loadingIndicator.visible = false ' hide loading indicator because content was retrieved
    m.GridScreen.content = m.contentTask.content ' populate GridScreen with content
    m.resumeRowIds = "" ' fresh content has no "Continue Watching" row yet
    RefreshResumeRow()

    args = m.top.launchArgs
    if args <> invalid and ValidateDeepLink(args) and DeepLink(m.GridScreen.content, args.mediaType, args.contentId)
        ' a deep-link launch is complete once playback starts (see OnVideoPlayerStateChange)
        m.waitForPlaybackBeacon = true
    else
        SignalLaunchComplete()
    end if
end sub