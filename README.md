# Introduction

SSDs have sophisticated wear-leveling algorithms which need to know about free blocks to work correctly [[1]][trim].
Widespread Linux filesystems (e.g. Ext4, XFS, Btrfs) support to issue the needed commands automatically after removing data by adding the discard mount option but doing so can have a negative effect on performance [[2]][poster], [[3]][blog].

[trim]: https://en.wikipedia.org/wiki/Trim_(computing)
[poster]: http://sigops.org/sosp/sosp11/posters/posters/sosp11-display-poster16.pdf
[blog]: https://patrick-nagel.net/blog/archives/337

To read more about SSD handling in Linux see the help pages of your distribution (e.g. [Arch Linux][arch], [Debian][debian], [Fedora][fedora], [SUSE Linux][suse]).

[arch]: https://wiki.archlinux.org/index.php/Solid_State_Drives
[debian]: https://wiki.debian.org/SSDOptimization
[fedora]: http://docs.fedoraproject.org/en-US/Fedora/14/html/Storage_Administration_Guide/newmds-ssdtuning.html
[suse]: http://en.opensuse.org/SDB:SSD_discard_(trim)_support

# discard-everything.sh

This script does currently do two things:
- Run `fstrim` on all mounted filesystems that reside on block devices supporting discards.  
  This does not check if the actual file system supports discard.
- Run `blkdiscard` on any free discardable space covered by LVM.  
  It does so by creating temporary volumes covering 100% of the free VG space and issuing blkdiscard on them.

# Requirements

You need to have `fstrim` and `blkdiscard` (as well as all other support utilities used such as `lvm` and `blockdev`) available for execution.
Besides that, the file systems as well as all block layers beneath them (e.g. LVM, dm-crypt) need to be configured to pass the trim commands on to the next layer.
Of course it does only make sense to use `discard-everything.sh` if you don't mount your filesystems with the `discard` option.

## LVM

Make sure you have `issue_discards = 1` in the `devices` section of your `lvm.conf` (see [[4]][lvm.conf] or your local manpage: `man lvm.conf`).

[lvm.conf]: http://linux.die.net/man/5/lvm.conf
## dm-crypt

For devices created by `crypttab` add `allow-discards` as optional argument [[5]][crypttab].  
For those created by `cryptsetup` use the `--allow-discards` parameter (see [[6]][cryptsetup] or your local manpage: `man cryptsetup`).

[crypttab]: http://www.freedesktop.org/software/systemd/man/crypttab.html
[cryptsetup]: http://linux.die.net/man/8/cryptsetup

Usage
=====
Just copy discard-everything.sh into /etc/cron.weekly/ or a similar place, or execute it manually regularly (as root).
