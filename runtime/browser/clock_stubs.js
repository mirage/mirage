function unix_gettimeofday() {
  var t = new Date();
  return t.getTime() / 1000;
}
