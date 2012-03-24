from django.conf.urls.defaults import *
from django.conf import settings


urlpatterns = patterns('mazerun.core.views',
    url(r'^$', 'home', name='home'),
)


#############################################################################
## Admin, static, and auth patterns
#############################################################################

from django.contrib import admin
admin.autodiscover()
urlpatterns += patterns('',
    url(r'^djadmin/', include(admin.site.urls)),
)

if settings.DEBUG:
    urlpatterns += patterns('',
        (r'^media/(?P<path>.*)$', 'django.views.static.serve',
         {'document_root': settings.MEDIA_ROOT}),
    )

#--- Authentication URLs
urlpatterns += patterns('django.contrib.auth.views',
    url(r'^login/$', 'login', name='login'),
    url(r'^logout/$', 'logout_then_login', name='logout'),
    url(r'^accounts/password/change/$', 'password_change', name='auth_password_change'),
    url(r'^password_change/done/$', 'password_change_done', name='auth_password_change_done'),
    url(r'^accounts/password/reset/$', 'password_reset', name='auth_password_reset'),
    url(r'^accounts/password/reset/confirm/(?P<uidb36>[0-9A-Za-z]+)-(?P<token>.+)/$', 'password_reset_confirm', name='auth_password_reset_confirm'),
    url(r'^accounts/password/reset/complete/$', 'password_reset_complete', name='auth_password_reset_complete'),
    url(r'^accounts/password/reset/done/$', 'password_reset_done', name='auth_password_reset_done'),
)
