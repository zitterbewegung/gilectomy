#! /bin/sh

#  Script to push docs from my development area to SourceForge, where the
#  update-docs.sh script unpacks them into their final destination.

TARGETHOST=www.python.org
TARGETDIR=/usr/home/fdrake/tmp

PKGTYPE="bzip"  # must be one of: bzip, tar, zip  ("tar" implies gzip)

TARGET="$TARGETHOST:$TARGETDIR"

ADDRESSES='python-dev@python.org doc-sig@python.org python-list@python.org'

TOOLDIR="`dirname $0`"
VERSION=`$TOOLDIR/getversioninfo`

# Set $EXTRA to something non-empty if this is a non-trunk version:
EXTRA=`echo "$VERSION" | sed 's/^[0-9][0-9]*\.[0-9][0-9]*//'`

if echo "$EXTRA" | grep -q '[.]' ; then
    DOCLABEL="maintenance"
    DOCTYPE="maint"
else
    DOCLABEL="development"
    DOCTYPE="devel"
fi

EXPLANATION=''
ANNOUNCE=true

# XXX Should use getopt(1) here.
while [ "$#" -gt 0 ] ; do
  case "$1" in
      -m)
          EXPLANATION="$2"
          shift 2
          ;;
      -p)
          PKGTYPE="$2"
          shift 1
          ;;
      -q)
          ANNOUNCE=false
          shift 1
          ;;
      -t)
          DOCTYPE="$2"
          shift 2
          ;;
      -F)
          EXPLANATION="`cat $2`"
          shift 2
          ;;
      -*)
          echo "Unknown option: $1" >&2
          exit 2
          ;;
      *)
          break
          ;;
  esac
done
if [ "$1" ] ; then
    if [ "$EXPLANATION" ] ; then
        echo "Explanation may only be given once!" >&2
        exit 2
    fi
    EXPLANATION="$1"
    shift
fi

START="`pwd`"
MYDIR="`dirname $0`"
cd "$MYDIR"
MYDIR="`pwd`"

if [ "$PKGTYPE" = bzip ] ; then
    PKGEXT=tar.bz2
elif [ "$PKGTYPE" = tar ] ; then
    PKGEXT=tgz
elif [ "$PKGTYPE" = zip ] ; then
    PKGEXT=zip
else
    echo 1>&2 "unsupported package type: $PKGTYPE"
    exit 2
fi

cd ..

# now in .../Doc/
make --no-print-directory ${PKGTYPE}html || exit $?
PACKAGE="html-$VERSION.$PKGEXT"
scp "$PACKAGE" tools/update-docs.sh $TARGET/ || exit $?
ssh "$TARGETHOST" tmp/update-docs.sh $DOCTYPE $PACKAGE '&&' rm tmp/update-docs.sh || exit $?

if $ANNOUNCE ; then
    sendmail $ADDRESSES <<EOF
To: $ADDRESSES
From: "Fred L. Drake" <fdrake@acm.org>
Subject: [$DOCLABEL doc updates]
X-No-Archive: yes

The $DOCLABEL version of the documentation has been updated:

    http://$TARGETHOST/dev/doc/$DOCTYPE/

$EXPLANATION

A downloadable package containing the HTML is also available:

    http://$TARGETHOST/dev/doc/python-docs-$DOCTYPE.$PKGEXT
EOF
    exit $?
fi
