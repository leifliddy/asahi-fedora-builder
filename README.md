# asahi-fedora-builder
Asahi Linux Fedora reference image builder  

**this is currently in an alpha experimental state. Should have it fully functional

Todo list:  
1  
Add documentation on how to build and/or install ```Fedora 35``` on a mac M1 system


2
The Fedora kernel rpm I created isn't building and/or packaging the apple-related modules that the arch kernel is:  
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
....
```
