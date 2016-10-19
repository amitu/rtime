from __future__ import absolute_import, unicode_literals

import types

from django.utils.functional import lazy

from rtimeit.utils import TimeIt, logger


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
        request.timeit = TimeIt(lazy(lambda r: get_request_name(r))(request))
        request.timeit.start()

    def process_response(self, request, response):
        if hasattr(request, 'timeit'):
            timeit = request.timeit
            timeit.stop(send=False)
            logger.info(
                '{} took {} ms for method {} to return {} status'.format(
                    timeit.name,
                    timeit.ms,
                    request.method,
                    response.status_code
                )
            )
        return response
