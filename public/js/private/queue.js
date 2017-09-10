;(function(){

	var data_tables = new Array();
	function pull_queues(callback){
		var statuses = '';
		$('.toggle.visible').each(function(index,element){
			var $chk = $(element);
			if($chk.is(':checked')){
				statuses = statuses + 'status=' + $chk.val() + '&';
			}
		});
		statuses = statuses.substring(0, statuses.length - 1);
		$.ajax({
			url: '/ticket/queue/all?' + statuses,
			method: 'GET'
		}).done(function(data){
			callback(data.queues,data_tables);
		});
	}

	$(function(){
		$.fn.dataTable.ext.type.order['status-sort-pre'] = function ( d ) {
		    switch ( d ) {
		        case 'New':    return 1;
		        case 'In Progress': return 2;
		        case 'Waiting Customer':   return 3;
		        case 'Waiting Vendor':   return 4;
		        case 'Waiting Other':   return 5;
		        case 'Closed':   return 6;
		        case 'Completed':   return 7;
		    }
		    return 0;
		};

		pull_queues(function(queues,data_tables){
			$.each(queues,function(index,queue){
				data_tables[index] = $('.queue .table[data-queue-id=' + index + ']').DataTable({
					'data': queue,
					'colReorder': true,
					'order': [[5,'asc']],
					'rowId': 0,
					'columns': [
						{ 'data': 1 },
						{ 'data': 2 },
						{ 'data': 3 },
						{ 'data': 4 },
						{ 'data': 5 },
						{ 'data': 6 },
						{ 'data': 8 },
					],
					'columnDefs': [
						{
							'type': 'status-sort',
							'targets': 5
						}
					]
				});
			});
		});

		$('table').on('click','td',function(){
			var $this = $(this);
			window.location = '/ticket/' + $this.closest('tr').attr('id');
		});
		
		$('.toggle.visible').click(function(){
			var $queues = pull_queues(function(queues,data_tables){
				$.each(queues,function(index,queue){
					data_tables[index].clear().draw();
					data_tables[index].rows.add(queue);
					data_tables[index].columns.adjust().draw();
				});
			});
		});
	});
})();