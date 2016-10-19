# -*- coding: utf-8 -*-
from __future__ import division
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import socket
import os
import sys
import json


SERVER = "127.0.0.1"
PORT = 6543


class Message(object):
    def __init__(self, server, app, name, otime, qtime=-1, rtime=-1, data=None):
        self.server = server
        self.app = app
        self.name = name
        self.otime = otime
        self.qtime = qtime
        self.rtime = rtime
        self.data = data if data is not None else {}

    def json(self):
        j = json.dumps(self.__dict__, indent=4, sort_keys=True)
        print("json: ", j)
        return j


def ping():
    msg = Message(
        server = socket.gethostname(),
        app = os.path.basename(__file__),
        name = sys.argv[1],
        otime = sys.argv[2]
    )
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(msg.json(), (SERVER, PORT))


if __name__ == "__main__":
    ping()
