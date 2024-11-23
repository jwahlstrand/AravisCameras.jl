using AravisCameras

# Tries to read a single image from the first camera found

update_device_list()
n_dev = AravisCameras.n_devices()
if n_dev == 0
    @warn("No cameras found")
end

camera::ArvCameraLeaf = ArvCamera(AravisCameras.device_id(0))
width, height = AravisCameras.sensor_size(camera)
mps = AravisCameras.G_.gv_auto_packet_size(camera)
ps = AravisCameras.G_.gv_get_packet_size(camera)
AravisCameras.exposure_time(camera,20000.0)

# uncomment one of these to set a particular pixel format
#AravisCameras.pixel_format(camera,AravisCameras.PIXEL_FORMAT_BAYER_RG_8)
#AravisCameras.pixel_format(camera,AravisCameras.PIXEL_FORMAT_BAYER_RG_12)
AravisCameras.pixel_format(camera,AravisCameras.PIXEL_FORMAT_MONO_8)

println("sensor size: $width, $height")
println("auto_packet_size: $mps")
println("packet size: $ps")

stream = AravisCameras.create_stream(camera)
if stream !== nothing
    stream.packet_timeout = 20*1000
    stream.frame_retention = 100*1000
    payload = AravisCameras.payload(camera)
    push!(stream, ArvBuffer(payload))
else
    @warn("failed to create stream")
    return nothing
end

AravisCameras.G_.start_acquisition(camera)
sleep(0.5)
buf::ArvBuffer = pop!(stream)
while AravisCameras.G_.get_status(buf) != AravisCameras.BufferStatus_SUCCESS
    push!(stream, buf)
    println("attempting to get another buffer")
    global buf = pop!(stream)
end
img = AravisCameras.G_.get_data(buf)
imwidth = AravisCameras.image_width(buf)
imheight = AravisCameras.image_height(buf)
format = AravisCameras.image_pixel_format(buf)
payload_type = AravisCameras.payload_type(buf)
#img = AravisCameras.image(buf)
println("image width and height: $imwidth, $imheight")
println("payload type: $payload_type")
#AravisCameras.G_.stop_acquisition(camera)

