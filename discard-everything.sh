#! /bin/sh
#
# * Copyright (C) 2014 Stefan Tauner
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

# First run fstrim on all mounted filesystems that reside on block devices supporting discards.
if ! command -v fstrim >/dev/null 2>&1 ; then
	echo >&2 "fstrim is not available."
else
	mount | while read dev on dir bla ; do
		if [ -b "$dev" ] && [ $(blockdev  --getdiscardzeroes $dev) -eq 0 ]; then
			fstrim "$dir"
		fi
	done
fi

# Then run blkdiscard on any free discardable space covered by lvm.
if ! command -v blkdiscard >/dev/null 2>&1 ; then
	echo >&2 "blkdiscard is not available."
else
	lvm pvs -o pv_name,vg_name,vg_free_count --noheadings | while read pvdev vgname free ; do
		vgdev="/dev/${vgname}/discard"
		if [ -e "$vgdev" ]; then
			echo "Logical volume $vgdev does already exist." >&2
			echo "If it is just a leftover from a previous run then remove it with:" >&2
			echo "lvm lvremove -f \"$vgdev\"" >&2
		elif [ -b "$pvdev" ] && [ $(blockdev  --getdiscardzeroes "$pvdev") -eq 0 ] && [ "$free" -gt 0 ]; then
			lvm lvcreate -l100%FREE -n discard "${vgname}" >/dev/null && blkdiscard "$vgdev"
			# There are (or at least were) many bugs prohibiting a clean removal
			# see http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=718582
			# https://bugzilla.redhat.com/show_bug.cgi?id=715624 etc.
			# The least invasive recovery strategy is just retrying a few times, so...
			cnt=5
			while [ $cnt -gt 0 ] && ! lvm lvremove -f "$vgdev" >/dev/null 2>&1 ; do
				sleep 1
				cnt=$(($cnt-1))
			done
			if [ "$cnt" -eq 0 ]; then
				echo "Could not remove logical volume $vgdev" >&2
			fi
		fi
	done
fi
