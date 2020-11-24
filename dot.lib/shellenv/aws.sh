
cfn-lint() {
  docker run --rm -v "$(pwd):/data" cfn-python-lint:latest "/data/$1"
}
