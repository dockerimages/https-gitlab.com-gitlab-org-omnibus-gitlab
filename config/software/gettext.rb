# Copyright:: Copyright (c) 2019 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

name 'gettext'

default_version '0.19.8.1'

version '0.19.8.1' do
  source md5: '97e034cf8ce5ba73a28ff6c3c0638092'
end

# using a git checkout would invoke the need to also clone gnulib, which is
# messy
source url: "https://ftp.gnu.org/pub/gnu/gettext/gettext-#{version}.tar.gz"

relative_path "gettext-#{version}"

dependency 'libiconv'
dependency 'ncurses'
dependency 'libxml2'
dependency 'bzip2'
dependency 'liblzma'
dependency 'ncurses'

license 'GPL v3'
license_file 'COPYING'

skip_transitive_dependency_licensing true

build do
    env = with_standard_compiler_flags(with_embedded_path)

# From dce3a16e5e9368245735e29bf498dcd5e3e474a4 Mon Sep 17 00:00:00 2001
# From: Daiki Ueno <ueno@gnu.org>
# Date: Thu, 15 Sep 2016 13:57:24 +0200
# Subject: [PATCH] xgettext: Fix crash with *.po file input
# 
# When xgettext was given two *.po files with the same msgid_plural, it
# crashed with double-free.  Problem reported by Davlet Panech in:
# http://lists.gnu.org/archive/html/bug-gettext/2016-09/msg00001.html
# * gettext-tools/src/po-gram-gen.y: Don't free msgid_pluralform after
# calling do_callback_message, assuming that it takes ownership.
# * gettext-tools/src/read-catalog.c (default_add_message): Free
# msgid_plural after calling message_alloc.
# * gettext-tools/tests/xgettext-po-2: New file.
# * gettext-tools/tests/Makefile.am (TESTS): Add new test.
# ---
#  gettext-tools/src/po-gram-gen.y   | 13 +++-----
#  gettext-tools/src/read-catalog.c  |  2 ++
#  gettext-tools/tests/Makefile.am   |  2 +-
#  gettext-tools/tests/xgettext-po-2 | 55 +++++++++++++++++++++++++++++++
#  4 files changed, 63 insertions(+), 9 deletions(-)
#  create mode 100755 gettext-tools/tests/xgettext-po-2
    patch source: '01-CVE-2018-18751.patch', env: env
    patch source: '02-CVE-2018-18751.patch', env: env
    patch source: '03-CVE-2018-18751.patch', env: env
    patch source: '04-CVE-2018-18751.patch', env: env

    command ['./configure',
             "--with-libiconv-prefix=#{install_dir}/embedded",
             "--with-ncurses-prefix=#{install_dir}/embedded",
             "--with-libxml2-prefix==#{install_dir}/embedded",
             "--prefix=#{install_dir}/embedded"].join(' '), env: env 
    make env: env
    make "install", env: env
end
