from functools import wraps

from django.http import HttpResponse
from django.shortcuts import render_to_response
from django.utils import simplejson
from django.template import RequestContext


def render_to(template=None):
    def renderer(function):
        @wraps(function)
        def wrapper(request, *args, **kwargs):
            output = function(request, *args, **kwargs)
            if not isinstance(output, dict):
                return output
            tmpl = output.pop('TEMPLATE', template)
            return render_to_response(tmpl, output, context_instance=RequestContext(request))
        return wrapper
    return renderer


class JsonResponse(HttpResponse):
    def __init__(self, data):
        super(JsonResponse, self).__init__(content=simplejson.dumps(data), mimetype='application/json')


def ajax_request(func):
    @wraps(func)
    def wrapper(request, *args, **kwargs):
        response = func(request, *args, **kwargs)
        if isinstance(response, dict):
            return JsonResponse(response)
        else:
            return response
    return wrapper
