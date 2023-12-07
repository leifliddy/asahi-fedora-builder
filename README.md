# asahi-fedora-builder

Builds a minimal Fedora image to run on Apple M1/M2 systems

<img src="https://github.com/leifliddy/asahi-fedora-builder/assets/12903289/331ed44e-8851-4dc3-a17a-31e23b3703a2" width=65%>  
<br/>
<br/>

## Installing a Prebuilt Image

Make sure to update your macOS to version 13.5 or later, then just pull up a Terminal in macOS and paste in this command:

```sh
curl https://leifliddy.com/fedora.sh | sh
```

## Fedora Package Install
```dnf install arch-install-scripts bubblewrap mkosi systemd-container zip```

#### Notes

- The ```qemu-user-static``` package is needed if building the image on a ```non-aarch64``` system  
- This project is based on `mkosi v19` which matches the current version of `mkosi` in the `F39` repo  
  https://src.fedoraproject.org/rpms/mkosi/  
  However....`mkosi` is updated so quickly that it's difficult to keep up at times (I have several projects based on `mkosi`)  
  I'll strive to keep things updated to the latest version supported in Fedora  
  If needed, you can always install a specific version via pip  
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git@v19`

### Notes

1. The root password is **fedora**
2. On the first boot the ```asahi-firstboot.service``` will run and the system will reboot   
3. This project installs packages from the `Asahi Fedora Remix` repos  
https://pagure.io/fedora-asahi/asahi-repos/tree/main  

## Setting up WiFi

`NetworkManager` is enabled by default.

To connect to a wireless network, use the following sytanx:
```nmcli dev wifi connect network-ssid```

An actual example:
```nmcli dev wifi connect blacknet-ac password supersecretpassword```

## Wiping Linux

Bring up a Terminal in macOS and run the following Asahi Linux script:  
```sudo curl -L https://alx.sh/wipe-linux | sh```  
You should definitely understand what this script does before running it. You can find more info here:  
<https://github.com/AsahiLinux/docs/wiki/Partitioning-cheatsheet>

## Boot from USB device

Once Linux is installed on an M1 system, you can then boot a compatible usb drive via ```u-boot```.  
This project will create a bootable USB drive for M1 systems.  
<https://github.com/leifliddy/asahi-fedora-usb>

## Persistently set your battery charge threshold to 80%
```sh
echo 'SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{charge_control_end_threshold}="80"' | sudo tee /etc/udev/rules.d/10-battery.rules
```

## Display and keyboard backlight

The `light` command can be used to adjust the screen and keyboard backlight.

```sh
light -s sysfs/leds/kbd_backlight -S 10
light -s sysfs/backlight/apple-panel-bl -S 50
```

## Asahi Fedora Remix
As of `1 April 2023`, this project now installs packages from the `Asahi Fedora Remix` repos  

## ChangeLog ##
**7-Nov-2023:** Install the **asahi-platform-metapackage** package  
If you've installed this image prior to this date, please install the `asahi-platform-metapackage` package with:  
```sh
dnf install asahi-platform-metapackage
```

**27-Aug-2023:** Install the **kernel-16k-modules-extra** package  
If you've installed this image prior to this date, please install the `kernel-16k-modules-extra` package with:  
```sh
dnf install kernel-16k-modules-extra
```
Otherwise, if you install a package that has a `kernel-modules-extra` dependency, the 4k kernel variant of that package will be installed instead.  

**23-Aug-2023:** Switched to the **kernel-16k** variant  
Ref: https://discussion.fedoraproject.org/t/switch-to-the-kernel-16k-variant/87711  

**31-Jul-2023:** removed the **asahi-repos-edge** repo  
Note: this repository is no longer being maintained.  
If you've installed this image prior to this date, please remove the `asahi-repos-edge` package with:  
```sh
dnf remove asahi-repos-edge
```
