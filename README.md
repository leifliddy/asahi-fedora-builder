# asahi-fedora-builder

Builds a minimal Fedora image to run on Apple M1/M2 systems

<img src="https://github.com/leifliddy/asahi-fedora-builder/assets/12903289/58acf44c-f34b-4573-a0fa-ad8052cfc8ce" width=65%>  
<br/>
<br/>

**Important**:  
Note that the **asahi-repos-edge** repository is no longer being maintained.  
If you've installed this image prior to 31 July 2023, then please remove the `asahi-repos-edge` package with:  
```sh
dnf remove asahi-repos-edge
```

## Installing a Prebuilt Image

Make sure to update your macOS to version 12.3 or later, then just pull up a Terminal in macOS and paste in this command:

```sh
curl https://leifliddy.com/fedora.sh | sh
```

## Fedora Package Install

```dnf install arch-install-scripts bubblewrap systemd-container zip```

### Notes

- ```qemu-user-static``` is also needed if building the image on a ```non-aarch64``` system  
- Until this PR is merged into the next `mkosi` release <https://github.com/systemd/mkosi/pull/1264/commits>  
  install mksoi from main:  
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git`

### Notes

1. The root password is **fedora**
2. On the first boot the ```asahi-firstboot.service``` will run, selinux will be set to enforcing and the system will reboot.   
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

## Display and keyboard backlight

The `light` command can be used to adjust the screen and keyboard backlight.

```sh
light -s sysfs/leds/kbd_backlight -S 10
light -s sysfs/backlight/apple-panel-bl -S 50
```

## Asahi Fedora Remix
As of `1 April 2023`, this project now installs packages from the `Asahi Fedora Remix` repos  
To transition from a previous `F37` build ----> `Asahi Fedora Remix`  
please see the following: https://github.com/leifliddy/asahi-fedora-builder/issues/25  

## Fedora 37 Release
To upgrade from F36 --> F37 <https://github.com/leifliddy/asahi-fedora-builder/issues/11>

Info on the official Fedora effort to support Apple silicon:
<https://fedoraproject.org/wiki/SIGs/Asahi>
