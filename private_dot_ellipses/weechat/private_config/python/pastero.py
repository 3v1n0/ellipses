# -*- coding: utf-8 -*-

# Copyright © 2015 Lucas Jiménez
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

# History:
# 2015-10-21, Lucas Jiménez
#     Version 0.5: Clipboard feature added and linux support
# 2015-10-19, Lucas Jiménez
#     Version 0.4: Added --cmd and use hook_process_hashtable
# 2015-10-05, Lucas Jiménez
#     Version 0.3: Change paste provider
# 2015-10-05, Lucas Jiménez
#     Version 0.2: Code complety rewritten :)
# 2015-09-25, Lucas Jiménez
#     Version 0.1: Initial release

# TODO:
# - Better language identifier. With a tuple with the most used languages
# - As of now the script is a little dangerous because it allows user entry
# - Hability to delete a URL, maybe with a list with the URL's
# - Allow to use 'passworded' uploads

SCRIPT_NAME    = 'pastero'
SCRIPT_AUTHOR  = 'Lucas Jiménez'
SCRIPT_VERSION = '0.5'
SCRIPT_LICENSE = 'MIT'
SCRIPT_DESC    = 'Upload snippets, text files, etc and return the URL'

PREFIX = '[pastero]'

SCRIPT_HELP = '''Help
This script will do its best to automatically identify the language of the file.
If the file doesn't have a file extension, then plain text is used.\n
Usage
To upload a file do:
/pastero <wherever_your_file_is>
*** eg: /pastero ~/Documents/Scripts/my_script.py
To run a command and upload the output do:
/pastero --cmd command
*** eg: /pastero --cmd echo 'Hello, world' # Please be careful with this option.
To upload the content of your clipboard do:
/pastero --clip
'''

import_ok = True

try:
    import weechat as w
    WEECHAT_RC_OK = w.WEECHAT_RC_OK

except ImportError:
    print 'This script must be run under WeeChat.'
    print 'Get WeeChat now at: http://www.weechat.org/'
    import_ok = False

import sys
from subprocess import Popen, PIPE

url = 'https://ptpb.pw/'

if 'linux' in sys.platform or 'bsd' in sys.platform:
    system_clip = 'xclip', '-o'
elif sys.platform == 'darwin':
    system_clip = 'pbpaste'


def f_input(file_in):
    w.hook_process_hashtable('url:'+url,
                             {'postfields':'c='+file_in},
                             5 * 1000, 'printer_cb', '')

# Gets the system clipboard
def get_clip_cmd():
    p = Popen(system_clip, stdout=PIPE)
    data = p.communicate()
    output = str(data[0])
    return output


def pastero_cmd_cb(data, buffer, args):
    global Ext
    command = 'curl -sSF c=@- ' + url

    if args.count('.') > 0:
        Ext = args.split('.')
        Ext.reverse()
    else:
        Ext = ' ' # Ugly hack so Ext[0] doesn't complain in case is empty :>

    if args != '':
        sargs = args.split()

        if sargs[0] == '--clip':
            f_input(get_clip_cmd().strip())

        elif sargs[0] == '--cmd':
            if len(sargs) == 1:
                w.prnt(w.current_buffer(),
                       '%s\tPlease specify a command to run.' % PREFIX)
            else:
                sargs = ' '.join(sargs[1:])
                command = ' '.join((sargs, '|', command))
                w.hook_process_hashtable('sh',
                                         {'arg1':'-c',
                                          'arg2':command},
                                         5 * 1000, 'printer_cb', '')
        else:
            f_input(open(sargs[0], 'r').read())
    else:
        w.prnt(w.current_buffer(),
                     '%s\tPlease, specify a file to upload.' % PREFIX)

    return WEECHAT_RC_OK


def printer_cb(data, command, return_code, out, err):
    if return_code == w.WEECHAT_HOOK_PROCESS_ERROR:
        w.prnt('', 'Error with command %s in printer_cb' % command)
        return WEECHAT_RC_OK

    if out != '':
        url = out.splitlines()
        string = 'Here is the ' + url[4].rstrip() + '/' + Ext[0]
        w.command(w.current_buffer(), string)

    if err != '':
        w.prnt('', 'stderr in function printer_cb: %s' % err)

    return WEECHAT_RC_OK


if __name__ == '__main__' and import_ok:
    if w.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE,
                  SCRIPT_DESC, '', ''):
        
        w.hook_command(SCRIPT_NAME, SCRIPT_DESC, '',SCRIPT_HELP,
                             '', 'pastero_cmd_cb', '')
