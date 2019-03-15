MIN_COVERAGE=80

verify_coverage () {
  busted
  if [ -s luacov.report.out ]; then
    percent=$(grep Total luacov.report.out | awk -F" " '{print $4}')
    percent=${percent%.*}
    echo 'Code Coverage is at '$percent'%'
    if [ $percent -lt $MIN_COVERAGE ]; then
      return 1
    else
      return 0
    fi
  else
    return 1
  fi
  
}

if verify_coverage; then
  rm luacov.*
  exit 0
else
  rm luacov.*
  exit 1
fi
