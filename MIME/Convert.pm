# Convert.pm
# Convert one MIME type into another
# (c) 2002-2009 Reuben Thomas (rrt@sc3d.org, http://rrt.sc3d.org/)
# Distributed under the GNU General Public License version 3, or (at
# your option) any later version.

# FIXME: Have another script, or a flag to cv, that can test for the
# existence of a particular converter

# FIXME: Implement chained converters using transitive closure

# FIXME: Implement many-to-many converters using convert and pacpl.

# TODO: extend Convert.pm to a program with many MIME type
# conversions. Can also think about systematic transformations such as
# cropping and scaling pictures, or downsampling sound. Should be
# provided by different programs, one for each of a limited set of
# canonical types, which can be converted to from any other type of
# the same sort.

require 5.8.4;
package MIME::Convert;

use utf8;
use strict;
use warnings;

use Perl6::Slurp;
use File::Slurp; # for write_file
use File::Basename;
use File::Temp qw(tempdir);
use CGI qw(:standard);
use Encode;

use lib ".";
use RRT::Misc;
use RRT::Macro;

use vars qw(%Converters);


# Identity function for null transformers
sub renderId {
  my ($file) = @_;
  return scalar(slurp '<:raw', $file);
}

# Use highlight to convert source code to HTML
sub highlight {
  my ($file, $page, $baseurl, $srctype, $desttype) = @_;
  my $tempdir = tempdir(CLEANUP => 1);
  my $css_file = "$tempdir/highlight.css";
  my $syntax = $srctype;
  $syntax =~ s|text/x-||;
  $syntax = "sh" if $syntax eq "shellscript"; # FIXME: Formalise this
  open(READER, "-|", "highlight", $file, "-c", $css_file, "-S", $syntax);
  my $html = scalar(slurp '<:raw', \*READER);
  my $css = slurp '<:raw', $css_file;
  $html =~ s|(<body[^>]*>)|"$1<style type=\"text/css\">$css</style>"|e;
  return $html;
}

%Converters =
  (
   # FIXME: Should have a rule for this
   #"text/plain>text/html" => ,

   # Treat empty files as text
   # FIXME: make this application/x-empty>*
   "application/x-empty>text/html" => \&renderId,

   # Types trivially transformable
   "text/x-mail>text/plain" => \&renderId,
   "text/x-news>text/plain" => \&renderId,
   "text/x-readme>text/plain" => \&renderId,

   # FIXME: Reuse (and expand) this list of programming languages
   "text/x-c>text/plain" => \&renderId,
   "text/x-c++>text/plain" => \&renderId,
   "text/x-fortran>text/plain" => \&renderId,
   "text/x-makefile>text/plain" => \&renderId,
   "text/x-pl1>text/plain" => \&renderId,
   "text/x-asm>text/plain" => \&renderId,
   "text/x-pascal>text/plain" => \&renderId,
   "text/x-java>text/plain" => \&renderId,
   "text/x-bcpl>text/plain" => \&renderId,
   "text/x-m4>text/plain" => \&renderId,
   "text/x-po>text/plain" => \&renderId,
   "text/x-perl>text/plain" => \&renderId,
   "text/x-python>text/plain" => \&renderId,
   "text/x-ruby>text/plain" => \&renderId,
   "text/x-shellscript>text/plain" => \&renderId,

   # Programming languages to HTML with highlight
   "text/x-c>text/html" => \&highlight,
   "text/x-c++>text/html" => \&highlight,
   "text/x-fortran>text/html" => \&highlight,
   "text/x-makefile>text/html" => \&highlight,
   "text/x-pl1>text/html" => \&highlight,
   "text/x-asm>text/html" => \&highlight,
   "text/x-pascal>text/html" => \&highlight,
   "text/x-java>text/html" => \&highlight,
   "text/x-bcpl>text/html" => \&highlight,
   "text/x-m4>text/html" => \&highlight,
   "text/x-po>text/html" => \&highlight,
   "text/x-perl>text/html" => \&highlight,
   "text/x-python>text/html" => \&highlight,
   "text/x-ruby>text/html" => \&highlight,
   "text/x-shellscript>text/html" => \&highlight,

   "text/x-tex>text/html" => sub {
     my ($file, $page, $baseurl) = @_;
     my $tempdir = tempdir(CLEANUP => 1);
     # FIXME: Customization of LaTeX env. vars should be moved into web.pl
     system "env BIBINPUTS=\"" . dirname($file) . ":$ENV{HOME}/texmf/bibtex\" TEXINPUTS=\"$tempdir:/home/rrt/texmf/tex/latex//:" . dirname($file) . ":\" TEXMFOUTPUT=\"$tempdir\" LOG=\"$tempdir/latex-mk.log\" latex-mk --pdflatex \"$file\" > \"$tempdir/log\"";
#     return ("", scalar(slurp "$tempdir/log")); # useful for debugging
     # FIXME: Move customization of special HeVeA files into web.pl
     system "cd \"$tempdir\"; hevea -fix -I \"$ENV{HOME}/texmf/hevea\" -I \"" . dirname($file) . "\" sym.hva latex2html.hva local.hva -o \"$tempdir/tmp.html\" \"$file\" >> \"$tempdir/log\"";
     my $text = scalar(slurp '<:raw', "$tempdir/tmp.html");
     my $encoding = getMimeEncoding("$tempdir/tmp.html");
     # FIXME: Convert from actual encoding
     $text = decode("iso-8859-1", $text) if $encoding ne "utf-8";
     # Workaround for poems: if no H1, extract title element (if
     # there's a real one, not just the filename) and reinject as H1
     if ($text !~ m|<H1[^>]*>|i) {
       $text =~ m|<TITLE[^>]*>(.*)</TITLE>|sm;
       my $title = $1;
       $text =~ s|(<BODY[^>]*>)|"$1<H1>$title</H1>"|e
         if $title !~ m|/tmp|;
     }
     # FIXME: Move text below into files that can be internationalised
     # FIXME: download links should be generated in convert's caller,
     # according to list of possible methods. Then get rid of $page
     # and $baseurl, and add page count using pdfpages macro.
     my $download = a({-href => "$baseurl$page?convert=application/pdf"}, "Download PDF");
     return ($text, $download);
   },

   "text/x-tex>application/pdf" => sub {
     my ($file) = @_;
     $file =~ s/\.tex$//;
     my $tempdir = tempdir(CLEANUP => 1);
     system "env BIBINPUTS=\"" . dirname($file) . ":$ENV{HOME}/texmf/bibtex\" TEXINPUTS=\"$tempdir:/home/rrt/texmf/tex/latex//:" . dirname($file) . ":\" TEXMFOUTPUT=\"$tempdir\" LOG=\"$tempdir/latex-mk.log\" latex-mk --pdflatex \"$file\" > \"$tempdir/log\"";
#     return scalar(slurp "$tempdir/log"); # useful for debugging
     return scalar(slurp '<:raw', "$tempdir/" . basename($file) . ".pdf");
   },

   # Rewrite with temporary file
   # "application/pdf>application/postscript" => sub {
   #   my ($file) = @_;
   #   return pipe2("pdf2ps", scalar(slurp '<:raw', $file), "", "", "-", "-");
   # },

   "application/x-dvi>application/postscript" => sub {
     my ($file) = @_;
     if ($file eq "-") { # Standard input can't be a pipe for dvips
       my $tempdir = tempdir(CLEANUP => 1);
       $file = "$tempdir/tmp.dvi";
       write_file($file, {binmode => 'raw'}, scalar(slurp '<:raw', \*STDIN));
     }
     open(READER, "-|", "dvips -f < \"$file\"");
     return scalar(slurp '<:raw', \*READER);
   },

   "image/x-epoc-sketch>image/png" => sub {
     my ($file) = @_;
     if ($file eq "-") {
       open(READER, "-|", "psiconv", "--type=PNG");
     } else {
       open(READER, "-|", "psiconv", "--type=PNG", $file);
     }
     return scalar(slurp '<:raw', \*READER);
   },

   "image/x-epoc-sketch>image/jpeg" => sub {
     my ($file) = @_;
     if ($file eq "-") {
       open(READER, "-|", "psiconv", "--type=JPEG");
     } else {
       open(READER, "-|", "psiconv", "--type=JPEG", $file);
     }
     return scalar(slurp '<:raw', \*READER);
   },

   # FIXME: generalise the function to arbitrary audio types, using
   # using File::MimeInfo::extensions()
   "audio/x-flac>audio/mpeg" => sub {
     my ($file) = @_;
     my $tempdir = tempdir(CLEANUP => 1);
     my $tempfile = "$tempdir/tmp.mp3";
     system "pacpl", "--flactomp3", "--file=\"$file\"", "--file=\"$tempfile\"";
     return scalar(slurp '<:raw', $tempfile);
   },
  );


sub convert {
  my ($file, $srctype, $desttype, $page, $baseurl) = @_;
  #print STDERR $file, " ", $srctype, " ", $desttype, " ", defined($Converters{"$srctype>$desttype"}), "\n";
  $srctype ||= "application/octet-stream";
  $desttype ||= "application/octet-stream";
  return scalar(slurp '<:raw', $file) if $srctype eq $desttype;
  return "" if ($file ne "-" && !-e $file) || !defined($Converters{"$srctype>$desttype"});
  return $Converters{"$srctype>$desttype"}($file, $page, $baseurl, $srctype, $desttype);
}


1;                              # return a true value
