function get_summary(){
	if($('#property_search').length){
		property_search();
	} else if($('#company_select').length){
		company_select();
	} else if($('#template_select').length){
		template_select();
	}

}

function by_property(){
	$('#table_body').text("");
	$('#update_object_button').remove();
	$('#disable_object_button').remove();
	$('#delete_object_button').remove();
	if($('#by_property').val() !== ""){
		var pid = $('#by_property').val();
		var property = $('#by_property :selected').text();
		var url = "inventory_current.pl";
		var mode = "by_property";
		$.ajax({
			type: 'POST',
			url: url,
			data:{mode: mode, pid: pid, property: property},
			success: function(data){
				$('#company_select_div').text("");
				$('#company_select_div').append(data);
			},
			error: function(){
				alert("An error");
			}
		});
	}
}

function property_search(){
	if($('#property_search').val() !== ""){
		var property = $('#by_property :selected').text();
		var search = $('#property_search').val();
		var mode = "search";
		var url = "inventory_current.pl";
		var pane = $("#object_lookup").jScrollPane({
			showArrows:true,
			maintainPosition: false
		}).data('jsp');
		var url = "inventory_current.pl?mode=search&search=" + search + "&property=" + property;
		pane.getContentPane().load(url,function(data){
			pane.reinitialise();
		});
		$("#object_summary_header").livequery(function(){
			$("#object_summary_header").tablesorter();
		});
	}
}

function company_select(){
	if($('#company_select').val() !== ""){
		if($("#object_lookup").length)
		{
			var cpid = $('#company_select').val();
			var pane = $("#object_lookup").jScrollPane({
				showArrows:true,
				maintainPosition: false
			}).data('jsp');
			var details_pane = $("#object_details").jScrollPane({
				showArrows:true,
				maintainPosition: false
			}).data('jsp');
			var url = "inventory_current.pl?mode=by_company&cpid=" + cpid;
			pane.getContentPane().load(url,function(data){
				pane.reinitialise();
			});
			$("#object_summary_header").livequery(function(){
				$("#object_summary_header").tablesorter();
			});
		}
	}
}

function template_select(){
	if($('#template_select').val() !== ""){
		if($("#object_lookup").length)
		{
			var tid = $('#template_select').val();
			var pane = $("#object_lookup").jScrollPane({
				showArrows:true,
				maintainPosition: false
			}).data('jsp');
			var url = "inventory_current.pl?mode=by_type&tid=" + tid;
			pane.getContentPane().load(url,function(data){
				pane.reinitialise();
			});
			$("#object_summary_header").livequery(function(){
				$("#object_summary_header").tablesorter();
			});
		}
	}
}

$(document).ready(function(){
	var details_pane;
	var url = "inventory_current.pl";
	var mode = "init";
	$.ajax({
		type: 'POST',
		url: url,
		data:{mode: mode},
		success: function(data){
			$('#select_menu').text("");
			$('#select_menu').append(data);
		},
		error: function(){
			alert("A more different error");
		}
	});

	$('#by_property').livequery(function(){
		$('#by_property').change(function(){
			resetLogout();
			by_property();
			$('#update_object_form').remove();
		});
	});

	$('#property_search_button').livequery(function(){
		$('#property_search_button').bind('click', function(){
			resetLogout();
			property_search();
			$('#update_object_button').remove();
			$('#disable_object_button').remove();
			$('#delete_object_button').remove();
			$('#update_object_form').remove();
		});
	});

	$('#company_select').livequery(function(){
		$('#company_select').change(function(){
			resetLogout();
			$('#table_body').text("");
			company_select();
			$('#update_object_button').remove();
			$('#disable_object_button').remove();
			$('#delete_object_button').remove();
			$('#update_object_form').remove();
		});
	});

	$('#template_select').livequery(function(){
		$('#template_select').change(function(){
			resetLogout();
			$('#table_body').text("");
			template_select();
			$('#update_object_button').remove();
			$('#disable_object_button').remove();
			$('#delete_object_button').remove();
			$('#update_object_form').remove();
		});
	});

	$(".object_row").livequery(function(){
		$(".object_row").bind('click', function(){
			resetLogout();
			var object_id = $(this).children(".object_id").text();
			var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
			details_pane = $("#object_details").jScrollPane({
					showArrows:true,
					maintainPosition: false
			}).data('jsp');
			details_pane.getContentPane().load(url,function(data){
				details_pane.reinitialise();			
			});
			$("#object_details").css("display","block");
		});
	});
	$("#update_object_button").livequery(function(){
		$("#update_object_button").bind('click', function(){
			resetLogout();
			var mode = "update_object";
			var submitvalue = "";
			var submitvid = "";
			var object_id = $(this).attr("object");
			$('input.object_detail').each(function(){
				if($(this).prev().text() != "type" && $(this).prev().text() != "company"){
						submitvalue += $(this).val() + ":";
						submitvid += $(this).attr("id") + ":";
				}
			});
			$.blockUI({message: "Submitting"});
			$.ajax({
				type: 'POST',
				url: 'inventory_getdata.pl',
				data: {mode: mode, value: submitvalue, vid: submitvid},
				success: function(data){
					$.unblockUI();
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					details_pane = $("#object_details").jScrollPane({
							showArrows:true,
							maintainPosition: false
					}).data('jsp');
					details_pane.getContentPane().load(url,function(data){
						details_pane.reinitialise();			
					});
					$("#object_details").css("display","block");
					get_summary();
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		});
	});
	$("#delete_object_button").livequery(function(){
		$("#delete_object_button").bind('click', function(){
			resetLogout();
			var mode = "delete_object";
			var object = $(this).attr("object");
			$.blockUI({message: "Submitting"});
			$.ajax({
				type: 'POST',
				url: 'inventory_getdata.pl',
				data: {mode: mode, object: object},
				success: function(data){
					$.unblockUI();
					var object_id = $(this).attr("object");
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					details_pane = $("#object_details").jScrollPane({
							showArrows:true,
							maintainPosition: false
					}).data('jsp');
					details_pane.getContentPane().load(url,function(data){
						details_pane.reinitialise();			
					});
					$("#object_details").css("display","none");
					$('#update_object_button').remove();
					$('#disable_object_button').remove();
					$('#delete_object_button').remove();
					get_summary();
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		});
	});
	$("#disable_object_button").livequery(function(){
		$("#disable_object_button").bind('click', function(){
			resetLogout();
			var mode = "disable_object";
			var object = $(this).attr("object");
			$.blockUI({message: "Submitting"});
			$.ajax({
				type: 'POST',
				url: 'inventory_getdata.pl',
				data: {mode: mode, object: object},
				success: function(data){
					$.unblockUI();
					var object_id = $(this).attr("object");
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					details_pane = $("#object_details").jScrollPane({
							showArrows:true,
							maintainPosition: false
					}).data('jsp');
					details_pane.getContentPane().load(url,function(data){
						details_pane.reinitialise();			
					});
					$("#object_details").css("display","none");
					$('#update_object_button').remove();
					$('#disable_object_button').remove();
					$('#delete_object_button').remove();
					get_summary();
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		});
	});
});
