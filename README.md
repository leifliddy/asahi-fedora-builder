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
3. The Fedora kernel config used is nearly identical to the kernel config used by the Asahi Linux project:  
   \*\*only a few Fedora-specific modifications were made  
   https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
4. On the first boot, the efi and / (root) filesystem UUID's will be randomized.  
   And the root partition will be resized to take up all available space.  
5. In short, this is essentially the Fedora version of the Asahi Linux Minimal build (Arch Linux-based).  
   The Asahi-related services, scripts, configs, and methodologies have simply been converted from Arch Linux --> Fedora.  
6. The only network service installed is ```systemd-networkd```  
   Basic config files for the ```eth0``` and ```wlp1s0f0``` interfaces are included in the image   
   ie.  
   **/etc/systemd/network/eth0.network**
   ```
   [Match]
   Name=eth0

   [Network]
   DHCP=yes
   ```
   The ```eth0``` intferface was meant for an external usb ethernet adapter.  
   That's the interface name it "should" be assigned to.   
7. Use ```iwd``` to setup the wifi interface (see info below)   
8. I might create a **cinnamon desktop** build in the future. 

**Todo:**
1. Sign RPM's with a gpg key. 
2. Modify the kernel SRPM to show where the kernel source is being pulled from.


**Setting up wifi**  
   
The ```iwd``` service is enabled by default.  
The wireless interface name "should" be ```wlp1s0f0```  
```
wlp1s0f0: flags=4098<BROADCAST,MULTICAST>  mtu 1500
        ether b0:be:83:1f:5b:c9  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
``` 

A basic ```systemd-networkd``` config for this interface is included in the image and is located at:  
**/etc/systemd/network/wlp1s0f0.network**
```
[Match]
Name=wlp1s0f0

[Network]
DHCP=yes
```

To connect to a wireless network, use the following sytanx:  
```iwctl --passphrase passphrase station device connect SSID```  
an actual example:  
```iwctl --passphrase supersecretpassword station wlp1s0f0 connect blacknet-ac```  
..and that's it. ```systemd-networkd``` should then pull in an address via ```dhcp```   
and your system should re-connect to this network upon reboot.   

Connection info for ```iwd``` connections are stored under ```/var/lib/iwd```   

For more information on ```iwd``` and ```systemd-networkd``` functionality:   
https://wiki.archlinux.org/title/Iwd   
https://wiki.archlinux.org/title/systemd-networkd

If you install a desktop environment (gnome, kde, cinnamon...etc), then you'll probably want to disable (and stop) these two services ie   
```systemctl disable --now iwd systemd-networkd```
