$(document).ready(function(){
	load_types3();

	$('.object_remove_property_button').livequery(function(){
		$('.object_remove_property_button').bind('click', function(){
			$(this).prev().remove();
			$(this).prev().remove();
			$(this).prev().remove();
			$(this).remove();
		});
	});

	$('#submit_create_object_button').livequery(function(){
		$('#submit_create_object_button').bind('click', function(){
					var type = $('#object_type_select').val();
					var company = $('#object_company_select').val();
					if( type !== "" && company !== ""){
						var mode = "create_object";
						var submitvalue = "";
						var submitproperty = "";
						var error;
							$('.object_form_input').each(function(){
								if($(this).val() !== "" ){
									submitvalue += $(this).val() + ":";
									submitproperty += $(this).attr('id') + ":";
								//	alert($(this).val());
								} else {
									error = 1;
								}
							});
						if(error == 1){
							$('#left_add_object_div label.error').remove();
							$('#left_add_object_div').append("<label id=\"validate_error\" class=\"error\">Please fill in all fields</label>");
						} else {
							$.blockUI({message: "Submitting"});
							$.ajax({
								type: 'POST',
								url: 'inventory_getdata.pl',
								data: {type: type, company: company, mode: mode, value: submitvalue, property: submitproperty},
								success: function(data){
									alert("Success");
									$.unblockUI();
								},
								error: function(){
									alert("Error");
									$.unblockUI();
								}
							});
						}
					}
		});
	});

	$('#submit_add_property_button').livequery(function(){
		$('#submit_add_property_button').bind('click', function(){
			if($('#object_type_select').val() == "" || $('#object_property_select').val() == ""){
			} else {
				var property = $('#object_property_select').val();
				var mode = "add_property_field";
				$.blockUI({message: "Submitting"});
				$.ajax({
					type: 'POST',
					url: 'inventory_getdata.pl',
					data: {property: property, mode: mode},
					success: function(data){
						$('#center_create_object_form').append(data);
						remove_error_label();
						$.unblockUI();
					},
					error: function(){
						alert("Error");
						$.unblockUI();
					}
				});
			}
		});
	});

	$('#object_type_select').livequery(function(){
		$('#object_type_select').change(function(){
			var type = $('#object_type_select').val();
			var mode = "populate_create_form";
			$.blockUI({message: "Submitting"});
			$.ajax({
				type: 'POST',
				url: 'inventory_getdata.pl',
				data: {type: type, mode: mode},
				success: function(data){
					$('.object_form').remove();
					remove_error_label();
					$('#center_create_object_form').children('br').remove();
					$('#center_create_object_form').append(data);
					$.unblockUI();
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		});
	});
});

function remove_error_label(){
	$('#left_add_object_div label.error').remove();
}

function load_types3(){
	var mode = "object_onload";
	$.ajax({
			type: 'POST',
			url: 'inventory_getdata.pl',
			data: {mode: mode},
			success: function(data){
				$('#left_add_object_div').append(data);
				remove_error_label();
			},
			error: function(){
				alert("Error");
			}
	});
}

