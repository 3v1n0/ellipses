# -*- coding: utf-8 -*-
# Copyright (C) 2009 Marien Zwart
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

"""Plugin adding "repo:" as a location alias.

This violates the usual bzr rule that repositories are strictly an
optimization (avoiding duplicated history). But in some setups
((lightweight) checkouts with the repository in an unrelated
location) it is very useful.
"""

from bzrlib import directory_service
from bzrlib.lazy_import import lazy_import
lazy_import(globals(), """
from bzrlib.branch import Branch
from bzrlib import urlutils
""")


class RepositoryDirectory(object):

    def look_up(self, name, url):
        alias, sep, url = url.partition(':')
        # Just making sure I understand how the directory service works.
        assert sep is not None and alias == 'repo'

        branch = Branch.open_containing('.')[0]
        return urlutils.join(branch.repository.bzrdir.root_transport.base,
                             url)


directory_service.directories.register(
    'repo:', RepositoryDirectory, 'Easy access to the repository root')
