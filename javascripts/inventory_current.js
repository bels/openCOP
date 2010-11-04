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
		});
	});

	$('#property_search_button').livequery(function(){
		$('#property_search_button').bind('click', function(){
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
		});
	});

	$('#company_select').livequery(function(){
		$('#company_select').change(function(){
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
		});
	});

	$('#template_select').livequery(function(){
		$('#template_select').change(function(){
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
		});
	});

	$(".object_row").livequery(function(){
		$(".object_row").bind('click', function(){
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
});
