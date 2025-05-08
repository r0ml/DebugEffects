#  DebugEffects

One can invoke shaders directly from SwiftUI views (using VisualEffects ).  See [Inferno](https://github.com/twostraws/Inferno/).
However, when running these shaders, I could not find a way to debug them
using the Metal Debugger in XCode.  This project is my solution to that problem.

Using the Metal macros provided in this project, and the supporting SwiftUI scaffolding,
one can run shaders as SwiftUI visual effects, and then, by toggling the Debug switch, one runs the same shader with the same arguments directly as a fragment shader, which allows invoking the XCode Metal Debugger upon it.

The scaffolding also provides support for passing in various kinds of dynamic parameters to the shader (numerical variables, mouse position, colors, images) which can be used to parameterize the behavior of any shader running in either regular SwiftUI visual effect mode or Metal debug mode.

The project comes preloaded with a variety of shaders to demonstrate how to use various features.  Documentation for these features will become available -- but it is always useful to having a working code sapmle.

The scaffolding is a standard three-pane app.  Rleated shaders can be grouped.  The first pane is the list of shader groups, the second pane will show the list of shaders in the selected group, and the rightmost pane will contain the selected shader from the shader list.

The search field in the top right will search for shader names beginning with the search text across all the groups.

All three types of visual effects shaders are supported: colorEffect, layerEffect, and distortionEffect -- and there are examples of all three kinds.

Currently, the difference between a regular shader and a Metal shader is that the Metal shader is twice as wide and high (in pixels) as the SwifTUI shader -- I'm guessing because of display scale on retina displays.
Shaders which use pixel counts instead of proportional sizes will exhibit different behavior between regulare and debug modes.  

All the visual effects in SwiftUI start by using the current contents of the view and modifying it.  DebugEffects has support to pass in a color, and image, or a video to be this video content.  In the case of video, the next video frame is passed to the shader for each render.

Shaders can be paused, resumed, and single-stepped.  Single-stepping advances the time parameter by a tenth of a second. 

When the mouse is dragged across the display area, the mouse coordinates are passed to the shader.

To debug a shader, you must (of course) be running the project in XCode.  GPU Frame Capture must enabled in the options of the scheme that runs DebugEffects. Toggle the Debug switch to on. Then click on the Metal button in XCode, click the Capture button on the popup -- and you will be deposited into the Metal debugger.  


