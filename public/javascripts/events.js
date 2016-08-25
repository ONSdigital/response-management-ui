$(document).ready(function() {
  $('#eventtext').keyup(function() {
    var remaining = 250 - $(this).val().length;
    $('#chars').text(remaining);
  });
});
