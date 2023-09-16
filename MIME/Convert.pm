# Convert.pm
# Convert one MIME type into another
# (c) 2002-2022 Reuben Thomas (rrt@sc3d.org, http://rrt.sc3d.org/)
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
  my $html = run("highlight", $file, "-c", $css_file, "-S", $syntax);
  my $css = slurp '<:raw', $css_file;
  $html =~ s|(<body[^>]*>)|"$1<style type=\"text/css\">$css</style>"|e;
  return $html;
}

sub audioToMp3 {
  my ($file) = @_;
  return run("ffmpeg", "-loglevel", "quiet", "-i", $file, "-f", "mp3", "-");
}

sub run {
  my @cmd = @_;
  open(READER, "-|", @cmd) or die "command $cmd[0] failed (open)";
  my $output = scalar(slurp '<:raw', \*READER);
  close(READER) or die "command $cmd[0] failed (close)";
  return $output;
}

%Converters =
  (
   "application/x-directory>text/plain" => sub {
     my ($file) = @_;
     return run("ls", $file);
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
   "text/markdown>text/plain" => \&renderId,

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
     return run("text_x-tex→text_html", $file);
   },

   "text/markdown>text/html" => sub {
     my ($file) = @_;
     return run("makepage", "-f", "footnote,nopants,noalphalist,nostyle,fencedcode", $file);
   },

   "text/x-tex>application/pdf" => sub {
     my ($file) = @_;
     return run("text_x-tex→application_pdf", $file);
   },

   # FIXME: Automate detection of file filters (use on-disk array?)
   "application/pdf>application/postscript" => sub {
     my ($file) = @_;
     return run("application_pdf→application_postscript", $file);
   },

   "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet>text/csv" => sub {
     my ($file, $srctype, $desttype, $fileext, $filebase) = @_;
     return run("application_vnd.openxmlformats-officedocument.spreadsheetml.sheet→text_csv", $file, $fileext, $filebase);
   },

   "application/vnd.ms-excel>text/csv" => sub {
     my ($file, $srctype, $desttype, $fileext, $filebase) = @_;
     # FIXME: use symlink for filter
     return run("application_vnd.openxmlformats-officedocument.spreadsheetml.sheet→text_csv", $file, $fileext, $filebase);
   },

   "application/vnd.ms-office>text/csv" => sub {
     my ($file, $srctype, $desttype, $fileext, $filebase) = @_;
     # FIXME: use symlink for filter
     return run("application_vnd.openxmlformats-officedocument.spreadsheetml.sheet→text_csv", $file, $fileext, $filebase);
   },

   "text/csv>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => sub {
     my ($file) = @_;
     return run("text_csv→application_vnd.openxmlformats-officedocument.spreadsheetml.sheet", $file);
   },

   "application/x-dvi>application/postscript" => sub {
     my ($file) = @_;
     return run("application_x-dvi→application_postscript", $file);
   },

   "image/x-epoc-sketch>image/png" => sub {
     my ($file) = @_;
     if ($file eq "-") {
       return run("psiconv", "--type=PNG");
     } else {
       return run("psiconv", "--type=PNG", $file);
     }
   },

   "image/x-epoc-sketch>image/jpeg" => sub {
     my ($file) = @_;
     if ($file eq "-") {
       return run("psiconv", "--type=JPEG");
     } else {
       return run("psiconv", "--type=JPEG", $file);
     }
   },

   # FIXME: generalise the function to arbitrary audio types, using output of pacpl --formats
   "audio/x-flac>audio/mpeg" => \&audioToMp3,
   "audio/x-opus+ogg>audio/mpeg" => \&audioToMp3,
   "audio/ogg>audio/mpeg" => \&audioToMp3,
  );


# FIXME: Detect and return errors, so that e.g. DarkGlass can give a generic error instead of leaking permissions information
sub convert {
  my ($file, $srctype, $desttype) = @_;
  $file =~ /^(.*)\.(.*)$/;
  my $filebase = $1 || "";
  my $fileext = $2 || "";
  #print STDERR $file, " ", $srctype, " ", $desttype, " ", defined($Converters{"$srctype>$desttype"}), "\n";
  $srctype ||= "application/octet-stream";
  $desttype ||= "application/octet-stream";
  return scalar(slurp '<:raw', $file) if $srctype eq $desttype;
  die "no converter found\n" if !defined($Converters{"$srctype>$desttype"});
  die "file not found\n" if $file ne "-" && !-e $file;
  return $Converters{"$srctype>$desttype"}($file, $srctype, $desttype, $fileext, $filebase);
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
