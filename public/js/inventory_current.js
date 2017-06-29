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
		var url = "inventory_current.pl?mode=search&search=" + search + "&property=" + property;
			$('.wo_link.selected').removeClass('selected');
			$('#object_lookup').html('<table id="object_table"></table><div id="pager"></div>');
			$('#object_table').jqGrid({
				url: url,
				datatype: 'xml',
				mtype: 'GET',
				colNames: ['ID','Name','Type','Company'],
				colModel: [
					{name: 'id', index: 'id', width: 100, sortable: true},
					{name: 'name', index: 'name', width: 100, sortable: true},
					{name: 'type', index: 'type', width: 200, sortable: true},
					{name: 'type', index: 'company', width: 200, sortable: true}
				],
				pager: "#pager",
				width: 700,
				rowNum: 10,
				rowList: [10,20,30],
				sortname: 'id',
				sortorder: 'asc',
				viewrecords: true,
				altRows: true,
				gridview: true,
				ignoreCase: true,
				multiKey: 'ctrlKey',
				multiselect: true,
				multiboxonly: true,
				toolbar: [true,'top'],
				ondblClickRow: function(rowid){
					resetLogout();
					var object_id = rowid;
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
					$('#object_details').html("");
					$('#object_details').load(url).fadeIn('slow');
					var windowWidth = document.documentElement.clientWidth;
					var windowHeight = document.documentElement.clientHeight;
					var popupHeight = $('#object_details').height();
					var popupWidth = $('#object_details').width();
					$('#object_details').css({
						'position': 'absolute',
						'top': windowHeight/2-popupHeight/2,
						'left': windowWidth/2-popupWidth/2
					});
					$('#behind_popup').css({
						'height': windowHeight
					});
				}
			});
	}
}

function company_select(){
	if($('#company_select').val() !== ""){
		if($("#object_lookup").length)
		{
			var cpid = $('#company_select').val();
			var url = "inventory_current.pl?mode=by_company&cpid=" + cpid;
			$('.wo_link.selected').removeClass('selected');
			$('#object_lookup').html('<table id="object_table"></table><div id="pager"></div>');
			$('#object_table').jqGrid({
				url: url,
				datatype: 'xml',
				mtype: 'GET',
				colNames: ['ID','Name','Type'],
				colModel: [
					{name: 'id', index: 'id', width: 100, sortable: true},
					{name: 'name', index: 'name', width: 100, sortable: true},
					{name: 'type', index: 'type', width: 200, sortable: true}
				],
				pager: "#pager",
				width: 700,
				rowNum: 10,
				rowList: [10,20,30],
				sortname: 'id',
				sortorder: 'asc',
				viewrecords: true,
				altRows: true,
				gridview: true,
				ignoreCase: true,
				multiKey: 'ctrlKey',
				multiselect: true,
				multiboxonly: true,
				toolbar: [true,'top'],
				ondblClickRow: function(rowid){
					resetLogout();
					var object_id = rowid;
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
					$('#object_details').html("");
					$('#object_details').load(url).fadeIn('slow');
					var windowWidth = document.documentElement.clientWidth;
					var windowHeight = document.documentElement.clientHeight;
					var popupHeight = $('#object_details').height();
					var popupWidth = $('#object_details').width();
					$('#object_details').css({
						'position': 'absolute',
						'top': windowHeight/2-popupHeight/2,
						'left': windowWidth/2-popupWidth/2
					});
					$('#behind_popup').css({
						'height': windowHeight
					});
					$(document).bind('keydown.escObject',function(e){
						if(e.keyCode == 27){
							resetLogout();
							$('#behind_popup').fadeOut('slow');
							$('#object_details').fadeOut('slow');
						}
					});

				}
			});
		}
	}
}

function template_select(){
	if($('#template_select').val() !== ""){
		if($("#object_lookup").length)
		{
			var tid = $('#template_select').val();
			var url = "inventory_current.pl?mode=by_type&tid=" + tid;
			$('.wo_link.selected').removeClass('selected');
			$('#object_lookup').html('<table id="object_table"></table><div id="pager"></div>');
			$('#object_table').jqGrid({
				url: url,
				datatype: 'xml',
				mtype: 'GET',
				colNames: ['ID','Name','Company'],
				colModel: [
					{name: 'id', index: 'id', width: 100, sortable: true},
					{name: 'name', index: 'name', width: 100, sortable: true},
					{name: 'type', index: 'company', width: 200, sortable: true}
				],
				pager: "#pager",
				width: 700,
				rowNum: 10,
				rowList: [10,20,30],
				sortname: 'id',
				sortorder: 'asc',
				viewrecords: true,
				altRows: true,
				gridview: true,
				ignoreCase: true,
				multiKey: 'ctrlKey',
				multiselect: true,
				multiboxonly: true,
				toolbar: [true,'top'],
				ondblClickRow: function(rowid){
					resetLogout();
					var object_id = rowid;
					var url = "inventory_current.pl?mode=object_details&object_id=" + object_id;
					$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
					$('#object_details').html("");
					$('#object_details').load(url).fadeIn('slow');
					var windowWidth = document.documentElement.clientWidth;
					var windowHeight = document.documentElement.clientHeight;
					var popupHeight = $('#object_details').height();
					var popupWidth = $('#object_details').width();
					$('#object_details').css({
						'position': 'absolute',
						'top': windowHeight/2-popupHeight/2,
						'left': windowWidth/2-popupWidth/2
					});
					$('#behind_popup').css({
						'height': windowHeight
					});
				}
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

	$('.add_property').livequery(function(){
		$(this).bind('click',function(e){
			e.preventDefault();
			resetLogout();
			var url = 'inventory_current.pl';
			var mode = 'add_property';
			$.ajax({
				type: 'POST',
				url: url,
				data:{mode: mode},
				success: function(data){
					$('#update_object_form').append(data);
					$('#update_object_form').append('<input type="text" id="0" class="object_detail"><button class="del_property">-</button><br>');
				},
				error: function(){
					alert("A more different error");
				}
			});
			var formHeight = $('#update_object_form').innerHeight();
			$('#update_object_form').css('height', (formHeight + 26) + 'px');
		});
	});

	$('#update_close').live('click',function(){
		resetLogout();
		$('#behind_popup').fadeOut('slow');
		$('#object_details').fadeOut('slow');
	});

	$('.del_property').livequery(function(){
		$(this).bind('click',function(e){
			e.preventDefault();
			resetLogout();
			$(this).prev().prev().remove();
			$(this).prev().remove();
			$(this).next().remove();
			$(this).remove();
		});
	});

	$('#by_property').livequery(function(){
		$(this).change(function(){
			resetLogout();
			by_property();
			$('#update_object_form').remove();
		});
	});

	$('#property_search_button').livequery(function(){
		$(this).bind('click', function(){
			resetLogout();
			property_search();
		});
	});

	$('#company_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			company_select();
		});
	});

	$('#template_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			template_select();
		});
	});

	$("#update_object_button").livequery(function(){
		$(this).bind('click', function(){
			resetLogout();
			var mode = "update_object";
			var submitvalue = "";
			var submitvid = "";
			var submitpid = "";
			var object_id = $(this).attr("object");
			$('input.object_detail').each(function(){
				if($(this).prev().text() != "type" && $(this).prev().text() != "company"){
					if($(this).prev('select').length){
						if($(this).prev().val() !== ""){
							submitpid += $(this).prev().val() + ":";
							submitvid += $(this).attr("id") + ":";
						}
					} else {
						submitpid += "0" + ":";						
						submitvid += $(this).attr("id") + ":";
					}
					submitvalue += $(this).val() + ":";
				}
			});
			$.blockUI({message: "Submitting"});
			$.ajax({
				type: 'POST',
				url: 'inventory_getdata.pl',
				data: {mode: mode, value: submitvalue, vid: submitvid, pid: submitpid, object_id: object_id},
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
					$('#object_details').fadeOut();
					$('#behind_popup').fadeOut('slow');
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
		$(this).bind('click', function(){
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
					$('#object_dedails').fadeOut();
					$('#behind_popup').fadeOut('slow');
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
		$(this).bind('click', function(){
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
					$('#object_details').fadeOut();
					$('#behind_popup').fadeOut('slow');
					get_summary();
				},
				error: function(){
					alert("Error");
					$.unblockUI();
				}
			});
		});
	});
	$('#cancel').livequery(function(){
		$(this).bind('click',function(e){
			e.preventDefault();
			resetLogout();
			$('#object_details').fadeOut();
			$('#behind_popup').fadeOut('slow');
		});
	});
});
