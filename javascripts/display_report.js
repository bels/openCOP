$(document).ready(function(){
	var pane = $('#top').jScrollPane({
		showArrows: true,
		maintainPosition: false
	}).data('jsp');
	$('#res_table').livequery(function(){
		$(this).tablesorter();
	});
	$('#export_button').bind('click',function(){
	//	var h = {};
		var h = [];
		h[0] = [];
		$('#table_head_row').each(function(){
			var i = h[0];
			i.push(null);
			$(this).children('th.table_head_cell').each(function(){
				i.push($(this).text());
			});
		});
		$('.table_row').each(function(){
			h[this.rowIndex] = [h[this.rowIndex]];
			var j = h[this.rowIndex];
			$(this).children('td').each(function(){
				j.push($(this).text());
			});
		});
		var table = $.toJSON(h);
		var mode = $('#export_select').val();
		var email = $('#email').attr('checked');
		var name = $('#report_name').text();
		alert(table);
		$.ajax({
			type: 'POST',
			url: 'export_report.pl',
			data: {mode: mode, table: table, email: email, report_name: name},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					alert(table);
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					alert(error);
					var str = data.replace(/^[\d\s]/,'');
				}
			},
			error: function(){
				alert("Error");
			}
		});
	});
});
