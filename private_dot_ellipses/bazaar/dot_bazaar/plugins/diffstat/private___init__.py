#!/usr/bin/python
"""diffstat - show stats about changes to the working tree"""

import bzrlib

from bzrlib.lazy_import import lazy_import
lazy_import(globals(), """
import sys
import re
from bzrlib import (
    builtins,
    option,
    config
    )

from bzrlib.option import Option
""")

from bzrlib.commands import display_command, register_command, plugin_cmds

version_info = (0, 2, 0, 'final', 0)

def version_string():
    """Convert version_info into a string"""
    if version_info[3] == 'final':
        version_string = '%d.%d.%d' % version_info[:3]
    else:
        version_string = '%d.%d.%d%s%d' % version_info
    return version_string

plugin_name = 'diffstat'
__version__ = version_string()


class cmd_diff(builtins.cmd_diff):
    builtins.cmd_diff.takes_options.append(option.Option('stat', help='Show diff summary statistics'))
    builtins.cmd_diff.takes_options.append(option.Option('stat-dir',  help='Show diff summary statistics per directory'))
    __doc__ = builtins.cmd_diff.__doc__
    encoding_type = 'replace'

    def _run_diff_wrapped(self, wrap_stdout=True, *args, **kwargs):
        """Run the diff command, possibly with its output wrapped.

        @param wrap_stdout: Should sys.stdout be wrapped?
        @return: (return value, output_stream) where output_stream is None if
                 wrap_stdout is False
        """
        output_stream = None
        orig_stdout = sys.stdout
        try:
            if wrap_stdout:
                from StringIO import StringIO
                output_stream = StringIO()
                sys.stdout = output_stream
            retval = diff_class.run(self, *args, **kwargs)
        finally:
            sys.stdout = orig_stdout
        return retval, output_stream

    @display_command
    def run(self, *args, **kwargs):
        stat = kwargs.pop('stat', False)
        stat_dir = kwargs.pop('stat_dir', False)

        # Find out if coloured output is enabled. We allow both colour and color spellings
        c = config.GlobalConfig()
        colour = c.get_user_option('colour') or c.get_user_option('color')
        if colour is None:
            colour = False
        else:
            # In lieu of a clever way of obtaining a boolean from config direct, a little parsing...
            colour = re.match('^(true|1|on)$', colour, re.IGNORECASE) is not None

        # Check for a no-color option and remove it from the argument list so that vanilla diff
        # doesn't get upset about it
        if kwargs.pop('no_color', False) == True:
            colour = False

        retval, diff_output = self._run_diff_wrapped(
            wrap_stdout=(stat or stat_dir), *args, **kwargs)

        if stat or stat_dir:
            from diffstat import DiffStat

            diff_output.seek(0)

            diffstat_output = str(DiffStat(diff_output.readlines(), stat_dir, colour=colour))

            if diffstat_output:
                print diffstat_output

        return retval


class cmd_diffstat(cmd_diff):
    """diffstat - show stats about changes to the working tree"""
    takes_args = ['file*']
    takes_options = ['revision', 'change', Option('dir-only',  help='Only list directories'),
                     Option('no-color',  help='Force colored output to be off'),]
    aliases = ['ds']
    def run(self, revision=None, dir_only=False, file_list=None, no_color=False):
        return cmd_diff().run(file_list=file_list, stat=True, stat_dir=dir_only,
                              revision=revision, no_color=no_color)



register_command(cmd_diffstat)
diff_class = register_command(cmd_diff, decorate=True)

try:
    from bzrlib.plugins import qbzr
except ImportError:
    qbzr = None

if qbzr is not None:
    plugin_cmds.register_lazy('cmd_qdiffstat', [],
                              'bzrlib.plugins.diffstat.qdiffstat')

def test_suite():
    import tests
    return tests.test_suite()
