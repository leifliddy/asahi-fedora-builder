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
5. The only network service installed is ```systemd-networkd```, it's configured to pull in an address via dhcp for both the ```eth0``` and ```wlp1s0f0``` interfaces.  
   ie.  
   **/etc/systemd/network/eth0.network**
   ```
   [Match]
   Name=eth0

   [Network]
   DHCP=yes
   ```
  The ```eth0``` intferface was meant for an external usb ethernet adapter. That's the interface name it "should" be assigned.   
6. Use ```iwd``` to setup the wifi interface (see info below)   
6. The ```systemd-udev-trigger-early``` and ```update-vendor-firmware.service``` services  
   from the asahi project have been implemented in this image:  
   https://github.com/AsahiLinux/asahi-scripts/tree/main/systemd  
8. Apple M1-related modules are included in the initramfs image via a dracut config.  
9. I might create a **cinnamon desktop** build in the future. 

**Todo:**
1. Sign RPM's with a gpg key. 
2. Modify the kernel SRPM to show where the kernel source is being pulled from.


**Setting up wifi**  
   
The ```iwd``` service is enabled by default.  
The wireless interface name "should" be ```wlp1s0f0```:  
```
wlp1s0f0: flags=4098<BROADCAST,MULTICAST>  mtu 1500
        ether b0:be:83:1f:5b:c9  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
\*\* at least it is on my macbook air m1  

A basic ```systemd-networkd``` config file for this interface has already been created at  
**/etc/systemd/network/wlp1s0f0.network**
```
[Match]
Name=wlp1s0f0

[Network]
DHCP=yes
```

To connect to a wireless network:  
```iwctl --passphrase passphrase station device connect SSID```  
ie  
```iwctl --passphrase supersecretpassword station wlp1s0f0 connect blacknet-ac```  
..and that's it. Your system should re-connect to this network upon reboot.   
The connection information for this network is stored under ```/var/lib/iwd```   

For more information on ```systemd-networkd``` and ```iwd``` functionality:   
https://wiki.archlinux.org/title/Iwd   
https://wiki.archlinux.org/title/systemd-networkd

