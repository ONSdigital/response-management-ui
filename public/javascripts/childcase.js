$(document).ready(function() {
  document.getElementById("mode").onchange = function() {
    var mode = document.getElementById("mode");
    var modeSelected = mode.options[mode.selectedIndex].text;
    if(modeSelected == "Online") {
        document.getElementById("icMode").disabled = false;
    } else {
        document.getElementById("icMode").disabled = true;
    }
  }

  document.getElementById("icMode").onchange = function() {
    var icmode = document.getElementById("icMode");
    document.getElementById("customerparameter").disabled = true;
    var icmodeSelected = icmode.options[icmode.selectedIndex].text;
    if(icmodeSelected == "eMail") {
        document.getElementById("customerparameter").disabled = false;
        document.getElementById('customerparametername').innerText = 'Input Email Address:';
    } else if(icmodeSelected == "SMS") {
        document.getElementById("customerparameter").disabled = false;
        document.getElementById('customerparametername').innerText = 'Input Mobile Number:';
    } else if(icmodeSelected == "Letter") {
        document.getElementById("customerparameter").disabled = false;
        document.getElementById('customerparametername').innerText = 'Input Name:';
    }
  }

});
