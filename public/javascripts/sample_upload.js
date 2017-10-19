$(document).ready(function(event) {

  $('input:file').change(
    function(){
        if ($(this).val()) {
            $('input:submit').attr('disabled',false);
        }
      }
  );

});
