;(function(){

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
		$.ajax({
			url: '/ticket/queue/all',
			method: 'GET'
		}).done(function(data){
			$.each(data.queues,function(index,queue){
				$('.queue .table[data-queue-id=' + index + ']').DataTable({
					'data': queue,
					'colReorder': true,
					'order': [[5,'asc']],
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
			window.location = '/ticket/' + $this.closest('tr').data('id');
		});
		
		$('.toggle.visible').click(function(){
			var $this = $(this);
			
			var $rows = $this.closest('.queue').find("[data-status='" + $this.val() + "']");
			$rows.each(function(index,element){
				if($this.is(':checked')){
					if($(element).hasClass('collapse')){
						$(element).removeClass('collapse');
					}
				} else {
					if($(element).hasClass('collapse')){
						
					} else {
						$(element).addClass('collapse');
					}
				}
			});
		});
	});
})();