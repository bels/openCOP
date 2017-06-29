$(document).ready(function(){
	$('#customer_admin_form').validate({
		rules: {
			first: "required",
			last: "required",
			username: "required",
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
			username: "*",
			email: "*",
			password1: "*",
			site: "*"
		}
	});

	$('#customer_admin_form').submit(function(e){
		e.preventDefault();
	});

	$('#submit_button').bind('click',function(e){
		e.preventDefault();
		var url = 'add_customer.pl';
		var the_data = $('#customer_admin_form').serialize();
		if($('#customer_admin_form').valid()){
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
						alert("The following errors were encountered while processing your request:" + str);
						window.location = 'customer_admin.pl?success=1';
					} else if(error == "2"){
						var str = data.replace(/^[\d\s]/,'');
						alert("A user with that name already exists. Please choose another.");
					} else {
						window.location = 'customer_admin.pl?success=1';
					}
				},
				error: function(a,b,c){
					alert(a.responseText + b + c);
				}
			});
		}
	});
});
