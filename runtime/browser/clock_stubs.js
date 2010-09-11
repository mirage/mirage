function unix_gettimeofday() {
  var t = new Date();
  return t.getTime() / 1000;
}

function unix_block_domain(t) {
  console.log("unix_block_domain: " + t);
}
