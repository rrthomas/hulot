# Convert.pm
# Convert one MIME type into another
# (c) 2002-2011 Reuben Thomas (rrt@sc3d.org, http://rrt.sc3d.org/)
# Distributed under the GNU General Public License version 3, or (at
# your option) any later version.

# FIXME: Implement chained converters using transitive closure

# FIXME: Implement many-to-many converters using convert and pacpl.

# TODO: Can also think about systematic transformations such as cropping and
# scaling pictures, or downsampling sound. Should be provided by different
# programs, one for each of a limited set of canonical types, which can be
# converted to from any other type of the same sort.

require 5.8.4;
package MIME::Convert;

use utf8;
use strict;
use warnings;

use File::Basename;
use File::Temp qw(tempdir);
use Encode;

use Perl6::Slurp;
use File::Slurp; # for write_file

use RRT::Misc;
use RRT::Macro; # FIXME: Is this still needed?

use vars qw(%Converters);


# Identity function for null transformers
sub renderId {
  my ($file) = @_;
  return scalar(slurp '<:raw', $file);
}

# Use highlight to convert source code to HTML
sub highlight {
  my %mime_to_ext = (
       "text/x-c" => "c",
       "text/x-c++" => "cc",
       "text/x-fortran" => "f",
       "text/x-makefile" => "mak",
       "text/x-pl1" => "pl1",
       "text/x-asm" => "asm",
       "text/x-pascal" => "pas",
       "text/x-java" => "java",
       "text/x-bcpl" => "b",
       "text/x-m4" => "m4",
       "text/x-po" => "po",
       "text/x-perl" => "pl",
       "text/x-python" => "py",
       "text/x-ruby" => "rb",
       "text/x-shellscript" => "sh",
      );
  my ($file, $srctype, $desttype) = @_;
  my $tempdir = tempdir(CLEANUP => 1);
  my $css_file = "$tempdir/highlight.css";
  my $syntax = $srctype;
  $syntax = $mime_to_ext{$syntax}; # FIXME: Use a central tool
  open(READER, "-|", "highlight", $file, "-c", $css_file, "-S", $syntax);
  my $html = scalar(slurp '<:raw', \*READER);
  my $css = slurp '<:raw', $css_file;
  $html =~ s|(<body[^>]*>)|"$1<style type=\"text/css\">$css</style>"|e;
  return $html;
}

%Converters =
  (
   "application/x-directory>text/plain" => sub {
     my ($file) = @_;
     open(READER, "-|", "ls", $file);
     return scalar(slurp '<:raw', \*READER);
   },

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
     my ($file) = @_;
     open(READER, "-|", "text_x-tex→text_html", $file);
     return scalar(slurp '<:raw', \*READER);
   },

   "text/x-tex>application/pdf" => sub {
     my ($file) = @_;
     open(READER, "-|", "text_x-tex→application_pdf", $file);
     return scalar(slurp '<:raw', \*READER);
   },

   # FIXME: Automate detection of file filters (use on-disk array?)
   "application/pdf>application/postscript" => sub {
     my ($file) = @_;
     open(READER, "-|", "application_pdf→application_postscript", $file);
     return scalar(slurp '<:raw', \*READER);
   },

   "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet>text/csv" => sub {
     my ($file) = @_;
     open(READER, "-|", "application_vnd.openxmlformats-officedocument.spreadsheetml.sheet→text_csv", $file);
     return scalar(slurp '<:raw', \*READER);
   },

   "text/csv>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => sub {
     my ($file) = @_;
     open(READER, "-|", "text_csv→application_vnd.openxmlformats-officedocument.spreadsheetml.sheet", $file);
     return scalar(slurp '<:raw', \*READER);
   },

   "application/x-dvi>application/postscript" => sub {
     my ($file) = @_;
     open(READER, "-|", "application_x-dvi→application_postscript", $file);
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

   # FIXME: generalise the function to arbitrary audio types, using output of pacpl -f
   "audio/x-flac>audio/mpeg" => sub {
     my ($file) = @_;
     my $tempdir = tempdir(CLEANUP => 1);
     my $tempfile = "$tempdir/tmp.mp3";
     system "pacpl", "--flactomp3", "--file=\"$file\"", "--file=\"$tempfile\"";
     return scalar(slurp '<:raw', $tempfile);
   },
  );


sub convert {
  my ($file, $srctype, $desttype) = @_;
  #print STDERR $file, " ", $srctype, " ", $desttype, " ", defined($Converters{"$srctype>$desttype"}), "\n";
  $srctype ||= "application/octet-stream";
  $desttype ||= "application/octet-stream";
  return scalar(slurp '<:raw', $file) if $srctype eq $desttype;
  # FIXME: return error if no converter available
  return "" if ($file ne "-" && !-e $file) || !defined($Converters{"$srctype>$desttype"});
  return $Converters{"$srctype>$desttype"}($file, $srctype, $desttype);
}

sub converters {
  my ($match) = @_;
  $match ||= qr/.*/;
  my @convs;
  for my $c (keys %Converters) {
    push @convs, $c if $c =~ m/$match/;
  }
  return @convs;
}


1;                              # return a true value
