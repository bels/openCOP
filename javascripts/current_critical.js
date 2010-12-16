	var url = 'current_critical_addon.pl';
	$('#res_table').jqGrid({
			url: url,
			datatype: 'xml',
			mtype: 'GET',
			colNames: ['Ticket Number','Ticket Status','Ticket Priority','Assigned Technician','Problem','Section'],
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true},
				{name: 'status', index: 'status', width: 100, sortable: true},
				{name: 'priority', index: 'priority', width: 100, sortable: true},
				{name: 'technician', index: 'technician', width: 125, sortable: true},
				{name: 'problem', index: 'problem', width: 200, sortable: true},
				{name: 'name', index: 'name', width: 100, sortable: true}
			],
			pager: "#pager",
			rowNum: 10,
			rowList: [10,20,30],
			sortname: 'ticket',
			sortorder: 'asc',
			viewrecords: true,
			altRows: true,
			gridview: true,
			ignoreCase: true,
			multiKey: 'ctrlKey',
			multiselect: true,
			multiboxonly: true,
			toolbar: [true,'top'],
			caption: "Current Critical Tickets",
			ondblClickRow: function(rowid){
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

	$('#cancel').live('click',function(e){
		e.preventDefault();
		resetLogout();
		$('#ticket_details').fadeOut();
		$('#behind_popup').fadeOut('slow');
	});
	$('#update_form').livequery(function(){
		$(this).append('<button id="cancel">Cancel</button>')
	});
