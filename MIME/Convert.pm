# Convert.pm
# Convert one MIME type into another
# (c) 2002-2023 Reuben Thomas (rrt@sc3d.org, https://github.com/rrthomas/Hulot)
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

use Config;

use Perl6::Slurp;
use File::Spec::Functions qw(catfile);
use Module::Path qw(module_path);

use vars qw(%Converters);


# Add on-disk converters to PATH
my $module_dir = module_path("MIME::Convert");
$module_dir =~ s|/Convert.pm||;
$ENV{PATH} .= $Config{path_sep} . catfile($module_dir, "converters");

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
     return run("application_x-directory→text_plain", $file);
   },

   "inode/directory>text/plain" => sub {
     my ($file) = @_;
     return run("inode_directory→text_plain", $file);
   },

   # FIXME: Should have a rule for this
   #"text/plain>text/html" => ,

   # Treat empty files as text
   # FIXME: make this application/x-empty>*
   "application/x-empty>text/html" => sub {
     my ($file) = @_;
     return run("application_x-empty→text/html", $file);
   },

   # Types trivially transformable
   "text/x-mail>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-mail→text_plain", $file);
   },
   "text/x-news>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-news→text_plain", $file);
   },
   "text/x-readme>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-readme→text_plain", $file);
   },
   "text/markdown>text/plain" => sub {
     my ($file) = @_;
     return run("text_markdown→text_plain", $file);
   },

   # FIXME: Reuse (and expand) this list of programming languages
   "text/x-c>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-c→text_plain", $file);
   },
   "text/x-c++>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-c++→text_plain", $file);
   },
   "text/x-fortran>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-fortran→text_plain", $file);
   },
   "text/x-makefile>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-makefile→text_plain", $file);
   },
   "text/x-pl1>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-pl1→text_plain", $file);
   },
   "text/x-asm>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-asm→text_plain", $file);
   },
   "text/x-pascal>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-pascal→text_plain", $file);
   },
   "text/x-java>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-java→text_plain", $file);
   },
   "text/x-bcpl>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-bcpl→text_plain", $file);
   },
   "text/x-m4>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-m4→text_plain", $file);
   },
   "text/x-po>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-po→text_plain", $file);
   },
   "text/x-perl>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-perl→text_plain", $file);
   },
   "text/x-python>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-python→text_plain", $file);
   },
   "text/x-ruby>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-ruby→text_plain", $file);
   },
   "text/x-shellscript>text/plain" => sub {
     my ($file) = @_;
     return run("text_x-shellscript→text_plain", $file);
   },

   # Programming languages to HTML with highlight
   "text/x-c>text/html" => sub {
     my ($file) = @_;
     return run("text_x-c→text_html", $file);
   },
   "text/x-c++>text/html" => sub {
     my ($file) = @_;
     return run("text_x-c++→text_html", $file);
   },
   "text/x-fortran>text/html" => sub {
     my ($file) = @_;
     return run("text_x-fortran→text_html", $file);
   },
   "text/x-makefile>text/html" => sub {
     my ($file) = @_;
     return run("text_x-makefile→text_html", $file);
   },
   "text/x-pl1>text/html" => sub {
     my ($file) = @_;
     return run("text_x-pl1→text_html", $file);
   },
   "text/x-asm>text/html" => sub {
     my ($file) = @_;
     return run("text_x-asm→text_html", $file);
   },
   "text/x-pascal>text/html" => sub {
     my ($file) = @_;
     return run("text_x-pascal→text_html", $file);
   },
   "text/x-java>text/html" => sub {
     my ($file) = @_;
     return run("text_x-java→text_html", $file);
   },
   "text/x-bcpl>text/html" => sub {
     my ($file) = @_;
     return run("text_x-bcpl→text_html", $file);
   },
   "text/x-m4>text/html" => sub {
     my ($file) = @_;
     return run("text_x-m4→text_html", $file);
   },
   "text/x-po>text/html" => sub {
     my ($file) = @_;
     return run("text_x-po→text_html", $file);
   },
   "text/x-perl>text/html" => sub {
     my ($file) = @_;
     return run("text_x-perl→text_html", $file);
   },
   "text/x-python>text/html" => sub {
     my ($file) = @_;
     return run("text_x-python→text_html", $file);
   },
   "text/x-ruby>text/html" => sub {
     my ($file) = @_;
     return run("text_x-ruby→text_html", $file);
   },
   "text/x-shellscript>text/html" => sub {
     my ($file) = @_;
     return run("text_x-shellscript→text_html", $file);
   },

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
     return run("application_vnd.ms-excel→text_csv", $file, $fileext, $filebase);
   },

   "application/vnd.ms-office>text/csv" => sub {
     my ($file, $srctype, $desttype, $fileext, $filebase) = @_;
     return run("application_vnd.ms-office→text_csv", $file, $fileext, $filebase);
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

   "audio/x-flac>audio/mpeg" => sub {
     my ($file) = @_;
     return run("audio_*→audio_mpeg", $file);
   },
   "audio/x-opus+ogg>audio/mpeg" => sub {
     my ($file) = @_;
     return run("audio_*→audio_mpeg", $file);
   },
   "audio/ogg>audio/mpeg" => sub {
     my ($file) = @_;
     return run("audio_*→audio_mpeg", $file);
   },
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
