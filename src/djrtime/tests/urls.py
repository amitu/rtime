from django.conf.urls import url
from django.contrib import admin
from django.http import HttpResponse


def test_view(request):
    return HttpResponse('response')

urlpatterns = [
    url('^$', view=test_view, name='homepage'),
    url('^random/$', view=test_view),
    url('^admin/', admin.site.urls),
]
