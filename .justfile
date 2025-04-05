_default:
  @just --list

fmt:
  fd --extension vhd --exec-batch vsg --fix -c .vsg-style.yml -f {}

check:
  fd --extension vhd --exec-batch vsg -c .vsg-style.yml -f {}

diff:
  diff run/output.txt run/output_ref.txt --unified --color=always --strip-trailing-cr --suppress-common-lines --report-identical-file

open:
  vivado -nojournal -nolog lab04_project/lab04_project.xpr
