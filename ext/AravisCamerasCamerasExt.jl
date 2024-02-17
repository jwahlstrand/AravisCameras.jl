module AravisCamerasCamerasExt

using AravisCameras

# useless at the moment

import Cameras: Camera

mutable struct AravisCamera <: Camera
    camera::ArvCameraLeaf
    isopen::Bool
    isrunning::Bool
    SimulatedCamera(cam::ArvCamera) = new(cam, false, false)
end

isopen(camera::AravisCamera) = camera.isopen
open!(camera::AravisCamera) = camera.isopen = true
close!(camera::AravisCamera) = camera.isopen = false

isrunning(camera::AravisCamera) = camera.isrunning
start!(camera::AravisCamera) = camera.isrunning = true

function stop!(camera::AravisCamera)
    camera.isrunning = false
end

function take!(camera::SimulatedCamera)
    #TODO
end

function trigger!(camera::SimulatedCamera)
    #TODO
end

end
