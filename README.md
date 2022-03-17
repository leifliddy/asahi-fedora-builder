# asahi-fedora-builder
Asahi Linux Fedora reference image builder  

**this is currently in an alpha experimental state. Should have it fully functional soon  

Todo list:  
1  
Add documentation on how to build and/or install ```Fedora 35``` on a mac M1 system


2
The Fedora kernel rpm I created isn't building and/or packaging the apple-related modules that the asahi arch kernel is:  
This is probably why ```wifi``` isn't currently working...  
ie 
```
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/clk/clk-apple-nco.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/cpufreq/apple-soc-cpufreq.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/dma/apple-admac.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/hid/hid-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/hid/hid-appleir.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/hid/spi-hid/spi-hid-apple-of.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/hid/spi-hid/spi-hid-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/i2c/busses/i2c-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/input/mouse/appletouch.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/iommu/apple-dart.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/mailbox/apple-mailbox.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/net/appletalk/ipddp.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/nvme/host/nvme-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/pci/controller/pcie-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/pinctrl/pinctrl-apple-gpio.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/platform/apple/macsmc-rtkit.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/platform/apple/macsmc.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/soc/apple/apple-rtkit.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/soc/apple/apple-sart.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/spi/spi-apple.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/spmi/spmi-apple-controller.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/usb/misc/apple-mfi-fastcharge.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/drivers/usb/misc/appledisplay.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/net/appletalk/appletalk.ko.zst
./5.17.0-rc6-asahi-next-20220301-4-asahi-ARCH/kernel/sound/soc/apple/snd-soc-apple-mca.ko.zst
....
```
