$(document).ready(function(){
	$('#customer_admin_form').validate({
		rules: {
			first: "required",
			last: "required",
			email: {
				required: true,
				email: true
			},
			password1: "required",
			password2: {
				equalTo: "#password1"
			},
			site: "required"
		},
		submitHandler: function(form){
			$.blockUI({message: "Creating User"});
			form.submit();
			$.unblockUI();
		},
		messages: {
			first: "*",
			last: "*",
			email: "*",
			password1: "*",
			site: "*"
		}
	});
});
