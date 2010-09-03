#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright © 2008-2010 Zac Medico <zmedico@gentoo.org>
# Copyright © 2008-2010 Diego Elio Pettenò <flameeyes@gentoo.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
# ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
# CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
# SOFTWARE.

seconds_per_week = 7 * 24 * 60 * 60
# reinstall_period = None
reinstall_period = 5 * seconds_per_week

import os
import sys
import time

import portage

current_time = time.time()

portdb = portage.portdb
portdb.porttrees = [portdb.porttree_root] # exclude overlays
portdb.freeze()
settings = portage.config(clone=portage.settings)
vardb = portage.db[settings["ROOT"]]["vartree"].dbapi
fakedb = portage.fakedbapi(settings=portage.settings)
deps = {}

metadata_keys = [k for k in portage.auxdbkeys if not k.startswith("UNUSED_")]
dep_keys = ["DEPEND", "RDEPEND", "PDEPEND"]
good_pkgs = set()
bad_pkgs = set()

for cp in portdb.cp_all():
	best_visible = portdb.xmatch("bestmatch-visible", cp)
	if best_visible:
		best_installed = portage.best(vardb.match(cp))
		reinstall = False
		if best_installed and reinstall_period is not None:
			try:
				mtime = os.stat(os.path.join(
					vardb.getpath(best_installed), 'COUNTER')).st_mtime
			except OSError:
				reinstall = True
			else:
				if current_time - mtime > reinstall_period:
					reinstall = True
					#sys.stderr.write("%s is %.1f weeks old\n" % \
					#	(best_installed,
					#	(current_time - mtime) / seconds_per_week))

		if reinstall or best_visible != best_installed:

			traversed = set()
			dep_stack = []
			dep_stack.append(("=" + best_visible, best_visible))
			unsatisfied_dep = False

			while dep_stack:
				dep_atom, parent = dep_stack.pop()
				dep_pkg = portdb.xmatch("bestmatch-visible", dep_atom)
				if not dep_pkg:
					unsatisfied_dep = True
					bad_pkgs.add(parent)
					break

				if dep_pkg in bad_pkgs:
					unsatisfied_dep = True
					bad_pkgs.add(parent)
					break

				if dep_pkg in good_pkgs or dep_pkg in traversed:
					continue

				metadata = dict(zip(metadata_keys,
					portdb.aux_get(dep_pkg, metadata_keys)))

				# If this package isn't the highest visible version
				# in the slot then drop it in order to avoid a slot
				# conflict.
				slot_atom = "%s:%s" % (portage.cpv_getkey(dep_pkg),
					metadata["SLOT"])
				best_visible_slot = portdb.xmatch("bestmatch-visible",
					slot_atom)
				if dep_pkg != best_visible_slot:
					unsatisfied_dep = True
					bad_pkgs.add(dep_pkg)
					bad_pkgs.add(parent)
					break

				dep_str = " ".join(metadata[k] for k in dep_keys)
				settings.setcpv(dep_pkg, mydb=metadata)
				metadata["USE"] = settings["PORTAGE_USE"]
				success, atoms = portage.dep_check(dep_str,
					None, settings, myuse=metadata["USE"].split(),
					trees=portage.db, myroot=settings["ROOT"])

				if not success:
					sys.stderr.write(atoms + "\n")
					unsatisfied_dep = True
					bad_pkgs.add(dep_pkg)
					bad_pkgs.add(parent)
					break

				traversed.add(dep_pkg)
				fakedb.cpv_inject(dep_pkg, metadata=metadata)

				deps[dep_pkg] = atoms
				for atom in atoms:
					if atom.blocker:
						continue
					dep_stack.append((atom, dep_pkg))

			if unsatisfied_dep:
				bad_pkgs.add(best_visible)
			else:
				good_pkgs.update(traversed)
				print cp

for cpv in good_pkgs:
	for atom in deps[cpv]:
		if atom.blocker:
			continue
		if not atom.use:
			continue
		if not fakedb.match(atom):
			sys.stderr.write("%s has unsatisfied USE dep: %s\n" % (cpv, atom))
			#for cpv2 in fakedb.match(atom.cp):
			#	sys.stderr.write("   %s IUSE: %s USE: %s\n" % (cpv2,
			#		fakedb.aux_get(cpv2, ["IUSE"])[0],
			#		fakedb.aux_get(cpv2, ["USE"])[0]))
