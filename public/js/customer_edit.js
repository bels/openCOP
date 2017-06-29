$(document).ready(function(){
	$("#password_form").validate();
	$("#password1").rules("add",{required: true});
	$("#password2").rules("add",{required: true});
	$("#password2").rules("add",{equalTo: "#password1"});

	$("#email_form").validate();
	$("#email1").rules("add",{required: true, email: true});
	$("#email2").rules("add",{required: true, email: true});
	$("#email2").rules("add",{equalTo: "#email1"});

	$('.change_form').submit(function(){
		resetLogout();
		$(this).find('#id').val($('#select_customer_select').val());
	});
});
