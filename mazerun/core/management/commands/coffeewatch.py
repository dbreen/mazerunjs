import os
import time
import sys

from django.conf import settings
from django.core.management.base import BaseCommand


COFFEE_DIR = os.path.join(settings.PROJECT_ROOT, 'coffee')
BUILD_DIR = os.path.join(settings.PROJECT_ROOT, '..', 'coffeebuild')
OUTPUT_DIR = os.path.join(settings.PROJECT_ROOT, 'media', 'js')
OUTPUT_JS = os.path.join(OUTPUT_DIR, 'mazerun.js')
SLEEP = 2

class Command(BaseCommand):
    def handle(self, *args, **options):
        try:
            while True:
                self.watchfiles()
                time.sleep(SLEEP)
        except KeyboardInterrupt:
            sys.exit(0)

    def watchfiles(self):
        try:
            lastmod = os.path.getmtime(OUTPUT_JS)
        except OSError:
            print "No js file yet, generate it"
            lastmod = 0
        files = [file for file in os.listdir(COFFEE_DIR) if file.endswith('.coffee')]
        if any(os.path.getmtime(os.path.join(COFFEE_DIR, file)) > lastmod for file in files):
            self.compilefiles(files)

    def compilefiles(self, files):
        print "Changes detected; joining %d coffee files" % len(files)
        out = open(os.path.join(BUILD_DIR, 'mazerun.coffee'), 'w')
        for file in files:
            out.write(open(os.path.join(COFFEE_DIR, file)).read())
        out.close()
        os.system('coffee.bat --compile --output %s %s/mazerun.coffee' % (OUTPUT_DIR, BUILD_DIR))
        print "JS generated: %s" % OUTPUT_JS
