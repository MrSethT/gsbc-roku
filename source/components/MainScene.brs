' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of  MainScene
' Note that we need to import this file in MainScene.xml using relative path.
sub Init()
    ' set background color for scene. Applied only if backgroundUri has empty value
    m.top.backgroundColor = "0x662D91"
    m.top.backgroundUri = "pkg:/images/background.jpg"
    m.loadingIndicator = m.top.FindNode("loadingIndicator") ' store loadingIndicator node to m
    InitScreenStack()
    ShowGridScreen()
    RunContentTask() ' retrieving content

    SetupAnalytics()

    m.top.SignalBeacon("AppLaunchComplete")

end sub

sub SetupAnalytics()
    try
        ' google G4 analytics
        m.global.AddField("analytics", "node", false)
        m.global.analytics = CreateObject("roSGNode", "GoogleAnalytics")
        m.global.analytics.callFunc("initialize", {
            measurementId: "G-M2NE88QH7W"
            appName: "GSBC Video"
            docLocation: "https://ganttstreetbaptist.org/live"
            customArgs: {
            }
            'isFirstOpen: myIsFirstOpen ' THIS VALUE IS OPTIONAL, THE DEFAULT BEHAVIOR IS TO USE THE STORAGE TO KNOW IF IT's THE FIRST OPEN
            userProperties: {
            }
        })
        m.global.analytics.callFunc("start")

        if false then
            m.global.analytics.callFunc("enableDebug")
            m.global.analytics.callFunc("logEvent", "Thump", {
                "event_category": "Heartbeat",
                "event_label": "Roku",
                "value": "value",
                "page_title": "Roku"
            })
        end if
    catch e
        print "It went wrong:", e.message
    end try
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        ' handle "back" key press
        if key = "back"
            numberOfScreens = m.screenStack.Count()
            ' close top screen if there are two or more screens in the screen stack
            if numberOfScreens > 1
                CloseScreen(invalid)
                result = true
            end if
        end if
    end if
    ' The OnKeyEvent() function must return true if the component handled the event,
    ' or false if it did not handle the event.
    return result
end function
