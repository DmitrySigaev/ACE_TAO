package GNUACEWorkspaceCreator;

# ************************************************************
# Description   : A GNU Workspace (GNUmakefile) creator for ACE
# Author        : Chad Elliott
# Create Date   : 5/13/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

use GNUACEProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub generate_implicit_project_dependencies {
  #my($self) = shift;
  return 1;
}


sub workspace_file_name {
  my($self) = shift;
  return $self->get_modified_workspace_name('GNUmakefile', '');
}


sub workspace_per_project {
  #my($self) = shift;
  return 1;
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '# -*- makefile -*-', $crlf,
            '#-------------------------------------------------------------------------', $crlf,
            '#       GNU ACE Workspace', $crlf,
            '#', $crlf,
            '# @file GNUmakefile', $crlf,
            '#', $crlf,
            '# $Id $', $crlf,
            '#', $crlf,
            '# This file was automatically generated by MPC.  Any changes made ', $crlf,
            '# directly to this file will be lost the next time it is generated.', $crlf,
            '#', $crlf,
            '#-------------------------------------------------------------------------', $crlf,
            'MAKEFILE = GNUmakefile', $crlf;
}


sub write_comps {
  my($self)    = shift;
  my($fh)      = shift;
  my($crlf)    = $self->crlf();
  my(%targnum) = ();
  my($pjs)     = $self->get_project_info();
  my(@list)    = $self->number_target_deps($self->get_projects(),
                                           $pjs, \%targnum);

  ## Print out some preliminary information
  print $fh $crlf,
            "ifeq (\$(findstring k,\$(MAKEFLAGS)),k)$crlf",
            "  KEEP_GOING = -$crlf",
            "endif$crlf$crlf",
            "include \$(ACE_ROOT)/include/makeinclude/macros.GNU$crlf",
            $crlf;

  ## Determine the ordering of the sub-directories
  my(@dirs)  = ();
  my(%found) = ();
  foreach my $file (reverse @list) {
    my($dir) = $self->get_first_level_directory($file);
    if ($dir ne '.') {
      if (!defined $found{$dir}) {
        $found{$dir} = 1;
        unshift(@dirs, $dir);
      }
    }
  }

  ## Store the local projects in a separate list
  my(@lprj) = ();
  foreach my $project (@list) {
    if ($project !~ /\//) {
      push(@lprj, $project);
    }
  }

  if ($#lprj >= 0) {
    ## Print out the all target first.  This will allow multiple projects
    ## within the same directory to build in parallel.
    print $fh 'all:';
    foreach my $project (@lprj) {
      print $fh ' ', $$pjs{$project}->[0];
    }
    print $fh $crlf;
    if ($#dirs > -1) {
      foreach my $dir (@dirs) {
        print $fh "\t\$(KEEP_GOING)\@cd $dir && \$(MAKE) \$(\@)$crlf";
      }
    }

    ## Print out each target separately.  Make can decide on which
    ## targets can be built in parallel because we add the local
    ## dependencies.
    foreach my $project (@lprj) {
      print $fh $crlf, '.PHONY: ', $$pjs{$project}->[0],
                $crlf, $$pjs{$project}->[0], ':';
      if (defined $targnum{$project}) {
        foreach my $number (@{$targnum{$project}}) {
          print $fh ' ', $$pjs{$list[$number]}->[0];
        }
      }
      print $fh $crlf,
                "\t\$(KEEP_GOING)\@\$(MAKE) -f $project$crlf";
    }
    print $fh $crlf,
              "REMAINING_TARGETS := \$(subst all, , \$(TARGETS_NESTED:.nested=))$crlf",
  }
  else {
    print $fh "REMAINING_TARGETS := \$(TARGETS_NESTED:.nested=)$crlf",
  }

  ## Print out the remaing targets.
  ## They will be handled serially by make.
  print $fh "\$(REMAINING_TARGETS):$crlf";
  foreach my $project (@lprj) {
    print $fh "\t\$(KEEP_GOING)\@\$(MAKE) -f $project \$(\@)$crlf";
  }
  if ($#dirs > -1) {
    foreach my $dir (@dirs) {
      print $fh "\t\$(KEEP_GOING)\@cd $dir && \$(MAKE) \$(\@)$crlf";
    }
  }
  print $fh $crlf;

  ## Backward compatibility.  This should eventually be removed.
  print $fh "reverseclean: realclean$crlf";
}

1;
