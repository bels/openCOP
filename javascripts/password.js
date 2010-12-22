$(document).ready(function(){
	if($("#password_form").length){
		$("#password_form").validate();
		$("#old_password").rules("add",{required: true});
		$("#password1").rules("add",{required: true});
		$("#password2").rules("add",{required: true});
		$("#password2").rules("add",{equalTo: "#password1"});
	}

	$("#email_form").validate();
	$("#email1").rules("add",{required: true, email: true});
	$("#email2").rules("add",{required: true, email: true});
	$("#email2").rules("add",{equalTo: "#email1"});
	$("#password").rules("add",{required: true});
});
