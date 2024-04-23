using Images
using FileIO
using Base64
using GLMakie
using VideoIO

function resize_img(img, factor)
    img = imresize(img, ratio=factor)
    return img
end

function main()
    plt = GLMakie
    # load the image
    img_file = "/home/ra/Documents/julia/PPF/assets/map_puzzle.png"
    img_full = load(img_file)

    # prepare the plot
    f = Figure()

    puz_ax = plt.Axis(f[1:2, 1:4])
    cam_ax = plt.Axis(f[3, 1])
    img_ax = plt.Axis(f[3, 2])
    edg_ax = plt.Axis(f[3, 3])
    ftr_ax = plt.Axis(f[3, 4])

    # remove all decorations
    for ax in [puz_ax, cam_ax, img_ax, edg_ax, ftr_ax]
        hidedecorations!.(ax, grid = false, label = false)
    end

    plt.colgap!(f.layout, 0)
    plt.rowgap!(f.layout, 0)
    
    img = resize_img(img_full, 0.5)
    
    plt.image!(puz_ax, rotr90(img))

    # setup the camera

    camera_ip = "http://192.168.1.40:8080/video"
    # camera_ip = "http://145.116.176.140:4747/video"
    strm = VideoIO.openvideo(camera_ip)
    
    frame = rotr90(read(strm))
    
    cam_frame = Observable(frame)
    img_frame = Observable(frame)
    # read_frame = @task read!(strm, frame)
    
    function update_cam_frame()
        @async while true
            read!(strm, frame)
            cam_frame[] = rotr90(frame)
            sleep(0.01)
        end
    end
    
    
    on(events(f).keyboardbutton) do event
        if event.key == Keyboard.space
            # print("capturing frame")
            img_frame[] = to_value(cam_frame)
            sleep(0.1)
        end
    end
    
    
    # plot the camera feed in the camera axis
    update_cam_frame()
    plt.image!(cam_ax, cam_frame)
    plt.image!(img_ax, img_frame)

    display(f)

end

main()