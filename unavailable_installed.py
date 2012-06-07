#!/usr/bin/env python2

import portage

portdb = portage.portdb
portdb.porttrees = [portdb.porttree_root] # exclude overlays
settings = portage.config(clone=portage.settings)
vardb = portage.db[settings['ROOT']]['vartree'].dbapi

for cpv in vardb.cpv_all():
	slot, = vardb.aux_get(cpv, ['SLOT'])
	cp = portage.cpv_getkey(cpv)
	atom = cp
	if slot:
		atom += ":" + slot
	if not portdb.xmatch('match-visible', atom):
		print atom
