$(document).keyup(function(event) {
  if ($("#questionnaireid").is(":focus") && (event.keyCode == 13)) {
    var questionnaireid = $("#questionnaireid").val();
    if (questionnaireid.length > 0) {
      window.location = "/questionnaires/" + questionnaireid;
    }
  }
});
