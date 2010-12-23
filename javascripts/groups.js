$(document).ready(function(){
	$('.multiselect').livequery(function(){
		$(this).multiselect();
		$('.ui-multiselect').show();
	});

	$('#select_user_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			if($('#select_user_select').val()){
				load_associations_ug();
			}
		});
	});

	$('#select_group_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			if($('#select_group_select').val()){
				load_associations_gu();
			}
		});
	});

	$('#submit_a_ug').bind('click', function(){
		resetLogout();
		var ug_select_string = "";
		var ug_unselect_string = "";
		var mode = "associate_ug";
		var uid = $('#select_user_select').val();
		$('#a_ug_append_div ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				ug_select_string += $(this).attr("value") + ":";
			}
		});
		$('#a_ug_append_div ul.available').children().each(function(e){
			if($(this).attr("title") !== ""){
				ug_unselect_string += $(this).attr("value") + ":";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_getdata.pl',
			data: {uid: uid, mode: mode, selected: ug_select_string, unselected: ug_unselect_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
				if($('#select_group_select').val()){
					load_associations_gu();
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('#add_group_button').bind('click', function(){
		resetLogout();
		var groupname = $('input#group_name').val();
		var mode = "add_group";
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_submit.pl',
			data: {groupname: groupname, mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Group added successfully");
					location.reload(true);
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Duplicate entry encountered");
				} else if(error == "2"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Error executing insert statement");
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('#del_group_button').bind('click', function(){
		resetLogout();
		var group = $('select#delete_group_select').val();
		var mode = "del_group";
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_submit.pl',
			data: {group: group, mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Group deleted successfully");
					location.reload(true);
				} else if(error == "1"){
					alert("Error executing delete statement");
				}
				if($('#select_group_select').val()){
					load_associations_ug();
					load_associations_gu();
					location.reload(true);
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('#submit_a_gu').bind('click', function(){
		resetLogout();
		var gu_select_string = "";
		var gu_unselect_string = "";
		var mode = "associate_gu";
		var gid = $('#select_group_select').val();
		$('#a_gu_append_div ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				gu_select_string += $(this).attr("value") + ":";
			}
		});
		$('#a_gu_append_div ul.available').children().each(function(e){
			if($(this).attr("title") !== ""){
				gu_unselect_string += $(this).attr("value") + ":";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_getdata.pl',
			data: {gid: gid, mode: mode, selected: gu_select_string, unselected: gu_unselect_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
				if($('#select_group_select').val()){
					load_associations_ug();
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

function load_associations_ug(){
	var uid = $('#select_user_select').val();
	var mode = "init_ug";
	$.ajax({
		type: 'POST',
		url: 'groups_getdata.pl',
		data: {uid: uid, mode: mode},
		success: function(data){
			$('#a_ug_append_div').text("");
			$('#a_ug_append_div').append(data);
		//	remove_error_label();
		},
		error: function(){
			alert("Error");
		}
	});
}

function load_associations_gu(){
	var gid = $('#select_group_select').val();
	var mode = "init_gu";
	$.ajax({
		type: 'POST',
		url: 'groups_getdata.pl',
		data: {gid: gid, mode: mode},
		success: function(data){
			$('#a_gu_append_div').text("");
			$('#a_gu_append_div').append(data);
		//	remove_error_label();
		},
		error: function(){
			alert("Error");
		}
	});
}
