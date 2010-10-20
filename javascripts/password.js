$(document).ready(function(){
	$("#password_form").validate();
	$("#old_password").rules("add",{required: true});
	$("#password1").rules("add",{required: true});
	$("#password2").rules("add",{equalTo: "#password1"});
});