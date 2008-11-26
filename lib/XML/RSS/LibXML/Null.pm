# $Id: /mirror/coderepos/lang/perl/XML-RSS-LibXML/trunk/lib/XML/RSS/LibXML/Null.pm 66337 2008-07-17T12:09:29.211352Z daisuke  $
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::Null;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::ImplBase);

sub definition { +{} }

1;
