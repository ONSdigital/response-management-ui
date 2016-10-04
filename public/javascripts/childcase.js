$(document).ready(function() {
  document.getElementById("responsemode").onchange = function() {
    var responseMode = document.getElementById("responsemode");
    var responseModeSelected = responseMode.options[responseMode.selectedIndex].text;
    document.getElementById("delivery").disabled = true;
    document.getElementById("contactmode").disabled = true;
    document.getElementById('deliverymode').innerText = 'Delivery Mode:';
    if(responseModeSelected == "Online") {
        document.getElementById("contactmode").disabled = false;
    } else {
        document.getElementById("contactmode").disabled = true;
    }
  }

  document.getElementById("contactmode").onchange = function() {
    var contactmode = document.getElementById("contactmode");
    document.getElementById("delivery").disabled = true;
    document.getElementById('deliverymode').innerText = 'Delivery Mode:';
    var contactmodeSelected = contactmode.options[contactmode.selectedIndex].text;
    if(contactmodeSelected == "eMail") {
        document.getElementById("delivery").disabled = false;
        document.getElementById("deliverymode").innerText = 'Delivery Mode - Input Email Address:';
    } else if(contactmodeSelected == "SMS") {
        document.getElementById("delivery").disabled = false;
        document.getElementById("deliverymode").innerText = 'Delivery Mode: - Input Mobile Number:';
    }
  }

});
