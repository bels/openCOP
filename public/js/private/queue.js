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
		$('.queue .table').DataTable({
			'colReorder': true,
			'paging': false,
			'order': [[4,'asc']],
			'columnDefs': [
				{
					'type': 'status-sort',
					'targets': 4
				}
			]
		});
		$('td').click(function(){
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