# asahi-fedora-builder


Builds a minimal Fedora image to run on Apple M1/M2 systems.

<img src="https://user-images.githubusercontent.com/12903289/200475188-41b1faf1-9b00-4376-ad8c-b9da19ef4d3f.png" width=65%>

**fedora package install:**
```dnf install mkosi arch-install-scripts systemd-container zip```

**note:** ```qemu-user-static``` is also needed if building the image on a ```non-aarch64``` system  
**note:** until this PR is merged into the next `mkosi` release https://github.com/systemd/mkosi/pull/1264/commits  
install mksoi from main:   
`python3 -m pip install --user git+https://github.com/systemd/mkosi.git`  

**To install a prebuilt image:**
Make sure to update your macOS to version 12.3 or later, then just pull up a Terminal in macOS and paste in this command:
```
curl https://leifliddy.com/fedora.sh | sh
```

**Notes:**
1. The root password is **fedora**
2. On the first boot the ```asahi-firstboot.service``` will run and will take around a minute to complete.  
3. The Asahi Linux-related RPM's (and Source RPM's) used in this image can be found here:  
   https://leifliddy.com/asahi-linux/37/  
   All RPM's signed are signed by a GPG key.
   The repo config can be found here:  
   https://leifliddy.com/asahi-linux/asahi-linux.repo
4. The Fedora kernel config used is nearly identical to the kernel config used by the Asahi Linux project:  
   \*\*only a few Fedora-specific modifications were made
   https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config

**Setting up wifi**  
`NetworkManager` is enabled by default.

To connect to a wireless network, use the following sytanx:  
```nmcli dev wifi connect network-ssid```  
an actual example:  
```nmcli dev wifi connect blacknet-ac password supersecretpassword```  
<br/>
**Wiping Linux**  
Bring up a Terminal in macOS and run the following Asahi Linux script:  
```curl -L https://alx.sh/wipe-linux | sh```  
You should definitely understand what this script does before running it.  
You can find more info here:  
https://github.com/AsahiLinux/docs/wiki/Partitioning-cheatsheet

**Boot from USB device**  
Once Linux is installed on an M1 system, you can then boot a compatible usb drive via ```u-boot```.  
This project will create a bootable USB drive for M1 systems.  
https://github.com/leifliddy/asahi-fedora-usb  

**Display and keyboard backlight**  
The `light` command can be used to adjust the screen and keyboard backlight  
```
light -s sysfs/leds/kbd_backlight -S 10
light -s sysfs/backlight/apple-panel-bl -S 50
```


**Fedora 37 release:**  
To upgrade from F36 --> F37 https://github.com/leifliddy/asahi-fedora-builder/issues/11  

**Known issues:**  
**mesa-asahi libraries**  
If you have mesa version `1:23.0.0_pre20221207` or `1:23.0.0_pre20221209` installed  
please see the following: https://github.com/leifliddy/asahi-fedora-builder/issues/8#issuecomment-1352990854  

**xorg-x11-server:** There's currently a known issue that causes `xorg` to crash  
Please copy the following config file to `/etc/X11/xorg.conf.d/`  
https://github.com/AsahiLinux/PKGBUILDs/blob/main/asahi-configs/30-modeset.conf  

**note:** The following MR has been submitted for this:  
https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1021

Info on the offical Fedora effort to support Apple silicon:  
https://fedoraproject.org/wiki/SIGs/Asahi
