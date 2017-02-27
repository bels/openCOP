$(document).ready(function(){
	load_types();
	load_types2();

	$('#add_tp_form').validate({
		rules: {
			add_tp: {
				required: true
			}
		}
	});

	$('#submit_add_button').bind('click',function(){
		resetLogout();
		submit_tp($(this));
	});

	$('#submit_del_button').bind('click',function(){
		resetLogout();
		submit_tp($(this));
	});

	$('.multiselect').livequery(function(){
		$(this).multiselect();
		$('.ui-multiselect').show();
	});


	$('#del_tp_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			if($('#del_tp_select').val() == "property"){
				load_properties();
			} else {
				load_types2();
			}
		});
	});

	$('.type_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			load_associations();
		});
	});

	$('#submit_a_tp').bind('click', function(){
		resetLogout();
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
		$.blockUI({message: "Please Wait"});
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
function load_associations(t,value){
	var type = $('#type_select').val();
	if($('#type_select').val() == ""){
		type = t;
	}
	var mode = "init";
	$.ajax({
		type: 'POST',
		url: 'inventory_getdata.pl',
		data: {type: type, mode: mode},
		success: function(data){
			$('#a_tp_append_div').text("");
			$('#a_tp_append_div').append(data);
			if(type == ""){
				type = value;
				$('#type_select option').each(function(){
					if($(this).text() == type){
						$(this).attr('selected','selected');
					}
				});
			} else {
				 $('#type_select option[value="' + type + '"]').attr('selected','selected');
			}
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
			},
			error: function(){
				alert("Error");
			}
	});
}

function submit_tp(button){
	var t = $('#type_select').val();
	var which = button.attr("mode");
	var value = $('#' + which).val();
	var errorspace = $('#errorspace');
	if(value == "") {
		$('.tp_return').remove();
		$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' cannot be blank</label>').appendTo(errorspace);
	} else {
			var mode = "configure";
			var type = $('#' + which + '_select').val();
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
						$('<label class="tp_return">' + $('#' + which + '_select :selected').text() + ' successfully modified</label>').appendTo(errorspace);
						load_types();
						load_types2();
						load_associations(t,value);
					} else if(error == "1"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('.tp_return').remove();
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' already exists</label>').appendTo(errorspace);
					} else if(error == "2"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('.tp_return').remove();
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' does not exist</label>').appendTo(errorspace);
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
