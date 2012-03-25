from django.http import HttpResponse
from mazerun.utils.decorators import render_to


@render_to('core/home.html')
def home(request):
    return {}

def download_source(request):
    response = HttpResponse(open('coffeebuild/mazerun.coffee'), mimetype='text/coffeescript')
    response['Content-Disposition'] = 'attachment; filename=mazerun.coffee'
    return response
