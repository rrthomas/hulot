"text/x-tex>text/html" => sub {
  my ($file, $page, $baseurl) = @_;
  my $tempdir = tempdir(CLEANUP => 1);
  # FIXME: Customization of LaTeX env. vars should be moved into web.pl
  system "env BIBINPUTS=\"" . dirname($file) . ":$ENV{HOME}/texmf/bibtex\" TEXINPUTS=\"$tempdir:/home/rrt/texmf/tex/latex//:" . dirname($file) . ":\" TEXMFOUTPUT=\"$tempdir\" LOG=\"$tempdir/latex-mk.log\" latex-mk --pdflatex \"$file\" > \"$tempdir/log\"";
   return ("", scalar(slurp "$tempdir/log")); # useful for debugging
  # FIXME: Move customization of special HeVeA files into web.pl
  system "cd \"$tempdir\"; hevea -fix -I \"$ENV{HOME}/texmf/hevea\" -I \"" . dirname($file) . "\" sym.hva latex2html.hva local.hva -o \"$tempdir/tmp.html\" \"$file\" >> \"$tempdir/log\"";
  my $text = scalar(slurp '<:utf8', "$tempdir/tmp.html");
  # FIXME: Move text below into files that can be internationalised
  # FIXME: download links should be generated in convert's caller,
  # according to list of possible methods. Then get rid of $page
  # and $baseurl, and add page count using pdfpages macro.
  my $download = a({-href => "$baseurl$page?convert=text/x-tex"}, "Download LaTeX") . br .
                   a({-href => "$baseurl$page?convert=application/pdf"}, "Download PDF");
  return ($text, $download);
},
