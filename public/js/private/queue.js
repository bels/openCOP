;(function(){

	$(function(){
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