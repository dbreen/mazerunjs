import os

from django.conf import settings
from django.http import HttpResponse

from mazerun.utils.decorators import render_to


@render_to('core/home.html')
def home(request):
    return {}

@render_to('core/designer.html')
def maze_designer(request, maze_id=None):
    return {}

def download_source(request):
    source = open(os.path.join(settings.PROJECT_ROOT , '..', 'coffeebuild', 'mazerun.coffee'))
    response = HttpResponse(source, mimetype='text/coffeescript')
    response['Content-Disposition'] = 'attachment; filename=mazerun.coffee'
    return response
