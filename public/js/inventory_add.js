$(document).ready(function(){
	load_types3();

	$('.object_remove_property_button').livequery(function(){
		$(this).bind('click', function(){
			resetLogout();
			$(this).prev().remove();
			$(this).prev().remove();
			$(this).prev().remove();
			$(this).remove();
		});
	});

	$('#submit_create_object_button').livequery(function(){
		$(this).bind('click', function(e){
			e.preventDefault();
			resetLogout();
			var type = $('#object_type_select').val();
			var company = $('#object_company_select').val();
			var name = $('#object_name').val();
			var tpid = $('#object_type_select :selected').attr("tpid");
			var cpid = $('#object_company_select :selected').attr("cpid");
			var npid = $('#object_name').attr("npid");
			if( type !== "" && company !== "" && name !== ""){
				var mode = "create_object";
				var submitvalue = "";
				var submitproperty = "";
				var error;
				$('.object_form_input').each(function(){
					var thisval = $(this).val();
					thisval = thisval.replace(/:/g, "AbsolutelyNotAColon");
					submitvalue += thisval + ":";
					submitproperty += $(this).attr('id') + ":";
				});
				submitvalue += type + ":" + company + ":" + name;
				submitproperty += tpid + ":" + cpid + ":" + npid;
				$.blockUI({message: "Please Wait"});
				$.ajax({
					type: 'POST',
					url: 'inventory_getdata.pl',
					data: {mode: mode, value: submitvalue, property: submitproperty},
					success: function(data){
						$.unblockUI();
						location.href="inventory.pl?mode=add";
					},
					error: function(){
						alert("Error");
						$.unblockUI();
					}
				});
			}
		});
	});

	$('#submit_add_property_button').livequery(function(){
		$(this).bind('click', function(e){
			e.preventDefault();
			resetLogout();
			if($('#object_type_select').val() == "" || $('#object_property_select').val() == ""){
			} else {
				var property = $('#object_property_select').val();
				var mode = "add_property_field";
				$.blockUI({message: "Please Wait"});
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
		$(this).change(function(){
			resetLogout();
			var type = $('#object_type_select').val();
			var mode = "populate_create_form";
			$.blockUI({message: "Please Wait"});
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

