_default:
  @just --list

fmt:
  fd --extension vhd --exec-batch vsg --fix -c .vsg-style.yml -f {}

check:
  fd --extension vhd --exec-batch vsg -c .vsg-style.yml -f {}

diff:
  diff <( head -n 100 run/output_updated.txt ) <( head -n 100 run/output_updated_ref.txt ) --suppress-common-lines --report-identical-file

open:
  vivado -nojournal -nolog lab04_project/lab04_project.xpr
