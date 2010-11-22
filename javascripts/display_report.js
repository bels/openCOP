$(document).ready(function(){
	var pane = $('#top').jScrollPane({
		showArrows: true,
		maintainPosition: false
	}).data('jsp');
	$('#res_table').livequery(function(){
		$(this).tablesorter();
	});
	$('#export_button').bind('click',function(){
		resetLogout();
	//	var h = {};
		var h = [];
		h[0] = [];
		$('#table_head_row').each(function(){
			var i = h[0];
			i.push(undefined);
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
		if(email === true){
			$.ajax({
				type: 'POST',
				url: 'export_report.pl',
				data: {mode: mode, table: table, email: email, report_name: name},
				success: function(data){
				},
				error: function(){
					alert("Error");
				}
			});
		} else {
			var data = {mode: mode, report_name: name, table: table};
			$.download('save_report.pl',data,'post',function(){});
		}
	});
});
