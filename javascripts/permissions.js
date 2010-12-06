$(document).ready(function(){
	$('.delete_button').bind('click', function(){
		resetLogout();
		var id = $(this).attr('id');
		var mode = "delete_permission";
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'permissions_submit.pl',
			data: {id: id, mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Record does not exist? Then what ID do I have? " + id);
				}
				$.unblockUI();
				location.reload(true);
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('.update_button').bind('click', function(){
		resetLogout();
		var id = $(this).attr('id');
		var mode = "update_permission";
		var permission_string = "";
		$(this).parent().parent().find('input.new_permission').each(function(e){
			if($(this).attr("checked") == true){
				permission_string += "1:";
			} else {
				permission_string += "0:";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'permissions_submit.pl',
			data: {id: id, mode: mode, permission: permission_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Record does not exist? Then what ID do I have? " + id);
				}
				$.unblockUI();
				location.reload(true);
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('#submit_a_gs').bind('click', function(){
		resetLogout();
		var gid = $('#select_group').val();
		var sid = $('#select_section').val();
		var mode = "add_gs";
		var permission_string = "";
		$('#add_permission').find('input.new_permission').each(function(e){
			if($(this).attr("checked") == true){
				permission_string += "1:";
			} else {
				permission_string += "0:";
			}
		});
		$.blockUI({message: "Submitting"});
		if(gid && sid){
			$.ajax({
				type: 'POST',
				url: 'permissions_submit.pl',
				data: {gid: gid, sid: sid, mode: mode, permission: permission_string},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
						alert("Duplicate entry encountered");
					}
					$.unblockUI();
					location.reload(true);
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		}
	});
});
