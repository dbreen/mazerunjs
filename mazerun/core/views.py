from mazerun.utils.decorators import render_to


@render_to('core/home.html')
def home(request):
    return {}
