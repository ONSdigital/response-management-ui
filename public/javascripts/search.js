$(document).keyup(function(event) {
  if ($("#sampleunitref").is(":focus") && (event.keyCode == 13)) {
    var sampleunitref = $("#sampleunitref").val();
    if (sampleunitref.length > 0) {
      // postcode = postcode.replace(/\s+|\/+/g, '').toLowerCase();

      // CTPA-477 Need to URI encode the postcode search string.
      window.location = "/sampleunitref/" + sampleunitref + "/cases";
    }
  }
});
