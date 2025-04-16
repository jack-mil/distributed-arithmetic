# This file provides some helpful command recipes for working with the Vivado project
# `Just` is a command recipe runner, inspired by `make`
# See https://just.systems/man/en/packages.html for installation options
# I recommend Scoop on Windows, but downloads are also available from Github Releases

_default:
  @just --list

fmt:
  fd --extension vhd --exec-batch vsg --fix -c .vsg-style.yml -f {} \;

check:
  fd --extension vhd --exec-batch vsg -c .vsg-style.yml -f {} \;

# Compare the simulation output to expected output
diff:
  cp *_project/*_project.sim/sim_1/behav/xsim/output.txt run/
  diff run/output.txt \
       run/output_ref.txt \
       --unified \
       --color=always \
       --strip-trailing-cr --suppress-common-lines \
       --report-identical-file

# Copy the desired implementation reports into report/
report:
  fd "^.*_utilization_placed|^.*power_routed|^.*_timing_summary_routed" \
    --extension rpt --no-ignore \
    --search-path *_project/ \
    --exec-batch cp {} ./report \;

# Recreate the project from tcl script
build:
  source ./env.sh && vivado -nojournal -nolog -notrace -mode batch -source ./*_project.tcl

# Delete ALL untracked git files
clean:
  #!/usr/bin/bash
  git clean -Xdn
  read -p "ARE YOU SURE? (y/n)" -n 1 -r
  echo # move to newline
  if [[ "$REPLY" =~ ^[Yy]$ ]] ; then git clean -Xdf; else echo "Aborted"; fi

# clean then build
clean-rebuild: clean build

# open the project in Vivado, and save on exit
open:
  source ./env.sh && exec vivado -nojournal -nolog -notrace -mode gui -source save_on_exit.tcl *_project/*_project.xpr
