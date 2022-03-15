# asahi-fedora-builder
Asahi Linux Fedora reference image builder

Todo list:
1.
Add documentation on how to build and/or install Fedora 35 on a mac M1 system

2.
Create a first-boot service that performs the equivalent function to grow the root partition and resize the filesystem. Will use UUID's in the actual function.

```
growpart /dev/nvme0n1 5
resize2fs /dev/nvme0n1p5
```

The mounting option ```x-systemd.growfs``` will not grow/expand the partition itself, I believe it's used to resize the filesystem. 

3.
Get wifi working.
