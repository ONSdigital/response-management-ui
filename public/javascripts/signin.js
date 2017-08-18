$(document).ready(function(event) {
  $("#username").focus();
});

$(document).ready(function() {
    $("#search-form").submit(function( event ) {
      var sampleunitref = $("#sampleunitref").val();
      if (sampleunitref.length > 0) {
        window.location = "/sampleunitref/" + sampleunitref + "/cases";
      }
      event.preventDefault();
    });

});
