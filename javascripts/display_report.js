$(document).ready(function(){
	$('#email').bind('click',function(){
		var eb = $('#export_button');
		if(eb.text() == "Save"){
			eb.text("Send");
		} else if(eb.text() == "Send"){
			eb.text("Save");
		}
	});
	$('#export_button').bind('click',function(){
		resetLogout();
		var h = [];
		h[0] = [];
		$('table.ui-jqgrid-htable tr').each(function(){
			var i = h[0];
			$(this).children('th').each(function(){
				i.push($(this).children('div').text());
			});
		});
		$('#res_table tr.ui-widget-content').each(function(){
			h[this.rowIndex] = [h[this.rowIndex]];
			var j = h[this.rowIndex];
			$(this).children('td').each(function(){
				j.push($(this).text());
			});
		});
		var table = $.toJSON(h);
		var mode = $('#export_select').val();
		var email = $('#email').attr('checked');
		var name = $('#gview_res_table span.ui-jqgrid-title').text();
		if(email === true){
			$.ajax({
				type: 'POST',
				url: 'export_report.pl',
				data: {mode: mode, table: table, report_name: name},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						alert("The report has been sent.");
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
						alert(str);
					}
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
