$(document).keyup(function(event) {
  if ($("#postcode").is(":focus") && (event.keyCode == 13)) {
    var postcode = $("#postcode").val();
    if (postcode.length > 0) {
      postcode = postcode.replace(/\s+|\/+/g, '').toLowerCase();

      // CTPA-477 Need to URI encode the postcode search string.
      window.location = "/postcodes/" + encodeURIComponent(postcode);
    }
  }
});
