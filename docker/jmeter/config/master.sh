export _TMP_DIR=/tmp
export _TEST_PLAN_DIR="$_TMP_DIR/tests"
export _OUTPUT_DIR="$_TMP_DIR/output"
export PATH=/opt/apache-jmeter-5.5/bin:$PATH

run() {
  pushd "$_TMP_DIR" || return
  rm -rf $_OUTPUT_DIR/*
  jmeter -n -t $_TEST_PLAN_DIR/test-plan.jmx -l $_OUTPUT_DIR/result.jtl -e -o $_OUTPUT_DIR/report -r
  popd > /dev/null
}
