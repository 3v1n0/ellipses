"""A graphical equivalent for the diffstat command."""

from PyQt4 import QtCore, QtGui

from bzrlib.option import Option
from bzrlib.plugins.qbzr.lib.util import (QBzrWindow,
                                          BTN_CLOSE,
                                          runs_in_loading_queue,
                                         )
from bzrlib.plugins.qbzr.lib.uifactory import ui_current_widget
from bzrlib.plugins.qbzr.lib.trace import reports_exception
from bzrlib.plugins.qbzr.lib.commands import QBzrCommand

from bzrlib.plugins.diffstat import cmd_diff
from bzrlib.plugins.diffstat.diffstat import DiffStat


class DiffStatWindow(QBzrWindow):

    def __init__(self, title='Diff Summary', parent=None, ui_mode=True,
                 *args, **kwargs):
        super(DiffStatWindow, self).__init__(title=title, 
                                             parent=parent, 
                                             ui_mode=ui_mode)

        self.diff_args = args
        self.diff_kwargs = kwargs
        self.restoreSize('diffstat', (100, 100))
        self.setSizePolicy(QtGui.QSizePolicy.Minimum, 
                           QtGui.QSizePolicy.Minimum)

        self.layout = QtGui.QVBoxLayout(self.centralwidget)
        
        self.label = QtGui.QLabel('')
        self.layout.addWidget(self.label)

        self.outview = QtGui.QTableWidget()
        self.outview.setSizePolicy(QtGui.QSizePolicy.Minimum, 
                                   QtGui.QSizePolicy.Minimum)
        self.outview.setColumnCount(2)
        self.outview.setShowGrid(False)
        self.outview.setHorizontalHeaderLabels(
            ['File','Changes'])
        self.outview.verticalHeader().hide()
        self.outview.horizontalHeader().setResizeMode(
            0, QtGui.QHeaderView.ResizeToContents)
        self.outview.horizontalHeader().setStretchLastSection(True)
        self.layout.addWidget(self.outview)
        self.layout.setStretchFactor(self.outview, 1)

        buttonbox = self.create_button_box(BTN_CLOSE)
        refresh = buttonbox.addButton(
            'Refresh', QtGui.QDialogButtonBox.ActionRole)
        self.layout.addWidget(buttonbox)

        QtCore.QObject.connect(refresh, 
                               QtCore.SIGNAL("clicked(bool)"),
                               self.do_refresh)

    def show(self):
        QBzrWindow.show(self)
        QtCore.QTimer.singleShot(1, self.initial_load)

    @runs_in_loading_queue
    @ui_current_widget
    @reports_exception()
    def initial_load(self):
        self.do_refresh()
        
    def do_refresh(self):
        stat_dir = self.diff_kwargs.pop('stat_dir', False)
        retval, outstream = cmd_diff()._run_diff_wrapped(wrap_stdout=True,
                                                         *self.diff_args,
                                                         **self.diff_kwargs)
        outstream.seek(0)
        diffstat = DiffStat(outstream.readlines(), stat_dir)
        self.display(diffstat)

    def display(self, diffstat):
        """Display a diffstat object (see bzr-diffstat/diffstat.py)"""
        self.label.setText('%d files changed, %d insertions, %d deletions' %
                           (len(diffstat.stats), 
                            diffstat.total_adds,
                            diffstat.total_removes))
        self.outview.setRowCount(len(diffstat.files))
        for i, file in enumerate(diffstat.files):
            self.outview.insertRow(i)
            self.outview.setItem(i, 0, QtGui.QTableWidgetItem(file))
            self.outview.setItem(i, 1, QtGui.QTableWidgetItem(
                '+'*diffstat.stats[file].adds+'-'*diffstat.stats[file].removes))
        self.outview.resizeRowsToContents()


class cmd_qdiffstat(QBzrCommand):

    """Graphically show stats about changes to the working tree."""

    takes_options = ['revision',
                     'change',
                     Option('dir-only',  help='Only list directories', param_name='stat_dir'),
                    ]

    def _qbzr_run(self, ui_mode=False, *args, **kwargs):
        self.main_window = DiffStatWindow(*args, **kwargs)
        self.main_window.show()
        self._application.exec_()
