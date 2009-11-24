#!/usr/bin/perl -w
#
#  Copyright (c) 2003-2004, Artem B. Bityuckiy, SoftMine Corporation.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.
#
use integer;
use Getopt::Std;
use strict;

sub err($);
sub process_section_encodings($);
sub process_section_cesdeps($);
sub next_entry($$$);

sub generate_cesbi_h($$);
sub generate_encnames_h(@);
sub generate_aliasesbi_c($);
sub generate_encoding_aliases_c($);
sub generate_cesdeps_h($);
sub generate_ccsbi_h($);
sub generate_cesbi_c($);
sub generate_ccsnames_h($);

# ==============================================================================
#
# GLOBAL VARIABLES
#
# ==============================================================================

my $comment_automatic =
"/*
 * This file was automatically generated mkdeps.pl script. Don't edit.
 */";

my $macro_from_enc     = '_ICONV_FROM_ENCODING_';
my $macro_to_enc       = '_ICONV_TO_ENCODING_';
my $macro_from_ucs_ces = 'ICONV_FROM_UCS_CES_';
my $macro_to_ucs_ces   = 'ICONV_TO_UCS_CES_';
my $macro_from_ucs_ccs = 'ICONV_FROM_UCS_CCS_';
my $macro_to_ucs_ccs   = 'ICONV_TO_UCS_CCS_';
my $macro_enc_name     = 'ICONV_ENCODING_';
my $macro_ccs_name     = 'ICONV_CCS_';

my $var_from_ucs_handlers = '_iconv_from_ucs_ces_handlers_';
my $var_to_ucs_handlers   = '_iconv_to_ucs_ces_handlers_';
my $var_ccs       = '_iconv_ccs_';
my $var_aliases   = '_iconv_aliases';
my $var_ces_names = 'iconv_ces_names_';

# ==============================================================================
#
# PARSE COMMAND-LINE OPTIONS.
#
# ==============================================================================

my %options;

# SUPPORTED OPTIONS.
my $help_opt    = 'h';
my $infile_opt  = 'i';
my $verbose_opt = 'v';

# Default input configuration file name
my $default_infile = '../lib/encoding.deps';
# Real input configuration file name
my $infile;
# Verbose flag (be verbose if not zero)
my $verbose;

{
getopts ("${help_opt}${verbose_opt}${infile_opt}:", \%options)
or err "getopts() failed: $!.";

if ($options{$help_opt})
{
  # Output help message and exit.
  print "Usage: $0 [-$infile_opt depfile] [-$help_opt]\n";
  print "\t-$infile_opt - input file with configuration ($default_infile ";
  print "file will be used by default)\n";
  print "\t-$help_opt - this help message\n";
  exit 0;
}

# Input file name.
$infile = $options{$infile_opt} ? $options{$infile_opt} : $default_infile;
$verbose = $options{$verbose_opt} ? 1 : 0;

print "Debug: -$verbose_opt option found.\n" if $verbose;

# ==============================================================================
#
# Find and fetch sections from input file
#
# ==============================================================================

# Opening input file
print "Debug: open \"$infile\" input file.\n" if $verbose;
open (INFILE, '<', $infile) or err "Can't open \"$infile\" file for reading.\n"
                                 . "System error message: $!.\n";

# Configuration file markers
my $marker_section = 'SECTION';
my $marker_section_end = 'SECTION END';

# File sections. Hash values are references to arrays with section contents
my %sections;

# Extract sections from file
for (my $ln = 1; my $l = <INFILE>; $ln += 1)
{
  # Skip comments and empty lines
  next if $l =~ m/^#.*$/ or $l =~ m/^\s*$/;

  # Remove last CR symbol
  $l =~ s/^(.*)\n$/$1/, $l =~ s/^(.*)\r$/$1/;

  # Generate error if line isn't section begin marker
  err "(input file line $ln) Unexpected marker: \"$l\". ${marker_section} "
    . "is expected."
  if $l !~ m/^$marker_section(\s+(\S*)\s*)?$/;
  
  # Generate error if there is no section name
  err "(input file line $ln) Section name isn't found"
  if !$1 or !$2;
  
  # Generate error if this is section end marker
  err "(input file line $ln) Unexpected \"${marker_section_end}\" marker "
    . "in input file."
  if $2 eq $marker_section_end;

  my $sect_name = $2;

  # Extract section content
  for (; $l = <INFILE>; $ln += 1)
  {
    # Skip comments and empty lines
    next if $l =~ m/^#.*$/ or $l =~ m/^$/;
    # Remove last CR symbol
    $l =~ s/^(.*)\n$/$1/, $l =~ s/^(.*)\r$/$1/;
    
    last if $l =~ m/^$marker_section_end$/;

    push @{$sections{$sect_name}}, $l;
  }

  # Generate error if section wasn't ended
  err "(input file line $ln) \"No $marker_section_end\" marker found"
  if $l !~ m/^$marker_section_end$/;
}

close INFILE or err "Error while closing input file.";

# =============================================================================
#
# Now sections are fetched. Each section is processed by separate function.
# There are only three supported sections now: ENCODINGS, CES_DEPENDENCIES
# and ENCODING_CCS_DEPENDENCIES.
#
# =============================================================================

my $section_encodings = 'ENCODINGS';
my $section_cesdeps   = 'CES_DEPENDENCIES';

my $section;

err "$section_encodings not found."
if !defined $sections{$section_encodings};
err "$section_cesdeps not found."
if !defined $sections{$section_cesdeps};

# Process sections
print "Debug: process $section_encodings section.\n" if $verbose;
process_section_encodings ($sections{$section_encodings});
delete $sections{$section_encodings};

print "Debug: process $section_cesdeps section.\n" if $verbose;
process_section_cesdeps ($sections{$section_cesdeps});
delete $sections{$section_cesdeps};

print STDERR "Warning: section \"$_\" was ignored!\n"
foreach (keys %sections);

exit 1;
}

# =============================================================================
#
# Print error message and exit.
#
# Parameter 1: error message.
#
# =============================================================================
sub err($)
{
  print STDERR "Error while running script.\n$_[0]\n";
  exit 0;
}


# =============================================================================
#
# Process ENCODINGS section.
#
# Parameter 1 (input):  array reference with section content;
#
# =============================================================================
sub process_section_encodings($)
{
  my $sect = $_[0];
  my $lineidx = 0;
  my @entry;
  my $marker_encoding = 'ENCODING';
  my $marker_ces      = 'CES';
  my $marker_ccs      = 'CCS';
  my $marker_aliases  = 'ALIASES';

  # Keys: CES names. Values: array reference with encodings list.
  my %cesenc;
  # Keys: encodings. Values: CES converter names.
  my %encces;
  # Keys: CCS tables names. Values: array reference with encodings.
  my %ccsenc;
  # Keys: encodings. Values: aliases list.
  my %encalias;

  while (next_entry ($sect, \@entry, \$lineidx))
  {
    my $encoding;
    my $ces;
    my $ccs;
    my $aliases;
    
    foreach my $l (@entry)
    {
      if ($l =~ m/^($marker_encoding):\s*(\S*)\s*$/)
      {
        err "(process_section_encodings()) More than one $marker_encoding "
          . "records found ($l)"
        if defined $encoding;
        
        $encoding = $2; 
      }
      elsif ($l =~ m/^($marker_ces):\s*(\S*)\s*$/)
      {
        err "(process_section_encodings()) More than one $marker_ces "
          . "records found ($l)"
        if defined $ces;

        $ces = $2;
      }
      elsif ($l =~ m/^($marker_aliases):\s*(.*)\s*$/)
      {
        err "(process_section_encodings()) More than one "
          . "$marker_aliases records found ($l)"
        if defined $aliases;

        $aliases = $2;
      }
      elsif ($l =~ m/^($marker_ccs):\s*(.*)\s*$/)
      {
        err "(process_section_encodings()) More than one "
          . "$marker_ccs records found ($l)"
        if defined $ccs;

        $ccs = $2;
      }
      else
      {
        err "(process_section_encodings()) Can't parse \"$l\"";
      }
    }
  
    err "(process_section_encodings()) $encoding is defined twice"
    if (defined $encces{$encoding});
    err "(process_section_encodings()) ENCODING: field isn't found"
    if not defined $encoding;

    if (defined $ces)
    {
      push @{$cesenc{$ces}}, $encoding;
      $encces{$encoding} = $ces;
    }
    
    if (defined $ccs)
    {
      my @ccs = split / /, $ccs;
      push @{$ccsenc{$_}}, $encoding foreach (@ccs);
    }
    $encalias{$encoding} = $aliases;
  }

  # Generate cesbi.h header file
  generate_cesbi_h (\%cesenc, \%encces);

  # Generate encnames.h header file
  generate_encnames_h (keys %encces);

  # Generate aliasesbi.c file
  generate_aliasesbi_c (\%encalias);
  
  # Generate encoding.aliases file
  generate_encoding_aliases (\%encalias);

  # Generate ccsbi.h header file
  generate_ccsbi_h (\%ccsenc);

  # Generate cesbi.c file
  generate_cesbi_c (\%cesenc);

  # Generate ccsbi.c file
  my @ccs = keys %ccsenc;
  generate_ccsbi_c (\@ccs);
  
  # Generate ccsnames.h header file
  generate_ccsnames_h (\%ccsenc);

}

# ==============================================================================
#
# Process CES_DEPENDENCIES section.
#
# Parameter 1: array reference with section content.
#
# ==============================================================================
sub process_section_cesdeps($)
{
  my $sect = $_[0];
  my $lineidx = 0;
  my @entry;
  my $marker_ces      = 'CES';
  my $marker_used_ces = 'USED_CES';
  my %cesdeps;

  while (next_entry ($sect, \@entry, \$lineidx))
  {
    my $ces;
    my $used_ces;

    foreach my $l (@entry)
    {
      if ($l =~ m/^($marker_ces):\s*(\S*)\s*$/)
      {
        err "(process_section_cesdeps()) More than one $marker_ces "
          . "records found ($l)"
        if $ces;
        
        $ces = $2; 
      }
      elsif ($l =~ m/^($marker_used_ces):\s*(.*)\s*$/)
      {
        err "(process_section_cesdeps()) More than one $marker_used_ces "
          . "records found ($l)"
        if $used_ces;

        $used_ces = $2;
      }
      else
      {
        err "(process_section_cesdeps()) Can't parse \"$l\"";
      }
    }
  
    err "(process_section_esdeps()) $ces dependecties are defined twice"
    if (defined $cesdeps{$ces});

    # Split string
    my @used_ces = split / /, $used_ces;

    $cesdeps{$ces} = \@used_ces;
  }

  # Generate cesdeps.h header file
  generate_cesdeps_h (\%cesdeps);
}

# ==============================================================================
#
# Extract next entry.
#
# Parameter 1 (input): array reference with entries;
# Parameter 2 (output): array reference with entry content;
# Parameter 3 (input/output): scalar reference with line index to process.
#
# Returns 1 is entry was found, 0 if thee is no more entries;
#
# ==============================================================================
sub next_entry($$$)
{
  my $entries = $_[0];
  my $entry   = $_[1];
  my $idx     = $_[2];
  my $marker_entry = 'ENTRY';
  my $marker_entry_end = 'ENTRY END';
  my $entry_flag = 0;

  return 0 if not defined ${$entries}[${$idx}];

  undef @{$entry};

  for (; my $l = ${$entries}[${$idx}++];)
  {
    # Skip comments and empty lines
    next if $l =~ m/^#.*$/ or $l =~ m/^\s*$/;
    
    if ($l =~ m/^$marker_entry$/)
    {
      err "(next_entry()) $marker_entry marker appears twice"
      if ($entry_flag == 1);
      $entry_flag = 1;
      $l = ${$entries}[${$idx}++]
    }
    else
    {
      # Generate error if line isn't entry begin marker
      err "(next_entry()) Unexpected marker: \"$l\". ${marker_entry} "
        . "is expected."
      if ($entry_flag == 0)
    }
        
    last if $l =~ m/^$marker_entry_end$/;

    push @{$entry}, $l;
  }

  return 1;
}

# ==============================================================================
#
# Generate cesbi.h file.
#
# Parameter 1 (input): hash reference with keys = CES Converters names and
# values = array references with list of supported encodings.
# Parameter 2 (input): hash reference with keys = encodings names and
# values = CES converter names.
#
# ==============================================================================
sub generate_cesbi_h($$)
{
  my %cesenc = %{$_[0]};
  my %encces = %{$_[1]};
  my @ces = sort keys %cesenc;
  
  print "Debug: create \"cesbi.h\" file.\n" if $verbose;
  open (CESBI_H, '>', "cesbi.h")
  or err "Can't create \"cesbi.h\" file for writing.\nSystem error message: $!.\n";

  print CESBI_H "$comment_automatic\n\n";
  print CESBI_H "#ifndef __CESBI_H__\n";
  print CESBI_H "#define __CESBI_H__\n\n";
  print CESBI_H "#include <newlib.h>\n";
  print CESBI_H "#include <_ansi.h>\n";
  print CESBI_H "#include \"../lib/encnames.h\"\n";
  print CESBI_H "#include \"../lib/ucsconv.h\"\n\n";
  print CESBI_H "/*\n";
  print CESBI_H " * Enable CES converter if correspondent encoding is requested.\n";
  print CESBI_H " * Defining ${macro_to_ucs_ces}XXX macro or ${macro_from_ucs_ces}XXX\n";
  print CESBI_H " * macro is needed to enable \"XXX encoding -> UCS\" or \"UCS -> XXX encoding\"\n";
  print CESBI_H " * part of UCS-based CES converter.\n";
  print CESBI_H " */\n";
    
  foreach my $ces (@ces)
  {
    my @encs = sort @{$cesenc{$ces}};
    foreach my $encoding (@encs)
    {
      print CESBI_H $encoding eq $encs[0] ? "#if " : " || ";
      print CESBI_H "defined ($macro_from_enc\U$encoding)";
      print CESBI_H " \\" if $encoding ne $encs[$#encs];
      print CESBI_H "\n";
    }
    print CESBI_H "#  define $macro_to_ucs_ces\U$ces\n";
    print CESBI_H "#endif\n";
    
    foreach my $encoding (@encs)
    {
      print CESBI_H $encoding eq $encs[0] ? "#if " : " || ";
      print CESBI_H "defined ($macro_to_enc\U$encoding)";
      print CESBI_H " \\" if $encoding ne $encs[$#encs];
      print CESBI_H "\n";
    }
    print CESBI_H "#  define $macro_from_ucs_ces\U$ces\n";
    print CESBI_H "#endif\n\n";
  }
  
  print CESBI_H "/*\n";
  print CESBI_H " * Some encodings require another encodings to be enabled.\n";
  print CESBI_H " * These dependencies are handled in cesdeps.h header file.\n";
  print CESBI_H " */\n";
  print CESBI_H "#include \"cesdeps.h\"\n\n";

  print CESBI_H "/*\n";
  print CESBI_H " * NLS uses iconv's capabilities and require one of encodings\n";
  print CESBI_H " * to be enabled for internal wchar_t representation.\n";
  print CESBI_H " */\n";
  print CESBI_H "#include \"../lib/iconvnls.h\"\n\n";

  print CESBI_H "/*\n";
  print CESBI_H " * Forward declarations of CES converter handlers.\n";
  print CESBI_H " * These handlers are actually defined in correspondent CES converter files.\n";
  print CESBI_H " */\n";

  foreach my $ces (@ces)
  {
    print CESBI_H "#ifdef $macro_to_ucs_ces\U$ces\n";
    print CESBI_H "extern _CONST iconv_to_ucs_ces_handlers_t\n";
    print CESBI_H "$var_to_ucs_handlers$ces;\n";
    print CESBI_H "#endif\n";

    print CESBI_H "#ifdef $macro_from_ucs_ces\U$ces\n";
    print CESBI_H "extern _CONST iconv_from_ucs_ces_handlers_t\n";
    print CESBI_H "$var_from_ucs_handlers$ces;\n";
    print CESBI_H "#endif\n\n";
  }

  print CESBI_H "#endif /* !__CESBI_H__ */\n\n";
  close CESBI_H or err "Error while closing cesbi.h file.";
}

# ==============================================================================
#
# Generate encnames.h header file.
#
# Parameters: array of supported encodings.
#
# ==============================================================================
sub generate_encnames_h(@)
{
  print "Debug: create \"../lib/encnames.h\" file.\n" if $verbose;
  open (ENCNAMES_H, '>', "../lib/encnames.h")
  or err "Can't create \"../lib/encnames.h\" file for writing.\nSystem error message: $!.\n";

  print ENCNAMES_H "$comment_automatic\n\n";
  print ENCNAMES_H "#ifndef __ENCNAMES_H__\n";
  print ENCNAMES_H "#define __ENCNAMES_H__\n\n";

  print ENCNAMES_H "/*\n";
  print ENCNAMES_H " * Encodings name macros.\n";
  print ENCNAMES_H " */\n";
  
  foreach my $enc (sort @_)
  {
    print ENCNAMES_H "#define $macro_enc_name\U$enc\E \"$enc\"\n";
  }

  print ENCNAMES_H "\n#endif /* !__ENCNAMES_H__ */\n\n";
  close ENCNAMES_H or err "Error while closing ../lib/encnames.h file.";
}

# ==============================================================================
#
# Generate aliasesbi.c C source file.
#
# Parameters: hash reference with keys = encodings and values = aliases string.
#
# ==============================================================================
sub generate_aliasesbi_c($)
{
  print "Debug: create \"../lib/aliasesbi.c\" file.\n" if $verbose;
  open (ALIASESBI_C, '>', "../lib/aliasesbi.c")
  or err "Can't create \"../lib/aliasesbi.c\" file for writing.\nSystem error message: $!.\n";

  print ALIASESBI_C "$comment_automatic\n\n";
  print ALIASESBI_C "#include <_ansi.h>\n";
  print ALIASESBI_C "#include \"encnames.h\"\n\n";
  print ALIASESBI_C "_CONST char *\n";
  print ALIASESBI_C "$var_aliases =\n";
  print ALIASESBI_C "{\n";

  foreach my $enc (sort keys %{$_[0]})
  {
    print ALIASESBI_C "#if defined ($macro_from_enc\U$enc) \\\n";
    print ALIASESBI_C " || defined ($macro_to_enc\U$enc)\n";
    print ALIASESBI_C "  $macro_enc_name\U$enc\E";
    print ALIASESBI_C " \" ${$_[0]}{$enc}\\n\"" if defined ${$_[0]}{$enc};
    print ALIASESBI_C "\n";
    print ALIASESBI_C "#endif\n";
  }
  print ALIASESBI_C "  \"\"\n";
  print ALIASESBI_C "};\n\n";
  
  close ALIASESBI_C or err "Error while closing ../lib/aliasesbi.c file.";
}

# ==============================================================================
#
# Generate encoding.aliases file.
#
# Parameter 1: hash reference with keys = encodings and values = aliases string.
#
# ==============================================================================
sub generate_encoding_aliases($)
{
  print "Debug: create \"../encoding.aliases\" file.\n" if $verbose;
  open (ALIASES, '>', "../encoding.aliases")
  or err "Can't create \"../encoding.aliases\" file for writing.\nSystem error message: $!.\n";

  print ALIASES "#\n# This file was automatically generated. Don't edit.\n#\n\n";

  foreach my $enc (sort keys %{$_[0]})
  {
    print ALIASES "$enc";
    print ALIASES " ${$_[0]}{$enc}" if defined ${$_[0]}{$enc};
    print ALIASES "\n";
  }
  
  print ALIASES "\n";
  
  close ALIASES or err "Error while closing ./encoding.aliases file.";
}

# ==============================================================================
#
# Generate cesdeps.h header file.
#
# Parameter 1: hash reference with keys = CES converters and values = references
# to arrays with list of CES converters which are needed by that CES converter
# (defined by key).
#
# ==============================================================================
sub generate_cesdeps_h($)
{
  my %cesdeps = %{$_[0]};
  
  print "Debug: create \"cesdeps.h\" file.\n" if $verbose;
  open (CESDEPS_H, '>', "cesdeps.h")
  or err "Can't create \"cesdeps.h\" file for writing.\nSystem error message: $!.\n";

  print CESDEPS_H "$comment_automatic\n\n";
  print CESDEPS_H "#ifndef __CESDEPS_H__\n";
  print CESDEPS_H "#define __CESDEPS_H__\n\n";

  print CESDEPS_H "/*\n";
  print CESDEPS_H " * Some CES converters use another CES converters and the following\n";
  print CESDEPS_H " * is such dependencies description.\n";
  print CESDEPS_H " */\n";
  
  foreach my $ces (sort keys %cesdeps)
  {
    my @deps = sort @{$cesdeps{$ces}};

    print CESDEPS_H "#ifdef $macro_to_ucs_ces\U$ces\n";
    
    foreach my $dep (@deps)
    {
      print CESDEPS_H "#  ifndef $macro_to_ucs_ces\U$dep\n";
      print CESDEPS_H "#    define $macro_to_ucs_ces\U$dep\n";
      print CESDEPS_H "#  endif\n";
    }
    print CESDEPS_H "#endif\n";
    
    print CESDEPS_H "#ifdef $macro_from_ucs_ces\U$ces\n";
    foreach my $dep (@deps)
    {
      print CESDEPS_H "#  ifndef $macro_from_ucs_ces\U$dep\n";
      print CESDEPS_H "#    define $macro_from_ucs_ces\U$dep\n";
      print CESDEPS_H "#  endif\n";
    }
    print CESDEPS_H "#endif\n";
  }

  print CESDEPS_H "\n#endif /* !__CESDEPS_H__ */\n\n";
  close CESDEPS_H or err "Error while closing cesdeps.h file.";
}

# ==============================================================================
#
# Generate ccsbi.h file.
#
# Parameter 1 (input): hash reference with keys = CCS tables names and
# values = array references with list of encodings which need this CCS table.
#
# ==============================================================================
sub generate_ccsbi_h($)
{
  my %ccsenc = %{$_[0]};
  my @ccs = sort keys %ccsenc;
  
  print "Debug: create \"../ccs/ccsbi.h\" file.\n" if $verbose;
  open (CCSBI_H, '>', "../ccs/ccsbi.h")
  or err "Can't create \"../ccs/ccsbi.h\" file for writing.\nSystem error message: $!.\n";

  print CCSBI_H "$comment_automatic\n\n";
  print CCSBI_H "#ifndef __CCSBI_H__\n";
  print CCSBI_H "#define __CCSBI_H__\n\n";
  print CCSBI_H "#include <newlib.h>\n";
  print CCSBI_H "#include <_ansi.h>\n";
  print CCSBI_H "#include \"ccs.h\"\n\n";
  print CCSBI_H "/*\n";
  print CCSBI_H " * Enable CCS tables if encoding needs them.\n";
  print CCSBI_H " * Defining ${macro_to_ucs_ccs}XXX macro or ${macro_from_ucs_ccs}XXX\n";
  print CCSBI_H " * macro is needed to enable \"XXX encoding -> UCS\" or \"UCS -> XXX encoding\"\n";
  print CCSBI_H " * part of CCS table.\n";
  print CCSBI_H " * CCS tables aren't linked if Newlib was configuted to use external CCS tables.\n";
  print CCSBI_H " */\n";
  
  print CCSBI_H "#ifndef _ICONV_ENABLE_EXTERNAL_CCS\n\n";

  foreach my $ccs (@ccs)
  {
    my @encs = sort @{$ccsenc{$ccs}};
    foreach my $encoding (@encs)
    {
      print CCSBI_H $encoding eq $encs[0] ? "#if " : " || ";
      print CCSBI_H "defined ($macro_from_enc\U$encoding)";
      print CCSBI_H " \\" if $encoding ne $encs[$#encs];
      print CCSBI_H "\n";
    }
    print CCSBI_H "#  define $macro_to_ucs_ccs\U$ccs\n";
    print CCSBI_H "#endif\n";
    
    foreach my $encoding (@encs)
    {
      print CCSBI_H $encoding eq $encs[0] ? "#if " : " || ";
      print CCSBI_H "defined ($macro_to_enc\U$encoding)";
      print CCSBI_H " \\" if $encoding ne $encs[$#encs];
      print CCSBI_H "\n";
    }
    print CCSBI_H "#  define $macro_from_ucs_ccs\U$ccs\n";
    print CCSBI_H "#endif\n\n";
  }

  print CCSBI_H "/*\n";
  print CCSBI_H " * CCS table description structures forward declarations.\n";
  print CCSBI_H " */\n";

  foreach my $ccs (@ccs)
  {
    print CCSBI_H "#if defined ($macro_to_ucs_ccs\U$ccs) \\\n";
    print CCSBI_H " || defined ($macro_from_ucs_ccs\U$ccs)\n";
    print CCSBI_H "extern _CONST iconv_ccs_t\n";
    print CCSBI_H "$var_ccs$ccs;\n";
    print CCSBI_H "#endif\n";
  }

  print CCSBI_H "\n#endif /* !_ICONV_ENABLE_EXTERNAL_CCS */\n\n";
  print CCSBI_H "\n#endif /* __CCSBI_H__ */\n\n";
  close CCSBI_H or err "Error while closing ../ccs/ccsbi.h file.";
}

# ==============================================================================
#
# Generate cesbi.c file.
#
# Parameter 1 (input): hash reference with keys = CES Converters names and
# values = array references with list of supported encodings.
#
# ==============================================================================
sub generate_cesbi_c($)
{
  my %cesenc = %{$_[0]};
  my @ces = sort keys %cesenc;

  print "Debug: create \"cesbi.c\" file.\n" if $verbose;
  open (CESBI_C, '>', "cesbi.c")
  or err "Can't create \"cesbi.c\" file for writing.\nSystem error message: $!.\n";

  print CESBI_C "$comment_automatic\n\n";
  print CESBI_C "#include <_ansi.h>\n";
  print CESBI_C "#include <newlib.h>\n";
  print CESBI_C "#include \"../lib/ucsconv.h\"\n";
  print CESBI_C "#include \"cesbi.h\"\n\n";
  print CESBI_C "/*\n";
  print CESBI_C " * Each CES converter provides the list of supported encodings.\n";
  print CESBI_C " */\n";

  foreach my $ces (@ces)
  {
    print CESBI_C "#if defined ($macro_to_ucs_ces\U$ces) \\\n";
    print CESBI_C " || defined ($macro_from_ucs_ces\U$ces)\n";
    print CESBI_C "static _CONST char *\n";
    print CESBI_C "$var_ces_names${ces}\[] =\n";
    print CESBI_C "{\n";
    my @encodings = sort @{$cesenc{$ces}};
    foreach my $encoding (@encodings)
    {
      print CESBI_C "# if defined ($macro_from_enc\U$encoding) \\\n";
      print CESBI_C "  || defined ($macro_to_enc\U$encoding)\n";
      print CESBI_C "  $macro_enc_name\U$encoding,\n";
      print CESBI_C "#endif\n";
    }
    print CESBI_C "  NULL\n";
    print CESBI_C "};\n";
    print CESBI_C "#endif\n\n";
  }

  print CESBI_C "/*\n";
  print CESBI_C " * The following structure contains the list of \"to UCS\" linked-in CES converters.\n";
  print CESBI_C " */\n";
  print CESBI_C "_CONST iconv_to_ucs_ces_t\n";
  print CESBI_C "_iconv_to_ucs_ces[] =\n";
  print CESBI_C "{\n";
  
  foreach my $ces (@ces)
  {
    print CESBI_C "#ifdef $macro_to_ucs_ces\U$ces\n";
    print CESBI_C "  {(_CONST char **)$var_ces_names$ces,\n";
    print CESBI_C "   &$var_to_ucs_handlers$ces},\n";
    print CESBI_C "#endif\n";
  }
  print CESBI_C "  {(_CONST char **)NULL,\n";
  print CESBI_C "  (iconv_to_ucs_ces_handlers_t *)NULL}\n";
  print CESBI_C "};\n\n";

  print CESBI_C "/*\n";
  print CESBI_C " * The following structure contains the list of \"from UCS\" linked-in CES converters.\n";
  print CESBI_C " */\n";
  print CESBI_C "_CONST iconv_from_ucs_ces_t\n";
  print CESBI_C "_iconv_from_ucs_ces[] =\n";
  print CESBI_C "{\n";
  
  foreach my $ces (@ces)
  {
    print CESBI_C "#ifdef $macro_from_ucs_ces\U$ces\n";
    print CESBI_C "  {(_CONST char **)$var_ces_names$ces,\n";
    print CESBI_C "   &$var_from_ucs_handlers$ces},\n";
    print CESBI_C "#endif\n";
  }
  print CESBI_C "  {(_CONST char **)NULL,\n";
  print CESBI_C "  (iconv_from_ucs_ces_handlers_t *)NULL}\n";
  print CESBI_C "};\n";

  close CESBI_C or err "Error while closing cesbi.c file.";
}

# ==============================================================================
#
# Generate ccsbi.c file.
#
# Parameter 1 (input): array reference with CCS tables names
#
# ==============================================================================
sub generate_ccsbi_c($)
{
  my @ccs = @{$_[0]};
  
  print "Debug: create \"../ccs/ccsbi.c\" file.\n" if $verbose;
  open (CESBI_C, '>', "../ccs/ccsbi.c")
  or err "Can't create \"../ccs/ccsbi.c\" file for writing.\nSystem error message: $!.\n";

  print CESBI_C "$comment_automatic\n\n";
  print CESBI_C "#include <_ansi.h>\n";
  print CESBI_C "#include \"ccsbi.h\"\n\n";
  print CESBI_C "/*\n";
  print CESBI_C " * The following array contains the list of built-in CCS tables.\n";
  print CESBI_C " */\n";

  print CESBI_C "_CONST iconv_ccs_t *\n";
  print CESBI_C "_iconv_ccs[] =\n";
  print CESBI_C "{\n";

  foreach my $ccs (@ccs)
  {
    print CESBI_C "#if defined ($macro_to_ucs_ccs\U$ccs) \\\n";
    print CESBI_C " || defined ($macro_from_ucs_ccs\U$ccs)\n";
    print CESBI_C "  &$var_ccs$ccs,\n";
    print CESBI_C "#endif\n";
  }
  print CESBI_C "  NULL\n";
  print CESBI_C "};\n";

  close CESBI_C or err "Error while closing ../ccs/ccsbi.c file.";
}

# ==============================================================================
#
# Generate ccsnames.h file.
#
# Parameter 1 (input): hash reference with keys = CCS tables names and
# values = array references with list of encodings which need this CCS table.
#
# ==============================================================================
sub generate_ccsnames_h($)
{
  my %ccsenc = %{$_[0]};
  my @ccs = sort keys %ccsenc;
  
  print "Debug: create \"../ccs/ccsnames.h\" file.\n" if $verbose;
  open (CCSNAMES_H, '>', "../ccs/ccsnames.h")
  or err "Can't create \"../ccs/ccsnames.h\" file for writing.\nSystem error message: $!.\n";

  print CCSNAMES_H "$comment_automatic\n\n";
  print CCSNAMES_H "#ifndef __CCSNAMES_H__\n";
  print CCSNAMES_H "#define __CCSNAMES_H__\n\n";
  print CCSNAMES_H "#include \"../lib/encnames.h\"\n\n";
  print CCSNAMES_H "/*\n";
  print CCSNAMES_H " * CCS tables names macros.\n";
  print CCSNAMES_H " */\n";

  foreach my $ccs (@ccs)
  {
    my @encs = @{$ccsenc{$ccs}};
    my $flag;
    foreach my $encoding (@encs)
    {
      print CCSNAMES_H "#define $macro_ccs_name\U$ccs ";
      if ($encoding eq $ccs)
      {
        $flag = 1;
        print CCSNAMES_H "$macro_enc_name\U$encoding\n";
        last;
      }
    }
    print CCSNAMES_H "\"$ccs\"\n" if !$flag;
  }

  print CCSNAMES_H "\n#endif /* !__CCSNAMES_H__ */\n\n";
  close CCSNAMES_H or err "Error while closing ../ccs/ccsnames.h file.";
}
