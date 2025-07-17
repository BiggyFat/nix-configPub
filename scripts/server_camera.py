import os
from typing import Optional
is_windows = (os.name == 'nt')
if is_windows:
    import wpygrapper as wgrap
    from ctypes import oledll
    backend = 700

else:
    import subprocess
    import pyudev
    backend = 0
import cv2
import re
from threading import Thread
import io
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse, Response
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import numpy as np
from PIL import Image
import time

# Trouve le chemin absolu du dossier où se trouve le script.
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construit le chemin complet vers l'image.
image_path = os.path.join(script_dir, 'no_picture.jpg')

# Ouvre l'image en utilisant son chemin absolu.
no_image = Image.open(image_path)

img_byte_arr = io.BytesIO()
no_image.save(img_byte_arr, format='JPEG')
img_bytes_no_image = img_byte_arr.getvalue()

pattern = r'Device Caps(?:.|\n)*?Video Capture'

webcam_map = {}
sn_map = {}
sn_index_map = {}
captures = [None, None, None, None, None, None]
frames_bytes = [img_bytes_no_image, img_bytes_no_image, img_bytes_no_image, img_bytes_no_image, img_bytes_no_image, img_bytes_no_image]
frames = [None, None, None, None, None, None]
read_cam = [False, False, False, False, False, False]
save_video = [False, False, False, False, False, False]
now = time.time() - 10
last_call_get_indexes = now
last_calls = [now, now, now, now, now, now]
last_rgb_computed = [now, now, now, now, now, now]
video_cam = [None, None, None, None, None, None]

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to your needs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_indexes():
    global is_windows, pattern, last_call_get_indexes
    current_time = time.time()
    delta = current_time - last_call_get_indexes
    print(delta)
    if delta < 5:
        return
    last_call_get_indexes = current_time
    index = -1
    # webcam_map.clear()
    # sn_map.clear()
    # sn_index_map.clear()
    if is_windows:
        graph = wgrap.FilterGraph()
        webcams = graph.get_input_devices()
        for i, elem in enumerate(webcams):
            print(str(i) + "  " + elem[0] + "  " + elem[1])
            sn = ''
            props = elem[1].split('&')
            if (len(props) > 3 and 'RealSense' not in elem[0]):
                sn = props[3]
                webcam_map[i] = {"name": elem[0], "property": elem[1], "sn": sn}
                index = index + 1
                sn_index_map[sn] = index
                sn_map[sn] = i
                print('index ' + str(index) + '   --- ' + elem[0] + ' ' + sn)

    else:
        context = pyudev.Context()
        for device in context.list_devices(subsystem='video4linux'):
            webcam_info = {
                "device": device.sys_name,
                "model": device.get('ID_MODEL_ENC', '')
            }
            cmd = f"v4l2-ctl --device /dev/{device.sys_name} --all"
            try:
                output = subprocess.check_output(cmd.split()).decode("utf-8")
                if 'RealSense' not in output and re.search(pattern, output):
                    #print(output)
                    lines = output.split("\n")
                    for i in range(len(lines)):
                        if "Device Caps" in lines[i]:
                            for j in range(i + 1, len(lines)):
                                if "Video Capture" in lines[j]:
                                    webcam_info['interface_type'] = 'Video Capture'
                                    break
                            break
                    for line in lines:
                        if "Card type" in line:
                            webcam_info['name'] = line.split(":")[1].strip()
                        elif "Serial" in line:
                            sn = line.split(":")[1].strip()
                    if len(sn) < 1:
                        sn = webcam_info['name'] + "-" + str(index)
                    sn = sn.replace(" ", "").replace("-", "AA")
                    if webcam_info.get('interface_type', '') == 'Video Capture' and sn not in sn_map:
                        index = index + 1
                        print(webcam_info['device'])
                        sn_index_map[sn] = int(webcam_info['device'].replace("video", ""))
                        sn_map[sn] = index
                        webcam_map[index] = {"name": webcam_info['name'], "property": "", "sn": sn}
                        print(str(index) + ' - sn : ' + sn + ' - cv_index : ' + str(sn_map[sn]))
            except subprocess.CalledProcessError:
                print('')
                webcam_info['interface_type'] = 'Error'


get_indexes()

def set_parameters_rgb(cap, params):
    if cap.isOpened():
        param_list = params.split(";")
        for param in param_list:
            key, value = param.split(',')
            key = int(key)
            value = int(value)
            if (key <= 5):
                cap.set(key, value)
        cap.read()
        for param in param_list:
            key, value = param.split(',')
            key = int(key)
            value = int(value)
            if (key > 5):
                cap.set(key, value)


def task_rgb(number, is_reversed, is_rotated):
    while(read_cam[number]):
        current_time = time.time()
        delta_call = (current_time - last_calls[number])
        delta_computed = (current_time - last_rgb_computed[number])
        if (save_video[number] or (delta_call <= 5 and delta_computed >= 0.05)):
            current_time0 = time.time()
            last_rgb_computed[number] = current_time
            if captures[number].isOpened():
                ret, frames[number] = captures[number].read()
                if ret:
                    if is_reversed:
                        frames[number] = cv2.rotate(frames[number], cv2.ROTATE_180)
                    if is_rotated:
                        frames[number] = cv2.rotate(frames[number], cv2.ROTATE_90_CLOCKWISE)
                    img_encoded = cv2.imencode('.jpg', frames[number])[1]
                    frames_bytes[number] = img_encoded.tobytes()
                    if save_video[number] and (video_cam[number] is not None):
                        video_cam[number].write(frames[number])
                else:
                    frames_bytes[number] = img_bytes_no_image
        else:
            time.sleep(0.01)
    print('Stop thread')
    frames_bytes[number] = img_bytes_no_image

@app.get("/get_all_cams")
def get_all_cams():
    result = ''
    for value in webcam_map.values():
        if "Capture" not in value["name"]:
            result += value["sn"] + ',' + value["name"] + ';'
    return result

@app.get("/get_params")
def get_params(sn: str):
    result = ''
    if sn_map.get(sn) is None:
        return 'sn not found'
    camera_number = sn_map[sn]
    cap = captures[camera_number]
    return str(cap.get(10)) + ";" + str(cap.get(11)) + ";" + str(cap.get(12)) + ";" + str(cap.get(13)) + ";" + str(cap.get(14)) + ";" + str(cap.get(15)) + ";" + str(cap.get(27)) + ";" + str(cap.get(28))

@app.get("/get_image_np")
def get_image_rgb_np(sn: str):
    if sn_map.get(sn) is None:
        return 'No image found'
    camera_number = sn_map[sn]
    last_calls[camera_number] = time.time()
    img_byte_arr = io.BytesIO()
    np.save(img_byte_arr, frames[camera_number], allow_pickle=True)
    return img_byte_arr.getvalue()


@app.get("/get_image")
def get_image_rgb(sn: str):
    if sn_map.get(sn) is None:
        return Response(content=img_bytes_no_image, media_type="image/jpeg")
    camera_number = sn_map[sn]
    last_calls[camera_number] = time.time()
    return Response(content=frames_bytes[camera_number], media_type="image/jpeg")

@app.get("/stop_cam")
def stop_camera_rgb(sn: str):
    if sn_map.get(sn) is None:
        return 'sn not found'
    camera_number = sn_map[sn]
    if not read_cam[camera_number]:
        return 'Already Stopped camera'
    read_cam[camera_number] = False
    save_video[camera_number] = False
    captures[camera_number].release()
    if video_cam[camera_number] is not None:
        video_cam[camera_number].release()
        video_cam[camera_number] = None
    return 'Stopped camera'

@app.get("/update_cam")
def update_camera_rgb(sn: str, params: str):
    if sn_map.get(sn) is None:
        return 'sn not found'
    camera_number = sn_map[sn]
    set_parameters_rgb(captures[camera_number], params)
    return 'Update OK'

@app.get("/update_indexes")
def update_indexes():
    oledll.ole32.CoInitializeEx(None, 0)
    get_indexes()
    oledll.ole32.CoUninitialize()
    return 'OK'

@app.get("/start_cam")
def start_camera_rgb(sn: str, params: str, is_reversed: Optional[bool] = False, is_rotated: Optional[bool] = False):
    global backend
    if is_windows:
        oledll.ole32.CoInitializeEx(None, 0)
    get_indexes()
    if is_windows:
        oledll.ole32.CoUninitialize()

    if sn_map.get(sn) is None:
        return 'sn not found'
    camera_number = sn_map[sn]
    if read_cam[camera_number]:
        set_parameters_rgb(captures[camera_number], params)
        return 'Already Started camera'
    index_cv = sn_index_map[sn]
    captures[camera_number] = cv2.VideoCapture(backend + index_cv)
    print("Camera number: " + str(camera_number))
    if not is_windows:
        captures[camera_number].set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
    set_parameters_rgb(captures[camera_number], params)

    read_cam[camera_number] = True
    thread = Thread(target = task_rgb, args=(camera_number, is_reversed, is_rotated))
    thread.start()
    return 'Starting rgb camera'

@app.get("/get_status_camera_rgb")
def get_status_camera_rgb(sn: str):
    if sn_map.get(sn) is None:
        return 'sn not found'
    camera_number = sn_map[sn]
    if read_cam[camera_number]:
        return 'Running'
    return 'Not running'

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=3000)

