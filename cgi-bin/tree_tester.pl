#!/usr/bin/perl -w

######################################################################
#
# tree_tester.pl is just a bit of code to test Tree::Simple and friends
#
# Copyright (C) 2006 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

require "allowSource.pl";

use lib "/home/barefoot_rob/perlmods/share/perl";   # to use modules installed in my user space
use strict;
use CGI;

use Tree::Simple;
use Tree::Simple::View::DHTML;
use Tree::Simple::Visitor::LoadDirectoryTree;
  
  # create a Tree::Simple object whose
  # node is path to a directory
my $tree = Tree::Simple->new("/home/barefoot_rob/temp.robnugen.com/images");

  # create an instance of our visitor
my $visitor = Tree::Simple::Visitor::LoadDirectoryTree->new();
  
  # set the directory sorting style
$visitor->setSortStyle($visitor->SORT_FILES_FIRST);
  
  # create node filter to filter 
  # out certain files and directories
$visitor->setNodeFilter(sub {
    my ($item) = @_;
    return 0 if $item =~ /CVS/;
    return 1;
});  
  
  # pass the visitor to a Tree::Simple object
$tree->accept($visitor);

my $html_tree = Tree::Simple::View::DHTML->new
    ($tree =>
     ( node_formatter => sub 
       {
	   my ($tree) = @_;
	   if ($tree->isLeaf()) {
	       return "<a href='/cgi-bin/sub.pl?obj=" .
	       $tree -> getNodeValue() . "'>" .
	       $tree -> getNodeValue() . "</a>";
	   } else {
	       return "X</a> " . $tree -> getNodeValue();
	   }
       },
       list_type => "ordered"
#       list_css => "list-style: circle;",
#       list_item_css => "font-family: courier;",
#       expanded_item_css_class => "myExpandedListItemClass",
#       link_css_class => "myListItemLinkClass",
#       radio_button => "tree_id"
       )
     );

  
  # the tree now mirrors the structure of the directory 



my $query = new CGI;


print $query->header, $query->start_html("title");

print $html_tree->javascript();

$html_tree->includeTrunk(1);
print $html_tree->expandPath(("/home/barefoot_rob/temp.robnugen.com/images"));

&allowSource;

print $query->end_html;
