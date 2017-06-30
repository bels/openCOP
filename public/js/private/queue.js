;(function(){

	$(function(){
		$('td').click(function(){
			var $this = $(this);
			window.location = '/ticket/' + $this.closest('tr').data('id');
		});
	});
})();