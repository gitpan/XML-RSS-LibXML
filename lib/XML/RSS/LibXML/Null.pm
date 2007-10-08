# $Id: /mirror/perl/XML-RSS-LibXML/trunk/lib/XML/RSS/LibXML/Null.pm 2259 2007-05-07T14:41:59.593216Z daisuke  $
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::Null;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::ImplBase);

sub definition { +{} }

1;
