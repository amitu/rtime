# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function,
                        unicode_literals)

import json
import os
import socket
import sys
import snappy

SERVER = "127.0.0.1"
PORT = 6543


class Message(object):
    def __init__(self, host, app, name, otime, qtime=-1, rtime=-1, data=None):
        self.host = host
        self.app = app
        self.name = name
        self.otime = int(otime)
        self.qtime = int(qtime)
        self.rtime = int(rtime)
        self.data = data if data is not None else {}

    def json(self):
        j = json.dumps(self.__dict__)
        print("json: ", j)
        return j


def ping():
    msg = Message(
        host=socket.gethostname(),
        app=os.path.basename(__file__),
        name=sys.argv[1],
        otime=sys.argv[2]
    )
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(snappy.compress(msg.json()), (SERVER, PORT))


if __name__ == "__main__":
    ping()
