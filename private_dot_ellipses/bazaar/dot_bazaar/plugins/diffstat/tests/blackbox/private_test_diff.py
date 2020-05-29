"""Black-box tests for the options added to the diff command.
"""

import os
import re
import time

import bzrlib

from bzrlib.tests.blackbox.test_diff import DiffBase

file_parser = re.compile(r'^\ [^| ]+\ +\|\ ([0-9]+)\ (\+*)(-*)$',
                         re.MULTILINE | re.VERBOSE)
summary_parser = re.compile(r'^\ ([0-9]+)\ (files?|director(?:ies|y))\ changed,\ ([0-9]+)\ insertions?\(\+\),\ ([0-9]+)\ deletions?\(-\)$'
                            r'|^\ 0\ files\ changed$',
                           re.MULTILINE | re.VERBOSE)

# Extend the core DiffBase to get the test branch initialisation for free
class DiffStatBase(DiffBase):
    def check_output_rules(self, output):
        """Perform some tests that all output from the plugin must always comply with"""
        if output == '':
            # No output is valid
            return

        # Parse the output and extract some useful information that we can check
        #print "Checking ->%s<-" % (output)
        file_matches    = file_parser.findall(output)
        file_line_count = len(file_matches)

        summary_match    = summary_parser.search(output)
        summary_files    = int(summary_match.group(1) or 0)
        summary_noun     = summary_match.group(2)
        summary_adds     = int(summary_match.group(3) or 0)
        summary_removes  = int(summary_match.group(4) or 0)
        summary_all      = summary_adds + summary_removes

        self.assertEquals(file_line_count, summary_files)
        self.assertEquals(summary_all, sum([int(x[0]) for x in file_matches]))


class TestDiffWithStat(DiffStatBase):
    """Test diff --stat"""

    def test_clean_tree(self):
        """diff --stat on a tree with committed files but no differences"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff --stat', retcode=0)[0]
        self.assertEquals(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_empty_tree(self):
        """diff --stat on a tree with nothing in it at all"""
        tree = self.make_branch_and_tree('.')
        output = self.run_bzr('diff --stat', retcode=0)[0]
        self.assertEquals(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_add_line(self):
        """diff --stat on a tree with just one added line"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz\nbaz2\n')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 1 +
 1 file changed, 1 insertion(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_add_line_double_plus(self):
        """diff --stat on a tree with the line '++' added"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz\n++\n')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output, '''\
 goodbye | 1 +
 1 file changed, 1 insertion(+), 0 deletions(-)
''')

    def test_remove_line(self):
        """diff --stat on a tree with just one removed line"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', '')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 1 -
 1 file changed, 0 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_remove_line_double_minus(self):
        """diff --stat on a tree with the line '--' removed"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz\n--\n')])
        tree.commit('modified')
        self.build_tree_contents([
            ('goodbye', 'baz\n')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output, '''\
 goodbye | 1 -
 1 file changed, 0 insertions(+), 1 deletion(-)
''')

    def test_change_line(self):
        """diff --stat on a tree with one line in one file changed"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_change_two_files(self):
        """diff --stat on a tree with changes in two files"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n'),
            ('hello',  'foo2\n\n')])
        output = self.run_bzr('diff --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 2 +-
 hello   | 3 ++-
 2 files changed, 3 insertions(+), 2 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_against_identical_revision(self):
        """diff --stat on a tree agains an idential prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n')])
        tree.commit('modified')
        # Now put it back the way it was
        self.build_tree_contents([
            ('goodbye', 'baz\n')])
        output = self.run_bzr('diff --stat -r 2', retcode=0)[0]
        self.assertEqualDiff(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_tree_against_different_revision(self):
        """diff --stat on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n\n')])
        tree.commit('modified')
        output = self.run_bzr('diff -r 1 --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 2 ++
 1 file changed, 2 insertions(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_between_consecutive_revisions(self):
        """diff --stat on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff -r 1..2 --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 1 +
 1 file changed, 1 insertion(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_between_consecutive_revisions_reversed(self):
        """diff --stat on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff -r 2..1 --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 1 -
 1 file changed, 0 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_tree_between_nonadjacent_revisions(self):
        """diff --stat on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n\n\n')])
        tree.commit('modified')
        output = self.run_bzr('diff -r 1..3 --stat', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 goodbye | 3 +++
 1 file changed, 3 insertions(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_specific_file(self):
        """diff --stat on a tree with two changes but specifying one"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n'),
            ('hello',  'foo2\n\n')])
        output = self.run_bzr('diff --stat hello', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 hello | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)


class TestDiffWithStatDir(DiffStatBase):
    """Test diff --stat-dir"""

    def test_clean_tree(self):
        """diff --stat-dir on a tree with committed files but no differences"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff --stat-dir', retcode=0)[0]
        self.assertEquals(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_empty_tree(self):
        """diff --stat-dir on a tree with nothing in it at all"""
        tree = self.make_branch_and_tree('.')
        output = self.run_bzr('diff --stat-dir', retcode=0)[0]
        self.assertEquals(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_add_line(self):
        """diff --stat-dir on a tree with just one added line"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz\nbaz2\n')])
        output = self.run_bzr('diff --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 1 +
 1 directory changed, 1 insertion(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_remove_line(self):
        """diff --stat-dir on a tree with just one removed line"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', '')])
        output = self.run_bzr('diff --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 1 -
 1 directory changed, 0 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_change_line(self):
        """diff --stat-dir on a tree with one line in one file changed"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n')])
        output = self.run_bzr('diff --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 2 +-
 1 directory changed, 1 insertion(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_change_two_files(self):
        """diff --stat-dir on a tree with changes in two files"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n'),
            ('hello',  'foo2\n\n')])
        output = self.run_bzr('diff --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 5 +++--
 1 directory changed, 3 insertions(+), 2 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_against_identical_revision(self):
        """diff --stat-dir on a tree agains an idential prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n')])
        tree.commit('modified')
        # Now put it back the way it was
        self.build_tree_contents([
            ('goodbye', 'baz\n')])
        output = self.run_bzr('diff --stat-dir -r 2', retcode=0)[0]
        self.assertEqualDiff(output,  ' 0 files changed\n')
        self.check_output_rules(output)

    def test_tree_against_different_revision(self):
        """diff --stat-dir on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n\n')])
        tree.commit('modified')
        output = self.run_bzr('diff -r 1 --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 2 ++
 1 directory changed, 2 insertions(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_between_consecutive_revisions(self):
        """diff --stat-dir on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff -r 1..2 --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 1 +
 1 directory changed, 1 insertion(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_tree_between_consecutive_revisions_reversed(self):
        """diff --stat-dir on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        output = self.run_bzr('diff -r 2..1 --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 1 -
 1 directory changed, 0 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)

    def test_tree_between_nonadjacent_revisions(self):
        """diff --stat-dir on a tree agains a different prior revision"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n\n\n')])
        tree.commit('modified')
        output = self.run_bzr('diff -r 1..3 --stat-dir', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 3 +++
 1 directory changed, 3 insertions(+), 0 deletions(-)
''')
        self.check_output_rules(output)

    def test_specific_file(self):
        """diff --stat-dir on a tree with two changes but specifying one"""
        tree = self.make_example_branch()
        self.build_tree_contents([
            ('goodbye', 'baz2\n'),
            ('hello',  'foo2\n\n')])
        output = self.run_bzr('diff --stat-dir hello', retcode=1)[0]
        self.assertEqualDiff(output,  '''\
 . | 3 ++-
 1 directory changed, 2 insertions(+), 1 deletion(-)
''')
        self.check_output_rules(output)


