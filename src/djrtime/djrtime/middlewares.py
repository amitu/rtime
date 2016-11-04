from __future__ import absolute_import, unicode_literals

import json
import logging
import socket
import time
import types

from django.core.serializers.json import DjangoJSONEncoder

import rtime.utils as rtime_utils
import snappy

from .conf import settings

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def get_request_name(request):
    if not hasattr(request, 'view'):
        if request.resolver_match:
            resolver_match = request.resolver_match
            url_name = ':'.join(
                resolver_match.namespaces + [resolver_match.url_name or '']
            )
            view = resolver_match.func
            if isinstance(view, types.FunctionType):  # FBV
                view_name = view.__name__
            else:  # CBV
                view_name = view.__class__.__name__ + '.__call__'
            request.view = '{}{}'.format(
                '.'.join((view.__module__, view_name)),
                '({})'.format(url_name) if url_name else '',
            )
        else:
            request.view = request.path_info

    return request.view


class TimeItMiddleware(object):
    def process_request(self, request):
        request._timeit_start = time.time()
        rtime_utils.init()

    def process_response(self, request, response):
        if hasattr(request, '_timeit_start'):
            try:
                ns = 1000 * 1000 * 1000 * (time.time() - request._timeit_start)
                elapsed = int(round(ns))
                rtime_utils.add_session_data(time_taken=elapsed)
                rtime_utils.set_name(get_request_name(request))
                data = rtime_utils.stop(send=False)
                # import pprint
                # pprint.pprint(data)
                self.send(
                    host=settings.RTIME_HOST,
                    app=settings.RTIME_APP,
                    name=data['name'],
                    otime=data['time_taken'],
                    data=data.get('stack', {}),
                )
            except:
                logger.error('Exception in TimeItMiddleware', exc_info=True)
        return response

    @staticmethod
    def send(**msg):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        data = json.dumps(msg, cls=DjangoJSONEncoder, default=lambda x: str(x))
        sock.sendto(snappy.compress(data), settings.RTIME_ADDRESS)
        logger.debug('data sent to {}'.format(settings.RTIME_ADDRESS))
