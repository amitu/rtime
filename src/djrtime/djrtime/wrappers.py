from functools import wraps

from django.utils.decorators import available_attrs

from rtime.utils import add_frame_data


def request_wrapper(meth):
    @wraps(meth, assigned=available_attrs(meth))
    def process_request(request):
        res = meth(request)
        if res is not None:
            m_class = meth.__self__.__class__
            request.view = '{}.{}.process_request'.format(
                m_class.__module__, m_class.__name__
            )
        return res
    return process_request


def view_wrapper(meth):
    @wraps(meth, assigned=available_attrs(meth))
    def process_view(request, *args, **kwargs):
        res = meth(request, *args, **kwargs)
        if res is not None:
            m_class = meth.__self__.__class__
            request.view = '{}.{}.process_view'.format(
                m_class.__module__, m_class.__name__
            )
        return res
    return process_view


def exception_wrapper(meth):
    @wraps(meth, assigned=available_attrs(meth))
    def process_exception(request, exception):
        res = meth(request, exception)
        if res is not None:
            m_class = meth.__self__.__class__
            request.view = '{}.{}.process_exception'.format(
                m_class.__module__, m_class.__name__
            )
        return res
    return process_exception


def template_response_wrapper(meth):
    @wraps(meth, assigned=available_attrs(meth))
    def process_template_response(request, response):
        current_status = response.status_code
        res = meth(request, response)
        if res is not None:
            if current_status != res.status_code:
                m_class = meth.__self__.__class__
                request.view = '{}.{}.process_template_response'.format(
                    m_class.__module__, m_class.__name__
                )
        return res
    return process_template_response


def response_wrapper(meth):
    @wraps(meth, assigned=available_attrs(meth))
    def process_response(request, response):
        current_status = response.status_code
        res = meth(request, response)
        if res is not None:
            if current_status != res.status_code:
                m_class = meth.__self__.__class__
                request.view = '{}.{}.process_response'.format(
                    m_class.__module__, m_class.__name__
                )
        return res
    return process_response


def execute(self, sql, params=None):
    add_frame_data(query=sql, query_params=params)
    return self._execute(sql, params)
