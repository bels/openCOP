$(document).ready(function(){
	load_types();
	load_types2();
	load_types3();

	$('#add_tp_form').validate({
		rules: {
			add_tp: {
				required: true
			}
		}
	});

	$('#submit_add_button').bind('click',function(){
		submit_tp($(this));
	});

	$('#submit_del_button').bind('click',function(){
		submit_tp($(this));
	});

	$('.multiselect').livequery(function(){
		$('.multiselect').multiselect();
		$('.ui-multiselect').show();
	});

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

	$('#del_tp_select').livequery(function(){
		$('#del_tp_select').change(function(){
			if($('#del_tp_select').val() == "property"){
				load_properties();
			} else {
				load_types2();
			}
		});
	});

	$('.type_select').livequery(function(){
		$('.type_select').change(function(){
			load_associations();
		});
	});

	$('#submit_a_tp').bind('click', function(){
		var tp_select_string = "";
		var tp_unselect_string = "";
		var mode = "associate";
		var type = $('#type_select').val();
		$('ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				tp_select_string += $(this).attr("value") + ":";
			}
		});
		$('ul.available').children().each(function(e){
			if($(this).attr("title") !== ""){
				tp_unselect_string += $(this).attr("value") + ":";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'inventory_getdata.pl',
			data: {type: type, mode: mode, selected: tp_select_string, unselected: tp_unselect_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});
});

function remove_error_label(){
	$('#left_add_object_div label.error').remove();
}

function load_associations(){
	var type = $('#type_select').val();
	var mode = "init";
	$.ajax({
		type: 'POST',
		url: 'inventory_getdata.pl',
		data: {type: type, mode: mode},
		success: function(data){
			$('#a_tp_append_div').text("");
			$('#a_tp_append_div').append(data);
			remove_error_label();
		},
		error: function(){
			alert("Error");
		}
	});
}

function load_properties(){
	var mode = "load_properties";
	$.ajax({
			type: 'POST',
			url: 'inventory_getdata.pl',
			data: {mode: mode},
			success: function(data){
				$('#t_tp_append_div').text("");
				$('#t_tp_append_div').append(data);
				remove_error_label();
			},
			error: function(){
				alert("Error");
			}
	});
}

function load_types(){
	var mode = "onload";
	$.ajax({
			type: 'POST',
			url: 'inventory_getdata.pl',
			data: {mode: mode},
			success: function(data){
				$('#onload_append_div').text("");
				$('#onload_append_div').append(data);
				remove_error_label();
			},
			error: function(){
				alert("Error");
			}
	});
}

function load_types2(){
	var mode = "onload_more";
	$.ajax({
			type: 'POST',
			url: 'inventory_getdata.pl',
			data: {mode: mode},
			success: function(data){
				$('#t_tp_append_div').text("");
				$('#t_tp_append_div').append(data);
				remove_error_label();
			},
			error: function(){
				alert("Error");
			}
	});
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

function submit_tp(button){
	which = button.attr("mode");
	value = $('#' + which).val();
	if(value == "") {
		$('.tp_return').remove();
		$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' cannot be blank</label>').appendTo('#' + which + '_form');
	} else {
			mode = "configure";
			type = $('#' + which + '_select').val();
			value = $('#' + which).val();
			$.blockUI({message: "Submitting"});			
			$.ajax({
				type: 'POST',
				url: 'inventory_submit.pl',
				data: {mode: mode, type: type, value: value,action: which},
				success: function(data){
                                        var error = data.substr(0,1);
                                        if(error == "0"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('#' + which).val("");
						$('#' + which).focus();
						$('.tp_return').remove();
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' successfully modified</label>').appendTo('#' + which + '_form');
						load_types();
						load_associations();
					} else if(error == "1"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('.tp_return').remove();
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' already exists</label>').appendTo('#' + which + '_form');
					} else if(error == "2"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('.tp_return').remove();
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' does not exist</label>').appendTo('#' + which + '_form');
					}
					$.unblockUI();
				},
				error: function(){
					alert("What? This should never return an error.");
					$.unblockUI();
				}
			});
	}
}
