#!/usr/bin/python
#
# Install script for tengis.
#

from distutils.core import setup

setup(name="curator",
      version="2.1",
      description="Templateable Image Gallery Generator.",
      long_description="""
Curator is a powerful script that allows one to generate Web page image
galleries with the intent of displaying photographic images on the Web, or for a
CD-ROM presentation and archiving.

It generates static Web pages only - no special configuration or running scripts
are required on the server. The script supports many file formats, hierarchical
directories, thumbnail generation and update, per-image description file with
any attributes, and 'tracks' of images spanning multiple directories. The
templates consist of HTML with embedded Python. Running this script only
requires a recent Python interpreter and the Python Imaging Library OR the
ImageMagick tools. If you've been looking for a simple yet very powerful script
to do this task you've come to the right place.""",
      license="GNU GPL",
      author="Martin Blais",
      author_email="blais@iro.umontreal.ca",
      url="http://curator.sourceforge.net",
      scripts = ['bin/curator']
     )
