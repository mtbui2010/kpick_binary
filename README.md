![license](https://img.shields.io/badge/license-MIT-green) ![PyTorch-1.4.0](https://img.shields.io/badge/PyTorch-1.4.0-blue)
# AI Picking package
## System Requirements:
```sh
- Ubuntu 16.04 or 18.04
- CUDA >=10.0, CUDNN>=7
- Pytorch >=1.4.0
```
## Install NVIDIA driver
```sh
check GPU info: 
sudo lshw -C display or hwinfo --gfxcard --short
Install:
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update
reboot
Open 'Software and update/ Addtional Drivers' and select proper driver
reboot
```

## Install CUDA and CUDNN
```sh
- Download *.run file from https://developer.nvidia.com/cuda-toolkit-archive
sudo sh cuda_XXX.run
- Follow the command line promts:
*** Note: Answer 'NO' for question "Install NVIDIA Accelerated Graphics Driver for Linux-XXX?"
- Download CUDNN from https://developer.nvidia.com/rdp/cudnn-archive
- Extract tar file
sudo cp /cuda/include/* /usr/loca/cuda-XX/include
sudo cp /cuda/lib64/* /usr/local/cuda-XX/lib64
- Set up CUDA path
sudo gedit ~/.bashrc
Add 2 lines to the file:
    PATH=/usr/local/cuda/bin:$PATH
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
source  ~/.bashrc

sudo gedit /etc/ld.so.conf.d/cuda.conf
Add: /usr/local/cuda/lib64
sudo ldconfig
reboot
```
## Install
```sh
sudo apt install python3.6-dev
sudo apt install python3.6-tk
cd $ROOT
pip install -e .
```
## Download pretrained network and cofigurations file
https://drive.google.com/drive/folders/1hdeJUe0EzIO6be5i-m8ygYpbnDGpHrKy?usp=sharing
** Place *.cfg files into $ROOT/configs, and trained *.pth to $ROOT/data/model/{grip or suction}_evaluator
## Demos
### Suction Detection with RGBD from realsense
```sh
from ttcv.sensor.realsense_sensor import RSSensor
import cv2

# get data from realsene
sensor = RSSensor()
sensor.start()
for i in range(5): rgb, depth = sensor.get_data()
# define detector
detector = SuctionDetector(cfg_path='configs/suction_net.cfg')
# set crop area
bbox = (630, 330, 1000, 670)    # left, top, right, bottom
# find suction  pose
Suctions = detector.find_suction_pose_rgb_depth(rgb=rgb, depth=depth, bbox=bbox)
out = detector.show_suctions_rgb_depth(rgb, depth, Suctions,  bbox=bbox)
# show
cv2.imshow('rgb', rgb[:, :, ::-1])
cv2.imshow('depth', depth)
cv2.imshow('out', out[:,:,::-1])
# release realsense
cv2.waitKey()
sensor.stop()
```
### Suction Detection with GUI
```sh
from  ttcv.basic.basic_objects import DetGui
from kpick.processing.suction_detection_v2 import SuctionDetector
class SuctionGuiDetector(SuctionDetector, DetGui):
    def gui_process_single(self, rgbd, method_ind=0, filename='unnamed', disp_mode='rgb'):
        if method_ind == 0: ret = self.show_suctions(
            rgbd=rgbd, Suctions=self.find_suction_pose_multiscale(rgbd=rgbd), disp_mode=disp_mode)
        return ret

from ttcv.sensor.realsense_sensor import get_realsense_modules
from ttcv.basic.basic_gui import BasGUI, GuiModule

cfg_path = 'configs/suction_net.cfg'
suction_detect_module = GuiModule(SuctionGuiDetector, type='suction_detector', name='Suction Detector',
                                  category='detector', cfg_path=cfg_path, num_mod_method=1)

BasGUI(title='Stefan Pose Maker',
       modules=[suction_detect_module] + get_realsense_modules(),
       )
```

### Suction Detection With TCP/IP connect
#### Server
```sh
from ttcv.basic.basic_tcp_connect import ServerThread
from kpick.processing.suction_detection_v2 import SuctionDetector


class SuctionSeverDetector(SuctionDetector, ServerThread):
    def __init__(self, cfg_path, host='localhost', port=8888):
        SuctionDetector.__init__(self,cfg_path=cfg_path)
        print('{} Detector initialized '.format('+'*10))
        ServerThread.__init__(self,host=host, port=port)
        print('{} Server initialized '.format('+' * 10))

    def process_received_data(self):
        Suctions = self.find_suction_pose_rgb_depth(rgb=self.data['rgb'], depth=self.data['depth'],
                                                    bbox=self.data['bbox'], ws_pts=self.data['ws_pts'])

        det = {'scores': Suctions.scores.tolist(), 'locs': Suctions.get_suction_locs(),
               'disp_color': Suctions.disp_colors, 'norms': Suctions.norm_vectors(), 'best_ind': Suctions.best_ind}
        out =  self.show_suctions_rgb_depth(rgb=self.data['rgb'], depth=self.data['depth'],
                                            Suctions=Suctions, bbox=self.data['bbox'],
                                            ws_pts=self.data['ws_pts'],  disp_mode=self.data['disp_mode'])
        return {'im':out, 'det': det}


if __name__=='__main__':
    SuctionSeverDetector(cfg_path='configs/suction_net.cfg').listen()


```
#### Client GUI
```sh
from ttcv.basic.basic_objects import  DetGuiObj
from ttcv.basic.basic_tcp_connect import ClientThread
from ttcv.utils.proc_utils import CFG
from ttcv.basic.basic_gui import BasGUI, GuiModule
from ttcv.sensor.realsense_sensor import get_realsense_modules


def demo_client_gui(host='localhost',port=8888):
    class ClientGui(DetGuiObj, ClientThread):
        def __init__(self, args=None, cfg_path=None):
            DetGuiObj.__init__(self, args=args, cfg_path=cfg_path)
            ClientThread.__init__(self, host=self.args.host, port=self.args.port)

        def gui_process_single(self, rgbd, method_ind=0, filename='unnamed', disp_mode='rgb'):

            rets =  self.send_and_get_return({'rgb': rgbd.rgb, 'depth': rgbd.depth,
                       'bbox': rgbd.workspace.bbox, 'ws_pts': rgbd.workspace.pts, 'disp_mode': disp_mode})
            print('Return received ...')

            if rets is None:
                print('None return ...')
                return rgbd.disp(mode=disp_mode)

            #++++++++++++++++++++++++++++ Robot actiont here
            det = rets['det']
            return rets['im']



    args = CFG()
    args.host, args.port = host, port
    client_module = GuiModule(ClientGui, type='client_gui', name='Client GUI', category='detector',
                              run_thread=True, args=args)
    BasGUI(title='Client Gui', modules=[client_module,]+get_realsense_modules())

if __name__=='__main__':
    demo_client_gui()
```
#### Client with realsense
```sh
from ttcv.sensor.realsense_sensor import RSSensor
import cv2
from ttcv.basic.basic_tcp_connect import ClientThread

# get data from realsene
sensor = RSSensor()
sensor.start()
# for i in range(5): rgb, depth = sensor.get_data()

# define detector
# detector = SuctionDetector(cfg_path='configs/suction_net.cfg')

# set crop area
bbox = None  # (630, 330, 1000, 670)    # left, top, right, bottom
ws_pts = [(177, 48), (1082, 40), (1104, 650), (855, 655), (760, 512), (692, 517), (762, 663), (136, 646)]
# init client
client = ClientThread()

while True:
    rgb, depth = sensor.get_data()
    cv2.imshow('im', rgb[:, :, ::-1])
    # find suction  pose
    # Suctions = detector.find_suction_pose_rgb_depth(rgb=rgb, depth=depth, bbox=bbox)
    # out = detector.show_suctions_rgb_depth(rgb, depth, Suctions,  bbox=bbox)

    sent_dict = {'rgb': rgb, 'depth': depth, 'bbox': None, 'ws_pts': ws_pts, 'disp_mode': 'rgb'}
    rets = client.send_and_get_return(sent_dict)

    out, det = rets['im'], rets['det']

    cv2.imshow('out', out[:, :, ::-1])
    if cv2.waitKey(10) == 27: break

# release realsense
sensor.stop()
```
### Grasp Detection with Realsense
```sh
from ttcv.sensor.realsense_sensor import RSSensor
from kpick.processing.grip_detection_v6 import GripDetector
import cv2
# get data from realsene
sensor = RSSensor()
sensor.start()
for i in range(5): rgb, depth = sensor.get_data()

# define detector
detector = GripDetector(cfg_path='configs/grip_net.cfg')

# set crop area
bbox = (630, 330, 1000, 670)  # left, top, right, bottom

# find suction  pose
Grips = detector.find_grip_pose_rgb_depth(rgb=rgb, depth=depth, bbox=bbox)
out = detector.show_grips_rgb_depth(rgb, depth, Grips, bbox=bbox)

# show
cv2.imshow('rgb', rgb[:, :, ::-1])
cv2.imshow('depth', depth)
cv2.imshow('out', out[:, :, ::-1])

# release realsense
cv2.waitKey()
sensor.stop()
```
### Grasp Detection with GUI
```sh
class GripGuiDetector(GripDetector, DetGui):
    def gui_process_single(self, rgbd, method_ind=0, filename='unnamed', disp_mode='rgb'):
        if method_ind == 0: ret = self.show_grips(
            rgbd=rgbd, Grips=self.find_grip_pose_from_edges_v3(rgbd=rgbd), disp_mode=disp_mode)
        return ret

from ttcv.sensor.realsense_sensor import get_realsense_modules
from ttcv.basic.basic_gui import BasGUI, GuiModule

cfg_path = 'configs/grip_net.cfg'
detect_module = GuiModule(GripGuiDetector, type='grip_detector', name='Grip Detector',
                          category='detector', cfg_path=cfg_path, num_mod_method=1)

BasGUI(title='Grip Detection GUI',
       modules=[detect_module] + get_realsense_modules(),
       )
```

### Grasp Detection Server
```sh
from ttcv.basic.basic_tcp_connect import ServerThread
from kpick.processing.grip_detection_v6 import GripDetector


class GripSeverDetector(GripDetector, ServerThread):
    def __init__(self, cfg_path, host='localhost', port=8888):
        GripDetector.__init__(self,cfg_path=cfg_path)
        print('{} Detector initialized '.format('+'*10))
        ServerThread.__init__(self,host=host, port=port)
        print('{} Server initialized '.format('+' * 10))

    def process_received_data(self):
        Grips = self.find_grip_pose_rgb_depth(rgb=self.data['rgb'], depth=self.data['depth'],
                                                    bbox=self.data['bbox'], ws_pts=self.data['ws_pts'])

        det = {'scores': Grips.scores, 'locs': Grips.get_grip_centers(),
               'disp_color': Grips.disp_colors, 'best_ind': Grips.best_ind}
        out =  self.show_grips_rgb_depth(rgb=self.data['rgb'], depth=self.data['depth'],
                                            Grips=Grips, bbox=self.data['bbox'],
                                            ws_pts=self.data['ws_pts'],  disp_mode=self.data['disp_mode'])
        return {'im':out, 'det': det}


if __name__=='__main__':
    GripSeverDetector(cfg_path='configs/grip_net.cfg').listen()

```

















