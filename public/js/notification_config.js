$(document).ready(function(){
	$('textarea').each(function(){
		if($(this).attr('textLength') >= 32){
			$(this).attr('rows','8').attr('cols','80');
		}
	});
	$('#notify_form').validate({
		rules: {
			email_password: "required",
			email_password2: {
				required: true,
				equalTo: "#email_password"
			}
		}
	});
	$('#update').bind('click',function(){
		if($('#notify_form').valid()){
			var o = $.toJSON($('#notify_form').serializeArray());
			$.ajax({
				type: 'POST',
				url: 'update_notification_config.pl',
				data: {object: o},
				success: function(){
					alert("Success");
				},
				error: function(data){
					alert("Error: " + data);
				}
			});
		}
	});
	
});
