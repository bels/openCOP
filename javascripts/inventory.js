$(document).ready(function(){
	load_types();
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
	});

	$('#type_select').livequery(function(){
		$('#type_select').change(function(){
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
					alert("Successfully modified");
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
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' successfully modified</label>').appendTo('#' + which + '_form');
						load_types();
						load_associations();
					} else if(error == "1"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('<label class="error tp_return">' + $('#' + which + '_select :selected').text() + ' already exists</label>').appendTo('#' + which + '_form');
					} else if(error == "2"){
                                                var str = data.replace(/^[\d\s]/,'');
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
