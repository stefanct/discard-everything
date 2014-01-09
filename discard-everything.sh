#! /bin/sh
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# first run fstrim on all mounted filesystem that support
mount | while read dev on dir bla ; do
	if [ -b "$dev" ] && [ $(blockdev  --getdiscardzeroes $dev) -eq 0 ]; then
		fstrim "$dir"
	fi
done

# then run blkdiscard on any free discardable space covered by lvm
pvs -o pv_name,vg_name,vg_free_count --noheadings | while read dev vgname free ; do
	if [ -b "$dev" ] && [ $(blockdev  --getdiscardzeroes $dev) -eq 0 ] && [ "$free" -gt 0 ]; then
		lvcreate -l100%FREE -n discard ${vgname} && blkdiscard -v  /dev/${vgname}/discard
		lvchange -f -an /dev/${vgname}/discard
		lvremove -f /dev/${vgname}/discard
	fi
done
