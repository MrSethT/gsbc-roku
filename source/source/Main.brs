' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Channel entry point
sub Main(args as object)
    ShowChannelRSGScreen(args)
end sub

sub ShowChannelRSGScreen(args as object)
    ' The roSGScreen object is a SceneGraph canvas that displays the contents of a Scene node instance
    screen = CreateObject("roSGScreen")
    ' message port is the place where events are sent
    m.port = CreateObject("roMessagePort")
    ' sets the message port which will be used for events from the screen
    screen.SetMessagePort(m.port)
    ' every screen object must have a Scene node, or a node that derives from the Scene node
    scene = screen.CreateScene("MainScene")
    ' AppLaunchComplete is signaled by MainScene once content (or deep-link playback) is ready
    screen.Show() ' Init method in MainScene.brs is invoked
    scene.launchArgs = args
    inputObject = createobject("roInput")
    inputObject.setmessageport(m.port)
    SetupMemoryMonitoring()

    ' event loop
    while(true)
        ' waiting for events from screen
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if msgType = "roInputEvent"
            inputData = msg.getInfo()
            ? "input"
            ' pass the deeplink to UI
            if inputData.DoesExist("mediaType") and inputData.DoesExist("contentId")
                deeplink = {
                    contentId: inputData.contentID
                    mediaType: inputData.mediaType
                }
                scene.inputArgs = deeplink
            end if
        else if msgType = "roAppMemoryNotificationEvent"
            LogMemoryStatus("memory warning")
        else if msgType = "roDeviceInfoEvent"
            info = msg.GetInfo()
            if info <> invalid and info.generalMemoryLevel <> invalid
                LogMemoryStatus("device memory level: " + info.generalMemoryLevel)
            end if
        end if
    end while
end sub

' Subscribes to the channel and device low-memory events Roku recommends handling
sub SetupMemoryMonitoring()
    m.memoryMonitor = CreateObject("roAppMemoryMonitor")
    if m.memoryMonitor <> invalid
        m.memoryMonitor.SetMessagePort(m.port)
        m.memoryMonitor.EnableMemoryWarningEvent(true)
    end if

    m.deviceInfo = CreateObject("roDeviceInfo")
    m.deviceInfo.SetMessagePort(m.port)
    m.deviceInfo.EnableLowGeneralMemoryEvent(true)

    LogMemoryStatus("launch")
end sub

sub LogMemoryStatus(reason as string)
    if m.memoryMonitor = invalid
        return
    end if
    print "[memory] "; reason; ": "; m.memoryMonitor.GetMemoryLimitPercent(); "% of limit used, "; m.memoryMonitor.GetChannelAvailableMemory(); " KB available, limit "; FormatJson(m.memoryMonitor.GetChannelMemoryLimit())
end sub
