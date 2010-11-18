$(document).ready(function(){
	$("#modules").load("list_modules.pl");
	$(".module").live('click',function(){
		var module_name = $(this).attr('name');
		if($(this).is(':checked')){
			handle_modules(module_name,'enable');
			location.reload(true);
		}
		else
		{
			handle_modules(module_name,'disable');
			location.reload(true);
		}
	});
});

function handle_modules(module_name,todo){
	$.get("handle_module_status.pl",{name: module_name,action: todo});
}