$(document).ready(function() {
  $('#eventtext').keyup(function() {
  var length = $(this).val().length;
  var length = 100-length;
  $('#chars').text(length);
});
});
