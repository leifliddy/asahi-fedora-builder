# asahi-fedora-builder

Builds a minimal Fedora image to run on Apple M-series systems

<img src="https://github.com/user-attachments/assets/9fc9652b-1513-47f6-8c45-35e3dff3cafd" width=65%>  
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
- This project is based on `mkosi v22`
  https://src.fedoraproject.org/rpms/mkosi/  
  I wasn't able to build this image on higher versions of mkosi.  
  If someone is able to figure it out -- please contact me and/or submit a PR.

  If needed, you can always install a specific version via pip
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git@v22`

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
```sudo curl -L https://leifliddy.com/wipe-linux | sh```  
You should definitely understand what this script does before running it. You can find more info here:  
<https://github.com/AsahiLinux/docs/wiki/Partitioning-cheatsheet>

## Boot from USB device

This project will create a bootable USB drive for Apple M-series systems  
This requires that Linux is already installed on on the internal drive  
<https://github.com/leifliddy/asahi-fedora-usb>

## Set the default startup disk

```
[root@m1 ~]# asahi-bless 
 1) Macintosh HD, Data
*2) Fedora - Data, Fedora
==>
```

## Persistently set your battery charge threshold to 80%
```sh
echo 'SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{charge_control_end_threshold}="80"' | sudo tee /etc/udev/rules.d/10-battery.rules
```

## Mute the startup chime
```sh
asahi-nvram write system:StartupMute=%01
```

## Display and keyboard backlight
The `light` command can be used to adjust the screen and keyboard backlight.

```shthe asahi swap package
light -s sysfs/leds/kbd_backlight -S 10
light -s sysfs/backlight/apple-panel-bl -S 50
```

## Increase the terminal font size
On high-DPI displays, the terminal fonts (on the console) appear extremely small  
To increase the size, edit `/etc/vconsole.conf` and specify a larger font size, such as:  
```
FONT="latarcyrheb-sun32"
```

## Viewing protected content sites like netflix.com
Run the `widevine-installer` script (which is part of the `widevine-installer` rpm)  
This will create the necessary configuration changes to make Widevine available for both `Firefox` and `Chromium`-based browsers  
Now you need to download a User-Agent (UA) switch extension and modify the UA string to a Chromium OS one   
There's many UA extensions out there, here's just an example of how I did it  
I installed this UA switcher extension for firefox  
https://addons.mozilla.org/en-US/firefox/addon/user-agent-string-switcher/  
and then chose a `Chromium OS` userAgent string  

<img src="https://github.com/leifliddy/asahi-fedora-builder/assets/12903289/324e1de1-dad8-48fd-a392-58b56ad93fdb" width=65%>
<br/>
<br/>

Then I chose `Custom Mode` and entered the following so that the UA string is only used to override a specific site  
<br/>
<img src="https://github.com/leifliddy/asahi-fedora-builder/assets/12903289/6c6afdb1-df87-407b-9ff3-29a48c6f7e3b" width=65%>

```
{
  "netflix.com": [
    Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36
  ]
}
```

## Asahi Fedora Remix
As of `1 April 2023`, this project now installs packages from the `Asahi Fedora Remix` repos  

## ChangeLog ##
**6-Jan-2024:** Modified `grub` and installed `fedora-asahi-remix-scripts` package  
If you've installed this image prior to this date, please run the following:  
```sh
dnf reinstall grub2-efi-aa64
dnf install fedora-asahi-remix-scripts
systemctl start asahi-setup-swap-firstboot.service
rm /usr/sbin/create-efi-bootloader
rm /boot/efi/EFI/BOOT/BOOTAA64.EFI.old
```
**27-Apr-2024:** Upgraded to F40

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
