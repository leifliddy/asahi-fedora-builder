# asahi-fedora-builder
  
Builds a minimal Fedora image to run on Apple M1 systems.

**To install a prebuilt image:**  
Make sure to update your macOS to version 12.3 or later, then just pull up a Terminal in macOS and paste in this command:
```
curl https://leifliddy.com/fedora.sh | sh
```

**Notes:** 
1. The root password is **fedora**
2. The custom RPM's (and Source RPM's) used in this image can be found here:  
   https://leifliddy.com/asahi-linux/35/
3. The kernel config used is the same kernel config used by the asahi project:  
   \*\*only a few Fedora-specific modifications were made  
   https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
4. On the first boot, the efi and / (root) filesystem UUID's will be randomized.  
   And the root partition will be resized to take up all available space.  
5. The only network service installed is ```systemd-networkd```, it's configured to pull in an address via dhcp for ```eth0```
   ie
   **/etc/systemd/network/eth0.network**
   ```
   [Match]
   Name=eth0

   [Network]
   DHCP=yes
   ```
   So if you have a usb ethernet adapter, it should pull in an address for it.  
6. Use ```iwd``` to setup the wifi interface. (I might include a how-to guide on this later).
6. The ```systemd-udev-trigger-early``` and ```update-vendor-firmware.service``` services  
   from the asahi project have been implemented in this image:  
   https://github.com/AsahiLinux/asahi-scripts/tree/main/systemd
8. Apple M1-related modules are included in the initramfs image via a dracut config. 
9. I might create a **cinnamon desktop** build in the future. 
