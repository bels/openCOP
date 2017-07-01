;(function(){
	$(function(){
		$('.edit.btn').click(function(){
			var $this = $(this);
			$('.static').each(function(index,element){
				$(element).addClass('hidden');
			});
			$('.input').each(function(index,element){
				$(element).removeClass('hidden');
			});
			$this.hide();
			$('.save.btn').removeClass('hidden');
		});
		
		$('.save.btn').click(function(){
			
		});
	});
})();