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
			var data = {};
			$('.input .form-control').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			$('.input').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			data['csrf_token'] = $('#csrf_token').val();
			$.ajax({
				url: '/ticket/update/' + $('#ticket_id').val(),
				method: 'POST',
				data: JSON.stringify(data),
				dataType: 'json'
			}).done(function(data){
				
			});
		});
	});
})();