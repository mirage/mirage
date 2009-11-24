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
use IO::Seekable;
use strict;


# ##############################################################################
#
# FUNCTION PROTOTYPES AND GLOBAL DATA DECLARATION SECTION
#
# ##############################################################################


# SUPPLEMENTARY FUNCTIONS FORWARD DECLARATIONS
sub ProcessOptions();
sub Err($;$);
sub Generate8bitToUCS();
sub GenerateSpeed($);
sub Generate16bitSize($);
sub Output8bitToUCS(;$);
sub Output8bitFromUCS(;$);
sub OutputSpeed($;$);
sub OutputSize($;$);

# VARIABLES RELATING TO COMMAND-LINE OPTIONS
my $Verbose;  # Be verbose if true
my $Source;   # Output C source code instead of binary .cct file if true
my $Plane;    # Use this plane if defined
my $InFile;   # Use this file for input
my $OutFile;  # Use this file for output
my $CCSName;  # Use this CCS name
my $NoSpeed;  # Don't generate speed-optimized tables (binary files only)
my $NoSize;   # Don't generate size-optimized tables (binary files only)
my $NoBE;     # Don't generate big-endian tables (binary files only)
my $NoLE;     # Don't generate big-endian tables (binary files only)
my $NoTo;     # Don't generate "to_ucs" table (binary files only)
my $NoFrom;   # Don't generate "from_ucs" table (binary files only)
my $CCSCol;   # CCS column number in source file
my $UCSCol;   # UCS column number in source file


# DATA STRUCTURES WITH "TO_UCS" AND "FROM_UCS" SPEED/SIZE -OPTIMIZED TABLES
my (@FromSpeedTbl, @ToSpeedTbl, @FromSizeTbl, @ToSizeTbl);
# "TO_UCS" AND "FROM_UCS" SPEED/SIZE -OPTIMIZED TABLES SIZE IN BYTES
my ($FromSpeedBytes, $ToSpeedBytes, $FromSizeBytes, $ToSizeBytes) =
   (0, 0, 0, 0);

my (%CCSUCS, %UCSCCS); # CCS->UCS and UCS->CCS mappings
my $Bits = 8;          # Table bits (8 or 16);

# SPECIAL MARKER CODES
my $InvCode  = 0xFFFF; # FFFF indicates 18 bit invalid codes
my $InvBlock = 0xFFFF; # FFFF also mark empty blocks in speed-optimized tables
my $LostCode = 0x3F;   # ASCII '?' marks codes lost during CCS->UCS mapping
# To mark invalid codes in 8bit encodings 0xFF is used CCS's 0xFF mapping is saved
# separately. $FFMap variable stores real 0xFF mapping if defined.
my $InvCode8bit = 0xFF;
my $FFMap;

# 8 Bit "From UCS" table header size (bytes)
my $Hdr8bitFromUCS = 2;
# Binary table header size (bytes)
my $HdrBinary = 8;

# At first all lost CCS codes are marked by $TmpLost to distinguish between
# code which is equivalent to $LostCode and lost codes. This is done in order to
# output $MacroLostCode instead of $LostCode in source file.
my $TmpLost = 0x1FFFF;

# VARIABLES RELATING TO C SOURCE CODE
my $MacroInvCode      = 'INVALC';
my $MacroInvBlock     = 'INVBLK';
my $MacroLostCode     = 'LOST_C';
my $MacroCCSName      = 'ICONV_CCS_%s';
my $GuardSize       = 'defined (TABLE_USE_SIZE_OPTIMIZATION)';
my $GuardToUCS      = "ICONV_TO_UCS_CCS_%s";
my $GuardFromUCS    = "ICONV_FROM_UCS_CCS_%s";
my $MacroSpeedTable = 'TABLE_SPEED_OPTIMIZED';
my $MacroSizeTable  = 'TABLE_SIZE_OPTIMIZED';  
my $Macro8bitTable  = 'TABLE_8BIT';
my $Macro16bitTable = 'TABLE_16BIT';
my $MacroVer1Table  = 'TABLE_VERSION_1';
my $TypeBICCS       = 'iconv_ccs_t';
my $VarToUCSSize    = "to_ucs_size_%s";
my $VarToUCSSpeed   = "to_ucs_speed_%s";
my $VarFromUCSSize  = "from_ucs_size_%s";
my $VarFromUCSSpeed = "from_ucs_speed_%s";
my $VarBICCS             = "_iconv_ccs_%s";
# Text block that visually separates tables.
my $Separator = '=' x 70;

# ##############################################################################
#
# SCRIPT ENTRY POINT
#
# ##############################################################################


# Parse command-line options, check them and set correspondent global variables
ProcessOptions();

# Initialize global variables tat depend on CCS name.
$_ = sprintf $_, $CCSName foreach +($VarToUCSSpeed,
                                    $VarToUCSSize,
                                    $VarToUCSSpeed,
                                    $VarFromUCSSpeed,
                                    $VarFromUCSSize,
                                    $VarBICCS);
$_ = sprintf $_, "\U$CCSName" foreach +($GuardToUCS,
                                        $GuardFromUCS,
                                        $MacroCCSName);

# Open input and output files
Err "Can't open \"$InFile\" file for reading: $!.\n", 1
unless open(INFILE, '<', $InFile);
Err "Can't open \"$OutFile\" file for writing: $!.\n", 1
unless open(OUTFILE, '>', $OutFile);

# ==============================================================================
# EXTRACT CODES MAP FROM INPUT FILE
# ==============================================================================

for (my $ln = 1; my $l = <INFILE>; $ln += 1)
{
  # Skip comment and empty lines, remove ending CR symbol
  next if $l =~ /^#.*$/ or $l =~ /^\s*$/;
  $l =~ s/^(.*)\n$/$1/, $l =~ s/^(.*)\r$/$1/;
 
  # Remove comment and extra spaces
  $l =~ s/(.*)\s*#.*/$1/;
  $l =~ s/\s+/ /g;
  $l =~ s/(.*)\s*$/$1/;

  # Split line into individual codes
  my @codes = split / /, $l;

  # Skip line if there is no needed columns
  unless (defined $codes[$CCSCol])
  {
    print("Warning (line $ln): no CCS column, skip.\n") if $Verbose;
    next;
  }
  unless (defined $codes[$UCSCol])
  {
    print("Warning (line $ln): no UCS column, skip.\n") if $Verbose;
    next;
  }

  # Extract codes strings from needed columns
  my ($ccs, $ucs) = ($codes[$CCSCol], $codes[$UCSCol]);
  my $patt = qr/(0[xX])?[0-9a-fA-F]{1,8}/; # HEX digit regexp pattern.

  # Check that CCS and UCS code strings has right format.
  unless ($ccs =~ m/^$patt$/)
  {
    print("Warning (line $ln): $ccs CCS code isn't recognized, skip.\n")
    if $Verbose;
    next;
  }
  unless ($ucs =~ m/^($patt(,|\+))*$patt$/)
  {
    print("Warning (line $ln): $ucs UCS code isn't recognized, skip.\n")
    if $Verbose;
    next;
  }

  # Convert code to numeric format (assume hex).
  $ccs = hex $ccs;

  if ($ucs =~ m/,/ or $ucs =~ m/\+/)
  {
    # Mark CCS codes with "one to many" mappings as lost
    printf "Warning (line $ln): only one to one mapping is supported, "
         . "mark 0x%.4X CCS code as lost.\n", hex $ccs if $Verbose;
    $ucs = $TmpLost;
  }
  else
  {
    # Convert code to numeric format
    $ucs = hex $ucs;

    # Check that UCS code isn't longer than 16 bits.
    if ($ucs > 0xFFFF)
    {
      printf("Warning (line $ln): UCS code should fit 16 bits, "
           . "mark 0x%.4X CCS code as lost.\n", hex $ccs) if $Verbose;
      $ucs = $TmpLost;
    }
  }

  # If CCS value > 0xFFFF user should specify plane number.
  if ($ccs > 0xFFFF && !defined $Plane)
  {
    print("Warning (line $ln): $ccs is > 16 bit, plane number should be specified,"
        . " skip this mapping.\n") if $Verbose;
    next;
  }
  
  if (defined $Plane)
  {
    next if (($ccs & 0xFFFF0000) >> 16) != hex $Plane; # Skip alien plane.
    $ccs &= 0xFFFF;
  }

  # Check that reserved codes aren't used.
  if ($ccs == $InvCode or $ucs == $InvCode)
  {
    print("Warning (line $ln): $InvCode is reserved to mark invalid codes and "
       . "shouldn't be used in mappings, skip.\n") if $Verbose;
    next;
  }

  # Save mapping in UCSCCS and CCSUCS hash arrays.
  $UCSCCS{$ucs} = $ccs if $ucs != $TmpLost && !defined $UCSCCS{$ucs};
  $CCSUCS{$ccs} = $ucs if !defined $CCSUCS{$ccs};

  $Bits = 16 if $ccs > 0xFF;
}

if (not %CCSUCS)
{
  Err "Error: there is no plane $Plane in \"$0\".\n" if defined $Plane;
  Err "Error: mapping wasn't found.\n";
}


# ==============================================================================
# GENERATE TABLE DATA
# ==============================================================================

if ($Bits == 8)
{
  $FFMap = $CCSUCS{0xFF};
  $FFMap = $InvCode if !defined $FFMap; 
}

if ($Bits == 8)
{
  Generate8bitToUCS() unless $NoTo;
}
else
{
  GenerateSpeed("to_ucs") unless $NoTo || $NoSpeed;
  Generate16bitSize("to_ucs")  unless $NoTo || $NoSize;
}

GenerateSpeed("from_ucs") unless $NoFrom || $NoSpeed;
Generate16bitSize("from_ucs")  unless $NoFrom || $NoSize;

# ==============================================================================
# OUTPUT ARRAYS
# ==============================================================================

if ($Source)
{
  # OUTPUT SOURCE
  print OUTFILE
"/*
 * This file was generated automatically - don't edit it.
 * File contains iconv CCS tables for $CCSName encoding.
 */

#include \"ccsbi.h\"

#if defined ($GuardToUCS) \\
 || defined ($GuardFromUCS)

#include <_ansi.h>
#include <sys/types.h>
#include <sys/param.h>
#include \"ccs.h\"
#include \"ccsnames.h\"

";

  if ($Bits == 8)
  {
    print OUTFILE
"#if (BYTE_ORDER == LITTLE_ENDIAN)
#  define W(word) (word) & 0xFF, (word) >> 8
#elif (BYTE_ORDER == BIG_ENDIAN)
#  define W(word) (word) >> 8, (word) & 0xFF
#else
#  error \"Unknown byte order.\"
#endif

";
  }

  unless ($NoTo)
  {
    if ($Bits == 8) 
    {
      Output8bitToUCS();
    }
    else
    {
      OutputSpeed("to_ucs") unless $NoSpeed;
      OutputSize("to_ucs")  unless $NoSize;
    }
  }
  unless ($NoFrom)
  {
    if ($Bits == 8) 
    {
      Output8bitFromUCS();
    }
    else
    {
      OutputSpeed("from_ucs") unless $NoSpeed;
      OutputSize("from_ucs")  unless $NoSize;
    }
  }

  # OUTPUT TABLE DESCRIPTION STRUCTURE 
  print OUTFILE  
"/*
 * $CCSName CCS description table.
 * $Separator
 */
_CONST $TypeBICCS
$VarBICCS =
{
\t$MacroVer1Table, /* Table version */
\t$MacroCCSName, /* CCS name */
";
  if ($Bits == 8)
  {
    print OUTFILE
"\t$Macro8bitTable, /* Table bits */
\t0, /* Not Used */
#if defined ($GuardFromUCS)
\t(__uint16_t *)&$VarFromUCSSpeed, /* UCS -> $CCSName table */
#else
\t(__uint16_t *)NULL,
#endif
\t0, /* Not Used */
#if defined ($GuardToUCS)
\t(__uint16_t *)&$VarToUCSSpeed /* $CCSName -> UCS table */
#else
\t(__uint16_t *)NULL,
#endif
};\n";
  }
  else
  {
    print OUTFILE
"\t$Macro16bitTable, /* Table bits */
#if defined ($GuardFromUCS) \\
 && ($GuardSize)
\t$MacroSizeTable,
\t(__uint16_t *)&$VarFromUCSSize, /* UCS -> $CCSName table size-optimized table */
#elif defined ($GuardFromUCS) \\
 && !($GuardSize)
\t$MacroSpeedTable,
\t(__uint16_t *)&$VarFromUCSSpeed, /* UCS -> $CCSName table speed-optimized table */
#else
\t$MacroSpeedTable,
\t(__uint16_t *)NULL,
#endif
#if defined ($GuardToUCS) \\
 && ($GuardSize)
\t$MacroSizeTable,
\t(__uint16_t *)&$VarToUCSSize /* $CCSName -> UCS table speed-optimized table */
#elif defined ($GuardToUCS) \\
 && !($GuardSize)
\t$MacroSpeedTable,
\t(__uint16_t *)&$VarToUCSSpeed /* $CCSName -> UCS table speed-optimized table */
#else
\t$MacroSpeedTable,
\t(__uint16_t *)NULL,
#endif
};\n";
  }
  print OUTFILE "\n#endif /* $GuardToUCS) || ... */\n\n";
}
else
{
  # OUTPUT BINARY TABLES DESCRIPTION STRUCTURE (ALWAYS BIG ENDIAN)
  print OUTFILE pack "n", 1;
  print OUTFILE pack "n", $Bits;
  my $len = length $CCSName;
  print OUTFILE pack "N", $len;
  print OUTFILE pack "a$len", $CCSName;
  
  my $pos = $HdrBinary + $len;
  if ($pos & 3)
  {
    my $l = 4 - ($pos & 3);
    print OUTFILE pack "a$l", 'XXX';
    $pos += $l;
  }
  
  $pos += 16*4;

  my @tables;
  for (my $i = 0; $i < 16; $i++)
  {
    $tables[$i] = 0;
  }
  
  $tables[0] = $pos, $tables[1] = $FromSpeedBytes, $pos += $FromSpeedBytes
  unless $NoFrom || $NoSpeed || $NoBE;
  $tables[2] = $pos, $tables[3] = $FromSpeedBytes, $pos += $FromSpeedBytes
  unless $NoFrom || $NoSpeed || $NoLE;
  if ($Bits == 16)
  {
    $tables[4] = $pos, $tables[5] = $FromSizeBytes, $pos += $FromSizeBytes
    unless $NoFrom || $NoSize || $NoBE;
    $tables[6] = $pos, $tables[7] = $FromSizeBytes, $pos += $FromSizeBytes
    unless $NoFrom || $NoSize || $NoLE;
  }
  $tables[8] = $pos, $tables[9] = $ToSpeedBytes, $pos += $ToSpeedBytes
  unless $NoTo || $NoSpeed || $NoBE;
  $tables[10] = $pos, $tables[11] = $ToSpeedBytes, $pos += $ToSpeedBytes
  unless $NoTo || $NoSpeed || $NoLE;
  if ($Bits == 16)
  {
    $tables[12] = $pos, $tables[13] = $ToSizeBytes, $pos += $ToSizeBytes
    unless $NoTo || $NoSize || $NoBE;
    $tables[14] = $pos, $tables[15] = $ToSizeBytes, $pos += $ToSizeBytes
    unless $NoTo || $NoSize || $NoLE;
  }

  print OUTFILE pack("N", $_) foreach @tables;

  print "Total bytes for output: $pos.\n" if $Verbose;
  
  # OUTPUT BINARY TABLES
  unless ($NoFrom)
  {
    if ($Bits == 8) 
    {
      Output8bitFromUCS("n") unless $NoBE;
      Output8bitFromUCS("v") unless $NoLE;
    }
    else
    {
      unless ($NoSpeed)
      {
        OutputSpeed("from_ucs", "n") unless $NoBE;
        OutputSpeed("from_ucs", "v") unless $NoLE;
      }
      unless ($NoSize)
      {
        OutputSize("from_ucs", "n") unless $NoBE;
        OutputSize("from_ucs", "v") unless $NoLE;
      }
    }
  }
  unless ($NoTo)
  {
    if ($Bits == 8) 
    {
      Output8bitToUCS("n") unless $NoBE;
      Output8bitToUCS("v") unless $NoLE;
    }
    else
    {
      unless ($NoSpeed)
      {
        OutputSpeed("to_ucs", "n") unless $NoBE;
        OutputSpeed("to_ucs", "v") unless $NoLE;
      }
      unless ($NoSize)
      {
        OutputSize("to_ucs", "n") unless $NoBE;
        OutputSize("to_ucs", "v") unless $NoLE;
      }
    }
  }
}

close INFILE;
close OUTFILE;
exit 0;


# ##############################################################################
#
# SUPPLEMENTARY FUNCTIONS
#
# ##############################################################################


# =============================================================================
#
# Generate 8bit "to_ucs" table. Store table data in %ToSpeedTbl hash.
# Store table size in $ToSpeedBytes scalar.
#
# =============================================================================
sub Generate8bitToUCS()
{
  for (my $i = 0; $i <= 255; $i++)
  {
    $ToSpeedTbl[$i] = defined $CCSUCS{$i} ? $CCSUCS{$i} : $InvCode;
  }
  $ToSpeedBytes = 256*2;
}


# =============================================================================
#
# Generate speed-optimized table.
#
# Parameter 1: 
#    "to_ucs"   - generate "to_ucs" table, store table data in @ToSpeedTbl
#                 array, store table size in $ToSpeedBytes scalar.
#    "from_ucs" - generate "from_ucs" table, store table data in @FromSpeedTbl
#                 array, store table size in $FromSpeedBytes scalar.
#
# Data is written to @ToSpeedTbl or @FromSpeedTbl (@map) table and has the
# following format:
# $table[0] - 256-element array (control block);
# $table[1 .. $#table] - 256-element arrays (data blocks).
#
# =============================================================================
sub GenerateSpeed($)
{
  my $map;
  my $tbl;
  my $bytes;
  
  if ($_[0] eq "to_ucs")
  {
    $map = \%CCSUCS;
    $tbl = \@ToSpeedTbl;
    $bytes = \$ToSpeedBytes;
  }
  elsif ($_[0] eq "from_ucs")
  {
    $map = \%UCSCCS;
    $tbl = \@FromSpeedTbl;
    $bytes = \$FromSpeedBytes;
  }
  else
  {
    Err "Internal script error in GenerateSpeed()\n";
  }
  
  # Identify unused blocks
  my @busy_blocks;
  $busy_blocks[$_ >> 8] = 1 foreach (keys %$map);

  # GENERATE FIRST 256-ELEMENT CONTROL BLOCK
  for (my $i = 0,
       my $idx = $Bits == 16 ? 0 : 256 + $Hdr8bitFromUCS;
       $i <= 0xFF; $i++)
  {
    $tbl->[0]->[$i] = $busy_blocks[$i] ? $idx += 256 : undef;
  }

  # GENERATE DATA BLOCKS
  $$bytes = 0;
  for (my $i = 0; $i <= 0xFF; $i++)
  {
    next unless $busy_blocks[$i];
    $$bytes += 256;
    for (my $j = 0; $j <= 0xFF; $j++)
    {
      $tbl->[$i+1]->[$j] = $map->{($i << 8) | $j};
    }
  } 
  $$bytes *= 2 if $Bits == 16;
  $$bytes += $Hdr8bitFromUCS if $Bits == 8;
  $$bytes += 512;
}


# =============================================================================
#
# Generate 16bit size-optimized table.
#
# Parameter 1: 
#    "to_ucs"   - generate "to_ucs" table, store table data in @ToSizeTbl
#                 array, store table size in $ToSizeBytes scalar.
#    "from_ucs" - generate "from_ucs" table, store table data in @FromSizeTbl
#                 array, store table size in $FromSizeBytes scalar.
#
# Data is written to @ToSizeTbl or @FromSizeTbl (@map) table and has the
# following format:
# $table[0] - number of ranges;
# $table[1] - number of unranged codes;
# $table[2] - unranged codes index in resulting array;
# $table[3]->[0 .. $table[0]] - array of arrays of ranges:
#     $table[3]->[x]->[0] - first code;
#     $table[3]->[x]->[1] - last code;
#     $table[3]->[x]->[2] - range index in resulting array;
# $table[4]->[0 .. $table[0]] - array of arrays of ranges content;
# $table[5]->[0 .. $table[1]] - array of arrays of unranged codes;
#     $table[5]->[x]->[0] - CCS code;
#     $table[5]->[x]->[0] - UCS code;
#
# =============================================================================
sub Generate16bitSize($)
{
  my $map;
  my $tbl;
  my $bytes;
  
  if ($_[0] eq "to_ucs")
  {
    $map = \%CCSUCS;
    $tbl = \@ToSizeTbl;
    $bytes = \$ToSizeBytes;
  }
  elsif ($_[0] eq "from_ucs")
  {
    $map = \%UCSCCS;
    $tbl = \@FromSizeTbl;
    $bytes = \$FromSizeBytes;
  }
  else
  {
    Err "Internal script error  Generate16bitSize()\n";
  }

  # CREATE LIST OF RANGES.
  my @codes = sort {$a <=> $b} keys %$map;
  my @ranges;  # Code ranges
  my @range;   # Current working range
  foreach (@codes)
  {
    if (not @range or $_ - 1 == $range[$#range])
    {
      push @range, $_;
    }
    else
    {
      my @tmp = @range;
      push @ranges, \@tmp;
      undef @range;
      redo;
    }
  }
  # Add Last range too
  if (@range)
  {
    my @tmp = @range;
    push @ranges, \@tmp;
  }

  # OPTIMIZE LIST OF RANGES.
  my $r = 0; # Working range number
  while (1)
  {
    last if ($r == $#ranges);

    my @r1 = @{$ranges[$r]};
    my @r2 = @{$ranges[$r + 1]};

    # Calculate how many array entries two ranges need
    my ($s1, $s2);

    if ($#r1 == 0)
    { $s1 = 2; }
    elsif ($#r1 == 1)
    { $s1 = 4; }
    else
    { $s1 = $#r1 + 1 + 3; }
    
    if ($#r2 == 0)
    { $s2 = 2; }
    elsif ($#r2 == 1)
    { $s2 = 4; }
    else
    { $s2 = $#r2 + 1 + 3; }

    my $two = $s1 + $s2;

    # Calculate how many array entries will be needed if we join them
    my $one = $r2[$#r2] - $r1[0] + 1 + 3;

    $r += 1, next if ($one > $two);
    
    # Join ranges
    my @r; # New range.
    push @r, $_ foreach (@r1);
    for (my $i = $r1[$#r1]+1; $i < $r2[0]; $i++)
    {
      push @r, undef; 
    }
    push @r, $_ foreach (@r2);
    $ranges[$r] = \@r;
    splice @ranges, $r+1, 1;
  }

  # SEPARATE RANGED AND UNRANGED CODES. SPLIT 2-CODES RANGES ON 2 UNRANGED.
  my @unranged;
  foreach (@ranges)
  {
    if ($#$_ == 0)
    {
      push @unranged, $$_[0];
      undef $_;
    }
    elsif ($#$_ == 1)
    {
      push @unranged, $$_[0];
      push @unranged, $$_[1];
      undef $_;
    }
  }

  # DELETE UNUSED ELEMENTS
  for (my $i = 0; $i <= $#ranges; $i++)
  {
    splice @ranges, $i--, 1 unless defined $ranges[$i];
  }

  # CALCULATE UNRANGED CODES ARRAY INDEX
  my $idx = 3 + ($#ranges + 1)*3;
  $idx += $#$_ + 1 foreach @ranges;

  # COMPOSE TABLE
  $tbl->[0] = $#ranges + 1;   # Number of ranges
  $tbl->[1] = $#unranged + 1; # Number of unranged codes
  $tbl->[2] = $idx;           # Array index of unranged codes
  
  # Generate ranges list
  $idx = 3 + ($#ranges + 1)*3; # First range data index
  $$bytes = $idx*2;
  my $num = 0;
  foreach (@ranges)
  {
    $tbl->[3]->[$num]->[0] = $_->[0];
    $tbl->[3]->[$num]->[1] = $_->[$#$_];
    $tbl->[3]->[$num]->[2] = $idx;
    $idx += $#$_ + 1;
    $num += 1;
  }

  # Generate ranges content
  $num = 0;
  foreach (@ranges)
  {
    for (my $i = 0; $i <= $#$_; $i++)
    {
      $tbl->[4]->[$num]->[$i] = defined $_->[$i] ? $map->{$_->[$i]} : undef;
    }
    $num += 1;
    $$bytes += ($#$_ + 1)*2;
  }

  # Generate unranged codes list
  $num = 0;
  foreach (@unranged)
  {
    $tbl->[5]->[$num]->[0] = $_;
    $tbl->[5]->[$num]->[1] = $map->{$_};
    $num += 1;
  }

  $$bytes += ($#unranged + 1)*4;
}  


# =============================================================================
#
# Output 8bit "to UCS" table. Output table's source code if $Source
# and table's binary data if !$Source.
# 
# Parameter 1: Not used when sources are output. Output BE binary if 'n' and
#              LE binary if 'v'.
#
# =============================================================================
sub Output8bitToUCS(;$)
{
  my $endian = $_[0];
  my $br = 0;

  printf "Output%s 8-bit UCS -> $CCSName table ($ToSpeedBytes bytes).\n",
         defined $endian ? ($endian eq 'n' ? 
                 " Big Endian" : " Little Endian") : "" if $Verbose;
  if ($Source)
  {
    # Output heading information
    printf OUTFILE
"/*
 * 8-bit $CCSName -> UCS table ($ToSpeedBytes bytes).
 * $Separator
 */
#if defined ($GuardToUCS)

static _CONST __uint16_t
${VarToUCSSpeed}\[] =
{\n\t";
  }

  if ($Source)
  {
    foreach (@ToSpeedTbl)
    {
      $br += 1;
      if ($_ != $InvCode)
      {
        if ($_ != $TmpLost)
        {
          printf OUTFILE "0x%.4X,", $_;
        }
        else
        {
          print OUTFILE "$MacroLostCode,";
        }
      }
      else
      {
        print OUTFILE "$MacroInvCode,";
      }
      print(OUTFILE "\n\t"), $br = 0 unless $br % 8;
    }
    print OUTFILE "\n};\n\n#endif /* $GuardToUCS */\n\n";
  }
  else
  {
    foreach (@ToSpeedTbl)
    {
      print OUTFILE pack($endian, $_ == $TmpLost ? $LostCode : $_);
    }
  }
}


# =============================================================================
#
# Output 8bit "from UCS" table. Output table's source code if $Source
# and table's binary data if !$Source.
# 
# Parameter 1: Not used when sources are output. Output BE binary if 'n' and
#              LE binary if 'v'.
#
# =============================================================================
sub Output8bitFromUCS(;$)
{
  my $endian = $_[0];

  printf "Output%s 8-bit $CCSName -> UCS table ($FromSpeedBytes bytes).\n",
         defined $endian ? ($endian eq 'n' ? 
                 " Big Endian" : " Little Endian") : "" if $Verbose;
  if ($Source)
  {
    print OUTFILE
"/*
 * 8-bit UCS -> $CCSName speed-optimized table ($FromSpeedBytes bytes).
 * $Separator
 */

#if defined ($GuardFromUCS)

static _CONST unsigned char
${VarFromUCSSpeed}\[] =
{
";
  }

  # SAVE 0xFF MAPPING.
  if ($Source)
  {
    printf OUTFILE "\tW(0x%.4X), /* Real 0xFF mapping. 0xFF is used "
                 . "to mark invalid codes */\n", $FFMap;
  }
  else
  {
    print OUTFILE pack($endian, $FFMap);
  }

  # OUTPUT HEADING BLOCK (ALWAYS 16 BIT)
  if ($Source)
  {
    my $count = 0;
    print OUTFILE "\t/* Heading Block */";
    for (my $i = 0, my $br = 0; $i < 256; $br = ++$i % 4)
    {
      print OUTFILE "\n\t" unless $br;
      if (defined $FromSpeedTbl[0]->[$i])
      {
        printf OUTFILE "W(0x%.4X),", $FromSpeedTbl[0]->[$i];
      }
      else
      {
        print OUTFILE "W($MacroInvBlock),";
      }
    }
  }
  else
  {
    print OUTFILE pack($endian, defined $_ ? $_ : $InvBlock)
    foreach @{$FromSpeedTbl[0]};
  }

  if ($Source)
  {
    my $index = 512 + $Hdr8bitFromUCS;
    for (my $blk = 1; $blk <= $#FromSpeedTbl; $blk++)
    {
      next unless defined $FromSpeedTbl[$blk];
      printf OUTFILE "\n\t/* Block $blk, Array index 0x%.4X */", $index;
      $index += 256;
      for (my $i = 0, my $br = 0; $i < 256; $i++, $br = $i % 8)
      {
        print OUTFILE "\n\t" unless $br;
        my $code = $FromSpeedTbl[$blk]->[$i];
        if (!defined $code)
        {
          printf OUTFILE "0x%.2X,", $InvCode8bit;
        }
        else
        {
          printf OUTFILE "0x%.2X,", $code == $TmpLost ? $LostCode : $code;
        }
      }
    }
    print OUTFILE "\n};\n\n#endif /* $GuardFromUCS */\n\n";
  }
  else
  {
    for (my $blk = 1; $blk <= $#FromSpeedTbl; $blk++)
    {
      next unless defined $FromSpeedTbl[$blk];
      for (my $i = 0, my $br = 0; $i < 256; $br = ++$i % 8)
      {
        my $code = $FromSpeedTbl[$blk]->[$i];
        if (!defined $code)
        {
          printf OUTFILE pack 'C', $InvCode8bit;
        }
        else
        {
          print OUTFILE $code == $TmpLost ? pack('C', $LostCode) 
                                          : pack('C', $code);
        }
      }
    }
  }
}


# =============================================================================
#
# Output 16bit Speed-optimized table. Output table's source code if $Source
# and table's binary data if !$Source.
# 
# Parameter 1: 
#    "to_ucs"   - Output "to_ucs" table.
#    "from_ucs" - Output "from_ucs" table.
# Parameter 2:    Not used when sources are output. Output BE binary if 'n' and
#                 LE binary if 'v'.
#
# =============================================================================
sub OutputSpeed($;$)
{
  my $endian = $_[1];
  my $tbl;
  my ($direction, $optimiz, $e, $bytes);
  $optimiz = $Bits == 16 ? " speed-optimized" : "";
  $e = $endian ? ($endian eq 'n' ? " Big Endian" : " Little Endian") : "";
  if ($_[0] eq "to_ucs")
  {
    $tbl = \@ToSpeedTbl;
    $direction = " $CCSName -> UCS";
    $bytes = $ToSpeedBytes;

    if ($Source)
    {
      print OUTFILE
"/*
 * 16-bit $CCSName -> UCS speed-optimized table ($ToSpeedBytes bytes).
 * $Separator
 */
#if defined ($GuardToUCS) \\
 && !($GuardSize)

static _CONST __uint16_t
${VarToUCSSpeed}\[] =
{
";
    }
  }
  elsif ($_[0] eq "from_ucs")
  {
    $tbl = \@FromSpeedTbl;
    $direction = " UCS -> $CCSName";
    $bytes = $FromSpeedBytes;
    
    if ($Source)
    {
      print OUTFILE
"/*
 * 16-bit UCS -> $CCSName speed-optimized table ($FromSpeedBytes bytes).
 * $Separator
 */

#if defined ($GuardFromUCS) \\
 && !($GuardSize)

static _CONST __uint16_t
${VarFromUCSSpeed}\[] =
{
";
    }
  }
  else
  {
    Err "Internal script error  Output16bitSpeed()\n";
  }

  printf "Output%s 16-bit%s%s table (%d bytes).\n",
  $e, $direction, $optimiz, $bytes if $Verbose;

  # OUTPUT HEADING BLOCK (ALWAYS 16 BIT)
  if ($Source)
  {
    my $count = 0;
    print OUTFILE "\t/* Heading Block */";
    for (my $i = 0, my $br = 0; $i < 256; $br = ++$i % 8)
    {
      print OUTFILE "\n\t" unless $br;
      if (defined $tbl->[0]->[$i])
      {
        printf OUTFILE "0x%.4X,", $tbl->[0]->[$i];
      }
      else
      {
        print OUTFILE "$MacroInvBlock,";
      }
    }
  }
  else
  {
    print OUTFILE pack($endian, defined $_ ? $_ : $InvBlock)
    foreach @{$tbl->[0]};
  }

  # OUTPUT OTHER BLOCKS
  if ($Source)
  {
    my $index = 256;
    for (my $blk = 1; $blk <= $#$tbl; $blk++)
    {
      next unless defined $tbl->[$blk];
      printf OUTFILE "\n\t/* Block $blk, Array index 0x%.4X */", $index;
      $index += 256;
      for (my $i = 0, my $br = 0; $i < 256; $br = ++$i % 8)
      {
        print OUTFILE "\n\t" unless $br;
        my $code = $tbl->[$blk]->[$i];
        print OUTFILE defined $code ? 
            ($code == $TmpLost ? $MacroLostCode : sprintf "0x%.4X", $code)
                                     : $MacroInvCode, ",";
      }
    }
  }
  else
  {
    for (my $blk = 1; $blk <= $#$tbl; $blk++)
    {
      next unless defined $tbl->[$blk];
      for (my $i = 0, my $br = 0; $i < 256; $br = ++$i % 8)
      {
        my $code = $tbl->[$blk]->[$i];
        print OUTFILE pack($endian, 
          defined $code ? ($code == $TmpLost ? $LostCode : $code) : $InvCode);
      }
    }
  }

  if ($Source)
  {
    if ($_[0] eq "to_ucs")
    {
      print OUTFILE
"
};

#endif /* $GuardToUCS && !$GuardSize */

";
    }
    else
    {
      print OUTFILE
"
};

#endif /* $GuardFromUCS && !$GuardSize */

";
    }
  }
}

# =============================================================================
#
# Output 16bit Size-optimized table. Output table's source code if $Source
# and table's binary data if !$Source.
# 
# Parameter 1: 
#    "to_ucs"   - Output "to_ucs" table.
#    "from_ucs" - Output "from_ucs" table.
# Parameter 2:    Not used when sources are output. Output BE binary if 'n' and
#                 LE binary if 'v'.
#
# =============================================================================
sub OutputSize($;$)
{
  my $endian = $_[1];
  my $tbl;
  my ($direction, $optimiz, $e, $bytes);
  $optimiz = $Bits == 16 ? " size-optimized" : "";
  $e = $endian ? ($endian eq 'n' ? " Big Endian" : " Little Endian") : "";
  if ($_[0] eq "to_ucs")
  {
    $tbl = \@ToSizeTbl;
    $direction = " $CCSName -> UCS";
    $bytes = $ToSizeBytes;

    if ($Source)
    {
      print OUTFILE
"/*
 * 16-bit $CCSName -> UCS size-optimized table ($ToSizeBytes bytes).
 * $Separator
 */
#if defined ($GuardToUCS) \\
 && ($GuardSize)

static _CONST __uint16_t
${VarToUCSSize}\[] =
{
";
    }
  }
  elsif ($_[0] eq "from_ucs")
  {
    $tbl = \@FromSizeTbl;
    $direction = " UCS -> $CCSName";
    $bytes = $FromSizeBytes;
    if ($Source)
    {
      print OUTFILE
"/*
 * 16-bit UCS -> $CCSName size-optimized table ($FromSizeBytes bytes).
 * $Separator
 */

#if defined ($GuardFromUCS) \\
 && ($GuardSize)

static _CONST __uint16_t
${VarFromUCSSize}\[] =
{
";
    }
  }
  else
  {
    Err "Internal script error  Output16bitSize()\n";
  }

  printf "Output%s 16-bit%s%s table (%d bytes).\n",
  $e, $direction, $optimiz, $bytes if $Verbose;

  # OUTPUT FIRST 3 ELEMENTS
  if ($Source)
  {
    printf OUTFILE "\t0x%.4X, /* Ranges number */\n", $tbl->[0];
    printf OUTFILE "\t0x%.4X, /* Unranged codes number */\n", $tbl->[1];
    printf OUTFILE "\t0x%.4X, /* First unranged code index */\n", $tbl->[2];
  }
  else
  {
    printf OUTFILE pack $endian, $tbl->[0];
    printf OUTFILE pack $endian, $tbl->[1];
    printf OUTFILE pack $endian, $tbl->[2];
  }

  my $idx = 0;
  # OUTPUT RANGES
  if ($Source)
  {
    print OUTFILE "\t/* Ranges list: first code, last Code, array index. */\n";
    for (my $range = 0; $range <= $#{$tbl->[3]}; $range++)
    {
      printf OUTFILE "\t/* Array index: 0x%.4X */ 0x%.4X, 0x%.4X, 0x%.4X,\n",
             $idx += 3,
             $tbl->[3]->[$range]->[0],
             $tbl->[3]->[$range]->[1],
             $tbl->[3]->[$range]->[2];
    }
  }
  else
  {
    for (my $range = 0; $range <= $#{$tbl->[3]}; $range++)
    {
      print OUTFILE pack($endian, $tbl->[3]->[$range]->[0]),
                    pack($endian, $tbl->[3]->[$range]->[1]),
                    pack($endian, $tbl->[3]->[$range]->[2]);
    }
  }
  $idx += 3;

  # OUTPUT RANGES CONTENT
  if ($Source)
  {
    print OUTFILE "\t/* Ranges content */";
    for (my $range = 0; $range <= $#{$tbl->[3]}; $range++)
    {
      printf OUTFILE "\n\t/* Range 0x%.4X - 0x%.4X, array index: 0x%.4X */",
             $tbl->[3]->[$range]->[0], $tbl->[3]->[$range]->[1], $idx;
             $idx += $tbl->[3]->[$range]->[1] - $tbl->[3]->[$range]->[0] + 1;
      for (my $elt = 0, my $br = 0;
           $elt <= $#{$tbl->[4]->[$range]};
           $br = ++$elt % 8)
      {
        print OUTFILE "\n\t" unless $br;
        if (defined $tbl->[4]->[$range]->[$elt])
        {
          if ($tbl->[4]->[$range]->[$elt] != $TmpLost)
          {
            printf OUTFILE "0x%.4X,", $tbl->[4]->[$range]->[$elt];
          }
          else
          {
            print OUTFILE "$MacroLostCode,";
          }
        }
        else
        {
          print OUTFILE "$MacroInvCode,";
        }
      }
    }
  }
  else
  {
    for (my $range = 0; $range <= $#{$tbl->[3]}; $range++)
    {
      for (my $elt = 0; $elt <= $#{$tbl->[4]->[$range]}; $elt++)
      {
        if (defined $tbl->[4]->[$range]->[$elt])
        {
          if ($tbl->[4]->[$range]->[$elt] != $TmpLost)
          {
            print OUTFILE pack $endian, $tbl->[4]->[$range]->[$elt];
          }
          else
          {
            print OUTFILE pack $endian, $LostCode;
          }
        }
        else
        {
          print OUTFILE pack $endian, $InvCode;
        }
      }
    }
  }

  # OUTPUT UNRANGED CODES
  if ($Source)
  {
    printf OUTFILE "\n\t/* Unranged codes (%d codes) */", $#{$tbl->[4]} + 1;
    for (my $i = 0; $i <= $#{$tbl->[5]}; $i++)
    {
      printf OUTFILE "\n\t/* Array index: 0x%.4X */ 0x%.4X,0x%.4X,",
             $idx, $tbl->[5]->[$i]->[0], $tbl->[5]->[$i]->[1];
    }
  }
  else
  {
    for (my $i = 0; $i <= $#{$tbl->[5]}; $i++)
    {
      print OUTFILE pack($endian, $tbl->[5]->[$i]->[0]),
                    pack($endian, $tbl->[5]->[$i]->[1]);
    }
  }

  if ($Source)
  {
    if ($_[0] eq "to_ucs")
    {
      print OUTFILE
"
};

#endif /* $GuardToUCS && $GuardSize */

";
    }
    else
    {
      print OUTFILE
"
};

#endif /* $GuardFromUCS && $GuardSize */

";
    }
  }
}


# =============================================================================
#
# Parse command line options
#
# =============================================================================
sub ProcessOptions()
{
  my $help_opt    = 'h'; # Print help option
  my $input_opt   = 'i'; # Input file name option
  my $output_opt  = 'o'; # Output file name option
  my $source_opt  = 'S'; # Generate C source file option
  my $enc_opt     = 'N'; # Encoding name
  my $plane_opt   = 'p'; # Plane number
  my $verbose_opt = 'v'; # Verbose output
  my $ccscol_opt  = 'x'; # Encoding's column number
  my $ucscol_opt  = 'y'; # UCS column number
  my $nosize_opt  = 'l'; # Don't generate size-optimized tables
  my $nospeed_opt = 'b'; # Don't generate speed-optimized tables
  my $nobe_opt    = 'B'; # Don't generate big-endian tables
  my $nole_opt    = 'L'; # Don't generate big-endian tables
  my $noto_opt    = 't'; # Don't generate "to_ucs" table
  my $nofrom_opt  = 'f'; # Don't generate "from_ucs" table

  my %args;              # Command line arguments found by getopts()

  my $getopts_string = 
     "$help_opt$source_opt$enc_opt:$verbose_opt$input_opt:$output_opt:$plane_opt:"
   . "$nosize_opt$nospeed_opt$nobe_opt$nole_opt$noto_opt$nofrom_opt$ccscol_opt:"
   . "$ucscol_opt:";

  getopts($getopts_string, \%args) || Err "getopts() failed: $!.\n", 1;

  # Print usage rules and exit.
  if ($args{$help_opt})
  {
    print<<END
Usage:
     -$help_opt - this help message;
     -$input_opt - input file name (required);
     -$output_opt - output file name;
     -$enc_opt - CCS or encoding name;
     -$plane_opt - plane number (high 16 bits) to use (in hex);
     -$source_opt - generate C source file;
     -$nospeed_opt - don't generate speed-optimized tables (binary files only);
     -$nosize_opt - don't generate size-optimized tables (binary files only);
     -$nobe_opt - don't generate Big Endian tables (binary files only);
     -$nole_opt - don't generate Little Endian tables (binary files only);
     -$noto_opt - don't generate "to_ucs" table;
     -$nofrom_opt - don't generate "from_ucs" table;
     -$ccscol_opt - encoding's column number;
     -$ucscol_opt - UCS column number;
     -$verbose_opt - verbose output.

If output file name isn't specified, <infile>.c (for sources) or
<infile>.cct (for binaries) is assumed.
If encoding name isn't specified <infile> is assumed.
<infile> is normalized (small letters, "-" are substituted by "_") input file
name base (no extension). For example, for Koi8-r.txt input file, <infile>
is koi8_r.            
END
;
    exit 0;
  }

  $Verbose   = $args{$verbose_opt};
  $Source    = $args{$source_opt};
  $NoSpeed   = $args{$nospeed_opt};
  $NoSize    = $args{$nosize_opt};
  $NoBE      = $args{$nobe_opt};
  $NoLE      = $args{$nole_opt};  
  $NoFrom    = $args{$nofrom_opt};
  $NoTo      = $args{$noto_opt};
  $CCSCol    = $args{$ccscol_opt};
  $UCSCol    = $args{$ucscol_opt};
  $Plane     = $args{$plane_opt};
  $InFile    = $args{$input_opt};
  $OutFile   = $args{$output_opt};
  $CCSName   = $args{$enc_opt};

  Err "Error: input file isn't defined. Use -$help_opt for help.\n", 1
  unless $InFile;
  
  unless ($OutFile)
  {
    # Construct output file name
    $OutFile = $InFile;
    $OutFile =~ s/(.*\/)*([0-9a-zA-Z-_]*)(\..*)$/\L$2/;
    $OutFile =~ tr/-/_/;
    if ($Source)
    {
      $OutFile = "$OutFile.c";
    }
    else
    {
      $OutFile = "$OutFile.cct"
    }
  }
  
  unless ($CCSName)
  {
    # Construct CCS name
    $CCSName = $InFile;
    $CCSName =~ s/(.*\/)*([0-9a-zA-Z-_]*)(\..*)$/\L$2/;
    $CCSName =~ tr/-/_/;
  }

  Err "-$nosize_opt option can't be used with -$nospeed_opt option "
    . "simultaniously.\n", 1 if $NoSpeed && $NoSize;

  Err "-$nobe_opt option can't be used with -$nole_opt option "
    . "simultaniously.\n", 1 if $NoBE && $NoLE;
  
  Err "-$noto_opt option can't be used with -$nofrom_opt option"
    . "simultaniously.\n", 1 if $NoTo && $NoFrom;

  Err "-$nosize_opt, -$nospeed_opt, -$nobe_opt -$nole_opt "
    . "-$noto_opt and -$nofrom_opt "
    . "options can't be used with -$source_opt option.\n"
    . "Source code always contains both speed- and size-optimized "
    . "tables in System Endian. Use -$help_opt for help.\n", 1
  if $Source and $NoSpeed || $NoSize || $NoBE || $NoLE || $NoTo || $NoFrom;
  
  if (!$CCSCol && !$UCSCol)
  {
    $CCSCol = 0;
    $UCSCol = 1;
  }
  elsif ($CCSCol && $UCSCol)
  {
    Err "Column number should be >= 0\n", 1 if ($CCSCol <= 0 or $UCSCol <= 0);
    $CCSCol -= 1;
    $UCSCol -= 1;
  }
  else
  {
    Err "Please, define both CCS and UCS column numbers\n", 1;
  }

  if ($Verbose)
  {
    print  "Use $InFile file for input.\n",
           "Use $OutFile file for output.\n",
           "Use $CCSName as CCS name.\n";
    print  "Generate C source file.\n"                if $Source;
    print  "Generate binary file.\n"                  if !$Source;
    printf "Use plane N 0x%.4X.\n", hex $Plane if defined $Plane;
    printf "Use column N $CCSCol for $CCSName.\n";
    printf "Use column N $UCSCol for UCS.\n";
    print  "Don't generate size-optimized tables.\n"  if $NoSize;
    print  "Don't generate speed-optimized tables.\n" if $NoSpeed;
    print  "Don't generate big-endian tables.\n"      if $NoBE;
    print  "Don't generate little-endian tables.\n"   if $NoLE;
    print  "Don't generate \"to_ucs\" table.\n"       if $NoTo;
    print  "Don't generate \"from_ucs\" table.\n"     if $NoFrom;
  }
  
  return;
}


# =============================================================================
#
# Print error message, close all and exit
#
# Parameter 1: error message
# Parameter 2: don't delete output file if > 1
#
# =============================================================================
sub Err($;$)
{
  print STDERR "$_[0]";
  close INFILE;
  close OUTFILE;
  unlink $OutFile unless $_[1];
  
  exit 1;
}