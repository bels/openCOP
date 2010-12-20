jQuery(function($){
		$('#res_table').jqGrid({
			height: 200,
			datatype: 'local',
			colNames: ['Name','Description'],
			colModel: [
				{name: 'name', index: 'name', width: 150, sortable: true},
				{name: 'description', index: 'description', width: 500, sortable: true},
			],
			sortname: 'name',
			sortorder: 'asc',
			viewrecords: true,
			altRows: true,
			gridview: true,
			ignoreCase: true,
			multiKey: 'ctrlKey',
			multiselect: true,
			multiboxonly: true,
			toolbar: [true,'top'],
			caption: 'Reports',
			ondblClickRow: function(rowid){
				var id = rowid;
				location.href = "display_report.pl?id=" + id;
				resetLogout();
				var ticket_number = rowid;
				var url = "ticket_details.pl?ticket_number=" + ticket_number;
				$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
				$('#ticket_details').load(url).fadeIn('slow');
				var windowWidth = document.documentElement.clientWidth;
				var windowHeight = document.documentElement.clientHeight;
				var popupHeight = $('#ticket_details').height();
				var popupWidth = $('#ticket_details').width();
				$('#ticket_details').css({
					'position': 'absolute',
					'top': windowHeight/2-popupHeight/2,
					'left': windowWidth/2-popupWidth/2
				});
				$('#behind_popup').css({
					'height': windowHeight
				});
			}
		});
		$('#hidden_table tr').each(function(){
			var id = $(this).children(' :nth-child(1) ').text();
			var name = $(this).children(' :nth-child(2) ').text();
			var report = $(this).children(' :nth-child(3) ').text();
			var desc = $(this).children(' :nth-child(4) ').text();
			$('#res_table').addRowData(id, {name: name, report: report, description: desc});
		});
});
