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
		lvcreate -l100%FREE -n discard ${vgname} >/dev/null && blkdiscard /dev/${vgname}/discard
		# There are (or at least were) many bugs prohibiting a clean removal
		# see http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=718582
		# https://bugzilla.redhat.com/show_bug.cgi?id=715624 etc.
		# The least invasive recovery strategy is just retrying a few times, so...
		cnt=5
		while [ $cnt -gt 0 ] && ! lvremove -f /dev/${vgname}/discard >/dev/null 2>&1 ; do
			sleep 1
			cnt=$(($cnt-1))
		done
		if [ "$cnt" -eq 0 ]; then
			echo "Could not remove logical volume /dev/${vgname}/discard" >&2
		fi
	fi
done
