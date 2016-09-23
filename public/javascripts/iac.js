$(document).ready(function() {
    document.getElementById("icMode").onchange = function() {
    alert("in here")
    var icmode = document.getElementById("icMode");
    //reset all selections to disabled
    document.getElementById("customeremail").disabled = true;
    document.getElementById("customercontact").disabled = true;
    document.getElementById("customername").disabled = true;
    var icmodeSelected = icmode.options[icmode.selectedIndex].text;
    if(icmodeSelected == "eMail") {
        document.getElementById("customeremail").disabled = false;
    } else if(icmodeSelected == "SMS") {
        document.getElementById("customercontact").disabled = false;
    } else if(icmodeSelected == "Letter") {
        document.getElementById("customername").disabled = false;
    }
  }

});
